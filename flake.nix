{
  description = "PartyDeck — split-screen game launcher for Linux/SteamOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (
      system:
      let
        pkgs = import nixpkgs { inherit system; };

        # ── gamescope-kbm ──────────────────────────────────────────────────────
        # PartyDeck's gamescope fork with keyboard/mouse device-filtering support.
        # Overrides upstream gamescope; intentionally not put on PATH globally —
        # partydeck wraps itself so that only gamescope-kbm is visible at runtime.
        gamescope-kbm = pkgs.gamescope.overrideAttrs (
          _finalAttrs: previousAttrs: {
            pname = "gamescope-kbm";
            version = "0-unstable-2026-03-11";

            src = pkgs.fetchFromGitHub {
              owner = "partydeck";
              repo = "gamescope";
              rev = "074c4f6f6f07d473af995717cc647e43efef741c";
              fetchSubmodules = true;
              hash = "sha256-IHxM1j2HMf5hC2GjTq4fI3qs3ev/AFwP2CPcyF6203o=";
            };

            patches = (previousAttrs.patches or [ ]) ++ [
              ./patches/gamescope-kbm-no-inhibit-shortcuts.patch
            ];

            mesonFlags = previousAttrs.mesonFlags ++ [
              (pkgs.lib.mesonOption "benchmark" "disabled")
              # libei / XTEST is not needed for PartyDeck's use-case
              (pkgs.lib.mesonOption "input_emulation" "disabled")
            ];

            # Rename the binary so it can coexist with stock gamescope and so
            # partydeck's wrapper can put only this one on PATH.
            postInstall =
              ''
                mv $out/bin/gamescope $out/bin/gamescope-kbm
              ''
              + builtins.replaceStrings [ "$out/bin/gamescope" ] [ "$out/bin/gamescope-kbm" ]
                previousAttrs.postInstall;

            passthru = { };

            meta = previousAttrs.meta // {
              description = "Gamescope fork with keyboard and mouse device filtering support";
              homepage = "https://github.com/partydeck/gamescope";
              mainProgram = "gamescope-kbm";
            };
          }
        );

        # ── Goldberg Steam Emu ─────────────────────────────────────────────────
        # Pre-built release binaries from gbe_fork.  PartyDeck needs both the
        # 64-bit and 32-bit shared libraries/executables at runtime to emulate
        # the Steam API across multiple game instances.
        #
        # To update: grab the tarball URL from
        #   https://github.com/Detanup01/gbe_fork/releases
        # and run:
        #   nix-prefetch-url --unpack <url>
        goldberg =
          let
            version = "release-2026_03_10";
          in
          pkgs.fetchzip {
            url = "https://github.com/Detanup01/gbe_fork/releases/download/${version}/emu-linux-release.tar.bz2";
            # Run `nix-prefetch-url --unpack <url>` and paste the hash here:
            hash = "sha256-tBqjc1FRxQ2foZvg24WdcS5gDWgF8m6ReJeluqxfWrk=";
          };
        goldberg-win =
          let
            version = "release-2026_03_10";
          in
          pkgs.fetchurl {
            url = "https://github.com/Detanup01/gbe_fork/releases/download/${version}/emu-win-release.7z";
            hash = "sha256-D2ekISqk5qcfhIeaOgD2dcsqjEPhPjjgsnq1yeal5l8=";
          };

        # ── partydeck ──────────────────────────────────────────────────────────
        partydeck = pkgs.rustPlatform.buildRustPackage (finalAttrs: {
          pname = "partydeck";
          version = "0.8.6";

          src = ./.;

          cargoHash = "sha256-L2FHN+H18qA01lFPLdsZnZGyYUW6y7Qa2VOtjbStO5A=";

          strictDeps = true;

          nativeBuildInputs = [
            pkgs.makeBinaryWrapper
            pkgs.pkg-config
            pkgs.p7zip
          ];

          buildInputs = [
            pkgs.fontconfig
            pkgs.libGL
            pkgs.libx11
            pkgs.libxcursor
            pkgs.libxi
            pkgs.libxkbcommon
            pkgs.libxrandr
            pkgs.openssl
            pkgs.wayland
          ];

          runtimeDeps = [
            pkgs.bubblewrap
            pkgs.fuse-overlayfs
            gamescope-kbm
            pkgs.umu-launcher
            pkgs.util-linux
            pkgs.xdg-utils
          ];


          # Redirect the hard-coded /usr/share/partydeck path so the binary finds
          # its bundled assets (JS glue, Goldberg, GamingModeLauncher, etc.) in
          # the Nix store.
          postPatch = ''
            substituteInPlace src/paths.rs \
              --replace-fail 'PathBuf::from("/usr/share/partydeck")' \
              'PathBuf::from("${placeholder "out"}/share/partydeck")'
          '';

          postInstall = ''
            # JS + PNG assets used by the launcher UI
            install -Dm644 res/*.js  -t $out/share/partydeck
            install -Dm644 res/*.png -t $out/share/partydeck
            install -Dm755 res/GamingModeLauncher.sh -t $out/share/partydeck

            # ── Goldberg Steam Emu ────────────────────────────────────────────
            # The pre-built Goldberg release tarball ships a x64/ and x32/
            # directory.  PartyDeck expects them at share/partydeck/goldberg/.
            install -dm755 $out/share/partydeck/goldberg
            cp -r ${goldberg}/regular/x64 $out/share/partydeck/goldberg/linux64
            cp -r ${goldberg}/regular/x32 $out/share/partydeck/goldberg/linux32

            7z x ${goldberg-win} -o$TMPDIR/goldberg-win
            install -dm755 $out/share/partydeck/goldberg/win
            cp $TMPDIR/goldberg-win/release/regular/x32/steam_api.dll $out/share/partydeck/goldberg/win/
            cp $TMPDIR/goldberg-win/release/regular/x64/steam_api64.dll $out/share/partydeck/goldberg/win/
            cp $TMPDIR/goldberg-win/release/steamclient_experimental/steamclient.dll $out/share/partydeck/goldberg/win/
            cp $TMPDIR/goldberg-win/release/steamclient_experimental/steamclient64.dll $out/share/partydeck/goldberg/win/
            cp $TMPDIR/goldberg-win/release/steamclient_experimental/GameOverlayRenderer.dll $out/share/partydeck/goldberg/win/
            cp $TMPDIR/goldberg-win/release/steamclient_experimental/GameOverlayRenderer64.dll $out/share/partydeck/goldberg/win/
          '';

          postFixup = pkgs.lib.optionalString pkgs.stdenv.hostPlatform.isLinux ''
            wrapProgram $out/bin/partydeck \
              --prefix LD_LIBRARY_PATH : "${pkgs.lib.makeLibraryPath finalAttrs.buildInputs}:/run/opengl-driver/lib" \
              --prefix PATH : "${pkgs.lib.makeBinPath finalAttrs.runtimeDeps}"
          '';

          meta = {
            description = "Split-screen game launcher for Linux and SteamOS";
            homepage = "https://github.com/partydeck/partydeck";
            changelog = "https://github.com/partydeck/partydeck/releases/tag/v${finalAttrs.version}";
            license = pkgs.lib.licenses.mit;
            mainProgram = "partydeck";
            platforms = pkgs.lib.platforms.linux;
          };
        });
      in
      {
        packages = {
          inherit gamescope-kbm partydeck;
          default = partydeck;
        };

        # `nix run github:partydeck/partydeck`
        apps.default = flake-utils.lib.mkApp { drv = partydeck; };

        # `nix develop` — drop into a shell with all build deps available
        devShells.default = pkgs.mkShell {
          inputsFrom = [ partydeck ];
          packages = [ pkgs.rust-analyzer ];
        };
      }
    );
}
