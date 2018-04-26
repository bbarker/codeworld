let
  fetchNixpkgs = import ./nix/fetchNixpkgs.nix;

  nixpkgs = fetchNixpkgs {
    rev = "cf68bb33cb797d4e6802ef5f3e6b68715fca1e7b";

    sha256 = "19vfp42w2n3lsaxarq481zklb70m1rsrcxc8wd84zpfiskdj9646";

    outputSha256 = "1rm7nranplzk6bfkvbpr1br42mbb41czss3fkgvbm2nx6xd8f3cm";
  };

  config = import ./nix/config.nix;

  overlays = [ (import ./nix/overlay.nix) ];

  pkgs = import nixpkgs { inherit config overlays; };

in
  { inherit (pkgs.haskell.packages.ghc802)
      codeworld-game-server
      codeworld-server
    ;
  }
