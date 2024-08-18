# Usage:
# 	.\getMFA3.ps1 -Path C:\Users\nrinc\Desktop\bot2.csv -UserList '.\New Text Document.txt'
# 	.\getMFA3.ps1 -Path C:\Users\nrinc\Desktop\bot2.csv

param ($Path, $UserList)

#Check if parameters are valid
if ((Test-Path $Path) -eq $False)
	{
	Write-Host "-Path not valid, please provide a filepath to export CSV to."
	Write-Host "-UserList, to optionally add a list of users to save time. By default grabs a list of every user in the tenant."
 	exit
}


function Tenant-Connect {
	if (Get-Module -ListAvailable -Name Microsoft.Graph) {
    		Write-Host "Module exists, connecting to tenant"
     		try { 
       			Connect-MgGraph -Scopes 'UserAuthenticationMethod.Read.All'
	  	}
    		catch {
      			Write-Host "Error occurred"
	 		Wrote-Host $_.Exception.Message
	 	}
	}
	else {
		Write-Host "Module does not exist, installing module"
  		Install-Module Microsoft.Graph -Scope CurrentUser -Repository PSGallery -Force
         	try { 
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
		# Display the custom objects
		#Get all Azure users
		$users = get-mguser -All
	}
	else {
		#Provide list of users
		$users = ForEach ($mguser in $(get-content -Path $UserList)) {
		get-mguser -userid $mguser
		}
	}
	$results=@();
	Write-Host  "`nRetreived $($users.Count) users";
	#loop through each user account
	foreach ($user in $users) {
	
		$MFAData=Get-MgUserAuthenticationMethod -UserId $user.UserPrincipalName #-ErrorAction SilentlyContinue

		#check authentication methods for each user
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

			$myobject.user = $user.UserPrincipalName;
			Switch ($method.AdditionalProperties["@odata.type"]) {
				"#microsoft.graph.emailAuthenticationMethod"  {
				$myObject.Id = $method.Id
				$myObject.email = $true
				$myObject.MFAstatus = "Enabled"
			}
				"#microsoft.graph.fido2AuthenticationMethod" {
				$myObject.fido2 = $true
				$myObject.MFAstatus = "Enabled"
			}
				"#microsoft.graph.passwordAuthenticationMethod"                {
				$myObject.password = $true
					# When only the password is set, then MFA is disabled.
					if($myObject.MFAstatus -ne "Enabled")
					{
						$myObject.MFAstatus = "Disabled"
					}
			}
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
		
				"#microsoft.graph.softwareOathAuthenticationMethod"  {
				$myObject.Id = $method.Id
				$myObject.softwareoath = "Oath OTP Enabled"
				$myObject.MFAstatus = "Enabled"
			}
				"#microsoft.graph.temporaryAccessPassAuthenticationMethod"  {
				$myObject.tempaccess = $true
				$myObject.MFAstatus = "Enabled"
			}
				"#microsoft.graph.windowsHelloForBusinessAuthenticationMethod"  {
				$myObject.hellobusiness = $true
				$myObject.MFAstatus = "Enabled"
			}
			}
		$results+= $myObject;
		}
	}
 
	# Display the custom objects
	$results | export-csv -NoTypeInformation -path $Path
}

Tenant-Connect
Get-DeviceNames
