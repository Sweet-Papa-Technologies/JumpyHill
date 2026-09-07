// Fill the new game's English listing and attach its captured gameplay artwork.
import {readFile} from 'node:fs/promises';
import {api} from './play-api.mjs';
const listing={language:'en-US',title:'TreadFall',shortDescription:'Pick your angle. Bank off glass. Roll through 33 playful downhill courses.',fullDescription:'One tire. One launch angle. A whole hill of possibilities.\n\nRead the terrain and send your tire through 33 downhill courses across four colorful worlds. Roll over crests, jump side gaps, time moving obstacles and use boost, ice, mud and spring surfaces. Bank gently off glass walls or smash through with enough speed.\n\nStart in tire view and switch to course view to plan your route. Fine-tune your launch angle, roll, and use two optional nudges to rescue a tricky line. Earn stars and style points, unlock tires and try a daily seeded challenge.\n\nNo countdown cuts a good roll short. Progress and settings stay on your device. No ads or account required.'};
const edit=await api('edits','POST',{});let committed=false;
try{
 await api(`edits/${edit.id}/listings/en-US`,'PUT',listing);
 const details=await api(`edits/${edit.id}/details`);
 await api(`edits/${edit.id}/details`,'PUT',{...details,defaultLanguage:'en-US',contactEmail:'fterry@sweetpapatechnologies.com'});
 for(const [type,files] of [['icon',['icon.png']],['featureGraphic',['feature-graphic.png']],['phoneScreenshots',['android/01-first-person.png','android/03-course-view.png','android/04-roll.png']]]){
  const existing=await api(`edits/${edit.id}/listings/en-US/${type}`);
  if(existing.images?.length) throw Error(`Existing ${type} images found; refusing to replace without review.`);
  for(const file of files){const result=await api(`edits/${edit.id}/listings/en-US/${type}?uploadType=media`,'POST',await readFile(`build/store/screenshots/${file}`),true,'image/png');console.log(JSON.stringify({type,file,id:result.image?.id}));}
 }
 await api(`edits/${edit.id}:commit`,'POST');committed=true;console.log('GOOGLE PLAY LISTING AND SCREENSHOTS SAVED');
}finally{if(!committed)await api(`edits/${edit.id}`,'DELETE').catch(()=>{});}
