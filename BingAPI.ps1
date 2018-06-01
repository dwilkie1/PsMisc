Try

{
[string]$Token=$NULL

# Rest API Method
[string]$Method='POST'

# Rest API Endpoint
[string]$Uri='https://www.googleapis.com/auth/books'

# Authentication Key
[string]$AuthenticationKey='AIzaSyC33PC0BHOuSlKnDsjOkKnofW0KIcVs9CA'

# Headers to pass to Rest API
$Headers=@{'Ocp-Apim-Subscription-Key' = $AuthenticationKey }

# Get Authentication Token to communicate with Text to Speech Rest API
[string]$Token=Invoke-RestMethod -Method $Method -Uri $Uri -Headers $Headers
}

Catch [System.Net.Webexception]

{

Write-Output 'Failed to Authenticate'

}