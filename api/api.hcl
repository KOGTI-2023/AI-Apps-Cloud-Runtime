variable "gcp_zone" {
  type = string
}

variable "image_name" {
  type = string
}

variable "api_port_name" {
  type = string
}

variable "api_port_number" {
  type = number
}

variable "nomad_address" {
  type = string
}

variable "nomad_token" {
  type = string
}

variable "logs_proxy_address" {
  type = string
}

variable "supabase_url" {
  type = string
}

variable "supabase_key" {
  type = string
}

variable "api_admin_key" {
  type = string
}

job "orchestration-api" {
  datacenters = [var.gcp_zone]

  priority = 90

  group "api-service" {
    network {
      port "api" {
        static = var.api_port_number
      }
    }

    service {
      name = "api"
      port = var.api_port_number

      check {
        type     = "http"
        name     = "health"
        path     = "/health"
        interval = "20s"
        timeout  = "5s"
        port     = var.api_port_number
      }
    }

    task "start" {
      driver = "docker"

      resources {
        memory = 256
        cpu    = 400
      }

      env {
        LOGS_PROXY_ADDRESS = var.logs_proxy_address
        NOMAD_ADDRESS      = var.nomad_address
        NOMAD_TOKEN      = var.nomad_token
        SUPABASE_URL       = var.supabase_url
        SUPABASE_KEY       = var.supabase_key
        API_ADMIN_KEY      = var.api_admin_key
      }

      config {
        network_mode = "host"
        image        = var.image_name
        ports        = [var.api_port_name]
        args = [
          "--port", "${var.api_port_number}",
        ]
      }
    }
  }
}
