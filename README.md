<div align="center">

# ✳ GG Developer Studio

**Среда разработки Lua-проектов прямо внутри GameGuardian.**
Пишешь код, собираешь меню, компилируешь готовый скрипт — не выходя из студии.

[![Version](https://img.shields.io/badge/version-0.16-7c5cff?style=for-the-badge)](https://ggstudio.freedev.app)
[![Lua](https://img.shields.io/badge/Lua-100%25-2C2D72?style=for-the-badge&logo=lua&logoColor=white)](https://www.lua.org)
[![Platform](https://img.shields.io/badge/Android-GameGuardian-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://gameguardian.net)
[![License](https://img.shields.io/badge/license-MPL--2.0-e0407a?style=for-the-badge)](LICENSE)
[![Stars](https://img.shields.io/github/stars/nearzvx/GGDevStudio?style=for-the-badge&color=ffcc33)](https://github.com/nearzvx/GGDevStudio/stargazers)

[**Сайт студии**](https://ggstudio.freedev.app) · [**Скачать**](https://ggstudio.freedev.app) · [**Ошибка**](https://github.com/nearzvx/GGDevStudio/issues/new) · [**Идея**](https://github.com/nearzvx/GGDevStudio/issues/new)

</div>

---

```text
  ✳  GG DEVELOPER STUDIO  ·  workspace                    v0.16
  ──────────────────────────────────────────────────────────────
  project    my_next_idea.ggds        Lua · UTF-8 · GameGuardian
  blocks     templates/ui/pretty_menu
             templates/strings/format
             custom/core.logic        ← твой код
  check      ✓ синтаксис в порядке
  build      ⚡ готовый скрипт  →  Download/my_next_idea.lua
  ──────────────────────────────────────────────────────────────
  ● READY TO CREATE
```

<div align="center">
<sub>Одна идея меняет всё. От идеи до скрипта — несколько нажатий.</sub>
</div>

---

## ✨ Что это

**GG Developer Studio** — это полноценная рабочая среда для Lua-разработчиков под Android, которая живёт **внутри GameGuardian** и написана на **чистом Lua**.

Больше не нужно собирать скрипт из десяти файлов в блокноте, вручную склеивать меню и ловить синтаксические ошибки уже на телефоне при запуске. Студия берёт рутину на себя: структура проекта, шаблоны, проверка кода, заметки, задачи, резервные копии — и **компиляция прямо в студии** в один готовый `.lua`-файл.

> Сложные задачи. Простые инструменты.

---

## ✦ Возможности

| | Модуль | Что даёт |
|---|---|---|
| ⌘ | **Проекты** | Создание проекта в один клик, файл `.ggds`, понятная структура и сборка шаг за шагом |
| ▦ | **Библиотека** | **110 шаблонов**: интерфейсы и меню, работа со строками, файлы, хуки, API GameGuardian |
| ⚡ | **Компиляция** | Сборка проекта в готовый Lua-скрипт **прямо в студии** — без внешних тулчейнов и ПК |
| ⌁ | **Инструменты** | Проверка синтаксиса, сравнение файлов, заметки, управление задачами проекта |
| ✳ | **Своё** | Собственные Lua-блоки рядом с готовыми шаблонами — никаких ограничений на логику |
| ⛨ | **Надёжность** | Резервные копии, просмотр TODO по проекту, поиск ошибок **до** запуска |

---

## 🚀 Быстрый старт

**01 · Скачай архив**
Возьми актуальную версию на [сайте студии](https://ggstudio.freedev.app) — на Android-устройство.

**02 · Распакуй и запусти**

```
Download/
└── GG_Developer_Studio.lua   →  открыть через GameGuardian
```

> Важно: извлекай **архив целиком**, а не один файл — студия использует соседние ресурсы.

**03 · Начни создавать**

```
Новый проект  →  добавить шаблоны  →  дописать логику  →  Build  →  готовый скрипт
```

Результат сборки, проекты и заметки лежат в папке **`Download`**. Резервные копии — твоя лучшая привычка.

---

## 🧩 Как устроена студия

```
┌──────────────┐    ┌───────────────┐    ┌──────────────┐    ┌──────────────┐
│   Project    │ →  │   Templates   │ →  │    Check     │ →  │    Build     │
│  .ggds файл  │    │ 110 шаблонов  │    │   синтаксис  │    │  ready.lua   │
└──────────────┘    └───────────────┘    └──────────────┘    └──────────────┘
       ↑                    ↑                    ↑                   │
       └──────────  Заметки · Задачи · TODO · Бэкапы  ←───────────────┘
```

Студия сама следит за связностью проекта: ты добавляешь блоки, она собирает их в один скрипт с правильным порядком и служебной обвязкой.

---

## 📚 Библиотека шаблонов

**110 готовых блоков**, чтобы не начинать с пустого файла:

- **Интерфейсы** — меню, списки, переключатели, диалоги, всплывающие окна
- **Строки и таблицы** — форматирование, парсинг, утилиты
- **Файлы** — чтение/запись, работа с путями, конфиги
- **GameGuardian API** — типовые обёртки и паттерны вызовов
- **Заготовки проектов** — готовые каркасы под разные типы скриптов

Шаблон можно взять целиком, обрезать до нужного или использовать как шпаргалку по синтаксису.

---

## ⚙️ Требования

| Требование | Детали |
|---|---|
| Устройство | Android |
| Среда | [GameGuardian](https://gameguardian.net) (актуальная версия) |
| Сеть | Интернет обязателен — студия проверяет сервер при запуске |
| Файлы | Архив распакован целиком в `Download` |
| Версия | `0.16` (см. `manifest.json`) |

Совместимость зависит от версии среды и устройства. Если сервер недоступен — запуск будет остановлен с сообщением в студии.

---

## 📁 Структура репозитория

```
GGDevStudio/
├── GG_Developer_Studio.lua   # упакованная сборка студии (весь движок на Lua)
├── manifest.json             # версия релиза
├── README.md
└── LICENSE                   # MPL-2.0
```

> Файл `GG_Developer_Studio.lua` поставляется в **упакованном** виде (hex-упаковка). Это затрудняет чтение, но не является защитой — код восстанавливаем; сама студия целиком написана на Lua.

---

## 🗺️ Планы

- [x] Проекты, шаблоны и сборка внутри студии
- [x] Проверка синтаксиса, сравнение файлов, задачи и заметки
- [ ] Расширение библиотеки шаблонов
- [ ] Улучшение движка сборки (минификация, управление модулями)
- [ ] Ещё инструменты отладки

> Идеи приветствуются — [открой issue](https://github.com/nearzvx/GGDevStudio/issues/new) с тегом `idea`.

---

## ❓ FAQ

<details>
<summary><b>Что такое GG Developer Studio?</b></summary>

Lua-скрипт для GameGuardian, который превращает телефон в среду разработки: помогает создавать, организовывать и собирать собственные проекты и скрипты.
</details>

<details>
<summary><b>Как начать пользоваться?</b></summary>

Скачай архив с сайта, извлеки его **целиком** в `Download` и открой файл студии в GameGuardian.
</details>

<details>
<summary><b>Нужен ли интернет?</b></summary>

Да. Для запуска студии требуется соединение с сервером; если он недоступен — запуск останавливается.
</details>

<details>
<summary><b>Где сохраняются проекты?</b></summary>

Проекты, заметки и результаты сборки — в папке `Download`. Делай резервные копии: студия для этого даёт инструменты.
</details>

<details>
<summary><b>Почему файл студии «запакован»?</b></summary>

Чтобы код не растаскивали по кускам. Это не защита, а способ держать релиз в одном файле — движок всё равно остаётся Lua.
</details>

---

## 🤝 Участие

1. Форк → ветка `feature/твоя-идея`
2. Осмысленные коммиты, один PR — одна фича
3. Для багов — шаги воспроизведения, версия студии (из `manifest.json`) и модель устройства

Приветствуются: шаблоны для библиотеки, идеи инструментов, переводы, документация.

---

## ⚠️ Дисклеймер

Проект — **инструмент разработки** и не поставляется вместе с играми, читами или готовыми скриптами. Используй его в рамках правил GameGuardian и законодательства своей страны; ответственность за содержимое созданных скриптов лежит на авторе скрипта.

---

## 📄 Лицензия

Распространяется под **Mozilla Public License 2.0** — см. [LICENSE](LICENSE).

<div align="center">

**YOUR NEXT IDEA STARTS HERE ↗**

Сайт · [ggstudio.freedev.app](https://ggstudio.freedev.app) &nbsp;·&nbsp; Автор · [@nearzvx](https://github.com/nearzvx)

<sub>Made with Lua, pain and inspiration ✳</sub>

</div>

---

<details>
<summary><b>🇬🇧 English summary</b></summary>

**GG Developer Studio** — a Lua IDE that runs inside **GameGuardian** on Android and is itself written in 100% Lua. It gives you projects (`.ggds`), a library of **110 templates** (menus, strings, files, GameGuardian API), built-in **syntax checking**, file diff, notes, project tasks and backups — plus **in-studio compilation** of a finished, ready-to-run `.lua` script. No PC, no external toolchain.

**Requirements:** Android, GameGuardian, internet connection; extract the whole archive into `Download`, then open the studio file in GameGuardian. Builds land in `Download`. Licensed under MPL-2.0.

</details>
