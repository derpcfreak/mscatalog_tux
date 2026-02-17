# mscatalog_tux.bash

This script is designed to download Windows Drivers for the current hardware from Microsoft® Update Catalog. It uses the functions from `functions.include` to do so.
It is a reference script. Feel free to check the functions and create your own script if you want to download other drivers
The functions are explained below.

Reference script to use the functions from `functions.include` to download drivers for the current hardware from Microsoft for

- `get_pci_by_class 02 '*' 1 # Any Network Controller and parent bridges`
- `get_pci_by_class 01 '*' 1 # Any Mass Storage Controller and parent bridges`
- `get_pci_by_class 0c '*' 1 # Any Serial Bus and parent bridges`

It was designed to download boot-critical drivers for Windows.

If you want to use it for your own purpose just use `mscatalog_tux.bash` as a base for your custom script. Also take a look at the
functions from `functions.include` for more things you can do.

Script and functions to download Windows drivers from mscatalog on Linux

## function get_pci_by_class

```
Usage:
  get_pci_by_class <main-class-hex|usb|tbt> [<subclass-hex|'*'|empty>] [<parents>] [<children>]

Arguments:
  <main-class-hex|usb|tbt> : Main PCI class (2 hex) or convenience values:
                             'usb' => 0c 03 (USB controllers)
                             'tbt'/'thunderbolt' => 0c 08 (Thunderbolt controllers)
  <subclass-hex>           : Subclass filter ('*', empty, or 2 hex digits)
  <parents>                : "1" to include parent bridges/hosts (default: 0)
  <children>               : "usb" to list attached USB devices,
                             "tbt" to list attached Thunderbolt devices,
                             "all" for both, or "0"/empty for none.

Examples:
  get_pci_by_class 01                          # All storage controllers
  get_pci_by_class 01 08                       # NVMe controllers
  get_pci_by_class 02 00                       # Ethernet controllers
  get_pci_by_class 02 00 1                     # Ethernet + parent bridges
  get_pci_by_class 0c 03 1 usb                 # USB controllers + parents + USB children
  get_pci_by_class usb '' 1 usb                # Same as above (convenience)
  get_pci_by_class tbt '' 0 tbt                # Thunderbolt controllers + TB children
  get_pci_by_class 0c 08 0 all                 # Thunderbolt controllers + both child types

PCI Class Codes:
  01 = Mass Storage Controller
       00 = SCSI      08 = NVMe
       01 = IDE       04 = RAID
  02 = Network Controller
       00 = Ethernet  80 = Other
  03 = Display Controller
       00 = VGA       80 = Other
  04 = Multimedia
       00 = Video     01 = Audio
  06 = Bridge Device             # Often parents of other devices
       00 = Host/PCI  04 = PCI-PCI
  0c = Serial Bus
       03 = USB       08 = Thunderbolt

Output Format:
  PCI\VEN_XXXX&DEV_YYYY[&SUBSYS_ZZZZVVVV][&REV_RR]
  USB\VID_XXXX&PID_YYYY[&REV_RR][&SERIAL_SSSS]
  TBT\UNIQUE_<id>[&VENDOR_<name>][&DEVICE_<name>]
```

## function updates_page1

```
Usage: updates_page1 <QUERY>
       <QUERY> is what you would enter in the search field
       at https://www.catalog.update.microsoft.com/

Result will be a list of Update-IDs (GUIDs) for the <QUERY>
```

## function get_update_details

```
Usage: get_update_details <GUID>
```

## function get_update_link

```
Usage: get_update_link <GUID>
```
