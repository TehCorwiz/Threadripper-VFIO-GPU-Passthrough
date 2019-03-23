# QEMU+KVM GPU Passthrough on Threadripper

Last Updated: 2019-03-23

## Introduction

I recently embarked on a quest to switch from dual-booting between Linux and Windows to a pure Linux system and move my Windows usage into a VM. Between the Arch Linux wiki and Level 1 Techs I foolishly believed I understood the factors involved and so ended up in a quagmire of failure without any debugging output. This isn't the story of how I got to a solution, it's instead a basic outline of the parts of the system that we need to be aware of and the issues I had with each component if any.

## Hardware

### Impact

At the base of the stack is the hardware. You generally need two features to setup PCI-E/GPU passthrough: AMD-v (or VT-x on Intel processors) and IOMMU. AMD has broad support for these technologies throughout their Ryzen and Threadripper lines, however beware lower-end motherboards which don't expose the options to enable these features in the BIOS/UEFI. As long as these features are supported you shouldn't have too much trouble.

### My Setup

* CPU: AMD Threadripper 1900X
* Motherboard: ASRock X399 Taichi
* RAM: 16GB G.Skill - Trident Z 16 GB (2 x 8 GB) DDR4-3200
* Host GPU: EVGA GTX 1060 6GB
* Guest GPU: MSI GTX 1080 DUKE 8G OC
* Guest USB: Mailiya PCI-E to Type-C + 5 Port Usb 3.0...blah..blah...here: https://www.amazon.com/gp/product/B01MQ5R7I1/ it's based on the NEC uPD720201 chip which is the important part.
* Host HD: Samsung SSD 960 EVO 500GB NVMe
* Guest HD: Sandisk 256G SSD (SDSSDH2256G)

#### Processor

When Threadripper first dropped there were some irregularities with its virtualization and IOMMU implementations which impeded PCIe passthorugh, however by spring 2018 they appear to have been fixed in most manufacturer BIOS updates, all upstream projects, and most common Linux distros. There should now be no outstanding issues with this processor family.

### Motherboard

In addition to the standard virtualization toggle `TODO: Add screenshot of VT toggle` in UEFI you also need to turn on IOMMU `TODO: Add screenshot of IOMMU toggle`. In my case I also needed to tweak the `TODO: I forgot the optin name, find it and screenshot it` option. This resolved an issue where QEMU would become a zombie process upon VM start and wouldn't produce any debug messages.

It's important to understand the relationship between your PCI-E slots and IOMMU groups, this varies by manufacturer and there are even some settings in some UEFI that can affect how IOMMU groups come together from PCI-E bus peripherals.

The Taichi has 2 16x PCI-E slots, 2 8x slots, and 1 1x slot. I've populated them as such:

1. (16x) Host GPU (GTX 1060)
2. (8x) Guest USB
3. (1x) Empty
4. (16x) Guest GPU (GTX 1080)
5. (8x) Empty

Despite the Guest USB card only being a 1x card I was forced to use the 8x slot due to how the IOMMU groups are laid out. As far as I can tell, the four 16x and 8x slots each get their own IOMMU group, while the 1x slot shares IOMMU Group 13 with the other on-board peripherals.

My IOMMU map looks like this:

