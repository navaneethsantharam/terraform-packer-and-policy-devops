terraform {
  required_version = ">=0.12"
  
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~>2.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "random_string" "fqdn" {
 length  = 10
 special = false
 upper   = false
 number  = false
}

resource "azurerm_virtual_network" "example" {
  name                = "example-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = var.resource_group_name
  tags = var.tags
}

resource "azurerm_subnet" "example" {
  name                 = "example-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes       = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "example" {
  name                         = "example-public-ip"
  location                     = var.location
  resource_group_name          = var.resource_group_name
  allocation_method            = "Static"
  domain_name_label            = random_string.fqdn.result
  tags = var.tags
}

resource "azurerm_lb" "example" {
  name                = "example-lb"
  location            = var.location
  resource_group_name = var.resource_group_name

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.example.id
  }

  tags = var.tags
}

resource "azurerm_lb_backend_address_pool" "bpepool" {
  loadbalancer_id     = azurerm_lb.example.id
  name                = "BackEndAddressPool"
}

resource "azurerm_lb_probe" "example" {
  resource_group_name = var.resource_group_name
  loadbalancer_id     = azurerm_lb.example.id
  name                = "ssh-running-probe"
  port                = var.application_port
}

resource "azurerm_lb_rule" "lbnatrule" {
  loadbalancer_id                = azurerm_lb.example.id
  resource_group_name            = var.resource_group_name
  name                           = "http"
  protocol                       = "Tcp"
  frontend_port                  = var.application_port
  backend_port                   = var.application_port
  backend_address_pool_id        = azurerm_lb_backend_address_pool.bpepool.id
  frontend_ip_configuration_name = "PublicIPAddress"
  probe_id                       = azurerm_lb_probe.example.id
}

data "azurerm_resource_group" "image" {
  name                = var.packer_resource_group_name
}

data "azurerm_image" "image" {
  name                = var.packer_image_name
  resource_group_name = data.azurerm_resource_group.image.name
}


resource "azurerm_network_security_group" "nsg" {
  name                = "nsg"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
  
  security_rule {
    name                       = "denyinternettraffichttp"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
 
  security_rule {
    name                       = "denyinternettraffichttps"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  
}


resource "azurerm_virtual_machine_scale_set" "example" {
  name                = "vmscaleset"
  location            = var.location
  resource_group_name = var.resource_group_name
  upgrade_policy_mode = "Manual"
  
  sku {
    name     = "Standard_DS1_v2"
    tier     = "Standard"
    capacity = var.instances_count
  }

  storage_profile_image_reference {
    id=data.azurerm_image.image.id
  }

  storage_profile_os_disk {
    name              = ""
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_profile_data_disk {
    lun          = 0
    caching        = "ReadWrite"
    create_option  = "Empty"
    disk_size_gb   = 10
  }

  os_profile {
    computer_name_prefix = "vmlab"
    admin_username       = var.admin_user
    admin_password       = var.admin_password
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/azureuser/.ssh/authorized_keys"
      key_data = file("~/.ssh/id_rsa.pub")
    }
  }

  network_profile {
    name    = "terraformnetworkprofile"
    primary = true

    ip_configuration {
      name                                   = "IPConfiguration"
      subnet_id                              = azurerm_subnet.example.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.bpepool.id]
      primary = true
    }
  }
  
  tags = var.tags
}