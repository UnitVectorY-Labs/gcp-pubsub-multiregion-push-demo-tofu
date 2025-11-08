provider "google" {
  project = var.project_id
}

data "google_project" "project" {
  project_id = var.project_id
}

locals {
  load_balancer_domain = "${var.app_name}-${replace(google_compute_global_address.load_balancer_ip.address, ".", "-")}.nip.io"
}

resource "google_compute_global_address" "load_balancer_ip" {
  name        = "${var.app_name}-ip"
  description = "Static IP address for the load balancer"
}

resource "google_artifact_registry_repository" "repos" {
  for_each      = toset(var.regions)
  location      = each.key
  repository_id = "${var.app_name}-${each.key}-repo"
  description   = "Proxy Container Registry for ${var.app_name} in ${each.key}"
  format        = "DOCKER"
  mode          = "REMOTE_REPOSITORY"

  remote_repository_config {
    docker_repository {
      custom_repository {
        uri = var.root_repository
      }
    }
  }
}

resource "google_service_account" "cloud_run_sa" {
  project      = var.project_id
  account_id   = "${var.app_name}-sa"
  display_name = "${var.app_name} service account"
}

resource "google_cloud_run_v2_service" "services" {
  for_each = toset(var.regions)
  name     = "${var.app_name}-${each.value}"
  location = each.value
  ingress  = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"

  deletion_protection = false

  template {
    service_account = google_service_account.cloud_run_sa.email

    containers {
      image = "${each.value}-docker.pkg.dev/${var.project_id}/${var.app_name}-${each.value}-repo/${var.image}:${var.image_tag}"
      
      env {
        name  = "METADATA_consumeRegion"
        value = each.value
      }
    }
  }

  custom_audiences = ["https://${local.load_balancer_domain}"]

  depends_on = [
    google_artifact_registry_repository.repos
  ]
}

resource "google_compute_ssl_policy" "tls_policy" {
  name            = "${var.app_name}-tls-policy"
  profile         = "RESTRICTED"
  min_tls_version = "TLS_1_2"
}

module "gclb" {
  source  = "GoogleCloudPlatform/lb-http/google//modules/serverless_negs"
  version = "~> 14.0"

  project = var.project_id
  name    = var.app_name

  load_balancing_scheme = "EXTERNAL_MANAGED"

  backends = {
    default = {
      enable_cdn = false

      log_config = {
        enable      = true
        sample_rate = 1.0
      }

      groups = []

      serverless_neg_backends = [
        for region in var.regions : {
          type   = "cloud-run"
          region = region
          service = {
            name = google_cloud_run_v2_service.services[region].name
          }
        }
      ]

      iap_config = {
        enable = false
      }
    }
  }

  http_forward = false
  url_map      = "default"
  ssl          = true

  managed_ssl_certificate_domains = [local.load_balancer_domain]
  create_address                  = false
  address                         = google_compute_global_address.load_balancer_ip.address
  ssl_policy                      = google_compute_ssl_policy.tls_policy.name

  depends_on = [
    google_artifact_registry_repository.repos
  ]
}

resource "google_service_account" "pubsub_sa" {
  project      = var.project_id
  account_id   = "${var.app_name}-pssa"
  display_name = "${var.app_name} pubsub service account"
}

resource "google_cloud_run_service_iam_member" "pubsub_invoker" {
  for_each   = toset(var.regions)
  location   = each.key
  service    = google_cloud_run_v2_service.services[each.key].name
  role       = "roles/run.invoker"
  member     = "serviceAccount:${google_service_account.pubsub_sa.email}"
  depends_on = [google_cloud_run_v2_service.services]
}

resource "google_pubsub_topic" "pubsub" {
  project                    = var.project_id
  name                       = "${var.app_name}-topic"
  message_retention_duration = "3600s"
}

resource "google_pubsub_subscription" "pubsub_subscription" {
  project                 = var.project_id
  name                    = "${var.app_name}-subscription"
  topic                   = google_pubsub_topic.pubsub.name
  enable_message_ordering = true

  retry_policy {
    minimum_backoff = "10s"
  }


  push_config {
    push_endpoint = "https://${local.load_balancer_domain}/pubsub"

    oidc_token {
      service_account_email = google_service_account.pubsub_sa.email
      audience              = "https://${local.load_balancer_domain}"
    }

    attributes = {
      x-goog-version = "v1"
    }

    no_wrapper {
      write_metadata = true
    }
  }
}

# Publish a message to the Pub/Sub topic from each region

resource "google_pubsub_topic_iam_member" "scheduler_publisher" {
  project = var.project_id
  topic   = google_pubsub_topic.pubsub.name
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-cloudscheduler.iam.gserviceaccount.com"
}

resource "google_cloud_scheduler_job" "publish_messages" {
  for_each = var.enable_publish_messages ? toset(var.regions) : []
  name        = "${var.app_name}-${each.key}-job-runner"
  project     = var.project_id
  region      = each.key
  schedule = "* * * * *"
  description = "Trigger Pub/Sub publish every minute in ${each.key}"

  pubsub_target {
    topic_name = google_pubsub_topic.pubsub.id
    data       = base64encode("{\"publishRegion\": \"${each.key}\"}")
  }

  depends_on = [google_pubsub_topic_iam_member.scheduler_publisher]
}