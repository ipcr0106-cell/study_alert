import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import sessionRoutes from './routes/sessionRoutes.js';
import subjectRoutes from './routes/subjectRoutes.js';

const app = express();
const port = process.env.PORT || 4000;

app.use(cors());
app.use(express.json());

app.get('/', (_req, res) => {
  res.json({ message: 'FocusGuard API 동작 중' });
});

app.use('/session', sessionRoutes);
app.use('/subjects', subjectRoutes);

app.listen(port, () => {
  console.log(`FocusGuard backend listening on port ${port}`);
});

