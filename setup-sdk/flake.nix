{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

    zephyr-nix.url = "github:urob/zephyr-nix";
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
              west
              pyelftools
              pyyaml
            ]))
          ];
        in
        rec {
          gnuarmemb = pkgs.mkShellNoCC {
            packages = shared_pkgs ++ [ pkgs.gcc-arm-embedded ];
            env = {
              ZEPHYR_TOOLCHAIN_VARIANT = "gnuarmemb";
              GNUARMEMB_TOOLCHAIN_PATH = pkgs.gcc-arm-embedded;
            };
          };

          zephyr = pkgs.mkShellNoCC {
            packages = shared_pkgs ++ [ (zephyr_.sdk-0_16.override { targets = [ "arm-zephyr-eabi" ]; }) ];
            env = {
              ZEPHYR_TOOLCHAIN_VARIANT = "zephyr";
            };
          };

          default = zephyr;
        });

      formatter = forAllSystems ({ pkgs, ... }: pkgs.nixpkgs-fmt);
    };
}
