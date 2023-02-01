terraform {
  required_version = ">= 1.3"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.42, < 4.49.0"
    }
    http = {
      source  = "hashicorp/http"
      version = ">= 3.2"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.17"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.3"
    }
  }
}

data "http" "test_address" {
  url = "https://checkip.amazonaws.com"
  lifecycle {
    postcondition {
      condition     = self.status_code == 200
      error_message = "Failed to get local IP address"
    }
  }
}

locals {
  testing_source_cidr = "0.0.0.0/0" #format("%s/32", trimspace(data.http.test_address.response_body))
  name                = format("%s-%s", var.prefix, var.scenario)
  sa                  = format("%s@%s.iam.gserviceaccount.com", substr(format("%s-gke", local.name), 0, 28), var.project_id)
  labels = merge({
    scenario = var.scenario
    name     = local.name
    use-case = "automated-testing"
    driver   = "kitchen-terraform"
  }, var.labels)
  annotations = merge({
    "community.f5.com/name"        = local.name
    "community.f5.com/scenario"    = var.scenario
    "community.f5.com/use-case"    = "automated-testing"
    "community.f5.com/driver"      = "kitchen-terraform"
    "community.f5.com/test-source" = "github.com/memes/kubernetes-ingress-gcp-mp"
  }, var.annotations)
  # Sanitise labels incase they conflict with GCP requirements
  gcp_labels = { for k, v in local.labels : replace(substr(lower(k), 0, 64), "/[^[[:alnum:]]_-]/", "_") => replace(lower(v), "/[^[[:alnum:]]_-]/", "_") }
}

module "sa" {
  source       = "github.com/memes/proteus-wip//private-gke/modules/sa"
  project_id   = var.project_id
  name         = substr(format("%s-gke", local.name), 0, 28)
  repositories = [var.repository]
}

module "vpc" {
  source                                 = "terraform-google-modules/network/google"
  version                                = "6.0.1"
  project_id                             = var.project_id
  network_name                           = local.name
  description                            = format("NGINX+ Ingress Controller testing VPC for %s scenario", var.scenario)
  auto_create_subnetworks                = false
  delete_default_internet_gateway_routes = false
  routing_mode                           = "GLOBAL"
  mtu                                    = 1460
  subnets = [
    {
      subnet_name           = var.scenario
      subnet_ip             = "192.168.0.0/24"
      subnet_region         = var.region
      subnet_private_access = false
      subnet_flow_logs      = false
    }
  ]
  secondary_ranges = {
    (var.scenario) = [
      {
        range_name    = "pods"
        ip_cidr_range = "10.0.0.0/16"
      },
      {
        range_name    = "services"
        ip_cidr_range = "10.100.0.0/24"
      }
    ]
  }
}

# Allow HTTP and HTTPS access to workloads on the cluster
resource "google_compute_firewall" "test" {
  project   = var.project_id
  name      = format("%s-ingress", local.name)
  network   = module.vpc.network_self_link
  direction = "INGRESS"
  priority  = 900
  source_ranges = [
    local.testing_source_cidr,
  ]
  target_service_accounts = [
    local.sa,
  ]
  allow {
    protocol = "TCP"
    ports = [
      80,
      443,
    ]
  }
}

# Create a basic regional cluster with public endpoints for ease of testing
resource "google_container_cluster" "cluster" {
  project                  = var.project_id
  name                     = local.name
  description              = format("NGINX+ Ingress Controller testing cluster for %s scenario", var.scenario)
  location                 = var.region
  resource_labels          = local.gcp_labels
  remove_default_node_pool = false
  initial_node_count       = var.node_count

  node_config {
    machine_type    = var.machine_type
    preemptible     = var.preemptible
    service_account = local.sa
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
    labels          = local.labels
    resource_labels = local.gcp_labels
  }

  release_channel {
    channel = "STABLE"
  }

  master_authorized_networks_config {
    cidr_blocks {
      display_name = "Test operator"
      cidr_block   = local.testing_source_cidr
    }
  }

  network         = module.vpc.network_self_link
  subnetwork      = module.vpc.subnets_self_links[0]
  networking_mode = "VPC_NATIVE"
  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }

  depends_on = [
    module.sa,
    module.vpc,
  ]
}
