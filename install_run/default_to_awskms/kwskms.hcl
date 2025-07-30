storage "raft" {
  path    = "/opt/vault/data"
  node_id = "vault-node"
}

listener "tcp" {
 address = "0.0.0.0:8200"
 cluster_address = "0.0.0.0:8201"
 tls_disable = true
}

# addition for auto seal with awskms
seal "awskms" {
       region = "us-east-1"
       kms_key_id = "arn:aws:kms:us-east-1:9750...94:key/7bf408b7-....02b8d25e6f"
}

api_addr = "http://vault-node:8200"
cluster_addr = "http://vault-node:8201"
cluster_name = "vault-node"
ui = true
log_level = "INFO"
disable_mlock = true

