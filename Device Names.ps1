<#
	.SYNOPSIS
		A brief description of the MFAAzureScript.ps1 file.
	
	.DESCRIPTION
		A description of the file.
	
	.PARAMETER Path
		A description of the Path parameter.
	
	.PARAMETER UserList
		A description of the UserList parameter.
	
	.NOTES
		===========================================================================
		Created on:   	8/16/2024 14:03
		Created by:   	Noah Rincon
		Usage:
			.\getMFA3.ps1 -Path C:\Users\nrinc\Desktop\bot2.csv -UserList '.\New Text Document.txt'
 			.\getMFA3.ps1 -Path C:\Users\nrinc\Desktop\bot2.csv
		===========================================================================
#>

param ($Path, $UserList)

#Check if parameters are valid
if ((Test-Path $Path) -eq $False)
	{
	Write-Host "-Path not valid, please provide a filepath to export CSV to."
	Write-Host "-UserList, to optionally add a list of users to save time. By default grabs a list of every user in the tenant."
 	exit
}


function Tenant-Connect {
	#Check if module is installed
	if (Get-Module -ListAvailable -Name Microsoft.Graph) {
    		Write-Host "Module exists, connecting to tenant"
     		try {
       			#Connect to Azure Tenant
       			Connect-MgGraph -Scopes 'UserAuthenticationMethod.Read.All'
	  	}
    		catch {
      			Write-Host "Error occurred"
	 		Wrote-Host $_.Exception.Message
	 	}
	}
	else {
 		#Install Mg Graph module
		Write-Host "Module does not exist, installing module"
  		Install-Module Microsoft.Graph -Scope CurrentUser -Repository PSGallery -Force
         	try { 
	  		#Connect to Azure Tenant
       			Connect-MgGraph -Scopes 'UserAuthenticationMethod.Read.All'
	  	}
    		catch {
      			Write-Host "Error occurred"
	 		Wrote-Host $_.Exception.Message
	 	}
	}
 }

function Get-DeviceNames {
	if ($UserList -eq $null)
 		
		{
		#Get all Azure users
		$users = get-mguser -All
	}
	else {
		#Place users from .text file in $users variable
		$users = ForEach ($mguser in $(get-content -Path $UserList)) {
			get-mguser -userid $mguser
		}
	}
 	
	$results=@();
	Write-Host  "`nRetreived $($users.Count) users";
	#loop through each user account
	foreach ($user in $users) {
		#Get all MFA data from users
		$MFAData=Get-MgUserAuthenticationMethod -UserId $user.UserPrincipalName #-ErrorAction SilentlyContinue

		#Define authentication methods for each user
		ForEach ($method in $MFAData) {
			$myObject = [PSCustomObject]@{
				user               		= "-"
				Id 				   		= "-"
				MFAstatus          		= "-"
				email              		= "-"
				fido2              		= "-"
				app                		= "-"
				password           		= "-"
				phone              		= "-"
				softwareoath       		= "-"
				tempaccess         		= "-"
				hellobusiness      		= "-"
				DeviceName         		= "-"
				PhoneAppVersion    		= "-"
				DeviceTag		  		= "-"
			}

   			#Check if user can authenticate with email
			$myobject.user = $user.UserPrincipalName;
			Switch ($method.AdditionalProperties["@odata.type"]) {
				"#microsoft.graph.emailAuthenticationMethod"  {
				$myObject.Id = $method.Id
				$myObject.email = $true
				$myObject.MFAstatus = "Enabled"
			}
   		   		#Check if user can authenticate with fido2
				"#microsoft.graph.fido2AuthenticationMethod" {
				$myObject.fido2 = $true
				$myObject.MFAstatus = "Enabled"
			}
      				#Check if user can authenticate with password
				"#microsoft.graph.passwordAuthenticationMethod"                {
				$myObject.password = $true
					# When only the password is set, then MFA is disabled.
					if($myObject.MFAstatus -ne "Enabled")
					{
						$myObject.MFAstatus = "Disabled"
					}
			}
      				#Check if user can authenticate with phone
				"#microsoft.graph.phoneAuthenticationMethod"  {
				$myObject.phone = $true
				$myObject.MFAstatus = "Enabled"
			}
			"#microsoft.graph.microsoftAuthenticatorAuthenticationMethod"  {
				$myObject.Id = $method.Id
				$myObject.DeviceName = $method.AdditionalProperties.displayName
				$myObject.PhoneAppVersion = $method.AdditionalProperties.phoneAppVersion
				$myObject.deviceTag = $method.AdditionalProperties.deviceTag
				$myObject.MFAstatus = "Enabled"
			}
			   	#Check if user can authenticate with Google Authenticator or Oath OTP
				"#microsoft.graph.softwareOathAuthenticationMethod"  {
				$myObject.Id = $method.Id
				$myObject.softwareoath = "Oath OTP Enabled"
				$myObject.MFAstatus = "Enabled"
			}
      				#Check if user can authenticate with temp pass
				"#microsoft.graph.temporaryAccessPassAuthenticationMethod"  {
				$myObject.tempaccess = $true
				$myObject.MFAstatus = "Enabled"
			}
      				#Check if user can authenticate with HelloBusiness
				"#microsoft.graph.windowsHelloForBusinessAuthenticationMethod"  {
				$myObject.hellobusiness = $true
				$myObject.MFAstatus = "Enabled"
			}
			}
   		#Place results in custom objects list
		$results+= $myObject;
		}
	}
	#Export custom objects list as a CSV
	$results | export-csv -NoTypeInformation -path $Path
}

Tenant-Connect
Get-DeviceNames
