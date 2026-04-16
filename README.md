# KPI Drive Kanban Board

## Запуск

```bash
flutter pub get
flutter build web
dart run tool/web_server.dart
```

Открыть в браузере:

```text
http://localhost:8080
```

## Переменные окружения

```bash
PORT=8080
KPI_BEARER_TOKEN=...
KPI_REQUESTED_MO_ID=42
KPI_AUTH_USER_ID=40
KPI_PERIOD_START=2026-04-01
KPI_PERIOD_END=2026-04-30
KPI_PERIOD_KEY=month
```

Пример:

```bash
PORT=8080 KPI_REQUESTED_MO_ID=42 dart run tool/web_server.dart
```
