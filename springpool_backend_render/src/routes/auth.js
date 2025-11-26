
import express from 'express';
const router = express.Router();

router.post('/login',(req,res)=>{
    return res.json({token:'sample_jwt_token'});
});

export default router;
