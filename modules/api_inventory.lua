return {name='⚙ API Inventory · вызовы GG',run=function(ctx)
 local p=ctx.project;if not p then ctx.alert('Откройте проект.');return end
 local count={};for _,v in ipairs(p.items) do if v.kind=='K' then for name in (v.content or ''):gmatch('gg%.([A-Za-z_][A-Za-z0-9_]*)%s*%(') do count[name]=(count[name] or 0)+1 end end end
 local names={} for name in pairs(count) do names[#names+1]=name end;table.sort(names)
 local out={'⚙ API INVENTORY','Поиск текстовых gg.name(...); возможны ложные совпадения и пропуски.',''};for _,name in ipairs(names) do out[#out+1]='gg.'..name..'  ·  '..count[name] end;if #names==0 then out[#out+1]='Вызовы не найдены.' end
 ctx.report(table.concat(out,'\n'))
end}
