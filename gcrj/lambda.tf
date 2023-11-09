locals {
  prefix              = "ashirt-workers"
  account_id          = data.aws_caller_identity.current.account_id
  ecr_repository_name = "${local.prefix}-ocr"
  ecr_image_tag       = "latest"
}

# Cloud Run service account
resource "google_service_account" "cloudrun-sa" {
  # TODO TN look into this
  account_id = "cloudrun-sa"
} 

# Cloud Run V2 job definition
resource "google_cloud_run_v2_job" "ocr" {
  name     = "${local.prefix}-ocr"
  location = var.region
  template {
    template {
      containers {
        image = "gcr.io/${local.project_id}/demo-ocr:latest"  

        env {
          name  = "ASHIRT_ACCESS_KEY"
          value = var.WORKER_ACCESS_KEY 
        }

        env {
          name  = "ASHIRT_BACKEND_PORT"
          value = "443"
        }

        env {
          name  = "ASHIRT_BACKEND_URL"
          # TODO TN add this
          value = "TODO_REPLACE_WITH_BACKEND_URL" 
        }

        env {
          name  = "ASHIRT_SECRET_KEY"
          value = var.WORKER_SECRET_KEY
        }

      }
      service_account = google_service_account.cloudrun-sa.email
      timeout = "900s"
    }
      
  }
  # TODO: Add your triggering conditions or schedule here if needed
}

# Build and push image to GCR 
resource "null_resource" "push_image" {
  provisioner "local-exec" {
    command = <<EOF
      docker build -t demo-ocr:latest .
      docker tag demo-ocr:latest gcr.io/${local.project_id}/demo-ocr:latest
      docker push gcr.io/${local.project_id}/demo-ocr:latest
    EOF
  }
  # Use triggers for changes in the repository or image tag
  triggers = {
    # TODO TN i don't think this will do anything - 
    image_tag = local.ecr_image_tag
  }
}

