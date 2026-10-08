import Link from 'next/link';
import {Workspace} from '@/components/workspace';
import {operationsAccess} from '@/lib/operations/access';
import {today} from '@/lib/workforce/validation';
export const dynamic='force-dynamic';
export default async function Alerts(){
 const a=await operationsAccess();if(!a.admin||!a.organizationId)return <Workspace email={a.user.email}><h1>Administrator access required</h1></Workspace>;
 const date=today();
 const [metrics,requests,leads,tasks]=await Promise.all([
  a.db.rpc('management_metrics',{org_id:a.organizationId,period_start:date,period_end:date}),
  a.db.from('portal_requests').select('id,subject,kind,created_at',{count:'exact'}).eq('organization_id',a.organizationId).eq('status','SUBMITTED').order('created_at').limit(20),
  a.db.from('leads').select('id,name,next_follow_up',{count:'exact'}).eq('organization_id',a.organizationId).lt('next_follow_up',date).not('stage','in','(CONVERTED,LOST)').order('next_follow_up').limit(20),
  a.db.from('business_tasks').select('id,name,due_date,priority',{count:'exact'}).eq('organization_id',a.organizationId).lt('due_date',date).not('status','in','(DONE,CANCELLED)').order('due_date').limit(20)
 ]);
 if(metrics.error||requests.error||leads.error||tasks.error)throw new Error('Unable to load operational alerts.');
 const signals=[{title:'New portal requests',value:requests.count||0,href:'/admin/requests'}, {title:'Low stock balances',value:metrics.data.low_stock,href:'/inventory'}, {title:'Overdue follow-ups',value:leads.count||0,href:'/records/leads'}, {title:'Overdue tasks',value:tasks.count||0,href:'/records/tasks'}];
 return <Workspace email={a.user.email}><header><p className="eyebrow">OPERATIONS</p><h1>Alerts & follow-ups</h1><p>Current signals from recorded data. Resolve the underlying task or request to clear its alert. Refresh to see new activity.</p></header><div className="grid">{signals.map(s=><section key={s.title} className="panel"><p className="eyebrow">{s.title}</p><h2>{s.value}</h2><Link href={s.href}>Review →</Link></section>)}</div><section className="panel"><h2>Requests awaiting review</h2><p>Showing the oldest 20 of {requests.count||0} submissions.</p>{requests.data.map(r=><p key={r.id}><Link href="/admin/requests">{r.subject}</Link> · {r.kind} · {new Date(r.created_at).toLocaleDateString('en-IN',{timeZone:'Asia/Kolkata'})}</p>)}{!requests.data.length&&<p>No new requests awaiting review.</p>}</section><div className="grid"><section className="panel"><h2>Overdue customer follow-ups</h2><p>Oldest 20 follow-ups.</p>{leads.data.map(l=><p key={l.id}><Link href={'/records/leads?q='+encodeURIComponent(l.name)}>{l.name}</Link> · Due {l.next_follow_up}</p>)}{!leads.data.length&&<p>No overdue follow-ups.</p>}</section><section className="panel"><h2>Overdue tasks</h2><p>Oldest 20 tasks.</p>{tasks.data.map(t=><p key={t.id}><Link href={'/records/tasks?q='+encodeURIComponent(t.name)}>{t.name}</Link> · {t.priority} · Due {t.due_date}</p>)}{!tasks.data.length&&<p>No overdue tasks.</p>}</section></div><section className="panel"><h2>Message delivery</h2><p>WhatsApp and Telegram are not connected. These alerts remain available in the workspace.</p><Link href="/settings/integrations">Messaging setup plans →</Link></section></Workspace>;
}
