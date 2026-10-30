#!/bin/bash

#=================================================
# COMMON VARIABLES AND CUSTOM HELPERS
#=================================================

# Start the release binary with the app's env loaded; install_dir/data_dir come from the caller's scope.
# NB: cd out of root-owned app_tmp_work_dirs — the BEAM crashes at boot with an untraversable CWD; env values are alphanumeric/URL-safe, so word-splitting is safe.
plausible_ctl() {
    ynh_exec_as_app bash -c "set -a; source '$install_dir/env'; set +a; cd '$data_dir'; '$install_dir/app/bin/plausible' $1"
}

wait_for_url() {
    local url="$1" expect="${2:-200}" tries="${3:-90}"
    for _ in $(seq 1 "$tries"); do
        [ "$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "$url")" = "$expect" ] && return 0
        sleep 2
    done
    return 1
}
