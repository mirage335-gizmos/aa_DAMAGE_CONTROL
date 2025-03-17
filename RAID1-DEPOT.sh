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

AVOID Shingled Magnetic Recording disks, as RAID resilvering, large file copying, etc, may cause non-responsiveness.

BACKGROUND



# ### _ Create _ ###

# REQUEST
# gParted ... partition table ... matching RAID1 partitions ... /dev/sdc2 LABEL ra1hdd   /dev/mmcblk1p2 LABEL ra1mmc

#-f (or erase existing filesystem first)
#-M (inappropriate for >5GB filesystems)
mkfs.btrfs --checksum xxhash -d raid1 -m raid1 -L ra1hdd /dev/disk/by-label/r1hdd1 /dev/disk/by-label/r1mmc2

# DANGER: Very strongly discouraged! Absence of either SATA or MMC controller, etc, during boot, could cause RAID array breakage.
# Optional.
#/etc/fstab
#nofail
#errors=remount‑ro
#defaults,compress=zstd:2,discard=async,commit=45,... 0 1
# CAUTION: SPECULATIVE
echo "LABEL=r1hdd1  /mnt/ingredients  btrfs  defaults,errors=remount-ro,commit=45,discard=async,compress=zstd:2,autodefrag,noatime,nofail  0  2" >> /etc/fstab


# ### _ Use _ ###

mkdir -p /mnt/ingredients

#thread_pool=16 (DUBIOUS)
# ...
#notreelog
# ...
#commit=3
#autodefrag
#compress-force,compress=zlib:9
# ...
#flushoncommit (DUBIOUS)
# ...
#noatime (preferred)
#relatime (possibly more compatible)
# ...
#barrier (DUBIOUS)
# ...
#acl (DUBIOUS)
# ...
#x-systemd.device-timeout=N (DUBIOUS)

mount -o errors=remount‑ro,commit=45,discard=async,compress=zstd:2,autodefrag,noatime /dev/disk/by-label/r1hdd1 /mnt/ingredients
#mount -o errors=remount‑ro,commit=45,discard=async,compress=zstd:2,autodefrag,noatime /dev/disk/by-label/r1mmc1 /mnt/ingredients
chown "$USER":"$USER" /mnt/ingredients

umount /mnt/ingredients


btrfs subvolume snapshot -r /mnt/ingredients /mnt/ingredients/.snapshots/$(date +%Y_%m_%d_%s%N | cut -b1-24)

#--commit-after --commit-each --recursive --verbose
btrfs subvolume delete /mnt/ingredients/.snapshots/*


compsize /mnt/ingredients



# ### _ Refurbishment (SPECULATIVE) _ ###

btrfs filesystem defragment -r /mnt/ingredients

#-v --dry-run
fstrim /mnt/ingredients


# ### _ Repair (SPECULATIVE) _ ###

#nospace_cache
#space_cache=v1
#space_cache=v2
#clear_cache,space_cache=v1
#clear_cache,nospace_cache
#mount -o ro,nologreplay,recovery,usebackuproot ...

# DANGER: NEVER while filesystem is mounted.
# ...
#--super=N: Use alternative superblock copy (0, 1, or 2)
#--backup: Use backup root tree
#--tree-root=BYTENR: Specify alternative tree root
#--chunk-root=BYTENR: Specify alternative chunk root
# ...
#--init-csum-tree: Rebuild checksum tree from scratch
#--init-extent-tree: Rebuild extent tree from scratch (useful for severe corruption)
#--chunk-recover: Recover chunk tree by scanning devices
#--clear-space-cache: Clear space cache during repair
# ...
#--check-data-csum: Verify data checksums (much slower but more thorough)
#--extra-extent-checking: Perform deep check of extent references
#--qgroup-report: Report quota group inconsistencies
#--subvol-extents: Check subvolume metadata
# ...
#--progress
btrfs check /dev/disk/by-label/r1hdd1
btrfs check --readonly /dev/disk/by-label/r1hdd1
btrfs check --repair /dev/disk/by-label/r1hdd1

btrfs rescue super-recover /dev/disk/by-label/r1hdd1
btrfs rescue chunk-recover /dev/disk/by-label/r1hdd1
btrfs restore /dev/disk/by-label/r1hdd1 /mnt/temporary

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

btrfs filesystem show /mnt/ingredients



# ### _ Survivability Testing (SPECULATIVE) _ ###

dd if=/dev/r1mmc2 of=/dev/sdc1 bs=512 count=1 seek=2048

losetup ...











<< 'EXTRA'

# SPECULATIVE
smartctl -i /dev/disk/by-label/r1hdd1 | grep -q "SMR"

| **notreelog** | Disables the "tree log" (also known as journal log) mechanism. The tree-log functionality in Btrfs is designed to speed up filesystem recovery after unexpected shutdowns by replaying the log quickly. Disabling it (`notreelog`) reduces performance overhead and wear on disks but can slow filesystem recovery slightly after power issues. Also slightly increases risk of losing recent file writes after a serious crash or power loss event. | Appropriate for workloads where reduced disk activity is needed at expense of minor data recovery safety. |



EXTRA


<< 'REFERENCE'

https://en.wikipedia.org/wiki/Shingled_magnetic_recording

https://btrfs.readthedocs.io/en/latest/Zoned-mode.html

REFERENCE



