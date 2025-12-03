[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT) [![Work In Progress](https://img.shields.io/badge/Status-Work%20In%20Progress-yellow)](https://guide.unitvectorylabs.com/bestpractices/status/#work-in-progress)

# gcp-pubsub-multiregion-push-demo-tofu

OpenTofu reference showing Pub/Sub push behavior with global load balancing and multi-region Cloud Run consumers.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_gclb"></a> [gclb](#module\_gclb) | GoogleCloudPlatform/lb-http/google//modules/serverless_negs | ~> 14.0 |

## Resources

| Name | Type |
|------|------|
| [google_artifact_registry_repository.repos](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/artifact_registry_repository) | resource |
| [google_cloud_run_service_iam_member.pubsub_invoker](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_service_iam_member) | resource |
| [google_cloud_run_v2_service.services](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_v2_service) | resource |
| [google_cloud_scheduler_job.publish_messages](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_scheduler_job) | resource |
| [google_compute_global_address.load_balancer_ip](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_global_address) | resource |
| [google_compute_ssl_policy.tls_policy](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_ssl_policy) | resource |
| [google_pubsub_subscription.pubsub_subscription](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_subscription) | resource |
| [google_pubsub_topic.pubsub](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_topic) | resource |
| [google_pubsub_topic_iam_member.scheduler_publisher](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_topic_iam_member) | resource |
| [google_service_account.cloud_run_sa](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |
| [google_service_account.pubsub_sa](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |
| [google_project.project](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/project) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_app_name"></a> [app\_name](#input\_app\_name) | Name of the application | `string` | n/a | yes |
| <a name="input_enable_publish_messages"></a> [enable\_publish\_messages](#input\_enable\_publish\_messages) | Whether to create the Cloud Scheduler job that triggers every minute | `bool` | `true` | no |
| <a name="input_image"></a> [image](#input\_image) | The Docker image name | `string` | `"unitvectory-labs/gologhttpjson"` | no |
| <a name="input_image_tag"></a> [image\_tag](#input\_image\_tag) | The Docker image tag | `string` | `"latest"` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The GCP project ID | `string` | n/a | yes |
| <a name="input_regions"></a> [regions](#input\_regions) | List of regions to deploy resources in | `list(string)` | n/a | yes |
| <a name="input_root_repository"></a> [root\_repository](#input\_root\_repository) | Root repository for Docker images | `string` | `"https://ghcr.io"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_load_balancer_dns_name"></a> [load\_balancer\_dns\_name](#output\_load\_balancer\_dns\_name) | The DNS name of the load balancer |
| <a name="output_load_balancer_ip_address"></a> [load\_balancer\_ip\_address](#output\_load\_balancer\_ip\_address) | The IP address of the load balancer |
<!-- END_TF_DOCS -->
