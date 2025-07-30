storage "raft" {
  path    = "/opt/vault/data"
  node_id = "vault-node"
}

listener "tcp" {
 address = "0.0.0.0:8200"
 cluster_address = "0.0.0.0:8201"
 tls_disable = true
}

api_addr = "http://vault-node:8200"
cluster_addr = "http://vault-node:8201"
cluster_name = "vault-node"
ui = true
log_level = "INFO"
disable_mlock = true