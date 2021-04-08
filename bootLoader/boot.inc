;==== boot sector variable
BytePerSec equ 512
SecPerClus equ 1
ReservedSec equ 1
FatsCnt equ 2
RootEntryCnt equ 224
SecCnt16 equ 2880
MediaDscrb equ 0xf0
SecPerFat equ 9
SecPerTrack equ 18
HeadCnt equ 2
HidSec equ 0
SecCnt32 equ 0
DriveNo equ 0
Reserved equ 0
BootSig equ 0x29
VolumeId equ 0
%define VolumeLabel "boot"
%define FsType "FAT12"
%define OemName "TOY_OS"

DIR_nameOffset equ 0X00
DIR_nameLen equ 11
DIR_attrOffset equ 0x0b
DIR_attrLen equ 1
DIR_reserveBitsOffset equ 0x0c
DIR_reserveBitsLen equ 10
DIR_writeTimeOffset equ 0x16
DIR_writeTimelen equ 2
DIR_writeDateOffset equ 0x18
DIR_writeDateLen equ 2
DIR_firstClusterNoOffset equ 0x1a
DIR_firstClusterNoLen equ 2
DIR_fileSizeOffset equ 0x1c
DIR_fileSizeLen equ 4


SectorNoOfFAT1 equ Reserved
DirEntryBytes equ 32
RootDirSectors equ (RootEntryCnt * DirEntryBytes) / BytePerSec ; 14
SectorNoOfRootDir equ ReservedSec + FatsCnt * SecPerFat ; 19
ClusterSecNoOffset equ SectorNoOfRootDir + RootDirSectors - 2; first cluster is numbered 2
TmpBufferAddress equ 0x8000

BaseOfStack equ 0x7c00
OffsetOfLoader equ 0x9000