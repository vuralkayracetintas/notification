const express = require('express');
const cors = require('cors');
const admin = require('firebase-admin');
const swaggerUi = require('swagger-ui-express');
const swaggerJsdoc = require('swagger-jsdoc');
const mongoose = require('mongoose');

const app = express();
const PORT = 3000;

// MongoDB Connection
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/notification_db';

mongoose.connect(MONGODB_URI)
.then(() => console.log('✅ MongoDB bağlantısı başarılı'))
.catch(err => console.error('❌ MongoDB bağlantı hatası:', err));

// Middleware
app.use(cors());
app.use(express.json());

// Swagger configuration
const swaggerOptions = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'Firebase Notification API',
      version: '1.0.0',
      description: 'Device ID bazlı Firebase Cloud Messaging API dokümantasyonu',
      contact: {
        name: 'API Support',
        email: 'support@example.com'
      }
    },
    servers: [
      {
        url: 'http://localhost:3000',
        description: 'Development server'
      }
    ],
    tags: [
      {
        name: 'Users',
        description: 'User bazlı işlemler'
      },
      {
        name: 'Devices',
        description: 'Device bazlı işlemler'
      },
      {
        name: 'Notifications',
        description: 'Bildirim gönderme işlemleri'
      }
    ]
  },
  apis: ['./server.js']
};

const swaggerDocs = swaggerJsdoc(swaggerOptions);
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerDocs, {
  customCss: '.swagger-ui .topbar { display: none }',
  customSiteTitle: 'Notification API Docs'
}));

