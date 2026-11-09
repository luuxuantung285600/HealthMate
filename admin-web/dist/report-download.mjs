import {buildXlsx} from './xlsx-export.mjs';

// A click requests a browser download; it cannot prove the file reached disk.
export function downloadReport({workbook,filename,isCurrent=()=>true,onResult=()=>{}}){
  let url,link;
  try{
    if(!isCurrent())return false;
    const bytes=buildXlsx(workbook);
    if(!isCurrent())return false;
    url=URL.createObjectURL(new Blob([bytes],{type:'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'}));
    link=document.createElement('a');link.href=url;link.download=filename;
    document.body.append(link);link.click();
    onResult(`Đã tạo ${workbook.rows.length} dòng dữ liệu và yêu cầu trình duyệt tải xuống.`,false);
    return true;
  }catch(error){
    if(isCurrent())onResult(`Chưa xuất được báo cáo. ${error instanceof Error?error.message:'Hãy thử lại.'}`,true);
    return false;
  }finally{
    link?.remove();
    if(url)setTimeout(()=>URL.revokeObjectURL(url),1000);
  }
}
