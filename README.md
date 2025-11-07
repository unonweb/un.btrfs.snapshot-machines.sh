# REQUIRES / EXPECTS

- systemd-nspawn containers in /var/lib/machines
- btrfs subvolumes in /var/lib/machines/<machine> for each container

# NOTES

- Look for systemd-nspawn machines in /var/lib/machines
- Snapshot them
- Clean-up old snapshots