{
  description = "OBS Studio with replay-source plugin and srtrelay";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        obs = pkgs.wrapOBS {
          plugins = with pkgs.obs-studio-plugins; [
            obs-replay-source
          ];
        };
      in
      {
        packages = {
          inherit obs;
          inherit (pkgs) srtrelay;
          default = obs;
        };

        apps = {
          obs = {
            type = "app";
            program = "${obs}/bin/obs";
          };
          srtrelay = {
            type = "app";
            program = "${pkgs.srtrelay}/bin/srtrelay";
          };
          default = self.apps.${system}.obs;
        };

        devShells.default = pkgs.mkShell {
          packages = [ obs pkgs.srtrelay ];
        };
      });
}
