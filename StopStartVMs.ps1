param (
    [Parameter(Mandatory=$true)]  
    [String] $TagName,

    [Parameter(Mandatory=$true)]
    [String] $TagValue,
	
	[Parameter(Mandatory=$true)]  
    [String] $Action = "Start or Stop"
) 

## Authentication
Write-Output ""
Write-Output "------------------------ Authentication ------------------------"
Write-Output "Logging into Azure ..."

try
{
    # Ensures you do not inherit an AzContext in your runbook
    $null = Disable-AzContextAutosave -Scope Process

    $Conn = Get-AutomationConnection -Name AzureRunAsConnection
    
    $null = Connect-AzAccount `
                    -ServicePrincipal `
                    -Tenant $Conn.TenantID `
                    -ApplicationId $Conn.ApplicationID `
                    -CertificateThumbprint $Conn.CertificateThumbprint

    Write-Output "Successfully logged into Azure." 
} 

catch
{
    if (!$Conn)
    {
        $ErrorMessage = "Service principal not found."
        throw $ErrorMessage
    } 
    else
    {
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}
## End of authentication

## Getting all virtual machines
Write-Output ""
Write-Output ""
Write-Output "---------------------------- Status ----------------------------"
Write-Output "Getting all virtual machines from all resource groups ..."

try
{
    if ($TagName)
    {                    
        $instances = Get-AzResource -TagName $TagName -TagValue $TagValue -ResourceType "Microsoft.Compute/virtualMachines"
        
        if ($instances)
        {
            $resourceGroupsContent = @()
                                      
            foreach ($instance in $instances)
            {
                $instancePowerState = (((Get-AzVM -ResourceGroupName $($instance.ResourceGroupName) -Name $($instance.Name) -Status).Statuses.Code[1]) -replace "PowerState/", "")

                $resourceGroupContent = New-Object -Type PSObject -Property @{
                    "Resource group name" = $($instance.ResourceGroupName)
                    "Instance name" = $($instance.Name)
                    "Instance type" = (($instance.ResourceType -split "/")[0].Substring(10))
                    "Instance state" = ([System.Threading.Thread]::CurrentThread.CurrentCulture.TextInfo.ToTitleCase($instancePowerState))
                    $TagName = $TagValue
                }

                $resourceGroupsContent += $resourceGroupContent
            }
        }
        else
        {
            #Do nothing
        }
    }       
    else
    {
        $instances = Get-AzResource -ResourceType "Microsoft.Compute/virtualMachines"

        if ($instances)
        {
            $resourceGroupsContent = @() 
                  
            foreach ($instance in $instances)
            {
                $instancePowerState = (((Get-AzVM -ResourceGroupName $($instance.ResourceGroupName) -Name $($instance.Name) -Status).Statuses.Code[1]) -replace "PowerState/", "")

                $resourceGroupContent = New-Object -Type PSObject -Property @{
                    "Resource group name" = $($instance.ResourceGroupName)
                    "Instance name" = $($instance.Name)
                    "Instance type" = (($instance.ResourceType -split "/")[0].Substring(10))
                    "Instance state" = ([System.Threading.Thread]::CurrentThread.CurrentCulture.TextInfo.ToTitleCase($instancePowerState))
                }

                $resourceGroupsContent += $resourceGroupContent
            }
        }
        else
        {
            #Do nothing
        }
    }

    $resourceGroupsContent | Format-Table -AutoSize
}
catch
{
    Write-Error -Message $_.Exception
    throw $_.Exception    
}
## End of getting all virtual machines

$runningInstances = ($resourceGroupsContent | Where-Object {$_.("Instance state") -eq "Running" -or $_.("Instance state") -eq "Starting"})
$deallocatedInstances = ($resourceGroupsContent | Where-Object {$_.("Instance state") -eq "Deallocated" -or $_.("Instance state") -eq "Deallocating"})

## Updating virtual machines power state
if (($runningInstances) -and ($Action -eq "Stop"))
{
    Write-Output "--------------------------- Updating ---------------------------"
    Write-Output "Trying to stop virtual machines ..."

    try
    {
        $updateStatuses = @()
         
        foreach ($runningInstance in $runningInstances)
        {
            Write-Output "$($runningInstance.("Instance name")) is shutting down ..."
        
            $startTime = Get-Date -Format G

            $null = Stop-AzVM -ResourceGroupName $($runningInstance.("Resource group name")) -Name $($runningInstance.("Instance name")) -Force
            
            $endTime = Get-Date -Format G

            $updateStatus = New-Object -Type PSObject -Property @{
                "Resource group name" = $($runningInstance.("Resource group name"))
                "Instance name" = $($runningInstance.("Instance name"))
                "Start time" = $startTime
                "End time" = $endTime
            }
            
            $updateStatuses += $updateStatus       
        }

        $updateStatuses | Format-Table -AutoSize
    }
    catch
    {
        Write-Error -Message $_.Exception
        throw $_.Exception    
    }
}
elseif (($deallocatedInstances) -and ($Action -eq "Start"))
{
    Write-Output "--------------------------- Updating ---------------------------"
    Write-Output "Trying to start virtual machines ..."

    try
    {
        $updateStatuses = @() 

        foreach ($deallocatedInstance in $deallocatedInstances)
        {                                    
            Write-Output "$($deallocatedInstance.("Instance name")) is starting ..."

            $startTime = Get-Date -Format G

            $null = Start-AzVM -ResourceGroupName $($deallocatedInstance.("Resource group name")) -Name $($deallocatedInstance.("Instance name"))

            $endTime = Get-Date -Format G

            $updateStatus = New-Object -Type PSObject -Property @{
                "Resource group name" = $($deallocatedInstance.("Resource group name"))
                "Instance name" = $($deallocatedInstance.("Instance name"))
                "Start time" = $startTime
                "End time" = $endTime
            }

            $updateStatuses += $updateStatus
        }

        $updateStatuses | Format-Table -AutoSize
    }
    catch
    {
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}
#### End of updating virtual machines power state
