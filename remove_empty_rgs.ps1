$ErrorActionPreference = "Stop"
$tenantId = "<YOUR_TENANT_ID>"

# Enter your service principal client ID & secret here
# You will get the client ID and client secret after creating the service principal.
$clientId = "<YOUR_CLIENT_ID>"
$clientSecret = "<YOUR_CLIENT_SECRET>"
$secClientSecret = ConvertTo-SecureString $clientSecret -AsPlainText -Force
$credentials = New-Object System.Management.Automation.PSCredential ($clientId, $secClientSecret)

# Authenticate using the service principal
Connect-AzAccount -ServicePrincipal -Credential $credentials -Tenant $tenantId -WarningAction SilentlyContinue | Out-Null

# Get the list of subscriptions
$subscriptionIds = (Get-AzSubscription).Id

Write-Host "Login Successfull..." -ForegroundColor Green

# Loop through the list of subscriptions and find empty resource groups
foreach ($subscription in $subscriptionIds) {
    Set-AzContext -SubscriptionId $subscription | Out-Null

    Write-Host "`n--------- Working on subscription $subscription ----------`n"

    $emptyRgs = New-Object System.Collections.ArrayList

    $rgs = Get-AzResourceGroup

    Write-Host "Empty resource groups:- "

    foreach ($rg in $rgs) {
        $resourceCount = (Get-AzResource -ResourceGroupName $rg.ResourceGroupName).Count

        if ($resourceCount -eq 0) {            
            Write-Host $rg.ResourceGroupName
            $emptyRgs.Add($rg) | Out-Null
        }
    }

    if ($emptyRgs.Count -eq 0) {
        Write-Host "No empty resource groups found in this subscription" -ForegroundColor Red
    }
    else {
        # Ask permission to delete the empty resource groups
        $msg = "`nDo you want to delete the above resource groups? [y/n]"

        $choice = [string]::empty

        while ($choice -notmatch "[y|Y|n|N]") {
            $choice = Read-Host -Prompt $msg
        }

        if ($choice -match "[y|Y]") {
            $emptyRgs | Remove-AzResourceGroup -Force -AsJob | Out-Null
            Write-Host "`n", $emptyRgs.Count, "resource groups will be deleted" -ForegroundColor Green
        }
        else {
            Write-Host "`nNo resource groups were deleted" -ForegroundColor Red
        }
    }
    Write-Host "`n---- Finished working on subscription $subscription -----`n"
}
