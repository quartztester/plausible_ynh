# First launch

Open `https://__DOMAIN__` — on a fresh install Plausible shows its
first-launch page to **create the owner account** (the first user becomes
the instance owner). Registration policy is `invite_only` by default:
after the first account exists, further users can only join by invitation
from an existing user.

If you chose a YunoHost `admin` user at install, their email receives
password reset emails (Plausible sends through the server's local Postfix).

## Adding a site

1. Log in → **Add a website** → set the domain.
2. Paste the snippet into your site's `<head>`:
   `<script defer data-domain="yourdomain.tld" src="https://__DOMAIN__/js/script.js"></script>`
3. You can also serve `/js/script.js` from your own domain or use
   [script extensions](https://plausible.io/docs) (a hash suffix like
   `script.hash.js`, `script.localize.md`, etc. is supported by this app version).

Stats appear as visitors arrive.
