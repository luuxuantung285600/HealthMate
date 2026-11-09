// Minimal OOXML workbook with inline strings. No macros, formulas, hyperlinks,
// external references, remote code or third-party runtime dependency.
const encoder = new TextEncoder();
const xml = value => String(value ?? '').replace(/[\u0000-\u0008\u000b\u000c\u000e-\u001f\ufffe\uffff]/g, '')
  .replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;').replace(/'/g,'&apos;');
function column(index) { let s=''; for(let n=index+1;n>0;n=Math.floor((n-1)/26))s=String.fromCharCode(65+(n-1)%26)+s;return s; }
const crcTable = Array.from({length:256}, (_,i) => { for(let j=0;j<8;j++)i=i&1?0xedb88320^(i>>>1):i>>>1;return i>>>0; });
function crc32(bytes) { let crc=0xffffffff;for(const b of bytes)crc=crcTable[(crc^b)&255]^(crc>>>8);return(crc^0xffffffff)>>>0; }
function bytes(size, fields) { const out=new Uint8Array(size),v=new DataView(out.buffer);for(const [at,n,width]of fields)width===2?v.setUint16(at,n,true):v.setUint32(at,n,true);return out; }
function concat(parts) { const out=new Uint8Array(parts.reduce((n,p)=>n+p.length,0));let at=0;for(const p of parts){out.set(p,at);at+=p.length;}return out; }
function zip(files) {
  const local=[],central=[];let offset=0;
  for(const [name,text]of Object.entries(files)) {
    const nameBytes=encoder.encode(name),body=encoder.encode(text),crc=crc32(body);
    const head=bytes(30,[[0,0x04034b50,4],[4,20,2],[6,0x800,2],[8,0,2],[12,33,2],[14,crc,4],[18,body.length,4],[22,body.length,4],[26,nameBytes.length,2]]);
    local.push(head,nameBytes,body);
    central.push(bytes(46,[[0,0x02014b50,4],[4,20,2],[6,20,2],[8,0x800,2],[10,0,2],[14,33,2],[16,crc,4],[20,body.length,4],[24,body.length,4],[28,nameBytes.length,2],[42,offset,4]]),nameBytes);
    offset+=head.length+nameBytes.length+body.length;
  }
  const directory=concat(central),count=Object.keys(files).length;
  return concat([...local,directory,bytes(22,[[0,0x06054b50,4],[8,count,2],[10,count,2],[12,directory.length,4],[16,offset,4]])]);
}
function sheetXml({name, headers, rows}) {
  if(!Array.isArray(headers)||!headers.length||headers.length>100||!Array.isArray(rows)||rows.length>5000)throw Error('Danh sách Excel vượt giới hạn.');
  if([headers,...rows].some(row=>!Array.isArray(row)||row.length>headers.length))throw Error('Số cột Excel không khớp; chưa xuất tệp thiếu dữ liệu.');
  const sheetName=String(name??'Danh sách').replace(/[\\/?*\[\]:]/g,' ').replace(/^'+|'+$/g,'').trim().slice(0,31)||'Danh sách';
  const data=[headers,...rows];
  const widths=headers.map((_,j)=>Math.min(54,Math.max(14,...data.slice(0,200).map(row=>String(row[j]??'').split(/\r?\n/).reduce((n,line)=>Math.max(n,[...line].length),0)+2))));
  const sheet=data.map((row,i)=>{
    const lineCount=Math.max(...headers.map((_,j)=>String(row[j]??'').split(/\r?\n/).reduce((n,line)=>n+Math.max(1,Math.ceil([...line].length/(widths[j]-2))),0)));
    return `<row r="${i+1}" ht="${Math.min(240,Math.max(i===0?36:20,lineCount*15))}" customHeight="1">${headers.map((_,j)=>{
    const value=row[j],ref=`${column(j)}${i+1}`,style=i===0?' s="1"':'';
    if(value===null||value===undefined)return `<c r="${ref}"${style}/>`;
    if(typeof value==='number'){
      if(!Number.isFinite(value))throw Error('Số không hữu hạn trong Excel.');
      // Excel retains only 15 significant digits; keep larger values as text.
      if(String(value).replace(/[^0-9]/g,'').length<=15)return `<c r="${ref}"${style}><v>${value}</v></c>`;
    }else if(typeof value!=='string'&&typeof value!=='boolean')throw Error('Kiểu dữ liệu ô Excel không hợp lệ.');
    if(String(value).length>32767)throw Error('Một ô Excel quá dài.');
    return `<c r="${ref}" t="inlineStr"${style}><is><t xml:space="preserve">${xml(value)}</t></is></c>`;
  }).join('')}</row>`;}).join('');
  return {name:sheetName,xml:`<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><dimension ref="A1:${column(headers.length-1)}${data.length}"/><sheetViews><sheetView workbookViewId="0"><pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/></sheetView></sheetViews><sheetFormatPr defaultRowHeight="30"/><cols>${widths.map((w,j)=>`<col min="${j+1}" max="${j+1}" width="${w}" customWidth="1"/>`).join('')}</cols><sheetData>${sheet}</sheetData><autoFilter ref="A1:${column(headers.length-1)}${data.length}"/><pageSetup orientation="landscape" fitToWidth="1" fitToHeight="0"/></worksheet>`};
}

