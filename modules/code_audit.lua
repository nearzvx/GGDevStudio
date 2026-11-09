return {name='◇ Code Audit · обзор рисков',run=function(ctx)
 local p=ctx.project;if not p then ctx.alert('Откройте проект.');return end
 local checks={{'os.execute','внешние команды'},{'io.popen','процессы'},{'loadstring','динамический код'},{'load(','динамический код'},{'loadfile','загрузка кода'},{'dofile','запуск файла'},{'gg.makeRequest','сеть'},{'io.open','работа с файлом'},{'gg.editAll','изменение значений'},{'gg.clearResults','очистка результатов'},{'gg.setValues','запись значений'}}
 local findings={};local total=0
 for i,item in ipairs(p.items) do if item.kind=='K' then
  local n=0;for line in ((item.content or '')..'\n'):gmatch('(.-)\n') do n=n+1
   for _,c in ipairs(checks) do if line:find(c[1],1,true) then total=total+1;if #findings<100 then findings[#findings+1]=i..':'..n..' · '..c[2]..' ('..c[1]..') · '..item.title end end end
  end
 end end
 local text='◇ CODE AUDIT\nСовпадений: '..total..'\nЭто поиск по тексту, не полноценный анализ безопасности: возможны ложные срабатывания и пропуски.\n\n'..(#findings>0 and table.concat(findings,'\n') or 'Совпадений не найдено.')
 if total>#findings then text=text..'\nПоказаны первые '..#findings end
 ctx.report(text)
end}
