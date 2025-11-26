
import express from 'express';
import jwt from 'jsonwebtoken';
const router = express.Router();

router.post('/login',(req,res)=>{
    const token = jwt.sign({user:'admin'}, process.env.JWT_SECRET);
    return res.json({token});
});

export default router;