```
IOMMU
├── 0
│   └── 00:01.0 Host bridge [0600]: Advanced Micro Devices, Inc. [AMD] Family 17h (Models 00h-1fh) PCIe Dummy Host Bridge [1022:1452]
├── 1
│   └── 00:01.1 PCI bridge [0604]: Advanced Micro Devices, Inc. [AMD] Family 17h (Models 00h-0fh) PCIe GPP Bridge [1022:1453]
├── 2
│   └── 00:02.0 Host bridge [0600]: Advanced Micro Devices, Inc. [AMD] Family 17h (Models 00h-1fh) PCIe Dummy Host Bridge [1022:1452]
├── 3
│   └── 00:03.0 Host bridge [0600]: Advanced Micro Devices, Inc. [AMD] Family 17h (Models 00h-1fh) PCIe Dummy Host Bridge [1022:1452]
├── 4
│   └── 00:03.1 PCI bridge [0604]: Advanced Micro Devices, Inc. [AMD] Family 17h (Models 00h-0fh) PCIe GPP Bridge [1022:1453]
├── 5
│   └── 00:04.0 Host bridge [0600]: Advanced Micro Devices, Inc. [AMD] Family 17h (Models 00h-1fh) PCIe Dummy Host Bridge [1022:1452]
├── 6
│   └── 00:07.0 Host bridge [0600]: Advanced Micro Devices, Inc. [AMD] Family 17h (Models 00h-1fh) PCIe Dummy Host Bridge [1022:1452]
├── 7
│   └── 00:07.1 PCI bridge [0604]: Advanced Micro Devices, Inc. [AMD] Family 17h (Models 00h-0fh) Internal PCIe GPP Bridge 0 to Bus B [1022:1454]
├── 8
│   └── 00:08.0 Host bridge [0600]: Advanced Micro Devices, Inc. [AMD] Family 17h (Models 00h-1fh) PCIe Dummy Host Bridge [1022:1452]
├── 9
│   └── 00:08.1 PCI bridge [0604]: Advanced Micro Devices, Inc. [AMD] Family 17h (Models 00h-0fh) Internal PCIe GPP Bridge 0 to Bus B [1022:1454]
├── 10
│   ├── 00:14.0 SMBus [0c05]: Advanced Micro Devices, Inc. [AMD] FCH SMBus Controller [1022:790b] (rev 59)
│   └── 00:14.3 ISA bridge [0601]: Advanced Micro Devices, Inc. [AMD] FCH LPC Bridge [1022:790e] (rev 51)
├── 11
│   ├── 00:18.0 Host bridge [0600]: Advanced Micro Devices, Inc. [AMD] Family 17h (Models 00h-0fh) Data Fabric: Device 18h; Function 0 [1022:1460]
│   ├── 00:18.1 Host bridge [0600]: Advanced Micro Devices, Inc. [AMD] Family 17h (Models 00h-0fh) Data Fabric: Device 18h; Function 1 [1022:1461]
│   ├── 00:18.2 Host bridge [0600]: Advanced Micro Devices, Inc. [AMD] Family 17h (Models 00h-0fh) Data Fabric: Device 18h; Function 2 [1022:1462]
│   ├── 00:18.3 Host bridge [0600]: Advanced Micro Devices, Inc. [AMD] Family 17h (Models 00h-0fh) Data Fabric: Device 18h; Function 3 [1022:1463]
│   ├── 00:18.4 Host bridge [0600]: Advanced Micro Devices, Inc. [AMD] Family 17h (Models 00h-0fh) Data Fabric: Device 18h; Function 4 [1022:1464]
│   ├── 00:18.5 Host bridge [0600]: Advanced Micro Devices, Inc. [AMD] Family 17h (Models 00h-0fh) Data Fabric: Device 18h; Function 5 [1022:1465]
│   ├── 00:18.6 Host bridge [0600]: Advanced Micro Devices, Inc. [AMD] Family 17h (Models 00h-0fh) Data Fabric: Device 18h; Function 6 [1022:1466]
│   └── 00:18.7 Host bridge [0600]: Advanced Micro Devices, Inc. [AMD] Family 17h (Models 00h-0fh) Data Fabric: Device 18h; Function 7 [1022:1467]
├── 12
│   ├── 00:19.0 Host bridge [0600]: Advanced Micro Devices, Inc. [AMD] Family 17h (Models 00h-0fh) Data Fabric: Device 18h; Function 0 [1022:1460]
│   ├── 00:19.1 Host bridge [0600]: Advanced Micro Devices, Inc. [AMD] Family 17h (Models 00h-0fh) Data Fabric: Device 18h; Function 1 [1022:1461]
│   ├── 00:19.2 Host bridge [0600]: Advanced Micro Devices, Inc. [AMD] Family 17h (Models 00h-0fh) Data Fabric: Device 18h; Function 2 [1022:1462]
│   ├── 00:19.3 Host bridge [0600]: Advanced Micro Devices, Inc. [AMD] Family 17h (Models 00h-0fh) Data Fabric: Device 18h; Function 3 [1022:1463]
│   ├── 00:19.4 Host bridge [0600]: Advanced Micro Devices, Inc. [AMD] Family 17h (Models 00h-0fh) Data Fabric: Device 18h; Function 4 [1022:1464]
│   ├── 00:19.5 Host bridge [0600]: Advanced Micro Devices, Inc. [AMD] Family 17h (Models 00h-0fh) Data Fabric: Device 18h; Function 5 [1022:1465]
│   ├── 00:19.6 Host bridge [0600]: Advanced Micro Devices, Inc. [AMD] Family 17h (Models 00h-0fh) Data Fabric: Device 18h; Function 6 [1022:1466]
│   └── 00:19.7 Host bridge [0600]: Advanced Micro Devices, Inc. [AMD] Family 17h (Models 00h-0fh) Data Fabric: Device 18h; Function 7 [1022:1467]
├── 13
│   ├── 01:00.0 USB controller [0c03]: Advanced Micro Devices, Inc. [AMD] X399 Series Chipset USB 3.1 xHCI Controller [1022:43ba] (rev 02)
│   ├── 01:00.1 SATA controller [0106]: Advanced Micro Devices, Inc. [AMD] X399 Series Chipset SATA Controller [1022:43b6] (rev 02)
│   ├── 01:00.2 PCI bridge [0604]: Advanced Micro Devices, Inc. [AMD] X399 Series Chipset PCIe Bridge [1022:43b1] (rev 02)
│   ├── 02:00.0 PCI bridge [0604]: Advanced Micro Devices, Inc. [AMD] 300 Series Chipset PCIe Port [1022:43b4] (rev 02)
│   ├── 02:04.0 PCI bridge [0604]: Advanced Micro Devices, Inc. [AMD] 300 Series Chipset PCIe Port [1022:43b4] (rev 02)
│   ├── 02:05.0 PCI bridge [0604]: Advanced Micro Devices, Inc. [AMD] 300 Series Chipset PCIe Port [1022:43b4] (rev 02)
│   ├── 02:06.0 PCI bridge [0604]: Advanced Micro Devices, Inc. [AMD] 300 Series Chipset PCIe Port [1022:43b4] (rev 02)
│   ├── 02:07.0 PCI bridge [0604]: Advanced Micro Devices, Inc. [AMD] 300 Series Chipset PCIe Port [1022:43b4] (rev 02)
│   ├── 04:00.0 Ethernet controller [0200]: Intel Corporation I211 Gigabit Network Connection [8086:1539] (rev 03)
│   ├── 05:00.0 Network controller [0280]: Intel Corporation Dual Band Wireless-AC 3168NGW [Stone Peak] [8086:24fb] (rev 10)
│   └── 06:00.0 Ethernet controller [0200]: Intel Corporation I211 Gigabit Network Connection [8086:1539] (rev 03)
├── 14
│   ├── 08:00.0 VGA compatible controller [0300]: NVIDIA Corporation GP104 [GeForce GTX 1080] [10de:1b80] (rev a1)
│   └── 08:00.1 Audio device [0403]: NVIDIA Corporation GP104 High Definition Audio Controller [10de:10f0] (rev a1)
├── 15
│   └── 09:00.0 Non-Essential Instrumentation [1300]: Advanced Micro Devices, Inc. [AMD] Zeppelin/Raven/Raven2 PCIe Dummy Function [1022:145a]
├── 16
│   └── 09:00.2 Encryption controller [1080]: Advanced Micro Devices, Inc. [AMD] Family 17h (Models 00h-0fh) Platform Security Processor [1022:1456]
├── 17
│   └── 09:00.3 USB controller [0c03]: Advanced Micro Devices, Inc. [AMD] Family 17h (Models 00h-0fh) USB 3.0 Host Controller [1022:145c]
├── 18
│   └── 0a:00.0 Non-Essential Instrumentation [1300]: Advanced Micro Devices, Inc. [AMD] Zeppelin/Renoir PCIe Dummy Function [1022:1455]
├── 19
│   └── 0a:00.2 SATA controller [0106]: Advanced Micro Devices, Inc. [AMD] FCH SATA Controller [AHCI mode] [1022:7901] (rev 51)
├── 20
│   └── 0a:00.3 Audio device [0403]: Advanced Micro Devices, Inc. [AMD] Family 17h (Models 00h-0fh) HD Audio Controller [1022:1457]
├── 21
│   └── 40:01.0 Host bridge [0600]: Advanced Micro Devices, Inc. [AMD] Family 17h (Models 00h-1fh) PCIe Dummy Host Bridge [1022:1452]
├── 22
│   └── 40:01.1 PCI bridge [0604]: Advanced Micro Devices, Inc. [AMD] Family 17h (Models 00h-0fh) PCIe GPP Bridge [1022:1453]
├── 23
│   └── 40:01.3 PCI bridge [0604]: Advanced Micro Devices, Inc. [AMD] Family 17h (Models 00h-0fh) PCIe GPP Bridge [1022:1453]
├── 24
│   └── 40:02.0 Host bridge [0600]: Advanced Micro Devices, Inc. [AMD] Family 17h (Models 00h-1fh) PCIe Dummy Host Bridge [1022:1452]
├── 25
│   └── 40:03.0 Host bridge [0600]: Advanced Micro Devices, Inc. [AMD] Family 17h (Models 00h-1fh) PCIe Dummy Host Bridge [1022:1452]
├── 26
│   └── 40:03.1 PCI bridge [0604]: Advanced Micro Devices, Inc. [AMD] Family 17h (Models 00h-0fh) PCIe GPP Bridge [1022:1453]
├── 27
│   └── 40:04.0 Host bridge [0600]: Advanced Micro Devices, Inc. [AMD] Family 17h (Models 00h-1fh) PCIe Dummy Host Bridge [1022:1452]
├── 28
│   └── 40:07.0 Host bridge [0600]: Advanced Micro Devices, Inc. [AMD] Family 17h (Models 00h-1fh) PCIe Dummy Host Bridge [1022:1452]
├── 29
│   └── 40:07.1 PCI bridge [0604]: Advanced Micro Devices, Inc. [AMD] Family 17h (Models 00h-0fh) Internal PCIe GPP Bridge 0 to Bus B [1022:1454]
├── 30
│   └── 40:08.0 Host bridge [0600]: Advanced Micro Devices, Inc. [AMD] Family 17h (Models 00h-1fh) PCIe Dummy Host Bridge [1022:1452]
├── 31
│   └── 40:08.1 PCI bridge [0604]: Advanced Micro Devices, Inc. [AMD] Family 17h (Models 00h-0fh) Internal PCIe GPP Bridge 0 to Bus B [1022:1454]
├── 32
│   └── 41:00.0 Non-Volatile memory controller [0108]: Samsung Electronics Co Ltd NVMe SSD Controller SM961/PM961 [144d:a804]
├── 33
│   └── 42:00.0 USB controller [0c03]: Renesas Technology Corp. uPD720201 USB 3.0 Host Controller [1912:0014] (rev 03)
├── 34
│   ├── 43:00.0 VGA compatible controller [0300]: NVIDIA Corporation GP106 [GeForce GTX 1060 6GB] [10de:1c03] (rev a1)
│   └── 43:00.1 Audio device [0403]: NVIDIA Corporation GP106 High Definition Audio Controller [10de:10f1] (rev a1)
├── 35
│   └── 44:00.0 Non-Essential Instrumentation [1300]: Advanced Micro Devices, Inc. [AMD] Zeppelin/Raven/Raven2 PCIe Dummy Function [1022:145a]
├── 36
│   └── 44:00.2 Encryption controller [1080]: Advanced Micro Devices, Inc. [AMD] Family 17h (Models 00h-0fh) Platform Security Processor [1022:1456]
├── 37
│   └── 44:00.3 USB controller [0c03]: Advanced Micro Devices, Inc. [AMD] Family 17h (Models 00h-0fh) USB 3.0 Host Controller [1022:145c]
├── 38
│   └── 45:00.0 Non-Essential Instrumentation [1300]: Advanced Micro Devices, Inc. [AMD] Zeppelin/Renoir PCIe Dummy Function [1022:1455]
└── 39
    └── 45:00.2 SATA controller [0106]: Advanced Micro Devices, Inc. [AMD] FCH SATA Controller [AHCI mode] [1022:7901] (rev 51)
```

The groups to keep an eye on are: Group 14 (PCI-E slot 4, Guest GPU), Group 13 (All of the on-board peripherals), Group 33 (Guest USB device), and Group 34 (PCI-E slot 1, Host GPU).

## Software

### Linux Kernel

Due to the threadripper specific fixes mentio0ned earlier kernel version 4.15 or later is required. I'm running Fedora 29 and kernel version `4.20.16-200.fc29.x86_64`.

### Virtualization

`sudo dnf install @Virtualization`


