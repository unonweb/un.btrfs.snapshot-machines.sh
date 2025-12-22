CONFIG
======

Path config file: `un.machines.snapshot/config.cfg`
Vars:

```sh
SNAPSHOTS_BASE="/.snapshots"
INCLUDE_MACHINES=()
EXCLUDE_MACHINES=()
```

REQUIRES / EXPECTS
==================

- systemd-nspawn containers in `/var/lib/machines`
- btrfs subvolumes in `/var/lib/machines/<machine>` for each container

NOTES
=====

- Look for systemd-nspawn machines in /var/lib/machines
- Snapshot them
- Clean-up old snapshots

```sh
local latest_src_snap_path=$(printf "%s\n" "${src_snaps[@]}" | sort | tail -n 1)
local latest_src_snap_name=$(basename "${latest_src_snap_path}")
```

TO DO
=====

- Extend interactive mode