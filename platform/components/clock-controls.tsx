'use client';
import {useFormStatus} from 'react-dom';
import {clockAttendance} from '@/app/attendance/clock';
function ClockButton({direction}:{direction:'in'|'out'}){const {pending}=useFormStatus();return <button disabled={pending}>{pending?'Recording…':direction==='in'?'Check in now':'Check out now'}</button>;}
export function ClockControls(){return <div className="clock-actions">{(['in','out'] as const).map(direction=><form action={clockAttendance} key={direction}><input name="direction" type="hidden" value={direction}/><ClockButton direction={direction}/></form>)}</div>;}
