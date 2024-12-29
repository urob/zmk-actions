{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

    # Version of requirements.txt installed in pythonEnv
    zephyr.url = "github:zephyrproject-rtos/zephyr/v3.5.0";
    zephyr.flake = false;

    # Zephyr sdk and toolchain
    zephyr-nix.url = "github:adisbladis/zephyr-nix";
    zephyr-nix.inputs.zephyr.follows = "zephyr";
    zephyr-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, zephyr-nix, ... }: let
    systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
    forAllSystems = nixpkgs.lib.genAttrs systems;
  in {
    devShells = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      zephyr = zephyr-nix.packages.${system};

    in {
      default = pkgs.mkShellNoCC {
        buildInputs = [
          # zephyr.pythonEnv

          # (zephyr.sdk-0_16.override { targets = [ "arm-zephyr-eabi" ]; })
          pkgs.gcc-arm-embedded

          pkgs.cmake
          pkgs.dtc
          pkgs.ninja

          (pkgs.python3.withPackages (ps: with ps; [
            ps.west
            ps.pyelftools
            ps.pyyaml
          ]))

          # pkgs.qemu # needed for native_posix target
        ];

        env = {
          ZEPHYR_TOOLCHAIN_VARIANT = "gnuarmemb";
          GNUARMEMB_TOOLCHAIN_PATH = pkgs.gcc-arm-embedded;
          ZEPHYR_VERSION = "3.5.0";
        };
      };
    });
  };
}
