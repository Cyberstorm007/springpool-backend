import express from 'express';
const router = express.Router();
router.post('/login', (_req, res) => res.status(503).json({error:'Legacy sign-in is disabled. Use the Supabase-authenticated platform.'}));
export default router;
