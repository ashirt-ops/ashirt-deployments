resource "google_compute_network" "vpc_network" {
  project                 = var.project
  name                    = "ashirt-${var.environment}-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  project = var.project
  # TODO: do we want to make it easier to support multi-az?
  name                     = "ashirt-${var.environment}-subnet-${count.index}"
  count                    = 1
  ip_cidr_range            = cidrsubnet("10.0.0.0/16", 4, 1)
  region                   = var.region
  network                  = google_compute_network.vpc_network.id
  private_ip_google_access = true
}

resource "google_compute_router" "router" {
  project = var.project
  name    = "ashirt-${var.environment}-router"
  network = google_compute_network.vpc_network.id
  region  = var.region
}

resource "google_compute_router_nat" "nat" {
  project                            = var.project
  name                               = "ashirt-${var.environment}-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

resource "google_compute_firewall" "allow_internal" {
  project = var.project
  name    = "ashirt-${var.environment}-allow-internal"
  network = google_compute_network.vpc_network.id

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  source_ranges = ["10.0.0.0/8"]
}
