# What is this?
[JA4+](https://blog.foxio.io/ja4+-network-fingerprinting) is a set of techniques for network fingerprinting. The most common version is used to identify TLS clients and servers.

[FoxIO-LLC/ja4-nginx-module](https://github.com/FoxIO-LLC/ja4-nginx-module) adds this functionality to nginx.

This repo lets you use the module from a Flakes-based Nix configuration.

# How do I use this?

Add this repo to your flake inputs:

```nix
inputs = {
  # ...
  nginx-ja4.url = "github:mgdm/nginx-ja4-flake";
};
```

In your system configuration, do something like this:

```nix
let
  nginx-ja4 = inputs.nginx-ja4.packages."${pkgs.system}".default;
in
  # NixOS configuration goes here
  services.nginx = {
    enable = true;
    package = nginx-ja4;

    # to expose the JA4 fingerprint to a FastCGI application such as PHP,
    # do something like this. I put it at the top level (`http`) to avoid issues
    # when redefining fastcgi_params in location or server blocks
    commonHttpConfig = ''
      # ...
      fastcgi_param HTTP_JA4_FINGERPRINT $http_ssl_ja4;
      # ...
    '';

    # to expose the JA4 details to proxied HTTP applications, do something like
    locations."/" = {
      proxyPass = "http://localhost:3000";
      extraConfig = ''
        proxy_set_header JA4_FINGERPRINT  $http_ssl_ja4;
      '';
    };

    # ...
  };
```

