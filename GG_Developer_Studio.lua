-- GG Developer Studio 0.14 — мастер проектов и генератор меню для GameGuardian
-- Один файл. Проекты и готовые скрипты сохраняются на устройство.
-- Меню, шаблоны, проектные инструменты, диагностика и сборка.

if type(gg) ~= 'table' then error('Запустите файл из GameGuardian') end

-- Проверка обновлений из публичного репозитория GitHub.
-- Размещайте manifest.json и GG_Developer_Studio.lua в корне ветки main.
local RELEASE = '0.14'
local UPDATE_ROOT = 'https://raw.githubusercontent.com/nearzvx/GGDevStudio/main'
local download_dir = (gg.EXT_STORAGE or '/sdcard') .. '/Download'

local function update_alert(message)
    gg.alert('GG Developer Studio\n\n' .. tostring(message))
end
local function numeric_version(v)
    if type(v) ~= 'string' or not v:match('^%d+%.%d+[%d%.]*$') or v:find('%.%.') or v:sub(-1) == '.' then return nil end
    local parts = {}
    for number in v:gmatch('%d+') do
        if #number > 6 then return nil end
        parts[#parts + 1] = tonumber(number)
    end
    if #parts < 2 or #parts > 4 then return nil end
    return parts
end
local function newer_than(a, b)
    local x, y = numeric_version(a), numeric_version(b)
    if not x or not y then return nil end
    for i = 1, math.max(#x, #y) do
        if (x[i] or 0) ~= (y[i] or 0) then return (x[i] or 0) > (y[i] or 0) end
    end
    return false
end
local function request(url)
    if type(gg.makeRequest) ~= 'function' then return nil, 'gg.makeRequest недоступна.' end
    local ok, response = pcall(gg.makeRequest, url, {['Cache-Control']='no-cache'})
    if not ok then return nil, tostring(response) end
    if type(response) ~= 'table' then return nil, 'Сервер не ответил.' end
    if tonumber(response.code) ~= 200 or type(response.content) ~= 'string' then
        return nil, 'HTTP ' .. tostring(response.code or '?')
    end
    return response.content
end
local function check_update()
    local manifest, err = request(UPDATE_ROOT .. '/manifest.json')
    if not manifest then update_alert('Не удалось проверить обновления на GitHub: ' .. tostring(err) .. '. Проверьте подключение и публикацию файлов в ветке main.'); return false end
    local latest = manifest:match('^%s*{%s*"version"%s*:%s*"([%d%.]+)"%s*}%s*$')
    local newer = latest and newer_than(latest, RELEASE)
    if newer == nil then update_alert('Некорректный manifest.json в репозитории.'); return false end
    if not newer then return true end
    update_alert('Доступно обновление: ' .. latest .. '. Установлена версия: ' .. RELEASE .. '. Сейчас начнётся загрузка.')
    local code, download_err = request(UPDATE_ROOT .. '/GG_Developer_Studio.lua')
    if not code then update_alert('Не удалось скачать обновление: ' .. tostring(download_err)); return false end
    if #code > 2097152 or code:sub(1, 22) ~= '-- GG Developer Studio' then update_alert('Неверный файл обновления.'); return false end
    local found = code:match("local RELEASE = '([%d%.]+)'")
    if found ~= latest then update_alert('Версия файла и manifest.json не совпадают. Попробуйте позже.'); return false end
    local filename = download_dir .. '/GG_Developer_Studio_update_' .. latest
    local path
    for i = 0, 99 do
        local candidate = filename .. (i == 0 and '' or ('_' .. i)) .. '.lua'
        local existing = io.open(candidate, 'rb')
        if not existing then path = candidate; break end
        existing:close()
    end
    if not path then update_alert('Не удалось найти свободное имя файла в Download.'); return false end
    local file, write_err = io.open(path, 'wb')
    if not file then update_alert('Не удалось сохранить файл: ' .. tostring(write_err)); return false end
    local ok, err_write = file:write(code)
    local closed, err_close = file:close()
    if not ok or not closed then update_alert('Ошибка записи: ' .. tostring(err_write or err_close)); return false end
    update_alert('Обновление сохранено: ' .. path .. '\n\nЗапустите новый файл в GameGuardian. Текущая версия закроется.')
    return false
end
if not check_update() then return end

local VERSION = '0.14'
-- Download уже существует на устройстве, поэтому os.execute не нужен.
local root = (gg.EXT_STORAGE or '/sdcard') .. '/Download'
local project, project_id

local function notify(text) gg.alert(tostring(text)) end
local function valid_id(id)
    return type(id) == 'string' and #id > 0 and #id <= 48 and id:match('^[%w_-]+$') ~= nil
end
local function hex(s)
    return (tostring(s):gsub('.', function(c) return string.format('%02X', string.byte(c)) end))
end
local function unhex(s)
    if #s % 2 ~= 0 or s:find('[^0-9A-Fa-f]') then return nil end
    return (s:gsub('%x%x', function(h) return string.char(tonumber(h, 16)) end))
end
local function write_file(path, contents)
    local f, err = io.open(path, 'w')
    if not f then return nil, err end
    local ok, write_err = f:write(contents)
    local close_ok, close_err = f:close()
    if not ok then return nil, write_err end
    if not close_ok then return nil, close_err end
    return true
end
local function path_for(id) return root .. '/' .. id .. '.ggds' end
local saved_snapshot = nil
local function project_data(pr)
    if not pr then return nil end
    local lines = {'GGDS1', hex(pr.title), hex(pr.version)}
    for _, item in ipairs(pr.items) do
        lines[#lines + 1] = item.kind .. '|' .. hex(item.title) .. '|' .. hex(item.content)
    end
    return table.concat(lines, '\n') .. '\n'
end
local function confirm_discard()
    if not project then return true end
    if saved_snapshot ~= nil and saved_snapshot == project_data(project) then return true end
    return gg.choice({'Остаться', 'Продолжить без сохранения'}, nil, 'В проекте есть несохранённые изменения. Продолжить?') == 2
end
local function save_project()
    if not project then notify('Сначала создайте или откройте проект.') return end
    local data = project_data(project)
    local ok, err = write_file(path_for(project_id), data)
    if ok then saved_snapshot = data end
    notify(ok and ('Проект сохранён: ' .. path_for(project_id)) or ('Ошибка сохранения: ' .. tostring(err)))
end
local function new_project()
    if not confirm_discard() then return end
    local p = gg.prompt({'ID проекта (латинские буквы, цифры, _ или -)', 'Название', 'Версия'}, {'my_project', 'Мой проект', '1.0'}, {'text', 'text', 'text'})
    if not p then return end
    if not valid_id(p[1]) then notify('Некорректный ID проекта.') return end
    local existing = io.open(path_for(p[1]), 'r')
    if existing then
        existing:close()
        if gg.choice({'Открыть существующий проект вручную', 'Создать новый и перезаписать при сохранении'}, nil, 'Проект с таким ID уже существует') ~= 2 then return end
    end
    project_id = p[1]
    project = {title = p[2] ~= '' and p[2] or p[1], version = p[3], items = {}}
    saved_snapshot = nil
    notify('Проект создан. Используйте «Сохранить проект».')
end
local function open_project()
    if not confirm_discard() then return end
    local p = gg.prompt({'ID сохранённого проекта'}, {project_id or 'my_project'}, {'text'})
    if not p then return end
    if not valid_id(p[1]) then notify('Некорректный ID.') return end
    local f, err = io.open(path_for(p[1]), 'r')
    if not f then notify('Не удалось открыть проект: ' .. tostring(err)) return end
    local lines = {}
    for line in f:lines() do lines[#lines + 1] = line end
    f:close()
    if lines[1] ~= 'GGDS1' or not lines[2] or not lines[3] then notify('Неверный формат проекта.') return end
    local title, ver = unhex(lines[2]), unhex(lines[3])
    if not title or not ver then notify('Повреждён заголовок проекта.') return end
    local loaded = {title = title, version = ver, items = {}}
    for i = 4, #lines do
        local kind, a, b = lines[i]:match('^([MSTQICRK])|([%x]*)|([%x]*)$')
        if not kind or not unhex(a) or not unhex(b) then notify('Повреждена строка проекта: ' .. i) return end
        loaded.items[#loaded.items + 1] = {kind = kind, title = unhex(a), content = unhex(b)}
    end
    project_id, project = p[1], loaded
    saved_snapshot = project_data(project)
    notify('Проект открыт: ' .. project.title)
end
local function configure_item(existing)
    local k
    if existing then
        k = ({M=1, T=2, S=3, Q=4, I=5, C=6, R=7, K=8})[existing.kind]
    else
        k = gg.choice({'Сообщение (окно)', 'Короткое уведомление', 'Заготовка функции', 'Поиск числа (просмотр результатов)', 'Запрос текста', 'Подтверждение действия', 'Количество результатов GG', 'Свой Lua-код'}, nil, 'Тип пункта')
    end
    if not k then return nil end
    local kinds = {'M', 'T', 'S', 'Q', 'I', 'C', 'R', 'K'}
    local labels = {'Текст сообщения', 'Текст уведомления', 'Имя функции (латиница, цифры, _)', 'Число и тип через двоеточие, например 100:DWORD', 'Текст запроса', 'Вопрос для подтверждения', 'Заголовок окна результатов', 'Lua-код действия (выполняется в собранном скрипте)'}
    local defaults = {'Привет!', 'Готово!', 'my_action', '100:DWORD', 'Введите значение:', 'Продолжить?', 'Результаты поиска', 'gg.alert("Привет!")'}
    local p = gg.prompt({'Название пункта', labels[k]}, {existing and existing.title or 'Новый пункт', existing and existing.content or defaults[k]}, {'text', 'text'})
    if not p then return nil end
    if p[1] == '' then notify('Название не должно быть пустым.') return nil end
    if k == 3 then
        if not p[2]:match('^[A-Za-z_][A-Za-z0-9_]*$') then notify('Некорректное имя функции.') return nil end
        for _, item in ipairs(project.items) do
            if item ~= existing and item.kind == 'S' and item.content == p[2] then notify('Имя функции уже используется.') return nil end
        end
    elseif k == 8 then
        local compiler = loadstring or load
        if compiler then
            local ok, fn, err = pcall(compiler, 'return function()\n' .. p[2] .. '\nend')
            if not ok or not fn then notify('Ошибка Lua-кода: ' .. tostring(ok and err or fn)) return nil end
        end
    elseif k == 4 then
        local value, typ = p[2]:match('^([^:]+):([A-Za-z]+)$')
        if not value or not tonumber(value) or not ({DWORD=true, FLOAT=true, DOUBLE=true, QWORD=true, WORD=true, BYTE=true})[typ] then
            notify('Пример: 100:DWORD или 1.5:FLOAT. Типы: DWORD, FLOAT, DOUBLE, QWORD, WORD, BYTE.') return nil
        end
    end
    return {kind = kinds[k], title = p[1], content = p[2]}
end
local function add_item()
    if not project then notify('Сначала создайте или откройте проект.') return end
    local item = configure_item()
    if item then project.items[#project.items + 1] = item end
end
local function manage_items()
    if not project then notify('Сначала откройте проект.') return end
    if #project.items == 0 then notify('Пунктов пока нет.') return end
    local choices = {}
    local names = {M='окно', T='уведомление', S='функция', Q='поиск', I='ввод', C='подтверждение', R='результаты', K='Lua-код'}
    for i, item in ipairs(project.items) do choices[i] = i .. '. ' .. item.title .. ' [' .. (names[item.kind] or '?') .. ']' end
    local i = gg.choice(choices, nil, 'Выберите пункт')
    if not i then return end
    local action = gg.choice({'Изменить', 'Переместить вверх', 'Переместить вниз', 'Удалить', 'Дублировать'}, nil, choices[i])
    if action == 1 then
        local item = configure_item(project.items[i])
        if item then project.items[i] = item end
    elseif action == 2 and i > 1 then project.items[i], project.items[i-1] = project.items[i-1], project.items[i]
    elseif action == 3 and i < #project.items then project.items[i], project.items[i+1] = project.items[i+1], project.items[i]
    elseif action == 4 and gg.choice({'Нет', 'Да'}, nil, 'Удалить пункт?') == 2 then table.remove(project.items, i)
    elseif action == 5 then
        local item = project.items[i]
        if item.kind == 'S' then notify('У заготовок должны быть разные имена. Создайте новую заготовку вручную.') return end
        table.insert(project.items, i + 1, {kind=item.kind, title=item.title .. ' (копия)', content=item.content})
        notify('Пункт скопирован. Сохраните проект.')
    end
end
local function project_settings()
    if not project then notify('Сначала откройте проект.') return end
    local p = gg.prompt({'Название проекта', 'Версия'}, {project.title, project.version}, {'text', 'text'})
    if not p then return end
    if p[1] == '' then notify('Название не должно быть пустым.') return end
    project.title, project.version = p[1], p[2]
end
local function preview()
    if not project then notify('Сначала откройте проект.') return end
    local labels = {}
    for i, item in ipairs(project.items) do labels[i] = item.title end
    labels[#labels + 1] = 'Выход'
    local i = gg.choice(labels, nil, 'ПРЕДПРОСМОТР: ' .. project.title)
    if i and project.items[i] then
        local item = project.items[i]
        notify('Тип: ' .. item.kind .. '\nСодержимое: ' .. item.content .. '\n\nПредпросмотр не выполняет действие.')
    end
end
local function build()
    if not project then notify('Сначала откройте проект.') return end
    if #project.items == 0 then notify('Добавьте хотя бы один пункт меню.') return end
    local outpath = root .. '/' .. project_id .. '_generated.lua'
    local old = io.open(outpath, 'r')
    if old then
        old:close()
        if gg.choice({'Отмена', 'Перезаписать'}, nil, 'Готовый файл уже существует. Ручные изменения будут потеряны!') ~= 2 then return end
    end
    local lines = {'-- Создано в GG Developer Studio ' .. VERSION,
        '-- После повторной сборки ручные изменения в этом файле будут потеряны.',
        "if type(gg) ~= 'table' then error('Запустите скрипт из GameGuardian') end",
        'local actions = {}'}
    for i, item in ipairs(project.items) do
        lines[#lines + 1] = 'actions[' .. i .. '] = function()'
        if item.kind == 'M' then
            lines[#lines + 1] = '    gg.alert(' .. string.format('%q', item.content) .. ')'
        elseif item.kind == 'T' then
            lines[#lines + 1] = '    gg.toast(' .. string.format('%q', item.content) .. ')'
        elseif item.kind == 'K' then
            lines[#lines + 1] = '    -- Пользовательский код; запускается только в готовом скрипте'
            lines[#lines + 1] = item.content
        elseif item.kind == 'I' then
            lines[#lines + 1] = '    local answer = gg.prompt({' .. string.format('%q', item.content) .. "}, {''}, {'text'})"
            lines[#lines + 1] = "    if answer then gg.alert('Введено: ' .. tostring(answer[1])) end"
        elseif item.kind == 'C' then
            lines[#lines + 1] = '    local answer = gg.choice({' .. string.format('%q', 'Нет') .. ', ' .. string.format('%q', 'Да') .. '}, nil, ' .. string.format('%q', item.content) .. ')'
            lines[#lines + 1] = "    if answer == 2 then gg.toast('Подтверждено') elseif answer == 1 then gg.toast('Отменено') end"
        elseif item.kind == 'R' then
            lines[#lines + 1] = '    gg.alert(' .. string.format('%q', item.content .. ': ') .. ' .. tostring(gg.getResultsCount()))'
        elseif item.kind == 'Q' then
            local value, typ = item.content:match('^([^:]+):([A-Za-z]+)$')
            if not value or not tonumber(value) or not ({DWORD=true,FLOAT=true,DOUBLE=true,QWORD=true,WORD=true,BYTE=true})[typ] then
                notify('Некорректный пункт поиска: ' .. item.title) return
            end
            lines[#lines + 1] = "    if gg.choice({'Отмена', 'Искать'}, nil, 'Предыдущие результаты поиска будут очищены.') ~= 2 then return end"
            lines[#lines + 1] = '    gg.clearResults()'
            lines[#lines + 1] = '    local err = gg.searchNumber(' .. string.format('%q', value) .. ', gg.TYPE_' .. typ .. ')'
            lines[#lines + 1] = "    if type(err) == 'string' then gg.alert('Ошибка поиска: ' .. err); return end"
            lines[#lines + 1] = "    gg.alert('Найдено результатов: ' .. tostring(gg.getResultsCount()) .. '. Посмотрите результаты в интерфейсе GG.')"
        else
            lines[#lines + 1] = '    -- TODO: добавьте код действия ' .. item.content
            lines[#lines + 1] = '    gg.alert(' .. string.format('%q', 'Функция ' .. item.content .. ' пока не реализована.') .. ')'
        end
        lines[#lines + 1] = 'end'
    end
    lines[#lines + 1] = 'local labels = {'
    for _, item in ipairs(project.items) do lines[#lines + 1] = '    ' .. string.format('%q', item.title) .. ',' end
    lines[#lines + 1] = "    'Выход'"
    lines[#lines + 1] = '}'
    lines[#lines + 1] = 'while true do'
    lines[#lines + 1] = '    local choice = gg.choice(labels, nil, ' .. string.format('%q', project.title .. ' — ' .. project.version) .. ')'
    lines[#lines + 1] = '    if choice == nil or choice == #labels then break end'
    lines[#lines + 1] = '    local ok, err = pcall(actions[choice])'
    lines[#lines + 1] = "    if not ok then gg.alert('Ошибка действия: ' .. tostring(err)) end"
    lines[#lines + 1] = 'end'
    local source = table.concat(lines, '\n') .. '\n'
    local compiler = loadstring or load
    if compiler then
        local passed, compiled, parse_error = pcall(compiler, source)
        if not passed or not compiled then notify('Ошибка синтаксиса итогового файла: ' .. tostring(passed and parse_error or compiled)) return end
    end
    local ok, err = write_file(outpath, source)
    notify(ok and ('Скрипт создан: ' .. outpath) or ('Ошибка сборки: ' .. tostring(err)))
end

local function diagnostics()
    local features = {'choice', 'prompt', 'alert', 'toast', 'searchNumber', 'getResultsCount', 'clearResults', 'copyText', 'getTargetInfo'}
    local lines = {'GG Developer Studio ' .. VERSION, 'Папка: ' .. root, ''}
    for _, name in ipairs(features) do lines[#lines + 1] = 'gg.' .. name .. ': ' .. (type(gg[name]) == 'function' and 'доступно' or 'нет') end
    if type(gg.getTargetInfo) == 'function' then
        local ok, info = pcall(gg.getTargetInfo)
        if ok and type(info) == 'table' then
            lines[#lines + 1] = ''
            lines[#lines + 1] = 'Целевой пакет: ' .. tostring(info.packageName or 'неизвестен')
            lines[#lines + 1] = 'Версия: ' .. tostring(info.versionName or 'неизвестна')
        else lines[#lines + 1] = 'Целевой процесс не выбран или информация недоступна.' end
    end
    local probe = root .. '/ggds_write_test.tmp'
    local ok, err = write_file(probe, 'GGDS test')
    if ok then
        lines[#lines + 1] = 'Проверка записи: успешно (тестовый файл: ggds_write_test.tmp)'
    else lines[#lines + 1] = 'Проверка записи: ошибка — ' .. tostring(err) end
    notify(table.concat(lines, '\n'))
end
local function project_report()
    if not project then notify('Сначала откройте проект.') return end
    local names = {M='Окно', T='Уведомление', S='Заготовка', Q='Поиск', I='Ввод', C='Подтверждение', R='Результаты', K='Lua-код'}
    local lines = {'GG Developer Studio ' .. VERSION, 'Проект: ' .. project.title, 'ID: ' .. project_id, 'Версия: ' .. project.version, 'Пунктов: ' .. #project.items, ''}
    for i, item in ipairs(project.items) do lines[#lines + 1] = i .. '. [' .. (names[item.kind] or '?') .. '] ' .. item.title .. ' — ' .. item.content end
    local text = table.concat(lines, '\n')
    local choice = gg.choice({'Показать отчёт', 'Сохранить отчёт в TXT', 'Скопировать отчёт'}, nil, 'Отчёт о проекте')
    if choice == 1 then notify(text)
    elseif choice == 2 then
        local path = root .. '/' .. project_id .. '_report.txt'
        local f = io.open(path, 'r')
        if f then f:close(); if gg.choice({'Отмена', 'Перезаписать'}, nil, 'Отчёт уже существует.') ~= 2 then return end end
        local ok, err = write_file(path, text .. '\n')
        notify(ok and ('Отчёт сохранён: ' .. path) or ('Ошибка: ' .. tostring(err)))
    elseif choice == 3 then
        if type(gg.copyText) ~= 'function' then notify('gg.copyText недоступна в этой версии GG.') return end
        local ok, err = pcall(gg.copyText, text)
        notify(ok and 'Отчёт скопирован.' or ('Ошибка: ' .. tostring(err)))
    end
end
local function backup_project()
    if not project then notify('Сначала откройте проект.') return end
    local lines = {'GGDS1', hex(project.title), hex(project.version)}
    for _, item in ipairs(project.items) do lines[#lines + 1] = item.kind .. '|' .. hex(item.title) .. '|' .. hex(item.content) end
    local p = gg.prompt({'ID резервной копии (латиница, цифры, _ или -)'}, {project_id .. '_backup'}, {'text'})
    if not p then return end
    if not valid_id(p[1]) or p[1] == project_id then notify('Некорректный ID копии или ID совпадает с текущим проектом.') return end
    local path = path_for(p[1])
    local old = io.open(path, 'r')
    if old then old:close(); if gg.choice({'Отмена', 'Перезаписать'}, nil, 'Такой проект уже существует.') ~= 2 then return end end
    local ok, err = write_file(path, table.concat(lines, '\n') .. '\n')
    notify(ok and ('Копия сохранена: ' .. path .. '\nЕё можно открыть по ID ' .. p[1]) or ('Ошибка: ' .. tostring(err)))
end
local function import_lua_action()
    if not project then notify('Сначала откройте проект.') return end
    local p = gg.prompt({'Название пункта', 'Полный путь к Lua-файлу с кодом действия'}, {'Моё действие', root .. '/action.lua'}, {'text', 'text'})
    if not p then return end
    if p[1] == '' or p[2] == '' then notify('Укажите название и путь.') return end
    local f, err = io.open(p[2], 'r')
    if not f then notify('Не удалось открыть файл: ' .. tostring(err)) return end
    local data = f:read(262145)
    f:close()
    if not data or #data > 262144 then notify('Пустой файл или размер больше 256 КБ.') return end
    local compiler = loadstring or load
    if compiler then
        local ok, fn, error_text = pcall(compiler, 'return function()\n' .. data .. '\nend')
        if not ok or not fn then notify('Ошибка Lua-кода: ' .. tostring(ok and error_text or fn)) return end
    end
    project.items[#project.items + 1] = {kind='K', title=p[1], content=data}
    notify('Код добавлен в проект. Он не выполнялся. Не забудьте сохранить проект.')
end
local TEMPLATE_LIBRARY = {
{name = [====[Интерфейс]====], items = {
{title = [====[Окно сообщения]====], code = [====[gg.alert('Привет!')]====]},
{title = [====[Короткое уведомление]====], code = [====[gg.toast('Действие выполнено')]====]},
{title = [====[Выбор одного пункта]====], code = [====[local c = gg.choice({'Первый', 'Второй'}, nil, 'Выберите пункт')
if not c then return end
gg.alert('Вы выбрали: ' .. c)]====]},
{title = [====[Выбор нескольких пунктов]====], code = [====[local c = gg.multiChoice({'Первый', 'Второй'}, nil, 'Выберите пункты')
if not c then return end
gg.alert('Первый: ' .. tostring(c[1]) .. ', второй: ' .. tostring(c[2]))]====]},
{title = [====[Подтверждение]====], code = [====[local c = gg.choice({'Отмена', 'Продолжить'}, nil, 'Подтвердить действие?')
if c ~= 2 then return end
gg.toast('Подтверждено')]====]},
{title = [====[Ввод строки]====], code = [====[local p = gg.prompt({'Введите текст'}, {''}, {'text'})
if not p then return end
gg.alert('Текст: ' .. tostring(p[1]))]====]},
{title = [====[Ввод числа]====], code = [====[local p = gg.prompt({'Введите число'}, {'0'}, {'number'})
if not p then return end
local n = tonumber(p[1])
if not n then gg.alert('Некорректное число') return end
gg.alert('Число: ' .. tostring(n))]====]},
{title = [====[Ввод двух значений]====], code = [====[local p = gg.prompt({'Имя', 'Значение'}, {'', '0'}, {'text', 'number'})
if not p then return end
gg.alert(tostring(p[1]) .. ': ' .. tostring(p[2]))]====]},
{title = [====[Меню с циклом]====], code = [====[while true do
  local c = gg.choice({'Показать сообщение', 'Выход'}, nil, 'Подменю')
  if not c or c == 2 then break end
  gg.alert('Пример действия')
end]====]},
{title = [====[Задержка в миллисекундах]====], code = [====[gg.toast('Ожидание...')
gg.sleep(1000)
gg.toast('Готово')]====]},
}},
{name = [====[GameGuardian]====], items = {
{title = [====[Сведения о процессе]====], code = [====[local t = gg.getTargetInfo()
if not t then gg.alert('Выберите процесс в GG') return end
gg.alert('Пакет: ' .. tostring(t.packageName or '?') .. '\nВерсия: ' .. tostring(t.versionName or '?'))]====]},
{title = [====[Количество результатов]====], code = [====[gg.alert('Результатов: ' .. tostring(gg.getResultsCount()))]====]},
{title = [====[Проверка наличия результатов]====], code = [====[local n = gg.getResultsCount()
if n == 0 then gg.alert('Результатов нет') return end
gg.alert('Найдено: ' .. n)]====]},
{title = [====[Просмотр первых 10 результатов]====], code = [====[local n = gg.getResultsCount()
if n == 0 then gg.alert('Результатов нет') return end
local rows = gg.getResults(math.min(n, 10))
local out = {'Всего: ' .. n}
for i, r in ipairs(rows) do out[#out + 1] = i .. '. ' .. tostring(r.address) .. ': ' .. tostring(r.value) end
gg.alert(table.concat(out, '\n'))]====]},
{title = [====[Поиск DWORD с подтверждением]====], code = [====[local p = gg.prompt({'Число для поиска DWORD'}, {'100'}, {'number'})
if not p then return end
if gg.choice({'Отмена', 'Очистить и искать'}, nil, 'Очистить прежние результаты?') ~= 2 then return end
gg.clearResults()
local err = gg.searchNumber(tostring(p[1]), gg.TYPE_DWORD)
if type(err) == 'string' then gg.alert(err) return end
gg.alert('Результатов: ' .. gg.getResultsCount())]====]},
{title = [====[Поиск FLOAT с подтверждением]====], code = [====[local p = gg.prompt({'Число для поиска FLOAT'}, {'1.5'}, {'number'})
if not p then return end
if gg.choice({'Отмена', 'Очистить и искать'}, nil, 'Очистить прежние результаты?') ~= 2 then return end
gg.clearResults()
local err = gg.searchNumber(tostring(p[1]), gg.TYPE_FLOAT)
if type(err) == 'string' then gg.alert(err) return end
gg.alert('Результатов: ' .. gg.getResultsCount())]====]},
{title = [====[Очистка результатов с подтверждением]====], code = [====[if gg.choice({'Отмена', 'Очистить'}, nil, 'Очистить результаты поиска?') == 2 then gg.clearResults(); gg.toast('Очищено') end]====]},
{title = [====[Проверка доступности API]====], code = [====[local names = {'searchNumber', 'getResults', 'getResultsCount', 'toast', 'copyText'}
local out = {}
for _, name in ipairs(names) do out[#out + 1] = name .. ': ' .. tostring(type(gg[name]) == 'function') end
gg.alert(table.concat(out, '\n'))]====]},
{title = [====[Копирование текста]====], code = [====[if type(gg.copyText) ~= 'function' then gg.alert('Копирование недоступно') return end
local p = gg.prompt({'Текст для копирования'}, {''}, {'text'})
if p then gg.copyText(tostring(p[1])); gg.toast('Скопировано') end]====]},
{title = [====[Проверка выбранного процесса]====], code = [====[local t = gg.getTargetInfo()
if not t or not t.packageName then gg.alert('Выберите процесс в GameGuardian') return end
gg.toast('Выбран: ' .. tostring(t.packageName))]====]},
}},
{name = [====[Строки]====], items = {
{title = [====[Обрезать пробелы]====], code = [====[local text = '  пример  '
local cleaned = text:match('^%s*(.-)%s*$')
gg.alert('[' .. cleaned .. ']')]====]},
{title = [====[Найти подстроку без шаблонов]====], code = [====[local text, needle = 'apple banana', 'banana'
local pos = string.find(text, needle, 1, true)
gg.alert(pos and ('Позиция: ' .. pos) or 'Не найдено')]====]},
{title = [====[Заменить текст]====], code = [====[local text = 'red red blue'
local replaced = string.gsub(text, 'red', 'green')
gg.alert(replaced)]====]},
{title = [====[Разделить строки]====], code = [====[local text = 'один,два,три'
local parts = {}
for part in (text .. ','):gmatch('(.-),') do parts[#parts + 1] = part end
gg.alert(table.concat(parts, '\n'))]====]},
{title = [====[Соединить элементы]====], code = [====[local items = {'один', 'два', 'три'}
gg.alert(table.concat(items, ' | '))]====]},
{title = [====[Проверить начало строки]====], code = [====[local text, prefix = 'GG Developer', 'GG'
gg.alert(tostring(text:sub(1, #prefix) == prefix))]====]},
{title = [====[Проверить окончание строки]====], code = [====[local text, suffix = 'script.lua', '.lua'
gg.alert(tostring(suffix == '' or text:sub(-#suffix) == suffix))]====]},
{title = [====[Извлечь расширение файла]====], code = [====[local filename = 'example.lua'
local extension = filename:match('%.([^%.]+)$')
gg.alert('Расширение: ' .. tostring(extension or 'нет'))]====]},
{title = [====[Форматировать число]====], code = [====[local value = 12.3456
gg.alert(string.format('%.2f', value))]====]},
{title = [====[Длина в байтах]====], code = [====[local text = 'Привет'
gg.alert('Байт UTF-8: ' .. #text .. ' (это не число символов)')]====]},
}},
{name = [====[Таблицы]====], items = {
{title = [====[Перебор списка]====], code = [====[local items = {'один', 'два', 'три'}
for i, v in ipairs(items) do print(i, v) end
gg.toast('Список выведен в журнал')]====]},
{title = [====[Перебор словаря]====], code = [====[local data = {name = 'Demo', version = '1.0'}
for k, v in pairs(data) do print(k, v) end
gg.toast('Данные выведены в журнал')]====]},
{title = [====[Добавить и удалить элемент]====], code = [====[local items = {'A', 'B'}
items[#items + 1] = 'C'
table.remove(items, 1)
gg.alert(table.concat(items, ', '))]====]},
{title = [====[Копия списка]====], code = [====[local original = {1, 2, 3}
local copy = {}
for i, value in ipairs(original) do copy[i] = value end
gg.alert('Элементов в копии: ' .. #copy)]====]},
{title = [====[Сортировка чисел]====], code = [====[local items = {10, 2, 30, 1}
table.sort(items, function(a, b) return a < b end)
gg.alert(table.concat(items, ', '))]====]},
{title = [====[Сортировка строк]====], code = [====[local items = {'beta', 'alpha', 'gamma'}
table.sort(items)
gg.alert(table.concat(items, ', '))]====]},
{title = [====[Поиск элемента в списке]====], code = [====[local items, target = {'A', 'B', 'C'}, 'B'
local index
for i, value in ipairs(items) do if value == target then index = i; break end end
gg.alert(index and ('Индекс: ' .. index) or 'Не найдено')]====]},
{title = [====[Подсчёт ключей]====], code = [====[local data, count = {a = 1, b = 2}, 0
for _ in pairs(data) do count = count + 1 end
gg.alert('Ключей: ' .. count)]====]},
{title = [====[Удалить повторы]====], code = [====[local input, seen, output = {'A','B','A'}, {}, {}
for _, v in ipairs(input) do if not seen[v] then seen[v] = true; output[#output + 1] = v end end
gg.alert(table.concat(output, ', '))]====]},
{title = [====[Фильтр чисел]====], code = [====[local input, output = {1, 2, 3, 4}, {}
for _, v in ipairs(input) do if v % 2 == 0 then output[#output + 1] = v end end
gg.alert(table.concat(output, ', '))]====]},
}},
{name = [====[Математика]====], items = {
{title = [====[Ограничить диапазон]====], code = [====[local value, min, max = 120, 0, 100
local result = math.max(min, math.min(max, value))
gg.alert(tostring(result))]====]},
{title = [====[Вычислить процент]====], code = [====[local part, whole = 25, 200
if whole == 0 then gg.alert('Деление на ноль') return end
gg.alert(string.format('%.2f%%', part / whole * 100))]====]},
{title = [====[Безопасное деление]====], code = [====[local a, b = 10, 2
if b == 0 then gg.alert('Деление на ноль') return end
gg.alert(tostring(a / b))]====]},
{title = [====[Округлить до целого]====], code = [====[local n = 12.7
local rounded = n >= 0 and math.floor(n + 0.5) or math.ceil(n - 0.5)
gg.alert(tostring(rounded))]====]},
{title = [====[Минимум и максимум]====], code = [====[local items = {5, 2, 9}
local min, max = items[1], items[1]
for _, n in ipairs(items) do min = math.min(min, n); max = math.max(max, n) end
gg.alert('Мин: ' .. min .. ', макс: ' .. max)]====]},
{title = [====[Сумма списка]====], code = [====[local sum = 0
for _, n in ipairs({1, 2, 3}) do sum = sum + n end
gg.alert('Сумма: ' .. sum)]====]},
{title = [====[Среднее значение]====], code = [====[local items = {2, 4, 6}
if #items == 0 then gg.alert('Список пуст') return end
local sum = 0
for _, n in ipairs(items) do sum = sum + n end
gg.alert('Среднее: ' .. sum / #items)]====]},
{title = [====[Проверка целого числа]====], code = [====[local n = tonumber('42')
gg.alert(tostring(n ~= nil and n == math.floor(n)))]====]},
{title = [====[Линейная интерполяция]====], code = [====[local a, b, t = 10, 20, 0.25
local result = a + (b - a) * t
gg.alert(tostring(result))]====]},
{title = [====[Перевести секунды в минуты]====], code = [====[local seconds = 125
local minutes = math.floor(seconds / 60)
gg.alert(string.format('%d:%02d', minutes, seconds % 60))]====]},
}},
{name = [====[Файлы и отладка]====], items = {
{title = [====[Безопасное чтение файла]====], code = [====[local path = (gg.EXT_STORAGE or '/sdcard') .. '/Download/example.txt'
local f, err = io.open(path, 'r')
if not f then gg.alert('Ошибка: ' .. tostring(err)) return end
local data = f:read(4096) or ''
f:close()
gg.alert(data)]====]},
{title = [====[Запись файла с подтверждением]====], code = [====[local path = (gg.EXT_STORAGE or '/sdcard') .. '/Download/ggds_example.txt'
if gg.choice({'Отмена', 'Записать'}, nil, 'Перезаписать ' .. path .. '?') ~= 2 then return end
local f, err = io.open(path, 'w')
if not f then gg.alert(tostring(err)) return end
local ok, e = f:write('Пример\n')
local closed, ce = f:close()
if not ok or not closed then gg.alert(tostring(e or ce)) else gg.alert('Готово') end]====]},
{title = [====[Проверить наличие файла]====], code = [====[local path = (gg.EXT_STORAGE or '/sdcard') .. '/Download/example.txt'
local f = io.open(path, 'r')
if f then f:close(); gg.alert('Файл доступен') else gg.alert('Файл не найден или недоступен') end]====]},
{title = [====[Добавить запись в журнал]====], code = [====[local path = (gg.EXT_STORAGE or '/sdcard') .. '/Download/ggds_log.txt'
local f, err = io.open(path, 'a')
if not f then gg.alert(tostring(err)) return end
local ok, e = f:write('Событие скрипта\n')
local closed, ce = f:close()
if not ok or not closed then gg.alert(tostring(e or ce)) else gg.toast('Записано') end]====]},
{title = [====[Обработка ошибки pcall]====], code = [====[local ok, result = pcall(function() return 10 / 2 end)
if not ok then gg.alert('Ошибка: ' .. tostring(result)) return end
gg.alert('Результат: ' .. tostring(result))]====]},
{title = [====[Проверка типа]====], code = [====[local value = 42
if type(value) ~= 'number' then gg.alert('Ожидалось число') return end
gg.alert('Число: ' .. tostring(value))]====]},
{title = [====[Защитный вызов функции]====], code = [====[local function run(fn)
  if type(fn) ~= 'function' then return false, 'Не функция' end
  return pcall(fn)
end
local ok, result = run(function() return 'готово' end)
gg.alert(ok and tostring(result) or ('Ошибка: ' .. tostring(result)))]====]},
{title = [====[Проверка обязательного поля]====], code = [====[local p = gg.prompt({'Имя'}, {''}, {'text'})
if not p then return end
local value = tostring(p[1]):match('^%s*(.-)%s*$')
if value == '' then gg.alert('Поле обязательно') return end
gg.alert('Имя: ' .. value)]====]},
{title = [====[Измерить время операции]====], code = [====[local start = os.clock()
local sum = 0
for i = 1, 10000 do sum = sum + i end
gg.alert('CPU-время: ' .. tostring(os.clock() - start) .. ' сек.; сумма: ' .. sum)]====]},
{title = [====[Вывести информацию в журнал]====], code = [====[print('Отладка: начало действия')
local data = {value = 123, label = 'demo'}
for k, v in pairs(data) do print(tostring(k) .. ' = ' .. tostring(v)) end
gg.toast('Информация выведена в журнал')]====]},
}},
{name = [====[Проверка данных]====], items = {
{title = [====[Число в диапазоне]====], code = [====[local n = tonumber('42')
if not n or n < 0 or n > 100 then gg.alert('Число должно быть от 0 до 100') return end
gg.alert('Подходит: ' .. n)]====]},
{title = [====[Положительное число]====], code = [====[local n = tonumber('10')
if not n or n <= 0 then gg.alert('Нужно положительное число') return end
gg.alert('Подходит: ' .. n)]====]},
{title = [====[Непустая строка]====], code = [====[local s = '  пример  '
if not s:find('%S') then gg.alert('Строка пуста') return end
gg.alert('Строка не пуста')]====]},
{title = [====[Проверка длины текста в байтах]====], code = [====[local s, limit = 'hello', 20
if #s > limit then gg.alert('Превышен лимит байтов') return end
gg.alert('Байтов: ' .. #s)]====]},
{title = [====[Проверка имени переменной]====], code = [====[local name = 'my_value'
if not name:match('^[A-Za-z_][A-Za-z0-9_]*$') then gg.alert('Некорректное имя') return end
gg.alert('Имя имеет допустимый формат')]====]},
{title = [====[Проверка расширения Lua]====], code = [====[local path = 'example.lua'
if path:sub(-4):lower() ~= '.lua' then gg.alert('Ожидается .lua') return end
gg.alert('Расширение .lua')]====]},
{title = [====[Проверка наличия ключа]====], code = [====[local t = {name = 'Demo'}
if t.name == nil then gg.alert('Ключ name отсутствует') return end
gg.alert(tostring(t.name))]====]},
{title = [====[Безопасное значение по умолчанию]====], code = [====[local data = {}
local label = data.label
if label == nil then label = 'Без названия' end
gg.alert(tostring(label))]====]},
{title = [====[Прочитать да или нет]====], code = [====[local c = gg.choice({'Да', 'Нет'}, nil, 'Продолжить?')
if not c then return end
local answer = c == 1
gg.alert('Ответ: ' .. tostring(answer))]====]},
{title = [====[Сравнить числа с допуском]====], code = [====[local a, b, epsilon = 0.1 + 0.2, 0.3, 0.000001
gg.alert('Приблизительно равны: ' .. tostring(math.abs(a - b) < epsilon))]====]},
}},
{name = [====[Дополнительные строки]====], items = {
{title = [====[Перевод строк в нижний регистр]====], code = [====[local text = 'HELLO Lua'
gg.alert(string.lower(text) .. '\nПримечание: стандартный lower не меняет кириллицу UTF-8.')]====]},
{title = [====[Перевод строк в верхний регистр]====], code = [====[local text = 'hello Lua'
gg.alert(string.upper(text) .. '\nПримечание: стандартный upper не меняет кириллицу UTF-8.')]====]},
{title = [====[Подсчитать вхождения]====], code = [====[local text, pattern = 'a-b-c', '-'
local _, n = text:gsub(pattern, '')
gg.alert('Вхождений: ' .. n)]====]},
{title = [====[Удалить переносы строк]====], code = [====[local text = 'a\nb\nc'
text = text:gsub('[\r\n]+', ' ')
gg.alert(text)]====]},
{title = [====[Первый и последний символ ASCII]====], code = [====[local text = 'Lua'
gg.alert('Первый: ' .. text:sub(1,1) .. ', последний: ' .. text:sub(-1))]====]},
{title = [====[Проверка версии по точному совпадению]====], code = [====[local actual, expected = '1.2.0', '1.2.0'
if actual ~= expected then gg.alert('Версия не совпадает') return end
gg.alert('Версия совпадает')]====]},
{title = [====[Безопасное преобразование в текст]====], code = [====[local value = nil
gg.alert('Значение: ' .. tostring(value))]====]},
{title = [====[Форматировать строку]====], code = [====[local name, n = 'Игрок', 3
gg.alert(string.format('%s — уровень %d', name, n))]====]},
{title = [====[Удалить цифры из текста]====], code = [====[local text = 'abc123'
gg.alert((text:gsub('%d', '')))]====]},
{title = [====[Экранировать проценты для gsub]====], code = [====[local text = 'a%b'
local replacement = '50%'
local result = text:gsub('%%', function() return replacement end)
gg.alert(result)]====]},
}},
{name = [====[Структуры и алгоритмы]====], items = {
{title = [====[Развернуть список]====], code = [====[local a, out = {'A','B','C'}, {}
for i = #a, 1, -1 do out[#out + 1] = a[i] end
gg.alert(table.concat(out, ', '))]====]},
{title = [====[Частота значений]====], code = [====[local a, counts = {'a','b','a'}, {}
for _, v in ipairs(a) do counts[v] = (counts[v] or 0) + 1 end
gg.alert('a: ' .. tostring(counts.a or 0))]====]},
{title = [====[Объединить два списка]====], code = [====[local a, b, out = {1,2}, {3,4}, {}
for _, v in ipairs(a) do out[#out + 1] = v end
for _, v in ipairs(b) do out[#out + 1] = v end
gg.alert(table.concat(out, ', '))]====]},
{title = [====[Взять первые элементы]====], code = [====[local a, out, limit = {1,2,3,4}, {}, 2
for i = 1, math.min(#a, limit) do out[#out + 1] = a[i] end
gg.alert(table.concat(out, ', '))]====]},
{title = [====[Проверить хотя бы один элемент]====], code = [====[local a, found = {1,3,4}, false
for _, v in ipairs(a) do if v % 2 == 0 then found = true; break end end
gg.alert('Есть чётное: ' .. tostring(found))]====]},
{title = [====[Проверить все элементы]====], code = [====[local a, all = {2,4,6}, true
for _, v in ipairs(a) do if v % 2 ~= 0 then all = false; break end end
gg.alert('Все чётные: ' .. tostring(all))]====]},
{title = [====[Преобразовать элементы списка]====], code = [====[local a, out = {1,2,3}, {}
for _, v in ipairs(a) do out[#out + 1] = v * 2 end
gg.alert(table.concat(out, ', '))]====]},
{title = [====[Получить отсортированные ключи]====], code = [====[local data, keys = {b=2,a=1,c=3}, {}
for k in pairs(data) do keys[#keys + 1] = k end
table.sort(keys)
gg.alert(table.concat(keys, ', '))]====]},
{title = [====[Создать множество]====], code = [====[local input, set = {'a','b','a'}, {}
for _, v in ipairs(input) do set[v] = true end
gg.alert('Есть b: ' .. tostring(set.b == true))]====]},
{title = [====[Простая очередь]====], code = [====[local queue = {'первый','второй'}
queue[#queue + 1] = 'третий'
local next_item = table.remove(queue, 1)
gg.alert('Извлечён: ' .. next_item)]====]},
}},
{name = [====[Работа с GG и процессом]====], items = {
{title = [====[Вывести название пакета]====], code = [====[local t = gg.getTargetInfo()
if not t then gg.alert('Процесс не выбран') return end
gg.alert('Пакет: ' .. tostring(t.packageName or 'неизвестен'))]====]},
{title = [====[Вывести версию приложения]====], code = [====[local t = gg.getTargetInfo()
if not t then gg.alert('Процесс не выбран') return end
gg.alert('Версия: ' .. tostring(t.versionName or 'неизвестна'))]====]},
{title = [====[Ограничить количество результатов]====], code = [====[local count = gg.getResultsCount()
if count == 0 then gg.alert('Результатов нет') return end
local items = gg.getResults(math.min(count, 5))
gg.alert('Получено: ' .. #items .. ' из ' .. count)]====]},
{title = [====[Просмотреть тип первой записи]====], code = [====[if gg.getResultsCount() == 0 then gg.alert('Результатов нет') return end
local r = gg.getResults(1)
gg.alert('Тип: ' .. tostring(r[1] and r[1].flags))]====]},
{title = [====[Просмотреть значение первой записи]====], code = [====[if gg.getResultsCount() == 0 then gg.alert('Результатов нет') return end
local r = gg.getResults(1)
gg.alert('Значение: ' .. tostring(r[1] and r[1].value))]====]},
{title = [====[Просмотреть адрес первой записи]====], code = [====[if gg.getResultsCount() == 0 then gg.alert('Результатов нет') return end
local r = gg.getResults(1)
gg.alert('Адрес: ' .. tostring(r[1] and r[1].address))]====]},
{title = [====[Проверить наличие toast]====], code = [====[if type(gg.toast) == 'function' then gg.toast('toast доступен') else gg.alert('toast недоступен') end]====]},
{title = [====[Показать путь к общей памяти]====], code = [====[gg.alert('Общая память: ' .. tostring(gg.EXT_STORAGE or '/sdcard'))]====]},
{title = [====[Предупреждение о чистке результатов]====], code = [====[local n = gg.getResultsCount()
gg.alert('Сейчас результатов: ' .. n .. '. Новый поиск может их очистить.')]====]},
{title = [====[Выбор типа для поиска]====], code = [====[local names = {'DWORD', 'FLOAT', 'DOUBLE', 'QWORD'}
local i = gg.choice(names, nil, 'Выберите тип')
if not i then return end
local flag = gg['TYPE_' .. names[i]]
if not flag then gg.alert('Тип недоступен') return end
gg.alert('Выбран тип: ' .. names[i] .. ', код: ' .. tostring(flag))]====]},
}},
{name = [====[Диагностика и файлы]====], items = {
{title = [====[Проверить функцию по имени]====], code = [====[local name = 'getResultsCount'
gg.alert(name .. ': ' .. tostring(type(gg[name]) == 'function'))]====]},
{title = [====[Просмотр версии Lua]====], code = [====[gg.alert('Версия Lua: ' .. tostring(_VERSION))]====]},
{title = [====[Показать дату, если доступна]====], code = [====[if not os or type(os.date) ~= 'function' then gg.alert('os.date недоступна') return end
local ok, value = pcall(os.date, '%Y-%m-%d %H:%M:%S')
gg.alert(ok and tostring(value) or 'Дата недоступна')]====]},
{title = [====[Проверить наличие компилятора Lua]====], code = [====[gg.alert('Проверка синтаксиса: ' .. tostring(type(loadstring or load) == 'function'))]====]},
{title = [====[Проверить синтаксис строки]====], code = [====[local compiler = loadstring or load
if not compiler then gg.alert('Компилятор недоступен') return end
local ok, fn, err = pcall(compiler, 'return 1 + 2')
gg.alert(ok and fn and 'Синтаксис верен' or tostring(ok and err or fn))]====]},
{title = [====[Прочитать первую строку файла]====], code = [====[local path = (gg.EXT_STORAGE or '/sdcard') .. '/Download/example.txt'
local f, err = io.open(path, 'r')
if not f then gg.alert(tostring(err)) return end
local line = f:read('*l')
f:close()
gg.alert(line or 'Файл пуст')]====]},
{title = [====[Размер файла в байтах]====], code = [====[local path = (gg.EXT_STORAGE or '/sdcard') .. '/Download/example.txt'
local f, err = io.open(path, 'rb')
if not f then gg.alert(tostring(err)) return end
local n, seek_err = f:seek('end')
f:close()
gg.alert(n and ('Байтов: ' .. n) or tostring(seek_err))]====]},
{title = [====[Читать ограниченный объём файла]====], code = [====[local path = (gg.EXT_STORAGE or '/sdcard') .. '/Download/example.txt'
local f, err = io.open(path, 'r')
if not f then gg.alert(tostring(err)) return end
local data = f:read(512) or ''
f:close()
gg.alert('Первые байты:\n' .. data)]====]},
{title = [====[Проверить пустой файл]====], code = [====[local path = (gg.EXT_STORAGE or '/sdcard') .. '/Download/example.txt'
local f, err = io.open(path, 'rb')
if not f then gg.alert(tostring(err)) return end
local byte = f:read(1)
f:close()
gg.alert(byte and 'Файл не пуст' or 'Файл пуст')]====]},
{title = [====[Записать предупреждение в журнал]====], code = [====[local message = 'Пример предупреждения'
print('[WARNING] ' .. message)
gg.toast('Предупреждение выведено в журнал')]====]},
}},
}
local function select_template(template)
    local action = gg.choice({'Вставить в проект', 'Посмотреть код', 'Скопировать код', 'Отмена'}, nil, template.title)
    if action == 2 then notify(template.code); return end
    if action == 3 then
        if type(gg.copyText) ~= 'function' then notify('Копирование недоступно.') return end
        local ok, err = pcall(gg.copyText, template.code)
        notify(ok and 'Код скопирован.' or ('Ошибка: ' .. tostring(err)))
        return
    end
    if action ~= 1 then return end
    project.items[#project.items + 1] = {kind='K', title=template.title, content=template.code}
    notify('Шаблон добавлен. Изменить его можно через «Управлять пунктами». Сохраните проект.')
end
local function insert_template()
    if not project then notify('Сначала откройте проект.') return end
    local categories = {'Поиск по названию'}
    for _, cat in ipairs(TEMPLATE_LIBRARY) do categories[#categories + 1] = cat.name .. ' (' .. #cat.items .. ')' end
    local cat = gg.choice(categories, nil, 'Библиотека шаблонов — 110 готовых примеров')
    if not cat then return end
    local items, labels = {}, {}
    if cat == 1 then
        local p = gg.prompt({'Поиск по названию (учитывается регистр)'}, {''}, {'text'})
        if not p then return end
        for _, group in ipairs(TEMPLATE_LIBRARY) do
            for _, item in ipairs(group.items) do
                if item.title:find(p[1], 1, true) then items[#items + 1] = item; labels[#labels + 1] = group.name .. ': ' .. item.title end
            end
        end
    else
        items = TEMPLATE_LIBRARY[cat - 1].items
        for i, item in ipairs(items) do labels[i] = item.title end
    end
    if #items == 0 then notify('Ничего не найдено.') return end
    local selected = gg.choice(labels, nil, cat == 1 and 'Результаты поиска' or TEMPLATE_LIBRARY[cat - 1].name)
    if selected then select_template(items[selected]) end
end
local function reference_menu()
    local topics = {
        {'Первые шаги', '1. Создайте проект и задайте ID.\n2. Добавьте пункты или шаблоны.\n3. Сохраните проект.\n4. Проверьте его и соберите скрипт.'},
        {'Переменные и типы', 'local name = \"demo\"\nlocal count = 10\nlocal enabled = true\n\ntype(value) возвращает тип значения. Локальные переменные безопаснее глобальных.'},
        {'Условия и циклы', 'if condition then ... elseif other then ... else ... end\n\nfor i = 1, 10 do ... end\nwhile condition do ... end\n\nipairs — список; pairs — таблица.'},
        {'Функции и ошибки', 'local function action(x)\n  return x * 2\nend\n\nlocal ok, result = pcall(action, 2)\nif not ok then gg.alert(tostring(result)) end'},
        {'API GameGuardian', 'gg.alert — окно; gg.toast — уведомление; gg.choice — выбор; gg.prompt — ввод; gg.getResultsCount — число найденных значений. Проверяйте совместимость на своей версии GG.'},
        {'Проекты и резервные копии', 'Проекты хранятся в Download как файлы .ggds. Копия создаётся в меню «Инструменты». Перед заменой или сборкой сохраняйте изменения.'},
        {'Безопасность', 'Не запускайте чужой Lua-код без проверки. Некоторые шаблоны записывают файлы или очищают результаты поиска. Изменения в итоговом файле будут потеряны при повторной сборке.'}
    }
    local labels = {}
    for i, topic in ipairs(topics) do labels[i] = topic[1] end
    local n = gg.choice(labels, nil, 'Справочник разработчика')
    if n then notify(topics[n][2]) end
end
local function validate_project()
    if not project then notify('Сначала откройте проект.') return end
    local errors, warnings = {}, {}
    if #project.items == 0 then errors[#errors + 1] = 'Нет пунктов меню.' end
    local compiler = loadstring or load
    for i, item in ipairs(project.items) do
        if item.title == '' then errors[#errors + 1] = i .. ': пустое название.' end
        if item.kind == 'S' then warnings[#warnings + 1] = i .. ': заготовка функции ещё не реализована.' end
        if item.kind == 'K' and compiler then
            local ok, fn, err = pcall(compiler, 'return function()\n' .. item.content .. '\nend')
            if not ok or not fn then errors[#errors + 1] = i .. ': ' .. tostring(ok and err or fn) end
        end
    end
    local text = 'Пунктов: ' .. #project.items .. '\nОшибок: ' .. #errors .. '\nПредупреждений: ' .. #warnings
    if #errors > 0 then text = text .. '\n\nОшибки:\n' .. table.concat(errors, '\n') end
    if #warnings > 0 then text = text .. '\n\nПредупреждения:\n' .. table.concat(warnings, '\n') end
    if not compiler then text = text .. '\nПроверка синтаксиса недоступна в этой среде.' end
    notify(text)
end
-- Дополнительные интерактивные инструменты не выполняют пользовательский код.
local function syntax_lab()
    local p = gg.prompt({'Введите Lua-код для проверки синтаксиса (без запуска)'}, {'local value = 1'}, {'text'})
    if not p then return end
    local compiler = loadstring or load
    if type(compiler) ~= 'function' then notify('Компилятор Lua недоступен в этой среде.') return end
    local ok, fn, err = pcall(compiler, p[1])
    if ok and fn then notify('Синтаксис принят. Код не выполнялся.')
    else notify('Ошибка проверки: ' .. tostring(ok and err or fn)) end
end
local function text_lab()
    local p = gg.prompt({'Введите текст'}, {''}, {'text'})
    if not p then return end
    local text = p[1]
    local c = gg.choice({'Число байтов и строк', 'Удалить пробелы по краям', 'Кодировать в HEX', 'Декодировать HEX', 'Скопировать текст'}, nil, 'Инструменты текста')
    if c == 1 then
        local _, n = text:gsub('\n', '')
        notify('Байтов: ' .. #text .. '\nСтрок: ' .. (n + 1) .. '\nКоличество байтов не равно числу символов UTF-8.')
    elseif c == 2 then notify('Результат:\n' .. text:match('^%s*(.-)%s*$'))
    elseif c == 3 then notify('HEX:\n' .. hex(text))
    elseif c == 4 then local result = unhex(text); notify(result and ('Результат:\n' .. result) or 'Ошибка: ожидается чётное число шестнадцатеричных символов.')
    elseif c == 5 then
        if type(gg.copyText) ~= 'function' then notify('Копирование недоступно.') return end
        local ok, err = pcall(gg.copyText, text)
        notify(ok and 'Текст скопирован.' or ('Ошибка: ' .. tostring(err)))
    end
end
local function read_limited(path, limit)
    local f, err = io.open(path, 'rb')
    if not f then return nil, err end
    local data = f:read(limit + 1) or ''
    f:close()
    if #data > limit then return nil, 'Файл больше ' .. limit .. ' байт.' end
    return data
end
local function file_compare()
    local p = gg.prompt({'Путь к первому файлу', 'Путь ко второму файлу'}, {root .. '/first.lua', root .. '/second.lua'}, {'text', 'text'})
    if not p then return end
    local a, e1 = read_limited(p[1], 262144)
    if not a then notify('Первый файл: ' .. tostring(e1)) return end
    local b, e2 = read_limited(p[2], 262144)
    if not b then notify('Второй файл: ' .. tostring(e2)) return end
    if a == b then notify('Файлы совпадают побайтно. Размер: ' .. #a .. ' байт.') return end
    local first = 1
    while first <= math.min(#a, #b) and a:byte(first) == b:byte(first) do first = first + 1 end
    notify('Файлы различаются.\nПервый: ' .. #a .. ' байт\nВторой: ' .. #b .. ' байт\nПервое отличие на позиции байта: ' .. first)
end
local function inspect_file()
    local p = gg.prompt({'Путь к файлу (чтение до 256 КБ)'}, {root .. '/example.lua'}, {'text'})
    if not p then return end
    local data, err = read_limited(p[1], 262144)
    if not data then notify('Ошибка: ' .. tostring(err)) return end
    local _, n = data:gsub('\n', '')
    local c = gg.choice({'Информация', 'Показать первые 2000 байт', 'Проверить синтаксис Lua'}, nil, 'Просмотр файла')
    if c == 1 then notify('Байтов: ' .. #data .. '\nСтрок: ' .. (n + 1))
    elseif c == 2 then notify(data:sub(1, 2000))
    elseif c == 3 then
        local compiler = loadstring or load
        if type(compiler) ~= 'function' then notify('Компилятор недоступен.') return end
        local ok, fn, parse_err = pcall(compiler, data)
        notify(ok and fn and 'Синтаксис принят. Файл не выполнялся.' or ('Ошибка: ' .. tostring(ok and parse_err or fn)))
    end
end
local function project_search()
    if not project then notify('Сначала откройте проект.') return end
    local p = gg.prompt({'Поиск в названии и содержимом (учитывается регистр)'}, {''}, {'text'})
    if not p then return end
    local labels, matches = {}, {}
    for i, item in ipairs(project.items) do
        if item.title:find(p[1], 1, true) or item.content:find(p[1], 1, true) then
            labels[#labels + 1] = i .. '. ' .. item.title
            matches[#matches + 1] = item
        end
    end
    if #matches == 0 then notify('Совпадений нет.') return end
    local i = gg.choice(labels, nil, 'Найдено: ' .. #matches)
    if i then notify('Тип: ' .. matches[i].kind .. '\n\n' .. matches[i].content:sub(1, 4000)) end
end
-- Локальные инструменты разработчика, не запускают чужой код.
local function statistics()
    if not project then notify('Сначала откройте проект.') return end
    local kinds = {M='Окна', T='Уведомления', S='Заготовки', Q='Поиск', I='Ввод', C='Подтверждения', R='Результаты', K='Lua-код'}
    local counts, bytes, duplicates, seen = {}, 0, 0, {}
    for _, item in ipairs(project.items) do
        counts[item.kind] = (counts[item.kind] or 0) + 1
        bytes = bytes + #item.title + #item.content
        if seen[item.title] then duplicates = duplicates + 1 end
        seen[item.title] = true
    end
    local lines = {'Проект: ' .. project.title, 'Пунктов: ' .. #project.items, 'Данных: ' .. bytes .. ' байт', 'Повторяющихся названий: ' .. duplicates, ''}
    for _, kind in ipairs({'M','T','S','Q','I','C','R','K'}) do lines[#lines + 1] = kinds[kind] .. ': ' .. (counts[kind] or 0) end
    notify(table.concat(lines, '\n'))
end
local function notes()
    if not project then notify('Сначала откройте проект.') return end
    local path = root .. '/' .. project_id .. '_notes.txt'
    local old = ''
    local f = io.open(path, 'rb')
    if f then old = f:read(65537) or ''; f:close() end
    if #old > 65536 then notify('Файл заметок больше 64 КБ; редактирование отменено.') return end
    local c = gg.choice({'Просмотреть', 'Редактировать и сохранить', 'Скопировать'}, nil, 'Заметки проекта')
    if c == 1 then notify(old ~= '' and old or 'Заметок пока нет.')
    elseif c == 2 then
        local p = gg.prompt({'Заметки проекта (заменяют текущие)'}, {old}, {'text'})
        if not p then return end
        if #p[1] > 65536 then notify('Заметка больше 64 КБ.') return end
        local ok, err = write_file(path, p[1])
        notify(ok and ('Заметки сохранены: ' .. path) or ('Ошибка: ' .. tostring(err)))
    elseif c == 3 then
        if type(gg.copyText) ~= 'function' then notify('Копирование недоступно.') return end
        local ok, err = pcall(gg.copyText, old)
        notify(ok and 'Заметки скопированы.' or ('Ошибка: ' .. tostring(err)))
    end
end
local function math_tool()
    local p = gg.prompt({'Первое число', 'Второе число'}, {'10', '2'}, {'number', 'number'})
    if not p then return end
    local a,b = tonumber(p[1]), tonumber(p[2])
    if not a or not b then notify('Введите два числа.') return end
    local c = gg.choice({'Сложение', 'Вычитание', 'Умножение', 'Деление', 'Остаток', 'Процент от числа'}, nil, 'Калькулятор')
    if not c then return end
    if (c == 4 or c == 5) and b == 0 then notify('Деление на ноль невозможно.') return end
    local result
    if c == 1 then result = a+b elseif c == 2 then result = a-b elseif c == 3 then result = a*b elseif c == 4 then result = a/b elseif c == 5 then result = a%b elseif c == 6 then result = a*b/100 end
    notify('Результат: ' .. tostring(result))
end
local function code_quote_tool()
    local p = gg.prompt({'Текст для Lua-строки'}, {''}, {'text'})
    if not p then return end
    local literal = string.format('%q', p[1])
    local c = gg.choice({'Показать Lua-литерал', 'Скопировать Lua-литерал'}, nil, 'Экранирование строки')
    if c == 1 then notify(literal)
    elseif c == 2 then
        if type(gg.copyText) ~= 'function' then notify('Копирование недоступно.') return end
        local ok, err = pcall(gg.copyText, literal)
        notify(ok and 'Скопировано.' or ('Ошибка: ' .. tostring(err)))
    end
end
local function lines_tool()
    local p = gg.prompt({'Текст, строки разделены переносами'}, {''}, {'text'})
    if not p then return end
    local lines = {}
    local text = p[1]:gsub('\r\n', '\n'):gsub('\r', '\n')
    for line in (text .. '\n'):gmatch('(.-)\n') do lines[#lines + 1] = line end
    local c = gg.choice({'Сортировать строки', 'Убрать повторяющиеся строки', 'Нумеровать строки', 'Показать длину строк'}, nil, 'Обработка строк')
    if not c then return end
    local out = {}
    if c == 1 then table.sort(lines); out = lines
    elseif c == 2 then local seen = {}; for _, line in ipairs(lines) do if not seen[line] then seen[line] = true; out[#out + 1] = line end end
    elseif c == 3 then for i, line in ipairs(lines) do out[#out + 1] = i .. '. ' .. line end
    elseif c == 4 then for i, line in ipairs(lines) do out[#out + 1] = i .. ': ' .. #line .. ' байт' end end
    local result = table.concat(out, '\n')
    local action = gg.choice({'Показать', 'Скопировать'}, nil, 'Обработано строк: ' .. #out)
    if action == 1 then notify(result)
    elseif action == 2 then
        if type(gg.copyText) ~= 'function' then notify('Копирование недоступно.') return end
        local ok, err = pcall(gg.copyText, result)
        notify(ok and 'Скопировано.' or ('Ошибка: ' .. tostring(err)))
    end
end
local function project_action_export()
    if not project or #project.items == 0 then notify('Откройте проект с пунктами.') return end
    local labels = {}
    for i, item in ipairs(project.items) do labels[i] = i .. '. ' .. item.title .. ' [' .. item.kind .. ']' end
    local i = gg.choice(labels, nil, 'Скопировать содержимое пункта')
    if not i then return end
    local item = project.items[i]
    if type(gg.copyText) ~= 'function' then notify('Копирование недоступно.') return end
    local ok, err = pcall(gg.copyText, item.content)
    notify(ok and 'Содержимое скопировано.' or ('Ошибка: ' .. tostring(err)))
end
local function developer_lab()
    local c = gg.choice({'Проверка синтаксиса Lua', 'Инструменты текста', 'Сравнение двух файлов', 'Просмотр и проверка файла', 'Поиск по текущему проекту', 'Статистика проекта', 'Заметки проекта', 'Калькулятор', 'Экранирование Lua-строки', 'Обработка строк', 'Скопировать пункт проекта'}, nil, 'Лаборатория разработчика')
    if c == 1 then syntax_lab() elseif c == 2 then text_lab() elseif c == 3 then file_compare() elseif c == 4 then inspect_file() elseif c == 5 then project_search() elseif c == 6 then statistics() elseif c == 7 then notes() elseif c == 8 then math_tool() elseif c == 9 then code_quote_tool() elseif c == 10 then lines_tool() elseif c == 11 then project_action_export() end
end
-- Инструменты для пакетной работы с открытым проектом.
local function bulk_titles()
    if not project or #project.items == 0 then notify('Откройте проект с пунктами.') return end
    local mode = gg.choice({'Добавить префикс', 'Добавить суффикс', 'Заменить текст в названиях', 'Нумеровать названия'}, nil, 'Пакетное изменение названий')
    if not mode then return end
    local p
    if mode == 1 then p = gg.prompt({'Префикс'}, {''}, {'text'})
    elseif mode == 2 then p = gg.prompt({'Суффикс'}, {''}, {'text'})
    elseif mode == 3 then p = gg.prompt({'Что найти (без шаблонов)', 'На что заменить'}, {'', ''}, {'text', 'text'})
    else p = {''} end
    if not p then return end
    if mode == 3 and p[1] == '' then notify('Строка поиска не должна быть пустой.') return end
    local new_titles, changed = {}, 0
    for i, item in ipairs(project.items) do
        local title = item.title
        if mode == 1 then title = p[1] .. title
        elseif mode == 2 then title = title .. p[1]
        elseif mode == 3 then
            -- Функция замены и plain-поиск не трактуют символы % и . как шаблон.
            local output, from = {}, 1
            while true do
                local a, b = title:find(p[1], from, true)
                if not a then output[#output + 1] = title:sub(from); break end
                output[#output + 1] = title:sub(from, a - 1)
                output[#output + 1] = p[2]
                from = b + 1
            end
            title = table.concat(output)
        elseif mode == 4 then title = i .. '. ' .. title end
        if title == '' then notify('Операция создаёт пустое название; изменения отменены.') return end
        new_titles[i] = title
        if title ~= item.title then changed = changed + 1 end
    end
    if changed == 0 then notify('Совпадений или изменений нет.') return end
    local sample = 'Будет изменено: ' .. changed .. '\nПример: ' .. project.items[1].title .. ' → ' .. new_titles[1]
    if gg.choice({'Отмена', 'Применить'}, nil, sample) ~= 2 then return end
    for i, title in ipairs(new_titles) do project.items[i].title = title end
    notify('Изменения применены. Сохраните проект.')
end
local function sort_project_items()
    if not project or #project.items < 2 then notify('Нужно хотя бы два пункта.') return end
    local c = gg.choice({'Отмена', 'По названию (байтовый порядок)'}, nil, 'Сортировка изменит порядок меню')
    if c ~= 2 then return end
    local indexed = {}
    for i, item in ipairs(project.items) do indexed[i] = {index=i, item=item} end
    table.sort(indexed, function(a,b)
        if a.item.title == b.item.title then return a.index < b.index end
        return a.item.title < b.item.title
    end)
    for i, entry in ipairs(indexed) do project.items[i] = entry.item end
    notify('Пункты отсортированы. Сохраните проект.')
end
local function compare_with_saved()
    if not project then notify('Сначала откройте проект.') return end
    if saved_snapshot == nil then notify('Этот проект ещё не был сохранён.') return end
    local current = project_data(project)
    if current == saved_snapshot then notify('Текущий проект совпадает с последней сохранённой версией.') return end
    local a, b = {}, {}
    for line in saved_snapshot:gmatch('([^\n]*)\n') do a[#a + 1] = line end
    for line in current:gmatch('([^\n]*)\n') do b[#b + 1] = line end
    local lines = {}
    if a[2] ~= b[2] then lines[#lines + 1] = 'Изменено название проекта.' end
    if a[3] ~= b[3] then lines[#lines + 1] = 'Изменена версия проекта.' end
    local old_count, new_count = #a - 3, #b - 3
    lines[#lines + 1] = 'Пунктов было: ' .. old_count .. ', сейчас: ' .. new_count
    local different = 0
    for i = 4, math.max(#a, #b) do if a[i] ~= b[i] then different = different + 1 end end
    lines[#lines + 1] = 'Различий по позициям: ' .. different
    lines[#lines + 1] = 'Перемещение пункта может считаться несколькими различиями.'
    notify(table.concat(lines, '\n'))
end
local function batch_delete()
    if not project or #project.items == 0 then notify('Нет пунктов.') return end
    local labels = {}
    for i, item in ipairs(project.items) do labels[i] = i .. '. ' .. item.title end
    local selected = gg.multiChoice(labels, nil, 'Отметьте пункты для удаления')
    if not selected then return end
    local count = 0
    for i = 1, #project.items do if selected[i] then count = count + 1 end end
    if count == 0 then notify('Пункты не выбраны.') return end
    if gg.choice({'Отмена', 'Удалить'}, nil, 'Будет удалено пунктов: ' .. count) ~= 2 then return end
    for i = #project.items, 1, -1 do if selected[i] then table.remove(project.items, i) end end
    notify('Удалено: ' .. count .. '. Сохраните проект.')
end
local function export_project_code()
    if not project then notify('Сначала откройте проект.') return end
    local lines = {'-- Сборник пользовательских блоков из проекта ' .. project_id,
        '-- Это справочный файл, не меню и не готовый скрипт.',
        '-- Блоки обёрнуты в функции и не выполняются при загрузке файла.',
        'local blocks = {}'}
    local count = 0
    for i, item in ipairs(project.items) do
        if item.kind == 'K' then
            count = count + 1
            lines[#lines + 1] = '-- Пункт ' .. i .. ': ' .. item.title:gsub('[\r\n]', ' ')
            lines[#lines + 1] = 'blocks[' .. count .. '] = function()'
            lines[#lines + 1] = item.content
            lines[#lines + 1] = 'end'
        end
    end
    lines[#lines + 1] = 'return blocks'
    if count == 0 then notify('В проекте нет блоков пользовательского Lua-кода.') return end
    local source = table.concat(lines, '\n') .. '\n'
    local compiler = loadstring or load
    if compiler then
        local ok, fn, err = pcall(compiler, source)
        if not ok or not fn then notify('Ошибка синтаксиса: ' .. tostring(ok and err or fn)) return end
    end
    local path = root .. '/' .. project_id .. '_blocks.lua'
    local old = io.open(path, 'r')
    if old then old:close(); if gg.choice({'Отмена', 'Перезаписать'}, nil, 'Файл блоков уже существует.') ~= 2 then return end end
    local ok, err = write_file(path, source)
    notify(ok and ('Экспортировано блоков: ' .. count .. '\nФайл: ' .. path) or ('Ошибка: ' .. tostring(err)))
end
local function export_project_summary()
    if not project then notify('Сначала откройте проект.') return end
    local lines = {'# ' .. project.title:gsub('[\r\n]', ' '), '', 'ID: ' .. project_id, 'Версия: ' .. project.version, '', '## Пункты меню', ''}
    for i, item in ipairs(project.items) do
        lines[#lines + 1] = i .. '. ' .. item.title:gsub('[\r\n]', ' ') .. ' (' .. item.kind .. ')'
    end
    local path = root .. '/' .. project_id .. '_summary.md'
    local old = io.open(path, 'r')
    if old then old:close(); if gg.choice({'Отмена', 'Перезаписать'}, nil, 'Отчёт уже существует.') ~= 2 then return end end
    local ok, err = write_file(path, table.concat(lines, '\n') .. '\n')
    notify(ok and ('Сохранено: ' .. path) or ('Ошибка: ' .. tostring(err)))
end
local function project_workbench()
    local options = {'Пакетное изменение названий', 'Сортировка пунктов', 'Сравнение с последним сохранением', 'Массовое удаление пунктов', 'Экспорт Lua-блоков', 'Экспорт структуры проекта в Markdown'}
    local c = gg.choice(options, nil, 'Мастерская проекта')
    if c == 1 then bulk_titles()
    elseif c == 2 then sort_project_items()
    elseif c == 3 then compare_with_saved()
    elseif c == 4 then batch_delete()
    elseif c == 5 then export_project_code()
    elseif c == 6 then export_project_summary() end
end
-- Проектные задачи записываются в отдельный локальный файл, без выполнения кода.
local function task_path() return root .. '/' .. project_id .. '_tasks.ggdstasks' end
local function read_tasks()
    local path = task_path()
    local file = io.open(path, 'rb')
    if not file then
        -- Отсутствие файла допустимо; ошибка доступа выявится при записи.
        return {}
    end
    local data = file:read(262145) or ''
    file:close()
    if #data > 262144 then return nil, 'Файл задач превышает 256 КБ.' end
    local tasks, first = {}, true
    for line in (data .. (data:sub(-1) == '\n' and '' or '\n')):gmatch('([^\n]*)\n') do
        if first then
            if line ~= 'GGDSTASK1' then return nil, 'Неверный заголовок файла задач.' end
            first = false
        else
            local status, encoded = line:match('^([01])|([%x]*)$')
            if not status then return nil, 'Повреждена запись задачи.' end
            local text = unhex(encoded)
            if text == nil then return nil, 'Повреждён текст задачи.' end
            tasks[#tasks + 1] = {done=status == '1', text=text}
        end
    end
    if first then return nil, 'Пустой файл задач.' end
    return tasks
end
local function write_tasks(tasks)
    local lines = {'GGDSTASK1'}
    for _, task in ipairs(tasks) do
        lines[#lines + 1] = (task.done and '1' or '0') .. '|' .. hex(task.text)
    end
    return write_file(task_path(), table.concat(lines, '\n') .. '\n')
end
local function task_manager()
    if not project then notify('Сначала откройте проект.') return end
    while true do
        local tasks, err = read_tasks()
        if not tasks then notify('Не удалось прочитать задачи: ' .. tostring(err)) return end
        local done = 0
        for _, task in ipairs(tasks) do if task.done then done = done + 1 end end
        local c = gg.choice({'Список и изменение задач', 'Добавить задачу', 'Удалить выполненные', 'Назад'}, nil,
            'Задачи проекта: ' .. done .. '/' .. #tasks .. ' выполнено')
        if not c or c == 4 then return end
        local changed = false
        if c == 1 then
            if #tasks == 0 then notify('Задач пока нет.')
            else
                local labels = {}
                for i, task in ipairs(tasks) do labels[i] = (task.done and '[x] ' or '[ ] ') .. task.text end
                local n = gg.choice(labels, nil, 'Выберите задачу')
                if n then
                    local action = gg.choice({'Переключить статус', 'Изменить текст', 'Удалить', 'Отмена'}, nil, tasks[n].text)
                    if action == 1 then tasks[n].done = not tasks[n].done; changed = true
                    elseif action == 2 then
                        local p = gg.prompt({'Текст задачи'}, {tasks[n].text}, {'text'})
                        if p and p[1] ~= '' then tasks[n].text = p[1]; changed = true end
                    elseif action == 3 and gg.choice({'Отмена', 'Удалить'}, nil, 'Удалить задачу?') == 2 then
                        table.remove(tasks, n); changed = true
                    end
                end
            end
        elseif c == 2 then
            local p = gg.prompt({'Новая задача'}, {''}, {'text'})
            if p and p[1] ~= '' then tasks[#tasks + 1] = {done=false, text=p[1]}; changed = true end
        elseif c == 3 then
            if done == 0 then notify('Выполненных задач нет.')
            elseif gg.choice({'Отмена', 'Удалить'}, nil, 'Удалить выполненных задач: ' .. done .. '?') == 2 then
                for i = #tasks, 1, -1 do if tasks[i].done then table.remove(tasks, i) end end
                changed = true
            end
        end
        if changed then
            local ok, write_err = write_tasks(tasks)
            if not ok then notify('Задачи не сохранены: ' .. tostring(write_err)); return end
            gg.toast('Задачи сохранены')
        end
    end
end

local function load_project_for_import(id)
    local data, err = read_limited(path_for(id), 1048576)
    if not data then return nil, err end
    local lines = {}
    for line in (data .. (data:sub(-1) == '\n' and '' or '\n')):gmatch('([^\n]*)\n') do lines[#lines + 1] = line end
    if lines[1] ~= 'GGDS1' or not lines[2] or not lines[3] or not unhex(lines[2]) or not unhex(lines[3]) then
        return nil, 'Некорректный формат проекта.'
    end
    local result = {}
    for i = 4, #lines do
        local kind, a, b = lines[i]:match('^([MSTQICRK])|([%x]*)|([%x]*)$')
        if not kind then return nil, 'Некорректный пункт в строке ' .. i end
        local title, content = unhex(a), unhex(b)
        if title == nil or content == nil then return nil, 'Повреждены данные в строке ' .. i end
        result[#result + 1] = {kind=kind, title=title, content=content}
    end
    return result
end
local function import_project_items()
    if not project then notify('Сначала откройте целевой проект.') return end
    local p = gg.prompt({'ID проекта-источника'}, {''}, {'text'})
    if not p then return end
    if not valid_id(p[1]) then notify('Некорректный ID.') return end
    local items, err = load_project_for_import(p[1])
    if not items then notify('Ошибка чтения: ' .. tostring(err)) return end
    if #items == 0 then notify('В исходном проекте нет пунктов.') return end
    local labels = {}
    for i, item in ipairs(items) do labels[i] = i .. '. [' .. item.kind .. '] ' .. item.title end
    local selected = gg.multiChoice(labels, nil, 'Выберите пункты для импорта')
    if not selected then return end
    local used, imported, skipped = {}, {}, 0
    for _, item in ipairs(project.items) do if item.kind == 'S' then used[item.content] = true end end
    for i, item in ipairs(items) do
        if selected[i] then
            if item.kind == 'S' and used[item.content] then skipped = skipped + 1
            else
                if item.kind == 'S' then used[item.content] = true end
                imported[#imported + 1] = {kind=item.kind, title=item.title, content=item.content}
            end
        end
    end
    if #imported == 0 then notify('Нечего импортировать. Пропущено конфликтов: ' .. skipped) return end
    if gg.choice({'Отмена', 'Импортировать'}, nil, 'Добавить: ' .. #imported .. '; конфликтов имён заготовок: ' .. skipped .. '?') ~= 2 then return end
    for _, item in ipairs(imported) do project.items[#project.items + 1] = item end
    notify('Импортировано: ' .. #imported .. '. Сохраните проект. Исходный код не выполнялся.')
end

-- Пакетная замена строго буквальная, изменения применяются только после проверки.
local function replace_code_text()
    if not project then notify('Сначала откройте проект.') return end
    local p = gg.prompt({'Найти (точный текст)', 'Заменить на'}, {'', ''}, {'text', 'text'})
    if not p then return end
    if p[1] == '' then notify('Пустую строку искать нельзя.') return end
    local pending, count, substitutions = {}, 0, 0
    for i, item in ipairs(project.items) do
        if item.kind == 'K' then
            local pieces, from, replacements = {}, 1, 0
            while true do
                local a, b = item.content:find(p[1], from, true)
                if not a then pieces[#pieces + 1] = item.content:sub(from); break end
                pieces[#pieces + 1] = item.content:sub(from, a - 1)
                pieces[#pieces + 1] = p[2]
                from, replacements = b + 1, replacements + 1
            end
            if replacements > 0 then
                pending[i] = table.concat(pieces)
                count, substitutions = count + 1, substitutions + replacements
            end
        end
    end
    if count == 0 then notify('Совпадений в Lua-блоках нет.') return end
    local compiler = loadstring or load
    if type(compiler) ~= 'function' then notify('Компилятор недоступен: безопасная пакетная замена отменена.') return end
    for i, code in pairs(pending) do
        local ok, fn, err = pcall(compiler, 'return function()\n' .. code .. '\nend')
        if not ok or not fn then notify('Замена отменена: ошибка в пункте ' .. i .. ': ' .. tostring(ok and err or fn)); return end
    end
    if gg.choice({'Отмена', 'Применить'}, nil, 'Блоков: ' .. count .. '; замен: ' .. substitutions .. '. Синтаксис проверен.') ~= 2 then return end
    for i, code in pairs(pending) do project.items[i].content = code end
    notify('Замена выполнена. Сохраните проект.')
end
local function inspect_code_markers()
    if not project then notify('Сначала откройте проект.') return end
    local markers, labels = {}, {}
    for i, item in ipairs(project.items) do
        if item.kind == 'K' then
            local number = 0
            for line in (item.content .. '\n'):gmatch('(.-)\n') do
                number = number + 1
                if line:find('TODO', 1, true) or line:find('FIXME', 1, true) then
                    labels[#labels + 1] = i .. ':' .. number .. ' ' .. item.title
                    markers[#markers + 1] = line
                end
            end
        elseif item.kind == 'S' then
            labels[#labels + 1] = i .. ': заготовка ' .. item.title
            markers[#markers + 1] = 'Функция пока не реализована: ' .. item.content
        end
    end
    if #markers == 0 then notify('Маркеры TODO/FIXME и заготовки не найдены.') return end
    local selected = gg.choice(labels, nil, 'Найдено: ' .. #markers)
    if selected then notify(markers[selected]) end
end
local function source_tools()
    local c = gg.choice({'Пакетная замена в Lua-блоках', 'Список TODO / FIXME и заготовок', 'Импорт пунктов другого проекта'}, nil, 'Инструменты исходного кода')
    if c == 1 then replace_code_text() elseif c == 2 then inspect_code_markers() elseif c == 3 then import_project_items() end
end
local function tools_menu()
    local c = gg.choice({'Диагностика GG и доступа к файлам', 'Отчёт о проекте', 'Резервная копия проекта', 'Импорт Lua-кода из файла', 'Библиотека шаблонов', 'Проверка проекта', 'Справочник разработчика', 'Лаборатория разработчика', 'Мастерская проекта', 'Задачи проекта', 'Исходный код и импорт'}, nil, 'Инструменты')
    if c == 1 then diagnostics() elseif c == 2 then project_report() elseif c == 3 then backup_project() elseif c == 4 then import_lua_action() elseif c == 5 then insert_template() elseif c == 6 then validate_project() elseif c == 7 then reference_menu() elseif c == 8 then developer_lab() elseif c == 9 then project_workbench() elseif c == 10 then task_manager() elseif c == 11 then source_tools() end
end

while true do
    local title = 'GG Developer Studio ' .. VERSION .. '\n' .. (project and ('Проект: ' .. project.title .. ' [' .. project_id .. ']' .. ((saved_snapshot == nil or saved_snapshot ~= project_data(project)) and ' *' or '')) or 'Проект не открыт')
    local choice = gg.choice({'Создать проект', 'Открыть проект по ID', 'Добавить пункт меню', 'Управлять пунктами', 'Настройки проекта', 'Предпросмотр меню', 'Сохранить проект', 'Собрать Lua-скрипт', 'Инструменты', 'Справка', 'Выход'}, nil, title)
    if not choice or choice == 11 then
        if confirm_discard() then break end
    elseif choice == 1 then new_project()
    elseif choice == 2 then open_project()
    elseif choice == 3 then add_item()
    elseif choice == 4 then manage_items()
    elseif choice == 5 then project_settings()
    elseif choice == 6 then preview()
    elseif choice == 7 then save_project()
    elseif choice == 8 then build()
    elseif choice == 9 then tools_menu()
    elseif choice == 10 then notify('Папка: ' .. root .. '\nСоздайте проект, добавьте пункты, сохраните проект и соберите Lua-файл.\nПоиск очищает предыдущие результаты после подтверждения. Предпросмотр не запускает действия.\nРучные изменения готового файла перезаписываются при повторной сборке.') end
end
