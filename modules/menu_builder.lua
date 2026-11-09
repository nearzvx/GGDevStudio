return {name='☷ Menu Builder · список в меню',run=function(ctx)
 local p=gg.prompt({'Путь к TXT: один пункт на строку','Заголовок меню'},{ctx.root..'/menu.txt','Выберите пункт'},{'file','text'});if not p then return end
 local data,e=ctx.read_file(tostring(p[1] or ''),65536);if not data then ctx.alert('Ошибка чтения: '..tostring(e));return end
 local out={'local options = {'};local count=0
 for raw in (data..'\n'):gmatch('(.-)\n') do local line=raw:gsub('\r$','');if line:match('%S') then count=count+1;if count>100 then ctx.alert('Максимум 100 пунктов.');return end;out[#out+1]='  '..string.format('%q',line)..',' end end
 if count==0 then ctx.alert('Список пуст.');return end
 out[#out+1]='}';out[#out+1]='local selected = gg.choice(options, nil, '..string.format('%q',tostring(p[2] or 'Меню'))..')';out[#out+1]='if not selected then return end';out[#out+1]='gg.alert("Выбран пункт: " .. tostring(options[selected]))'
 ctx.offer_code('Меню из списка',table.concat(out,'\n'),'Пунктов: '..count..'. Измени действия после вставки.')
end}
