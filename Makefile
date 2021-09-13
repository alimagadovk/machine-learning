PASSWORD := $(firstword $(file < password))
CRYPTOR := openssl enc -aes-128-cbc -pbkdf2 -iter 1000 -a -A -K $(PASSWORD) -iv $(PASSWORD)
SOURCES := $(wildcard *.ipynb)
CLEANUP := jq --indent 1 \
			'reduce path(.cells[]|select(.cell_type=="code")) as $$i \
				(.; setpath($$i + ["outputs"]; []) | setpath($$i + ["execution_count"]; null))'

define cryptotransform
	awk -i inplace \
		'BEGIN { is_code_cell = 0; is_source = 0; command = $(1); } \
		/^[ \t]*\]$$/ { if (is_source && is_code_cell) { is_source = 0; is_code_cell = 0; } } \
		{ if (is_source) { \
				match($$0, "^([ \t]*\")(.*)(\",?)$$", a); \
				print(a[2]) |& command; close(command, "to"); \
				command |& getline out; close(command, "from"); \
				printf("%s%s%s\n", a[1], out, a[3]); \
			} else { \
				print $$0; \
			} \
		} \
		/^[ \t]*"cell_type":[ ]*"code"/ { is_code_cell = 1; } \
		/^[ \t]*"source":[ ]*\[/ { if (is_code_cell) is_source = 1; } \
		' $(2)
endef

define runall
	echo Running $(1)
	jupyter nbconvert --to notebook --inplace --execute $(1)
	jupyter nbconvert --to html $(1)
endef

encrypt: $(SOURCES)
	@$(call cryptotransform,"$(CRYPTOR) -e; echo",$^)

decrypt: $(SOURCES)
	@$(call cryptotransform,"$(CRYPTOR) -d",$^)

purge:
	@$(foreach f,$(SOURCES),$(shell $(CLEANUP) $(f) | sponge $(f)))

run:
	@$(foreach f,$(SOURCES),$(call runall,$(f)))

pdf: $(SOURCES)
	@jupyter nbconvert --to webpdf $^
