const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');

let mongoServer;
let isInMemory = false;

const connect = async () => {
  if (process.env.NODE_ENV === 'test' && !isInMemory) {
    mongoServer = await MongoMemoryServer.create();
    const mongoUri = mongoServer.getUri();
    await mongoose.connect(mongoUri);
    isInMemory = true;
  }
};

const close = async () => {
  if (isInMemory) {
    await mongoose.disconnect();
    if (mongoServer) {
      await mongoServer.stop();
    }
    isInMemory = false;
  }
};

const clear = async () => {
  if (isInMemory) {
    const collections = mongoose.connection.collections;
    for (const key in collections) {
      await collections[key].deleteMany({});
    }
  }
};

module.exports = { connect, close, clear };