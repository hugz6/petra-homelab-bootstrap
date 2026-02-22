{
  description = "Flake for my Homelab Bootstrap Repo.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        
        pythonEnv = pkgs.python3.withPackages (ps: with ps; [
          netaddr
          jinja2
          ruamel-yaml
          jmespath
          cryptography
        ]);
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = [
	    pkgs.terraform
            pkgs.go-task
            pythonEnv
            pkgs.ansible_2_17
          ];

          shellHook = ''
            echo "Homelab Bootstrap Flake Environment loaded."
          '';
        };
      }
    );
}
