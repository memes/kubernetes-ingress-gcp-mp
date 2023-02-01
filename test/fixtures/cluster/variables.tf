variable "prefix" {
  type = string
}

variable "project_id" {
  type = string
}

variable "repository" {
  type = string
}

variable "labels" {
  type    = map(string)
  default = {}
}

variable "scenario" {
  type = string
}

variable "region" {
  type = string
}

variable "annotations" {
  type    = map(string)
  default = {}
}

variable "machine_type" {
  type    = string
  default = "e2-standard-4"
}

variable "preemptible" {
  type    = bool
  default = true
}

variable "node_count" {
  type    = number
  default = 1
}
