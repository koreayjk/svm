const {chromium}=require('playwright');
(async()=>{const b=await chromium.launch();
const p=await b.newPage({viewport:{width:1440,height:900}});
await p.goto('http://localhost:8127/app/?demo');await p.waitForTimeout(1500);
await p.screenshot({path:'/tmp/d2/auth.png'});
await p.fill('input[name=name]','Admin Tester');await p.fill('input[name=email]','a@test.com');await p.fill('input[name=password]','password123');await p.check('input[name=agree]');
await p.click('#auth-form button[type=submit]');await p.waitForTimeout(2500);
await p.evaluate(()=>{location.hash='#/learn/KR'});await p.waitForTimeout(1500);await p.screenshot({path:'/tmp/d2/learn.png'});
await p.evaluate(()=>{location.hash='#/apply/KR'});await p.waitForTimeout(1500);await p.screenshot({path:'/tmp/d2/apply.png'});
await p.evaluate(()=>{location.hash='#/network'});await p.waitForTimeout(1500);await p.screenshot({path:'/tmp/d2/network.png'});
await p.evaluate(()=>{location.hash='#/rooms/KR'});await p.waitForTimeout(1200);await p.click('text=Join this room').catch(()=>{});await p.waitForTimeout(1200);await p.screenshot({path:'/tmp/d2/room.png'});
await b.close()})()
