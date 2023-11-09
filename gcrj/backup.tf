# Google Cloud Storage Bucket for backups
resource "google_storage_bucket" "ashirt_backups" {
  name     = "ashirt-backups"
  location = var.region
  lifecycle_rule {
    condition {
      age = 35 # Delete objects older than 35 days
    }
    action {
      type = "Delete"
    }
  }
}

# Google Cloud IAM Service Account for backups
resource "google_service_account" "backup" {
  account_id   = "backup"
  display_name = "Backup Service Account"
}

# Assign roles to the Service Account for necessary access
resource "google_project_iam_binding" "backup_binding" {
  project = local.project_id
  role    = "roles/storage.objectAdmin"
  members = [
    "serviceAccount:${google_service_account.backup.email}",
  ]
}

# Google Cloud Scheduler Job for daily backups
resource "google_cloud_scheduler_job" "backup" {
  name     = "ashirt-backup-job"
  description = "Daily backup job for Cloud SQL and GCS"
  schedule = "0 5 * * *" # Daily at 5 AM UTC
  time_zone = "Etc/UTC"

  http_target {
    # TODO TN Look into this
    uri = "YOUR_BACKUP_FUNCTION_URL" # Provide the URL to your backup function
    http_method = "POST"

    # TODO TN Look into this
    # You would need to include authorization token if needed
    # oauth_token {
    #   service_account_email = google_service_account.backup.email
    # }
  }
}

# You would need to add additional resources for setting up Cloud SQL backups
# using google_sql_database_instance and configuring its settings.



# Certainly! In GCP, a backup function is typically a Cloud Function or a Cloud Run service that you would invoke to perform backup operations. Below is an example of what a simple backup Cloud Function in Python could look like. This function could be set up to trigger backups for Cloud SQL and export them to a Cloud Storage bucket. 

# ```python
# import googleapiclient.discovery
# from google.cloud import storage
# import datetime

# def backup_cloud_sql(data, context):
#     # Replace with your project ID, instance ID, and bucket name
#     project_id = 'your-gcp-project-id'
#     instance_id = 'your-cloudsql-instance-id'
#     bucket_name = 'your-backup-bucket-name'
    
#     # Create a timestamp for the backup
#     timestamp = datetime.datetime.now().strftime("%Y-%m-%d-%H-%M-%S")
#     backup_name = f"{instance_id}-{timestamp}"

#     # Construct the service object for the interacting with the Cloud SQL Admin API
#     service = googleapiclient.discovery.build('sqladmin', 'v1beta4')

#     # Create a new backup
#     request_body = {
#         'exportContext': {
#             'kind': 'sql#exportContext',
#             'fileType': 'SQL',
#             'uri': f"gs://{bucket_name}/{backup_name}.sql",
#             'databases': []  # List the databases you want to backup, or leave empty for all
#         }
#     }
    
#     request = service.instances().export(project=project_id, instance=instance_id, body=request_body)
#     response = request.execute()

#     return response
# ```

# To use this function:

# 1. Replace `your-gcp-project-id`, `your-cloudsql-instance-id`, and `your-backup-bucket-name` with your actual GCP project ID, Cloud SQL instance ID, and GCS bucket name.
# 2. Deploy this function to Google Cloud Functions.
# 3. Schedule the function to run using Cloud Scheduler, which will call this function's trigger URL at the specified times.

# This function uses the Cloud SQL Admin API to export the SQL database to a Cloud Storage bucket. It generates a filename with a timestamp to keep each backup distinct.

# Here's how you might deploy such a function using Terraform:

# ```hcl
# resource "google_cloudfunctions_function" "backup_function" {
#   name                  = "cloud-sql-backup-function"
#   description           = "A Cloud Function to backup Cloud SQL databases"
#   runtime               = "python39"
#   available_memory_mb   = 256
#   source_archive_bucket = google_storage_bucket.cloud_function_source.name
#   source_archive_object = google_storage_bucket_object.archive.name
#   trigger_http          = true
#   entry_point           = "backup_cloud_sql"

#   environment_variables = {
#     PROJECT_ID   = "your-gcp-project-id"
#     INSTANCE_ID  = "your-cloudsql-instance-id"
#     BUCKET_NAME  = "your-backup-bucket-name"
#   }
# }

# resource "google_storage_bucket" "cloud_function_source" {
#   name = "cloud-function-source-bucket"
# }

# resource "google_storage_bucket_object" "archive" {
#   name   = "source-archive.zip"
#   bucket = google_storage_bucket.cloud_function_source.name
#   source = "path/to/your/local/source-archive.zip"
# }

# resource "google_cloud_scheduler_job" "backup_scheduler" {
#   name     = "cloud-sql-backup-scheduler"
#   schedule = "0 5 * * *" # Daily at 5 AM
#   time_zone = "Etc/UTC"

#   http_target {
#     uri        = google_cloudfunctions_function.backup_function.https_trigger_url
#     http_method = "POST"
#     oidc_token {
#       service_account_email = google_service_account.backup_sa.email
#     }
#   }
# }

# resource "google_service_account" "backup_sa" {
#   account_id   = "backup-sa"
#   display_name = "Backup Service Account"
# }

# resource "google_project_iam_member" "invoker" {
#   role    = "roles/cloudfunctions.invoker"
#   member  = "serviceAccount:${google_service_account.backup_sa.email}"
# }
# ```

# This Terraform setup does the following:
# - Defines a Cloud Function for the backup operation.
# - Creates a Cloud Scheduler job to trigger the function daily at 5 AM UTC.
# - Sets up a service account with the necessary permissions to invoke the function.

# Before using this, you would need to create a zip file containing your Python function and any dependencies and update the `source` in `google_storage_bucket_object` to point to this zip file's location.
