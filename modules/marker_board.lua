return {name='☷ Marker Board · комментарии задач',run=function(ctx)
 local p=ctx.project;if not p then ctx.alert('Откройте проект.');return end
 local out={'☷ MARKER BOARD','Поиск по тексту TODO, FIXME, NOTE, HACK.',''};local count=0
 for i,v in ipairs(p.items) do if v.kind=='K' then local n=0;for line in ((v.content or '')..'\n'):gmatch('(.-)\n') do n=n+1;if line:find('TODO',1,true) or line:find('FIXME',1,true) or line:find('NOTE',1,true) or line:find('HACK',1,true) then count=count+1;if count<=100 then out[#out+1]=i..':'..n..' · '..v.title..'\n'..line:sub(1,180) end end end end end
 out[#out+1]='\nВсего: '..count..(count>100 and ' (первые 100)' or '');ctx.report(table.concat(out,'\n'))
end}
