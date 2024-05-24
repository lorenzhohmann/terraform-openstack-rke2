terraform {
  required_version = ">= 1.3.3"

  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2.2"
    }
    openstack = {
      source = "terraform-provider-openstack/openstack"
      # 2.0.x is maybe affected by https://github.com/terraform-provider-openstack/terraform-provider-openstack/issues/1601
      version = "~> 2.0.0"
    }
  }
}
