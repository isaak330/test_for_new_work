# KPI Drive Kanban Board

Flutter web-first тестовое задание: задачи из KPI Drive выводятся на канбан-доску, а перенос карточек между колонками сохраняется через backend.

## Почему есть локальный proxy

Живой API `https://api.dev.kpi-drive.ru` сейчас отдает `Access-Control-Allow-Origin` только для `https://admin.dev.kpi-drive.ru`.
Из-за этого браузер не сможет обращаться к API напрямую с локально запущенного Flutter Web.

Поэтому проект состоит из двух частей:

1. Flutter Web UI
2. Локальный Dart proxy/server, который:
   - раздает `build/web`
   - проксирует `/api/tasks` и `/api/tasks/move` к KPI Drive

## Запуск

```bash
flutter pub get
flutter build web
dart run tool/web_server.dart
```

После этого откройте:

```text
http://localhost:8080
```

## Доступные переменные окружения

По умолчанию подставлены значения из ТЗ, но их можно переопределить:

```bash
PORT=8080
KPI_BEARER_TOKEN=...
KPI_REQUESTED_MO_ID=42
KPI_AUTH_USER_ID=40
KPI_PERIOD_START=2026-04-01
KPI_PERIOD_END=2026-04-30
KPI_PERIOD_KEY=month
```

## Что уже заложено

- web-first UI
- drag-and-drop карточек по колонкам и внутри колонки
- обработка `STATUS` и `MESSAGES` от сервера
- защита от повторных переносов во время сохранения
- демо-режим, если backend недоступен или выдал ошибку
- понятные названия колонок по имени папки, а не только по id
