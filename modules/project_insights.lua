return {name='◈ Project Insights · метрики', run=function(ctx)
 local p=ctx.project
 if not p then ctx.alert('Откройте проект.');return end
 local counts,bytes,lines,markers={K=0,S=0},0,0,0
 local ranked={}
 for i,item in ipairs(p.items) do
  counts[item.kind]=(counts[item.kind] or 0)+1
  local text=item.content or '';bytes=bytes+#text
  local n=0
  if #text>0 then n=1;for _ in text:gmatch('\n') do n=n+1 end end
  lines=lines+n;ranked[#ranked+1]={index=i,title=item.title,lines=n}
  for line in (text..'\n'):gmatch('(.-)\n') do if line:find('TODO',1,true) or line:find('FIXME',1,true) then markers=markers+1 end end
 end
 table.sort(ranked,function(a,b) if a.lines==b.lines then return a.index<b.index end return a.lines>b.lines end)
 local out={'◈ PROJECT INSIGHTS',p.title..' · v'..p.version,'Пунктов: '..#p.items,'Lua-блоков: '..(counts.K or 0)..' · заготовок: '..(counts.S or 0),'Байтов: '..bytes..' · строк: '..lines,'Строк с TODO/FIXME: '..markers,'','Крупнейшие блоки:'}
 for i=1,math.min(5,#ranked) do local x=ranked[i];out[#out+1]=x.index..'. '..x.title..' — '..x.lines..' строк' end
 ctx.report(table.concat(out,'\n'))
end}
