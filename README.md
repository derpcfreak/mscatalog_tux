# mscatalog_tux.bash

This script is designed to download Windows Drivers for the current hardware from Microsoft® Update Catalog on Linux. It is a reference script that uses the functions from `functions.include`. Feel free to check the functions and create your own script if you want to download other drivers. I use this script to download boot-critical drivers during my PXE install of Windows using [P.E.T.E.R.](https://github.com/derpcfreak/P.E.T.E.R.)

If you want to use it for your own purpose just use `mscatalog_tux.bash` as a base for your custom script. Also take a look at the
functions from `functions.include` for more things you can do.

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

**Examples:**

**get_pci_by_class 02 '*' 1 # Any Network Controller and parent bridges**

```
PCI\VEN_8086&DEV_15D8&SUBSYS_20688086&REV_21
PCI\VEN_8086&DEV_24FD&SUBSYS_90108086&REV_78
```

**get_pci_by_class 01 '*' 1 # Any Mass Storage Controller and parent bridges**

```
PCI\VEN_8086&DEV_9D03&SUBSYS_20688086&REV_21
PCI\VEN_8086&DEV_9D03&SUBSYS_20688086&REV_21
PCI\VEN_1C5C&DEV_1327&SUBSYS_00001C5C&REV_00
```

**get_pci_by_class 0c '*' 1 # Any Serial Bus and parent bridges**

```
PCI\VEN_8086&DEV_9D2F&SUBSYS_20688086&REV_21
PCI\VEN_8086&DEV_9D2F&SUBSYS_20688086&REV_21
PCI\VEN_8086&DEV_9D23&SUBSYS_20688086&REV_21
PCI\VEN_8086&DEV_9D23&SUBSYS_20688086&REV_21
```

## function updates_page1

```
Usage: updates_page1 <QUERY>
       <QUERY> is what you would enter in the search field
       at https://www.catalog.update.microsoft.com/

Result will be a list of Update-IDs (GUIDs) for the <QUERY>
```

**Example:**

```bash
updates_page1 'PCI\VEN_8086&DEV_15D8'
```

**Output:**

```
50810f85-cb97-4c87-986a-ae58740c16ba
7b34a17e-3329-4a84-b390-33f56aa08d02
099772c9-de41-4050-b35a-8b5fc0c0056f
d0363136-fd04-4ef9-944a-e57e079befaf
8727e24f-d4a1-41c7-9724-b6a3e6ee8d5e
```


## function get_update_details

```
Usage: get_update_details <GUID>
```

**Example:**

```bash
get_update_details 65373dd7-4c1d-4e87-b8d9-dc7163359ed9
```

**Output:**

```
65373dd7-4c1d-4e87-b8d9-dc7163359ed9|2021/4/23|4/23/2021|1.0.0.51|Firmware|Lenovo Ltd.|ThinkPad L570 System Firmware 1.51|Compal Electronics, Inc|()
```

## function get_update_link

```
Usage: get_update_link <GUID>
```
**Example:**

```bash
get_update_link 65373dd7-4c1d-4e87-b8d9-dc7163359ed9
```

**Output:**

```
https://catalog.s.download.windowsupdate.com/d/msdownload/update/driver/drvs/2021/07/29cc0003-2b50-49c4-a451-2560aeb57078_66b0bd62fa9e80ca30093ca1281dde76e201875b.cab
```


Thanks to [Marco-online](https://github.com/Marco-online) and his [MSCatalogLTS](https://github.com/Marco-online/MSCatalogLTS) for some impressions.
