resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
}

resource "vault_kubernetes_auth_backend_config" "this" {
  depends_on      = [vault_auth_backend.kubernetes]
  kubernetes_host = "https://kubernetes.default.svc"
}

resource "vault_mount" "kv" {
  path = "kv"
  type = "kv-v2"
  options = {
    version = "2"
    type    = "kv-v2"
  }
}

resource "vault_policy" "eso" {
  name = "eso"

  policy = <<-EOT
  path "${vault_mount.kv.path}/data/sanae/*" {
    capabilities = ["read"]
  }
  path "${vault_mount.kv.path}/metadata/sanae/*" {
    capabilities = ["read", "list"]
  }
  EOT
}

resource "vault_kubernetes_auth_backend_role" "this" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "eso"
  bound_service_account_names      = [var.eso_k8s_sa]
  bound_service_account_namespaces = [var.eso_k8s_namespace]
  token_ttl                        = 3600
  token_max_ttl                    = 86400
  token_policies                   = [vault_policy.eso.name]
}
