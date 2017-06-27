############################
#
# Params/Prompts
# 
# Creates storage account & storage container if it doesn't already exist.
# Creates Shared Access Signature credential on SQL Server


Param(

    [Parameter(Mandatory=$true)] 
      [string] $resourceGroupName,
    [Parameter(Mandatory=$true)] 
      [string] $serverName, 
    [Parameter(Mandatory=$true)] 
      [string] $storageAccountName,
    [string] $subscriptionName = "My Subscription Name",
    [string] $storageLocation = "East US 2"
  )

Import-Module AzureRM
Import-Module Sqlserver

$containerName= $serverName.ToLower() + 'bu'  # the storage container name to which you will attach the SAS policy with its SAS token  
$policyName = $containerName.ToLower() + '_policy' # the name of the SAS policy 


# adds an authenticated Azure account for use in the session, if not already logged in 
Try {
    Select-AzureRmSubscription -SubscriptionName $subscriptionName -ErrorAction Stop
}
Catch{
    Add-AzureRmAccount -SubscriptionName $subscriptionName
}

# Create the storage account if you need to.
Try {
    Get-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName
    }
Catch {
    New-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName -Location $storageLocation -SkuName Standard_GRS -Kind BlobStorage -AccessTier Cool -EnableEncryptionService Blob
    }

# Get the access keys for the ARM storage account  
$accountKeys = Get-AzureRmStorageAccountKey -ResourceGroupName $resourceGroupName -Name $storageAccountName  


# Create a new storage account context using an ARM storage account  
$storageContext = New-AzureStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $accountKeys[0].Value 



# If necessary, Create a new container in blob storage  
Try {
    $container = Get-AzureStorageContainer -Context $StorageContext -Name $containerName 
    $cbc = $container.CloudBlobContainer  
    }    
Catch{
    $container = New-AzureStorageContainer -Context $storageContext -Name $containerName  
    $cbc = $container.CloudBlobContainer  
    }


# Sets up a Stored Access Policy and a Shared Access Signature for the new container  
$permissions = $cbc.GetPermissions();  
# $policyName = $policyName  
$policy = new-object 'Microsoft.WindowsAzure.Storage.Blob.SharedAccessBlobPolicy'  
$policy.SharedAccessStartTime = $(Get-Date).ToUniversalTime().AddMinutes(-5)  
$policy.SharedAccessExpiryTime = $(Get-Date).ToUniversalTime().AddYears(10)  
$policy.Permissions = "Read,Write,List,Delete"  
$permissions.SharedAccessPolicies.Add($policyName, $policy)  
$cbc.SetPermissions($permissions);  

# Gets the Shared Access Signature for the policy  
$policy = new-object 'Microsoft.WindowsAzure.Storage.Blob.SharedAccessBlobPolicy'  
$sas = $cbc.GetSharedAccessSignature($policy, $policyName)  
Write-Output 'Shared Access Signature: '$($sas.Substring(1))''  

# Outputs the Transact SQL to the clipboard and to the screen to create the credential using the Shared Access Signature  
Write-Output 'Credential T-SQL'  
$tSql = "CREATE CREDENTIAL [{0}] WITH IDENTITY='Shared Access Signature', SECRET='{1}'" -f $cbc.Uri,$sas.Substring(1)   
$tSql | clip  
Write-Output $tSql  


#Create the credential on the server
Invoke-Sqlcmd -ServerInstance $servername -Query $tsql

Write-Output "Your backup URL is: $($cbc.Uri)"