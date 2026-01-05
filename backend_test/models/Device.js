const mongoose = require('mongoose');

const deviceSchema = new mongoose.Schema({
  deviceId: {
    type: String,
    required: true,
    unique: true
  },
  fcmToken: {
    type: String,
    required: true
  },
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    default: null
  },
  platform: {
    type: String,
    enum: ['iOS', 'Android', 'unknown'],
    default: 'unknown'
  },
  deviceInfo: {
    type: String,
    default: null
  },
  lastActive: {
    type: Date,
    default: Date.now
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

// Update lastActive before save
deviceSchema.pre('save', function() {
  this.lastActive = Date.now();
});

const Device = mongoose.model('Device', deviceSchema);

module.exports = Device;
