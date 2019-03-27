# module-krops

A repository to make make some jobs using krops nicer.

## keys

```nix
krops.keys."foobar".path = /run/keys/foobar;
```
Will create a service `key.foobar.service` which can be used
to wait until the key-file `/run/keys/foobar` is present.

You can reference the serivename by `config.krops.keys."foobar".serviceName`.

### Additinal parameters

`requiredBy` will be forwarded to the `key.foobar.service` to block another serivce
from starting.

## userKeys

can be used to copy a key to a file that can be read by a user

```nix
krops.userKeys = {
  user = "foobar";
  source = config.krops.keys."foobar".path;
  requires = [ "${config.krops.keys."foobar".serviceName}.service" ];
  requireBy = [ "foobar.service" ];
}
```
Will create a service that waits until the `/run/keys/foobar` is present
and than copy it to a place where it can be read by the user `foobar`.


