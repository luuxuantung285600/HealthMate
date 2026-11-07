import {collection, doc, query, where, orderBy, limit, startAfter, documentId, Timestamp, onSnapshot} from 'https://www.gstatic.com/firebasejs/13.0.0/firebase-firestore.js';
import {pageScope, createAdminPageReader,pageConstraints} from './server-paging.mjs';
import {validateSupportThread, supportId} from './support-model.mjs';

export function createLiveData(db, session, {statisticsMode = 'server'} = {}) {
  if (!['server','firestore'].includes(statisticsMode)) throw Error('Chế độ thống kê không hợp lệ.');
  const subscriptions = new Set();
  function watch(options, error, setup) {
    const verify = session();
    let stopped = false;
    const stops = new Set();
    const stop = () => { if (stopped) return; stopped = true; for (const fn of stops) fn(); stops.clear(); subscriptions.delete(stop); };
    subscriptions.add(stop);
    const current = () => { if (stopped) return false; try { verify(); if (options?.isCurrent?.() === false) {stop(); return false;} return true; } catch {stop(); return false;} };
    const fail = e => { if (current()) error(e); };
    const listen = (target, receive, unverified = () => {}) => {
      const unsubscribe = onSnapshot(target, {includeMetadataChanges:true}, snapshot => {
        if (!current()) return;
        if (snapshot.metadata.isFromCache || snapshot.metadata.hasPendingWrites) {
          unverified();
          fail(Error('Đang kết nối lại. Dữ liệu chưa được máy chủ xác nhận.')); return;
        }
        try { receive(snapshot); } catch (e) { unverified(); fail(e); }
      }, e => {unverified(); fail(e);});
      stops.add(unsubscribe);
      return () => {unsubscribe(); stops.delete(unsubscribe);};
    };
    try { setup({listen,current,fail}); } catch(e) { fail(e); stop(); }
    return stop;
  }
  function watchDocument(path, receive, error, options) {
    return watch(options,error,({listen}) => listen(doc(db,...path), snapshot => receive(snapshot.exists() ? snapshot.data() : null)));
  }
  return {
    stopAll() { for (const stop of [...subscriptions]) stop(); },
    watchConfig: (receive,error,options) => watchDocument(['app_config','runtime'],receive,error,options),
    watchRegisteredAccounts: (receive,error,options) => watchDocument(['admin_statistics','accounts'],receive,error,options),
    watchCounts: (receive,error,options) => statisticsMode === 'firestore' ? watch(options,error,({listen}) => {
      // Spark has no trusted aggregate worker. For a small catalog, observe the
      // complete bounded sets; never label one page as the collection total.
      const kinds=['food_catalog','user_directory','account_controls','admin_audit'];
      const rows=new Map(),ready=new Set();
      for (const kind of kinds) listen(query(collection(db,kind),limit(5001)),snapshot => {
        ready.delete(kind);
        if (snapshot.size>5000) throw Error('Thống kê trực tiếp vượt 5.000 mục ở một nguồn. Cần bộ tổng hợp máy chủ; chưa hiển thị tổng bị thiếu.');
        rows.set(kind,snapshot.docs);ready.add(kind);
        if (ready.size!==kinds.length) return;
        const users=new Set(rows.get('user_directory').map(row=>row.id));
        receive([rows.get('food_catalog').length,users.size,
          rows.get('account_controls').filter(row=>users.has(row.id)&&row.data().status==='suspended').length,
          rows.get('admin_audit').length]);
      },()=>ready.delete(kind));
    }) : watchDocument(['admin_statistics','operations'],data => {
      if (data?.ready !== true || data.schemaVersion !== 1) throw Error('Thống kê trực tiếp chưa được khởi tạo trên máy chủ.');
      const counts = ['foods','accounts','suspended','audits'].map(key => data[key]);
      if (counts.some(n => !Number.isSafeInteger(n) || n < 0)) throw Error('Thống kê trực tiếp chưa hợp lệ.');
      receive(counts);
    },error,options),
    watchRange(kind, range, receive, error, options) {
      const scope = pageScope(kind,range);
      if (kind !== 'demo_premium_transactions' || !scope.start) throw Error('Chọn kỳ doanh thu để đồng bộ.');
      return watch(options,error,({listen}) => listen(query(collection(db,kind),where('occurredAt','>=',new Date(scope.lower)),where('occurredAt','<',new Date(scope.upper)),orderBy('occurredAt','desc'),orderBy(documentId(),'desc'),limit(5001)), snapshot => {
        if (snapshot.size > 5000) throw Error('Kỳ này vượt 5.000 giao dịch. Chọn khoảng ngày nhỏ hơn để tổng hợp đầy đủ.');
        receive(snapshot.docs.map(s => ({...s.data(),id:s.id})));
      }));
    },
    watchPage(kind, options, receive, error) {
      const scope = pageScope(kind,options), cursor = options.cursor ?? null;
      // Reuse the page reader's cursor validation before attaching a listener.
      const validate = createAdminPageReader({fetchDocuments:async()=>[],enrichAccount:async()=>({})});
      return watch(options,error,({listen,current,fail}) => {
        const clauses=pageConstraints(scope,cursor,{where,orderBy,documentId,startAfter,Timestamp});
        let rows = [], revision = 0,sourceReady=false;
        const extras = new Map();
        const publish = async () => {
          const turn = ++revision;
          if (!current() || !sourceReady || (kind === 'user_directory' && rows.some(row => !extras.get(row.id)?.ready()))) return;
          try {
            const reader = createAdminPageReader({fetchDocuments:async()=>rows,enrichAccount:async uid=>extras.get(uid).value});
            const page = await reader(kind,{...options,isCurrent:()=>current()&&turn===revision});
            if (current() && turn === revision) receive(page);
          } catch(e) { if (current() && turn === revision) fail(e); }
        };
        validate(kind,options).then(() => {
          if (!current()) return;
          const target=scope.lookupField==='id'?doc(db,kind,scope.lookupValue):query(collection(db,kind),...clauses,limit(25));
          listen(target,snapshot => {
            sourceReady=true;
            rows = scope.lookupField==='id'?(snapshot.exists()?[{...snapshot.data(),id:snapshot.id}]:[]):snapshot.docs.map(s=>({...s.data(),id:s.id}));
            if (kind === 'user_directory') {
              const ids = new Set(rows.map(row=>row.id));
              for (const [id,entry] of extras) if (!ids.has(id)) {entry.stops.forEach(fn=>fn()); extras.delete(id);}
              for (const row of rows) if (!extras.has(row.id)) {
                const seen = new Set(), entry = {value:{},stops:[],ready:()=>seen.size===2}; extras.set(row.id,entry);
                for (const [key,path] of [['adminRole','admin_roles'],['control','account_controls']]) entry.stops.push(listen(doc(db,path,row.id),snapshot=>{
                  entry.value[key]=snapshot.exists()?snapshot.data():null; seen.add(key); publish();
                },()=>{seen.delete(key);revision++;}));
              }
            }
            publish();
          },()=>{sourceReady=false;revision++;});
        }).catch(fail);
      });
    },
    watchSupportThread(id, receive, error, options) {
      supportId(id);
      return watch(options,error,({listen}) => {
        let ticket, messages,ticketReady=false,messagesReady=false;
        // Parent and messages listeners can deliver the same committed batch
        // in either order. Publish only a complete conversation version.
        const publish = () => { if (ticketReady && messagesReady && ticket.messageCount===messages.length) receive(validateSupportThread(ticket,messages)); };
        listen(doc(db,'support_tickets',id),snapshot=>{
          if (!snapshot.exists() || snapshot.data().deleting) {ticketReady=false;ticket=undefined;throw Error('Yêu cầu không còn khả dụng.');}
          ticket={...snapshot.data(),id:snapshot.id};ticketReady=true;publish();
        },()=>{ticketReady=false;});
        listen(query(collection(db,'support_tickets',id,'messages'),orderBy('sequence'),limit(101)),snapshot=>{
          messages=snapshot.docs.map(s=>({...s.data(),id:s.id}));messagesReady=true;publish();
        },()=>{messagesReady=false;});
      });
    },
  };
}
