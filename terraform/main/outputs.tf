locals {
  k8s_api_external_ip = one(flatten([
    for listener in yandex_lb_network_load_balancer.k8s_api_lb.listener :
    [for spec in listener.external_address_spec : spec.address]
    if length(listener.external_address_spec) > 0
  ]))
}

output "k8s_api_lb_external_ip" {
  description = "Внешний IP API Load Balancer"
  value       = local.k8s_api_external_ip
}

output "main_alb_external_ip" {
  description = "Внешний IP ALB для Ingress/Istio"
  value       = yandex_alb_load_balancer.main_alb.listener[0].endpoint[0].address[0].external_ipv4_address[0].address
}

output "cluster_info" {
  description = "Основная информация о кластере"
  value = {
    masters      = { for vm in yandex_compute_instance.masters : vm.name => vm.network_interface[0].nat_ip_address }
    workers      = { for vm in yandex_compute_instance.workers : vm.name => vm.network_interface[0].nat_ip_address }
    k8s_api_ip   = local.k8s_api_external_ip
    k8s_api_port = 6443
    alb_url      = "http://${yandex_alb_load_balancer.main_alb.listener[0].endpoint[0].address[0].external_ipv4_address[0].address}"
    ansible_file = local_file.ansible_inventory.filename
  }
}
