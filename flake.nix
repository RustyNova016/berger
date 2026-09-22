{
  description = "Rust devShell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs =
    {
      nixpkgs,
      rust-overlay,
      ...
    }:
    let
      eachSupportedSystem = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;
    in
    {
      packages = eachSupportedSystem (
        system:
        let
          overlays = [ (import rust-overlay) ];

          pkgs = import nixpkgs {
            inherit system overlays;
          };
        in
        {
          default = pkgs.rustPlatform.buildRustPackage {
            pname = "berger";
            version = "0.1.0";
            src = pkgs.lib.cleanSource ./.;
            cargoLock.lockFile = ./Cargo.lock;

            buildInputs = [
              pkgs.openssl
              pkgs.gh
              pkgs.cargo-msrv
              pkgs.cargo-machete
              pkgs.cargo-nextest
            ];

            nativeBuildInputs = [
              pkgs.pkg-config
            ];
          };
        }
      );

      devShells = eachSupportedSystem (
        system:
        let
          overlays = [ (import rust-overlay) ];

          pkgs = import nixpkgs {
            inherit system overlays;
          };
        in
        {
          default =
            with pkgs;
            mkShell {
              buildInputs = [
                openssl
                pkg-config
                pkgs.gh

                # CI / Linting tools
                cargo-mutants
                cargo-hack
                cargo-msrv
                cargo-audit
                cargo-machete

                (rust-bin.stable.latest.default.override {
                  extensions = [
                    "cargo"
                    "clippy"
                    "rust-src"
                    "rust-analyzer"
                  ];
                })
              ];
            };
        }
      );
    };
}
