
import express from 'express';
const router = express.Router();

router.get('/', (req,res)=>res.json([{id:1,name:'Dealer 1'}]));

export default router;
