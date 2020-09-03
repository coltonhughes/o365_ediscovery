#!powershell


## Copyright 2020 Colton Hughes <colton.hughes@firemon.com>

## Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
## The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
## THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


#AnsibleRequires -CSharpUtil Ansible.Basic


$spec = @{
  options = @{
    user_email = @{ type = "str"; required = $true }
    o365_username = @{ type = "str"; required = $true }
    o365_password = @{ type = "str"; required = $true; no_log = $true }
    hold_enabled = @{ type = "bool"; required = $true}
  }
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$userEmail = $module.Params.user_email
$o365_username = $module.Params.o365_username
$o365_password = $module.Params.o365_password
$hold_status = $module.Params.hold_enabled

## Convert plaintext password to securestring
$secure_password = ConvertTo-SecureString -String $o365_password -AsPlainText -Force


##Build display name from email by splitting at '@' and at '.'
$pos = $userEmail.IndexOf("@")
$emailNoDomain = $userEmail.Substring(0, $pos)
$displayName = $emailNoDomain.Split(".")


## Site for determining OneDrive URI
$mySiteDomain = "firemon"
$AdminUrl = "https://$mySiteDomain-admin.sharepoint.com"

## Loading the current date/time
[Datetime]$date = Get-Date

## Creating a secure reusable credential object
$credObject = New-Object System.Management.Automation.PSCredential ($o365_username, $secure_password)

try {
  Import-Module ExchangeOnlineManagement
}
catch {
  $module.FailJson("Failed to import ExchangeOnlineManagement PowerShell module", $_)
  $module.Result.changed = $false
}

## Connect to Security and Compliance Center

try {
  Connect-IPPSSession -Credential $credObject
}
catch {  
$module.FailJson("Could not Connect to ExchangeOnline", $_)
$module.Result.changed = $false
}


## Specific Date ranges for our quarters
$q1start = "1/1/2020 12:00:00 AM"
$q1end = "3/31/2020 11:59:59 PM"

$q2start = "4/1/2020 12:00:00 AM"
$q2end = "6/30/2020 11:59:59 PM"

$q3start = "7/1/2020 12:00:00 AM"
$q3end = "9/30/2020 11:59:59 PM"

$q4start = "10/1/2020 12:00:00 AM"
$q4end = "12/31/2020 11:59:59 PM"


## Determine the quarter of the current date
if (($date -ge $q1start) -and ($date -le $q1end))
{ 
     $currQuarter = 1 
} 
elseif (($date -ge $q2start) -and ($date -le $q2end))
{ 
    $currQuarter = 2 
}
elseif (($date -ge $q3start) -and ($date -le $q3end))
{
    $currQuarter = 3
}
elseif (($date -ge $q4start) -and ($date -le $q4end))
{
    $currQuarter = 4
}

## Return Quarter
$module.Result.current_quarter = $currQuarter

## Format of YYYY Q<Quarter> Terminated Employees
$casename = "$($date.Year) Q$currQuarter Terminated Employees"

## Return Case Name
$module.Result.casename = $casename

## Query if case with this name exists
$caseExists = (get-compliancecase -identity "$casename" -erroraction silentlycontinue).isvalid

## Determine next step. Either create new case or use existing one
if ($caseExists -ne 'True') {
    ##Write-host "Creating New Case with $casename name"
    try{
      ## Attempt to create the case if it does not exist
      New-complianceCase -name $casename
    }
    catch {
      $module.FailJson("Could not create a new case", $_)
      $module.Result.changed = $false
      Disconnect-ExchangeOnline -Confirm:$false | out-null
      $module.ExitJson()
    }
    
}
## Determine if hold exists within specific case
$holdName = "$displayName mailbox hold $($date.Month)/$($date.Day)/$($date.Year)"
$holdexists = (get-caseholdpolicy -identity "$holdName" -case "$casename" -erroraction SilentlyContinue).isvalid

## Return hold name generated
$module.Result.hold_name = $holdName

## Error out if holdname exists
if ($holdexists -eq 'True') {
  ##write-host "A hold named '$holdname' already exists. Please specify a new hold name." -foregroundColor Yellow
    $module.Result.hold_status = "Exists"
    $module.FailJson("The hold already exists. Please specific a new user or delete the existing hold and rerun")
    $module.Result.changed = $false
    Disconnect-ExchangeOnline -Confirm:$false | out-null
    $module.ExitJson()
}



try {
  ## Connect to the Sharepoint site to determine users OneDrive URL
  Connect-pnponline -url $AdminUrl -credentials $credObject
}
catch {
  $module.FailJson("Could not connect to Sharepoint Online (OneDrive)", $_)
  $module.Result.changed = $false
  Disconnect-ExchangeOnline -Confirm:$false | out-null
  $module.ExitJson()
  
}

## Get users OneDrive URL
try{
  $odURL = Get-pnpuserprofileproperty -account $userEmail
}
catch {
  $module.FailJson("Could not retrieve OneDrive profile",$_)
  $module.Result.changed = $false
  Disconnect-ExchangeOnline -Confirm:$false | out-null
  $module.ExitJson()
}

try{
  New-CaseHoldPolicy -name "$holdName" -case "$casename" -ExchangeLocation "$userEmail" -SharePointLocation $odURL.PersonalUrl -Enabled $hold_status  | out-null
  $module.Result.changed = $true
}
catch{
  $module.FailJson("Could not create the CasePolicy",$_)
  $module.Result.changed = $false
  Disconnect-ExchangeOnline -Confirm:$false | out-null
  $module.ExitJson()

}

try {
  New-CaseHoldRule -name "$holdName" -policy "$holdName" -contentmatchquery "" -Disabled $hold_status | out-null
  $module.Result.hold_status = "Created"
  $module.Result.changed = $true
}
catch{
  $module.FailJson("Could not create the CaseHold",$_)
  $module.Result.changed = $false
  Disconnect-ExchangeOnline -Confirm:$false | out-null
  $module.ExitJson()

}
##Write-host "`n$date`nCreating a new hold with the following settings:`nCase: $casename`nHold: $holdName`nUser: $userEmail`nOneDrive: $($odURL.PersonalUrl)`nHold Enabled: True" -ForegroundColor Cyan
##Write-host "`nCreating and enabling hold matching all content for $userEmail" -ForegroundColor Cyan

## Cleanup session
Disconnect-ExchangeOnline -Confirm:$false | out-null
$module.ExitJson()
