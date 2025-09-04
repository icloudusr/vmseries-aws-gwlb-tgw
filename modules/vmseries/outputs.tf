# =============================================================================
# VM-SERIES MODULE - OUTPUTS
# =============================================================================

# =============================================================================
# INSTANCE OUTPUTS
# =============================================================================

output "instance_id" {
  description = "List of VM-Series instance IDs"
  value       = aws_instance.vmseries[*].id
}

output "instance_details" {
  description = "Detailed information about VM-Series instances"
  value = [
    for idx, instance in aws_instance.vmseries : {
      id                = instance.id
      availability_zone = instance.availability_zone
      instance_type     = instance.instance_type
      private_ip        = instance.private_ip
      public_ip         = instance.public_ip
      instance_state    = instance.instance_state
      ami_id           = instance.ami
    }
  ]
}

# =============================================================================
# NETWORK INTERFACE OUTPUTS
# =============================================================================

output "eni0_id" {
  description = "List of ENI0 (Trust/Data) network interface IDs"
  value       = aws_network_interface.eni0[*].id
}

output "eni0_private_ip" {
  description = "List of ENI0 (Trust/Data) private IP addresses"
  value       = aws_network_interface.eni0[*].private_ip
}

output "eni1_id" {
  description = "List of ENI1 (Management) network interface IDs"
  value       = aws_network_interface.eni1[*].id
}

output "eni1_private_ip" {
  description = "List of ENI1 (Management) private IP addresses"
  value       = aws_network_interface.eni1[*].private_ip
}

output "eni2_id" {
  description = "List of ENI2 (Untrust/Data) network interface IDs (if created)"
  value       = var.eni2_subnet != null ? aws_network_interface.eni2[*].id : []
}

output "eni2_private_ip" {
  description = "List of ENI2 (Untrust/Data) private IP addresses (if created)"
  value       = var.eni2_subnet != null ? aws_network_interface.eni2[*].private_ip : []
}

# =============================================================================
# PUBLIC IP OUTPUTS
# =============================================================================

output "eni0_public_ip" {
  description = "List of ENI0 public IP addresses (if assigned)"
  value       = var.eni0_public_ip ? aws_eip.eni0[*].public_ip : []
}

output "eni1_public_ip" {
  description = "List of ENI1 public IP addresses (if assigned)"
  value       = var.eni1_public_ip ? aws_eip.eni1[*].public_ip : []
}

output "eni2_public_ip" {
  description = "List of ENI2 public IP addresses (if assigned)"
  value       = (var.eni2_subnet != null && var.eni2_public_ip) ? aws_eip.eni2[*].public_ip : []
}

output "management_public_ips" {
  description = "Management interface public IP addresses"
  value       = var.eni1_public_ip ? aws_eip.eni1[*].public_ip : []
}

# =============================================================================
# MANAGEMENT ACCESS OUTPUTS
# =============================================================================

output "management_urls" {
  description = "HTTPS management URLs for VM-Series firewalls"
  value = var.eni1_public_ip ? [
    for eip in aws_eip.eni1 : "https://${eip.public_ip}"
  ] : []
}

output "management_ssh_commands" {
  description = "SSH commands to access VM-Series management interfaces"
  value = var.eni1_public_ip ? [
    for idx, eip in aws_eip.eni1 : "ssh admin@${eip.public_ip} -i ~/.ssh/${var.key_name}.pem"
  ] : []
}

# =============================================================================
# SECURITY GROUP OUTPUTS
# =============================================================================

output "management_security_group_id" {
  description = "Management security group ID"
  value       = aws_security_group.management.id
}

output "data_security_group_id" {
  description = "Data plane security group ID"
  value       = aws_security_group.data.id
}

# =============================================================================
# SUMMARY OUTPUT
# =============================================================================

output "vm_series_summary" {
  description = "Summary of deployed VM-Series firewalls"
  value = {
    total_instances = local.vm_count
    instance_type   = var.size
    panos_version   = var.panos
    license_type    = var.license
    
    instances = [
      for idx in range(local.vm_count) : {
        name           = "${var.name}-${idx}"
        instance_id    = aws_instance.vmseries[idx].id
        trust_ip       = aws_network_interface.eni0[idx].private_ip
        mgmt_ip        = aws_network_interface.eni1[idx].private_ip
        untrust_ip     = var.eni2_subnet != null ? aws_network_interface.eni2[idx].private_ip : null
        mgmt_public_ip = var.eni1_public_ip ? aws_eip.eni1[idx].public_ip : null
        mgmt_url       = var.eni1_public_ip ? "https://${aws_eip.eni1[idx].public_ip}" : null
      }
    ]
  }
}

# =============================================================================
# AVAILABILITY ZONE OUTPUT
# =============================================================================

output "availability_zones" {
  description = "Availability zones where VM-Series instances are deployed"
  value       = distinct(aws_instance.vmseries[*].availability_zone)
}