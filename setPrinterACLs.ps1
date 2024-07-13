# Using CSV to a Security Group to Printer Security with Read/Print only permissions.
# Existing Permissions will persist
# CSV Format headers: PrinterName, SecurityGroup

# Define the domain
$Domain = "nealmckinney.local"

# Path to the CSV file
$csvPath = "C:\scripts\Printers\printers.csv"

# Path to the log file
$logPath = "C:\scripts\Printers\printer-acl-log.txt"

# Read the CSV file
$printers = Import-Csv -Path $csvPath

# Initialize log file
Add-Content -Path $logPath -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Script started"

foreach ($printer in $printers) {
    $PrinterName = $printer.PrinterName
    $SecurityGroup = $printer.SecurityGroup

    # Search for the security group in Active Directory
    $searcher = New-Object System.DirectoryServices.DirectorySearcher
    $searcher.Filter = "(&(objectCategory=group)(name=$SecurityGroup))"
    $searcher.SearchRoot = "LDAP://$Domain"
    $group = $searcher.FindOne()

    if ($null -eq $group) {
        $message = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Security group '$SecurityGroup' not found in domain '$Domain'"
        Write-Host $message
        Add-Content -Path $logPath -Value $message
    } else {
        # Retrieve the objectsid property
        $objectSidProperty = $group.Properties["objectsid"]
        if ($objectSidProperty -and $objectSidProperty.Count -gt 0) {
            try {
                # Directly use the objectsid from the properties
                $groupSID = New-Object System.Security.Principal.SecurityIdentifier($objectSidProperty[0], 0)

                # Get the printer using WMI
                $Printer = Get-WmiObject -Query "SELECT * FROM Win32_Printer WHERE Name='$PrinterName'"

                if ($Printer) {
                    # Retrieve the current security descriptor
                    $securityDescriptor = $Printer.GetSecurityDescriptor().Descriptor

                    if ($securityDescriptor) {
                        $dacl = $securityDescriptor.DACL

                        # Create a new trustee for the security group
                        $trustee = ([WmiClass]"\\.\root\cimv2:Win32_Trustee").CreateInstance()
                        $trustee.Name = $SecurityGroup
                        $trustee.Domain = $Domain
                        [byte[]] $SIDArray = ,0 * $groupSID.BinaryLength
                        $groupSID.GetBinaryForm($SIDArray, 0)
                        $trustee.SID = $SIDArray

                        # Create a new ACE for the trustee
                        $ace = ([WmiClass]"\\.\root\cimv2:Win32_Ace").CreateInstance()
                        $ace.AccessMask = 131080  # Read and Print permissions
                        $ace.AceType = 0  # Allow
                        $ace.AceFlags = 0
                        $ace.Trustee = $trustee

                        # Ensure each ACE is a ManagementBaseObject
                        $newDacl = @()
                        foreach ($item in $dacl) {
                            $newDacl += [System.Management.ManagementBaseObject]$item
                        }

                        # Add the new ACE to the DACL
                        $newDacl += [System.Management.ManagementBaseObject]$ace

                        # Update the security descriptor with the new DACL
                        $securityDescriptor.DACL = $newDacl
                        $Printer.psbase.Scope.Options.EnablePrivileges = $true
                        $result = $Printer.SetSecurityDescriptor($securityDescriptor)

                        if ($result.ReturnValue -eq 0) {
                            $message = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Security group '$SecurityGroup' added to printer '$PrinterName' permissions."
                            Write-Host $message
                            Add-Content -Path $logPath -Value $message
                        } else {
                            $message = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Failed to set security descriptor for printer '$PrinterName'. Error: $($result.ReturnValue)"
                            Write-Host $message
                            Add-Content -Path $logPath -Value $message
                        }
                    } else {
                        $message = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - No ACL information found for printer '$PrinterName'."
                        Write-Host $message
                        Add-Content -Path $logPath -Value $message
                    }
                } else {
                    $message = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Printer '$PrinterName' not found."
                    Write-Host $message
                    Add-Content -Path $logPath -Value $message
                }
            } catch {
                $message = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Failed to convert objectsid for the security group '$SecurityGroup'. Error: $_"
                Write-Host $message
                Add-Content -Path $logPath -Value $message
            }
        } else {
            $message = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Failed to retrieve objectsid for the security group '$SecurityGroup'."
            Write-Host $message
            Add-Content -Path $logPath -Value $message
        }
    }
}

Add-Content -Path $logPath -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Script finished"