export function buildXlsx({metadata=[],...data}) {
  if(!Array.isArray(metadata))throw Error('Thông tin báo cáo không hợp lệ.');
  const sheets=[sheetXml(data)];
  if(metadata.length){
    const info=sheetXml({name:'Thông tin báo cáo',headers:['Thông tin','Giá trị'],rows:[...metadata,['Số dòng dữ liệu',data.rows.length],['Thời điểm tạo (UTC)',new Date().toISOString()]]});
    if(info.name===sheets[0].name)info.name='Thông tin xuất';
    sheets.push(info);
  }
  const declaration='<?xml version="1.0" encoding="UTF-8" standalone="yes"?>';
  const files={
    '[Content_Types].xml':declaration+`<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>${sheets.map((_,i)=>`<Override PartName="/xl/worksheets/sheet${i+1}.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>`).join('')}<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/></Types>`,
    '_rels/.rels':declaration+'<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/></Relationships>',
    'xl/workbook.xml':declaration+`<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets>${sheets.map((s,i)=>`<sheet name="${xml(s.name)}" sheetId="${i+1}" r:id="rId${i+1}"/>`).join('')}</sheets></workbook>`,
    'xl/_rels/workbook.xml.rels':declaration+`<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">${sheets.map((_,i)=>`<Relationship Id="rId${i+1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet${i+1}.xml"/>`).join('')}<Relationship Id="rId${sheets.length+1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/></Relationships>`,
    'xl/styles.xml':declaration+'<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><fonts count="2"><font><sz val="11"/><name val="Inter"/></font><font><b/><color rgb="FFFFFFFF"/><sz val="11"/><name val="Inter"/></font></fonts><fills count="3"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill><fill><patternFill patternType="solid"><fgColor rgb="FF16705A"/><bgColor indexed="64"/></patternFill></fill></fills><borders count="1"><border/></borders><cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs><cellXfs count="2"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0" applyAlignment="1"><alignment vertical="top" wrapText="1"/></xf><xf numFmtId="0" fontId="1" fillId="2" borderId="0" xfId="0" applyFont="1" applyFill="1" applyAlignment="1"><alignment vertical="center" wrapText="1"/></xf></cellXfs><cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles></styleSheet>',
  };
  sheets.forEach((sheet,i)=>files[`xl/worksheets/sheet${i+1}.xml`]=declaration+sheet.xml);
  const result=zip(files);
  if(result.length>12*1024*1024)throw Error('Tệp Excel vượt 12 MB; hãy chia phạm vi dữ liệu.');
  return result;
}
