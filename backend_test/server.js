const express = require('express');
const cors = require('cors');
const admin = require('firebase-admin');
const swaggerUi = require('swagger-ui-express');
const swaggerJsdoc = require('swagger-jsdoc');

const app = express();
const PORT = 3000;

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

// Mock database (memory)
const users = {
  'user1': {
    id: 'user1',
    name: 'Ahmet Yılmaz',
    email: 'ahmet@example.com',
    fcmToken: null
  },
  'user2': {
    id: 'user2',
    name: 'Mehmet Demir',
    email: 'mehmet@example.com',
    fcmToken: null
  },
  'user3': {
    id: 'user3',
    name: 'Ayşe Kaya',
    email: 'ayse@example.com',
    fcmToken: null
  }
};

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
app.get('/api/users', (req, res) => {
  res.json({
    success: true,
    users: Object.values(users).map(u => ({
      id: u.id,
      name: u.name,
      email: u.email,
      hasToken: !!u.fcmToken
    }))
  });
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
app.post('/api/register-token', (req, res) => {
  const { userId, fcmToken } = req.body;

  if (!userId || !fcmToken) {
    return res.status(400).json({
      success: false,
      error: 'userId ve fcmToken gerekli'
    });
  }

  if (!users[userId]) {
    return res.status(404).json({
      success: false,
      error: 'Kullanıcı bulunamadı'
    });
  }

  users[userId].fcmToken = fcmToken;

  console.log(`✅ Token kaydedildi: ${users[userId].name}`);

  res.json({
    success: true,
    message: 'FCM token başarıyla kaydedildi',
    user: {
      id: userId,
      name: users[userId].name
    }
  });
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

  const user = users[userId];

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

  try {
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
        id: user.id,
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

  const inviter = users[inviterId];
  const invitedUser = users[invitedUserId];

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

  try {
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
        inviterId: inviter.id,
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

  const sender = users[senderId];
  const recipient = users[recipientId];

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

  try {
    const message = {
      token: recipient.fcmToken,
      notification: {
        title: `💬 ${sender.name}'den yeni mesaj`,
        body: messageText
      },
      data: {
        type: 'message',
        senderId: sender.id,
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

  const usersWithToken = Object.values(users).filter(u => u.fcmToken);

  if (usersWithToken.length === 0) {
    return res.status(400).json({
      success: false,
      error: 'Token\'ı olan kullanıcı yok'
    });
  }

  try {
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

    const response = await admin.messaging().sendEach(messages);

    console.log(`✅ Toplu bildirim gönderildi: ${response.successCount}/${messages.length}`);

    res.json({
      success: true,
      message: 'Toplu bildirim gönderildi',
      totalUsers: messages.length,
      successCount: response.successCount,
      failureCount: response.failureCount
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

  let targetDevices = Object.values(devices);

  // Platform filtresi varsa uygula
  if (platform) {
    targetDevices = targetDevices.filter(d => d.platform === platform);
  }

  if (targetDevices.length === 0) {
    return res.status(400).json({
      success: false,
      error: 'Kayıtlı device bulunamadı'
    });
  }

  try {
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

    const response = await admin.messaging().sendEach(messages);

    console.log(`✅ Toplu device bildirimi gönderildi: ${response.successCount}/${messages.length}`);
    if (platform) {
      console.log(`   Platform filtresi: ${platform}`);
    }

    res.json({
      success: true,
      message: 'Toplu bildirim tüm kayıtlı device\'lara gönderildi',
      totalDevices: messages.length,
      successCount: response.successCount,
      failureCount: response.failureCount,
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

// Device tabanlı bildirim endpoint'i ekle
// Device ID ve FCM Token eşleştirme için bellek veritabanı
const devices = {}; // { deviceId: { fcmToken, userId, platform, registeredAt } }

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
app.post('/api/register-device', (req, res) => {
  const { deviceId, fcmToken, userId, platform, deviceInfo } = req.body;

  if (!deviceId || !fcmToken) {
    return res.status(400).json({
      success: false,
      error: 'deviceId ve fcmToken gerekli'
    });
  }

  devices[deviceId] = {
    fcmToken,
    userId: userId || null,
    platform: platform || 'unknown',
    deviceInfo: deviceInfo || null,
    registeredAt: new Date().toISOString(),
    lastActive: new Date().toISOString()
  };

  console.log(`✅ Device kaydedildi: ${deviceId} (${platform})`);

  res.json({
    success: true,
    message: 'Device başarıyla kaydedildi',
    deviceId,
    registeredAt: devices[deviceId].registeredAt
  });
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

  const device = devices[deviceId];

  if (!device) {
    return res.status(404).json({
      success: false,
      error: 'Device bulunamadı. Önce /api/register-device ile kayıt yapın'
    });
  }

  try {
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
    device.lastActive = new Date().toISOString();

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
app.get('/api/devices', (req, res) => {
  res.json({
    success: true,
    totalDevices: Object.keys(devices).length,
    devices: Object.entries(devices).map(([deviceId, info]) => ({
      deviceId,
      platform: info.platform,
      userId: info.userId,
      deviceInfo: info.deviceInfo,
      registeredAt: info.registeredAt,
      lastActive: info.lastActive,
      hasToken: !!info.fcmToken
    }))
  });
});

// Server başlat
app.listen(PORT, () => {
  console.log(`\n🚀 Server çalışıyor: http://localhost:${PORT}`);
  console.log('\n📋 Test kullanıcıları:');
  Object.values(users).forEach(u => {
    console.log(`   - ${u.id}: ${u.name} (${u.email})`);
  });
  console.log('\n💡 Test için: http://localhost:3000\n');
});
