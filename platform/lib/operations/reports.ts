export const reports={
 invoices:{title:'Sales invoices',table:'business_documents',fields:'number,document_date,due_date,state,subtotal,tax_total,cgst,sgst,igst,grand_total',date:'document_date',kind:'INVOICE'},
 orders:{title:'Sales orders',table:'business_documents',fields:'number,document_date,due_date,state,subtotal,tax_total,grand_total',date:'document_date',kind:'ORDER'},
 purchases:{title:'Purchase orders',table:'business_documents',fields:'number,document_date,due_date,state,subtotal,tax_total,grand_total',date:'document_date',kind:'PURCHASE'},
 payments:{title:'Payments',table:'document_payments',fields:'document_id,amount,method,reference,paid_on',date:'paid_on',kind:null},
 expenses:{title:'Expenses',table:'expenses',fields:'name,amount,expense_date,category,reference,notes',date:'expense_date',kind:null},
 attendance:{title:'Employee attendance',table:'employee_attendance',fields:'employee_id,work_date,status,check_in,check_out,break_minutes,notes',date:'work_date',kind:null},
 work:{title:'Daily work',table:'employee_work_logs',fields:'employee_id,work_date,title,description,minutes,status,review_status',date:'work_date',kind:null},
 production:{title:'Production batches',table:'production_runs',fields:'batch_number,product_id,warehouse_id,quantity,manufactured_on,expires_on,notes',date:'manufactured_on',kind:null},
} as const;
export function csvCell(value:unknown){let text=value==null?'':String(value);if(/^[\s]*[=+@-]/.test(text))text="'"+text;return '"'+text.replaceAll('"','""')+'"';}
export function toCsv(fields:string[],rows:Record<string,unknown>[]){return '\uFEFF'+[fields.map(csvCell).join(','),...rows.map(row=>fields.map(f=>csvCell(row[f])).join(','))].join('\r\n');}
