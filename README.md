# 🚀 zapret-discord-youtube-linux

Полноценный, удобный и стабильный порт популярной сборки **[Flowseal/zapret-discord-youtube](https://github.com/Flowseal/zapret-discord-youtube)** для **Linux** (с полной поддержкой **РЕД ОС 8**, Fedora, CentOS, RHEL, Ubuntu, Debian, Arch Linux).

Данный проект переносит все 22 стратегии обхода, дампы фейков и списки доменов/IP от Flowseal на Linux-движок `nfqws`, избавляя от проблем и багов сторонних надстроек.

---

## ✨ Особенности

- 🎯 **22 готовые стратегии Flowseal**: `ALT13`, `ALT12`, `ALT11`, `ALT`, `FAKE TLS AUTO`, `SIMPLE FAKE` и др.
- 📸 **Обход Meta (Instagram, Facebook, WhatsApp) и Telegram Web**: интеллектуальная маршрутизация через чистые Anycast CDN Edge IP (методика из Nukera) в комбинации с десинхронизацией `nfqws`.
- ✈️ **Встроенный MTProto WebSocket Proxy для Telegram**: локальный прокси (`127.0.0.1:1443`) для Telegram Desktop и мобильных приложений с автогенерацией `tg://` ссылки.
- ⚡ **Мгновенное переключение стратегий**: интерактивное меню или команда `sudo zapret-cli switch <имя>` на лету меняют стратегию и перезапускают службу.
- 🛡️ **Полная адаптация под РЕД ОС 8**: учтены правила SELinux, корректная работа `iptables/nftables`, включение `net.ipv4.tcp_timestamps = 1` для `ts`-спуфинга.
- 🎮 **Game Filter**: поддержка игрового фильтра (порты 1024–65535 для TCP и UDP) через меню или команду `zapret-cli game-filter`.
- 🔄 **Автообновление списков**: обновление актуальных IP-адресов (Discord, Cloudflare, YouTube) из репозитория Flowseal одной командой.
- ⚙️ **Чистая служба systemd**: надежный сервис `zapret-linux.service` без мусорных фоновых процессов и конфликтов.

---

## ⚡ Быстрая установка

Склонируйте репозиторий и запустите скрипт установки:

```bash
git clone https://github.com/Nemuro-teo/zapret-discord-youtube-linux.git
cd zapret-discord-youtube-linux
sudo bash install.sh
```

Скрипт автоматически:
1. Установит нужные системные зависимости (`iptables`, `ipset`, `libnetfilter_queue`).
2. Загрузит скомпилированный движок `nfqws` (bol-van v72.13 x86_64).
3. Установит все фейки `.bin`, списки `.txt` и 22 стратегии в `/opt/zapret-linux/`.
4. Активирует проверенную стратегию по умолчанию (**`general (ALT13)`**).
5. Настроит и запустит службу `systemd`, а также добавит утилиту `zapret-cli` в систему.

---

## 🎮 Управление стратегиями (`zapret-cli`)

Для управления используется удобная консольная утилита **`zapret-cli`**:

### 1. Выбор стратегии через интерактивное меню
```bash
sudo zapret-cli switch
```
Откроется нумерованный список всех 22 стратегий. Введите номер нужной стратегии, и служба автоматически применит её и перезапустится.

### 2. Быстрое переключение по имени
```bash
sudo zapret-cli switch alt13     # Включить стратегию ALT13
sudo zapret-cli switch alt12     # Включить стратегию ALT12
sudo zapret-cli switch alt11     # Включить стратегию ALT11
sudo zapret-cli switch fake_tls  # Включить FAKE TLS AUTO
```

### 3. Автоматический тест стратегий (как в Flowseal)
```bash
# Проверить доступность сервисов прямо сейчас:
zapret-cli test

# Протестировать ВСЕ 22 стратегии и выбрать работающую для вашего провайдера:
sudo zapret-cli test all

# Быстрый тест топ-6 самых популярных стратегий:
sudo zapret-cli test quick

# Протестировать конкретную стратегию:
sudo zapret-cli test alt12
```
Тест отправляет параллельные запросы к Discord (`discord.com`, `gateway.discord.gg`, `cdn.discordapp.com`) и YouTube (`youtube.com`, `googlevideo.com`) и формирует наглядную таблицу со статусом и временем отклика. По завершении можно одной клавишей переключиться на работающую стратегию!

### 4. Управление IPv6 (решение ERR_SSL_VERSION_OR_CIPHER_MISMATCH)
В современных дистрибутивах (Arch Linux, CachyOS и др.) по умолчанию включен двойной стек IPv6. Если провайдер не поддерживает десинхронизацию IPv6 или ТСПУ блокирует IPv6 TLS handshake, браузер выдает ошибку `ERR_SSL_VERSION_OR_CIPHER_MISMATCH`.

Команда для мгновенного решения:
```bash
# Проверить статус IPv6:
zapret-cli ipv6

# Принудительно отключить IPv6 (направить весь трафик через чистый IPv4):
sudo zapret-cli ipv6 off

# Включить IPv6 обратно при необходимости:
sudo zapret-cli ipv6 on
```

### 5. Разблокировка Meta (Instagram, Facebook) и Telegram Web (`hosts`)
В РФ ресурсы Meta (Instagram, Facebook) и частично Telegram заблокированы **на уровне IP-маршрутизации (BGP blackhole)** — обычный DNS возвращает заблокированные адреса, до которых пакеты даже не доходят.
В проекте реализован метод из Nukera / MagilaCDN: чистые Anycast CDN Edge IP сопоставляются с доменами в `/etc/hosts`, после чего `nfqws` успешно десинхронизирует TLS SNI.

```bash
# Проверить статус разблокировки hosts:
zapret-cli hosts

# Включить разблокировку Meta и Telegram Web:
sudo zapret-cli hosts on

# Отключить (вернуть стандартный /etc/hosts):
sudo zapret-cli hosts off
```
*Примечание:* при `sudo zapret-cli start` или `restart` хосты подключаются автоматически.

### 6. MTProto WebSocket прокси для Telegram Desktop (`zapret-cli tg`)
Для обхода блокировок звонков и медиа в Telegram Desktop и мобильных приложениях встроен локальный WebSocket MTProto-прокси:

```bash
# Включить прокси Telegram (автоматически создаст и запустит службу):
sudo zapret-cli tg on

# Автоматически открыть диалог подключения в приложении Telegram:
zapret-cli tg open

# Получить готовую ссылку для подключения в Telegram:
zapret-cli tg link

# Проверить статус службы:
zapret-cli tg status

# Просмотр лога подключений прокси в реальном времени:
zapret-cli tg log

# Остановить службу прокси:
sudo zapret-cli tg off
```
После включения достаточно выполнить `zapret-cli tg open`, либо кликнуть по ссылке `tg://proxy?server=127.0.0.1&port=1443&secret=...`, либо ввести параметры вручную в настройках Telegram (*Настройки -> Продвинутые -> Тип соединения -> Добавить прокси -> MTProto-прокси: Хост 127.0.0.1, Порт 1443*).

### 7. Список всех стратегий
```bash
zapret-cli list
```

### 8. Проверка статуса
```bash
zapret-cli status
```
Выводит название активной стратегии, состояние IPv6, состояние Meta/TG hosts, статус Telegram MTProto прокси, состояние игрового фильтра и системный статус службы.

### 9. Обновление списков доменов и IP
```bash
sudo zapret-cli update-lists
```
Скачивает актуальный `ipset-service.txt` (IP-адреса Discord, YouTube, CDN) из репозитория Flowseal и применяет обновления.

### 10. Настройка игрового фильтра
```bash
sudo zapret-cli game-filter
```

### 11. Просмотр логов в реальном времени
```bash
zapret-cli log
```

---

## 📁 Структура сборки

```text
/opt/zapret-linux/
├── bin/                       # Дампы фейков Flowseal (.bin) + nfqws
│   ├── nfqws
│   ├── quic_initial_www_google_com.bin
│   ├── tls_clienthello_www_google_com.bin
│   ├── tls_clienthello_sochi_park.bin
│   ├── tls_clienthello_max_ru.bin
│   ├── stun.bin, stun2.bin
│   └── ACTIVE_DISCORD_UDP.bin, ACTIVE_GAME_UDP.bin ...
├── lists/                     # Списки доменов и IP от Flowseal + Anycast IP
│   ├── ipset-all.txt          # База IP адресов (Discord, Cloudflare и др.)
│   ├── list-general.txt       # Основные домены (включая Discord, Meta, Telegram)
│   ├── list-google.txt        # Домены сервисов Google и YouTube
│   ├── list-exclude.txt       # Исключения
│   ├── hosts-meta.txt         # Anycast Edge IP для Instagram и Facebook
│   ├── hosts-telegram.txt     # Clean Edge IP для Telegram Web
│   └── *-user.txt             # Пользовательские списки
├── services/                  # Вспомогательные службы
│   └── tg-ws-proxy/           # MTProto WebSocket локальный прокси для Telegram
├── strategies/                # 22 файла готовых стратегий (.conf)
├── scripts/
│   ├── zapret-run.sh          # Скрипт запуска выбранной стратегии и фаервола
│   ├── zapret-stop.sh         # Скрипт корректной очистки правил iptables и hosts
│   └── zapret-hosts.sh        # Утилита управления Anycast CDN в /etc/hosts
├── zapret-cli                 # Главная утилита управления
└── current_strategy.conf      # Текущая выбранная стратегия
```

---

## 🔧 Пользовательские списки доменов и IP

Если вам нужно добавить свои сайты или исключения:
- `/opt/zapret-linux/lists/list-general-user.txt` — добавление ваших доменов в обход.
- `/opt/zapret-linux/lists/list-exclude-user.txt` — добавление доменов в исключения (не пускать через zapret).
- `/opt/zapret-linux/lists/ipset-exclude-user.txt` — добавление IP в исключения.

После редактирования примените изменения:
```bash
sudo zapret-cli restart
```

---

## 🛠️ Управление системной службой напрямую

Если вы предпочитаете стандартные команды `systemctl`:
```bash
sudo systemctl start zapret-linux      # Запустить
sudo systemctl stop zapret-linux       # Остановить
sudo systemctl restart zapret-linux    # Перезапустить
sudo systemctl status zapret-linux     # Статус
```

---

## ⚠️ Важно: запуск в виртуальных машинах (VirtualBox / VMware)

Если Linux запущен внутри виртуальной машины (VirtualBox, VMware) на Windows-компьютере, где **уже работает** Zapret (WinDivert):
- **Обязательно переключите тип подключения сети с NAT на «Сетевой мост» (Bridged Adapter)** в настройках виртуальной машины!
- **Почему это необходимо:** В режиме *NAT* весь сетевой трафик виртуальной машины проксируется через сетевой стек Windows. В результате пакеты десинхронизируются **дважды** (сначала `nfqws` в Linux, а затем `winws` в Windows), что полностью ломает TLS-рукопожатие (`decryption failed or bad record mac` / `ERR_SSL_VERSION_OR_CIPHER_MISMATCH`).
- В режиме *«Сетевой мост»* виртуальная машина получает собственный IP-адрес напрямую от роутера в локальной сети, полностью минуя сетевой стек и фильтры Windows-хоста.

---

## ❌ Удаление

Полностью удалить службу, правила фаервола, скрипты и утилиту из системы можно любой удобной командой:

```bash
# Быстро через CLI:
sudo zapret-cli uninstall

# Или напрямую через скрипт:
sudo bash /opt/zapret-linux/uninstall.sh

# Или из папки склонированного репозитория:
sudo bash uninstall.sh
```

---

## 🤝 Благодарности
- [bol-van](https://github.com/bol-van/zapret) — автор оригинального комплекса `zapret` и движка `nfqws`.
- [Flowseal](https://github.com/Flowseal/zapret-discord-youtube) — автор стратегий, дампов и списков.
- [finestcrtn/nukera](https://github.com/finestcrtn/nukera) — концепция Anycast Edge IP маршрутизации для Meta/Telegram и MTProto WebSocket прокси.
