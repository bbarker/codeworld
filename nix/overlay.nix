pkgsNew: pkgsOld:

let
  codeworldSourceOverrides =
    pkgsNew.haskell.lib.packageSourceOverrides {
      codeworld-base = ../codeworld-base;

      codeworld-account = ../codeworld-account;

      codeworld-api = ../codeworld-api;

      codeworld-auth = ../codeworld-auth;

      codeworld-compiler = ../codeworld-compiler;

      codeworld-error-sanitizer = ../codeworld-error-sanitizer;

      codeworld-game-api = ../codeworld-game-api;

      codeworld-game-server = ../codeworld-game-server;

      codeworld-prediction = ../codeworld-prediction;

      codeworld-server = ../codeworld-server;

      funblocks-client = ../funblocks-client;
    };

  nativeSourceOverrides =
    pkgsNew.haskell.lib.packageSourceOverrides {
      blank-canvas = "0.6.2";
    };

  nativeOverrides = haskellPackagesNew: haskellPackagesOld: {
    # The test suite hangs
    blank-canvas =
      pkgsNew.haskell.lib.dontCheck haskellPackagesOld.blank-canvas;

    codeworld-compiler =
      pkgsNew.haskell.lib.addBuildDepend
        haskellPackagesOld.codeworld-compiler
        (pkgsNew.haskell.packages.ghcjs.ghcWithPackages
          (haskellPackages: [
              haskellPackages.codeworld-api
              haskellPackages.codeworld-base
              haskellPackages.codeworld-error-sanitizer
              haskellPackages.codeworld-game-api
              haskellPackages.codeworld-prediction
            ]
          )
        );

    # `concurrent-output` has an upper bound on `process` that is too tight
    # Latest version of `concurrent-output` doesn't build against
    # the `process-1.4.3.0` package that ships with `ghc-8.0.2`.  It's simpler
    # to jailbreak `concurrent-output` than to downgrade it (which requires
    # downgrading other packages, too)
    concurrent-output =
      pkgsNew.haskell.lib.doJailbreak haskellPackagesOld.concurrent-output;

    # `filesystem-trees` has an upper bound of `directory < 1.3`, but
    # `ghc-8.0.2` ships with directory-1.3.0.0`.  Rather than downgrade to
    # `ghc-8.0.1` (which ships with `directory-1.2.6.2`) we can instead
    # jailbreak `filesystem-trees`
    filesystem-trees =
      pkgsNew.haskell.lib.doJailbreak haskellPackagesOld.filesystem-trees;

    # Fix test failure:
    #
    # https://github.com/RyanGlScott/text-show/issues/36
    text-show =
      pkgsNew.haskell.lib.appendPatch
        haskellPackagesOld.text-show
        (pkgsNew.fetchpatch {
            url = "https://github.com/RyanGlScott/text-show/commit/1ee6beff85c159dc1dfca5baf160b9e607a05901.patch";

            sha256 = "163s874q6fsay30hvxwy3xbpsgfqb1gnjxjjr74rbnjksw7bl4w2";
          }
        );
  };

  ghcjsSourceOverrides =
    pkgsNew.haskell.lib.packageSourceOverrides {
      # `codeworld-api` requires downgrading `ghcjs-dom` and `ghcjs-dom-jsffi`

      ghcjs-dom = "0.8.0.0";

      ghcjs-dom-jsffi = "0.8.0.0";
    };

  ghcjsOverrides = haskellPackagesNew: haskellPackagesOld: {
    # `haddock` fails on `bytestring-builder` and `ghcjs-dom` because they have
    # no modules:
    #
    # https://github.com/haskell/cabal/issues/944

    bytestring-builder =
      pkgsNew.haskell.lib.dontHaddock haskellPackagesOld.bytestring-builder;

    ghcjs-dom =
      pkgsNew.haskell.lib.dontHaddock haskellPackagesOld.ghcjs-dom;
  };

in
  { haskell = pkgsOld.haskell // {
      packages = pkgsOld.haskell.packages // {
        # The GHC and GHCJS versions must match.  They are both version 8.0.2 in
        # this configuration
        ghc802 = pkgsOld.haskell.packages.ghc802.override {
          overrides =
            pkgsNew.lib.fold pkgsNew.lib.composeExtensions (_: _: {}) [
              codeworldSourceOverrides
              nativeSourceOverrides
              nativeOverrides
            ];
        };

        ghcjs = pkgsOld.haskell.packages.ghcjs.override {
          overrides =
            pkgsNew.lib.fold pkgsNew.lib.composeExtensions (_: _: {}) [
              codeworldSourceOverrides
              ghcjsSourceOverrides
              ghcjsOverrides
            ];
        };
      };
    };

    codemirrorNix =
      let
        src =
          pkgsNew.fetchFromGitHub {
            owner = "codemirror";

            repo = "CodeMirror";

            rev = "5.25.2";

            sha256 = "0l7wjdkria4iylykqj1k15cxa09kcyw477rbjbgfdbwzcwhnw1lc";
          };

      in
        pkgsNew.runCommand "codemirror" {} ''
          mkdir $out

          ${pkgsNew.nodePackages.node2nix}/bin/node2nix --development --input ${src}/package.json --output $out/node-packages.nix --node-env $out/node-env.nix --composition $out/default.nix
        '';

    nodeEnv = pkgsNew.callPackage "${pkgsNew.codemirrorNix}/node-env.nix" { };

    codemirror =
      pkgsNew.callPackage "${pkgsNew.codemirrorNix}/node-packages.nix" { };

    codemirrorCompressed =
      let
        components = pkgsNew.lib.concatStringsSep " " [
          "codemirror"
          "haskell"
          "active-line"
          "annotatescrollbar"
          "dialog"
          "match-highlighter"
          "matchbrackets"
          "matchesonscrollbar"
          "placeholder"
          "rulers"
          "runmode"
          "search"
          "searchcursor"
          "show-hint"
        ];

      in
        pkgsNew.runCommand "codemirror-compressed" {} ''
          cp -R ${pkgsNew.codemirror.package} $out
          chmod -R u+w $out
          cd $out/lib/node_modules/codemirror
          bin/compress ${components} --local ${pkgsNew.nodePackages.uglify-js}/bin/uglifyjs > codemirror-compressed.js
        '';

    webDirectory =
      pkgsNew.runCommand "web" {} ''
        cp -R ${../web} $out
        chmod -R u+w $out
        for suffix in lib out rts runmain; do
          ln -sf ${pkgsNew.haskell.packages.ghcjs.funblocks-client}/bin/funblocks-client.jsexe/$suffix.js $out/js/blocks_$suffix.js
        done
        ln -sf ${pkgsNew.codemirrorCompressed}/lib/node_modules/codemirror/codemirror-compressed.js $out/js/codemirror-compressed.js
        ln -sf ${../third_party/CodeMirror/function-highlight-addon.js} $out/js/function-highlight-addon.js
      '';
  }
