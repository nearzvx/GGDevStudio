return {name='✓ Syntax Batch · проверка блоков',run=function(ctx)
 local p=ctx.project;if not p then ctx.alert('Откройте проект.');return end
 local compiler=loadstring or load;if type(compiler)~='function' then ctx.alert('Компилятор недоступен.');return end
 local n,fail,out=0,0,{'✓ SYNTAX BATCH','Проверяется синтаксис каждого Lua-блока без выполнения.',''}
 for i,v in ipairs(p.items) do if v.kind=='K' then n=n+1;local ok,fn,e=pcall(compiler,'return function()\n'..(v.content or '')..'\nend');if not ok or not fn then fail=fail+1;out[#out+1]=i..' · '..v.title..'\n'..tostring(ok and e or fn) end end end
 out[#out+1]='Блоков: '..n..' · Ошибок: '..fail..'\nСинтаксическая проверка не гарантирует правильную работу.';ctx.report(table.concat(out,'\n'))
end}
