# City Runner

City Runner is a demo bus tracking and seat management system for the Gangtok to Ranipool route. It includes a Next.js frontend with a Leaflet map and a FastAPI backend with in-memory demo state.

## Stack

- Frontend: Next.js App Router, Tailwind CSS, Leaflet
- Backend: FastAPI
- State: In-memory demo state
- Auth: Demo driver login

## Demo Driver Login

- Username: `driver`
- Password: `cityrunner123`

## Run The Backend

```bash
cd backend
python -m uvicorn main:app --reload --port 8000
```

## Run The Frontend

```bash
npm install
npm run dev
```

## Optional Frontend Env

Create `.env.local` if the backend is not running on `http://localhost:8000`.

```bash
NEXT_PUBLIC_API_BASE_URL=http://localhost:8000
```

## Features

- Live route map with Gangtok, Tadong, 6th Mile, Boomtar, Singtam Turn, and Ranipool
- Auto-moving bus marker that advances every 3 seconds while active
- Passenger bottom sheet with ETA, fares, distance, and read-only seats
- Protected driver view with login, seat toggling, reset, and active or inactive controls
