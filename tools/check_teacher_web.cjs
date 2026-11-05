// Browser QA only: login with existing teacher fixture; never seed or submit work.
const { chromium }=require('D:/DeXa_Assessment_fik/ai-assessment-copilot/node_modules/@playwright/test');
const fs=require('node:fs');
const path=require('node:path');
const root=path.resolve(__dirname,'..');
const data=JSON.parse(fs.readFileSync(path.join(root,'.local/teskelas.json'),'utf8'));
const out=path.join(root,'docs/evidence');
(async()=>{
 const browser=await chromium.launch({channel:'chrome',headless:true});
 const context=await browser.newContext({viewport:{width:1440,height:1000}});
 const page=await context.newPage();
 const errors=[];
 page.on('pageerror',err=>errors.push(err.message));
 const base='http://127.0.0.1:3000';
 try {
  await page.goto(base+'/login',{waitUntil:'networkidle',timeout:120000});
  await page.locator('input[type="email"]').fill('dosen_a@test.local');
  await page.locator('input[type="password"]').fill(process.env.DEXA_QA_TEACHER_PASSWORD);
  await page.locator('button[type="submit"]').click();
  await page.waitForURL('**/dashboard',{timeout:90000});
  await page.getByText('Antrean koreksi',{exact:true}).waitFor({timeout:90000});
  await page.screenshot({path:path.join(out,'teacher-class-live-dashboard.png'),fullPage:true});
  const dashboard=await page.locator('body').innerText();
  if(/belum dapat dimuat|gagal memuat|layanan tidak tersedia/i.test(dashboard)) throw new Error('Teacher dashboard reported load failure');
  await page.goto(base+'/classes/'+data.DEXA_QA_CLASS_ID,{waitUntil:'networkidle',timeout:120000});
  await page.getByRole('tab',{name:/Mahasiswa/}).click();
  await page.getByText('teskelas',{exact:true}).waitFor({timeout:30000});
  await page.screenshot({path:path.join(out,'teacher-class-live-members.png'),fullPage:true});
  const detail=await page.request.get(base+'/api/classes/'+data.DEXA_QA_CLASS_ID);
  if(detail.status()!==200) throw new Error('Teacher class API HTTP '+detail.status());
  const cls=await detail.json();
  const member=cls.enrollments.filter(e=>e.user?.email===data.DEXA_QA_EMAIL);
  if(member.length!==1) throw new Error('Expected exactly one teskelas enrollment');
  const report={teacherLogin:'passed',dashboard:'visible',className:cls.name,studentVisible:'teskelas',membershipCount:member.length,totalMembers:cls.enrollments.length,assignments:cls.assignments.map(a=>({title:a.title,submissionCount:a._count?.submissions})),pageErrors:errors,uploadFromMobile:'not implemented; no submission performed'};
  fs.writeFileSync(path.join(out,'teacher-class-live-result.json'),JSON.stringify(report,null,2));
  console.log(JSON.stringify(report));
 } catch(error) {
  // Do not screenshot a failed login with credentials populated.
  if(!page.url().includes('/login')) await page.screenshot({path:path.join(out,'teacher-class-live-failure.png'),fullPage:true}).catch(()=>{});
  console.error(error.message);process.exitCode=1;
 } finally { await browser.close(); }
})();
