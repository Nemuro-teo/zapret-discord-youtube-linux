# 🚀 zapret-discord-youtube-linux

Полноценный, удобный и стабильный порт популярной сборки **[Flowseal/zapret-discord-youtube](https://github.com/Flowseal/zapret-discord-youtube)** для **Linux** (с полной поддержкой **РЕД ОС 8**, Fedora, CentOS, RHEL, Ubuntu, Debian, Arch Linux).

Данный проект переносит все 22 стратегии обхода, дампы фейков и списки доменов/IP от Flowseal на Linux-движок `nfqws`, избавляя от проблем и багов сторонних надстроек.

---

## ✨ Особенности

- 🎯 **22 готовые стратегии Flowseal**: `ALT13`, `ALT12`, `ALT11`, `ALT`, `FAKE TLS AUTO`, `SIMPLE FAKE` и др.
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

### 5. Список всех стратегий
```bash
zapret-cli list
```

### 6. Проверка статуса
```bash
zapret-cli status
```
Выводит название активной стратегии, состояние IPv6, состояние игрового фильтра и системный статус службы.

### 7. Обновление списков доменов и IP
```bash
sudo zapret-cli update-lists
```
Скачивает актуальный `ipset-service.txt` (IP-адреса Discord, YouTube, CDN) из репозитория Flowseal и применяет обновления.

### 8. Настройка игрового фильтра
```bash
sudo zapret-cli game-filter
```

### 9. Просмотр логов в реальном времени
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
├── lists/                     # Списки доменов и IP от Flowseal
│   ├── ipset-all.txt          # База IP адресов (Discord, Cloudflare и др.)
│   ├── list-general.txt       # Основные домены
│   ├── list-google.txt        # Домены сервисов Google и YouTube
│   ├── list-exclude.txt       # Исключения
│   └── *-user.txt             # Пользовательские списки
├── strategies/                # 22 файла готовых стратегий (.conf)
├── scripts/
│   ├── zapret-run.sh          # Скрипт запуска выбранной стратегии и фаервола
│   └── zapret-stop.sh         # Скрипт корректной очистки правил iptables
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

## ❌ Удаление

Если вы решите полностью удалить сборку из системы:
```bash
sudo bash /opt/zapret-linux/uninstall.sh
```
(или из склонированной папки: `sudo bash uninstall.sh`).

---

## 🤝 Благодарности
- [bol-van](https://github.com/bol-van/zapret) — автор оригинального комплекса `zapret` и движка `nfqws`.
- [Flowseal](https://github.com/Flowseal/zapret-discord-youtube) — автор стратегий, дампов и списков.
