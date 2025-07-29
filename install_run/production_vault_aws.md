## To install vault and run it as service using serviced in aws ec2

[Hashicorp installation documentation](https://developer.hashicorp.com/vault/install)

```sh
sudo yum install -y yum-utils shadow-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo yum -y install vault
```


Now we can create a service config file to start vault as systemd service.

```sh
cd /etc/systemd/system
sudo vim vault.service
```
Add the details from `./vault.service`


Production deployment of vault requires a configuration file.

```sh
ExecStart=/usr/local/bin/vault server -config=/etc/vault.d/vault.hcl
```

So we will define the `/etc/vault.d/vault.hcl` config

Note: `.hcl` is HCL, or HashiCorp Configuration Language (domain-specific language developed by HashiCorp. Its primary purpose is to define structured configurations in a human-readable and machine-friendly format, particularly for infrastructure as code (IaC) tools)

