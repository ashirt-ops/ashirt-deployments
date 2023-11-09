# Create a random password for the database user
resource "random_password" "db_password" {
  length  = 24
  special = false
}

# Create a MySQL database instance
resource "google_sql_database_instance" "ashirt" {
  name             = "${var.app_name}-db"
  # TODO TN - this is what the dev dockerfile uses
  database_version = "MYSQL_8_0"
  project          = locals.project_id
  region           = var.region

      # Configure the root password - if I have user I don't think I need this?
  root_password = "your-root-password"

# TODO figure out networking? or leave alone?
  settings {
    # TODO TN is this okay?
    tier = "db-n1-standard-2" # Choose an appropriate tier

    backup_configuration {
      enabled    = true
      start_time = "05:00" 
    }
  }
}

# Create a database user and grant privileges
resource "google_sql_user" "ashirt" {
  instance = google_sql_database_instance.ashirt.name
  name     = "ashirt"
  password = random_password.db_password.result
}

# Create a database
resource "google_sql_database" "ashirt" {
  instance = google_sql_database_instance.ashirt.name
  name     = "ashirt"
}

# TODO how to conect db with app?
output "connection_name" {
  value = google_sql_database_instance.example_instance.connection_name
}
