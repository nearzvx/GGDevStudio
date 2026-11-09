return {name='◈ Title Check · повторы названий',run=function(ctx)
 local p=ctx.project;if not p then ctx.alert('Откройте проект.');return end
 local seen,items={},{};for i,v in ipairs(p.items) do local title=v.title or '';if title=='' then items[#items+1]=i..' · пустое название' elseif seen[title] then items[#items+1]=i..' · повтор пункта '..seen[title]..' · '..title else seen[title]=i end end
 ctx.report('◈ TITLE CHECK\nПроверка точных совпадений с учётом регистра.\n\n'..(#items>0 and table.concat(items,'\n') or 'Пустых и повторяющихся названий нет.'))
end}
