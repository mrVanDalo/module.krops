# module-krops

A repository to make some jobs using krops nicer.

## keys

```nix
krops.keys."foobar".path = /run/keys/foobar;
```
Will create a service `key.foobar.service` which is not started
until the key-file `/run/keys/foobar` is present.

You can reference the serivcename by `config.krops.keys."foobar".serviceName`.

### Additinal parameters

`requiredBy` will be forwarded to the `key.foobar.service` to block another serivce
from starting.

## userKeys

can be used to copy a key to a file that can be read only by the user

```nix
krops.userKeys."foobar" = {
  user = "foobar";
  source = config.krops.keys."foobar".path;
  requires = [ "${config.krops.keys."foobar".serviceName}.service" ];
  requiredBy = [ "foobar.service" ];
}
```

Will create a service `key.foobar.user.service` that waits until
the `/run/keys/foobar` is present
and than copy it to a place where it can be read by the user `foobar`.

You can reference the serivcename by `config.krops.userKeys."foobar".serviceName`.
