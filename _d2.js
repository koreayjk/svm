const {chromium}=require('playwright');
const out=process.argv[2]||'/tmp/d1';require('fs').mkdirSync(out,{recursive:true});
const W=+process.argv[3]||1440,H=+process.argv[4]||900;
const routes=(process.argv[5]||'home,countries,countries/KR,community,rooms/KR,train,my,admin,feed,events').split(',');
(async()=>{const b=await chromium.launch();const p=await b.newPage({viewport:{width:W,height:H}});
const errs=[];p.on('pageerror',e=>errs.push(e.message));
await p.goto('http://localhost:8127/app/?demo');await p.waitForTimeout(1200);
await p.fill('input[name=name]','Admin Tester');await p.fill('input[name=email]','a@test.com');await p.fill('input[name=password]','password123');await p.check('input[name=agree]');
await p.click('#auth-form button[type=submit]');await p.waitForTimeout(2500);
let i=1;for(const r of routes){await p.evaluate(h=>{location.hash='#/'+h},r);await p.waitForTimeout(1300);
 await p.screenshot({path:`${out}/${String(i).padStart(2,'0')}-${r.replace(/\//g,'_')}.png`});i++}
console.log(errs.slice(0,3));await b.close()})()
