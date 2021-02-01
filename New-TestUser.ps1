# Number of user accounts to create
$UserCount = 5
$RandomPassword = $true
$DefaultPassword = 'Pa55w.rd'

# User name prefix
# New user object will be named TestUser1, TestUser2, ...
$TestUserPrefix = 'TestUser'

# User object properties
$GivenName = 'Test'
$Surname = 'User'
$Company = 'Varunagroup'
$JobTitle = @('Junior Consultant','Senior Consultant','Technical Consultant','Business Consultant')
$PreferredLanguage = 'de-DE'

# Name of the new organizational unit for test user object
$TestOU = 'Test User'

# Target OU path where the script creates the new OU 
$TargetOU = 'OU=IT,dc=varunagroup,dc=de'

# Import Active Directory PowerShell Module
Import-Module -Name ActiveDirectory 

# Build OU Path
$UserOUPath = ('OU={0},{1}' -f $TestOU, $TargetOU)

# Check if OU exists
$OUExists = $false

try {
   $OUExists = [adsi]::Exists("LDAP://$UserOUPath")
}
catch {
   $OUExists =$true   
}

if(-not $OUExists) { 
   # Create new organizational unit for test users
   New-ADOrganizationalUnit -Name $TestOU -Path $TargetOU -ProtectedFromAccidentalDeletion:$false -Confirm:$false
}
else {
   Write-Warning -Message ('OU {0} exists please delete the OU and user objects manually, before running this script.' -f $UserOUPath)
   Exit
}

Write-Output -InputObject ('Creating {0} user object in {1}' -f $UserCount, $UserOUPath)

# Create new user objects
1..$UserCount | ForEach-Object {

   # Get a random number for selecting a job title
   $random = Get-Random -Minimum 0 -Maximum (($JobTitle | Measure-Object). Count - 1)

   # Set user password
   if($RandomPassword) {
      # Create a random password
      $UserPassword = ConvertTo-SecureString -String (-join ((33..93) + (97..125) | Get-Random -Count 25 | % {[char]$_})) -AsPlainText -Force
   }
   else {
      # Use a fixed password
      $UserPassword = ConvertTo-SecureString -String $DefaultPassword -AsPlainText -Force
   }

   # Create a new user object
   # Adjust user name template and other attributes as needed
   New-ADUser -Name ('{0}{1}' -f $TestUserPrefix, $_) `
   -DisplayName ('{0} {1}' -f $TestUserPrefix, $_) `
   -GivenName $GivenName `
   -Surname (('{0}{1}' -f $Surname, $_)) `
   -OtherAttributes @{title=$JobTitle[$random];company=$Company;preferredLanguage=$PreferredLanguage} `
   -Path $UserOUPath `
   -AccountPassword $UserPassword `
   -Enabled:$True `
   -Confirm:$false
}