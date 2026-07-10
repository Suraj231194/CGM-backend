# Render demo deployment

This backend is prepared for a free Render demo deployment with Docker and Render Postgres.

## What Render creates

- `optimus-cgm-backend`: Docker web service on the free instance type.
- `optimus-cgm-db`: Render Postgres database on the free instance type.
- Laravel runs migrations on each deploy.
- Demo seed data is disabled by default with `RUN_DEMO_SEEDERS=false`.
- Production startup will never run `DemoDatabaseSeeder`, even if the flag is accidentally enabled.
- When `AUTH_BYPASS=true`, startup provisions only the configured bypass user,
  patient profile, and alert settings through `AuthBypassSeeder`. It never
  creates glucose readings, meals, reports, devices, or other demo records.

## Deploy steps

1. Push this Laravel backend folder to a GitHub repository.
2. In Render, create a new Blueprint and select that repository.
3. Render reads `render.yaml` and creates the web service and Postgres database.
4. Wait for the first deploy to finish.
5. Test the health endpoint:

```text
https://YOUR_RENDER_SERVICE.onrender.com/up
```

6. Use this URL in Flutter:

```bash
flutter run --dart-define=API_BASE_URL=https://YOUR_RENDER_SERVICE.onrender.com/api
```

## Data location

After deployment, app data saves in Render Postgres, not local SQLite.

Main tables:

- `users`
- `patient_profiles`
- `glucose_readings`
- `meal_logs`
- `sensor_orders`
- `report_exports`
- `alert_settings`
- `glucose_alerts`

## Demo warning

Render free web services can sleep after inactivity, and free Render Postgres is intended for testing/demo only. Move to paid Postgres before using real user or health data.

To populate a non-production environment for local testing, set
`RUN_DEMO_SEEDERS=true`. The default `DatabaseSeeder` and the dedicated
`DemoDatabaseSeeder` both refuse to populate demo records in production.
