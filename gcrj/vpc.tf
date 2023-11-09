# VPC Resources

resource "google_compute_network" "ashirt" {
  name = var.app_name
}

# TODO TN what should this subnet be named then rename subnet
resource "google_compute_subnetwork" "public" {
  count         = var.az_count
  name          = "${var.app_name}-public"
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
  network       = google_compute_network.vpc.self_link
}

# How do I make this actually private?
# as 
resource "google_compute_subnetwork" "private" {
  count         = var.private_subnet ? var.az_count : 0 
  name          = "${var.app_name}-private"
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
  network       = google_compute_network.vpc.self_link
}

# Create network endpoint group for internet access
resource "google_compute_network_endpoint_group" "egress" {
  name         = "egress-endpoint"
  network      = google_compute_network.ashirt.id
  subnetwork   = google_compute_subnetwork.public.id
} 

# Allow Internet access on endpoint group
resource "google_compute_network_endpoint" "internet_egress" {
  network_endpoint_group = google_compute_network_endpoint_group.egress.id

  instance      = google_compute_instance.nat.id
  ip_address    = google_compute_instance.nat.network_interface.0.network_ip
  port          = "80"
}

# VPC connector to allow Cloud Run to access VPC 
resource "google_vpc_access_connector" "connector" {
  name          = "connector"
  region        = google_compute_subnetwork.public.region
  # TODO TN should this be 24?
  ip_cidr_range = "10.8.0.0/28"
  network       = google_compute_network.vpc.id
}
