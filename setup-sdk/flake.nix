{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    zephyr-nix.url = "github:urob/zephyr-nix/zephyr-4.1";
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
          cmake = [
            pkgs.cmake
            pkgs.dtc
            pkgs.ninja
          ];

          pythonSmall = [
            (pkgs.python3.withPackages (ps: with ps; [
              west
              pyelftools
              pyyaml
            ]))
          ];

          pythonFull = [
            (zephyr_.pythonEnv.override {
              extraPackages = ps: [ ps.setuptools ];
            })
          ];
        in
        rec {
          gnuarmemb = pkgs.mkShellNoCC {
            packages = cmake ++ pythonSmall ++ [ pkgs.gcc-arm-embedded ];
            env = {
              ZEPHYR_TOOLCHAIN_VARIANT = "gnuarmemb";
              GNUARMEMB_TOOLCHAIN_PATH = pkgs.gcc-arm-embedded;
            };
          };

          zephyr = pkgs.mkShellNoCC {
            packages = cmake ++ pythonSmall ++ [ (zephyr_.sdk-0_17.override { targets = [ "arm-zephyr-eabi" ]; }) ];
            env = {
              ZEPHYR_TOOLCHAIN_VARIANT = "zephyr";
            };
          };

          zephyr-full = pkgs.mkShellNoCC {
            packages = cmake ++ pythonFull ++ [ (zephyr_.sdk-0_17.override { targets = [ "arm-zephyr-eabi" ]; }) ];
            env = {
              ZEPHYR_TOOLCHAIN_VARIANT = "zephyr";
              PYTHONPATH = "${zephyr_.pythonEnv}/${zephyr_.pythonEnv.sitePackages}";
            };
          };

          default = zephyr;
        });

      formatter = forAllSystems ({ pkgs, ... }: pkgs.nixpkgs-fmt);
    };
}
