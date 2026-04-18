resource "yandex_vpc_network" "k8s_vpc" {
  name = "k8s-network"
}

resource "yandex_vpc_subnet" "k8s_subnets" {
  count          = length(var.zones)
  name           = "k8s-subnet-${var.zones[count.index]}"
  zone           = var.zones[count.index]
  network_id     = yandex_vpc_network.k8s_vpc.id
  v4_cidr_blocks = [var.subnet_cidrs[count.index]]
}

# ==========================================
# Security Group для Application Load Balancer
# ==========================================
resource "yandex_vpc_security_group" "alb_sg" {
  name       = "alb-security-group"
  network_id = yandex_vpc_network.k8s_vpc.id

  ingress {
    description    = "Allow HTTP from internet"
    protocol       = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80
  }

  ingress {
    description    = "Allow HTTPS from internet"
    protocol       = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 443
  }

  ingress {
    description       = "Healthchecks from Yandex Load Balancers"
    protocol          = "TCP"
    predefined_target = "loadbalancer_healthchecks"
    from_port         = 0
    to_port           = 65535
  }

  egress {
    description    = "Allow all outbound"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

# ==========================================
# Security Group для Kubernetes Nodes
# ==========================================
resource "yandex_vpc_security_group" "k8s_nodes_sg" {
  name       = "k8s-nodes-sg"
  network_id = yandex_vpc_network.k8s_vpc.id

  # Внутрикластерное общение нод (любой с любым внутри группы)
  ingress {
    description       = "Allow all traffic between cluster nodes"
    protocol          = "ANY"
    predefined_target = "self_security_group"
    from_port         = 0
    to_port           = 65535
  }

  # Трафик из подсетей VPC, Pod CIDR и Service CIDR
  ingress {
    description    = "Allow traffic from VPC Subnets, Pod and Service CIDRs"
    protocol       = "ANY"
    v4_cidr_blocks = concat(var.subnet_cidrs, [var.pod_network_cidr, var.service_network_cidr])
    from_port      = 0
    to_port        = 65535
  }

  # SSH (доступ только для администраторов и Ansible)
  ingress {
    description    = "SSH Access"
    protocol       = "TCP"
    v4_cidr_blocks = var.admin_ips
    port           = 22
  }

  # Трафик от ALB на Istio NodePort
  ingress {
    description       = "Traffic from ALB to Istio NodePort"
    protocol          = "TCP"
    security_group_id = yandex_vpc_security_group.alb_sg.id
    port              = var.istio_node_port
  }

  # Проверки состояния от балансировщиков Яндекса
  ingress {
    description       = "Healthchecks from Yandex Load Balancers to nodes"
    protocol          = "TCP"
    predefined_target = "loadbalancer_healthchecks"
    from_port         = 0
    to_port           = 65535
  }

  # Доступ в интернет с нод
  egress {
    description    = "Allow all outbound"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

# ==========================================
# Отдельные правила Security Group 
# ==========================================

# Разрешаем доступ к API-серверу
resource "yandex_vpc_security_group_rule" "api_access" {
  security_group_binding = yandex_vpc_security_group.k8s_nodes_sg.id
  direction              = "ingress"
  description            = "Kube API Access"
  protocol               = "TCP"
  port                   = var.k8s_api_port

  v4_cidr_blocks = compact(concat(
    var.admin_ips,
    var.subnet_cidrs,
    [for instance in yandex_compute_instance.masters : "${instance.network_interface.0.nat_ip_address}/32"],
    [for instance in yandex_compute_instance.workers : "${instance.network_interface.0.nat_ip_address}/32"]
  ))
}
