let
  pkgs_rev = "6a3f5bcb061e1822f50e299f5616a0731636e4e7";
  nixpkgs = builtins.fetchTarball {
    name = "nixpkgs-${builtins.substring 0 6 pkgs_rev}";
    url = "https://github.com/NixOS/nixpkgs/archive/${pkgs_rev}.tar.gz";
    # Hash obtained using `nix-prefetch-url --unpack <url>`
    sha256 = "1ib96has10v5nr6bzf7v8kw7yzww8zanxgw2qi1ll1sbv6kj6zpd";
  };

  config = import ./nix/config.nix;

  overlays = [ (import ./nix/overlay.nix) ];

  pkgs = import nixpkgs { inherit config overlays; };

in
  { inherit (pkgs.haskell.packages.ghc802)
      codeworld-game-server
      codeworld-server
    ;

    inherit (pkgs) webDirectory;
  }
