provider "azurerm" {
  features {} 
  #export ARM_SUBSCRIPTION_ID=
}
variable "new_resource_group_name" {
  description = "Name of the new resource group for the VM"
  type        = string
  default     = "rgauevmpi"
}

variable "existing_resource_group_name" {
  description = "Name of the existing resource group for the VNet"
  type        = string
  default     = "RGAUEGWComputoi"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "australiaeast"   
}

variable "vnet_name" {
  description = "Name of the existing Virtual Network"
  type        = string
  default     = "vnetauecomputo"
}

variable "subnet_name" {
  description = "Name of the existing subnet (vnetauecomputo)"
  type        = string
  default     = "vnetauecomputo"
}

variable "ssh_public_key_path" {
  description = "Path to the existing SSH public key"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "vm_size" {
  description = "Size of the VM"
  type        = string
  default     = "Standard_B1s"  # Burstable VM size
}

variable "vm_name" {
  description = "Name of the Pi-hole VM"
  type        = string
  default     = "vmauepihole"
}

variable "lb_name" {
  description = "Name of the Load Balancer"
  type        = string
  default     = "ilbpiholeaue"
}

data "azurerm_resource_group" "existing" {
  name = var.existing_resource_group_name
}

data "azurerm_virtual_network" "existing" {
  name                = var.vnet_name
  resource_group_name = data.azurerm_resource_group.existing.name
}

data "azurerm_subnet" "existing" {
  name                 = var.subnet_name
  virtual_network_name = data.azurerm_virtual_network.existing.name
  resource_group_name  = data.azurerm_resource_group.existing.name
}

resource "azurerm_resource_group" "new" {
  name     = var.new_resource_group_name
  location = var.location
}

resource "azurerm_public_ip" "vm" {
  name                = "${var.vm_name}-pip"
  location            = azurerm_resource_group.new.location
  resource_group_name = azurerm_resource_group.new.name
  allocation_method   = "Static"  # Use Static if you need a persistent IP
  sku = "Standard"
}

resource "azurerm_network_interface" "vm" {
  name                = "${var.vm_name}-nic"
  location            = azurerm_resource_group.new.location
  resource_group_name = azurerm_resource_group.new.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.existing.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm.id
  }
}

resource "azurerm_linux_virtual_machine" "pihole" {
  name                = var.vm_name
  location            = azurerm_resource_group.new.location
  resource_group_name = azurerm_resource_group.new.name
  size                = var.vm_size
  admin_username      = "roberto"
  network_interface_ids = [
    azurerm_network_interface.vm.id,
  ]

  admin_ssh_key {
    username   = "roberto"
    public_key = file(var.ssh_public_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

resource "azurerm_public_ip" "lb" {
  name                = "${var.lb_name}-pip"
  location            = azurerm_resource_group.new.location
  resource_group_name = azurerm_resource_group.new.name
  allocation_method   = "Static"  # Static IP for the Load Balancer
  sku = "Standard"
}

# resource "azurerm_lb" "pihole" {
#   name                = var.lb_name
#   location            = azurerm_resource_group.new.location
#   resource_group_name = azurerm_resource_group.new.name
#   sku                 = "Standard"  # Use "Standard" for advanced features

#   frontend_ip_configuration {
#     name                 = "frontend"
#     public_ip_address_id = azurerm_public_ip.lb.id
#   }
# }

# resource "azurerm_lb_backend_address_pool" "pihole" {
#   loadbalancer_id = azurerm_lb.pihole.id
#   name            = "backend-pool"
# }

# resource "azurerm_lb_probe" "pihole" {
#   loadbalancer_id = azurerm_lb.pihole.id
#   name            = "health-probe"
#   port            = 80  # TCP health probe (Pi-hole admin interface)
# }

# resource "azurerm_lb_rule" "pihole" {
#   loadbalancer_id                = azurerm_lb.pihole.id
#   name                           = "dns-rule"
#   protocol                       = "Udp"
#   frontend_port                  = 53
#   backend_port                   = 53
#   frontend_ip_configuration_name = "frontend"
#   backend_address_pool_ids       = [azurerm_lb_backend_address_pool.pihole.id]
#   probe_id                       = azurerm_lb_probe.pihole.id
# }