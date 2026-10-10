Plausible Analytics is a lightweight, open-source, privacy-friendly web analytics tool.

The YunoHost package runs the **native Community Edition** (no Docker):

- Plausible itself is a prebuilt **Elixir/OTP release** (v3.2.1) with its own bundled Erlang runtime, served on loopback behind nginx.
- **PostgreSQL** (YunoHost-managed) stores sites, users and settings.
- **ClickHouse 24.12** (official debs, pinned like Plausible's own CE compose stack) stores the analytics events on loopback.
- Outgoing mail goes through YunoHost's local Postfix.

## Key features

- Simple dashboards with unique visitor counts, pageviews, bounce rate, visit duration
- Events and goals, funnels, retention, segments and filters
- Lightweight (< 1 KB) custom script, or a proxy for plausible.js
- No cookies, no cross-site tracking, GDPR/CCPA/PECR friendly
- Google Search Console integration (optional), import from Google Analytics
- Invite-based user management, TOTP 2FA, SSO SAML (optional)

## First launch

On first visit to `https://__DOMAIN__/register` you can create the owner
account (when registration policy allows). The email used for password
resets is the one configured at install (`admin_email` setting).

## Limitations

- Root path install only (`/` of a domain) — the app uses absolute URLs.
- No YunoHost SSO/LDAP integration: Plausible manages its own accounts,
  and the public stats/script endpoints need anonymous access.
