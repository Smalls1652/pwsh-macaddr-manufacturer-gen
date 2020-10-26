[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [switch]$Compress
)

process {

    $convertToJsonSplat = $null
    switch ($Compress) {
        $true {
            #If '-Compress' is provided, then ensure that the JSON is compressed.
            Write-Warning "Output JSON will be compressed."
            $convertToJsonSplat = @{
                "Compress" = $true;
            }
            break
        }

        Default {
            #Otherwise, do not compress the JSON.
            $convertToJsonSplat = @{
                "Compress" = $false;
            }
            break
        }
    }

    #Get the manufacturer OUI file from the WireShark GitLab repo.
    Write-Verbose "Getting current OUI manufacturer file from WireShark's repository."
    $wiresharkOuiManufacturerFile = (Invoke-WebRequest -Uri "https://gitlab.com/wireshark/wireshark/-/raw/master/manuf" -Verbose:$false -ErrorAction "Stop").Content

    #Initialize the regular expression pattern for parsing the OUI file.
    Write-Verbose "Parsing the data in the file."
    $regexPattern = "^(?'oui'[A-F0-9:]{17}\/\d{2}|[A-F0-9:]{8})\t(?'vendorShortName'.+?)(?>$|\t(?'vendorLongName'.+?)$)"
    $regex = [System.Text.RegularExpressions.Regex]::new($regexPattern, [System.Text.RegularExpressions.RegexOptions]::Multiline, [System.TimeSpan]::FromSeconds(20))

    #Get all matches from the file
    $regexMatches = $regex.Matches($wiresharkOuiManufacturerFile)

    #Loop through each match found and add it to the 'manufacturerData' list object.
    Write-Verbose "Building object of the parsed data."
    $manufacturerData = [System.Collections.Generic.List[pscustomobject]]::new()
    foreach ($item in $regexMatches) {
        $manufacturerData.Add(
            [pscustomobject]@{
                "VendorOui"       = (($item.Groups | Where-Object { $PSItem.Name -eq "oui" }).Value);
                "VendorShortName" = (($item.Groups | Where-Object { $PSItem.Name -eq "vendorShortName" }).Value);
                "VendorLongName"  = (($item.Groups | Where-Object { $PSItem.Name -eq "vendorLongName" }).Value);
            }
        )
    }

    #Write the data to a JSON file in the script's root directory.
    $jsonOutPath = [System.IO.Path]::Combine($PSScriptRoot, "mac-address-oui.json")
    Write-Verbose "Writing parsed data to '$($jsonOutPath)'."
    $manufacturerData | ConvertTo-Json @convertToJsonSplat | Out-File -FilePath $jsonOutPath -Force
}