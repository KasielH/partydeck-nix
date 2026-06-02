> [!IMPORTANT]
> ### Partydeck continuation 
> Partydeck development has moved to a new github orginization located at https://github.com/partydeck for the project to continue thanks to [@wunnr's](https://github.com/wunnr) help.
> [@Blahkaey](https://github.com/blahkaey) and [@davidawesome02-backup](https://github.com/davidawesome02-backup) are currently maintaining partydeck and the related handlers.
> Development efforts will continue, hopefully adding some exciting new features soon. Stay tuned for more updates.

<img src=".github/assets/icon.png" align="left" width="100" height="100">

### `PartyDeck`

A split-screen game launcher for Linux/SteamOS

---

<p align="center">
    <img src=".github/assets/launcher.png" width="49%" />
    <img src=".github/assets/gameplay1.png" width="49%" />
</p>

> [!NOTE]
> ### New discussion forum!
> The discussion forum is now open! Join the matrix server for help, to contribute to the development discussion, or just leave feedback!
> - [Matrix server](https://matrix.to/#/#partydeck:matrix.org)
> - [More information](https://github.com/partydeck/partydeck/issues/168)

> [!NOTE]
> PartyDeck is in early development, and may contain violations of software best practices and security flaws; use at your own discretion! If you are experienced in software any advice and contributions are greatly appreciated.

## Features

- Runs multiple instances of a game at a time and automatically tiles up to 4 game windows per monitor
- Supports native Linux games as well as Windows games through Proton-GE/UMU Launcher
- Handler system that tells the launcher how to handle game files, meaning very little manual setup is required
- Steam multiplayer API is emulated, allowing for multiple instances of Steam games
- Works with most game controllers without any additional setup, drivers, or third-party software
- Now works with multiple keyboards and mice!
- Now supports launching the instances across multiple monitors when using the SDL gamescope backend!
- Uses sandboxing software to mask out controllers so that each game instance only detects the controller assigned to it, preventing input interference
- Profile support allows each player to have their own persistent save data, settings, and stats for games
- Works out of the box on SteamOS

## Installing & Usage (NixOS)

This fork is packaged as a Nix flake. All dependencies — including the `gamescope-kbm` fork with keyboard/mouse device filtering — are built and bundled automatically.

Download game handlers [here](https://drive.proton.me/urls/D9HBKM18YR#zG8XC8yVy9WL).

### Requirements

- NixOS with flakes enabled. If you haven't enabled flakes yet, add this to your `configuration.nix`:

```nix
nix.settings.experimental-features = [ "nix-command" "flakes" ];
```

- GPU drivers configured:

```nix
hardware.graphics.enable = true;
```

### Try it without installing

```bash
nix run github:KasielH/partydeck-nix
```

### Install to your user profile

```bash
nix profile install github:KasielH/partydeck-nix
```

After installing, `partydeck` will be on your PATH and will appear in your app launcher.

### Add to your NixOS system flake

In your `flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    partydeck.url = "github:KasielH/partydeck-nix";
  };

  outputs = { nixpkgs, partydeck, ... }: {
    nixosConfigurations.your-hostname = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ({ pkgs, ... }: {
          environment.systemPackages = [
            partydeck.packages.x86_64-linux.default
          ];
        })
      ];
    };
  };
}
```

### SteamOS

For SteamOS, refer to the [upstream installation instructions](https://github.com/partydeck/partydeck).

### Getting Started

Once in the main menu, click the + button to add a game, or click the button with the down arrow icon to import a PartyDeck Handler package (.pd2). Create profiles if you want to store save data, and have a look through the settings menu.

## Building from source

```bash
git clone https://github.com/KasielH/partydeck-nix.git
cd partydeck-nix
nix build .#partydeck
./result/bin/partydeck
```

To build just the gamescope-kbm fork:

```bash
nix build .#gamescope-kbm
```


## How it Works

PartyDeck uses a few software layers to provide a console-like split-screen gaming experience:

- **KWin Session:** This KWin Session displays all running game instances and runs a script to automatically resize and reposition each Gamescope window.
- **Gamescope:** Contains each instance of the game to its own window. Also has the neat side effect of receiving controller input even when the window is not currently active, meaning multiple Gamescope instances can all receive input simultaneously
- **Bubblewrap:** Uses bindings to mask out evdev input files from the instances, so each instance only receives input from one specific controller. Also uses directory binding to give each player their own save data and settings within the games.
- **Runtime (Steam Runtime/Proton):** If needed, the app can run native Linux games through a Steam Runtime (currently, 1.0 (scout) and 2.0 (soldier) are supported) for better compatibility. Windows games are launched through UMU Launcher.
- **Goldberg Steam Emu:** On games that use the Steam API for multiplayer, Goldberg is used to allow the game instances to connect to each other, as well as other devices running on the same LAN.
- **And finally, the game itself.**

## Known Issues, Limitations and To-dos

- AppImages and Flatpaks are not supported yet for native Linux games. Handlers can only run regular executables inside folders.
- Controller navigation support in the launcher is super primitive; I'd love to try making a more controller-friendly, Big-Picture-style UI in the future, but have no immediate plans for it.
- Games using Goldberg might have trouble discovering LAN games from other devices. If this happens, you can try adding a firewall rule for port 47584. If connecting two Steam Decks through LAN, their hostnames should be changed from the default "steamdeck".

## Credits/Thanks

- [@wunnr](https://github.com/wunnr) for starting partydeck
- [@Blahkaey](https://github.com/blahkaey) for helping to maintain partydeck and the comunity
- [@davidawesome02-backup](https://github.com/davidawesome02-backup) for the [Gamescope keyboard/mouse fork](https://github.com/davidawesome02-backup/gamescope), and Valve for Gamescope
- [@Twig6943](https://github.com/Twig6943) for work on AppImage packaging
- [@blckink](https://github.com/blckink) for contributions
- MrGoldberg & Detanup01 for [Goldberg Steam Emu](https://github.com/Detanup01/gbe_fork/)
- GloriousEggroll and the rest of the contributors for [UMU Launcher](https://github.com/Open-Wine-Components/umu-launcher)
- Inspired by [Tau5's Coop-on-Linux](https://github.com/Tau5/Co-op-on-Linux) and [Syntrait's Splinux](https://github.com/Syntrait/splinux)
- Talos91 and the rest of the Splitscreen.me team for [Nucleus Coop](https://github.com/SplitScreen-Me/splitscreenme-nucleus), and for helping with handler creation

## Disclaimer
This software has been created purely for the purposes of academic research. It is not intended to be used to attack other systems. Project maintainers are not responsible or liable for misuse of the software. Use responsibly.
