locals {
    ###########################################################
    #
    # Config parameters
    #
    # also add terraform.tfvars, see README at:
    #
    # https://github.com/srieger1/terraform-openstack-rke2/tree/main/hs-fulda
    #
    ###########################################################

    auth_url         = "https://private-cloud.informatik.hs-fulda.de:5000"
    object_store_url = "private-cloud.informatik.hs-fulda.de:6780"
    region           = "RegionOne"

    cluster_name     = "k8s"
    image_name       = "Ubuntu 22.04 - Jammy Jellyfish - 64-bit - Cloud Based Image"
    #image_name       = "Ubuntu 20.04 - Focal Fossa - 64-bit - Cloud Based Image"
    flavor_name      = "m1.medium"
    region_name      = "RegionOne"
    system_user      = "ubuntu"
    floating_ip_pool = "public1"
    ssh_pubkey_file  = "~/.ssh/id_rsa.pub"
    dns_server       = "10.33.16.100"

    manifests_folder = "../../manifests"

    #rke2_version = "v1.24.8+rke2r1"
    #rke2_version = "v1.25.5+rke2r2"
    #rke2_version = "v1.26.4+rke2r1"
    rke2_version = "v1.26.6+rke2r1"

    rke2_config = <<EOF
    etcd-snapshot-schedule-cron: "0 */6 * * *"
    etcd-snapshot-retention: 20

    control-plane-resource-requests: kube-apiserver-cpu=75m,kube-apiserver-memory=128M,kube-scheduler-cpu=75m,kube-scheduler-memory=128M,kube-controller-manager-cpu=75m,kube-controller-manager-memory=128M,etcd-cpu=75m,etcd-memory=128M
    EOF

    # https://docs.rke2.io/install/configuration#configuration-file
    # https://docs.rke2.io/install/configuration#configuring-rke2-server-nodes
    # https://docs.rke2.io/reference/server_config
}

###########################################################

module "rke2" {
  # source = "zifeo/rke2/openstack"
  source = "./../.."
  #source = "zifeo/rke2/openstack"
  # fixing the version is recommended (follows semantic versioning)
  #version = "2.0.3"

  # must be true for single-server cluster or only on first run for HA cluster
  bootstrap           = true
  name                = local.cluster_name
  ssh_authorized_keys = [local.ssh_pubkey_file]
  floating_pool = local.floating_ip_pool
  # should be restricted to a secure bastion
  rules_ssh_cidr = "0.0.0.0/0"
  rules_k8s_cidr = "0.0.0.0/0"
  lb_provider = "amphora"
  # auto load manifest from a folder (https://docs.rke2.io/advanced#auto-deploying-manifests)
  manifests_folder = local.manifests_folder

  servers = [{
    name = "server"

    flavor_name        = local.flavor_name
    image_name         = local.image_name
    system_user        = local.system_user
    boot_volume_size   = 8

    rke2_version       = local.rke2_version
    rke2_volume_size   = 8
    rke2_volume_device = "/dev/vdb"
    rke2_config = local.rke2_config
  }]

  agents = [
    {
      name        = "pool-a"
      nodes_count = 3

      flavor_name        = local.flavor_name
      image_name         = local.image_name
      system_user        = local.system_user
      boot_volume_size   = 8

      rke2_version       = local.rke2_version
      rke2_volume_size   = 8
      rke2_volume_device = "/dev/vdb"
    }
  ]

  dns_nameservers4 = [ local.local.dns_server ]

  # enable automatically `kubectl delete node AGENT-NAME` after an agent change
  ff_autoremove_agent = "30s"
  # rewrite kubeconfig
  ff_write_kubeconfig = true
  # deploy etcd backup
  ff_native_backup = true

  identity_endpoint     = local.auth_url
  object_store_endpoint = local.object_store_url
}

variable "project" {
  type = string
}

variable "username" {
  type = string
}

variable "password" {
  type = string
}

output "floating_ip" {
  value = module.rke2.external_ip
}

provider "openstack" {
  #tenant_name = var.tenant_name
  #user_name   = var.user_name
  # checkov:skip=CKV_OPENSTACK_1
  tenant_name = var.project
  user_name   = var.username
  password = var.password
  auth_url = local.auth_url
  region   = local.region
}

terraform {
  required_version = ">= 0.14.0"

  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = ">= 1.51.1"
    }
  }
}
