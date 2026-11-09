return {name='≡ Line Review · длинные строки',run=function(ctx)
 local p=ctx.project;if not p then ctx.alert('Откройте проект.');return end
 local v=gg.prompt({'Порог длины строки в байтах'},{'120'},{'number'});if not v then return end
 local limit=tonumber(v[1]);if not limit or limit<1 or limit>100000 then ctx.alert('Введите число от 1 до 100000.');return end
 local out={'≡ LINE REVIEW','Длина в байтах; UTF-8 символ может занимать несколько байтов.',''};local total=0
 for i,item in ipairs(p.items) do if item.kind=='K' then local n=0 for line in ((item.content or '')..'\n'):gmatch('(.-)\n') do n=n+1;if #line>limit then total=total+1;if total<=100 then out[#out+1]=i..':'..n..' · '..#line..' байт · '..item.title end end end end end
 out[#out+1]='\nСтрок: '..total..(total>100 and ' (первые 100)' or '');ctx.report(table.concat(out,'\n'))
end}
