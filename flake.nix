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
          });

          # nyxt = with final; lispPackages.buildLispPackage rec {
          #   baseName = "nyxt";
          #   inherit version;

          #   description = "Nyxt browser";

          #   overrides = x: {
          #     postInstall = ''
          #       echo "Building nyxt binary"
          #       (
          #         source "$out/lib/common-lisp-settings"/*-shell-config.sh
          #         cd "$out/lib/common-lisp"/*/
          #         makeFlags="''${makeFlags:-}"
          #         make LISP=common-lisp.sh NYXT_INTERNAL_QUICKLISP=false PREFIX="$out" $makeFlags all
          #         make LISP=common-lisp.sh NYXT_INTERNAL_QUICKLISP=false PREFIX="$out" $makeFlags install
          #         cp nyxt "$out/bin/nyxt"
          #       )
          #       NIX_LISP_PRELAUNCH_HOOK='
          #         nix_lisp_build_system nyxt/gtk-application \
          #         "(asdf/system:component-entry-point (asdf:find-system :nyxt/gtk-application))" \
          #         "" "(format *error-output* \"Alien objects:~%~s~%\" sb-alien::*shared-objects*)"
          #       ' "$out/bin/nyxt-lisp-launcher.sh"
          #       cp "$out/lib/common-lisp/nyxt/nyxt" "$out/bin/"
          #     '';
          #   };

          #   deps = with pkgs.lispPackages; [
          #     alexandria
          #     bordeaux-threads
          #     calispel
          #     cl-css
          #     cl-json
          #     cl-markup
          #     cl-ppcre
          #     cl-ppcre-unicode
          #     cl-prevalence
          #     closer-mop
          #     cl-containers
          #     cluffer
          #     moptilities
          #     dexador
          #     enchant
          #     file-attributes
          #     iolib
          #     local-time
          #     log4cl
          #     mk-string-metrics
          #     osicat
          #     parenscript
          #     quri
          #     serapeum
          #     str
          #     plump
          #     swank
          #     trivia
          #     trivial-clipboard
          #     trivial-features
          #     trivial-package-local-nicknames
          #     trivial-types
          #     unix-opts
          #     cl-html-diff
          #     hu_dot_dwim_dot_defclass-star
          #     cl-custom-hash-table
          #     fset
          #     cl-cffi-gtk
          #     cl-webkit2-nyxt
          #     cl-gobject-introspection
          #   ];

          #   src = nyxt;

          #   packageName = "nyxt";

          #   propagatedBuildInputs = [
          #     pkgs.libressl.out
          #     pkgs.webkitgtk
          #     pkgs.sbcl
          #   ];
          # };
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
