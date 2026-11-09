'use strict';
const {GoogleAuth}=require('google-auth-library');
// Application Default Credentials: never ship a service-account key to Flutter.
class PlayPublisher {
  constructor(packageName){this.packageName=encodeURIComponent(packageName);this.auth=new GoogleAuth({scopes:['https://www.googleapis.com/auth/androidpublisher']});}
  async request(path,method='GET',body){
    const client=await this.auth.getClient();
    const response=await client.request({url:`https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${this.packageName}/${path}`,method,...(body?{data:body}:{}),timeout:20000,retry:false});
    return response.data;
  }
  getSubscription(token){return this.request(`purchases/subscriptionsv2/tokens/${encodeURIComponent(token)}`);}
  getOrder(orderId){return this.request(`orders/${encodeURIComponent(orderId)}`);}
  acknowledge(productId,token){return this.request(`purchases/subscriptions/${encodeURIComponent(productId)}/tokens/${encodeURIComponent(token)}:acknowledge`,'POST',{});}
}
module.exports={PlayPublisher};
