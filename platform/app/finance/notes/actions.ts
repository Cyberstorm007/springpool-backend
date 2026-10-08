'use server';
import {redirect} from 'next/navigation';
export async function issueNote(){redirect('/finance/notes?error=Issuance+is+paused+pending+finance+validation');}
