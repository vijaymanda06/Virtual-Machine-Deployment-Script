# PowerCLI script to create Virtual Machines
# ===========================================
# It can create new VM or deploy VM from template if template name is specified.

Clear-Host

Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false

# Prompt user for vCenter Server configuration
$vcenter = Read-Host "Enter vCenter Server IP or hostname"
$vcenteruser = Read-Host "Enter vCenter Server username"
$vcenterpw = Read-Host "Enter vCenter Server password" -AsSecureString

# Prompt user for VM creation parameters
$vm_count = Read-Host "Enter number of VMs to create"
$Datastore = Read-Host "Enter vCenter Server datastore name"
$Folder = Read-Host "Enter vCenter Server Virtual Machine & Templates folder name"
$Cluster = Read-Host "Enter vSphere Cluster name"
$VM_prefix = Read-Host "Enter VM name prefix"
$VM_create_async = Read-Host "Create VMs asynchronously? (yes/no)"
$VM_from_template = Read-Host "Enter template name (leave blank for new VM)"
$VM_power_on = Read-Host "Power on VMs after creation? (yes/no)"

# Prompt user for new VM parameters (if not using template)
if ($VM_from_template -eq "") {
  $numcpu = Read-Host "Enter number of VM CPUs"
  $MBram = Read-Host "Enter VM memory size (in MB)"
  $MBguestdisk = Read-Host "Enter VM disk size (in MB)"
  $Typeguestdisk = Read-Host "Enter VM disk type (Thin, Thick, EagerZeroedThick)"
  $guestOS = Read-Host "Enter VM guest OS"
}

# Convert secure string to plain text
$vcenterpw_plain = (New-Object System.Management.Automation.PSCredential("dummy", $vcenterpw)).GetNetworkCredential().Password

# Connect to vCenter Server
try {
  Write-Host "Connecting to vCenter Server $vcenter" -ForegroundColor Green
  Connect-VIServer $vcenter -User $vcenteruser -Password $vcenterpw_plain
} catch {
  Write-Host "Error connecting to vCenter Server: $_" -ForegroundColor Red
  exit
}

1..$vm_count | ForEach-Object {
  $VM_postfix = "{0:D2}" -f $_
  $VM_name = $VM_prefix + $VM_postfix

  $folder_obj = Get-Folder -Name $Folder -Location (Get-Datacenter)

  if ($VM_from_template -eq "") {
    Write-Host "Creation of VM $VM_name initiated" -ForegroundColor Green
    New-VM -RunAsync:($VM_create_async.ToLower() -eq "yes") -Name $VM_name -ResourcePool $Cluster -NumCpu $numcpu -MemoryMB $MBram -DiskMB $MBguestdisk -DiskStorageFormat $Typeguestdisk -Datastore $Datastore -GuestId $guestOS -Location $folder_obj[0]
  } else {
    Write-Host "Deployment of VM $VM_name from template $VM_from_template initiated" -ForegroundColor Green
    New-VM -RunAsync:($VM_create_async.ToLower() -eq "yes") -Name $VM_name -Template $VM_from_template -ResourcePool $Cluster -Datastore $Datastore -Location $folder_obj[0]
  }

  if ($VM_power_on.ToLower() -eq "yes") {
    Start-VM -VM $VM_name
  }
}
