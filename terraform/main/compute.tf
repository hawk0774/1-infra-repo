data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2204-lts"
}

# Мастер-ноды
resource "yandex_compute_instance" "masters" {
  count       = var.master_count
  name        = "master-${count.index + 1}"
  platform_id = "standard-v2"
  
  zone = element(var.zones, count.index % length(var.zones))

  resources {
    cores         = var.vm_resources["cores"]
    memory        = var.vm_resources["memory"]
    core_fraction = var.vm_resources["core_fraction"]
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = var.vm_resources["disk_size"]
    }
  }

  network_interface {
    # Берем подсеть, соответствующую выбранной зоне
    subnet_id          = yandex_vpc_subnet.k8s_subnets[count.index % length(var.zones)].id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.k8s_nodes_sg.id]
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_pub_key_path)}"
  }
}

# Воркер-ноды 
resource "yandex_compute_instance" "workers" {
  count       = var.worker_count
  name        = "worker-${count.index + 1}"
  platform_id = "standard-v2"
  
  zone = element(var.zones, count.index % length(var.zones))

#  scheduling_policy {
#    preemptible = true
#  }

  resources {
    cores         = var.vm_resources["cores"]
    memory        = var.vm_resources["memory"]
    core_fraction = var.vm_resources["core_fraction"]
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = var.vm_resources["disk_size"]
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.k8s_subnets[count.index % length(var.zones)].id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.k8s_nodes_sg.id]
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_pub_key_path)}"
  }
}