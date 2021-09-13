with import <nixpkgs> {};
mkShell {
  name = "machine-learning";
  nativeBuildInputs = [
    gnumake
    jupyter
    jq
    pandoc
    wkhtmltopdf
    texlive.combined.scheme-full
  ];
}
