{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.krops.userKeys;

in {

  # user keys
  options.krops.userKeys = mkOption {
    type    = with types; attrsOf (submodule ({name, ... }:{
      options = {
        user = mkOption {
          type    = with types; str;
          description = ''
            user who should own the file or folder
          '';
        };
        serviceName = mkOption {
          type    = with types; str;
          default = "key.${config.krops.userKeys.${name}.user}.${name}";
          description = ''
            name of the copy serice
          '';
        };
        requires = mkOption {
          type    = with types; listOf str;
          default = [];
          description = ''
            list of services which are needed to run before this service runs.
          '';
        };
        requiredBy = mkOption {
          type    = with types; listOf str;
          default = [];
          description = ''
            list of services which depend on this service
          '';
        };
        target = mkOption {
          type    = with types; path;
          default = "/run/keys.${config.krops.userKeys.${name}.user}/${name}";
          description = ''
            where to copyt the file to
          '';
        };
        source = mkOption {
          type    = with types; path;
          description = ''
            where to copyt the file from
          '';
        };
      };
    }));
    default = {};
    description = ''
      services that copy secrets to a place where only this user can read them.
    '';
  };

  config = {

    systemd.services = (flip mapAttrs' cfg (name: keyCfg:
      nameValuePair keyCfg.serviceName {
        enable = true;

        before = keyCfg.requiredBy;
        requiredBy = keyCfg.requiredBy;
        after = keyCfg.requires;
        requires = keyCfg.requires;

        serviceConfig.TimeoutStartSec = "infinity";
        serviceConfig.Restart = "always";
        serviceConfig.RestartSec = "100ms";
        path = [ pkgs.inotifyTools ];

        script = /* sh */ ''
          rm -rf ${keyCfg.target}
          mkdir -p ${dirOf keyCfg.target}
          chmod 755 ${dirOf keyCfg.target}
          cp -r ${keyCfg.source} ${keyCfg.target}
          chown -R ${keyCfg.user} ${keyCfg.target}
          chmod -R 700 ${keyCfg.target}

          inotifywait --quiet --event delete_self "${keyCfg.target}" &
          if [[ ! -e "${keyCfg.target}" ]]; then
            echo 'flapped up'
            exit 0
          fi
          wait %1
        '';
      }
    ));




  };
}
