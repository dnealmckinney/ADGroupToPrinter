# SetPrinterACLwithADGroup
**Description:**
This colleciton of scripts will retrieve printer object info and write the printer name and security groups/users assigned to it to a text file. Second script to filter text file and create CSV with headers PrinterName and Group. Manual data changes using Excel during this stage. Use Excel export to a new CSV with headers PrinterName, SecurityGroup. Third script will use second CSV file to add the security group to the printer by creating and apphending the ACLs on the target printer. Filtering configuration is controlled by ignore.txt.

**Instructions:** 
1. Run PowerShell as Administrator
2. Run **getPrinters.ps1** - finds and writes local server printer permissions(acls) information to a text file `(PrinterACLs.txt)` in a simplied format.
3. Run **filterGroupsConvertCSV.ps1** - filters out text file `(PrinterACLs.txt)`, removing groups/user lines. Config included from `ignore.txt`. Creates CSV file `(filteredPrinterACLs.csv)` with headers `PrinterName` and `Group`.
4. Open the CSV **`(filteredPrinterACLs.csv)`** `PrinterName, Group` with Excel and filter out values. 
5. Create a new column `SecurityGroup` for the targeted AD group we want to add to a the corresponding printer. 
    This process will be tedious but in the end we should end up with 2 columns: `PrinterName` and `SecurityGroup`. 
6. Export from Excel as CSV **`(printers.csv)`** `PrinterName, SecurityGroup` and run the following script using it.
5. Run **setPrinterACLs.ps1** - this will use the CSV **`(printers.csv)`** `PrinterName, SecurityGroup` to add the Security Group to the Printer by appending ACLs.