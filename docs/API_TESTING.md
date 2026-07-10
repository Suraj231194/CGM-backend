# API Testing Setup

Production API base URL:

```text
https://optimus-cgm-backend-production.up.railway.app
```

Health check:

```text
GET https://optimus-cgm-backend-production.up.railway.app/up
```

## Seeded Login Users

The production Railway database was seeded during deployment.

```text
Doctor:   doctor@optimus.test / password
Customer: customer@optimus.test / password
Admin:    admin@optimus.test / password
```

## VS Code REST Client

Install the VS Code extension named `REST Client` by Huachao Mao.

Open this file:

```text
docs/api-testing.http
```

Run requests in this order:

1. `Health check`
2. `Login as seeded doctor`
3. `Doctor: list assigned patients`
4. Copy a returned patient `id` into `@patientId` at the top of `docs/api-testing.http`
5. Run patient endpoints such as dashboard, readings, alerts, meals, sensors, and orders

The `.http` file automatically reuses the doctor token with:

```text
Authorization: Bearer {{doctorLogin.response.body.token}}
```

## Postman Setup

Create a Postman environment with:

```text
baseUrl = https://optimus-cgm-backend-production.up.railway.app
token =
patientId = 1
```

Login request:

```http
POST {{baseUrl}}/api/auth/sign-in
Content-Type: application/json
Accept: application/json

{
  "email": "doctor@optimus.test",
  "password": "password",
  "device_name": "postman"
}
```

In the login request `Tests` tab, add:

```javascript
const json = pm.response.json();
pm.environment.set("token", json.token);
```

For protected requests, add this header:

```text
Authorization: Bearer {{token}}
```

## Quick Curl Examples

Login and copy the `token` value from the response:

```bash
curl -s -X POST "https://optimus-cgm-backend-production.up.railway.app/api/auth/sign-in" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"doctor@optimus.test\",\"password\":\"password\",\"device_name\":\"curl\"}"
```

Use the token:

```bash
curl -s "https://optimus-cgm-backend-production.up.railway.app/api/patients" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

## Main Endpoints

Auth:

```text
POST /api/auth/sign-in
POST /api/auth/sign-out
GET  /api/auth/session
POST /api/auth/refresh
PUT  /api/auth/password
```

Master data:

```text
GET /api/master-data/enums
GET /api/master-data/integrations
GET /api/device-integrations
```

Patients:

```text
GET  /api/patients
POST /api/patients
GET  /api/patients/{patient}
PUT  /api/patients/{patient}
GET  /api/patients/{patient}/dashboard
```

Glucose:

```text
GET  /api/patients/{patient}/readings
POST /api/patients/{patient}/readings
POST /api/patients/{patient}/readings/bulk
GET  /api/patients/{patient}/glucose-summary
GET  /api/patients/{patient}/alerts
POST /api/alerts/{alert}/acknowledge
PATCH /api/alerts/{alert}/acknowledge
```

Patient activity:

```text
GET  /api/patients/{patient}/meals
POST /api/patients/{patient}/meals
GET  /api/patients/{patient}/orders
POST /api/patients/{patient}/orders
GET  /api/patients/{patient}/reports
POST /api/patients/{patient}/reports
```

Devices:

```text
GET   /api/patients/{patient}/sensors
POST  /api/patients/{patient}/sensors
PATCH /api/devices/{device}
GET   /api/patients/{patient}/sensor-sessions
POST  /api/patients/{patient}/sensor-sessions
PATCH /api/sensor-sessions/{session}
```

Doctor/admin:

```text
GET   /api/doctor/dashboard
GET   /api/admin/dashboard
GET   /api/patients/{patient}/clinician-notes
POST  /api/patients/{patient}/clinician-notes
GET   /api/patients/{patient}/care-tasks
POST  /api/patients/{patient}/care-tasks
PATCH /api/care-tasks/{task}/complete
GET   /api/organizations
POST  /api/organizations
```
