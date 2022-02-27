$OutputVariable = Get-Service -Displayname "*winlogbeat*" | Out-String
if(-NOT $OutputVariable -Match "Running") {
	Write-Output "Winlogbeat service is not running"
	exit 1
}
Write-Output "Winlogbeat installed succesfully"
