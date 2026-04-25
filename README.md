# City Runner

City Runner is a multi-role bus tracking and seat management system for the Gangtok → Ranipool route in Sikkim.

## Stack

- Frontend: Next.js App Router, Tailwind CSS, OpenLayers with OpenStreetMap tiles
- Backend: FastAPI, SQLAlchemy, SQLite
- Auth: database-backed admin and driver login
- Password security: salted PBKDF2 password hashing

## Roles

- `User`: views live buses, route stops, ETA, fare list, and seat availability
- `Driver`: logs in on their phone, shares live GPS, manages seats, and updates bus status
- `Admin`: creates buses, provisions drivers, resets passwords, and monitors the fleet

## First-Time Setup

Create a `.env.local` file in the project root if needed:

```bash
NEXT_PUBLIC_API_BASE_URL=http://localhost:8000
CITY_RUNNER_ADMIN_USERNAME=admin
CITY_RUNNER_ADMIN_PASSWORD=cityrunner
CITY_RUNNER_ADMIN_NAME=City Runner Admin
```

The first admin account is created on backend startup only if no admin exists yet. `CITY_RUNNER_ADMIN_USERNAME` and `CITY_RUNNER_ADMIN_PASSWORD` are required for that first startup; the backend does not create default admin credentials.

## Run The Backend

```bash
cd backend
python -m pip install -r requirements.txt
set CITY_RUNNER_ADMIN_USERNAME=admin
set CITY_RUNNER_ADMIN_PASSWORD=cityrunner
set CITY_RUNNER_ADMIN_NAME=City Runner Admin
python -m uvicorn main:app --reload --port 8000
```

On PowerShell, you can also use:

```powershell
$env:CITY_RUNNER_ADMIN_USERNAME="admin"
$env:CITY_RUNNER_ADMIN_PASSWORD="cityrunner"
$env:CITY_RUNNER_ADMIN_NAME="City Runner Admin"
python -m uvicorn main:app --reload --port 8000
```

## Run The Frontend

```bash
npm install
npm run dev
```

Open:

```text
http://localhost:3000
```

## Current Features

- Real Sikkim route map for Gangtok → Ranipool
- Driver phone GPS becomes the live bus location source
- User, driver, and admin map views
- Embedded inline live-map card inside the app layout instead of a full background map
- Database-backed buses, drivers, seats, and sessions
- Admin-managed driver onboarding and password reset
- Driver self-service password change
- Loading skeletons while the frontend waits for the first bus payload

## If The Frontend Looks Broken In Dev

If `localhost:3000` starts showing a broken dev page or a stale 500, clear the Next.js cache and restart:

```powershell
Get-Process node | Stop-Process -Force
if (Test-Path .next) { Remove-Item -Recurse -Force .next }
npm run dev
```

Then do a hard refresh in the browser:

```text
Ctrl + Shift + R
```
