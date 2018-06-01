<# 
.SYNOPSIS 
This script can be used to update service account password configured in system. It updates in Services,Scheduled Task, Web Site, Web Application, Web Directory, Com+ Application.

.DESCRIPTION 
This script can be used if your updating password for service account and want to update the same on one or more computers
As of now below are supported while updating password

    Services
    Scheduled Tasks
    Web Site
    Web Directory
    Web Application
    App Pool
    Com+ Application

.PARAMETER ComputerName
Accepts  a single computer name or an array of computer names. You can also pipe the computername to the script
Default value : local computer

.PARAMETER Path
Provide path of csv file which contains accounts and passwords
 
.PARAMETER Credential
Alternate credential can be provided to run the script, otherwise logged in credetial will be used to run the script  

.EXAMPLE 
Update service account password on local system, where csv file path is C:\Scripts\ServiceAccounts.csv which contains account information

.\Update-ServiceAcountPassword.ps1 -Path C:\Scripts\ServiceAccounts.csv

.EXAMPLE 
Perfoming same operation on multiple computer
 
.\Update-ServiceAcountPassword.ps1 -Path C:\Scripts\ServiceAccounts.csv -ComputerName Server01, Server02

.EXAMPLE 
Providing different credential
 
.\Update-ServiceAcountPassword.ps1 -Path C:\Scripts\ServiceAccounts.csv -ComputerName Server01, Server02 -Credential (Get-Credential)

.EXAMPLE  
Reading the computer name from text file for updating the password
 
Get-Content C:\Scripts\Servers.txt | .\Update-ServiceAcountPassword.ps1 -Path C:\Scripts\ServiceAccounts.csv -ComputerName Server01, Server02 -Credential (Get-Credential)
 
.Link 
If you have any question, you can post to
https://gallery.technet.microsoft.com/PowerShell-Update-Service-10470f62

