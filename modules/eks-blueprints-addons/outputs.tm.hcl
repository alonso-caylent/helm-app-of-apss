generate_hcl "_terramate_generated-eks-blueprints-addmins-outputs.tf" {
  content {
    # output "argocd_admin_password" {
    #   description = "argocd admin password (Temporary)"
    #   value       = data.vault_kv_secret_v2.argo_admin_password_secret.data["argo_app_credentials_admin_password"]
    #   sensitive   = true
    # }
  }
}