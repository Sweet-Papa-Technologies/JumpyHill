// Upload actual game captures to the existing draft listing; never submit production.
import {apple} from './apple-api.mjs';
import {readFile,writeFile} from 'node:fs/promises';
import {createHash} from 'node:crypto';
const appId='6809527457';
const versions=(await apple(`apps/${appId}/appStoreVersions`)).data;
const version=versions.find(v=>v.attributes.appStoreState==='PREPARE_FOR_SUBMISSION');
if(!version) throw Error('Expected an editable TreadFall listing.');
const localization=(await apple(`appStoreVersions/${version.id}/appStoreVersionLocalizations`)).data.find(l=>l.attributes.locale==='en-US');
if(!localization) throw Error('Missing English localization.');
const specs=[['APP_IPHONE_67','iphone',['01-meadow','02-coral','03-ember','04-title']],['APP_IPAD_PRO_3GEN_129','ipad',['01-meadow','02-coral']]];
const receipt=[];
for(const [type,folder,files] of specs){
 let set=(await apple(`appStoreVersionLocalizations/${localization.id}/appScreenshotSets`)).data.find(s=>s.attributes.screenshotDisplayType===type);
 if(!set) ({data:set}=await apple('appScreenshotSets','POST',{data:{type:'appScreenshotSets',attributes:{screenshotDisplayType:type},relationships:{appStoreVersionLocalization:{data:{type:'appStoreVersionLocalizations',id:localization.id}}}}}));
 const existing=(await apple(`appScreenshotSets/${set.id}/appScreenshots`)).data;
 for(const name of files){
  const fileName=name+'.png';
  let screenshot=existing.find(s=>s.attributes.fileName===fileName&&s.attributes.assetDeliveryState?.state==='COMPLETE');
  if(!screenshot){
   const content=await readFile(`build/store/screenshots/${folder}/${fileName}`);
   ({data:screenshot}=await apple('appScreenshots','POST',{data:{type:'appScreenshots',attributes:{fileName,fileSize:content.length},relationships:{appScreenshotSet:{data:{type:'appScreenshotSets',id:set.id}}}}}));
   for(const operation of screenshot.attributes.uploadOperations){
    const response=await fetch(operation.url,{method:operation.method,headers:Object.fromEntries(operation.requestHeaders.map(h=>[h.name,h.value])),body:content.subarray(operation.offset,operation.offset+operation.length)});
    if(!response.ok) throw Error(`Screenshot asset upload failed: ${response.status}`);
   }
   await apple(`appScreenshots/${screenshot.id}`,'PATCH',{data:{type:'appScreenshots',id:screenshot.id,attributes:{uploaded:true,sourceFileChecksum:createHash('md5').update(content).digest('hex')}}});
  }
  receipt.push({type,fileName,id:screenshot.id});console.log('Uploaded',type,fileName,screenshot.id);
 }
}
await writeFile('build/store/apple-screenshots-receipt.json',JSON.stringify(receipt,null,2));
