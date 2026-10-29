const {chromium}=require('playwright');
const out=process.argv[2]||'/tmp/d0';require('fs').mkdirSync(out,{recursive:true});
(async()=>{const b=await chromium.launch();const p=await b.newPage({viewport:{width:1440,height:900}});
const errs=[];p.on('pageerror',e=>errs.push(e.message));
await p.goto('http://localhost:8127/app/?demo');await p.waitForTimeout(1200);
await p.fill('input[name=name]','Admin Tester');await p.fill('input[name=email]','a@test.com');await p.fill('input[name=password]','password123');await p.check('input[name=agree]');
await p.click('#auth-form button[type=submit]');await p.waitForTimeout(2500);
await p.screenshot({path:out+'/00-auth-or-home.png'});
const routes=['home','countries','countries/KR','feed','community','rooms/KR','train','my','events','admin','prayers','lead','field','network','conference','plans','testimonies','support','teams','apps'];
let i=1;for(const r of routes){await p.evaluate(h=>{location.hash='#/'+h},r);await p.waitForTimeout(1300);
 await p.screenshot({path:`${out}/${String(i).padStart(2,'0')}-${r.replace(/\//g,'_')}.png`});i++}
console.log(errs.slice(0,3));await b.close()})()
