


$VMcsv = Import-Csv "Filepath"
$subscription = 
$i = 1
$domaintojoin = 
$userdomain =
$username = 
$password = 
$azurepath = new-item -Path $env:USERPROFILE\<NAME>-ItemType Directory -Force  
$LogFile = "$($azurepath.FullName)\LogFile.log"


$error.Clear()

out-file -InputObject "--------------------------------------------------------------------------------------------------" -Append -FilePath $LogFile
out-file -InputObject "$((Get-Date).tostring("dd-MM-yyyy-hh:mm:ss")) Script started" -Append -FilePath $logfile   
 
    
foreach ($VM in $VMcsv)
{ 


do {
   

$family = $VM.OSFamily
if ($vm.Image ) 
{ 
$image = $VM.Image
$imageStorageAccount = (Get-AzureVMImage -ImageName $VM.Image).OSDiskConfiguration.MediaLink.Host.Split('.')[0]
out-file -InputObject "$((Get-Date).tostring("dd-MM-yyyy-hh:mm:ss")) Beginning creation of VM $($vm.VMPrefix) with a custom image template in temporary storage account $($imageStorageAccount)" -Append -FilePath $logfile   
    
Write-Host "Beginning creation of VM $($vm.VMPrefix) with a custom image template" 


} 
else 

{ 
$imageStorageAccount = $vm.StorageAccount
$image = Get-AzureVMImage | where { $_.ImageFamily -eq $family } | sort PublishedDate -Descending | select -ExpandProperty ImageName -First 1
out-file -InputObject "$((Get-Date).tostring("dd-MM-yyyy-hh:mm:ss")) Beginning creation of VM $($vm.VMPrefix) with an OOB image template in storage account $($imageStorageAccount)" -Append -FilePath $logfile   
    
Write-Host "Beginning creation of VM $($vm.VMPrefix) with an OOB image template" 

}

If (!(Get-AzureStorageAccount -StorageAccountName $vm.StorageAccount -WarningAction SilentlyContinue -ErrorAction SilentlyContinue ) )
{ 
Write-Host "Storage account $($vm.StorageAccount) does not exist. Creating the storage account"
Out-File -InputObject "$((Get-Date).tostring("dd-MM-yyyy-hh:mm:ss")) Storage account $($vm.StorageAccount) does not exist. Creating the storage account" -Append -FilePath $LogFile
New-AzureStorageAccount -StorageAccountName $vm.StorageAccount -Location $vm.Location -Type "Standard_LRS" -WarningAction SilentlyContinue 

}

while (!((Get-AzureStorageAccount -StorageAccountName $vm.StorageAccount -WarningAction SilentlyContinue -ErrorAction SilentlyContinue).StorageAccountStatus -eq "Created"))
{
Write-Host " Waiting for $($vm.StorageAccount) to be created"
Start-Sleep -Seconds 10 
}

Write-Host "Creating the VM - $($vm.VMPrefix) in the $($imageStorageAccount)"
Out-File -InputObject "$((Get-Date).tostring("dd-MM-yyyy-hh:mm:ss")) Creating the VM - $($vm.VMPrefix) in the $($imageStorageAccount)" -Append -FilePath $LogFile
Set-AzureSubscription -SubscriptionName $subscription -CurrentStorageAccountName $imageStorageAccount
    #Find an image
   
        
     
        
       # $image = Get-AzureVMImage | where { $_.ImageFamily -eq $family } | sort PublishedDate -Descending | select -ExpandProperty ImageName -First 1
       
        $VMBuild = New-AzureVMConfig -Name $VM.VMprefix -ImageName $image -InstanceSize $VM.InstanceSize -AvailabilitySetName $VM.AvailabilitySet 
        
        
    
    #Add to domain, among other thigns
    $error.Clear()
    $VMBuild | Add-AzureProvisioningConfig -WindowsDomain  -AdminUsername $VM.AdminLogin-Password $VM.AdminPassword -JoinDomain $DOMAINTOJOIN -Domain $userdomain -DomainUserName $username -DomainPassword $password | Set-AzureSubnet -SubnetNames $VM.SubnetName |  Set-AzureStaticVNetIP -IPAddress $vm.IPAddress | New-AzureVM -ServiceName $VM.CloudService -VNetName $VM.VNetName -Location $vm.Location -WarningAction SilentlyContinue
    $vmcontext = Get-AzureVM -Name $vm.VMPrefix -ServiceName $vm.CloudService
    if($error[0])
    {
    Write-Host "Creation of $($vm.VMPrefix) in the $($imageStorageAccount) - FAILED. Proceeding to next VM. See log for more dettails" -ForegroundColor Yellow
    Out-File -InputObject "$((Get-Date).tostring("dd-MM-yyyy-hh:mm:ss")) Creation of $($vm.VMPrefix) in the $($imageStorageAccount) - FAILED. Error details $($error[0].Exception)" -Append -FilePath $LogFile
    continue
    }
    else

    {

    Write-Host "Successfully created $($vm.VMPrefix) in the $($imageStorageAccount)"
    Out-File -InputObject "$((Get-Date).tostring("dd-MM-yyyy-hh:mm:ss")) Successfully created $($vm.VMPrefix) in the $($imageStorageAccount)" -Append -FilePath $LogFile

    }

    while ( !($vmcontext.Status -eq 'ReadyRole')) 
    { 
    Write-Host "Waiting for $($vm.VMPrefix) to be provisioned completely in the $($imageStorageAccount). Sleeping for 50 seconds. Current status - $($vmcontext.Status)"
    Out-File -InputObject "$((Get-Date).tostring("dd-MM-yyyy-hh:mm:ss")) Waiting for $($vm.VMPrefix) to be provisioned completely in the $($imageStorageAccount). Sleeping for 50 seconds. Current status - $($vmcontext.Status)" -Append -FilePath $LogFile
    Start-Sleep -Seconds 50 
    $vmcontext = Get-AzureVM -Name $vm.VMPrefix -ServiceName $vm.CloudService
    
    }


    Write-Host "Successfully provisioned VM - $($vm.VMPrefix) in the $($imageStorageAccount)" -ForegroundColor Green
    Out-File -InputObject "Successfully provisioned VM - $($vm.VMPrefix) in the $($imageStorageAccount)" -Append -FilePath $LogFile
    if ( !($vm.Image ) )
    { 
    
     Write-Host "This VM $($vm.VMPrefix) does not have a custom image template, hence proceeding to the next VM without making any modifications"
     Out-File -InputObject "$((Get-Date).tostring("dd-MM-yyyy-hh:mm:ss")) This VM $($vm.VMPrefix) does not have a custom image template, hence proceeding to the next VM without making any modifications" -Append -FilePath $LogFile
     continue
    }    

    
    $vmcontext | Stop-AzureVM -Force

    while ( $vmcontext.Status -eq 'StoppedDeallocated') 
    {
    
    Write-Host "Waiting for $($vm.VMPrefix) to be shutdown completely in the $($imageStorageAccount). Sleeping for 10 seconds. Current status - $($vmcontext.Status)"
    Out-File -InputObject "$((Get-Date).tostring("dd-MM-yyyy-hh:mm:ss")) Waiting for $($vm.VMPrefix) to be provisioned completely in the $($imageStorageAccount). Sleeping for 10 seconds. Current status - $($vmcontext.Status)" -Append -FilePath $LogFile
    Start-Sleep -Seconds 10 
    $vmcontext = Get-AzureVM -Name $vm.VMPrefix -ServiceName $vm.CloudService

    }
    #Exporting Values in CSV 

    $pathOS = "$($azurepath.FullName)\$($vm.VMPrefix)-osdisk.csv"
    $pathdatadisk = "$($azurepath.FullName)\$($vm.VMPrefix)-datadisk.csv"
    $pathEndpoint = "$($azurepath.FullName)\$($vm.VMPrefix)-endpoint.csv"

        
    

    Get-AzureOSDisk -VM $vmcontext | Export-Csv -Append $pathOS
    
    Get-AzureDataDisk -VM $vmcontext | Export-Csv -Append $pathdatadisk
    
    $vmcontext | Get-AzureEndpoint | Export-Csv $pathEndpoint

    Write-Host "Exported OS disk and Data Disk information to the following folder--> $($azurepath.FullName)" -ForegroundColor Green
    Out-File -InputObject "$((Get-Date).tostring("dd-MM-yyyy-hh:mm:ss")) Exported OS disk and Data Disk information --> $($azurepath.FullName)"  -Append -FilePath $LogFile



    $error.Clear()
#Start BlobCopy 

Write-Host "waiting for 150 seconds to release the blob lease from source storage account - $($imageStorageAccount) in order to copy to  to $($vm.StorageAccount)" 
Out-File -InputObject "waiting for 150 seconds to release the blob lease from source storage account - $($imageStorageAccount) in order to copy to  to $($vm.StorageAccount)"  -Append -FilePath $LogFile

start-sleep -Seconds 150

Write-Host "Beginning Blob copy of VHDs from source storage account - $($imageStorageAccount)  to $($vm.StorageAccount)" 
Out-File -InputObject "$((Get-Date).tostring("dd-MM-yyyy-hh:mm:ss")) Beginning Blob copy of VHDs from source storage account - $($imageStorageAccount)  to $($vm.StorageAccount)"   -Append -FilePath $LogFile

$osdiskcsv = Import-Csv $pathOS
$datadiskcsv = Import-Csv $pathdatadisk
#$endpointsuffix = "core.usgovcloudapi.net"  ##Only add this is Azure GOV 
#$imageStorageAccount = (Get-AzureVMImage -ImageName $VM.Image).OSDiskConfiguration.MediaLink.Host.Split('.')[0]
foreach ($disk in $osdiskcsv ) 
{
$blob = $disk.MediaLink.Split('/')[4]
# Source Storage Account Information #
$sourceStorageAccountName = $imageStorageAccount
$sourceKey = (Get-AzureStorageKey -StorageAccountName $sourceStorageAccountName).Primary
#$sourceKey = $VM.SourceKey
$sourceContext = New-AzureStorageContext –StorageAccountName $sourceStorageAccountName -StorageAccountKey $sourceKey -Endpoint $endpointsuffix 
$sourceContainer = "vhds"

# Destination Storage Account Information #
$destinationStorageAccountName = $vm.StorageAccount
$destinationKey = (Get-AzureStorageKey -StorageAccountName $destinationStorageAccountName).Primary
#$destinationKey = $VM.DestinationKey
$destinationContext = New-AzureStorageContext –StorageAccountName $destinationStorageAccountName -StorageAccountKey $destinationKey -Endpoint $endpointsuffix

# Create the destination container #
$destinationContainerName = "vhds"
if (!( Get-AzureStorageContainer -Name $destinationContainerName -Context $destinationContext -ErrorAction SilentlyContinue ) )
{
New-AzureStorageContainer -Name $destinationContainerName -Context $destinationContext 
}

$error.Clear()
# Copy the blob # 
$blobCopy = Start-AzureStorageBlobCopy -DestContainer $destinationContainerName -DestContext $destinationContext -SrcBlob $blob -Context $sourceContext -SrcContainer $sourceContainer


if ( $error[0] ) 

{ 
Write-Host "Error copying OS disk from $($imageStorageAccount) to $($vm.StorageAccount)"
Out-File -InputObject "$((Get-Date).tostring("dd-MM-yyyy-hh:mm:ss")) Error copying OS disk from $($imageStorageAccount) to $($vm.StorageAccount). Error details $($error[0].Exception)"  -Append -FilePath $LogFile
} 
else 
{
Write-Host "Successfully copied OS disk from source storage account - $($imageStorageAccount)  to $($vm.StorageAccount)" 
Out-File -InputObject  "$((Get-Date).tostring("dd-MM-yyyy-hh:mm:ss")) Successfully copied OS disk from source storage account - $($imageStorageAccount)  to $($vm.StorageAccount)" -Append -FilePath $LogFile

}
}

 


foreach ($disk in $datadiskcsv ) 
{
$blob = $disk.MediaLink.Split('/')[4]
# Source Storage Account Information #
$sourceStorageAccountName = $imageStorageAccount
$sourceKey = (Get-AzureStorageKey -StorageAccountName $sourceStorageAccountName).Primary
#$sourceKey = $VM.SourceKey
$sourceContext = New-AzureStorageContext –StorageAccountName $sourceStorageAccountName -StorageAccountKey $sourceKey -Endpoint $endpointsuffix 
$sourceContainer = "vhds"

# Destination Storage Account Information #
$destinationStorageAccountName = $vm.StorageAccount
$destinationKey = (Get-AzureStorageKey -StorageAccountName $destinationStorageAccountName).Primary
#$destinationKey = $VM.DestinationKey
$destinationContext = New-AzureStorageContext –StorageAccountName $destinationStorageAccountName -StorageAccountKey $destinationKey -Endpoint $endpointsuffix

# Create the destination container #
$destinationContainerName = "vhds"
#New-AzureStorageContainer -Name $destinationContainerName -Context $destinationContext 

$destinationContainerName = "vhds"
if (!( Get-AzureStorageContainer -Name $destinationContainerName -Context $destinationContext -ErrorAction SilentlyContinue ) )
{
New-AzureStorageContainer -Name $destinationContainerName -Context $destinationContext 
}

$error.Clear()
# Copy the blob # 
$blobCopy = Start-AzureStorageBlobCopy -DestContainer $destinationContainerName -DestContext $destinationContext -SrcBlob $blob -Context $sourceContext -SrcContainer $sourceContainer

if ( $error[0] ) 

{ 
Write-Host "Error copying data disk $($disk.DiskName) from $($imageStorageAccount) to $($vm.StorageAccount)"
Out-File -InputObject "$((Get-Date).tostring("dd-MM-yyyy-hh:mm:ss")) Error copying data disk from $($disk.DiskName) - $($disk.Lun) from $($imageStorageAccount) to $($vm.StorageAccount). Error details $($error[0].Exception)"  -Append -FilePath $LogFile
} 
else
{
Write-Host "Successfully copied data disk $($disk.Lun) from source storage account - $($imageStorageAccount)  to $($vm.StorageAccount)" 
Out-File -InputObject  "$((Get-Date).tostring("dd-MM-yyyy-hh:mm:ss")) Successfully copied data disk $($disk.Lun) from source storage account - $($imageStorageAccount)  to $($vm.StorageAccount)" -Append -FilePath $LogFile

}
}







# Delete VMs
Write-Host "Deleting VM - $($vm.VMPrefix) from $($imageStorageAccount)" 
Out-File -InputObject "$((Get-Date).tostring("dd-MM-yyyy-hh:mm:ss")) Deleting VM - $($vm.VMPrefix) from $($imageStorageAccount)"  -Append -FilePath $LogFile



if ( $vm.DeleteDuplicateVHD -eq "True") 
{

Remove-AzureVM -Name $vm.VMPrefix -ServiceName $vm.CloudService -DeleteVHD 
Write-Host "Deleted the VM -->" $vm.VMPrefix.ToUpper() "and the associated VHDS in the custom template storage account" -ForegroundColor Green
}

else 

{ 
Remove-AzureVM -Name $vm.VMPrefix -ServiceName $vm.CloudService 
Write-Host "Deleted the VM -->" $vm.VMPrefix.ToUpper() "but retains the associated VHDS in the custom template storage account" -ForegroundColor Green
}

Write-Host "Successfully deleted the VM - $($vm.VMPrefix) from $($imageStorageAccount)" 
Out-File -InputObject "$((Get-Date).tostring("dd-MM-yyyy-hh:mm:ss")) Successfully deleted the VM - $($vm.VMPrefix) from $($imageStorageAccount)"  -Append -FilePath $LogFile


#Recreating VMs
Write-Host "Sleeping for 100 seconds to ensure deletion has been replicated across"
Out-File -InputObject "$((Get-Date).tostring("dd-MM-yyyy-hh:mm:ss")) Sleeping for 100 seconds to ensure deletion has been replicated across" -Append -FilePath $LogFile
Start-Sleep -Seconds 100 


Write-Host "Creating VM - $($vm.VMPrefix) in destination storage account - $($vm.StorageAccount)" 
Out-File -InputObject "$((Get-Date).tostring("dd-MM-yyyy-hh:mm:ss")) Creating VM - $($vm.VMPrefix) in destination storage account - $($vm.StorageAccount)" -Append -FilePath $LogFile

$medialocation = $osdiskcsv.MediaLink.Replace($imageStorageAccount,$vm.StorageAccount)

Set-AzureSubscription -SubscriptionName $subscription -CurrentStorageAccountName $vm.StorageAccount
Set-AzureStorageServiceMetricsProperty -MetricsType Minute -ServiceType Blob -MetricsLevel ServiceAndApi  -RetentionDays 5
Set-AzureStorageServiceLoggingProperty -ServiceType Blob -LoggingOperations read,write,delete -RetentionDays 5
$diskname = "$($vm.VMPrefix)-OSDisk"
$error.Clear()
Add-AzureDisk -DiskName $diskname -MediaLocation $medialocation -Label "OS Disk for $($vm.VMPrefix)" -OS "Windows"


if ( $error[0] ) 

{ 
Write-Host "Error creating OS disk $($diskname) from $($medialocation) for $($vm.VMPrefix)"
Out-File -InputObject "Error create OS disk $($diskname) from $($medialocation) for $($vm.VMPrefix). Error details $($error[0].Exception)"  -Append -FilePath $LogFile
} 
else
{
Write-Host "Successfully created OS disk $($diskname) from $($medialocation) for $($vm.VMPrefix)"
Out-File -InputObject  "Successfully created OS disk $($diskname) from $($medialocation) for $($vm.VMPrefix)" -Append -FilePath $LogFile

}


$AzureVMConfigNew = New-AzureVMConfig -Name $vm.VMPrefix -InstanceSize $vm.InstanceSize -AvailabilitySetName $vm.AvailabilitySet -DiskName $diskname

foreach ( $ddisk in $datadiskcsv ) 
{

$medialocationdd = $ddisk.MediaLink.Replace($imageStorageAccount,$vm.StorageAccount)
$AzureVMConfigNew | Add-AzureDataDisk -ImportFrom -DiskLabel "Disk$($ddisk.Lun)" -LUN $ddisk.Lun -MediaLocation $medialocationdd

}

$error.Clear()
$AzureVMConfigNew | Set-AzureSubnet $vm.SubnetName | Set-AzureStaticVNetIP -IPAddress $vm.IPAddress  | New-AzureVM -ServiceName $vm.CloudService -Location $vm.Location -VNetName $vm.VNetName

if ( $error[0] ) 

{ 
Write-Host "Error creating VM $($vm.VMPrefix)"
Out-File -InputObject "Error creating VM $($vm.VMPrefix). Error details $($error[0].Exception)"  -Append -FilePath $LogFile
} 
else
{
Write-Host "$((Get-Date).tostring("dd-MM-yyyy-hh:mm:ss")) Successfully created the VM - $($vm.VMPrefix) in destination storage account - $($vm.StorageAccount)" 
Out-File -InputObject "$((Get-Date).tostring("dd-MM-yyyy-hh:mm:ss")) Successfully created the VM - $($vm.VMPrefix) in destination storage account - $($vm.StorageAccount)" -Append -FilePath $LogFile

}



    $i++
    }



while ($i -le $vm.numberOfVMs)



}

out-file -InputObject "$((Get-Date).tostring("dd-MM-yyyy-hh:mm:ss")) Script ended" -Append -FilePath $logfile   























