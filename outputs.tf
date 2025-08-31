
output "load_balancer_ip_address" {
  description = "The IP address of the load balancer"
  value       = google_compute_global_address.load_balancer_ip.address
}

output "load_balancer_dns_name" {
  description = "The DNS name of the load balancer"
  value       = local.load_balancer_domain
}