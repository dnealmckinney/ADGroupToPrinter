# Define the output text file
$outputFile = "C:\scripts\Printers\PrinterACLs.txt"

# Get the list of printers using WMI
$printers = Get-WmiObject -Query "SELECT * FROM Win32_Printer"

# Initialize the output content
$outputContent = ""

foreach ($printer in $printers) {
    $printerName = $printer.Name
    $outputContent += "Printer: $printerName`n"

    try {
        # Retrieve the printer's security descriptor using WMI
        $printerInstance = Get-WmiObject -Query "SELECT * FROM Win32_Printer WHERE DeviceID='$($printer.DeviceID)'"

        if ($printerInstance) {
            $securityDescriptor = $printerInstance.GetSecurityDescriptor().Descriptor

            if ($securityDescriptor) {
                $dacl = $securityDescriptor.DACL

                foreach ($ace in $dacl) {
                    $outputContent += "User/Group: $($ace.Trustee.Name)`n"
                }
            } else {
                $outputContent += "No ACL information found.`n"
            }
        } else {
            $outputContent += "Failed to retrieve printer instance for $printerName.`n"
        }
    } catch {
        $outputContent += "Failed to retrieve ACL information for $printerName. Error: $_`n"
    }

    $outputContent += "`n"
}

# Write the output content to the file
$outputContent | Out-File -FilePath $outputFile -Encoding UTF8
