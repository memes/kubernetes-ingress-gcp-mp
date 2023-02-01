output "endpoint" {
  value = format("https://%s", google_container_cluster.cluster.endpoint)
}

output "b64_ca_cert" {
  value = google_container_cluster.cluster.master_auth.0.cluster_ca_certificate
}
