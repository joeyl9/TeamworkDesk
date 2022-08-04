#V1 API Key goes in user
$user = ''
#Leave Blank
$pass = ''
#Comes before .teamwork.com in your url
$Customer = ""
$CustomerURI = "http://$customer.teamwork.com/desk/v1/customers.json"
#combine the username and password
$pair = "$($user):$($pass)"
#Encode them as required
$EncodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pair))

$BasicAuthValue = "Basic $EncodedCreds"
#The OU you want to pass through to Teamwork Desk
$usersOU = "OU=Employees,DC=AD,DC=DOMAIN,DC=COM"
#Getting Data to be passed through
$UserData = Get-ADUser -Filter "*" -SearchBase "$usersOU" -Properties mail, streetAddress, l, st, givenName, sn, postalCode | Select-Object mail, streetAddress, l, st, givenName, sn, postalCode
$UserData | ForEach-Object{
	$City = $_.l
	$State = $_.st
	$Street = $_.streetAddress
	$PostalCode = $_.postalCode
	$Address = $Street + ", " + $City + ", " + $State + " " + $PostalCode
	$FirstName = $_.givenName
	$LastName = $_.sn
	$Email = $_.mail
	
	#Checking if the user has an Email, if they don't it wont pass them through the api
	if ($Email -eq $Null) { Write-host "No Email" }
	else
	{
		#Checking if the user has an address, if they don't it wont pass them through the api
		if ($Address -eq ", ,  ") { write-host "No address" }
		else
		{
			#Checking if the user has a first name, if they don't it wont pass them through the api
			if ($FirstName -eq $Null) { Write-host "No first name" }
			else
			{
				#Checking if the user has last name, if they don't it wont pass them through the api
				if ($LastName -eq $Null) { Write-host "No last name" }
				else
				{
					
					$Headers = @{
						Authorization = $BasicAuthValue
					}
					$Body = @{ firstname = $FirstName; Lastname = $LastName; email = $Email; Address = $Address }
					
					try
					{
						Invoke-RestMethod -Method Post -Uri $CustomerURI -body $Body -Headers $Headers
					}
					catch
					{
						$StatusCode = $_.Exception.Response.StatusCode.value__
						Write-Host "StatusCode:" $StatusCode
						Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription
					}
					#If the status code returned is 429 than the script has exceeded the rate limit and we need to wait a minute before trying again so the script sleeps for 61 seconds
					if ($StatusCode -eq "429")
					{
						Write-host "Need to wait 61 seconds because we're rate limited"
						start-sleep -seconds 61
						
						try
						#To make sure the impacted user at the time of being rate limited is still passed through we initate it again
						{
							Invoke-RestMethod -Method Post -Uri $CustomerURI -body $Body -Headers $Headers
						}
						catch
						{
							$StatusCode = $_.Exception.Response.StatusCode.value__
							Write-Host "StatusCode:" $StatusCode
							Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription
						}
						
						
						
						
					}
					else { write-host "Not a rate limit error" }
				}
			}
		}
	}
}