// Firebase Admin SDK Initialize
const serviceAccount = require('./service_account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

console.log('✅ Firebase Admin initialized');

// Import MongoDB Models
const User = require('./models/User');
const Device = require('./models/Device');

// Mock database (memory) - DEPRECATED, MongoDB kullanılıyor
// const users = { ... };
// const devices = { ... };

// ===== ENDPOINTS =====

/**
 * @swagger
 * /:
 *   get:
 *     summary: API durumunu kontrol et
 *     tags: [Health]
 *     responses:
 *       200:
 *         description: Server çalışıyor
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 status:
 *                   type: string
 *                   example: running
 *                 message:
 *                   type: string
 *                 endpoints:
 *                   type: object
 */
// Health check
app.get('/', (req, res) => {
  res.json({
    status: 'running',
    message: '🚀 Notification Backend Test Server',
    endpoints: {
      'POST /api/register-token': 'FCM token kaydet (User ID bazlı)',
      'POST /api/register-device': 'Device bilgilerini kaydet (Device ID bazlı)',
      'POST /api/send-notification': 'Tek kullanıcıya bildirim',
      'POST /api/send-to-device': 'Belirli device\'a bildirim gönder',
      'POST /api/send-invitation': 'Davetiye gönder',
      'POST /api/send-message': 'Mesaj bildirimi',
      'POST /api/send-bulk': 'Toplu bildirim (User bazlı)',
      'POST /api/send-bulk-devices': 'Toplu bildirim (Device bazlı)',
      'GET /api/users': 'Tüm kullanıcıları listele',
      'GET /api/devices': 'Kayıtlı tüm device\'ları listele'
    }
  });
});

/**
 * @swagger
 * /api/users:
 *   get:
 *     summary: Tüm kullanıcıları listele
 *     tags: [Users]
 *     responses:
 *       200:
 *         description: Kullanıcı listesi
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 users:
 *                   type: array
 *                   items:
 *                     type: object
 *                     properties:
 *                       id:
 *                         type: string
 *                       name:
 *                         type: string
 *                       email:
 *                         type: string
 *                       hasToken:
 *                         type: boolean
 */
// Kullanıcıları listele
app.get('/api/users', async (req, res) => {
  try {
    const users = await User.find().select('-__v');
    res.json({
      success: true,
      users: users.map(u => ({
        id: u._id,
        name: u.name,
        email: u.email,
        hasToken: !!u.fcmToken,
        createdAt: u.createdAt
      }))
    });
  } catch (error) {
    console.error('❌ Hata:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * @swagger
 * /api/register-token:
 *   post:
 *     summary: FCM token kaydet (User ID bazlı)
 *     tags: [Users]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - userId
 *               - fcmToken
 *             properties:
 *               userId:
 *                 type: string
 *                 example: user1
 *               fcmToken:
 *                 type: string
 *                 example: fcm-token-xyz
 *     responses:
 *       200:
 *         description: Token başarıyla kaydedildi
 *       400:
 *         description: Eksik parametreler
 *       404:
 *         description: Kullanıcı bulunamadı
 */
// FCM Token kaydet
app.post('/api/register-token', async (req, res) => {
  const { userId, fcmToken } = req.body;

  if (!userId || !fcmToken) {
    return res.status(400).json({
      success: false,
      error: 'userId ve fcmToken gerekli'
    });
  }

  try {
    const user = await User.findById(userId);

    if (!user) {
      return res.status(404).json({
        success: false,
        error: 'Kullanıcı bulunamadı'
      });
    }

    user.fcmToken = fcmToken;
    await user.save();

    console.log(`✅ Token kaydedildi: ${user.name}`);

    res.json({
      success: true,
      message: 'FCM token başarıyla kaydedildi',
      user: {
        id: user._id,
        name: user.name
      }
    });
  } catch (error) {
    console.error('❌ Hata:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Basit bildirim gönder
app.post('/api/send-notification', async (req, res) => {
  const { userId, title, body, data } = req.body;

  if (!userId || !title || !body) {
    return res.status(400).json({
      success: false,
      error: 'userId, title ve body gerekli'
    });
  }

  try {
    const user = await User.findById(userId);

    if (!user) {
      return res.status(404).json({
        success: false,
        error: 'Kullanıcı bulunamadı'
      });
    }

    if (!user.fcmToken) {
      return res.status(400).json({
        success: false,
        error: 'Kullanıcının FCM token\'ı yok'
      });
    }

    const message = {
      token: user.fcmToken,
      notification: {
        title: title,
        body: body
      },
      data: data || {},
      android: {
        priority: 'high'
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1
          }
        }
      }
    };

    const response = await admin.messaging().send(message);

    console.log(`✅ Bildirim gönderildi: ${user.name}`);

    res.json({
      success: true,
      message: 'Bildirim başarıyla gönderildi',
      messageId: response,
      recipient: {
        id: user._id,
        name: user.name
      }
    });
  } catch (error) {
    console.error('❌ Hata:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Davetiye gönder
app.post('/api/send-invitation', async (req, res) => {
  const { inviterId, invitedUserId, eventName } = req.body;

  if (!inviterId || !invitedUserId || !eventName) {
    return res.status(400).json({
      success: false,
      error: 'inviterId, invitedUserId ve eventName gerekli'
    });
  }

  try {
    const inviter = await User.findById(inviterId);
    const invitedUser = await User.findById(invitedUserId);

    if (!inviter || !invitedUser) {
      return res.status(404).json({
        success: false,
        error: 'Kullanıcı bulunamadı'
      });
    }

    if (!invitedUser.fcmToken) {
      return res.status(400).json({
        success: false,
        error: 'Davet edilen kullanıcının FCM token\'ı yok'
      });
    }

    const invitationId = Date.now().toString();

    const message = {
      token: invitedUser.fcmToken,
      notification: {
        title: `📨 ${inviter.name} seni davet etti!`,
        body: `${eventName} etkinliğine katılmak ister misin?`
      },
      data: {
        type: 'invitation',
        invitationId: invitationId,
        inviterId: inviter._id.toString(),
        inviterName: inviter.name,
        eventName: eventName,
        screen: 'invitation_detail'
      },
      android: {
        priority: 'high',
        notification: {
          sound: 'default',
          clickAction: 'FLUTTER_NOTIFICATION_CLICK',
          color: '#FF6B6B'
        }
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1
          }
        }
      }
    };

    const response = await admin.messaging().send(message);

    console.log(`✅ Davetiye gönderildi: ${inviter.name} → ${invitedUser.name}`);

    res.json({
      success: true,
      message: 'Davetiye başarıyla gönderildi',
      invitation: {
        id: invitationId,
        inviter: inviter.name,
        invitedUser: invitedUser.name,
        eventName: eventName
      },
      messageId: response
    });
  } catch (error) {
    console.error('❌ Hata:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Mesaj bildirimi
app.post('/api/send-message', async (req, res) => {
  const { senderId, recipientId, messageText } = req.body;

  if (!senderId || !recipientId || !messageText) {
    return res.status(400).json({
      success: false,
      error: 'senderId, recipientId ve messageText gerekli'
    });
  }

  try {
    const sender = await User.findById(senderId);
    const recipient = await User.findById(recipientId);

    if (!sender || !recipient) {
      return res.status(404).json({
        success: false,
        error: 'Kullanıcı bulunamadı'
      });
    }

    if (!recipient.fcmToken) {
      return res.status(400).json({
        success: false,
        error: 'Alıcının FCM token\'ı yok'
      });
    }

    const message = {
      token: recipient.fcmToken,
      notification: {
        title: `💬 ${sender.name}'den yeni mesaj`,
        body: messageText
      },
      data: {
        type: 'message',
        senderId: sender._id.toString(),
        senderName: sender.name,
        messageText: messageText,
        screen: 'chat'
      },
      android: {
        priority: 'high'
      }
    };

    const response = await admin.messaging().send(message);

    console.log(`✅ Mesaj bildirimi: ${sender.name} → ${recipient.name}`);

    res.json({
      success: true,
      message: 'Mesaj bildirimi gönderildi',
      messageId: response
    });
  } catch (error) {
    console.error('❌ Hata:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Toplu bildirim (tüm kullanıcılara - user bazlı)
app.post('/api/send-bulk', async (req, res) => {
  const { title, body, data } = req.body;

  if (!title || !body) {
    return res.status(400).json({
      success: false,
      error: 'title ve body gerekli'
    });
  }

  try {
    const usersWithToken = await User.find({ fcmToken: { $ne: null } });

    if (usersWithToken.length === 0) {
      return res.status(400).json({
        success: false,
        error: 'Token\'ı olan kullanıcı yok'
      });
    }

    const messages = usersWithToken.map(user => ({
      token: user.fcmToken,
      notification: {
        title: title,
        body: body
      },
      data: data || {},
      android: {
        priority: 'high'
      }
    }));

    // Firebase sendEach() maksimum 500 mesaj alır, batch olarak gönder
    const BATCH_SIZE = 500;
    let totalSuccess = 0;
    let totalFailure = 0;
    const batches = [];

    for (let i = 0; i < messages.length; i += BATCH_SIZE) {
      const batch = messages.slice(i, i + BATCH_SIZE);
      batches.push(batch);
    }

    console.log(`📤 ${messages.length} kullanıcıya ${batches.length} batch halinde gönderiliyor...`);

    for (let i = 0; i < batches.length; i++) {
      const batch = batches[i];
      const response = await admin.messaging().sendEach(batch);
      totalSuccess += response.successCount;
      totalFailure += response.failureCount;
      console.log(`   Batch ${i + 1}/${batches.length}: ${response.successCount}/${batch.length} başarılı`);
    }

    console.log(`✅ Toplu bildirim tamamlandı: ${totalSuccess}/${messages.length} başarılı`);

    res.json({
      success: true,
      message: 'Toplu bildirim gönderildi',
      totalUsers: messages.length,
      successCount: totalSuccess,
      failureCount: totalFailure,
      batchCount: batches.length,
      batchSize: BATCH_SIZE
    });
  } catch (error) {
    console.error('❌ Hata:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * @swagger
 * /api/send-bulk-devices:
 *   post:
 *     summary: Tüm kayıtlı device'lara toplu bildirim gönder
 *     tags: [Notifications]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - title
 *               - body
 *             properties:
 *               title:
 *                 type: string
 *                 example: Toplu Bildirim
 *               body:
 *                 type: string
 *                 example: Bu bildirim tüm cihazlara gönderildi
 *               data:
 *                 type: object
 *               platform:
 *                 type: string
 *                 enum: [iOS, Android]
 *                 example: iOS
 *     responses:
 *       200:
 *         description: Toplu bildirim gönderildi
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 totalDevices:
 *                   type: integer
 *                 successCount:
 *                   type: integer
 *                 failureCount:
 *                   type: integer
 *       400:
 *         description: Eksik parametreler veya device bulunamadı
 */
// Toplu bildirim (tüm kayıtlı device'lara - device bazlı)
app.post('/api/send-bulk-devices', async (req, res) => {
  const { title, body, data, platform } = req.body;

  if (!title || !body) {
    return res.status(400).json({
      success: false,
      error: 'title ve body gerekli'
    });
  }

  try {
    let query = {};
    // Platform filtresi varsa uygula
    if (platform) {
      query.platform = platform;
    }

    const targetDevices = await Device.find(query);

    if (targetDevices.length === 0) {
      return res.status(400).json({
        success: false,
        error: 'Kayıtlı device bulunamadı'
      });
    }

    const messages = targetDevices.map(device => ({
      token: device.fcmToken,
      notification: {
        title: title,
        body: body
      },
      data: data || {},
      android: {
        priority: 'high',
        notification: {
          sound: 'default',
          clickAction: 'FLUTTER_NOTIFICATION_CLICK'
        }
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1
          }
        }
      }
    }));

    // Firebase sendEach() maksimum 500 mesaj alır, batch olarak gönder
    const BATCH_SIZE = 500;
    let totalSuccess = 0;
    let totalFailure = 0;
    const batches = [];

    for (let i = 0; i < messages.length; i += BATCH_SIZE) {
      const batch = messages.slice(i, i + BATCH_SIZE);
      batches.push(batch);
    }

    console.log(`📤 ${messages.length} cihaza ${batches.length} batch halinde gönderiliyor...`);

    for (let i = 0; i < batches.length; i++) {
      const batch = batches[i];
      const response = await admin.messaging().sendEach(batch);
      totalSuccess += response.successCount;
      totalFailure += response.failureCount;
      console.log(`   Batch ${i + 1}/${batches.length}: ${response.successCount}/${batch.length} başarılı`);
    }

    console.log(`✅ Toplu device bildirimi tamamlandı: ${totalSuccess}/${messages.length} başarılı`);
    if (platform) {
      console.log(`   Platform filtresi: ${platform}`);
    }

    res.json({
      success: true,
      message: 'Toplu bildirim tüm kayıtlı device\'lara gönderildi',
      totalDevices: messages.length,
      successCount: totalSuccess,
      failureCount: totalFailure,
      batchCount: batches.length,
      batchSize: BATCH_SIZE,
      platform: platform || 'all',
      devices: targetDevices.map(d => ({
        deviceId: d.deviceId,
        platform: d.platform,
        userId: d.userId
      }))
    });
  } catch (error) {
    console.error('❌ Hata:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * @swagger
 * /api/create-user:
 *   post:
 *     summary: Yeni kullanıcı oluştur
 *     tags: [Users]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - name
 *               - email
 *             properties:
 *               name:
 *                 type: string
 *                 example: Ali Veli
 *               email:
 *                 type: string
 *                 example: ali@example.com
 *     responses:
 *       201:
 *         description: Kullanıcı başarıyla oluşturuldu
 *       400:
 *         description: Eksik parametreler veya email zaten kullanılıyor
 */
// Yeni kullanıcı oluştur
app.post('/api/create-user', async (req, res) => {
  const { name, email } = req.body;

  if (!name || !email) {
    return res.status(400).json({
      success: false,
      error: 'name ve email gerekli'
    });
  }

  try {
    // Email zaten kayıtlı mı kontrol et
    const existingUser = await User.findOne({ email: email.toLowerCase() });
    if (existingUser) {
      return res.status(400).json({
        success: false,
        error: 'Bu email adresi zaten kullanılıyor'
      });
    }

    const user = new User({
      name,
      email: email.toLowerCase()
    });

    await user.save();

    console.log(`✅ Yeni kullanıcı oluşturuldu: ${user.name}`);

    res.status(201).json({
      success: true,
      message: 'Kullanıcı başarıyla oluşturuldu',
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        createdAt: user.createdAt
      }
    });
  } catch (error) {
    console.error('❌ Hata:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * @swagger
 * /api/register-device:
 *   post:
 *     summary: Device bilgilerini kaydet
 *     tags: [Devices]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - deviceId
 *               - fcmToken
 *             properties:
 *               deviceId:
 *                 type: string
 *                 example: device-123-abc
 *               fcmToken:
 *                 type: string
 *               userId:
 *                 type: string
 *                 example: user1
 *               platform:
 *                 type: string
 *                 example: iOS
 *               deviceInfo:
 *                 type: string
 *                 example: iPhone 15 Pro
 *     responses:
 *       200:
 *         description: Device başarıyla kaydedildi
 *       400:
 *         description: Eksik parametreler
 */
// Device bilgilerini kaydet
app.post('/api/register-device', async (req, res) => {
  const { deviceId, fcmToken, userId, platform, deviceInfo } = req.body;

  if (!deviceId || !fcmToken) {
    return res.status(400).json({
      success: false,
      error: 'deviceId ve fcmToken gerekli'
    });
  }

  try {
    // Device zaten var mı kontrol et, varsa güncelle
    let device = await Device.findOne({ deviceId });

    if (device) {
      // Mevcut device'ı güncelle
      device.fcmToken = fcmToken;
      device.userId = userId || device.userId;
      device.platform = platform || device.platform;
      device.deviceInfo = deviceInfo || device.deviceInfo;
      device.lastActive = Date.now();
      await device.save();

      console.log(`✅ Device güncellendi: ${deviceId} (${platform})`);
    } else {
      // Yeni device oluştur
      device = new Device({
        deviceId,
        fcmToken,
        userId: userId || null,
        platform: platform || 'unknown',
        deviceInfo: deviceInfo || null
      });
      await device.save();

      console.log(`✅ Device kaydedildi: ${deviceId} (${platform})`);
    }

    res.json({
      success: true,
      message: 'Device başarıyla kaydedildi',
      deviceId,
      registeredAt: device.createdAt
    });
  } catch (error) {
    console.error('❌ Hata:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * @swagger
 * /api/send-to-device:
 *   post:
 *     summary: Belirli bir device'a bildirim gönder
 *     tags: [Notifications]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - deviceId
 *               - title
 *               - body
 *             properties:
 *               deviceId:
 *                 type: string
 *                 example: device-123-abc
 *               title:
 *                 type: string
 *                 example: Test Notification
 *               body:
 *                 type: string
 *                 example: Bu bir test bildirimidir
 *               data:
 *                 type: object
 *     responses:
 *       200:
 *         description: Bildirim başarıyla gönderildi
 *       400:
 *         description: Eksik parametreler
 *       404:
 *         description: Device bulunamadı
 */
// Device ID'ye göre bildirim gönder
app.post('/api/send-to-device', async (req, res) => {
  const { deviceId, title, body, data } = req.body;

  if (!deviceId || !title || !body) {
    return res.status(400).json({
      success: false,
      error: 'deviceId, title ve body gerekli'
    });
  }

  try {
    const device = await Device.findOne({ deviceId });

    if (!device) {
      return res.status(404).json({
        success: false,
        error: 'Device bulunamadı. Önce /api/register-device ile kayıt yapın'
      });
    }

    const message = {
      token: device.fcmToken,
      notification: {
        title: title,
        body: body
      },
      data: data || {},
      android: {
        priority: 'high',
        notification: {
          sound: 'default',
          clickAction: 'FLUTTER_NOTIFICATION_CLICK'
        }
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1
          }
        }
      }
    };

    const response = await admin.messaging().send(message);

    // Son aktivite zamanını güncelle
    device.lastActive = Date.now();
    await device.save();

    console.log(`✅ Device'a bildirim gönderildi: ${deviceId}`);

    res.json({
      success: true,
      message: 'Bildirim başarıyla gönderildi',
      messageId: response,
      device: {
        deviceId: deviceId,
        platform: device.platform,
        userId: device.userId
      }
    });
  } catch (error) {
    console.error('❌ Hata:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * @swagger
 * /api/send-to-multiple-devices:
 *   post:
 *     summary: Belirli device ID'lere toplu bildirim gönder
 *     tags: [Notifications]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - deviceIds
 *               - title
 *               - body
 *             properties:
 *               deviceIds:
 *                 type: array
 *                 items:
 *                   type: string
 *                 example: ["device-123", "device-456", "device-789"]
 *               title:
 *                 type: string
 *                 example: Özel Bildirim
 *               body:
 *                 type: string
 *                 example: Bu bildirim sadece seçili cihazlara gönderildi
 *               data:
 *                 type: object
 *     responses:
 *       200:
 *         description: Toplu bildirim gönderildi
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 totalDevices:
 *                   type: integer
 *                 foundDevices:
 *                   type: integer
 *                 notFoundDevices:
 *                   type: integer
 *                 successCount:
 *                   type: integer
 *                 failureCount:
 *                   type: integer
 *                 batchCount:
 *                   type: integer
 *       400:
 *         description: Eksik parametreler veya device bulunamadı
 */
// Belirli device ID'lere toplu bildirim gönder
app.post('/api/send-to-multiple-devices', async (req, res) => {
  const { deviceIds, title, body, data } = req.body;

  if (!deviceIds || !Array.isArray(deviceIds) || deviceIds.length === 0) {
    return res.status(400).json({
      success: false,
      error: 'deviceIds array gerekli ve boş olmamalı'
    });
  }

  if (!title || !body) {
    return res.status(400).json({
      success: false,
      error: 'title ve body gerekli'
    });
  }

  try {
    // Device ID'lere göre device'ları bul
    const devices = await Device.find({ deviceId: { $in: deviceIds } });

    if (devices.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Hiçbir device bulunamadı'
      });
    }

    const notFoundDevices = deviceIds.filter(
      id => !devices.find(d => d.deviceId === id)
    );

    const messages = devices.map(device => ({
      token: device.fcmToken,
      notification: {
        title: title,
        body: body
      },
      data: data || {},
      android: {
        priority: 'high',
        notification: {
          sound: 'default',
          clickAction: 'FLUTTER_NOTIFICATION_CLICK'
        }
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1
          }
        }
      }
    }));

    // Firebase sendEach() maksimum 500 mesaj alır, batch olarak gönder
    const BATCH_SIZE = 500;
    let totalSuccess = 0;
    let totalFailure = 0;
    const batches = [];

    for (let i = 0; i < messages.length; i += BATCH_SIZE) {
      const batch = messages.slice(i, i + BATCH_SIZE);
      batches.push(batch);
    }

    console.log(`📤 ${deviceIds.length} device ID'den ${devices.length} tanesi bulundu`);
    console.log(`📤 ${messages.length} cihaza ${batches.length} batch halinde gönderiliyor...`);

    for (let i = 0; i < batches.length; i++) {
      const batch = batches[i];
      const response = await admin.messaging().sendEach(batch);
      totalSuccess += response.successCount;
      totalFailure += response.failureCount;
      console.log(`   Batch ${i + 1}/${batches.length}: ${response.successCount}/${batch.length} başarılı`);
    }

    // Son aktivite zamanlarını güncelle
    await Device.updateMany(
      { deviceId: { $in: deviceIds } },
      { $set: { lastActive: Date.now() } }
    );

    console.log(`✅ Toplu device bildirimi tamamlandı: ${totalSuccess}/${messages.length} başarılı`);
    if (notFoundDevices.length > 0) {
      console.log(`⚠️  ${notFoundDevices.length} device bulunamadı: ${notFoundDevices.join(', ')}`);
    }

    res.json({
      success: true,
      message: 'Belirli device\'lara bildirim gönderildi',
      totalDevices: deviceIds.length,
      foundDevices: devices.length,
      notFoundDevices: notFoundDevices.length,
      notFoundList: notFoundDevices,
      successCount: totalSuccess,
      failureCount: totalFailure,
      batchCount: batches.length,
      batchSize: BATCH_SIZE,
      devices: devices.map(d => ({
        deviceId: d.deviceId,
        platform: d.platform,
        userId: d.userId
      }))
    });
  } catch (error) {
    console.error('❌ Hata:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * @swagger
 * /api/devices:
 *   get:
 *     summary: Kayıtlı tüm device'ları listele
 *     tags: [Devices]
 *     responses:
 *       200:
 *         description: Device listesi
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 totalDevices:
 *                   type: integer
 *                 devices:
 *                   type: array
 *                   items:
 *                     type: object
 *                     properties:
 *                       deviceId:
 *                         type: string
 *                       platform:
 *                         type: string
 *                       userId:
 *                         type: string
 *                       registeredAt:
 *                         type: string
 *                       lastActive:
 *                         type: string
 *                       hasToken:
 *                         type: boolean
 */
// Kayıtlı tüm device'ları listele
app.get('/api/devices', async (req, res) => {
  try {
    const devices = await Device.find().select('-__v');
    res.json({
      success: true,
      totalDevices: devices.length,
      devices: devices.map(d => ({
        deviceId: d.deviceId,
        platform: d.platform,
        userId: d.userId,
        deviceInfo: d.deviceInfo,
        registeredAt: d.createdAt,
        lastActive: d.lastActive,
        hasToken: !!d.fcmToken
      }))
    });
  } catch (error) {
    console.error('❌ Hata:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Server başlat
app.listen(PORT, () => {
  console.log(`\n🚀 Server çalışıyor: http://localhost:${PORT}`);
  console.log('📁 MongoDB: notification_db');
  console.log('📡 Swagger API Docs: http://localhost:3000/api-docs');
  console.log('\n💡 Test için: http://localhost:3000\n');
});
