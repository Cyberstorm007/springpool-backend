import type {MetadataRoute} from 'next';
export default function robots():MetadataRoute.Robots{return{rules:{userAgent:'*',disallow:['/','/auth/','/api/']},host:'https://springpool.org'}};
