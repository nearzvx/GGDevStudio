return {name='🌐 Language Pack · TSV → Lua',run=function(ctx)
 local p=gg.prompt({'Путь к TSV: ключ, язык, текст (через табуляцию)', 'Язык для примера (например en)'}, {ctx.root..'/translations.tsv','en'}, {'file','text'})
 if not p then return end
 local data,e=ctx.read_file(tostring(p[1] or ''),262144);if not data then ctx.alert('Ошибка чтения: '..tostring(e));return end
 if data:sub(1,3)=='\239\187\191' then data=data:sub(4) end
 local languages,order,seen={}, {}, {};local n=0
 for rawline in (data..'\n'):gmatch('(.-)\n') do
  n=n+1;local line=rawline:gsub('\r$','')
  if line~='' and line:sub(1,1)~='#' then
   local key,lang,text=line:match('^([^\t]+)\t([^\t]+)\t([^\t]*)$')
   if not key or not lang:match('^[A-Za-z][A-Za-z0-9_-]*$') then ctx.alert('Ошибка TSV в строке '..n..'. Формат: ключ<TAB>язык<TAB>текст');return end
   local ident=lang..'\0'..key;if seen[ident] then ctx.alert('Дублирующийся ключ и язык в строке '..n);return end;seen[ident]=true
   if not languages[lang] then languages[lang]={};order[#order+1]=lang end
   languages[lang][#languages[lang]+1]={key,text}
  end
 end
 if #order==0 then ctx.alert('Нет данных.');return end
 table.sort(order);local code={'local translations = {'}
 for _,lang in ipairs(order) do code[#code+1]='  ['..string.format('%q',lang)..'] = {';for _,v in ipairs(languages[lang]) do code[#code+1]='    ['..string.format('%q',v[1])..'] = '..string.format('%q',v[2])..',' end;code[#code+1]='  },' end
 local selected=tostring(p[2] or 'en');code[#code+1]='}'
 code[#code+1]='local language = '..string.format('%q',selected)
 code[#code+1]='local function tr(key) return (translations[language] or {})[key] or key end'
 code[#code+1]='-- Пример: gg.alert(tr("hello"))'
 ctx.offer_code('Переводы проекта',table.concat(code,'\n'),'Языков: '..#order..'. Ключи и тексты сохранены как данные. Код не выполнялся.')
end}
