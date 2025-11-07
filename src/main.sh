#!/bin/bash

set -o errexit
set -o pipefail
#set -o nounset

# script location
export SCRIPT_PATH="$(readlink -f "${BASH_SOURCE}")"
export SCRIPT_DIR=$(dirname -- "$(readlink -f "${BASH_SOURCE}")")
export SCRIPT_NAME=$(basename -- "$(readlink -f "${BASH_SOURCE}")")
export SCRIPT_PARENT=$(dirname "${SCRIPT_DIR}")
export CLEAR="\e[0m"
export BOLD="\e[1m"
export UNDERLINE="\e[4m"
export RED="\e[31m"
export GREEN="\e[32m"
export YELLOW="\e[33m"
export BLUE="\e[34m"
export MAGENTA="\e[35m"
export CYAN="\e[36m"
export GREY="\e[38;5;248m"

# STATIC
PATH_CONFIG="${SCRIPT_PARENT}/config.cfg"
BASE_DIR="/var/lib/machines"

# DEFAULTS
# just in case $PATH_CONFIG cannot be read
SNAPSHOTS_BASE="/.snapshots"
SNAPSHOTS_MAX_NUM=7

# IMPORTS
source "${PATH_CONFIG}"

function is_btrfs_subvolume {
	# must be run as root!
	btrfs subvolume show ${1} > /dev/null 2>&1
}

function cleanup_snapshots {
	# Function to clean up old snapshots
	# If there are more than ${SNAPSHOTS_MAX_NUM} snapshots, delete the oldest ones
	# must be run as root!
	
	local required=(
		SNAPSHOTS_BASE
		SNAPSHOTS_MAX_NUM
	)
    local machine="${1}"
	local snapshots=("${SNAPSHOTS_BASE}/${machine}/"*)
    local snapshot

	# check required vars
    for var in "${required[@]}"  ; do
        if [[ -z "${!var}" ]]; then
            echo "ERROR: ${var} is not set or is empty." >&2
			return 1
        fi
    done
	
	# check
	if [[ ${#snapshots[@]} -eq 0 ]]; then
		echo "ERROR: No snapshots found in "${SNAPSHOTS_BASE}/${machine}/""
		return 1
	fi

    if [ ${#snapshots[@]} -gt ${SNAPSHOTS_MAX_NUM} ]; then
        for snapshot in $(printf "%s\n" "${snapshots[@]}" | sort | head -n -${SNAPSHOTS_MAX_NUM}); do
			# sort: oldest up, newest down
			# head -n -3: exclude the last/the newest <num> files
			echo "Removing old snapshot: ${snapshot}"
            rm -rf "${snapshot}"
        done
	fi
}

function main {

	local machine_path
	local machine_name

	if [ "${UID}" -ne 0 ]; then
		echo "This script must be run as root."
		exit 1
	fi	

	# Loop over each directory in the base directory
	for machine_path in "${BASE_DIR}"/*; do

		# Check if it is a directory
		if [ -d "${machine_path}" ]; then
			machine_name=$(basename "${machine_path}")
			
			if ! is_btrfs_subvolume ${machine_path}; then
				echo "Not a btrfs subvolume: ${machine_path}"
				echo "Skipping ..."
				continue
			fi

			# Shut down machine
			echo "Shutting down container: ${machine_name} ..."
			machinectl stop "${machine_name}"
			
			# Wait for the shutdown to complete
			while machinectl status "${machine_name}" &>/dev/null; do
				sleep 2
			done
			
			# Create a snapshot
			echo "Creating snapshot of machine: ${machine_name} ..."
			local snapshot_dir="${SNAPSHOTS_BASE}/${machine_name}"
            mkdir -p "${snapshot_dir}"
            btrfs subvol snapshot "${machine_path}" "${snapshot_dir}/$(date +%Y-%m-%d-%H%M%S)" # /.snapshots/nextcloud-db/2025-11-07-111429

			# Cleanup old snapshots
            cleanup_snapshots "${machine_name}"
			
			# Start the container again
			echo "Starting up container again: ${machine_name} ..."
			machinectl start "${machine_name}"
			
			echo "Snapshot and restart complete for: ${machine_name}"
		fi
	done
}

main