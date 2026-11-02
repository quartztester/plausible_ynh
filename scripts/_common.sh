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

# YunoHost's apt-extras helper breaks on pinned packages when the app also
# has regular apt packages: the deps-merge sed rewrites "pkg=ver" into
# "pkg (= ver)", a token apt cannot parse (E: Unable to locate package).
# So ClickHouse is provisioned here with the syntax apt accepts.
CH_VERSION="24.12.6.70"
CH_KEY_URL="https://github.com/quartztester/plausible_ynh/releases/download/v3.2.1-ynh1/clickhouse-key-v3.asc"

_plausible_install_clickhouse() {
    # "ii" = properly installed; a config-files leftover still reports a
    # version and would wrongly skip the install.
    if [ "$(dpkg-query --show -f'${db:Status-Abbrev}' clickhouse-server 2>/dev/null)" = "ii" ] \
        && [ "$(dpkg-query --showformat='${Version}' --show clickhouse-server 2>/dev/null)" = "$CH_VERSION" ]; then
        return 0
    fi
    ynh_script_progression "Installing ClickHouse $CH_VERSION from upstream repo..."
    mkdir -p /etc/apt/trusted.gpg.d
    wget --timeout=900 --quiet "$CH_KEY_URL" --output-document=- \
        | gpg --dearmor > /etc/apt/trusted.gpg.d/plausible_ch.gpg
    echo "deb https://packages.clickhouse.com/deb stable main" \
        > /etc/apt/sources.list.d/plausible_ch.list
    apt-get update -qq
    apt-get install -y --no-install-recommends --allow-downgrades \
        clickhouse-server="$CH_VERSION" clickhouse-client="$CH_VERSION" \
        clickhouse-common-static="$CH_VERSION"
    # Pinned to upstream's compose-stack version: hold so Debian's apt
    # never moves it behind our back; repo+key dropped right after.
    apt-mark hold clickhouse-server clickhouse-client clickhouse-common-static
    rm -f /etc/apt/sources.list.d/plausible_ch.list /etc/apt/trusted.gpg.d/plausible_ch.gpg
    apt-get update -qq
}
