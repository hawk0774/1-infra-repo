resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/templates/inventory.tpl", {
    lb_ip = one(flatten([
      for listener in yandex_lb_network_load_balancer.k8s_api_lb.listener :
      [for spec in listener.external_address_spec : spec.address]
      if length(listener.external_address_spec) > 0
    ]))

    masters = [
      for m in yandex_compute_instance.masters :
      m.network_interface[0].nat_ip_address
    ]

    workers = [
      for w in yandex_compute_instance.workers :
      w.network_interface[0].nat_ip_address
    ]
  })

  filename = "${path.module}/inventory.ini"
}

