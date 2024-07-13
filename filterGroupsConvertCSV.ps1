# Define the input text file, output CSV file, and ignore list file
$inputFile = "C:\scripts\Printers\PrinterACLs.txt"
$outputCsvFile = "C:\scripts\Printers\filteredPrinterACLs.csv"
$ignoreFile = "C:\scripts\Printers\ignore.txt"

# Read the text file content
$textContent = Get-Content -Path $inputFile

# Read the ignore list and trim whitespace
$ignoreList = Get-Content -Path $ignoreFile | ForEach-Object { $_.Trim() }

# Initialize an array to hold the CSV data
$csvDataArray = @()

# Initialize a variable to store the current printer name
$currentPrinter = ""

foreach ($line in $textContent) {
    if ($line -match "^Printer: (.+)$") {
        $currentPrinter = $matches[1]
        Write-Output "Current Printer: $currentPrinter"
    } elseif ($line -match "^User/Group: (.+)$") {
        $group = $matches[1].Trim()
        if ($ignoreList -notcontains $group) {
            $csvDataArray += New-Object PSObject -Property @{
                PrinterName = [string]$currentPrinter
                Group = [string]$group
            }
            Write-Output "Added: PrinterName=$currentPrinter, Group=$group"
        } else {
            Write-Output "Ignored: $group"
        }
    }
}

# Debugging: Output the CSV data to console before writing to file
#foreach ($entry in $csvDataArray) {
#    Write-Output "PrinterName: $($entry.PrinterName), Group: $($entry.Group)"
#    # Ensure each entry is a PSCustomObject
#    Write-Output "Type: $($entry.GetType().Name)"
#}

# Write the CSV data to the file
$csvDataArray | Export-Csv -Path $outputCsvFile -NoTypeInformation -Encoding UTF8
