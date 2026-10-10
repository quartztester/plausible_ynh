# Plausible Analytics (YunoHost) — admin notes

## Layout

- App release: `/var/www/__APP__/app` (native Elixir/OTP release, bundles its own Erlang runtime)
- Per-instance env: `/var/www/__APP__/env` (chmod 600; contains `SECRET_KEY_BASE`, DB and ClickHouse passwords)
- Data dir: `/home/yunohost.app/__APP__/` (`geodb/`, `sessions/`, `tmp/`)
- PostgreSQL database `__DB_NAME__` (user `__DB_USER__`)
- ClickHouse database `plausible_events_db`, user `default`, password in the `ch_password` app setting
- systemd unit: `plausible.service` (after `postgresql.service` and `clickhouse-server.service`)
- nginx: `/etc/nginx/conf.d/__DOMAIN__.d/plausible.conf`

## Managing registration

The `DISABLE_REGISTRATION` env var controls who can create accounts:
`invite_only` (default; existing users send invites), `true` (registration
closed), `false` (open). Edit `/var/www/__APP__/env`, then
`systemctl restart plausible`. It is also the `disable_registration` YunoHost
setting (configurable via `yunohost app config`).

## ClickHouse

- Pinned to 24.12.x (same major as Plausible CE's own compose stack).
  The apt repo is added only during install/upgrade, then removed.
- Config drop-ins in `/etc/clickhouse-server/config.d/` (loopback listen,
  low-resources profile from Plausible's CE) and `users.d/` (password for
  the `default` user) — the server never ran with the empty default
  password because drop-ins land before its first start.
- Shell access: `clickhouse-client --password "$(yunohost app setting plausible get ch_password)"`

## Useful commands

```bash
systemctl status plausible
journalctl -fu plausible            # app logs
curl -s http://127.0.0.1:8000/health/live   # health probe (from the box)
/var/www/plausible/app/bin/plausible remote # IEx shell into the running node
```

## Backups

YunoHost backups include the env, data dir, nginx/systemd/ClickHouse
configs, a PostgreSQL dump and ClickHouse table dumps (Native format) under
`clickhouse/`. Both databases are restored by the restore script.

## Upgrades

The upgrade script swaps the release, re-renders env/nginx/systemd and runs
`Plausible.Release.interweave_migrate` (PG + ClickHouse migrations in the
right order). ClickHouse version pin is bumped together with the app
version when upstream's CE compose moves.
