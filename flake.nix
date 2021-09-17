{
  description = "Nyxt browser";

  # Nixpkgs / NixOS version to use.
  inputs.nixpkgs.url = "nixpkgs/nixos-21.05";
  # Nyxt upstream.
  # NOTE: would be replaced by `self` if flake is adopted upstream.
  inputs.nyxt = {
    url = "github:atlas-engineer/nyxt/2.1.1";
    flake = false;
  };

  outputs = { self, nixpkgs, nyxt }:
    let
      version = builtins.substring 0 8 nyxt.lastModifiedDate;

      supportedSystems = [ "x86_64-linux" "x86_64-darwin" ];

      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);

      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; overlays = [ self.overlay ]; });
    in
    {
      overlay = final: prev: {
        inherit (final.lispPackages) nyxt;

        lispPackages = prev.lispPackages // {
          # Needs a more up-to-date version of this package
          cl-webkit2 = prev.lispPackages.cl-webkit2.overrideAttrs (oa: {
            src = final.fetchFromGitHub {
              owner = "joachifm";
              repo = "cl-webkit";
              rev = "90b1469713265096768fd865e64a0a70292c733d";
              sha256 = "sha256:0lxws342nh553xlk4h5lb78q4ibiwbm2hljd7f55w3csk6z7bi06";
            };
          });

          # Shamelessly stolen from nixpkgs
          nyxt = prev.lispPackages.nyxt.overrideAttrs (oa: {
            inherit version;
            src = nyxt;

            meta.mainProgram = "nyxt";
          });
        };
      };

      packages = forAllSystems (system: {
        inherit (nixpkgsFor.${system}) nyxt;
      });

      defaultPackage = forAllSystems (system: self.packages.${system}.nyxt);

      # Tests run by 'nix flake check' and by Hydra.
      checks = forAllSystems (system: {
        inherit (self.packages.${system}) nyxt;
      });
    };
}
