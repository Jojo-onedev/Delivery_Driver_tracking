const express = require('express');
const dotenv = require('dotenv');
const mongoose = require('mongoose');

dotenv.config();

const app = express();

app.use(express.json());

// Routes
app.use('/api/auth', require('./routes/auth'));
app.use('/api/deliveries', require('./routes/delivery'));

// Connexion MongoDB
mongoose
    .connect(process.env.MONGO_URI)
    .then(() => console.log('Mongo connected Successfully'))
    .catch((err) => console.log(err));

// Route de test
app.get('/', (req, res) => {
    res.status(200).json({ welcome: "Job Portal API" });
});

const PORT = process.env.PORT || 5001;
app.listen(PORT, () => console.log(`Running on port ${PORT}`));