pkgsNew: pkgsOld:

let
  sourceOverrides =
    pkgsNew.haskell.lib.packageSourceOverrides {
      ghcjs-dom-jsffi = "0.8.0.0";

      ghcjs-dom = "0.8.0.0";

      codeworld-api = ../codeworld-api;

      codeworld-base = ../codeworld-base;

      codeworld-compiler = ../codeworld-compiler;

      codeworld-error-sanitizer = ../codeworld-error-sanitizer;

      codeworld-game-api = ../codeworld-game-api;

      codeworld-game-server = ../codeworld-game-server;

      codeworld-prediction = ../codeworld-prediction;

      codeworld-server = ../codeworld-server;
    };

  manualOverrides = haskellPackagesNew: haskellPackagesOld: {
    # `haddock` fails on packages with no modules:
    #
    # https://github.com/haskell/cabal/issues/944
    bytestring-builder =
      pkgsNew.haskell.lib.dontHaddock haskellPackagesOld.bytestring-builder;

    # `haddock` fails on packages with no modules:
    #
    # https://github.com/haskell/cabal/issues/944
    ghcjs-dom =
      pkgsNew.haskell.lib.dontHaddock haskellPackagesOld.ghcjs-dom;
  };

in
  { haskell = pkgsOld.haskell // {
      packages = pkgsOld.haskell.packages // {
        ghcjsHEAD = pkgsOld.haskell.packages.ghcjsHEAD.override {
          overrides =
            pkgsNew.lib.composeExtensions
              sourceOverrides
              manualOverrides;
        };
      };
    };
  }
