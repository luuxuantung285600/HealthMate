import {text} from './validation.mjs';
export const exerciseRegions={chest:'Ngực',back:'Lưng',legs:'Chân',shoulders:'Vai',arms:'Tay',core:'Bụng',cardio:'Tim mạch'};
export const exerciseEquipment={bodyweight:'Trọng lượng cơ thể',dumbbell:'Tạ đơn',barbell:'Tạ đòn',cable:'Cáp',machine:'Máy',band:'Dây kháng lực',kettlebell:'Tạ chuông'};
export const exerciseSource=row=>row.sourceProvider??'exercisedb';
export const exerciseMediaCredit=()=> 'AscendAPI / ExerciseDB · GIF 180p';
export function exerciseId(value){if(typeof value!=='string'||! /^[a-zA-Z0-9_-]{1,100}$/.test(value))throw Error('Mã bài tập: 1–100 chữ, số, gạch ngang hoặc gạch dưới.');return value;}
export function exercisePayload(input){
  const provider=exerciseSource(input);
  if(provider!=='exercisedb')throw Error('HealthMate chỉ sử dụng minh họa ExerciseDB.');
  if(typeof input.sourceId!=='string'||! /^[a-zA-Z0-9]{7}$/.test(input.sourceId))throw Error('Mã ExerciseDB cần đúng 7 chữ hoặc số.');
  if(!Object.hasOwn(exerciseRegions,input.region)||!Object.hasOwn(exerciseEquipment,input.equipment))throw Error('Nhóm cơ hoặc dụng cụ không hợp lệ.');
  const steps=Array.isArray(input.steps)?input.steps:String(input.steps??'').split('\n').map(s=>s.trim()).filter(Boolean);
  if(steps.length<2||steps.length>6||steps.some(s=>typeof s!=='string'||!s.trim()||s.length>400))throw Error('Hướng dẫn cần 2–6 bước, tối đa 400 ký tự mỗi bước.');
  if(typeof input.isActive!=='boolean')throw Error('Trạng thái hiển thị không hợp lệ.');
  return {name:text(input.name,'Tên bài tập',120),sourceId:input.sourceId,...(input.sourceProvider?{sourceProvider:provider}:{}),region:input.region,equipment:input.equipment,target:text(input.target,'Cơ tác động',160),steps:steps.map(s=>s.trim()),easier:text(input.easier,'Biến thể dễ hơn',400),isActive:input.isActive,schemaVersion:1};
}
export function mergeExerciseLibrary(bundled,remote){
  const map=new Map(bundled.map(row=>[exerciseId(row.id),{...exercisePayload({...row,isActive:row.isActive!==false}),id:row.id,remote:false}]));
  for(const row of remote)map.set(exerciseId(row.id),{...exercisePayload(row),id:row.id,updatedAt:row.updatedAt,remote:true});
  return [...map.values()].sort((a,b)=>a.name.localeCompare(b.name,'vi'));
}
let gifRetryAt=0;
export async function freshExerciseGif(sourceId,{fetcher=fetch,signal,sourceProvider='exercisedb'}={}){
  if(sourceProvider!=='exercisedb')throw Error('Nguồn minh họa không hợp lệ.');
  if(!/^[a-zA-Z0-9]{7}$/.test(sourceId))throw Error('Mã ExerciseDB không hợp lệ.');
  if(Date.now()<gifRetryAt)throw Error('Nguồn minh họa đang giới hạn lượt tải. Chờ rồi thử lại.');
  const response=await fetcher(`https://oss.exercisedb.dev/api/v1/exercises/${sourceId}`,{signal,cache:'no-store'});
  if(response.status===429){const seconds=Number(response.headers?.get?.('retry-after'));gifRetryAt=Date.now()+(Number.isFinite(seconds)&&seconds>0?Math.min(seconds,300):30)*1000;throw Error('Nguồn minh họa đang giới hạn lượt tải. Chờ rồi thử lại.');}
  if(!response.ok)throw Error('Chưa tải được minh họa. Hãy thử lại.');
  const result=await response.json(),url=new URL(result.data?.gifUrl);
  if(result.success!==true||result.data?.exerciseId!==sourceId||result.data.gifUrl!==`https://static.exercisedb.dev/media/${sourceId}.gif`||url.username||url.password)throw Error('Đường dẫn minh họa không hợp lệ.');
  return url.href;
}
