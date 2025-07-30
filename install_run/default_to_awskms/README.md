## Migrating the vault cluster from keysharding to autounseal with awskms

1. Create a standalone deployment of vault server with RAFT protocol backend storage

`/etc/vault.d/bare_minimum.hcl`

To initialize the vault server

```sh
vault operator init -key-shares=3 -key-threshold=2
```

Note: The vault will read the config from `/etc/vault.d/bare_minimum.hcl`

Question: How will vault will know where to read from config?

Answer: It is defined in vault startup command, we mostly start vault with systemd. So we can first find out there is systemd config is written.

```sh
systemctl status vault
```

output:

```sh
root@vault-node:/etc/systemd/system# systemctl status vault

● vault.service - "HashiCorp Vault - A tool for managing secrets"
     Loaded: loaded (/lib/systemd/system/vault.service; disabled; vendor preset: enabled)
     Active: active (running) since Wed 2025-07-30 12:24:49 EDT; 8min ago
● vault.service - "HashiCorp Vault - A tool for managing secrets"
     Loaded: loaded (/lib/systemd/system/vault.service; disabled; vendor preset: enabled)
     Active: active (running) since Wed 2025-07-30 12:24:49 EDT; 8min ago
       Docs: https://developer.hashicorp.com/vault/docs
   Main PID: 1249 (vault)
      Tasks: 13 (limit: 77143)
     Memory: 31.9M
     CGroup: /system.slice/vault.service
             └─1249 /usr/bin/vault server -config=/etc/vault.d/vault.hcl

```

Clearly the systemd config is at `/lib/systemd/system/vault.service`

If we see the file content, we will see it runs `/usr/bin/vault server -config=/etc/vault.d/vault.hcl`

And it clearly states the config file location `/etc/vault.d/vault.hcl` and we used the name of `bare_minimum.hcl`, we either we will have to change the systemd config or rename our `.hcl` file name.

2. Initialize the bare minimum vault server with key sharding with N/M of 3/2

```sh
vault operator init -key-shares=3 -key-threshold=2
```

Output:

```sh
Unseal Key 1: RbGIj5vfLN1VOwD....K4p1KNNs4g
Unseal Key 2: 8QyX7VGKAa....nzTbEM4S20VvDUK
Unseal Key 3: Tq5uZ0j0a....40mmST556mlo

Initial Root Token: hvs.nckA...0sB4aWD

Vault initialized with 3 key shares and a key threshold of 2. Please securely
distribute the key shares printed above. When the Vault is re-sealed,
restarted, or stopped, you must supply at least 2 of these keys to unseal it
before it can start servicing requests.

Vault does not store the generated root key. Without at least 2 keys to
reconstruct the root key, Vault will remain permanently sealed!

It is possible to generate new unseal keys, provided you have a quorum of
existing unseal keys shares. See "vault operator rekey" for more information.
```


