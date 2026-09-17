# BookOps Secure V1

This is the hardened rebuild of the lean BookOps prototype. The interface stays focused on Today, Book, Add note, client records, CSV import, follow-through, annual-review monitoring, and licensed approval gates.

## Security changes

- Client/book data is no longer stored in `localStorage`.
- D1 is the server-side source of truth.
- Passwords use PBKDF2-SHA256 with per-user salts.
- Session tokens are random; only their hashes are stored server-side.
- HttpOnly + SameSite=Strict session cookie.
- 12-hour absolute session lifetime and 30-minute idle expiry.
- Session-bound CSRF token and same-origin checks on state-changing requests.
- Login throttling: five failed-window attempts per IP/email key before temporary blocking.
- Every protected record query is scoped by authenticated `agency_id`.
- Roles: owner, agent, staff, readonly.
- Licensed approval authority is checked on the server and cannot be bypassed through ordinary task completion.
- CSV preview and commit are revalidated on the server.
- CSV size/row/column/cell limits and sensitive-column rejection are enforced.
- Obvious SSN, payment-card, credential, and medical-data patterns are blocked from notes.
- Audit history is append-only at the database layer.
- CSP, HSTS, clickjacking, MIME-sniffing, referrer, and browser-permission security headers are enabled.
- The annual-review watchdog runs server-side every 15 minutes and is idempotent.

## Use the hardened config

The hardened deployment entrypoint is:

```bash
wrangler.secure.toml
```

It points to `src/secure.ts`.

## Setup

1. Install dependencies:

```bash
npm install
```

2. Create the D1 database:

```bash
npx wrangler d1 create bookops-prod
```

3. Put the returned database ID into `wrangler.secure.toml`.

4. Add production secrets:

```bash
npx wrangler secret put BOOTSTRAP_SECRET -c wrangler.secure.toml
npx wrangler secret put SESSION_PEPPER -c wrangler.secure.toml
```

Use different long random values.

5. Apply the database migration:

```bash
npx wrangler d1 migrations apply bookops-prod --remote -c wrangler.secure.toml
```

6. Deploy:

```bash
npx wrangler deploy -c wrangler.secure.toml
```

7. Bootstrap the first owner once:

```bash
curl -X POST https://YOUR-BOOKOPS-DOMAIN/api/bootstrap \
  -H "Content-Type: application/json" \
  -H "X-Bootstrap-Secret: YOUR_BOOTSTRAP_SECRET" \
  --data '{
    "agencyName":"Pilot Insurance Agency",
    "ownerName":"Agency Owner",
    "ownerEmail":"owner@example.com",
    "ownerPassword":"Use-A-Strong-Unique-Password!123"
  }'
```

After the first user is created, the bootstrap endpoint closes itself.

## Production gate

Do not load real insurance-client data until all of these non-code gates are approved:

- Vidora / agency service agreement
- applicable carrier permissions
- retention and deletion policy
- incident response and notification process
- applicable licensing and privacy requirements
- production administrator MFA
- synthetic-data acceptance test
- documented user offboarding/access-removal process
- database backup/restore expectations

Never store Social Security numbers, payment data, medical information, enrollment credentials, or carrier-portal passwords in BookOps.
