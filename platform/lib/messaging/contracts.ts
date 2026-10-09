/** Future adapters must implement this boundary. No adapter is active in this release. */
export type MessagingChannel='WHATSAPP'|'TELEGRAM';
export type DeliveryResult=
 | {status:'SENT';providerMessageId:string}
 | {status:'FAILED';retryable:boolean;retryAfterSeconds?:number}
 | {status:'UNKNOWN'};
export interface MessageEnvelope {
 eventId:string;
 organizationId:string;
 recipientId:string;
 template:string;
 parameters:Record<string,string>;
}
export interface MessagingAdapter {
 channel:MessagingChannel;
 send(message:MessageEnvelope):Promise<DeliveryResult>;
 verifyWebhook(request:Request):Promise<boolean>;
}
// UNKNOWN means delivery may have occurred: reconcile before retrying to avoid duplicates.
export const messagingEnabled=false;
