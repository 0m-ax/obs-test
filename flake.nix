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
          packages = [
            obs
            pkgs.srtrelay
            pkgs.gst_all_1.gstreamer
            pkgs.gst_all_1.gst-plugins-base
            pkgs.gst_all_1.gst-plugins-good
            pkgs.gst_all_1.gst-plugins-bad
            pkgs.gst_all_1.gst-plugins-ugly
            pkgs.gst_all_1.gst-libav
          ];

          shellHook = ''
            export GST_PLUGIN_PATH="${pkgs.lib.makeSearchPath "lib/gstreamer-1.0" (with pkgs.gst_all_1; [
              gstreamer gst-plugins-base gst-plugins-good gst-plugins-bad gst-plugins-ugly gst-libav
            ])}"
          '';
        };
      });
}
