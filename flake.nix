{
  inputs = {
    unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    nixpkgs.follows = "unstable";
  };
  outputs = { self, nixpkgs, ... } @ inputs:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
    in {
    devShells.x86_64-linux = {
      default = pkgs.mkShell {
        buildInputs = with pkgs.haskellPackages; [
          haskell-language-server
          ghcid
          cabal-install
          pkgs.nil
          pkgs.pkg-config
        ];
      };
    };
  };
}