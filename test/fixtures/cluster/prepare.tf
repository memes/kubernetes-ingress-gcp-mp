data "google_client_config" "default" {
  depends_on = [
    google_container_cluster.cluster,
  ]
}

provider "kubernetes" {
  host                   = format("https://%s", google_container_cluster.cluster.endpoint)
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.cluster.master_auth.0.cluster_ca_certificate)
}

data "local_file" "schema" {
  filename = format("%s/../../../%s/schema.yaml", path.module, var.scenario)
}

# data "http" "crd" {
#   url = "https://raw.githubusercontent.com/GoogleCloudPlatform/marketplace-k8s-app-tools/master/crd/app-crd.yaml"
#   lifecycle {
#     postcondition {
#       condition     = self.status_code == 200
#       error_message = "Failed to get Application CRD"
#     }
#   }
# }

# output "crd" {
#   value = yamldecode(data.http.crd.response_body)
# }

locals {
  k8s_sa     = format("%s-sa", var.scenario)
  schema     = yamldecode(data.local_file.schema.content)
  role_rules = try(local.schema.properties["nginx-ingress.controller.serviceAccount.name"].x-google-marketplace.serviceAccount.roles[0].rules, [])
}

resource "kubernetes_namespace_v1" "namespace" {
  metadata {
    name        = var.prefix
    annotations = local.annotations
    labels      = local.labels
  }

  depends_on = [
    google_container_cluster.cluster,
  ]
}

