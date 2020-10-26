# PowerShell MAC Address OUI JSON Generator

## Description

This repository contains a PowerShell script to generate a JSON file of the manufacturer OUI data from the WireShark repository. It parses the OUI, the short short name for the vendor, and the long name for the vendor. The JSON file could be used to help do MAC address vendor lookups locally.

## Usage

### Generating JSON file

To generate an updated JSON file, run this in a PowerShell console (**Ensure that your current directory is where the script is located!**):

```powershell
.\Invoke-MakeMacManufacturerJson.ps1
```

Additionally, if you want to have the JSON file compressed you can supply the `-Compress` switch parameter as well:

```powershell
.\Invoke-MakeMacManufacturerJson.ps1 -Compress
```

### Import the data into PowerShell

To import the data into your current PowerShell console, you can run this:

```powershell
$macAddressManuf = Get-Content -Path "path\to\file\mac-address-oui.json" -Raw | ConvertFrom-Json

$macAddressManuf

VendorOui VendorShortName VendorLongName
--------- --------------- --------------
00:00:00  00:00:00        Officially Xerox, but 0:0:0:0:0:0 is more common
00:00:01  Xerox           Xerox Corporation
00:00:02  Xerox           Xerox Corporation
00:00:03  Xerox           Xerox Corporation
00:00:04  Xerox           Xerox Corporation
00:00:05  Xerox           Xerox Corporation
00:00:06  Xerox           Xerox Corporation
00:00:07  Xerox           Xerox Corporation
00:00:08  Xerox           Xerox Corporation
00:00:09  Powerpip        powerpipes?
00:00:0A  OmronTat        Omron Tateisi Electronics Co.
[...]
```

Once the data is stored into a variable, you can use `Where-Object` to filter through the data.

For example...

If I wanted to get all of the OUI codes for ***Dell*** I could run this:

```powershell
$macAddressManuf | Where-Object { $PSItem.VendorShortName -eq "Dell" }

VendorOui VendorShortName VendorLongName
--------- --------------- --------------
00:06:5B  Dell            Dell Inc.
00:08:74  Dell            Dell Inc.
00:0B:DB  Dell            Dell Inc.
00:0D:56  Dell            Dell Inc.
00:0F:1F  Dell            Dell Inc.
00:11:43  Dell            Dell Inc.
00:12:3F  Dell            Dell Inc.
[...]
```

Or if I wanted to get the vendor for a MAC address I know I could run this:

```powershell
$macAddressManuf | Where-Object { $PSItem.VendorOui -eq ("34:48:ED:12:3A:BC".Substring(0,8)) }

VendorOui VendorShortName VendorLongName
--------- --------------- --------------
34:48:ED  Dell            Dell Inc.
```

## Assets used

* [WireShark `manuf` file](https://gitlab.com/wireshark/wireshark/-/raw/master/manuf)