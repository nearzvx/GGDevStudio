return {name='▦ CSV → Lua таблица',run=function(ctx)
 local p=gg.prompt({'Путь к CSV-файлу (UTF-8)', 'Имя локальной переменной'}, {ctx.root..'/data.csv','data'}, {'file','text'})
 if not p then return end
 local name=tostring(p[2] or '')
 if not name:match('^[A-Za-z_][A-Za-z0-9_]*$') or ({['and']=1,['break']=1,['do']=1,['else']=1,['elseif']=1,['end']=1,['false']=1,['for']=1,['function']=1,['if']=1,['in']=1,['local']=1,['nil']=1,['not']=1,['or']=1,['repeat']=1,['return']=1,['then']=1,['true']=1,['until']=1,['while']=1})[name] then ctx.alert('Некорректное имя переменной.');return end
 local s,e=ctx.read_file(tostring(p[1] or ''),262144);if not s then ctx.alert('Ошибка чтения: '..tostring(e));return end
 if s:sub(1,3)=='\239\187\191' then s=s:sub(4) end
 local rows,row,field={}, {}, {};local i=1;local state='start'
 local function cell() row[#row+1]=table.concat(field);field={} end
 local function line() cell();rows[#rows+1]=row;row={} end
 while i<=#s do
  local c=s:sub(i,i)
  if state=='quoted' then
   if c=='"' then if s:sub(i+1,i+1)=='"' then field[#field+1]='"';i=i+1 else state='closed' end else field[#field+1]=c end
  elseif c==',' then cell();state='start'
  elseif c=='\r' or c=='\n' then line();state='start';if c=='\r' and s:sub(i+1,i+1)=='\n' then i=i+1 end
  elseif c=='"' and state=='start' then state='quoted'
  elseif state=='closed' or c=='"' then ctx.alert('Некорректный CSV около байта '..i);return
  else field[#field+1]=c;state='plain' end
  i=i+1
 end
 if state=='quoted' then ctx.alert('Незакрытые кавычки CSV.');return end
 if #s>0 and s:sub(-1)~='\n' and s:sub(-1)~='\r' then line() end
 if #rows>5000 then ctx.alert('Слишком много строк CSV (максимум 5000).');return end
 local code={'local '..name..' = {'}
 for _,r in ipairs(rows) do local cells={} for _,value in ipairs(r) do cells[#cells+1]=string.format('%q',value) end;code[#code+1]='  {'..table.concat(cells,', ')..'},' end
 code[#code+1]='}';code[#code+1]='-- Используйте '..name..' в этом Lua-блоке.'
 ctx.offer_code('CSV: '..name,table.concat(code,'\n'),'Строк: '..#rows..'. Значения сохранены как строки. Код не выполнялся.')
end}
