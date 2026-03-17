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

Initialize MySQL with:

```powershell
Get-Content ".\scripts\init-db.sql" | & "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" --default-character-set=utf8mb4 -u root -p
```

The script creates:

- database `machine_control`
- user `machine_control_app`
- tables `users` and `devices`
- seed users `admin` / `operator`
- 5 demo devices

## Test

Run backend tests:

```powershell
& "C:\Program Files\nodejs\npm.cmd" test
```


