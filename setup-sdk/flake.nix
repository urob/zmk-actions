{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

    # Only affects which requirements.txt is sourced by pythonEnv
    zephyr.url = "github:zmkfirmware/zephyr/v3.5.0+zmk-fixes";
    zephyr.flake = false;

    # Zephyr sdk and toolchain
    zephyr-nix.url = "github:urob/zephyr-nix";
    zephyr-nix.inputs.zephyr.follows = "zephyr";
    zephyr-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, zephyr-nix, ... }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f {
        pkgs = nixpkgs.legacyPackages.${system};
        zephyr_ = zephyr-nix.packages.${system};
      });
    in
    {
      devShells = forAllSystems ({ pkgs, zephyr_ }:
        let
          shared_pkgs = [
            pkgs.cmake
            pkgs.dtc
            pkgs.ninja

            (pkgs.python3.withPackages (ps: with ps; [
              ps.west
              ps.pyelftools
              ps.pyyaml
            ]))
          ];
        in
        rec {
          gnuarmemb = pkgs.mkShellNoCC {
            packages = shared_pkgs ++ [ pkgs.gcc-arm-embedded ];

            env = {
              ZEPHYR_TOOLCHAIN_VARIANT = "gnuarmemb";
              GNUARMEMB_TOOLCHAIN_PATH = pkgs.gcc-arm-embedded;
              ZEPHYR_VERSION = "3.5.0";
            };
          };

          zephyr = pkgs.mkShellNoCC {
            packages = shared_pkgs ++ [ (zephyr_.sdk-0_16.override { targets = [ "arm-zephyr-eabi" ]; }) ];

            env = {
              ZEPHYR_TOOLCHAIN_VARIANT = "zephyr";
              ZEPHYR_VERSION = "3.5.0";
            };
          };

          default = gnuarmemb;
        });

      formatter = forAllSystems ({ pkgs, ... }: pkgs.nixpkgs-fmt);
    };
}
