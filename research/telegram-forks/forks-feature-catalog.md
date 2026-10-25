# Каталог фич Telegram форков для Mollygram

Дата: **2026-10-25**. Статус: **исследование и кандидаты, не утверждённый roadmap**.

Здесь собраны конкретные заимствуемые сценарии, исходники Inugram и наши дополнительные идеи. Порядок работ определяет только [roadmap.md](../../docs/roadmap.md), состояние паритета — [parity.md](../../docs/parity.md). Это дополнение к [исследованию от 12 октября](../../docs/forks-research.md); номера старых stages оттуда нельзя переносить на M1–M9.

Метки доказательности:

- **Документация** — возможность прямо заявлена в указанном README, FEATURES или официальном сайте. Это не проверка приложения и не доказательство качества.
- **Код** — прочитаны конкретные файлы на указанном SHA. Проверена реализация соответствующего участка; сборка и runtime не проверялись.
- **Наша идея** — предлагаемый сценарий Mollygram, без утверждения об уникальности или наличии в стороннем клиенте.
- **Неизвестно** — обсуждалось, но выбранный источник не подтверждает точное поведение. Не считать отсутствием функции.

## Что уже входит в план

Ghost mode, история удалений и правок, local folders, перевод, фильтры, свои плагины и media quality уже обсуждены в [forks-research.md](../../docs/forks-research.md) и roadmap. Их наличие у ещё одного форка не делает их новой задачей. Дополнения ниже уточняют UX: например, не просто история правок, а diff относительно версии, которую я видел; не просто вложения, а сохранение выбранных файлов при закрытии панели.

По прочитанному parity.md уже заявлены переход к reply и обратно, поиск по отправителю/дате/медиа, серверный черновик, scheduled send, форматирование, ⌘S в viewer, Saved Messages с подчатами и тегами, транскрипция через RecognizeSpeech. Статусы в этом каталоге не переаудируют текущий продуктовый код; параллельная работа может менять parity. Несколько локальных черновиков, OCR-индекс и локальные коллекции нельзя объявлять готовыми на основании этих соседних функций.

## Сравнение форков

В таблице приведены проверенные заявленные функции и кандидаты для Mollygram. Если указано «неизвестно», ссылка — исходная точка дальнейшей проверки, а не подтверждение.

