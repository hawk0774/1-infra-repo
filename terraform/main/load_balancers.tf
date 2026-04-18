# --- L4 Балансировщик для Kubernetes API (external NLB) ---

resource "yandex_lb_target_group" "k8s_api_tg" {
  name = "k8s-api-tg"

  dynamic "target" {
    for_each = yandex_compute_instance.masters
    content {
      subnet_id = target.value.network_interface[0].subnet_id
      address   = target.value.network_interface[0].ip_address
    }
  }
}

resource "yandex_lb_network_load_balancer" "k8s_api_lb" {
  name = "k8s-api-lb"

  listener {
    name = "api-listener"
    port = var.k8s_api_port

    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.k8s_api_tg.id

    healthcheck {
      name                = "tcp"
      timeout             = 3
      interval            = 5
      healthy_threshold   = 3
      unhealthy_threshold = 3

      tcp_options {
        port = var.k8s_api_port
      }
    }
  }
}

# --- L7 Балансировщик для Ingress / Istio ---

resource "yandex_alb_target_group" "k8s_workers_tg" {
  name = "k8s-workers-alb-tg"

  dynamic "target" {
    for_each = yandex_compute_instance.workers
    content {
      subnet_id  = target.value.network_interface[0].subnet_id
      ip_address = target.value.network_interface[0].ip_address
    }
  }
}

resource "yandex_alb_backend_group" "istio_backend" {
  name = "istio-backend-group"

  http_backend {
    name             = "istio-nodeport"
    weight           = 1
    port             = var.istio_node_port
    target_group_ids = [yandex_alb_target_group.k8s_workers_tg.id]

    healthcheck {
      timeout             = "10s"
      interval            = "5s"
      healthy_threshold   = 3
      unhealthy_threshold = 5
      healthcheck_port    = var.istio_node_port

      stream_healthcheck {}
    }
  }
}

resource "yandex_alb_http_router" "main_router" {
  name = "main-http-router"
}

resource "yandex_alb_virtual_host" "main_host" {
  name           = "main-virtual-host"
  http_router_id = yandex_alb_http_router.main_router.id

  route {
    name = "route-to-istio"

    http_route {
      http_route_action {
        backend_group_id = yandex_alb_backend_group.istio_backend.id
        timeout          = "60s"
      }
    }
  }
}

resource "yandex_alb_load_balancer" "main_alb" {
  name               = "main-alb"
  network_id         = yandex_vpc_network.k8s_vpc.id
  security_group_ids = [yandex_vpc_security_group.alb_sg.id]

  allocation_policy {
    dynamic "location" {
      for_each = yandex_vpc_subnet.k8s_subnets
      content {
        zone_id   = location.value.zone
        subnet_id = location.value.id
      }
    }
  }

  listener {
    name = "http-listener"

    endpoint {
      address {
        external_ipv4_address {}
      }
      ports = [80]
    }

    http {
      handler {
        http_router_id = yandex_alb_http_router.main_router.id
      }
    }
  }
}
