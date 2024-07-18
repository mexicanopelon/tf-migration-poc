resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name = "${var.resource_group_name}_${var.env}"

  tags = {
    Department = var.department
    Project = var.project
    Owner = var.owner
    Environment = var.env
    Release = var.release
  }
}

# Create virtual network
resource "azurerm_virtual_network" "my_terraform_network" {
  name                = "${var.username}Vnet_${var.env}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = {
    Department = var.department
    Project = var.project
    Owner = var.owner
    Environment = var.env
    Release = var.release
  }
}

# Create subnet
resource "azurerm_subnet" "my_terraform_subnet" {
  name                 = "${var.username}Subnet_${var.env}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.my_terraform_network.name
  address_prefixes     = ["10.0.1.0/24"]

}

# Create public IPs
resource "azurerm_public_ip" "my_terraform_public_ip" {
  name                = "${var.username}PublicIP_${var.env}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"

  tags = {
    Department = var.department
    Project = var.project
    Owner = var.owner
    Environment = var.env
    Release = var.release
  }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "my_terraform_nsg" {
  name                = "${var.username}NetworkSecurityGroup_${var.env}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    Department = var.department
    Project = var.project
    Owner = var.owner
    Environment = var.env
    Release = var.release
  }
}

# Create network interface
resource "azurerm_network_interface" "my_terraform_nic" {
  name                = "${var.username}NIC_${var.env}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "${var.username}_nic_configuration_${var.env}"
    subnet_id                     = azurerm_subnet.my_terraform_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.my_terraform_public_ip.id
  }

  tags = {
    Department = var.department
    Project = var.project
    Owner = var.owner
    Environment = var.env
    Release = var.release
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.my_terraform_nic.id
  network_security_group_id = azurerm_network_security_group.my_terraform_nsg.id
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "my_storage_account" {
  name                     = "${var.username}123${var.env}"
  location                 = azurerm_resource_group.rg.location
  resource_group_name      = azurerm_resource_group.rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    Department = var.department
    Project = var.project
    Owner = var.owner
    Environment = var.env
    Release = var.release
  }
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "my_terraform_vm" {
  name                  = "${var.username}VM_${var.env}"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.my_terraform_nic.id]
  size                  = "Standard_DS1_v2"

  os_disk {
    name                 = "${var.username}OsDisk_${var.env}"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  computer_name  = "hostname"
  admin_username = var.username

  admin_ssh_key {
    username   = var.username
    # public_key = jsondecode(azapi_resource_action.ssh_public_key_gen.output).publicKey
    public_key = azapi_resource_action.ssh_public_key_gen.output.publicKey
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.my_storage_account.primary_blob_endpoint
  }

  tags = {
    Department = var.department
    Project = var.project
    Owner = var.owner
    Environment = var.env
    Release = var.release
  }
}
