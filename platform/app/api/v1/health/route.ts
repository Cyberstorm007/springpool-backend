import { NextResponse } from 'next/server';
export function GET(){return NextResponse.json({success:true,data:{status:'ok',stage:'foundation'},error:null,requestId:crypto.randomUUID()},{headers:{'Cache-Control':'no-store'}});}
