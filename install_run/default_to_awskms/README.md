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

3. Using awskms for auto unseal

First stop the running vault service `sudo systemctl stop vault`

Add the `seal` block in the `/etc/vault.d/vault.hcl` (we are calling it `./awskms.hcl`)

```hcl
# addition for auto seal with awskms
seal "awskms" {
       region = "us-east-1"
       kms_key_id = "arn:aws:kms:us-east-1:9750...94:key/7bf408b7-....02b8d25e6f"
}
```

Now how do we pass the auth for our vault server to access the aws kms key?

Solution 1: Use AWS auth `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`

To use this method, we create a new file `/etc/vault.d/vault.env`, it is just a standard name and path for the env file and the content of this file should be

```evn
AWS_ACCESS_KEY_ID='AKIA6....O5VWYHK'
AWS_SECRET_ACCESS_KEY='3Um8Y.....V8OybXllmX0'
AWS_REGION='us-east-1'
```


Question: Now who loads this env file? 

Answer: Our vault systemd config file

```service
[Service]
Type=notify
EnvironmentFile=/etc/vault.d/vault.env
...
ExecStart=/usr/bin/vault server -config=/etc/vault.d/vault.hcl
```

So we tell our systemd to load the `env` file from `/etc/vault.d/vault.env`




Solution 2: Use AWS role and attach the role to the EC2 instance (In the case where we have our vault server running on AWS EC2)

Question: How will vault fetch the credentials for connecting to KMS?

Answer: 

Vault, under the hood, uses the AWS SDK, which:

* First checks environment variables like AWS_ACCESS_KEY_ID.

* If not found, falls back to the instance profile credentials via IMDS (http://169.254.169.254).

* The SDK does this automatically, so no config is needed for IAM roles.



Now we can simply start our vault servie

```bash
systemctl start vault && systemctl status vault
```

```bash
root@vault-node:/etc/vault.d# vault status
Key                           Value
---                           -----
Seal Type                     awskms
Recovery Seal Type            shamir
Initialized                   true
Sealed                        true
Total Recovery Shares         3
Threshold                     2
Unseal Progress               0/2
Unseal Nonce                  n/a
Seal Migration in Progress    true
Version                       1.15.4
Build Date                    2023-12-04T17:45:28Z
Storage Type                  raft
HA Enabled                    true
```

Note: Our vault did not automatically unsealed.


Why? Bec we will have to run a migration from default key sharding to auto unseal

```bash
vault operator unseal -migrate
```

 And provide the og unseal keys (we need to run the unseal with --migrate for M times, it will unseal the vault and also migrate the sealing mechanism to auto unseal with awskms)


Now if we run `sudo systemctl restart vault` and run `vault status` we will see that vault is automatically unsealed

 Note: Even after migration and restart of vault, we can still use the same `root token`

 


Note: When using vault without TLS, we will have to use `http` instead of `https`. By default the CLI calls the `https` api endpoint, so to use CLI to work with our unsecure deployment, we must export an env variable with vault endpoint


```bash
export VAULT_ADDR='http://localhost:8200'
```


The CLI uses a token helper to cache access tokens after authenticating with vault login The default file for cached tokens is `~/.vault-token` and deleting the file forcibly logs the user out of Vault.

We can set the env variable `VAULT_TOKEN` with the token value for CLI to use for authentication api calls

```bash
export VAULT_TOKEN=hvs.xxxxxxxxxxxxxxxx
```