# Module Hub · 0.26

15 Lua-модулей / 15 Lua modules.

Скопируйте папку `modules` в доступное место и выберите её в студии; по умолчанию используется `Download/modules`. При запуске студия спросит разрешение на загрузку. Открыть модули: «Инструменты → Module Hub». Модули являются исполняемым Lua-кодом и имеют полные права студии; загружайте только доверенные файлы.

Copy this folder to an accessible location and select it in the studio; the default is `Download/modules`. Approve trusted modules at startup, then choose Tools → Module Hub. Modules execute Lua with the studio's privileges; load only trusted files.

Интерфейс / API: `return { name = '...', run = function(ctx) ... end }`. См. основной README / See the main README for details.
