return {name='☰ Project Outline · структура проекта',run=function(ctx)
 local p=ctx.project;if not p then ctx.alert('Откройте проект.');return end
 local out={'# '..p.title,'Версия: '..p.version,'','## Пункты'}
 for i,v in ipairs(p.items) do out[#out+1]=i..'. ['..v.kind..'] '..v.title end
 if #p.items==0 then out[#out+1]='Пустой проект.' end
 ctx.report(table.concat(out,'\n'))
end}
