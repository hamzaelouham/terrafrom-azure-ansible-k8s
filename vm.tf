# =============================================================================
# Master Node
# =============================================================================

# Network Interface for Master
resource "azurerm_network_interface" "master" {
  name                = "nic-${var.master_vm_name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = var.tags
}

# Master VM
resource "azurerm_linux_virtual_machine" "master" {
  name                = var.master_vm_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = var.master_vm_size
  admin_username      = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.master.id
  ]

  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_public_key_path)
  }

  custom_data = base64encode(templatefile("${path.module}/templates/cloud-init.yaml.tftpl", {
    username       = var.admin_username
    ssh_public_key = file(var.ssh_public_key_path)
  }))

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = var.os_disk_size_gb
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  tags = merge(var.tags, {
    Role = "master"
  })
}

# =============================================================================
# Worker Nodes
# =============================================================================

# Network Interfaces for Workers
resource "azurerm_network_interface" "worker" {
  count               = var.worker_count
  name                = "nic-${var.worker_vm_name_prefix}-${count.index + 1}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = var.tags
}

# Worker VMs
resource "azurerm_linux_virtual_machine" "worker" {
  count               = var.worker_count
  name                = "${var.worker_vm_name_prefix}-${count.index + 1}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = var.worker_vm_size
  admin_username      = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.worker[count.index].id
  ]

  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_public_key_path)
  }

  custom_data = base64encode(templatefile("${path.module}/templates/cloud-init.yaml.tftpl", {
    username       = var.admin_username
    ssh_public_key = file(var.ssh_public_key_path)
  }))

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = var.os_disk_size_gb
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  tags = merge(var.tags, {
    Role = "worker"
  })
}
