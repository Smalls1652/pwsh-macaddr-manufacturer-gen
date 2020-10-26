[CmdletBinding()]
param(
    [Parameter(Position = 0, Mandatory)]
    [ValidateScript( {
            #Check to see if the provided input actually matches a MAC address string format.
            $regex = [System.Text.RegularExpressions.Regex]::new("(?'firstOctet'[a-fA-F0-9]{2})(?>[:-]|)(?'secondOctet'[a-fA-F0-9]{2})(?>[:-]|)(?'thirdOctet'[a-fA-F0-9]{2})(?>[:-]|)(?'fourthOctet'[a-fA-F0-9]{2})(?>[:-]|)(?'fifthOctet'[a-fA-F0-9]{2})(?>[:-]|)(?'sixthOctet'[a-fA-F0-9]{2})")

            switch ($regex.IsMatch($PSItem)) {
                $false {
                    throw [System.Exception]::new("The provided input does not match a known MAC address format.")
                    break
                }

                Default {
                    return $true
                }
            }
        })]
    [string]$MacAddress
)

process {
    #Get the contents of the manufacturer OUI data.
    $manufacturerDataFilePath = [System.IO.Path]::Combine($PSScriptRoot, "mac-address-oui.json")

    #If the data file doesn't exist, then throw an error.
    switch ((Test-Path -Path $manufacturerDataFilePath)) {
        $false {
            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    [System.Exception]::new("Could not find the file vendor file at '$($manufacturerDataFilePath)'."),
                    "ManufacturerDataFileNotFound",
                    [System.Management.Automation.ErrorCategory]::OpenError,
                    $manufacturerDataFilePath
                )
            )
            break
        }
    }

    $manufacturerData = Get-Content -Path $manufacturerDataFilePath -Raw | ConvertFrom-Json

    #Run a regex match on the provided MAC address to get the six octets.
    Write-Verbose "Parsing the provided MAC address."
    $macAddressRegex = [System.Text.RegularExpressions.Regex]::new("(?'firstOctet'[a-fA-F0-9]{2})(?>[:-]|)(?'secondOctet'[a-fA-F0-9]{2})(?>[:-]|)(?'thirdOctet'[a-fA-F0-9]{2})(?>[:-]|)(?'fourthOctet'[a-fA-F0-9]{2})(?>[:-]|)(?'fifthOctet'[a-fA-F0-9]{2})(?>[:-]|)(?'sixthOctet'[a-fA-F0-9]{2})")
    $macAddressRegexMatch = $macAddressRegex.Match($MacAddress)

    #Create a list of the found MAC address octets.
    $macAddressList = [System.Collections.Generic.List[string]]@(
        ($macAddressRegexMatch.Groups | Where-Object { $PSItem.Name -eq "firstOctet" }).Value,
        ($macAddressRegexMatch.Groups | Where-Object { $PSItem.Name -eq "secondOctet" }).Value,
        ($macAddressRegexMatch.Groups | Where-Object { $PSItem.Name -eq "thirdOctet" }).Value,
        ($macAddressRegexMatch.Groups | Where-Object { $PSItem.Name -eq "fourthOctet" }).Value,
        ($macAddressRegexMatch.Groups | Where-Object { $PSItem.Name -eq "fifthOctet" }).Value,
        ($macAddressRegexMatch.Groups | Where-Object { $PSItem.Name -eq "sixthOctet" }).Value
    )

    #Create a string of the full MAC address and the first three octets (The vendor OUI).
    $fullMacAddressString = $macAddressList -join ":"
    $vendorOuiMacAddressString = $macAddressList[0..2] -join ":"

    #Search the manufacturer data for the vendor OUI.
    $vendorData = $manufacturerData | Where-Object { $PSItem.VendorOui -eq $vendorOuiMacAddressString }

    #If the OUI is not found, then throw a terminating error.
    switch ($null -eq $vendorData) {
        $true {
            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    [System.Exception]::new("Vendor OUI not found."),
                    "VendorOuiNotFound",
                    [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                    $vendorOuiMacAddressString
                )
            )
            break
        }
    }

    #Return the lookup data
    return [pscustomobject]@{
        "MacAddress" = $fullMacAddressString;
        "VendorData" = $vendorData;
    }

}