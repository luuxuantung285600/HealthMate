import {test} from 'node:test';import assert from 'node:assert/strict';
import {verifiedRevenue,formatNanos,verifiedRevenueExport} from '../dist/verified-revenue.mjs';
const range={start:'2026-11-01',end:'2026-11-30'};
const row=(id,patch={})=>({id,uid:'alice',orderId:id,provider:'google_play',verified:true,environment:'production',status:'paid',currency:'VND',totalNanos:'29000000000000',refundedNanos:'0',netNanos:'29000000000000',occurredAt:{toMillis:()=>Date.parse('2026-11-07T04:00:00Z')},...patch});
test('production and test money remain separate, currencies never converted or mixed',()=>{
  const rows=[row('paid'),row('sandbox',{environment:'test'}),row('usd',{currency:'USD',totalNanos:'1990000000',netNanos:'1990000000'})];
  const report=verifiedRevenue(rows,range);assert.equal(report.count,2);assert.equal(report.currencies.length,2);
  assert.equal(report.currencies.find(g=>g.currency==='VND').net,'29000000000000');
  assert.equal(verifiedRevenue(rows,{...range,environment:'test'}).count,1);
});
test('unresolved receipts excluded, refunds adjust original order, cancelled and pending excluded',()=>{
  const report=verifiedRevenue([row('refund',{status:'partially_refunded',refundedNanos:'4000000000000',netNanos:'25000000000000'}),row('pending',{status:'pending'}),row('unresolved',{status:'awaiting_order',totalNanos:null,netNanos:null,refundedNanos:null,currency:null})],range);
  assert.equal(report.count,1);assert.equal(report.unresolved,1);assert.equal(report.currencies[0].net,'25000000000000');
  assert.equal(verifiedRevenueExport(report,'production').rows.length,3);
});
test('invalid data fails closed; precision preserved above JS integer limit',()=>{
  assert.equal(verifiedRevenue([row('stale',{reconciliationPending:true})],range).count,0);
  assert.throws(()=>verifiedRevenue([row('demo',{provider:'demo'})],range));
  assert.throws(()=>verifiedRevenue([row('x'),row('x')],range));
  assert.throws(()=>verifiedRevenue([row('x',{netNanos:'1'})],range));
  assert.equal(formatNanos('9999999999999999999999999','USD'),'9.999.999.999.999.999,999999999 USD');
});

test('duplicate order under a different document cannot double count revenue',()=>{
  assert.throws(()=>verifiedRevenue([row('a',{orderId:'GPA-same'}),row('b',{orderId:'GPA-same'})],range));
});

test('refund states and pending flags must match verified numeric data',()=>{
  for(const reconciliationPending of ['true','false',0,1,null])assert.throws(()=>verifiedRevenue([row('x',{reconciliationPending})],range));
  assert.throws(()=>verifiedRevenue([row('x',{status:'refunded',refundedNanos:'0'})],range));
  assert.throws(()=>verifiedRevenue([row('x',{status:'partially_refunded',refundedNanos:'0'})],range));
  const report=verifiedRevenue([row('refunded',{status:'refunded',refundedNanos:'29000000000000',netNanos:'0'})],range);
  assert.equal(report.currencies[0].net,'0');
});

test('known old amounts awaiting reconciliation stay excluded from totals and exported amounts',()=>{
  const report=verifiedRevenue([row('stale',{reconciliationPending:true})],range);
  assert.equal(report.count,0);assert.equal(report.buyers,0);assert.equal(report.unresolved,1);assert.deepEqual(report.currencies,[]);
  const cells=verifiedRevenueExport(report,'production').rows[0];
  assert.deepEqual(cells.slice(4),Array(4).fill('Chờ đối soát'));
});
