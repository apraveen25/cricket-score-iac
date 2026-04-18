###############################################################################
# providers.tf
# Declares required providers and the minimum Terraform version.
# The AzureRM provider is pinned to a recent stable major version to balance
# access to new resources with build reproducibility.
###############################################################################

terraform {
  # Pin to the latest stable 1.x line. Using >= with a patch floor lets us pick
  # up bug-fixes without silently jumping major versions.
  required_version = ">= 1.7.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.110" # 3.110+ has stable support for all resources used here
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.53"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

# The AzureRM provider block. Features is required (even if empty) for >= 2.x.
provider "azurerm" {
  features {
    key_vault {
      # Soft-delete is on by default in Azure. Purging helps in non-prod so the
      # same name can be recreated quickly when testing.
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      # Prevent accidental deletion when RG still holds resources (safer default
      # than the provider's historical "force delete" behavior).
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "azuread" {}
provider "random" {}
