exit

<< 'BACKGROUND'

DEPOT disk arrangement with RAID1. Specialized, enhanced, 'puddleJumper'.

Assuming the usual:

W540 ThinkPad Laptop

>2TB HDD (internal)  --->  rsync >2TB HDD (external, backup: write-once)
 |___ <256MB mount scripts
 |___ 1TB RAID1 LABEL:r1hdd1  ingredients (dist/OS images, AI developer models, AI automation models)
 |___ >1TB  static (backup versions, kiwix/Wikipedia)

1TB SDCard (internal)
 |___ <256MB mount scripts
 |___ 1TB RAID1 LABEL:r1mmc2  ingredients

?128?GB SDCard (slot, ExpressCard adapter, optional)
 |___ ?128?GB  temporary

128GB USB3 (optional, possible alternatives)
 |___ 128GB  dist_OS

BACKGROUND



# ### _ Create _ ###

# REQUEST
# gParted ... partition table ... matching RAID1 partitions ... /dev/sdc2 LABEL ra1hdd   /dev/mmcblk1p2 LABEL ra1mmc

#-f (or erase existing filesystem first)
#-M (inappropriate for >5GB filesystems)
mkfs.btrfs --checksum xxhash -d raid1 -m raid1 -L ra1hdd /dev/disk/by-label/r1hdd1 /dev/disk/by-label/r1mmc2

# Optional. Very strongly discouraged.
#/etc/fstab
#defaults,compress=zstd:2,notreelog,discard=async,commit=45 0 1



# ### _ Use _ ###

#commit=3
#autodefrag
#compress-force,compress=zlib:9

mount -o commit=45,discard=async,compress=zstd:2,notreelog /dev/disk/by-label/r1hdd1 /mnt/ingredients
#mount -o commit=45,discard=async,compress=zstd:2,notreelog /dev/disk/by-label/r1mmc1 /mnt/ingredients

umount /mnt/ingredients


btrfs subvolume snapshot -r /mnt/ingredients /mnt/ingredients/.snapshots/$(date +%Y_%m_%d_%s%N | cut -b1-24)

btrfs subvolume delete /mnt/ingredients/.snapshots/*


compsize /mnt/ingredients



# ### _ Refurbishment (DUBIOUS) _ ###

btrfs filesystem defragment -r /mnt/ingredients



# ### _ Repair (DUBIOUS) _ ###

btrfs check
btrfs check --repair

btrfs device remove /dev/disk/by-label/r1hdd1 /mnt/ingredients
btrfs device remove /dev/disk/by-label/r1mmc2 /mnt/ingredients

btrfs device add /dev/disk/by-label/r1hdd1 /mnt/ingredients
btrfs device add /dev/disk/by-label/r1mmc2 /mnt/ingredients

#--bg
#-v
btrfs balance start -dconvert=raid1 -mconvert=raid1 /mnt/ingredients
btrfs balance start --full-balance -dconvert=raid1 -mconvert=raid1 /mnt/ingredients

btrfs scrub start -r -Bd /mnt/ingredients
btrfs scrub start -Bd /mnt/ingredients

btrfs scrub status /mnt/ingredients


btrfs device stats /mnt/ingredients



# ### _ Survivability Testing (DUBIOUS) _ ###

dd if=/dev/r1mmc2 of=/dev/sdc1 bs=512 count=1 seek=2048

losetup ...
























