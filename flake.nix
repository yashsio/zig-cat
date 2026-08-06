{
  description = "Zig Dev Shell";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system: 
    let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      devShells.default = pkgs.mkShell {
        RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";
        nativeBuildInputs = with pkgs; [
          clang        
          lldb         
          zig          
          zls          
        ];
      };
    });
}   
