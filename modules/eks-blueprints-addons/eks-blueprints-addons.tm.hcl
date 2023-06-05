# Generate '_terramate_generated_data-source.tf' in each stack for Local File-System
generate_hcl "_terramate_generated_data-source.tf" {
  condition = global.isLocal == true

  content {

    data "terraform_remote_state" "eks" {
      backend = "local"

      config = {
        path = "../eks/${global.local_tfstate_path}"
      }

      defaults = {
        cluster_id                         = "ex-eks"
        cluster_endpoint                   = "https://ABCDEFGHIJKLMNOPQRSTUVWXYZ.gr7.us-west-2.eks.amazonaws.com"
        cluster_certificate_authority_data = "dGhpcyBpcyB0ZXN0IGRhdGEuLi4K"
        oidc_provider_arn                  = "arn:aws:iam::1234567890:oidc-provider/oidc.eks.us-west-2.amazonaws.com/id/A1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P6Q7R8S9T0UVWXYZ"
      }
    }
  }
}

# Generate '_terramate_generated_data-source.tf' in each stack for Remote Terraform Cloud
generate_hcl "_terramate_generated_data-source.tf" {
  condition = global.isLocal == false

  content {
    data "terraform_remote_state" "eks" {
      backend = "s3"

      config = {
        bucket = global.terramate_bucket
        key    = "${global.terramate_key_base_path}/eks/${global.local_tfstate_path}"
        region = global.region
      }

      defaults = {
        cluster_id                         = "ex-eks"
        cluster_endpoint                   = "https://ABCDEFGHIJKLMNOPQRSTUVWXYZ.gr7.us-west-2.eks.amazonaws.com"
        cluster_certificate_authority_data = "dGhpcyBpcyB0ZXN0IGRhdGEuLi4K"
        oidc_provider_arn                  = "arn:aws:iam::1234567890:oidc-provider/oidc.eks.us-west-2.amazonaws.com/id/A1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P6Q7R8S9T0UVWXYZ"
      }
    }
  }
}

generate_hcl "_terramate_generated_eks_blueprints_addons.tf" {
  content {

    provider "aws" {
      region = global.terraform_aws_provider_region
    }

    provider "kubernetes" {
      host                   = data.terraform_remote_state.eks.outputs.cluster_endpoint
      cluster_ca_certificate = base64decode(data.terraform_remote_state.eks.outputs.cluster_certificate_authority_data)

      exec {
        api_version = "client.authentication.k8s.io/v1beta1"
        command     = "aws"
        # This requires the awscli to be installed locally where Terraform is executed
        args = ["eks", "get-token", "--cluster-name", data.terraform_remote_state.eks.outputs.cluster_id]
      }
    }

    provider "helm" {
      kubernetes {
        host                   = data.terraform_remote_state.eks.outputs.cluster_endpoint
        cluster_ca_certificate = base64decode(data.terraform_remote_state.eks.outputs.cluster_certificate_authority_data)

        exec {
          api_version = "client.authentication.k8s.io/v1beta1"
          command     = "aws"
          # This requires the awscli to be installed locally where Terraform is executed
          args = ["eks", "get-token", "--cluster-name", data.terraform_remote_state.eks.outputs.cluster_id]
        }
      }
    }

    provider "vault" {
      address          = global.vault_address
      skip_tls_verify  = true
      skip_child_token = true
    }

    # data "vault_kv_secret_v2" "argo_admin_password_secret" {
    #   mount = "${global.repo_project_name}-${global.environment}-kv"
    #   name  = "argo/app/credentials"
    # }

    locals {

      name                       = global.eks_cluster_name
      environment                = global.environment
      argocd_secret_manager_name = "${local.environment}_${local.name}_argocd_secret_manager"

      tags = {
        environment = local.environment
        team        = "devops"
        stack       = local.name
      }
    }

    module "eks_blueprints_kubernetes_addons" {
      source = "git@github.com:aws-ia/terraform-aws-eks-blueprints.git//modules/kubernetes-addons"

      eks_cluster_id       = data.terraform_remote_state.eks.outputs.cluster_id
      eks_cluster_endpoint = data.terraform_remote_state.eks.outputs.cluster_endpoint
      eks_oidc_provider    = data.terraform_remote_state.eks.outputs.oidc_provider_arn
      eks_cluster_version  = global.cluster_version

      enable_argocd         = true
      argocd_manage_add_ons = true # 


      #K8s Add-ons
      argocd_applications = {
        addons = {
          path               = "chart"
          repo_url           = "https://github.com/aws-samples/eks-blueprints-add-ons.git"
          add_on_application = true
        }
        examples-addons = {
          path               = "chart"
          repo_url           = "git@github.com:lytxinc/devops-pipeline-infra.git"
          add_on_application = true
        }
      }

      enable_kubecost                     = true
      enable_aws_efs_csi_driver           = true
      enable_aws_load_balancer_controller = true
      enable_cert_manager                 = true
      enable_external_secrets             = true

      eks_cluster_domain                  = "caylent.dev"
      enable_external_dns                 = true
      #external_dns_route53_zone_arns      = [
      #  "arn:aws:route53::131578276461:hostedzone/Z0156898CF3KVEDIW8JG"
      #]
      #external_dns_helm_config = {
      #  name                       = "external-dns"
      #  chart                      = "external-dns"
      #  repository                 = "https://charts.bitnami.com/bitnami"
      #  version                    = "6.1.6"
      #  namespace                  = "external-dns"
      #}
      
      
      # enable_metrics_server               = true




      #   # Add-ons
      #   # enable_amazon_eks_aws_ebs_csi_driver = true
      #   # enable_aws_for_fluentbit             = true
      #   # # Let fluentbit create the cw log group
      #   # aws_for_fluentbit_create_cw_log_group = false
      #   # enable_cert_manager                   = true
      #   # enable_cluster_autoscaler             = true
      #   # enable_karpenter                      = true
      #   # enable_keda                           = true
      #   # enable_metrics_server                 = true
      #   # enable_prometheus                     = true
      #   # enable_traefik                        = true
      #   # enable_vpa                            = true
      #   # enable_yunikorn                       = true
      #   # enable_argo_rollouts                  = true

      tags = local.tags
    }
  }
}