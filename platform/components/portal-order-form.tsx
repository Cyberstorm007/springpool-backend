'use client';
import {useState} from 'react';
import {useFormStatus} from 'react-dom';
import {submitRequest} from '@/app/portal/requests/actions';
export type CatalogItem={id:string,name:string,sku:string,unit_price:number,gst_rate:number,unit:string};
function Submit(){const {pending}=useFormStatus();return <button disabled={pending}>{pending?'Submitting…':'Submit order request'}</button>;}
export function PortalOrderForm({products,requestKey}:{products:CatalogItem[],requestKey:string}){
 const [rows,setRows]=useState([0]);
 return <form action={submitRequest} className="form-grid"><input type="hidden" name="kind" value="ORDER"/><input type="hidden" name="key" value={requestKey}/><label>Order title<input name="title" required minLength={2} maxLength={160} defaultValue="Product order"/></label><label>Delivery address and instructions<textarea name="body" required maxLength={2000}/></label><div className="full-width">{rows.map((r,i)=><div className="inline-form" key={r}><label>Product {i+1}<select name="product_id" required><option value="">Select product</option>{products.map(p=><option key={p.id} value={p.id}>{p.name} · {p.sku} · ₹{p.unit_price}/{p.unit} + {p.gst_rate}% GST</option>)}</select></label><label>Quantity<input name="quantity" type="number" min="0.001" max="1000000" step="0.001" defaultValue="1" required/></label>{rows.length>1&&<button type="button" className="secondary" onClick={()=>setRows(rows.filter(v=>v!==r))}>Remove</button>}</div>)}<button type="button" className="secondary" disabled={rows.length>=50} onClick={()=>setRows([...rows,Math.max(...rows)+1])}>Add product</button></div><p>Prices are estimates. SpringPool confirms current prices, stock, delivery and credit before approving an order.</p><Submit/></form>;
}
