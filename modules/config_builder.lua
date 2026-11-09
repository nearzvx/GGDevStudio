return {name='⚑ Config Builder · настройки',run=function(ctx)
 local p=gg.prompt({'Путь к TXT с настройками key=value','Имя таблицы Lua'},{ctx.root..'/config.txt','config'},{'file','text'});if not p then return end
 local name=tostring(p[2] or '');local keywords={['and']=1,['break']=1,['do']=1,['else']=1,['elseif']=1,['end']=1,['false']=1,['for']=1,['function']=1,['if']=1,['in']=1,['local']=1,['nil']=1,['not']=1,['or']=1,['repeat']=1,['return']=1,['then']=1,['true']=1,['until']=1,['while']=1}
 if not name:match('^[A-Za-z_][A-Za-z0-9_]*$') or keywords[name] then ctx.alert('Некорректное имя таблицы.');return end
 local data,e=ctx.read_file(tostring(p[1] or ''),131072);if not data then ctx.alert('Ошибка чтения: '..tostring(e));return end
 local out={'local '..name..' = {'};local n=0;local seen={};local count=0
 for raw in (data..'\n'):gmatch('(.-)\n') do n=n+1;local line=raw:gsub('\r$','')
  if line~='' and not line:match('^%s*#') then local key,value=line:match('^%s*([A-Za-z_][A-Za-z0-9_]*)%s*=(.*)$');if not key then ctx.alert('Ошибка в строке '..n);return end;if seen[key] then ctx.alert('Повтор ключа в строке '..n);return end;seen[key]=true;count=count+1;out[#out+1]='  ['..string.format('%q',key)..'] = '..string.format('%q',value)..',' end
 end
 out[#out+1]='}';out[#out+1]='-- Используйте '..name..' в этом блоке.'
 ctx.offer_code('Конфигурация: '..name,table.concat(out,'\n'),'Настроек: '..count..'. Все значения — строки.')
end}
