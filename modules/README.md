# Module Hub

Скопируйте папку `modules` целиком в `Download/modules`. При запуске студия спросит разрешение на загрузку. Открыть модули: «Инструменты → Module Hub». Модули являются исполняемым Lua-кодом и имеют полные права студии; загружайте только доверенные файлы.

Copy this entire folder to `Download/modules`. Approve trusted modules at startup, then choose Tools → Module Hub. Modules execute Lua with the studio's privileges; load only trusted files.

Интерфейс / API: `return { name = '...', run = function(ctx) ... end }`. См. основной README / See the main README for details.
