Случайный Выбор 
(Flutter + JS Web + FastAPI + SQLite)

Архитектура
- **Backend (FastAPI, SQLite)**: `backend/`
- **Web-frontend (vanilla JS)**: `frontend-web/`
- **Mobile UI (Flutter)**: `mobile-flutter/`

Быстрый старт

1) Backend
```bash
cd backend
python -m venv .venv && source .venv/bin/activate  # Windows: .venv\Scripts\activate
pip install -r requirements.txt
./run.sh  # Windows: uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```
API поднимется на `http://127.0.0.1:8000`.

````markdown
# Случайный Выбор — как запустить локально

Небольшая заметка и шаги для быстрой проверки проекта в локальной сети.

Структура
- backend/ — FastAPI + SQLite
- frontend-web/ — простая веб-версия (vanilla JS)
- mobile-flutter/ — Flutter приложение

Быстрый запуск backend
1. Откройте PowerShell и перейдите в папку `backend`:

```powershell
cd E:\.mcp-project\random_choice_app\backend
```

2. Создайте виртуальное окружение и установите зависимости:

```powershell
python -m venv .venv
. .venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

3. Запустите сервер (слушает на всех интерфейсах 0.0.0.0:8000):

```powershell
$env:DATABASE_URL = "sqlite:///./random_choice.db"
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

4. Проверьте локально: `http://127.0.0.1:8000/health` → `{"status":"ok"}`.

Запуск backend + Flutter вместе (Windows)
Чтобы одновременно поднять бэкенд и запустить мобильное приложение (`flutter run`) из одной команды на Windows, используйте скрипт `run_all.ps1` в корне проекта:

```powershell
cd E:\.mcp-project\random_choice_app
.\run_all.ps1
```

Скрипт попробует использовать `backend/.venv` (если он есть) иначе — системный `python`. Он запустит Uvicorn в фоне и затем выполнит `flutter run` в папке `mobile-flutter`. Логи бэкенда пишутся в `backend/server_stdout.log` и `backend/server_stderr.log`.

Подключение с телефона в одной Wi‑Fi сети
1. Убедитесь, что компьютер и телефон в одной сети.
2. Узнайте IPv4 компьютера: в PowerShell `ipconfig` → раздел адаптера Wi‑Fi → `IPv4 Address`, например `192.168.0.108`.
3. В приложении (или в `frontend-web/index.html`) укажите API URL `http://192.168.0.108:8000`.
4. Откройте на телефоне `http://192.168.0.108:8000/health` — должен быть ответ.

Веб-версия
- Откройте `frontend-web/index.html` в браузере. В поле `API URL` укажите `http://192.168.0.108:8000`.

Flutter (локально или на устройстве)
1. Перейдите в папку `mobile-flutter`:

```powershell
cd E:\.mcp-project\random_choice_app\mobile-flutter
```

2. Запустите приложение:

```powershell
flutter pub get
flutter run
```

3. Или собрать debug APK и установить на устройство:

```powershell
flutter build apk --debug
adb install -r .\build\app\outputs\flutter-apk\app-debug.apk
```

> В `mobile-flutter/lib/main.dart` по умолчанию теперь установлен `ApiConfig.baseUrl = 'http://192.168.0.108:8000'`.

API (кратко)
- `GET /health` — проверка
- `GET /lists` — получить списки
- `POST /lists` — создать список `{ "name": "..." }`
- `GET /lists/{id}/choices` — получить варианты
- `POST /lists/{id}/choices` — добавить вариант `{ "text": "..." }`
- `POST /lists/{id}/pick` — случайный выбор

````
