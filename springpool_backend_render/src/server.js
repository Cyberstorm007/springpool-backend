
import express from 'express';
import cors from 'cors';
import authRoutes from './routes/auth.js';
import dealerRoutes from './routes/dealers.js';

const app = express();
app.use(cors());
app.use(express.json());

app.get('/', (req,res)=>res.send('Springpool ERP Backend Running'));
app.use('/auth', authRoutes);
app.use('/dealers', dealerRoutes);

const port = process.env.PORT || 8080;
app.listen(port, ()=>console.log('Backend running on port', port));
