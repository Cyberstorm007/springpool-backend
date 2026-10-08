'use client';
import Link from 'next/link';
import {usePathname} from 'next/navigation';
const groups:Record<string,string>={'/dashboard':'Workspace','/records/leads':'Relationships & sales','/records/products':'Supply & operations','/finance':'Finance','/records/tasks':'Team & administration'};
export function WorkspaceNav({links}:{links:string[][]}){const pathname=usePathname();return <nav aria-label="Main navigation">{links.map(([href,label])=><div key={href}>{groups[href]&&<p className="nav-label">{groups[href]}</p>}<Link href={href} aria-current={pathname===href?'page':undefined}><span>{label}</span><span className="nav-arrow" aria-hidden="true">↗</span></Link></div>)}</nav>;}
