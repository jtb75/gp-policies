# =============================================================================
# Remediation & Response Deployment — manages Outpost Lite deployment config
# =============================================================================

# Look up the built-in EBS snapshot tagging action
data "wiz_response_actions_catalog" "ebs_007" {
  search = "rem-aws-ebs-007"
  cloud_platform {
    equals = ["AWS"]
  }
  builtin = "true"
}

locals {
  # First matching built-in catalog item for EBS-007
  ebs_007_item    = tolist(data.wiz_response_actions_catalog.ebs_007.response_action_catalog_items)[0]
  ebs_007_id      = local.ebs_007_item.id
  ebs_007_version = tolist(local.ebs_007_item.versions)[0].id
}

resource "wiz_remediation_and_response_deployment_v2" "main" {
  name                 = "JTB75 Remediation"
  resource_name_prefix = "Wiz"

  config {
    aws {
      method = "TERRAFORM"
      scope  = "SINGLE_ACCOUNT"
      kubernetes {
        cluster_arn = "arn:aws:eks:us-east-1:695862934856:cluster/jtb75-wiz-remediation"
        namespace   = "wiz-remediation"
      }
    }
  }

  auto_tag {
    enabled = false
  }

  # --- Built-in: EBS snapshot tagging (rem-aws-ebs-007) ---
  deployed_response_action_configs {
    response_action_catalog_item         = local.ebs_007_id
    response_action_catalog_item_version = local.ebs_007_version
    deployed_response_action_instance_configs {
      status        = "ENABLED"
      is_disruptive = false
      target {
        graph_entity_native_type = "ec2#unencryptedsnapshot"
      }
    }
    deployed_response_action_instance_configs {
      status        = "ENABLED"
      is_disruptive = false
      target {
        graph_entity_native_type = "ec2#encryptedsnapshot"
      }
    }
  }

  # --- Custom: Tag consumer role ---
  deployed_response_action_configs {
    response_action_catalog_item         = wiz_response_action_catalog_item.tag_consumer_role.id
    response_action_catalog_item_version = wiz_response_action_catalog_item.tag_consumer_role.versions[0].id
    deployed_response_action_instance_configs {
      status        = "ENABLED"
      is_disruptive = false
      target {
        cloud_configuration_rule = wiz_cloud_configuration_rule.aws_consumer_role_missing_type_tag.id
      }
    }
  }

  # --- Custom: Remove untrusted trust ---
  deployed_response_action_configs {
    response_action_catalog_item         = wiz_response_action_catalog_item.remove_untrusted_trust.id
    response_action_catalog_item_version = wiz_response_action_catalog_item.remove_untrusted_trust.versions[0].id
    deployed_response_action_instance_configs {
      status        = "ENABLED"
      is_disruptive = true
      target {
        cloud_configuration_rule = wiz_cloud_configuration_rule.aws_role_untrusted_trust.id
      }
    }
  }

  # --- Custom: Deactivate stale access keys ---
  deployed_response_action_configs {
    response_action_catalog_item         = wiz_response_action_catalog_item.deactivate_stale_access_keys.id
    response_action_catalog_item_version = wiz_response_action_catalog_item.deactivate_stale_access_keys.versions[0].id
    deployed_response_action_instance_configs {
      status        = "ENABLED"
      is_disruptive = true
      target {
        cloud_configuration_rule = wiz_cloud_configuration_rule.aws_service_access_key_older_than_90_days.id
      }
    }
    deployed_response_action_instance_configs {
      status        = "ENABLED"
      is_disruptive = true
      target {
        cloud_configuration_rule = wiz_cloud_configuration_rule.aws_user_access_key_older_than_30_days.id
      }
    }
    deployed_response_action_instance_configs {
      status        = "ENABLED"
      is_disruptive = true
      target {
        cloud_configuration_rule = wiz_cloud_configuration_rule.aws_vendor_access_key_older_than_60_days.id
      }
    }
    deployed_response_action_instance_configs {
      status        = "ENABLED"
      is_disruptive = true
      target {
        cloud_configuration_rule = wiz_cloud_configuration_rule.aws_untagged_access_key_older_than_30_days.id
      }
    }
  }
}

# --- Outputs: generated configs for Helm and IAM ---

output "outpost_lite_helm_values" {
  description = "Generated Helm values for Outpost Lite — use to update outpost-lite-values.tpl.yaml"
  value       = wiz_remediation_and_response_deployment_v2.main.outpost_lite_helm_values
  sensitive   = true
}

output "aws_iam_terraform" {
  description = "Generated Terraform for IAM roles — use to update iam_remediation.tf"
  value       = wiz_remediation_and_response_deployment_v2.main.aws_remediation_and_response_deploy_roles_terraform
}

output "outpost_id" {
  description = "Outpost ID for this deployment"
  value       = wiz_remediation_and_response_deployment_v2.main.outpost
}
