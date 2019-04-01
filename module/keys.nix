{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.krops.keys;

in {

  options.krops.keys = mkOption {
    type    = with types; attrsOf (submodule ({name, ... }:{
      options = {
        path = mkOption {
          type    = with types; path;
          description = ''
            path to the key file
          '';
        };
        serviceName = mkOption {
          type    = with types; str;
          default = "key.${name}";
          description = ''
            name of the key service;
          '';
        };
        requiredBy = mkOption {
          type    = with types; listOf str;
          default = [];
          description = ''
            Services that can be started and need to go down when
            depending on key availability.
          '';
        };
      };
    }));
    default = {};
    description = ''
      create services
      key."name".service which are up once the files are existing.
      use krops to deploy the keys.
    '';
  };

  config = {

    system.activationScripts.krops-keys = {
        deps = [ "users" "groups" ];
        text =
          let
            scripts = flip mapAttrsToList cfg (name: keyCfg: /* sh */ ''
              mkdir --mode 0700 --parents ${dirOf keyCfg.path}
              chown root:root ${dirOf keyCfg.path}
            '');
          in
            ''
              ${concatStringsSep "\n" scripts}
            '';
      };

    systemd.services = (flip mapAttrs' cfg (name: keyCfg:
      nameValuePair keyCfg.serviceName {
        enable = true;

        before = keyCfg.requiredBy;
        requiredBy = keyCfg.requiredBy;

        serviceConfig = {
          TimeoutStartSec = "infinity";
          Restart = "always";
          RestartSec = "100ms";
        };
        path = [ pkgs.inotifyTools ];

        preStart = /* sh */ ''
          (while read f; do if [ "$f" = "${baseNameOf keyCfg.path}" ]; then break; fi; done \
            < <(inotifywait --quiet --monitor --format '%f' --event create,move ${dirOf keyCfg.path}) ) &

          # check if already exists
          if [[ -e "${keyCfg.path}" ]]
          then
            echo 'flapped down'
            kill %1
            exit 0
          fi

          # wait for inotifywait
          wait %1
        '';

        script = /* sh */ ''
          inotifywait --quiet --event delete_self "${keyCfg.path}" &
          if [[ ! -e "${keyCfg.path}" ]]; then
            echo 'flapped up'
            exit 0
          fi

          # wait for inotifywait
          wait %1
        '';

      }
    ));

  };

}
