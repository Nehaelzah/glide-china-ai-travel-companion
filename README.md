# Glide China — AI Travel Companion

Glide China is a Flutter and FastAPI prototype designed to help international travellers navigate China. It brings together multilingual travel support, mock or configurable AI assistance, a local-app guide, translation and speech interfaces, itinerary features, weather support, and community-oriented screens.

## Team project

This was developed in a six-person international team. Neha Elsa Renji contributed to quality assurance and testing, test-case design, release-readiness work, and presentation support. The public source has been prepared with the team’s permission.

## Technology

- Frontend: Flutter/Dart, Provider, Dio, maps, device-location, speech, and text-to-speech packages.
- Backend: Python, FastAPI, SQLAlchemy, Pydantic Settings, JWT-based sessions, and SQLite/MySQL-compatible configuration.
- Integrations: swappable mock/provider interfaces for chat, translation, speech, weather, and mapping services.

## Repository layout

- `lib/` — Flutter screens, state, services, and UI components.
- `assets/` — project UI assets required by the application.
- `backend/app/` — FastAPI routes, schemas, services, authentication helpers, and data models.
- `backend/.env.example` — non-secret configuration template.

## Run locally

Install Flutter, then run `flutter pub get`. Start the app with a deliberately configured backend URL, for example:

```bash
flutter run --dart-define=GLIDE_API_BASE_URL=http://localhost:8000
```

For the backend, create `backend/.env` from `backend/.env.example`, generate a strong local `SECRET_KEY`, set the specific frontend origin in `CORS_ORIGINS`, install `backend/requirements.txt`, and run the FastAPI app from `backend/`. The `.env` file and local database are ignored by Git.

## Security and privacy scope

The repository contains no API keys, tokens, databases, user records, device data, or local network addresses. The public copy removes active configuration, avoids a permissive CORS default, uses a build-time frontend endpoint, and disables the prototype’s console-based OTP flow unless explicitly enabled for local development.

This remains a prototype, not a production service. Before deployment, it requires a security review and production controls including a real OTP provider, rate limiting, monitoring, secure media storage, privacy and consent processes, and a review of features that process location, identity, or social content.

## Licensing and external services

The project does not ship third-party API credentials or external service data. Integration providers and any branded services represented in the UI have their own terms and branding policies; use them only with the required permissions.
