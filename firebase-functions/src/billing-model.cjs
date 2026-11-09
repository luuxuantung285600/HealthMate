'use strict';
const {createHash}=require('node:crypto');
const hash=value=>createHash('sha256').update(value).digest('hex');
const accountId=uid=>hash(`healthmate:google-play:account:v1:${uid}`);
class BillingError extends Error { constructor(code,message){super(message);this.code=code;} }
function validateIdentity(user,auth){
  const validAfter=Date.parse(user?.tokensValidAfterTime),authTime=auth?.token?.auth_time;
  if(!auth?.uid||user?.uid!==auth.uid||user.disabled||!user.emailVerified||auth.token.email_verified!==true||!Number.isFinite(authTime)||!Number.isFinite(validAfter)||validAfter>authTime*1000)throw new BillingError('unauthenticated','Phiên đã hết hiệu lực. Hãy đăng nhập lại.');
  return user.uid;
}
function configuration(env=process.env){
  const config={enabled:env.BILLING_ENABLED==='true',packageName:env.BILLING_PACKAGE_NAME||'',productId:env.BILLING_PRODUCT_ID||'',basePlanId:env.BILLING_BASE_PLAN_ID||'',allowTest:env.BILLING_ALLOW_TEST==='true'};
  if(config.enabled&&(!/^[\w]+(\.[\w]+)+$/.test(config.packageName)||!/^[-\w.]{1,150}$/.test(config.productId)||!/^[-\w]{1,63}$/.test(config.basePlanId)))throw new BillingError('failed-precondition','Cấu hình Google Play chưa đầy đủ.');
  return config;
}
function tokenValue(value){if(typeof value!=='string'||value.length<10||value.length>4096||/[\s\x00-\x1f]/.test(value))throw new BillingError('invalid-argument','Biên nhận không hợp lệ.');return value;}
function timestamp(value){const n=Date.parse(value);if(!Number.isFinite(n))throw new BillingError('failed-precondition','Google chưa trả thời điểm hợp lệ.');return n;}
function subscription(data,config,uid,now=Date.now()){
  if(data.externalAccountIdentifiers?.obfuscatedExternalAccountId!==accountId(uid))throw new BillingError('permission-denied','Giao dịch thuộc tài khoản HealthMate khác.');
  if(!Array.isArray(data.lineItems)||data.lineItems.length!==1)throw new BillingError('failed-precondition','Chỉ hỗ trợ một gói Premium trong giao dịch.');
  const line=data.lineItems[0];
  if(line.productId!==config.productId||line.offerDetails?.basePlanId!==config.basePlanId||!line.autoRenewingPlan||line.offerDetails?.offerId)throw new BillingError('failed-precondition','Gói mua không khớp gói Premium được hỗ trợ.');
  const environment=data.testPurchase!=null?'test':'production';
  if(environment==='test'&&!config.allowTest)throw new BillingError('permission-denied','Máy chủ chưa bật kiểm thử Google Play.');
  const status=data.subscriptionState;
  if(!['SUBSCRIPTION_STATE_PENDING','SUBSCRIPTION_STATE_ACTIVE','SUBSCRIPTION_STATE_PAUSED','SUBSCRIPTION_STATE_IN_GRACE_PERIOD','SUBSCRIPTION_STATE_ON_HOLD','SUBSCRIPTION_STATE_CANCELED','SUBSCRIPTION_STATE_EXPIRED','SUBSCRIPTION_STATE_PENDING_PURCHASE_CANCELED'].includes(status))throw new BillingError('failed-precondition','Trạng thái Google Play chưa được hỗ trợ.');
  const startedAt=data.startTime?timestamp(data.startTime):now;
  const expiresAt=line.expiryTime?timestamp(line.expiryTime):now;
  if(['SUBSCRIPTION_STATE_ACTIVE','SUBSCRIPTION_STATE_IN_GRACE_PERIOD','SUBSCRIPTION_STATE_CANCELED'].includes(status)&&(!data.startTime||!line.expiryTime||expiresAt<=startedAt))throw new BillingError('failed-precondition','Google chưa xác nhận đủ thời hạn gói.');
  const active=['SUBSCRIPTION_STATE_ACTIVE','SUBSCRIPTION_STATE_IN_GRACE_PERIOD','SUBSCRIPTION_STATE_CANCELED'].includes(status)&&startedAt<=now&&expiresAt>now;
  return {provider:'google_play',verified:true,environment,productId:line.productId,basePlanId:config.basePlanId,status,startedAt,expiresAt,active,autoRenewing:line.autoRenewingPlan.autoRenewEnabled===true,orderId:line.latestSuccessfulOrderId||null,acknowledge:active&&data.acknowledgementState==='ACKNOWLEDGEMENT_STATE_PENDING'};
}
function replaceMembership(existing,state,tokenHash){
  if(!existing)return true;
  // Sandbox can be reported and acknowledged, but cannot replace a real plan.
  // A real subscription must also replace an earlier sandbox record regardless
  // of the tester's purchase timestamp or notification delivery order.
  if(existing.environment!==state.environment){
    if(existing.environment==='production')return false;
    if(state.environment==='production')return !['SUBSCRIPTION_STATE_PENDING','SUBSCRIPTION_STATE_PENDING_PURCHASE_CANCELED'].includes(state.status);
  }
  const pending=['SUBSCRIPTION_STATE_PENDING','SUBSCRIPTION_STATE_PENDING_PURCHASE_CANCELED'].includes(state.status);
  return existing.tokenHash===tokenHash||!pending&&(existing.startedAt?.toMillis?.()??0)<state.startedAt;
}
function money(value,currency){
  if(!value||!/^[A-Z]{3}$/.test(value.currencyCode)||currency&&value.currencyCode!==currency||!/^\d{1,18}$/.test(String(value.units??'0'))||!Number.isInteger(value.nanos??0)||(value.nanos??0)<0||(value.nanos??0)>999999999)throw new BillingError('failed-precondition','Số tiền từ Google chưa hợp lệ.');
  return {currency:value.currencyCode,nanos:BigInt(value.units??0)*1000000000n+BigInt(value.nanos??0)};
}
function order(data,{uid,token,productId,environment,orderId}){
  if(data.orderId!==orderId||data.purchaseToken!==token||data.lineItems?.length!==1||data.lineItems[0].productId!==productId)throw new BillingError('permission-denied','Đơn hàng không khớp biên nhận.');
  const amount=money(data.total),history=data.orderHistory??{};
  const states={PROCESSED:'paid',PENDING:'pending',CANCELED:'cancelled',PENDING_REFUND:'pending_refund',PARTIALLY_REFUNDED:'partially_refunded',REFUNDED:'refunded'};
  const status=states[data.state];if(!status)throw new BillingError('failed-precondition','Trạng thái đơn hàng chưa hỗ trợ.');
  let refunds=0n;
  for(const event of history.partialRefundEvents??[])if(event.state==='PROCESSED_SUCCESSFULLY')refunds+=money(event.refundDetails?.total,amount.currency).nanos;
  if(history.refundEvent)refunds+=money(history.refundEvent.refundDetails?.total,amount.currency).nanos;
  if(refunds>amount.nanos||status==='refunded'&&refunds!==amount.nanos||status==='partially_refunded'&&refunds===0n)throw new BillingError('failed-precondition','Cần đối soát số tiền hoàn với Google.');
  return {provider:'google_play',verified:true,uid,productId,environment,orderId,status,currency:amount.currency,totalNanos:String(amount.nanos),refundedNanos:String(refunds),netNanos:String(amount.nanos-refunds),occurredAt:timestamp(history.processedEvent?.eventTime||data.createTime),providerUpdatedAt:timestamp(data.lastEventTime||data.createTime)};
}
module.exports={BillingError,configuration,validateIdentity,accountId,hash,tokenValue,subscription,replaceMembership,order};
