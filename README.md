# TrollGram

TrollGram — неофициальная сборка Telegram для iOS на базе Swiftgram. Включает
разблокированные функции Plus/Privacy и слой плагинов, совместимый с
exteraGram (`.py`).

> Сборка **неподписанная**. Устанавливается через TrollStore или Sideloadly.
> Это не официальный клиент Telegram; используйте на свой риск.

---

## Что внутри

### 1. Брендинг
* Отображаемое имя приложения — **TrollGram**.
* Строки интерфейса, домен (`my.trollgram.app`), имя бота и настройки сборки
  переименованы; внутренние символы Swift/C++ не тронуты, чтобы не ломать
  компиляцию.

### 2. Plus / Privacy
В настройках появляется раздел **PRIVACY** (все переключатели включены по
умолчанию). Гейты выполняются в сетевом слое TelegramCore:

| Функция | Что делает | Где реализовано |
| --- | --- | --- |
| Anti-Delete | Копия удалённых сообщений в `Documents/TrollArchive/messages.json` | `TrollMessageArchive`, `DeleteMessages` |
| Edit History | Сохранение прошлых версий отредактированных сообщений | `TrollPrivacyRuntime.setArchiveFlags` |
| Ghost Mode | Мастер-переключатель для трёх пунктов ниже | `TrollPrivacyRuntime` |
| Hide Online | Не отправляет `account.updateStatus(offline:false)` | `ManagedAccountPresence` |
| Hide Read Receipts | Не отправляет read receipts (личные, группы, каналы, секретные чаты) | `SynchronizePeerReadState` |
| Hide Typing | Не отправляет `messages.setTyping` (включая «записывает голосовое») | `ManagedLocalInputActivities` |
| Hide Uploading | Не отправляет статусы загрузки медиа | `ManagedLocalInputActivities` |
| View Once Media | Одноразовые фото/видео не затираются и не запускают таймер | `MarkMessageContentAsConsumedInteractively` |
| Copy Protected | Разрешает копирование/пересылку из `noforwards`-чатов | `PeersData.CopyProtectionEnabled` |
| Remove Sponsored | Убирает рекламные посты из каналов | `AdMessages` |

Флаги хранятся локально в `UserDefaults` (`app.trollgram.ios.privacy`) и
зеркалятся в процессный рантайм при старте (`TrollPrivacyBootstrap.activate()`
в `AppDelegate.didFinishLaunching`).

### 3. Плагины exteraGram (`.py`)
* Встроенный CPython 3.11 (`third-party/python`, скачивается скриптом сборки).
* Экран **Settings → PRIVACY → Plugins**: список плагинов, включение,
  импорт `.py` через Files, лог плагинов.
* Совместимый SDK в `Swiftgram/PythonPlugins/stdlib`: `base_plugin`,
  `ui.settings`, `client_utils`, `android_utils`, `hook_utils`,
  `trollgram_bridge` (реализован на чистом Python, вызовы пишутся в
  `Documents/PluginsData`).
* Хук отправки сообщения: `ChatController.sendMessages` вызывает
  `on_send_message_hook`; `HookResult.CANCELLED` (2) отменяет отправку.

Плагины кладутся в `Documents/Plugins`:

* через кнопку **Import .py File** в экране плагинов;
* либо копированием файлов в `TrollGram/Plugins` через приложение «Файлы»
  (Documents приложения доступен, если включён file sharing).

### 4. Сборка
GitHub Actions: `.github/workflows/build-ipa.yml`.

* `workflow_dispatch` — кнопка **Run workflow** в разделе Actions.
* push тега `v*` — например `git tag v1.0 && git push --tags`.

Workflow собирает приложение Bazel-ом (кэш действий и репозиториев
сохраняется между запусками, dSYM не генерируются) и упаковывает `Payload/`
в `TrollGram.ipa`.

* `TrollGram.ipa` — неподписанный, ставится через TrollStore.
* `TrollGram-signed.ipa` — появляется, если в репозитории заданы секреты
  `P12_BASE64`, `P12_PASSWORD`, `MOBILEPROVISION_BASE64`: IPA
  переподписывается сертификатом и профилем из секретов (Sideloadly/AltStore).
  Ошибка переподписи не ломает сборку — неподписанный IPA публикуется всегда.

Оба файла попадают в артефакт и в **GitHub Release**. Переподписать уже
опубликованный IPA вручную можно workflow `Sign TrollGram IPA`
(`workflow_dispatch`, параметр `tag`). Если сборка падает, лог компилятора
автоматически публикуется в issue `CI build log`.

Локальная сборка на macOS:

```bash
python3 build-system/setup_python.py      # Python 3.11 + stdlib
python3 build-system/Make/Make.py \
  --cacheDir="$HOME/bazel-cache" \
  --bazelUserRoot="$HOME/bazel-trollgram" \
  build \
  --configurationPath=build-system/appstore-configuration.json \
  --codesigningInformationPath=build-system/fake-codesigning \
  --configuration=release_arm64 \
  --buildNumber=1000 \
  --skipDsym \
  --overrideXcodeVersion
```

### 5. Структура
```
Swiftgram/
  SGTrollPrivacy/        настройки privacy (Foundation-only)
  SGTrollPrivacyCore/    зеркалирование флагов в TelegramCore
  PythonPlugins/         хост плагинов + stdlib
  SGTrollPluginsUI/      экран управления плагинами
  SGSettingsUI/          раздел PRIVACY в настройках
submodules/TelegramCore/Sources/
  TrollPrivacyRuntime.swift        процессные флаги
  TrollMessageArchive.swift        локальный архив сообщений
third-party/python/      Python.xcframework + python.zip (генерируется)
```

## Лицензия
Код Telegram/Swiftgram сохраняет свои лицензии. Изменения TrollGram
распространяются на тех же условиях, что и исходный проект.
