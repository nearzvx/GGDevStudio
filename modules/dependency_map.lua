return {name='⌘ Dependency Map · зависимости',run=function(ctx)
 local p=ctx.project;if not p then ctx.alert('Откройте проект.');return end
 local found,order={},{}
 for i,item in ipairs(p.items) do if item.kind=='K' then
  local n=0
  for line in ((item.content or '')..'\n'):gmatch('(.-)\n') do n=n+1
   local name=line:match('require%s*%(%s*["\']([^"\']+)["\']%s*%)') or line:match('require%s+["\']([^"\']+)["\']')
   if name then if not found[name] then found[name]={};order[#order+1]=name end; found[name][#found[name]+1]=i..':'..n end
  end
 end end
 table.sort(order);local result={'⌘ DEPENDENCY MAP','Только буквальные require; комментарии и строки могут дать ложные совпадения. Динамические имена не отслеживаются.',''}
 for _,name in ipairs(order) do result[#result+1]=name..'  →  '..table.concat(found[name],', ') end
 if #order==0 then result[#result+1]='Зависимости не найдены.' end
 ctx.report(table.concat(result,'\n'))
end}
