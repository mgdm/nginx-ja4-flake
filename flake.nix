{
  inputs = {
    nixpkgs = { url = "github:NixOS/nixpkgs/nixos-unstable"; };
    flake-utils = { url = "github:numtide/flake-utils"; };
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        inherit (pkgs.lib) optional optionals;
        pkgs = import nixpkgs { inherit system; };

        nginx-ja4-module = {
          name = "ja4-nginx-module";
          src = let src' = pkgs.fetchFromGitHub {
            owner = "FoxIO-LLC";
            repo = "ja4-nginx-module";
            rev = "ad8d7fba6d5d7043c760639e5d95f174a3d8c88e";
            sha256 = "sha256-LZ+7n2Qy2d+Bg2bApI+235LH8P5oerZNrOcoeSQymTA=";
          }; in
            pkgs.runCommand "ja4-nginx-module" { } ''
              cp -a ${src'} $out

              # The nginx compilation with -Werror fails without this as the variable
              # is not known to be initialised in the if/else chain
              substituteInPlace $out/src/ngx_http_ssl_ja4_module.c \
                --replace 'double propagation_delay_factor;' 'double propagation_delay_factor = 1.0;'
          '';
        };

        openssl-ja4 = pkgs.openssl.overrideAttrs (drv: {
          patches = (drv.patches or [ ])
            ++ [ "${nginx-ja4-module.src}/patches/openssl.patch" ];
           # On Linux, we need to run `make update` after configuring so that the new
           # function added by the patch isn't stripped out by the linker
           postConfigure = ''
            make update
          '';
        });

        nginx-ja4 = (pkgs.nginxStable.overrideAttrs (drv: {
          patches = (drv.patches or [ ])
            ++ [ "${nginx-ja4-module.src}/patches/nginx.patch" ];
          configureFlags = drv.configureFlags ++ [ "--add-module=${nginx-ja4-module.src}/src" ];
        })).override { openssl = openssl-ja4; };

        in {
            packages = {
              nginx-ja4 = nginx-ja4;
              default = nginx-ja4;
            };
        });
  }
