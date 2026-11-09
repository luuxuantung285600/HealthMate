import {supportStatuses,supportTypes,supportTopics,supportTopicLabel,supportText,filterSupport} from './support-model.mjs';
import {entityVersion} from './validation.mjs';
import {liveScope,observe} from './live-scope.mjs';
const loads=new WeakMap();

export async function supportPage({host,api,h,button,isCurrent,onDispose,drafts}) {
  const revision=(loads.get(host)??0)+1;loads.set(host,revision);
  const scope=liveScope(host,()=>isCurrent()&&loads.get(host)===revision,onDispose),current=scope.current;
  const listHost={},detailHost={};let stopList,stopDetail;
  let search='',type='',status='',topic='',pageNumber=1,detailRevision=0,listRevision=0;
  let rows=[],hasMore=false,refreshList;const cursors=[null],replyDrafts=new Map();
  let statusDraftDirty=false;
  drafts?.set('page',()=>statusDraftDirty||[...replyDrafts.values()].some(draft=>draft.text.trim()||draft.messageId));
  async function discardAnd(action){if(!drafts||await drafts.allow(['page'])){statusDraftDirty=false;replyDrafts.clear();await action();}}
  const time=t=>t?.toDate?.()?new Intl.DateTimeFormat('vi-VN',{dateStyle:'short',timeStyle:'short',timeZone:'Asia/Ho_Chi_Minh'}).format(t.toDate()):'—';
  host.replaceChildren(h('p',{class:'loading'},'Đang tải yêu cầu hỗ trợ…'));
  try {
    async function load(cursor=null,page=1){
      stopList?.();stopDetail?.();const listScope=liveScope(listHost,current,scope.add);stopList=listScope.stop;
      const turn=++listRevision;detailRevision++;refreshList=null;
      const active=()=>current()&&turn===listRevision;
      host.replaceChildren(h('p',{class:'loading'},'Đang tải trang hỗ trợ…'));
      try{
        return await observe(listScope,api,'watchPage',['support_tickets',{cursor,isCurrent:active}],result=>{if(!active())return;
        rows=result.rows;hasMore=result.hasMore;pageNumber=page;if(hasMore)cursors[page]=result.cursor;
        if(refreshList)refreshList();else list();
        },e=>{refreshList=null;host.replaceChildren(h('p',{class:'error'},e.message),button('Thử lại',()=>load(cursor,page)));},()=>api.listPage('support_tickets',{cursor,isCurrent:active}));
      }catch(e){if(active())host.replaceChildren(h('p',{class:'error'},e.message),button('Thử lại',()=>load(cursor,page)));}
    }
    function list(){
      if(!current())return;detailRevision++;
      const searchInput=h('input',{type:'search',class:'search',value:search,placeholder:'Tìm yêu cầu trong trang đang xem…','aria-label':'Tìm yêu cầu trong trang đang xem',maxLength:200,
        onInput:e=>{search=e.target.value;render();}});
      const select=(label,values,value,change)=>h('label',{class:'filter-field'},label,h('select',{'aria-label':label,value,onChange:e=>{change(e.target.value);render();}},
        h('option',{value:''},'Tất cả'),...Object.entries(values).map(([v,label])=>h('option',{value:v,selected:v===value},label))));
      const tableHost=h('div',{'aria-live':'polite'});
      function render(){
        if(!current())return;
        const filtered=filterSupport(rows,{search,type,status,topic}),page={rows:filtered,offset:(pageNumber-1)*25};
        const body=h('tbody',{},...page.rows.map((r,i)=>h('tr',{},h('td',{},String(page.offset+i+1)),h('td',{},h('strong',{},r.title),h('small',{},r.uid)),
          h('td',{},supportTypes[r.type]??'—'),h('td',{},supportTopicLabel(r.topic)),h('td',{},h('span',{class:`pill ${r.status==='resolved'?'off':''}`},supportStatuses[r.status]??'—')),
          h('td',{},time(r.updatedAt)),h('td',{},button('Xem & trả lời',()=>detail(r.id))))));
        tableHost.replaceChildren(h('div',{class:'table-wrap'},h('table',{},h('thead',{},h('tr',{},...['STT','YÊU CẦU / KHÁCH HÀNG','LOẠI','CHỦ ĐỀ','TRẠNG THÁI','CẬP NHẬT (VN)','THAO TÁC'].map(t=>h('th',{},t)))),body)),
          ...(!filtered.length?[h('p',{class:'empty'},rows.length?'Không có yêu cầu phù hợp trong trang này.':'Không có yêu cầu ở trang này.')]:[]),
          h('div',{class:'table-foot'},h('span',{},`Trang ${pageNumber} · ${filtered.length}/${rows.length} yêu cầu trên trang`),h('div',{class:'pagination'},
            h('button',{type:'button',class:'button secondary',disabled:pageNumber===1,onClick:()=>load()},'Mới nhất'),
            h('button',{type:'button',class:'button secondary',disabled:pageNumber===1,onClick:()=>load(cursors[pageNumber-2],pageNumber-1)},'Trước'),
            h('button',{type:'button',class:'button secondary',disabled:!hasMore,onClick:()=>load(cursors[pageNumber],pageNumber+1)},'Sau'))));
      }
      host.replaceChildren(h('section',{class:'panel'},h('div',{class:'toolbar'},searchInput,
        select('Loại yêu cầu',supportTypes,type,v=>type=v),select('Trạng thái',supportStatuses,status,v=>status=v),
        select('Chủ đề',{...supportTopics,unclassified:'Chưa phân loại'},topic,v=>topic=v),
        button('Tải lại',()=>discardAnd(()=>supportPage({host,api,h,button,isCurrent,onDispose,drafts})))),h('p',{class:'muted'},'Cập nhật mới nhất lên đầu, tự đồng bộ khi có kết nối. Tìm kiếm, loại, chủ đề và trạng thái chỉ lọc trang đang xem.'),tableHost));refreshList=render;render();
    }
    async function detail(id){
      if(!current())return;stopList?.();stopDetail?.();const detailScope=liveScope(detailHost,current,scope.add);stopDetail=detailScope.stop;
      listRevision++;const turn=++detailRevision;const active=()=>current()&&turn===detailRevision;
      host.replaceChildren(h('p',{class:'loading'},'Đang tải cuộc trao đổi…'));
      try{
        let {ticket,messages}=await api.supportThread(id);if(!active())return;
        let draft=replyDrafts.get(id)??{text:'',messageId:null};
        if(draft.messageId&&messages.some(message=>message.id===draft.messageId&&message.text===draft.text))draft={text:'',messageId:null};
        replyDrafts.set(id,draft);
        let busy=false,statusDirty=false;statusDraftDirty=false;
        let confirmedTicket=ticket;
        const error=h('p',{class:'error',role:'alert'});
        const controls=h('div',{class:'toolbar'}),thread=h('div',{class:'support-thread'});
        function message(label,text,at,admin=false){return h('article',{class:`support-message${admin?' from-admin':''}`},h('small',{},`${label} · ${time(at)} (VN)`),h('p',{},text));}
        thread.append(message('Khách hàng',ticket.description,ticket.createdAt),...messages.map(m=>message(m.role==='admin'?'HealthMate hỗ trợ':'Khách hàng',m.text,m.createdAt,m.role==='admin')));
        const statusSelect=h('select',{'aria-label':'Trạng thái xử lý',onChange:()=>{statusDirty=true;statusDraftDirty=true;}},...Object.entries(supportStatuses).map(([value,label])=>h('option',{value,selected:value===ticket.status},label)));
        async function run(action,{clearReply=false}={}){
          if(busy||!active())return;busy=true;error.textContent='';
          for(const element of host.querySelectorAll('button,textarea,select'))element.disabled=true;
          try{await action();if(active()){if(clearReply)replyDrafts.delete(id);await detail(id);}}
          catch(e){if(active()){error.textContent=e.message;busy=false;for(const el of host.querySelectorAll('button,textarea,select'))el.disabled=false;}}
        }
        controls.append(button('← Danh sách',()=>discardAnd(()=>load())),h('label',{class:'filter-field'},'Trạng thái xử lý',statusSelect),
          button('Lưu trạng thái',()=>run(()=>api.supportStatus(id,statusSelect.value,entityVersion(confirmedTicket)))),button('Tải lại trao đổi',async()=>{if(!statusDraftDirty||!drafts||await drafts.allow(['page']))await detail(id);}));
        const summaryText=()=>`${supportTypes[ticket.type]} · Chủ đề: ${supportTopicLabel(ticket.topic)} · ${supportStatuses[ticket.status]} · UID: ${ticket.uid}`;
        const summary=h('p',{class:'muted'},summaryText());
        const input=h('textarea',{'aria-label':'Trả lời khách hàng',maxLength:2000,rows:5,placeholder:'Nhập phản hồi cho khách hàng…',onInput:()=>{draft.text=input.value;}});
        input.value=draft.text;input.readOnly=Boolean(draft.messageId);
        const send=button('Gửi phản hồi',()=>{
          try{const text=supportText(input.value);draft.text=text;draft.messageId??=api.newSupportMessageId();input.readOnly=true;
            run(()=>api.supportReply(id,draft.messageId,text),{clearReply:true});}catch(e){error.textContent=e.message;}
        },'');
        host.replaceChildren(h('section',{class:'panel'},controls,h('h2',{},ticket.title),summary,thread,error,
          ticket.messageCount>=100?h('p',{class:'notice'},'Đã đủ 100 tin nhắn. Khách hàng cần tạo yêu cầu mới để trao đổi thêm.'):
          h('div',{},h('label',{class:'field'},'Trả lời khách hàng',input),h('p',{class:'muted'},'Phản hồi được gửi tới cuộc trao đổi trong app HealthMate.'),send)));
        if(api.watchSupportThread) detailScope.add(api.watchSupportThread(id,next=>{
          if(!active())return;
          ticket=next.ticket;
          summary.textContent=summaryText();
          thread.replaceChildren(message('Khách hàng',ticket.description,ticket.createdAt),...next.messages.map(m=>message(m.role==='admin'?'HealthMate hỗ trợ':'Khách hàng',m.text,m.createdAt,m.role==='admin')));
          if(!statusDirty){statusSelect.value=ticket.status;confirmedTicket=ticket;}
          if(!busy)error.textContent=statusDirty&&entityVersion(confirmedTicket)!==entityVersion(ticket)?'Cuộc trao đổi đã cập nhật. Kiểm tra trạng thái mới trước khi lưu.':'';
          if(!busy)for(const el of host.querySelectorAll('button,select,textarea'))el.disabled=false;
          if(ticket.messageCount>=100)send.disabled=true;
        },e=>{if(active()){error.textContent=e.message;send.disabled=true;for(const el of controls.querySelectorAll('button,select'))el.disabled=el.tagName==='SELECT'||!['Tải lại trao đổi','← Danh sách'].includes(el.textContent);}},{isCurrent:active}));

      }catch(e){if(active())host.replaceChildren(h('p',{class:'error'},e.message),button('Tải lại',()=>detail(id)),button('Danh sách',()=>discardAnd(()=>supportPage({host,api,h,button,isCurrent,onDispose,drafts}))));}
    }
    await load();
  }catch(e){if(current())host.replaceChildren(h('p',{class:'error'},e.message),button('Tải lại',()=>discardAnd(()=>supportPage({host,api,h,button,isCurrent,onDispose,drafts}))));}
}
