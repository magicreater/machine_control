# Machine Control Backend

## Start

Project root quick start:

```powershell
.\scripts\start-dev.cmd
```

This prepares the DevEco toolchain environment for the current session, checks MySQL, starts the local backend, and prints the next build/install commands.

## Backend Only
Install dependencies:

```powershell
& "C:\Program Files\nodejs\npm.cmd" install
```

Start the API:

```powershell
& "C:\Program Files\nodejs\npm.cmd" start
```

The default API base URL is `http://127.0.0.1:3000/api`.

## Database

Prepare the remote `platform` database with:

```powershell
npm run db:prepare-platform
```

Before running the migration, create `backend/.env` from `backend/.env.example` and point it at the target MySQL instance.

The migration script:

- extends `platform.details` with the fields required by the Harmony app
- keeps legacy `lck` and `lastUpdate` fields in sync
- seeds `admin` and `operator`
- upserts 5 demo potato-sorting devices into `details`

The backend now expects:

- database `platform`
- tables `admin`, `user`, and `details`
- a unique device key on `details.equipmentId`

## Server Deploy

Recommended production topology:

- `Nginx` listens on public `80/443`
- Node listens on private `127.0.0.1:3000`
- MySQL stays on private `3306`
- open `22/TCP` for SSH, `80/TCP` for HTTP, and `443/TCP` for future HTTPS
- keep `3000/TCP` and `3306/TCP` private

Deployment assets:

- `deploy/machine-control-backend.service`
- `deploy/machine-control.nginx.conf`

Recommended server `.env` values:

```dotenv
API_HOST=127.0.0.1
API_PORT=3000
MYSQL_HOST=127.0.0.1
MYSQL_PORT=3306
MYSQL_DATABASE=platform
MYSQL_USER=platform
MYSQL_PASSWORD=change_me
```

Smoke test after deploy:

```powershell
API_BASE_URL=http://127.0.0.1/api npm run smoke
```

## Test

Run backend tests:

```powershell
& "C:\Program Files\nodejs\npm.cmd" test
```


