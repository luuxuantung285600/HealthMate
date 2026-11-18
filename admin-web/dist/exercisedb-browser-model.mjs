// ExerciseDB free hosted API: cursor pages, no credentials or persisted cache.
const base='https://oss.exercisedb.dev/api/v1/';
const idPattern=/^[a-zA-Z0-9]{7}$/;
const bodyLabels={neck:'Cổ',back:'Lưng',chest:'Ngực',shoulders:'Vai',waist:'Bụng',cardio:'Tim mạch','lower arms':'Cẳng tay','upper arms':'Cánh tay','lower legs':'Cẳng chân','upper legs':'Đùi và mông'};
const equipmentLabels={bodyweight:'Trọng lượng cơ thể',dumbbell:'Tạ đơn',barbell:'Tạ đòn',cable:'Cáp',band:'Dây kháng lực','resistance band':'Dây kháng lực',kettlebell:'Tạ chuông',assisted:'Máy hỗ trợ','leverage machine':'Máy đòn bẩy','smith machine':'Máy Smith','stationary bike':'Xe đạp tại chỗ','elliptical machine':'Máy elip','stepmill machine':'Máy bước cầu thang','olympic barbell':'Tạ đòn Olympic','EZ bar':'Thanh tạ EZ','trap bar':'Thanh tạ lục giác','stability ball':'Bóng thăng bằng','medicine ball':'Bóng tập','bosu ball':'Bóng Bosu','ab wheel':'Con lăn bụng',rope:'Dây thừng','suspension trainer':'Dây treo',roller:'Con lăn',weighted:'Có thêm tạ',towel:'Khăn',tire:'Lốp xe',hammer:'Búa','tennis ball':'Bóng tennis','ski ergometer':'Máy trượt tuyết','upper body ergometer':'Máy đạp tay','sled machine':'Xe đẩy tạ'};
export const exerciseDbBodyLabel=value=>bodyLabels[value]??value;
export const exerciseDbEquipmentLabel=value=>equipmentLabels[value]??value;
const aliases={'chong day':'push up','hit dat':'push up','gap bung':'crunch','ngoi xom':'squat','keo xa':'pull up','hit xa':'pull up','chay bo':'run','nhay day':'jump rope'};
export function exerciseDbSearchTerm(value) {
  const term=String(value??'').trim();
  if(term.length>120)throw Error('Từ khóa tối đa 120 ký tự.');
  const normalized=term.normalize('NFD').replace(/[\u0300-\u036f]/g,'').replace(/đ/g,'d').toLowerCase().replace(/\s+/g,' ');
  return aliases[normalized]??term;
}
function strings(value,max=32) {
  if(!Array.isArray(value)||value.length>max||value.some(v=>typeof v!=='string'||!v.trim()||v.length>2000))throw Error('Nguồn trả về dữ liệu bài tập không hợp lệ.');
  return value.map(v=>v.trim());
}
export function readExerciseDbEntry(value) {
  if(!value||!idPattern.test(value.exerciseId)||typeof value.name!=='string'||!value.name.trim()||value.name.length>300)throw Error('Nguồn trả về mã hoặc tên bài tập không hợp lệ.');
  if(value.gifUrl!==`https://static.exercisedb.dev/media/${value.exerciseId}.gif`)throw Error('Nguồn trả về đường dẫn GIF không hợp lệ.');
  // Do not retain rotating URLs. Previews resolve fresh media via the existing service.
  return {sourceId:value.exerciseId,name:value.name.trim(),bodyParts:strings(value.bodyParts),equipments:strings(value.equipments),targetMuscles:strings(value.targetMuscles),instructions:strings(value.instructions)};
}
export function createExerciseDbClient({fetcher=(...args)=>fetch(...args),timeoutMs=20000,now=()=>Date.now()}={}) {
  let retryAt=0;
  async function request(path,{signal}={}) {
    if(now()<retryAt)throw Error('ExerciseDB đang giới hạn lượt gọi. Vui lòng chờ rồi thử lại.');
    const controller=new AbortController();
    const abort=()=>controller.abort();
    if(signal?.aborted)throw new DOMException('Cancelled','AbortError');
    signal?.addEventListener('abort',abort,{once:true});
    const timer=setTimeout(abort,timeoutMs);
    try {
      const response=await fetcher(base+path,{signal:controller.signal,cache:'no-store',credentials:'omit',redirect:'error'});
      if(response.status===429) {
        const raw=response.headers?.get?.('retry-after'),seconds=Number(raw);
        const wait=Number.isFinite(seconds)&&seconds>0?seconds*1000:Date.parse(raw)-now();
        retryAt=now()+Math.min(300000,Number.isFinite(wait)&&wait>0?wait:30000);
        throw Error('ExerciseDB đang giới hạn lượt gọi. Vui lòng chờ rồi thử lại.');
      }
      if(!response.ok)throw Error('Chưa tải được kho ExerciseDB. Hãy thử lại.');
      const result=await response.json();
      if(controller.signal.aborted)throw new DOMException('Cancelled','AbortError');
      if(result?.success!==true)throw Error('ExerciseDB trả về dữ liệu không hợp lệ.');
      return result;
    } catch(error) {
      if(signal?.aborted)throw new DOMException('Cancelled','AbortError');
      if(controller.signal.aborted)throw Error('Tải kho quá lâu. Kiểm tra kết nối rồi thử lại.');
      if(error instanceof TypeError)throw Error('Không kết nối được ExerciseDB. Kiểm tra Internet rồi thử lại.');
      throw error;
    } finally {clearTimeout(timer);signal?.removeEventListener('abort',abort);}
  }
  return {
    async page({query='',bodyPart='',equipment='',after='',signal}={}) {
      const params=new URLSearchParams({limit:'25'}),name=exerciseDbSearchTerm(query);
      if(name)params.set('name',name);
      for(const [key,value] of [['bodyParts',bodyPart],['equipments',equipment]])if(value) {
        if(typeof value!=='string'||value.length>100)throw Error('Bộ lọc không hợp lệ.');
        params.set(key,value);
      }
      if(after){if(!idPattern.test(after))throw Error('Trang tiếp theo không hợp lệ.');params.set('after',after);}
      const result=await request(`exercises?${params}`,{signal});
      if(!Array.isArray(result.data)||result.data.length>25)throw Error('Danh sách nguồn không hợp lệ.');
      const rows=result.data.map(readExerciseDbEntry),meta=result.meta;
      if(new Set(rows.map(r=>r.sourceId)).size!==rows.length||!meta||!Number.isSafeInteger(meta.total)||meta.total<rows.length||meta.total>100000||typeof meta.hasNextPage!=='boolean')throw Error('Phân trang nguồn không hợp lệ.');
      const next=meta.hasNextPage?meta.nextCursor:null;
      if(meta.hasNextPage&&(!idPattern.test(next)||!rows.length||next!==rows.at(-1).sourceId||next===after))throw Error('Con trỏ nguồn không hợp lệ.');
      return {rows,total:meta.total,next};
    },
    async facets({signal}={}) {
      const read=async path=>{
        const response=await request(path,{signal});
        if(!Array.isArray(response.data)||response.data.length>100)throw Error('Bộ lọc nguồn không hợp lệ.');
        return [...new Set(response.data.map(row=>{
          if(typeof row?.name!=='string'||!row.name||row.name.length>100)throw Error('Bộ lọc nguồn không hợp lệ.');
          return row.name;
        }))];
      };
      const [bodyParts,equipments]=await Promise.all([read('bodyparts'),read('equipments')]);
      return {bodyParts,equipments};
    },
  };
}

