'use strict';
const {randomUUID}=require('node:crypto');
const {Timestamp}=require('firebase-admin/firestore');
const {BillingError,accountId,hash,tokenValue,subscription,replaceMembership,order}=require('./billing-model.cjs');
const stamp=n=>Timestamp.fromMillis(n);
const millis=value=>value?.toMillis?.()??0;
class BillingService {
  constructor(db,publisher,config,{now=Date.now}={}){this.db=db;this.publisher=publisher;this.config=config;this.now=now;}
  ref(path){return this.db.doc(path);}
  async assertAccount(uid){
    const [deleted,control]=await this.db.getAll(this.ref(`account_deletions/${uid}`),this.ref(`account_controls/${uid}`));
    if(deleted.exists||control.exists&&control.data().status!=='active')throw new BillingError('permission-denied','Tài khoản chưa được phép sử dụng thanh toán.');
  }
  async prepare(uid){
    if(!this.config.enabled)return {enabled:false};
    await this.assertAccount(uid);
    const id=accountId(uid);
    await this.ref(`billing_accounts/${id}`).set({uid});
    return {enabled:true,accountId:id,packageName:this.config.packageName,productId:this.config.productId,basePlanId:this.config.basePlanId};
  }
  async reconcile(rawToken,uid=null,extraOrderId=null){
    if(!this.config.enabled)throw new BillingError('failed-precondition','Thanh toán Google Play chưa được mở.');
    const token=tokenValue(rawToken),tokenHash=hash(token),tokenRef=this.ref(`billing_tokens/${tokenHash}`);
    if(!uid){
      const saved=await tokenRef.get();uid=saved.data()?.uid;
      if(!uid){
        const preliminary=await this.publisher.getSubscription(token);
        const id=preliminary.externalAccountIdentifiers?.obfuscatedExternalAccountId;
        if(!/^[a-f0-9]{64}$/.test(id??''))throw new BillingError('permission-denied','Giao dịch không liên kết HealthMate.');
        uid=(await this.ref(`billing_accounts/${id}`).get()).data()?.uid;
        if(!uid)throw new BillingError('failed-precondition','Chưa tìm được chủ giao dịch.');
      }
    }
    const lease=randomUUID(),lock=this.ref(`billing_locks/${uid}`);
    // Serialize API reads and writes per user. A stale event always fetches fresh
    // Play state after taking the lease, never grants from the RTDN payload.
    await this.db.runTransaction(async t=>{
      const current=await t.get(lock);
      if(millis(current.data()?.until)>this.now())throw new BillingError('aborted','Giao dịch đang được đối soát. Hãy thử lại.');
      t.set(lock,{lease,until:stamp(this.now()+180000)});
    });
    try{
      let data=await this.publisher.getSubscription(token),state=subscription(data,this.config,uid,this.now());
      // Refresh before the durable grant as well as acknowledgement. If Play
      // changed state during verification, persist that latest known state.
      if(state.acknowledge){
        data=await this.publisher.getSubscription(token);
        state=subscription(data,this.config,uid,this.now());
      }
      const savedToken=await tokenRef.get();
      const orderIds=[...new Set([state.orderId,extraOrderId,...(savedToken.data()?.retryOrderIds??[])].filter(Boolean))];
      if(orderIds.length>10)throw new BillingError('resource-exhausted','Cần đối soát thủ công các đơn chưa xác nhận.');
      if(orderIds.some(id=>typeof id!=='string'||id.length>200))throw new BillingError('invalid-argument','Mã đơn không hợp lệ.');
      const receipts=[];
      for(const orderId of orderIds){
        try{receipts.push(order(await this.publisher.getOrder(orderId),{uid,token,productId:state.productId,environment:state.environment,orderId}));}
        catch(error){
          // Never invent a price. Entitlement is independently verified using
          // subscriptionsv2; revenue stays explicitly unresolved until retry.
          if(error instanceof BillingError&&error.code==='permission-denied')throw error;
          receipts.push({provider:'google_play',verified:true,uid,environment:state.environment,productId:state.productId,orderId,status:'awaiting_order',currency:null,totalNanos:null,refundedNanos:null,netNanos:null,occurredAt:this.now(),providerUpdatedAt:0});
        }
      }
      const membershipRef=this.ref(`premium_memberships/${uid}`);
      let allowed=false,granted=false;
      await this.db.runTransaction(async t=>{
        const refs=[lock,tokenRef,membershipRef,this.ref(`account_deletions/${uid}`),this.ref(`account_controls/${uid}`),...receipts.map(r=>this.ref(`premium_transactions/${hash(r.orderId)}`))];
        const [guard,saved,previous,deleted,control,...oldOrders]=await t.getAll(...refs);
        if(guard.data()?.lease!==lease||millis(guard.data()?.until)<=this.now())throw new BillingError('aborted','Đối soát đã hết thời gian.');
        if(saved.exists&&saved.data().uid!==uid)throw new BillingError('permission-denied','Biên nhận đã thuộc tài khoản khác.');
        allowed=!deleted.exists&&(!control.exists||control.data().status==='active');
        t.set(tokenRef,{uid,token,environment:state.environment,startedAt:stamp(state.startedAt),checkedAt:stamp(this.now()),retryOrderIds:receipts.filter(r=>r.status==='awaiting_order').map(r=>r.orderId)});
        const existing=previous.data();
        // Old replacement tokens must not overwrite the newer subscription.
        const replace=replaceMembership(existing,state,tokenHash);
        granted=replace&&allowed&&state.active;
        if(replace){
          const {acknowledge,orderId,...publicState}=state;
          t.set(membershipRef,{...publicState,active:allowed&&state.active,tokenHash,startedAt:stamp(state.startedAt),expiresAt:stamp(state.expiresAt),updatedAt:stamp(this.now())});
        }
        for(let i=0;i<receipts.length;i++){
          const row=receipts[i],old=oldOrders[i].data();
          // A failed Orders fetch never erases a previously verified amount.
          if(old&&row.status==='awaiting_order'){
            t.set(refs[5+i],{...old,reconciliationPending:true,updatedAt:stamp(this.now())});
            continue;
          }
          if(old&&millis(old.providerUpdatedAt)>row.providerUpdatedAt)continue;
          t.set(refs[5+i],{...row,reconciliationPending:row.status==='awaiting_order',occurredAt:stamp(row.occurredAt),providerUpdatedAt:stamp(row.providerUpdatedAt),updatedAt:stamp(this.now())});
        }
      });
      // Acknowledge only purchased, verified subscriptions, after durable grant.
      // Retry is safe when Google acknowledged but the response was interrupted.
      let completionAllowed=data.acknowledgementState==='ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED';
      if(state.acknowledge){
        await this.publisher.acknowledge(state.productId,token);completionAllowed=true;
      }
      const pending=state.status==='SUBSCRIPTION_STATE_PENDING';
      const incomplete=pending||state.status==='SUBSCRIPTION_STATE_PENDING_PURCHASE_CANCELED';
      return {verified:true,active:granted,pending,completionAllowed:!incomplete&&completionAllowed,environment:state.environment};
    }finally{
      await this.db.runTransaction(async t=>{if((await t.get(lock)).data()?.lease===lease)t.delete(lock);});
    }
  }
}
module.exports={BillingService};
