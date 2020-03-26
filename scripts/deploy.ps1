param(
    $location = 'australiasoutheast',
    $prefix = 'aks-slb-vmss-mid',
    $rgName = "$prefix-rg",
    $spName = "$prefix-sp",
    $deploymentName = $('{0}-{1}-{2}' -f $prefix, 'deployment', (Get-Date).ToFileTime()),
    $containerName = 'templates',
    $aksVersion = '1.16.7',
    $aksNodeCount = 1,
    $aksMaxPods = 50,
    $aksNodeVMSize = 'Standard_D2s_v3',
    $tags = @{
        'environment' = 'dev'
        'app'         = 'testapp'
    }
)

$sasTokenExpiry = (Get-Date).AddHours(2).ToString('u') -replace ' ', 'T'

# create resource group
if (!($rg = Get-AzResourceGroup -Name $rgName -Location $location -ErrorAction SilentlyContinue)) {
    $rg = New-AzResourceGroup -Name $rgName -Location $location
}

# start storage account template deployment
$storageDeployment = New-AzResourceGroupDeployment `
    -Name $deploymentName `
    -ResourceGroupName $rg.ResourceGroupName `
    -Mode Incremental `
    -TemplateFile $PSScriptRoot\..\templates\nested\storage.json `
    -Tags $tags `
    -ContainerName $containerName `
    -SasTokenExpiry $sasTokenExpiry

# upload ARM template files to blob storage account
$sa = Get-AzStorageAccount -ResourceGroupName $rgName -Name $storageDeployment.Outputs.storageAccountName.Value
Get-ChildItem $PSScriptRoot\..\templates\nested -Filter *.json -File | ForEach-Object {
    Set-AzStorageBlobContent `
        -File $_.FullName `
        -Context $sa.Context `
        -Container $containerName `
        -Blob $_.Name `
        -BlobType Block `
        -Force
}

# start ARM template deployment
New-AzResourceGroupDeployment -Name $deploymentName `
    -ResourceGroupName $rg.ResourceGroupName `
    -Mode Incremental `
    -TemplateFile $PSScriptRoot\..\templates\azuredeploy.json `
    -TemplateParameterFile $PSScriptRoot\..\templates\azuredeploy.parameters.json `
    -AksNodeCount $aksNodeCount `
    -AksNodeVMSize $aksNodeVMSize `
    -AksVersion $aksVersion `
    -MaxPods $aksMaxPods `
    -StorageUri $storageDeployment.Outputs.storageContainerUri.value `
    -SasToken $storageDeployment.Outputs.storageAccountSasToken.value `
    -Tags $tags `
    -Verbose