// Editorial content stays in the existing HealthMate schema. Source guidance
// is shown transiently for reference; an admin authors Vietnamese text to save.
export function exerciseDbDraft(source) {
  const regions={back:'back',chest:'chest',shoulders:'shoulders',waist:'core',cardio:'cardio','lower arms':'arms','upper arms':'arms','lower legs':'legs','upper legs':'legs'};
  const equipment={bodyweight:'bodyweight',dumbbell:'dumbbell',barbell:'barbell','olympic barbell':'barbell','EZ bar':'barbell','trap bar':'barbell',cable:'cable',band:'band','resistance band':'band',kettlebell:'kettlebell',assisted:'machine','leverage machine':'machine','smith machine':'machine','stationary bike':'machine','elliptical machine':'machine','stepmill machine':'machine','ski ergometer':'machine','upper body ergometer':'machine','sled machine':'machine'};
  if(!idPattern.test(source.sourceId))throw Error('Mã nguồn không hợp lệ.');
  const muscleLabels={pectorals:'Cơ ngực',deltoids:'Cơ vai',abdominals:'Cơ bụng',biceps:'Cơ tay trước',triceps:'Cơ tay sau',quads:'Cơ đùi trước',hamstrings:'Cơ đùi sau',glutes:'Cơ mông',calves:'Cơ bắp chân',lats:'Cơ lưng rộng',traps:'Cơ thang',forearms:'Cơ cẳng tay','erector spinae':'Cơ dựng sống','cardiovascular system':'Hệ tim mạch'};
  return {id:`edb-${source.sourceId}`,sourceId:source.sourceId,sourceProvider:'exercisedb',name:'',region:regions[source.bodyParts[0]]??'',equipment:equipment[source.equipments[0]]??'',target:source.targetMuscles.every(m=>muscleLabels[m])?source.targetMuscles.map(m=>muscleLabels[m]).join(', '):'',steps:[],easier:'',isActive:true};
}
