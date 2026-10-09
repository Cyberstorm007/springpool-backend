import { z } from 'zod';
export const credentials = z.object({email:z.email().max(254),password:z.string().min(1).max(128)});
export const companyInput=z.object({
 organization_id:z.uuid(),
 display_name:z.string().trim().min(2).max(120),
 legal_name:z.string().trim().min(2).max(200),
 email:z.union([z.email(),z.literal('')]),
 phone:z.string().trim().max(30),
 website:z.union([z.url({protocol:/^https$/}),z.literal('')]),
 registered_address:z.string().trim().max(1000),
 gstin:z.union([z.string().regex(/^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]$/),z.literal('')]),
 pan:z.union([z.string().regex(/^[A-Z]{5}[0-9]{4}[A-Z]$/),z.literal('')])
}).strict();
