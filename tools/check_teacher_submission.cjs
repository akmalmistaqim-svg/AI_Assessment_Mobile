const {chromium}=require('D:/DeXa_Assessment_fik/ai-assessment-copilot/node_modules/@playwright/test');
const fs=require('node:fs'),path=require('node:path');
const root=path.resolve(__dirname,'..'),out=path.join(root,'docs/evidence');
const qa=JSON.parse(fs.readFileSync(path.join(out,'submission-live-result.json'),'utf8').replace(/^\uFEFF/,''));
(async()=>{const browser=await chromium.launch({channel:'chrome',headless:true});const page=await browser.newPage({viewport:{width:1440,height:1000}});const errors=[];page.on('pageerror',e=>errors.push(e.message));
try {
 await page.goto('http://127.0.0.1:3000/login',{waitUntil:'networkidle',timeout:120000});
 await page.locator('input[type=email]').fill('dosen_a@test.local');await page.locator('input[type=password]').fill(process.env.DEXA_QA_TEACHER_PASSWORD);await page.locator('button[type=submit]').click();await page.waitForURL('**/dashboard',{timeout:90000});
 const taskUrl=`http://127.0.0.1:3000/classes/${qa.classId}/assignments/${qa.assignmentId}`;
 await page.goto(taskUrl,{waitUntil:'networkidle',timeout:120000});await page.getByText('teskelas',{exact:true}).waitFor();await page.getByText(/teskelas-jawaban.pdf/).waitFor();
 await page.screenshot({path:path.join(out,'teacher-mobile-submission.png'),fullPage:true});
 await page.getByRole('link',{name:'Koreksi AI',exact:true}).click();await page.waitForURL(`**/submissions/${qa.submissionId}`,{timeout:90000});await page.getByText('DEXA_MOBILE_QA_PDF_20261101',{exact:false}).first().waitFor({timeout:90000});
 await page.screenshot({path:path.join(out,'teacher-mobile-answer.png'),fullPage:true});
 if(errors.length)throw new Error('Browser runtime errors: '+errors.join(';'));
 const result={teacherLogin:true,studentVisible:'teskelas',fileName:'teskelas-jawaban.pdf',answerMarkerVisible:true,submissionId:qa.submissionId,pageErrors:errors,aiGradingTriggered:false};fs.writeFileSync(path.join(out,'teacher-mobile-submission-result.json'),JSON.stringify(result,null,2));console.log(JSON.stringify(result));
} catch(e){console.error(e.message);if(!page.url().includes('/login'))await page.screenshot({path:path.join(out,'teacher-mobile-submission-failure.png'),fullPage:true}).catch(()=>{});process.exitCode=1;}finally{await browser.close();}})();
