{
  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        inherit (pkgs.lib) optional optionals;
        pkgs = import nixpkgs { inherit system; };

        nginx-ja4-module = {
          name = "ja4-nginx-module";
          src =
            let
              src' = pkgs.fetchFromGitHub {
                owner = "FoxIO-LLC";
                repo = "ja4-nginx-module";
                rev = "cd16673ded88fcb7f5ca2d3cca2235b1be046b16";
                sha256 = "sha256-JJq9QIxhSlw+kS9Rnes3IJOdErQaN0MZXM9qziccT04=";
              };
            in
            pkgs.runCommand "ja4-nginx-module" { } ''
              cp -a ${src'} $out

              # The nginx compilation with -Werror fails without this as the variable
              # is not known to be initialised in the if/else chain
              substituteInPlace $out/src/ngx_http_ssl_ja4_module.c \
                --replace 'double propagation_delay_factor;' 'double propagation_delay_factor = 1.0;'
            '';
        };

        nginx-ja4 = (
          pkgs.nginxStable.overrideAttrs (drv: {
            patches = (drv.patches or [ ]) ++ [
              "${nginx-ja4-module.src}/patches/nginx-ssl-save-client-hello.patch"
            ];
            configureFlags = drv.configureFlags ++ [ "--add-module=${nginx-ja4-module.src}" ];
          })
        );

      in
      {
        packages = {
          nginx-ja4 = nginx-ja4;
          default = nginx-ja4;
        };
      }
    );
}
