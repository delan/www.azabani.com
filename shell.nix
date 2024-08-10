{ pkgs ? import (fetchTarball { url = "https://github.com/NixOS/nixpkgs/archive/21cc704b5e918c5fbf4f9fff22b4ac2681706d90.tar.gz"; }) {} }:
pkgs.mkShell {
  shellHook = ''
    # Gemfile > jekyll
    # Jekyll::Converters::Scss error: Invalid US-ASCII character "\xE2"
    export LANG=C.UTF-8

    # helper > requirements.txt > Brotli
    # https://discourse.nixos.org/t/x/5522/2
    export LD_LIBRARY_PATH=${pkgs.lib.makeLibraryPath [pkgs.stdenv.cc.cc]}
  '';

  buildInputs = [
    # Makefile
    pkgs.git
    pkgs.rsync
    pkgs.less

    # Gemfile
    pkgs.bundler

    # helper > requirements.txt
    pkgs.python3

    # helper > package.json
    pkgs.nodejs

    # soupault.toml
    pkgs.soupault
  ];
}
