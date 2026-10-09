import {NextRequest,NextResponse} from 'next/server';
import {z} from 'zod';
import {membership} from '@/lib/auth';
import {reports,toCsv} from '@/lib/operations/reports';
export async function GET(request:NextRequest){
 const {db,organizationId}=await membership();if(!organizationId)return NextResponse.json({error:'Workspace required'},{status:403});const permission=await db.rpc('has_permission',{org_id:organizationId,permission_code:'reports.view'});if(permission.error||permission.data!==true)return NextResponse.json({error:'Report access required'},{status:403});
 const p=z.object({report:z.enum(Object.keys(reports) as [keyof typeof reports,...(keyof typeof reports)[]]),from:z.iso.date(),to:z.iso.date()}).safeParse(Object.fromEntries(request.nextUrl.searchParams));
 if(!p.success||p.data.from>p.data.to)return NextResponse.json({error:'Select valid report dates'},{status:400});
 const config:{table:string,fields:string,date:string,kind:string|null}=reports[p.data.report],rows:Record<string,unknown>[]=[];
 for(let start=0;start<=10000;start+=1000){
  let query=db.from(config.table).select(config.fields).eq('organization_id',organizationId).gte(config.date,p.data.from).lte(config.date,p.data.to).order(config.date).order('id').range(start,start+999);
  if(config.kind)query=query.eq('kind',config.kind);
  const {data,error}=await query;if(error)return NextResponse.json({error:'Report unavailable'},{status:500});
  rows.push(...(data as unknown as Record<string,unknown>[]));if(rows.length>10000)return NextResponse.json({error:'More than 10,000 rows. Choose a shorter date range.'},{status:422});if(data.length<1000)break;
 }
 return new NextResponse(toCsv(config.fields.split(','),rows),{headers:{'Content-Type':'text/csv; charset=utf-8','Content-Disposition':`attachment; filename="springpool-${p.data.report}-${p.data.from}-${p.data.to}.csv"`,'Cache-Control':'private, no-store','X-Content-Type-Options':'nosniff'}});
}
