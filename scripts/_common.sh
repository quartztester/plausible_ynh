#!/bin/bash

#=================================================
# COMMON VARIABLES AND CUSTOM HELPERS
#=================================================

# Keep shared functions/variables here.

# Start the release binary with env loaded (install_dir/data_dir from caller scope).
# cd out of root-owned app_tmp_work_dirs or the BEAM crashes; env values are package-generated so word-splitting is safe.
plausible_ctl() {
    ynh_exec_as_app bash -c "set -a; source '$install_dir/env'; set +a; cd '$data_dir'; '$install_dir/app/bin/plausible' $1"
}

# Wait up to TRIES*2s for URL to answer with HTTP EXPECT.
wait_for_url() {
    local url="$1" expect="${2:-200}" tries="${3:-90}"
    for _ in $(seq 1 "$tries"); do
        [ "$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "$url")" = "$expect" ] && return 0
        sleep 2
    done
    return 1
}
