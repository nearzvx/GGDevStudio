return {name='⌕ Code Search · поиск по коду',run=function(ctx)
 local p=ctx.project;if not p then ctx.alert('Откройте проект.');return end
 local v=gg.prompt({'Точный текст для поиска (с учётом регистра)'},{''},{'text'});if not v then return end
 local term=tostring(v[1] or '');if term=='' then ctx.alert('Введите текст.');return end
 local out={'⌕ CODE SEARCH · '..term,''};local total=0
 for i,item in ipairs(p.items) do if item.kind=='K' then local n=0 for line in ((item.content or '')..'\n'):gmatch('(.-)\n') do n=n+1;if line:find(term,1,true) then total=total+1;if total<=100 then out[#out+1]=i..':'..n..' · '..item.title..'\n'..line:sub(1,200) end end end end end
 out[#out+1]='\nВсего строк: '..total..(total>100 and ' (показаны первые 100)' or '')
 ctx.report(table.concat(out,'\n'))
end}