| Клиент и источник | Что подтверждено | Пример полезного сценария и граница переноса |
|---|---|---|
| [AyuGram Desktop — список](https://docs.ayugram.one/desktop/), [подробности](https://docs.ayugram.one/desktop/features/) | **Документация:** Message Shot, настройка контекстного меню, перемотка voice и circles | Выделить три сообщения → сохранить картинкой с настройками оформления. Скрывать имена/аватары по отдельному выбору, предпросмотр перед экспортом; изображение — не подтверждение подлинности переписки. Редкие действия меню можно вынести в расширенный слой. Seek полезен независимо от транскрипции; точность зависит от файла/декодера |
| [Kotatogram README](https://github.com/kotatogram/kotatogram-desktop/blob/HEAD/README.md), [changelog](https://github.com/kotatogram/kotatogram-desktop/blob/HEAD/kotatogram_changes.txt) | **Документация:** local folders, text replacements, retain selection after forward; в changelog также настройки счётчиков и default folder | Переслать подборку в рабочий чат и сохранить выделение для следующего действия. Папки уже в плане; дополнительные локальные правила не должны незаметно менять серверные папки. Замены текста отключаемы для кода/URL и совместимы с Undo |
| [64Gram features.md](https://github.com/TDesktop-x64/tdesktop/blob/HEAD/features.md) | **Документация:** поиск сообщений человека из avatar/member menu, Quick Forward to Saved Messages, shortcuts для forward/copy, Disable Cloud Draft Sync To Local | Контекстное «Сообщения этого человека» открывает существующий sender filter. Быстрое сохранение в Избранное — удобный вход в существующий forward. Отдельный save hotkey в выбранном features.md **не подтверждён**; не путать его с указанными ALT+F/ALT+C. Cloud→local switch — другое направление, чем запрет upload у Inugram |
| [Forkgram README](https://github.com/Forkgram/TelegramAndroid/blob/HEAD/README.md) | **Документация:** unmuted unread immediately after pinned, original forwarded date | Сначала закреплённые, затем непрочитанные со звуком; счётчики остаются согласованы с порядком. В forward header показать исходную дату с отличимой подписью, чтобы не путать её с датой пересылки |
| [Materialgram README](https://github.com/kukuruzka165/materialgram/blob/HEAD/README.md) | **Документация:** улучшенный export, сниженная JPEG-компрессия, voice bitrate, DC/исходная дата файла/фото, platform фото, experimental circle seek | В карточке файла — доступные метаданные с указанием происхождения; в экспорте — управляемое разбиение и загрузки. Увеличенный bitrate не обещает улучшения исходной записи. Upload boost не доказывает обход серверных ограничений |
| [Nagram README](https://github.com/NextAlone/Nagram/blob/HEAD/README.md) | **Документация:** original filename при скачивании, сохранение нескольких сообщений в Saved Messages, массовое снятие закрепления, voice noise suppression/enhancement | «Сохранить выбранные» с прогрессом и результатом по каждому объекту. Original filename нормализуется от path traversal и конфликтов имён. README перечисляет bulk unpin; bulk pin в этом источнике **неизвестно** |
| [Nekogram официальный сайт](https://nekogram.app/) | **Документация:** несколько движков перевода для чата/сообщения/статьи; бесплатная транскрипция через Workers AI | Выбирать провайдера по языку и условиям передачи данных. Бесплатность чужого сервиса не гарантирует нашу квоту/доступность. Текущая TDLib-транскрипция Mollygram и внешний ASR — разные пути |
| [Swiftgram официальный сайт](https://swiftgram.app/) | **Документация:** disable mentions/replies notifications, Quick Formatting panel | Независимо приглушить mentions/replies и обычные сообщения; панель форматов поверх уже существующего rich text, без новой модели entities |
| [exteraGram сайт](https://exteragram.app/), [plugin SDK](https://plugins.exteragram.app/docs) | **Документация:** reworked player, Python-плагины с Java interop/method hooking | Перенять сценарии плеера и каталог разрешений, не бинарную совместимость. exteraGram plugin compatibility уже исключена решением проекта. Транскрипция exteraGram в прочитанных страницах **неизвестно** |
| [Inugram FEATURES](https://github.com/teidesu/inugram/blob/10944b7772573a7240724ee9eec1acd6e8f2a07e/FEATURES.md) | **Документация** и пять разборов **кода** ниже | Наиболее полезен как набор небольших изменений состояния и переходов, а не готовый Flutter-компонент |
| [Octogram](https://github.com/OctoGramApp/OctoGram), [Cherrygram](https://github.com/arsLan4k1390/Cherrygram) | **Неизвестно:** конкретные обсуждавшиеся фичи не подтверждены прочитанными материалами этой сессии | Сохранены для следующего прохода; не приписываем им ни уникальность, ни готовую реализацию нужного сценария |
| [Unigram](https://github.com/UnigramDev/Unigram) | **Неизвестно** относительно уникальных фич этого списка | Референс Windows и клавиатурных сценариев для будущего M9; не доказательство наличия конкретной функции |

## Inugram с привязкой к исходникам

Снимок: commit [`10944b7772573a7240724ee9eec1acd6e8f2a07e`](https://github.com/teidesu/inugram/commit/10944b7772573a7240724ee9eec1acd6e8f2a07e), 2026-10-21. Через GitHub прочитаны FEATURES, дерево `src/`, нужные `.patch` и [series](https://github.com/teidesu/inugram/blob/10944b7772573a7240724ee9eec1acd6e8f2a07e/series). `series` перечисляет соответствующие patches для применения; это Android patchset, не отдельные готовые TDLib API. Даты в заголовках patches не заменяют SHA снимка.

### 1. Стек возврата по replies

**Код:** [remember-all-replies.patch](https://github.com/teidesu/inugram/blob/10944b7772573a7240724ee9eec1acd6e8f2a07e/patches/feature/remember-all-replies.patch).

В `ChatActivity` добавлен `ArrayDeque<int[]>`: запись хранит исходные message ID и load index. При переходе запоминается исходная точка, повтор верхнего ID не добавляется; Down извлекает последнюю запись и скроллит туда. Переход между поисковыми результатами очищает стек. Long press Down очищает его и ведёт к последнему сообщению. Обычный return-to-message остаётся fallback при выключенной настройке.

Собственный псевдокод механизма:

```text
onReplyJump(origin): push origin, если он не верхний
onDown: если стек непуст -> открыть pop(); иначе штатный переход
onSearchNavigation / onLongDown: очистить стек
```

Это стек replies внутри текущего экрана, а не полная browser history. Для Mollygram можно развить его в Back/Forward между чатами, поиском, ветками и panes; scoped IDs, anchor offset и восстановление после загрузки нужны дополнительно. Уже имеющийся один переход reply/back из parity — база, не доказательство многозвенного стека.

### 2. Сворачивание панели вложений с сохранением выбора

**Код:** [minimize-attach-panel.patch](https://github.com/teidesu/inugram/blob/10944b7772573a7240724ee9eec1acd6e8f2a07e/patches/feature/minimize-attach-panel.patch) и [AttachMinimizeHelper.kt](https://github.com/teidesu/inugram/blob/10944b7772573a7240724ee9eec1acd6e8f2a07e/src/fork/helpers/chat/AttachMinimizeHelper.kt).

В диалоге отмены выбора появляется нейтральное действие Minimize. Текущий selection generation помечается сохранённым; при повторном открытии `inu_consumePreservedState()` позволяет пропустить обычный `init()` и перезапись подписи. Helper показывает на attach button число сохранённых объектов. Новый `init()` увеличивает поколение и инвалидирует прежнее сохранение.

Ограничение в коде существенное: только `photoLayout`, обычный `ChatActivity`, без редактируемого сообщения, avatar picker, photo picker и sticker mode. Это сохранение состояния существующего alert, **не доказательство сохранения вложений на диск или переживания перезапуска**. Для Mollygram: выбрала 4 фото → свернула → перечитала переписку → вернулась к тем же фото и подписи. Долговечные несколько черновиков — наша отдельная идея.

### 3. Локальное сохранение без upload cloud draft

**Код:** [cloud-drafts.patch](https://github.com/teidesu/inugram/blob/10944b7772573a7240724ee9eec1acd6e8f2a07e/patches/debloat/cloud-drafts.patch).

В `MediaDataController` локальный `saveDraft(...)` остаётся перед условием. Отправка `TL_messages_saveDraft` дополнительно проверяет `DISABLE_DRAFT_UPLOAD`; прочие условия encrypted/forum остаются на штатном пути. Это запрещает upload на прочитанном участке, а не доказывает блокировку всех видов drafts в каждом кодовом пути.

Для Mollygram разделить «хранить локально», «принимать изменения из облака» и «публиковать текущий draft в облако». Переключатель 64Gram из features.md относится к **cloud→local**, а здесь **local→cloud**. Множество локальных drafts нельзя отображать на несколько серверных слотов без подтверждённого контракта. При отключении upload уже существующий cloud draft сам по себе не исчезает.

### 4. Preview ссылки на конкретное сообщение

**Код:** [MessageLinkPreviewHelper.kt](https://github.com/teidesu/inugram/blob/10944b7772573a7240724ee9eec1acd6e8f2a07e/src/fork/helpers/chat/MessageLinkPreviewHelper.kt).

Helper распознаёт публичные t.me ссылки и private `/c/`, а также `tg://resolve` и `tg://privatepost` с post ID. Сначала использует cached peer или resolver, проверяет возможность открыть чат. Для форума загружает исходное сообщение, определяет topic, при необходимости загружает topic и создаёт preview соответствующего `ChatActivity`. Есть отменяемый progress и ошибка отсутствия объекта. Query `comment` и `thread` **явно исключены парсером**; нельзя заявлять поддержку всех ссылок на обсуждения.

UX Mollygram: контекстное «Предпросмотр сообщения» сохраняет место чтения; «Открыть» переводит в обычную историю или отдельную pane. Предпросмотр не даёт доступ к private chat без прав. Даже без навигации может загружать данные и инициировать клиентские события: совместимость с ghost mode проверяется отдельно.

### 5. Diff редактирования в admin log

**Код:** [admin-logs.patch](https://github.com/teidesu/inugram/blob/10944b7772573a7240724ee9eec1acd6e8f2a07e/patches/hooks/admin-logs.patch) и [WordDiff.kt](https://github.com/teidesu/inugram/blob/10944b7772573a7240724ee9eec1acd6e8f2a07e/src/core/src/main/kotlin/desu/inugram/core/diff/WordDiff.kt).

Hook передаёт old/new message в `AdminLogHelper.applyEditDiff`; прочитанный `WordDiff.compute` отдельно вычисляет диапазоны EQUAL/INSERT/DELETE. Pipeline: токены слов/цифр и пробелов → Myers → уточнение соседних удалений/вставок по символам → объединение шумных участков. Вычисления идут по code points с переводом в строковые offsets: surrogate pairs не делятся. Code points при этом не гарантируют целостность сложных grapheme clusters.

Пример нашего UI: «Сдача ~~в четверг~~ **в пятницу**». Доступность old/new версии из admin event не означает, что сервер отдаёт историю правок любого сообщения любому участнику. Для «что изменилось после моего чтения» нужен собственный снимок увиденной версии; это наша идея поверх M3, не тот же admin log. Полный renderer и его корректность здесь не аудировались.

### Ещё возможности из FEATURES

Ниже **документация**, без утверждения о прочитанной реализации. Источник для каждой строки — [FEATURES на том же SHA](https://github.com/teidesu/inugram/blob/10944b7772573a7240724ee9eec1acd6e8f2a07e/FEATURES.md).

| Возможность | Конкретное применение | Ограничение и пересечение |
|---|---|---|
| Media search type + sender, only matches | «Файлы от Маши» и компактный список только найденного | M2 уже имеет sender/media; only matches — отдельный UX-кандидат. Не обещать OCR |
| Select between messages, >100 selection, auto-chunk forwards/saves/deletes | Два края диапазона → выбран промежуток; 250 объектов → прогресс batches | UI cap и реальные серверные лимиты различаются. Дополнительно прочитан [no-selection-cap.patch](https://github.com/teidesu/inugram/blob/10944b7772573a7240724ee9eec1acd6e8f2a07e/patches/feature/no-selection-cap.patch): он снимает UI cap и разбивает delete по 100, с оговоркой для secret-chat randoms. Один этот patch не подтверждает batching forwards/saves; это заявление FEATURES. M2 multi-select |
| Spoiler web previews | URL под spoiler → вся карточка preview скрыта до раскрытия | Скрыть нужно image/title/description и доступное описание; обычные spoilers уже M2 |
| Copy photo / copy frame, GIF seekbar | Остановить видео на нужном кадре → скопировать | Декодирование, HDR→SDR, clipboard lifetime; M4/viewer |
| Меню, animation multiplier, reduce menu motion | Убрать редкие действия, ускорить интерфейс или выключить motion | Единый action registry, клавиатура и accessibility остаются согласованы; M1/M7 |
| JSON settings export/import | Перенести конфигурацию на второй Mac | Только allowlist полей, schema version, preview изменений; без auth keys, sessions, database secrets. Наличие cloud settings через Web App Storage у форка не даёт нам готового backend |
| App font stack с fallbacks, отдельный monospace | Основной шрифт + fallback кириллицы/азиатских письменностей; code font отдельно | Метрики и timeline height cache инвалидируются; проверить emoji/ligatures, M7 |
| Режимы folder unread counters | Исключить muted или muted non-DM, скрыть счётчик | Объяснимое вычисление badge, не менять read state; M1/M6/M7 |
| Hide custom authors без блокировки | Приглушить автора в группе без server block | Локальный render filter с «показать скрытое» и доступом к reply context; M5 |
| Per-chat theme/wallpaper override | Игнорировать установленную собеседником тему для читаемости | Локальная настройка, темы и доступность M7 |
| MapLibre и выбор map preview provider | Выбрать подходящий картографический источник | Ключи, лицензии, доступность и передача координат провайдеру — отдельный контракт; M2/M7 |
| Paranoia/display mode с выбором скрытых чатов | Режим демонстрации экрана с редактированными данными | Не приравнивать скрытие UI к OS capture protection. Нужны search/palette/recent/notifications safeguards; базовый streamer mode уже M3 |
| Очистка URL, resolve redirects, web preview replacements | Открыть/вставить менее отслеживаемую ссылку, улучшить preview | Наша политика: точные правила по host и назначению, preview/Undo; сохранять signed/auth/invite/payment и прочие значимые параметры. В FEATURES среди удаляемых есть erid — автоматически переносить такое правило нельзя. Не удалять erid бездумно. Разрешение redirect само делает сетевой запрос; `twitter→fixupx` меняет получателя данных |
| Original video quality, audio removal без re-encode video | Убрать звук, сохранить исходный видеопоток | Это отдельный remux-путь при поддерживаемом контейнере/кодеке, не все edits возможны без re-encode. M4 уже про media quality |

## Наши идеи для рабочего клиента

Все пункты этого раздела — **наши идеи**, а не обнаруженные уникальные функции названных форков. «Связь с M» означает зависимость от имеющихся возможностей, не включение в утверждённый milestone.

### 1. Отложить сообщение

«Вернуть завтра в 10:00» в меню сообщения создаёт локальную задачу со ссылкой на источник. Отдельная очередь «Отложено» показывает срок, chat и короткий контекст. Это напоминание о входящем сообщении, не scheduled send. Состояния: pending → due → done или rescheduled; wake/restart сверяет просроченные задачи. Локальный клиент может спать или быть выключен; без проверенного OS scheduler/сервера нельзя обещать доставку в срок. Связь: M1 notifications, M3 store, M6 accounts.

### 2. Жду ответа

После своего вопроса выбрать «Жду ответ до пятницы». Храним исходное сообщение, нужного собеседника/ветку, срок и кандидатов ответа. Входящее «ок» или новая реплика в группе не равны решению задачи: появление релевантного сообщения предлагает «Похоже, ответили. Закрыть?», а статус done подтверждает человек. Повторные/старые updates не должны заново уведомлять. Связь: M1/M2/M3/M6. [Эскиз состояний](examples/fork-features/follow_up.dart.example) общий с snooze.

### 3. Общая лента выбранных каналов

Выбрать пять каналов → читать общую временную ленту с явно видимым источником. Хранить позицию для каждого источника и отдельный cursor общей ленты; source read state не менять до реального просмотра. Stable tie-breaker при одинаковой дате и довставка старого поста не должны прыгать под рукой. Дедуп: сначала точная идентичность исходного forward при доступном origin, затем осторожное группирование контентных дублей с «показать все источники». Совпавший URL не доказывает одинаковый пост; edits и media albums учитываются отдельно. Удалённый/private source может стать недоступен. Это новое локальное представление поверх M2/M6, не серверный канал.

### 4. Workspace presets

«Работа» восстанавливает выбранные tabs/panes, локальные папки, фильтры и активный account; «Личное» — другую конфигурацию. База tabs/split/layout restore уже есть в roadmap. Preset хранит ссылки на scope, а не копии авторизации. Перед восстановлением показывать недоступные аккаунты/чаты; не переносить текст drafts между аккаунтами. Не менять системные уведомления скрытым побочным эффектом preset. События: PresetSaved, Activated, PartiallyRestored; связь M1/M6/M7.

### 5. Личные заметки и коллекции

Сообщение → «В коллекцию: Ремонт» → частная заметка «Проверить размер». Храним ссылку, tags и заметку; локальный snapshot текста/медиа только по явному выбору. Открытие проверяет доступ к исходнику, при потере доступа остаётся tombstone и собственная заметка. Это не server pin и не тот же Saved Messages с серверными tags, уже указанный в parity. Не удалять оригинал при удалении записи коллекции. Связь M2/M3/M6; [эскиз](examples/fork-features/collections.dart.example).

### 6. Поиск по OCR, голосовым и документам

Запрос «счёт 154» находит текст на картинке или страницу документа; запрос по voice открывает нужный фрагмент при наличии реальных временных сегментов. Результат помечен происхождением: OCR / transcript / document extraction, языком, доступным контекстом. На экране видно «проиндексировано 320 из 500 доступных файлов», очередь и ошибки. Нельзя писать «ничего нет» при частичном покрытии. Локальный index не умеет искать по всем сообщениям Telegram, которых нет в inventory.

Индексировать асинхронно, с квотой, версией модели и content revision. Edit/delete инвалидируют результаты и выполняющиеся старые задачи. PDF, изображения и голосовые могут требовать скачивания; unavailable — отдельный статус. Внешнему OCR/ASR передаются чувствительные данные только по отдельному выбору; local mode и cloud mode различимы. Не предполагаем, что TDLib умеет server search по произвольному OCR или возвращает word timestamps. Связь M2/M3/M4/M5; [эскиз](examples/fork-features/search_index.dart.example).

### 7. Голосовые как рабочий материал

Очередь прослушивания из нескольких чатов, bookmarks «здесь дедлайн», transcript рядом с waveform, клик по подтверждённому timestamp → seek. Различать playback queue и очередь распознавания. Состояния записи: доступна/скачивается/недоступна; ASR: queued/running/partial/ready/failed. При отсутствии timestamps транскрипт остаётся обычным текстом. Таймкод нельзя вычислить пропорционально числу букв и выдать за точный. RecognizeSpeech из parity уже реализован; timestamps/queue/bookmarks — надстройка. Связь M2/M4/M9.

### 8. Undo send delay и account guard

После Send на несколько секунд показать «Отправка через 5 с · Отменить», явно сохраняя получателя и account. До конца локального grace period сообщение ещё не отправлено; после отправки Undo не обещает отзыв. Переключение tab/account не должно менять captured recipient. Для «рабочее → личное» или похожих имён возможна точечная проверка адресата, а не постоянная модалка всем. Состояния: staged → cancelled / submitting → acknowledged / failed; restart/offline policy нужно выбрать отдельно. Не подменять этим уже существующую server schedule и не предполагать idempotency без подтверждённого TDLib контракта. Связь M1/M2/M6.

### 9. История переходов как в браузере

Предлагаемые Back/Forward возвращают из поиска, reply chain, comments и другого чата на точную позицию. Для восстановления самого поискового экрана нужно хранить query/filters отдельно: текущий эскиз ViewAnchor хранит только позицию сообщения. Храним account/chat/thread, anchor message и offset относительно viewport, pane отдельно. После Back новый переход обрезает forward-ветку. Не писать каждый scroll как отдельный visit; не переносить cursor при неудачной загрузке. Для удалённого сообщения показать причину и предложить доступный соседний anchor. Связь с готовыми tabs/split и M2; [эскиз](examples/fork-features/navigation.dart.example). Inugram reply stack — проверенный меньший механизм, не доказательство полной такой history.

### 10. Несколько черновиков одного чата

Сохранить «Ответ клиенту», начать «Пост с 4 фото», вернуться к первому. Черновик хранит text/entities, reply, файлы и edits, caption, album order, preview и send options; scope включает account и ветку. Сворачивание attachment composer не очищает выбор и не отправляет его. Локальные ревизии защищают от позднего autosave и от удаления новой версии после acknowledgement старой.

Только активный draft может иметь выбранную пользователем cloud-проекцию. Если серверный draft обновился на другом устройстве, предложить сохранить отдельную локальную версию; не молча перетирать её. Пути временных файлов не вечны: нужны управляемые копии/permissions, квота, очистка и шифрование. Inugram minimize ограничен живым photo alert; несколько durable drafts — наша надстройка. Связь M1/M2/M3/M4; [эскиз](examples/fork-features/drafts.dart.example).

### 11. Что изменилось после моего чтения

Показывать «Изменено после просмотра» с diff последней действительно увиденной версии к текущей. Read receipt не равен сохранённому локальному snapshot и в ghost mode может вообще не отправляться. Нужна запись LocalVersionSeen(account/chat/thread/message, content revision, time), обновляемая по явному просмотру; пользователь решает, когда принять новую версию как seen baseline. Если предыдущей версии нет, честно показывать «Ранее не сохранено», а не строить diff из admin log, доступного не всем. Лимит хранения, медиа/подписи, entities, Unicode и удаление аккаунта входят в политику M3. Это уточнение существующей edit history, не новая обещанная серверная функция.

## Собственные эскизы кода

В [examples/fork-features](examples/fork-features/) лежат пять содержательных Dart-эскизов и общая модель [scope](examples/fork-features/scope.dart.example). Они написаны заново, **не интегрированы и не компилировались/тестировались**. Расширение `.dart.example` намеренно исключает их из продуктовых Dart sources. Это демонстрация состояния и событий, не предложение готовых API/классов из текущего репозитория.

| Файл | Что иллюстрирует | Чего ещё нет |
|---|---|---|
| [navigation](examples/fork-features/navigation.dart.example) | Курсор Back/Forward, обрезание ветки, commit после загрузки | Async token/cancellation, адаптер timeline/pane, persistence, query/filters поискового экрана |
| [drafts](examples/fork-features/drafts.dart.example) | Несколько drafts на conversation, revision guard, acknowledgement конкретной ревизии | Durable store, rich entities/options, cloud conflict UI, file lifecycle |
| [follow_up](examples/fork-features/follow_up.dart.example) | Snooze/жду ответа, due и candidate как разные состояния | Scheduler, дедуп доставки, правила релевантности, сохранение и явное close action |
| [collections](examples/fork-features/collections.dart.example) | Локальные ссылки/заметки, account scope, unlink | Storage/search/order, проверка source access, snapshot policy |
| [search_index](examples/fork-features/search_index.dart.example) | Версионирование extract results, инвалидирование, covered/tracked | OCR/ASR/PDF engines, inventory всех целей, FTS и backend |

## Ограничения для будущей реализации

- Всегда scoped account + chat + тип/ID thread + message; message ID не глобален. В эскизе thread упрощён до nullable ID: продуктовый адаптер обязан различать forum topic, comments, saved messages topic и прочие пространства.
- Локальный таймер не живёт гарантированно, когда клиент выключен/спит. Server scheduled send, OS notification и наша напоминалка — разные механизмы.
- Исходное сообщение может быть удалено, недоступно аккаунту или ещё не скачано; history/collections/feed/search должны иметь состояние unavailable без бесконечных retries.
- Наличие API в Android patchset не доказывает соответствующую функцию TDLib в закреплённой версии Mollygram. Сначала проверить schema/контракт, затем писать адаптер. Имена в собственных эскизах — только наши типы.
- Поиск, snapshot, ASR и коллекции создают производные данные: учитывать logout, clear cache, edit/delete, retention, шифрование и согласие на внешнюю обработку. Не считать Saved Messages приватной локальной БД.
- Bulk actions нужны per-item/batch result, rate-limit/backoff, resume и сохранение failed selection; снять UI cap недостаточно. Точные лимиты API нельзя выводить только из чужого patch.
- Изучение механизмов не означает разрешение копировать произвольные файлы. Код эскизов собственный; при прямом переносе отдельно проверять LICENSE нужного файла и upstream. Не распространять blanket-вывод старого research о юридической совместимости на все форки.

## Предварительный shortlist без сроков

1. **Дешёвые надстройки поверх существующего UI:** original forwarded date, sender search из меню, retain selection after forward, quick save, only matches, spoiler preview, copy frame. Сперва проверить, что не появилось в текущей M1–M9 работе.
2. **Повседневный контекст:** многозвенный reply/back, preview t.me, сворачиваемые вложения; затем полноценные history и draft shelf с durable state.
3. **Личная организация:** snooze, жду ответа, коллекции с заметками. Требуют честной политики reminders и локального хранения.
4. **Поиск и voice:** прозрачное покрытие OCR/ASR/doc index, реальные timestamps и очередь. Наиболее полезно после выбора engines, квот и политики данных.
5. **Отдельное исследование:** общая лента и workspace presets. Нужны ответы о read semantics, дедупе, масштабе и нескольких аккаунтах.

Это список кандидатов для выбора; он не меняет порядок M1–M9 и не содержит обещаний сроков. Любая принятая задача должна получить собственный критерий готовности в действующем backlog.
