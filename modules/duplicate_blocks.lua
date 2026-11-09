return {name='▣ Duplicate Blocks · повторы кода',run=function(ctx)
 local p=ctx.project;if not p then ctx.alert('Откройте проект.');return end
 local seen,out={},{};for i,v in ipairs(p.items) do if v.kind=='K' and v.content and v.content~='' then if seen[v.content] then out[#out+1]=i..' · '..v.title..' = пункт '..seen[v.content] else seen[v.content]=i end end end
 ctx.report('▣ DUPLICATE BLOCKS\nТочные совпадения Lua-блоков.\n\n'..(#out>0 and table.concat(out,'\n') or 'Повторов не найдено.'))
end}
