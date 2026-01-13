# =============================================================================
# Ansible Integration
# =============================================================================

# Generate Ansible inventory from Terraform outputs
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/templates/inventory.tftpl", {
    master_ip    = azurerm_network_interface.master.private_ip_address
    worker_ips   = azurerm_network_interface.worker[*].private_ip_address
    ssh_user     = var.admin_username
    ssh_password = var.admin_password
  })
  filename        = "${path.module}/ansible/inventory"
  file_permission = "0600"

  depends_on = [
    azurerm_linux_virtual_machine.master,
    azurerm_linux_virtual_machine.worker
  ]
}

# Wait for VMs to be ready before running Ansible
resource "null_resource" "wait_for_vms" {
  depends_on = [
    azurerm_linux_virtual_machine.master,
    azurerm_linux_virtual_machine.worker
  ]

  # Wait for VMs to be fully booted
  provisioner "local-exec" {
    command = "echo 'Waiting 60 seconds for VMs to boot...' && sleep 60"
  }
}

# Run Ansible playbook to set up Kubernetes cluster
resource "null_resource" "run_ansible" {
  depends_on = [
    local_file.ansible_inventory,
    null_resource.wait_for_vms
  ]

  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command     = "ansible-playbook -i inventory k8s/k8s-main.yaml -e k8s_version=${var.k8s_version}"
    working_dir = "${path.module}/ansible"
    environment = {
      ANSIBLE_HOST_KEY_CHECKING = "False"
    }
  }
}
