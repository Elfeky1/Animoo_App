const express = require('express');
const cors = require('cors');

const authRoutes = require('./routes/auth.routes');
const animalRoutes = require('./routes/animal.routes');

const app = express();

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true })); 

app.use('/api/auth', authRoutes);
app.use('/api/animals', animalRoutes);

const path = require('path');

app.use('/uploads', express.static(path.join(__dirname, '../uploads')));



const adRoutes = require('./routes/ad.routes');
app.use('/api/ads', adRoutes);

app.use('/api/admin', require('./routes/admin.routes'));
app.use('/api/chat', require('./routes/chat.routes'));
app.use('/api/notifications', require('./routes/notification.routes'));
app.use('/api/pets', require('./routes/pet.routes'));
app.use('/api/ratings', require('./routes/rating.routes'));

module.exports = app;
