#!/bin/bash

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

# apt-extras helper mangles pins alongside regular packages ("pkg=ver" -> "pkg (= ver)"); provision here
CH_VERSION="24.12.6.70"
CH_KEY_URL="https://github.com/quartztester/plausible_ynh/releases/download/v3.2.1-ynh1/clickhouse-key-v3.asc"

_plausible_install_clickhouse() {
    # "ii" only: a config-files leftover still reports a version
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
    # postinst prompts for the default-user password on stdin without it; hangs headless installs
    export DEBIAN_FRONTEND=noninteractive
    # postinst housekeeping can stall in CI; timeout + configure-resume turns the flake into a slow success
    if ! timeout 600 apt-get install -y --no-install-recommends --allow-downgrades \
        clickhouse-server="$CH_VERSION" clickhouse-client="$CH_VERSION" \
        clickhouse-common-static="$CH_VERSION"; then
        dpkg --configure -a
        timeout 600 apt-get install -y --no-install-recommends --allow-downgrades \
            clickhouse-server="$CH_VERSION" clickhouse-client="$CH_VERSION" \
            clickhouse-common-static="$CH_VERSION"
    fi
    # pin+hold to the compose-stack version; repo+key dropped right after
    apt-mark hold clickhouse-server clickhouse-client clickhouse-common-static
    rm -f /etc/apt/sources.list.d/plausible_ch.list /etc/apt/trusted.gpg.d/plausible_ch.gpg
    apt-get update -qq
}