resource "kubernetes_secret" "reporting_secret" {
  type = "Opaque"
  metadata {
    name        = var.scenario
    namespace   = var.prefix
    annotations = local.annotations
    labels      = local.labels
  }
  data = {
    consumer-id    = "project:pr-xxxx-fake-xxxx"
    entitlement-id = "ffffffff-ffff-ffff-ffff-ffffffffffff"
    reporting-key  = "ewogICJ0eXBlIjogInNlcnZpY2VfYWNjb3VudCIsCiAgInByb2plY3RfaWQiOiAiY2xvdWQtbWFya2V0cGxhY2UtdG9vbHMiLAogICJwcml2YXRlX2tleV9pZCI6ICJmNGZiMGQ2MzNhZDQ3YjEwZTJhNDRjM2ZjMGZiYjA3NTk4NzgyY2JjIiwKICAicHJpdmF0ZV9rZXkiOiAiLS0tLS1CRUdJTiBQUklWQVRFIEtFWS0tLS0tXG5NSUlFdkFJQkFEQU5CZ2txaGtpRzl3MEJBUUVGQUFTQ0JLWXdnZ1NpQWdFQUFvSUJBUUN6MG9iVmxtVjA4MFVoXG5uY3h0d2dyTU1JNmd0K2NhNlRqdk4vbk5naDFudk1UMXR0NnptYjZCMGI0Sk1vWExHN2pjL3F5OWJLa0tDOFA2XG5lWDJjWnA1ZEhOUlBFUExUYzFWTnBWY3BPNmQxUXRsVm9NYWUzVmMyMlF3MzBCalNHS1MvWE9Wb2RsTytQLzY3XG5xM1FaT3pZbjE4MjA2OFd3L0VlT3E3YmFvT3BieVRDRVQ2RTcrOG8raU1ET1JIZW5rMTRrMkZ6R24zK2NqOUZIXG5TNHFCL1dSKzQxZm5lNW91NU5JSXE0aWVYVWdlNzZ6OFYxZDN1dWF5cFhhY0NtTCtMZFVyYXY1b0RIN3lESUJ6XG5MaGFGS29lSGJ6RFpTdGdSaUJpVjZFbzZhTWxuN0NwTGxqbVNPdGorbVNSbHYzdEU2blU5N1ZqOEptaWNCQ3pWXG5JdDluNHRzSEFnTUJBQUVDZ2dFQUJSbnFwNklweEZJUnV0STlBT1laZVZFWC9XT0tMbFRCditPTGRoMkQvbDZOXG5ZSUpzdWVxWmRzUlU5WnpWelNlL0FhSHdrNC9DdklnTjZndjFRM0VUMEFTOUx5QmJkYzByOVNwdmJtVGFBTXBzXG5oa1hXZ2ZPUExGS205VDhLM1RidXdZWlRTYmlGblZHTkdwVFN2bjUrc0UycWNSWDVMZWFubEZxM0NCSmxqa1NsXG5aY08rUnNEUjRQNDBFUWUwaWQxazNTYW9JMHRBS0taNGNCbGRhS1JBVFRXNHBzNkdvSG9yOVI2NDBYY1ZRSzlWXG5lTlJPamMwTmltRnlKUWZUS2NXaUxIMVhiQTRUQ29GV0hOdUNlL2hWUVRSVnJSOXVoMXVUSnB5UG40QkMzZnpSXG5NdHFyNXlhTG5ybTMyY0Qrb0YrVnZYN1JlVmtMZnZMSk5DVURTOEF1cVFLQmdRRDA4N2RHUFJhTWJGOUV5bmVqXG45S3RqSlNBclhzYmJwblJQRzlSa0FUSTlGaXBtTFpaczRTaDc5OWdYNVdPNXRVNldBYVVqTUR1M3pzTGZCNCtPXG5NNE9MQml0L3kwVzFBZlM0TUY2TmpmcElaSUlsOWk1Z0JLUnBFQXB0dmVtSW9GZFlRY0xTb2F0SFJlcHBlN2liXG5iMHFnYi9UVnNFYXhhZ1B2KzhIN3pEcUZXUUtCZ1FDNzdzNUg0UjN1WDRUS3JROWU0SVFNNm9qUEIxQk9EWG1jXG5reTJCUG5LclNBb1cycllZRXpnNXpFQmpyendsOU1nK0lhQXVubS9ydENFZ0o2S2ZKVXdYQ3hWcTZjV21yVHhCXG5hQ2ZHTEozai85alhNQ2tHT2tUYUhUdjllcHUwbC90ZzM5NkxCSUxMaWhnOW96UVozbHlrazdHOXhYcmFEbW5nXG5KTEQ5a3NkM1h3S0JnRWNxL0NmREhlY0VvWlZhQWZLMzVvZXl4S3IxS1crdDZBTUlBZWhnVkpsYzlFcWxtaHZlXG5PeVh4ZDI1UjdteUpXZURKYjVKT3REc09McDRnRXp4c2lSNStWMnNVd3hiNUQ0SG9ROEI2N0tuVjBkNTNyVGVtXG5nYUlveis3Y2k1cHZnNUVYNGlQU1p2SVpSU2NLbEROTTNYREp0bWZUaEdhTmQ4Rms4eEpXWHZaWkFvR0FZUE04XG5SWWFUMjFJNWZoa3pVYjIvUWE2SWIwMFZsMzZLRzBVdDkzdlF5aDI2M3JscnNSWFJMcmY1QzdQdDhxTEozb3VZXG5TQlNDSm5WaGxXWDlGZDYyMXpobmp5VVVTdjBabGFCMnpGeGVBNjRNSGs4QkN1NXFjSjhlUUpETTNLaC9EU1hRXG5kNlVYR0l1Z0g4UWU3NjF2MjVNNTRXMk1DQXZoZ0xsTStUT01aVDhDZ1lCcjV5R1piMlBGZitKbWZmTU1ENE56XG5lbEp1S1JlYzRielpsNFBGQ1c3OHpJMi9DZTZjOHRnWGN0OEptTUM2R2kxaERCMS8vZlZISjcxRnlSYjBIYXVPXG5TWHZ2VXQ1OGEvL1Bsc1ZUbGNucGJ2UEVRRTY0SjZ6UjlnK0RLNWhEOGo4UUxVaFhkdHFYYjVhUXA4QzlzNG5PXG5icURQZ3VoL0tJaVA1WSthUE9laG53PT1cbi0tLS0tRU5EIFBSSVZBVEUgS0VZLS0tLS1cbiIsCiAgImNsaWVudF9lbWFpbCI6ICJ4eHgtZmFrZS1yZXBvcnRlci14eHhAY2xvdWQtbWFya2V0cGxhY2UtdG9vbHMuaWFtLmdzZXJ2aWNlYWNjb3VudC5jb20iLAogICJjbGllbnRfaWQiOiAiMTA1ODYyMDM3ODQ1Mjk5NzI3ODIzIiwKICAiYXV0aF91cmkiOiAiaHR0cHM6Ly9hY2NvdW50cy5nb29nbGUuY29tL28vb2F1dGgyL2F1dGgiLAogICJ0b2tlbl91cmkiOiAiaHR0cHM6Ly9vYXV0aDIuZ29vZ2xlYXBpcy5jb20vdG9rZW4iLAogICJhdXRoX3Byb3ZpZGVyX3g1MDlfY2VydF91cmwiOiAiaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vb2F1dGgyL3YxL2NlcnRzIiwKICAiY2xpZW50X3g1MDlfY2VydF91cmwiOiAiaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vcm9ib3QvdjEvbWV0YWRhdGEveDUwOS94eHgtZmFrZS1yZXBvcnRlci14eHglNDBjbG91ZC1tYXJrZXRwbGFjZS10b29scy5pYW0uZ3NlcnZpY2VhY2NvdW50LmNvbSIKfQ=="
  }

  depends_on = [
    google_container_cluster.cluster,
    kubernetes_namespace_v1.namespace,
  ]
}

resource "kubernetes_service_account_v1" "nginx" {
  metadata {
    name        = local.k8s_sa
    namespace   = var.prefix
    annotations = local.annotations
    labels      = local.labels
  }

  depends_on = [
    google_container_cluster.cluster,
    kubernetes_namespace_v1.namespace,
  ]
}

resource "kubernetes_cluster_role_v1" "nginx" {
  metadata {
    name        = var.scenario
    annotations = local.annotations
    labels      = local.labels
  }

  dynamic "rule" {
    for_each = local.role_rules
    content {
      api_groups = rule.value.apiGroups
      resources  = rule.value.resources
      verbs      = rule.value.verbs
    }
  }

  depends_on = [
    google_container_cluster.cluster,
    kubernetes_namespace_v1.namespace,
  ]
}

resource "kubernetes_cluster_role_binding_v1" "nginx" {
  metadata {
    name        = var.scenario
    annotations = local.annotations
    labels      = local.labels
  }
  subject {
    kind      = "ServiceAccount"
    name      = local.k8s_sa
    namespace = var.prefix
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = var.scenario
  }

  depends_on = [
    google_container_cluster.cluster,
    kubernetes_namespace_v1.namespace,
  ]
}
