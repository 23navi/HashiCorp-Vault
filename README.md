# HashiCorp-Vault

### Important links:

* [Deploying production vault HA cluster using RAFT](https://developer.hashicorp.com/vault/tutorials/raft/raft-deployment-guide)


Now, to validate the configuration file before using it by the vault service. Use the following command: -

```sh
vault operator diagnose -config=/etc/vault.d/vault.hcl
```