.Notes
Author: Vikram Athare
Version: 1.0
#>
[CmdletBinding(SupportsShouldProcess=$True,ConfirmImpact='Low')] 
param(
    [Parameter(ValueFromPipeline=$True)][string[]]$ComputerName = $env:COMPUTERNAME,
    [Parameter(Mandatory=$True)][ValidateScript({Test-Path $_})][String]$Path,
    [Parameter()][ValidateNotNull()][System.Management.Automation.PSCredential][System.Management.Automation.Credential()]$Credential = [System.Management.Automation.PSCredential]::Empty
)
Begin {
    Write-Verbose "Script execution has started"
    # Define Log file
    [String]$LogFile = (Get-Location).Path + "\Result_" + (Get-Date -Format MM-dd-yyyy_hh-mm) + ".csv"
    Write-Verbose "At the end of execution, check $LogFile for service account details"
    # Define domain and netbios name 
    $DomainNetBios = (Get-WmiObject Win32_NTDomain -Filter "DnsForestName = '$( (Get-WmiObject Win32_ComputerSystem).Domain)'").DomainName
    $DomainFQDN = (Get-WmiObject Win32_NTDomain).DomainName
    # Importing service accounts
    $Accounts = Import-Csv $Path
    $VPreference = $VerbosePreference
}
Process {
    foreach($MachineName in $COMPUTERNAME){
    Write-Host "$MachineName - Processing..." -ForegroundColor Magenta
    Write-Verbose "$MachineName - Trying to establish PSSession..."
	$MachineSession = New-PSSession -ComputerName $MachineName -Credential $Credential -ErrorAction SilentlyContinue
	    if ($MachineSession.State -ne "Opened") {
            Write-Verbose "$MachineName - Cannot establish PS session"
            $Services = @()
            $item = @{}
            $item.PSComputerName = $MachineName
            $item.ServiceType = 'NA'
            $item.ServiceName = 'NA'
            $item.ServiceAccount = 'NA'
            $item.Action = 'Failed to connect to PsSession'
            $PsObject = New-Object -TypeName PSObject -Property $item
            $Services += $PsObject
            $Services | Select-Object PSComputerName, ServiceType, ServiceName, ServiceAccount, Action | Export-Csv $LogFile -Append -NoTypeInformation -Encoding ASCII -Force
	    }
	    else {
            Write-Verbose "$MachineName - Successfully establish PSSession"
		    Invoke-Command -Session $MachineSession -InputObject $Accounts -ArgumentList $DomainNetBios, $DomainFQDN, $VPreference -ScriptBlock{
                param (
                    $DomainNetBios,
                    $DomainFQDN,
                    $VPreference
                )
                $VerbosePreference = $VPreference
                Write-Verbose "Remote execution started"
                # get input object
                $Accounts = @()
                foreach ($Objects in $input) {
                    foreach ($Object in $Objects) {
                        $item = @{}
                        $item.ServiceAccount = $Object.ServiceAccount
                        $item.Password = $Object.Password
                        $PsObject = New-Object -TypeName PSObject -Property $item
                        $Accounts += $PsObject
                    }
                }
                $Services = @()
			    Write-Verbose "$env:COMPUTERNAME - Update Password - Services"
                foreach ($Object in $Accounts) {
	                $ServiceAccount = $Object.ServiceAccount
                    $Password = $Object.Password
	                $Service = Get-WmiObject -Class Win32_Service | Where-Object {($_.StartName -eq "$DomainNetBios\$ServiceAccount") -or ($_.StartName -eq "$ServiceAccount@$DomainFQDN")}
	                foreach ($Object in $Service) {
                        if ($Object -ne $null) {
                            try {
                                Write-Verbose "Updating password for $ServiceAccount on $($Object.Name)"
			                    $ChangeService = $Object.Change($null,$null,$null,$null,$null,$null,"$DomainNetBios\$ServiceAccount","$Password")
                                $item = @{}
                                $item.ServiceType = 'Service'
                                $item.ServiceName = $Object.Name
                                $item.ServiceAccount = $ServiceAccount
                                $item.Action = 'Success'
                                $PsObject = New-Object -TypeName PSObject -Property $item
                                $Services += $PsObject
                            }
		                    catch {
                                Write-Verbose "Update password failed for $ServiceAccount on $($Object.Name)"
                                $item = @{}
                                $item.ServiceType = 'Service'
                                $item.ServiceName = $Object.Name
                                $item.ServiceAccount = $ServiceAccount
                                $item.Action = 'Fail'
                                $PsObject = New-Object -TypeName PSObject -Property $item
                                $Services += $PsObject
		                    }
                        }
	                }
                }
                Write-Verbose "$env:COMPUTERNAME - Update Password - Scheduled Tasks"
                $SchTasks = schtasks /query /FO csv /V
                $SchTasks | Out-File $env:SystemDrive\schtasks.csv -Force
                $SchTasksCsv = Import-Csv -Path $env:SystemDrive\schtasks.csv
                foreach ($Object in $Accounts) {
                    $ServiceAccount = $Object.ServiceAccount
                    $Password = $Object.Password
	                $TaskObjects = $SchTasksCsv | Where-Object {($_."Run As User" -eq "$DomainNetBios\$ServiceAccount") -or ($_."Run As User" -eq "$ServiceAccount@$DomainFQDN")}
	                foreach ($Object in $TaskObjects) {
                        if ($Object -ne $null) {
                            try {
                                Write-Verbose "Updating password for $ServiceAccount on $($Object.TaskName)"
		                        $TaskName = $Object.TaskName
		                        $TaskService = new-object -comobject "Schedule.Service"
		                        $TaskService.Connect($MachineName, $ServiceAccount, "$DomainNetBios", $Password)
		                        $rootFolder = $TaskService.GetFolder("\")
		                        $taskDefinition = $rootFolder.GetTask($TaskName).Definition
		                        $logonType = $taskDefinition.Principal.LogonType
		                        [Void] $rootFolder.RegisterTaskDefinition($TaskName, $taskDefinition, 4,"$DomainNetBios\"+$ServiceAccount, $Password, $logonType)
                                $item = @{}
                                $item.ServiceType = 'ScheduledTask'
                                $item.ServiceName = $TaskName
                                $item.ServiceAccount = $ServiceAccount
                                $item.Action = 'Success'
                                $PsObject = New-Object -TypeName PSObject -Property $item
                                $Services += $PsObject
                            }
                            catch {
                                Write-Verbose "Updat password failed for $ServiceAccount on $($Object.TaskName)"
                                $item = @{}
                                $item.ServiceType = 'ScheduledTask'
                                $item.ServiceName = $TaskName
                                $item.ServiceAccount = $ServiceAccount
                                $item.Action = 'Fail'
                                $PsObject = New-Object -TypeName PSObject -Property $item
                                $Services += $PsObject
                            }
                        }
	                }
                }
                Remove-Item $env:SystemDrive\schtasks.csv -Force
                Write-Verbose "$env:COMPUTERNAME - Update Password - Com Application"
                $comAdmin = New-Object -com ("COMAdmin.COMAdminCatalog.1")
                $applications = $comAdmin.GetCollection("Applications")
                $applications.Populate()
                foreach ($Object in $Accounts) {
	                $ServiceAccount = $Object.ServiceAccount  
                    $Password = $Object.Password
	                $ComAppObjs = $applications | Where-Object {($_.Value("Identity") -eq "$DomainNetBios\$ServiceAccount") -or ($_.Value("Identity") -eq "$ServiceAccount@$DomainFQDN")}
	                foreach ($Object in $ComAppObjs) {
                        if ($Object -ne $null) {
                            try {
                                Write-Verbose "Updating password for $ServiceAccount on $($Object.Name)"
			                    $Object.Value("Identity") = "$DomainNetBios\$ServiceAccount"
			                    $Object.Value("Password") = "$Password"
			                    $Check = $applications.SaveChanges()
                                $item = @{}
                                $item.ServiceType = 'ComApp'
                                $item.ServiceName = $Object.Name
                                $item.ServiceAccount = $ServiceAccount
                                $item.Action = 'Success'
                                $PsObject = New-Object -TypeName PSObject -Property $item
                                $Services += $PsObject
		                    }
                            catch {
                                Write-Verbose "Update password failed for $ServiceAccount on $($Object.Name)"
                                $item = @{}
                                $item.ServiceType = 'ComApp'
                                $item.ServiceName = $Object.Name
                                $item.ServiceAccount = $ServiceAccount
                                $item.Action = 'Fail'
                                $PsObject = New-Object -TypeName PSObject -Property $item
                                $Services += $PsObject
                            }
                        }
	                }
                }		
                Import-Module ServerManager -ErrorAction SilentlyContinue
                Import-Module WebAdministration -ErrorAction SilentlyContinue
                $IIS = Get-WindowsFeature -Name Web-Server -ErrorAction SilentlyContinue
                if ($IIS.Installed -eq 'True') {
                    Write-Verbose "$env:COMPUTERNAME - Update Password - Virtual Directory"  
	                foreach ($Object in $Accounts) {
		                $ServiceAccount = $Object.ServiceAccount
		                $Password = $Object.Password
		                $ParentWebSite = Get-ChildItem IIS:\Sites\
		                foreach($Site in $ParentWebSite) {
			                $VDirs = Get-WebVirtualDirectory -Site $Site.name -Application * | Where-Object {($_.UserName -eq "$DomainNetBios\$ServiceAccount") -or ($_.UserName -eq "$ServiceAccount@$DomainFQDN")}
			                foreach($webvdirectory in $VDirs) {
                                if ($webvdirectory -ne $null) {
                                    try {
                                        Write-Verbose "Updating password for $ServiceAccount on $($webvdirectory.path -split "/")"
				                        $xpath = ($webvdirectory | Select -Property "ItemXPath").ItemXPath
				                        $fullPath = $xpath.Substring(1)							
				                        Set-WebConfigurationProperty $fullPath -Name "username" -Value "$DomainNetBios\$ServiceAccount"
				                        Set-WebConfigurationProperty $fullPath -Name "password" -Value $Password
				                        $nVDir = Get-WebConfigurationProperty $fullPath -Name "username"
                                        $item = @{}
                                        $item.ServiceType = 'WebDirectory'
                                        $item.ServiceName = ($webvdirectory.path -split "/")[-1]
                                        $item.ServiceAccount = $ServiceAccount
                                        $item.Action = 'Success'
                                        $PsObject = New-Object -TypeName PSObject -Property $item
                                        $Services += $PsObject
                                    }
                                    catch {
                                        Write-Verbose "Update password failed for $ServiceAccount on $($webvdirectory.path -split "/")"
                                        $item = @{}
                                        $item.ServiceType = 'WebDirectory'
                                        $item.ServiceName = ($webvdirectory.path -split "/")[-1]
                                        $item.ServiceAccount = $ServiceAccount
                                        $item.Action = 'Fail'
                                        $PsObject = New-Object -TypeName PSObject -Property $item
                                        $Services += $PsObject
                                    }
                                }
			                }
		                }
	                }
                    Write-Verbose "$env:COMPUTERNAME - Update Password - App Pool"
                    foreach ($Object in $Accounts) {
                        $ServiceAccount = $Object.ServiceAccount
                        $Password = $Object.Password
	                    $AppPools = get-childitem IIS:\AppPools\ | Where-Object {($_.processModel.UserName -eq "$DomainNetBios\$ServiceAccount") -or ($_.processModel.UserName -eq "$ServiceAccount@$DomainFQDN")}    
	                    foreach ($AppPool in $AppPools) {
		                    if (($AppPool.processModel.UserName -contains "$DomainNetBios\$ServiceAccount") -or ($AppPool.processModel.UserName -contains "$ServiceAccount@$DomainFQDN")) {
                                try {
                                    Write-Verbose "Updating password for $ServiceAccount on $($Object.Name)"
			                        $AppPool | Set-ItemProperty -name processModel -value @{userName="$DomainNetBios\$ServiceAccount";password="$Password";identitytype=3}
			                        $AppPoolObj = get-childitem IIS:\AppPools\ | Where-Object {($_.processModel.UserName -eq "$DomainNetBios\$ServiceAccount") -or ($_.processModel.UserName -eq "$ServiceAccount@$DomainFQDN")}
                                    $item = @{}
                                    $item.ServiceType = 'AppPool'
                                    $item.ServiceName = $AppPool.name
                                    $item.ServiceAccount = $ServiceAccount
                                    $item.Action = 'Success'
                                    $PsObject = New-Object -TypeName PSObject -Property $item
                                    $Services += $PsObject
                                }
                                catch {
                                    Write-Verbose "Update password failed for $ServiceAccount on $($Object.Name)"
                                    $item = @{}
                                    $item.ServiceType = 'AppPool'
                                    $item.ServiceName = $AppPool.name
                                    $item.ServiceAccount = $ServiceAccount
                                    $item.Action = 'Fail'
                                    $PsObject = New-Object -TypeName PSObject -Property $item
                                    $Services += $PsObject
                                }
		                    }
	                    }
                    }
                    Write-Verbose "$env:COMPUTERNAME - Update Password - Web Apps"
                    $ParentWebSite = Get-ChildItem IIS:\Sites\
                    foreach ($WebSite in $ParentWebSite) {
	                    $WebSiteName = $Website.Name
	                    $WebApps = Get-Item "IIS:\Sites\$WebSiteName\*" | Where-Object {($_.UserName -eq "$DomainNetBios\$ServiceAccount") -or ($_.UserName -eq "$ServiceAccount@$DomainFQDN")}
	                    foreach ($WebApp in $WebApps) {
		                    if ($WebApp.enabledProtocols -ne $null) {
                                try {
                                    Write-Verbose "Updating password for $ServiceAccount on $($WebApp.Name)"
                                    $WebAppName = $WebApp.Name
			                        $SitePath = $WebApp.PSPath
			                        Set-ItemProperty -Path $SitePath -Name userName -Value "$DomainNetBios\$ServiceAccount"
			                        Set-ItemProperty -Path $SitePath -Name password -Value "$Password"
                                    $item = @{}
                                    $item.ServiceType = 'WebApplication'
                                    $item.ServiceName = $WebApp.Name
                                    $item.ServiceAccount = $ServiceAccount
                                    $item.Action = 'Success'
                                    $PsObject = New-Object -TypeName PSObject -Property $item
                                    $Services += $PsObject
                                }
                                catch {
                                    Write-Verbose "Update password failed for $ServiceAccount on $($WebApp.Name)"
                                    $item = @{}
                                    $item.ServiceType = 'WebApplication'
                                    $item.ServiceName = $WebApp.Name
                                    $item.ServiceAccount = $ServiceAccount
                                    $item.Action = 'Fail'
                                    $PsObject = New-Object -TypeName PSObject -Property $item
                                    $Services += $PsObject
                                }
                            }
                        }
                    }
                    Write-Verbose "$env:COMPUTERNAME - Update Password - Web Sites"
                    $GetWebSites = Get-Item IIS:\Sites\* | Where-Object {($_.UserName -eq "$DomainNetBios\$ServiceAccount") -or ($_.UserName -eq "$ServiceAccount@$DomainFQDN")}                                                                                                 
                    foreach ($Website in $GetWebSites) {
                        if ($WebSite -ne $null) {
                            try {
                                Write-Verbose "Updating password for $ServiceAccount on $($WebSite.Name)"
		                        $SitePath = $Website.PSPath
		                        Set-ItemProperty -Path $SitePath -Name userName -Value "$DomainNetBios\$ServiceAccount"
		                        Set-ItemProperty -Path $SitePath -Name password -Value "$Password"
		                        $WebSiteName = $Website.name
                                $item = @{}
                                $item.ServiceType = 'WebSite'
                                $item.ServiceName = $WebSite.Name
                                $item.ServiceAccount = $ServiceAccount
                                $item.Action = 'Success'
                                $PsObject = New-Object -TypeName PSObject -Property $item
                                $Services += $PsObject
                            }
                            catch {
                                Write-Verbose "Update password failed for $ServiceAccount on $($WebSite.Name)"
                                $item = @{}
                                $item.ServiceType = 'WebSite'
                                $item.ServiceName = $WebSite.Name
                                $item.ServiceAccount = $ServiceAccount
                                $item.Action = 'Fail'
                                $PsObject = New-Object -TypeName PSObject -Property $item
                                $Services += $PsObject
                            }
                        }
                    }
                }	
                if ($Services.Length -eq 0) {
                    $item = @{}
                    $item.ServiceType = 'NA'
                    $item.ServiceName = 'NA'
                    $item.ServiceAccount = 'NA'
                    $item.Action = 'NA'
                    $PsObject = New-Object -TypeName PSObject -Property $item
                    $Services += $PsObject
                }
                Write-Verbose "End of remote execution"
            }
		    Write-Verbose "$MachineName - End of machine PS session"
		    $Services = Invoke-Command -Session $MachineSession -ScriptBlock {$Services}
		    $Services | Select-Object PSComputerName, ServiceType, ServiceName, ServiceAccount, Action | Export-Csv $LogFile -Append -NoTypeInformation -Encoding ASCII -Force
		    Write-Verbose "$MachineName - Removing PS Session"
		    Remove-PSSession -Session $MachineSession
	    }
    }
}
end {
    Write-Host "Script execution is completed, check $LogFile for details"
}