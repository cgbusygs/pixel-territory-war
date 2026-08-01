const port=Number(process.argv[2]||9229);
const targetUrl=process.argv[3]||'';
const wait=ms=>new Promise(resolve=>setTimeout(resolve,ms));
let stopping=false;
let socket=null;

async function findPage(){
  const response=await fetch(`http://127.0.0.1:${port}/json/list`);
  if(!response.ok)throw new Error(`Chrome DevTools HTTP ${response.status}`);
  const pages=await response.json();
  return pages.find(page=>page.type==='page'&&page.url.includes('autoRecord=1'))||pages.find(page=>page.type==='page');
}

async function keepPageActive(){
  while(!stopping){
    try{
      const page=await findPage();
      if(!page){await wait(1000);continue;}
      const current=new WebSocket(page.webSocketDebuggerUrl);
      socket=current;
      await new Promise((resolve,reject)=>{
        current.addEventListener('open',resolve,{once:true});
        current.addEventListener('error',reject,{once:true});
      });
      current.send(JSON.stringify({id:1,method:'Emulation.setFocusEmulationEnabled',params:{enabled:true}}));
      current.send(JSON.stringify({id:2,method:'Page.setWebLifecycleState',params:{state:'active'}}));
      if(targetUrl&&page.url!=='about:blank'&&page.url!==targetUrl){
        current.send(JSON.stringify({id:3,method:'Page.navigate',params:{url:targetUrl}}));
      }else if(targetUrl&&page.url==='about:blank'){
        current.send(JSON.stringify({id:3,method:'Page.navigate',params:{url:targetUrl}}));
      }
      await new Promise(resolve=>current.addEventListener('close',resolve,{once:true}));
    }catch{}
    if(socket){try{socket.close();}catch{}socket=null;}
    await wait(500);
  }
}

process.on('SIGINT',()=>{stopping=true;try{socket?.close();}catch{}});
process.on('SIGTERM',()=>{stopping=true;try{socket?.close();}catch{}});
keepPageActive();
