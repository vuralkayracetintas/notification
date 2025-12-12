const express = require('express');
const cors = require('cors');
const admin = require('firebase-admin');

const app = express();
const PORT = 3000;

// Middleware
app.use(cors());
app.use(express.json());

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

// Health check
app.get('/', (req, res) => {
  res.json({
    status: 'running',
    message: '🚀 Notification Backend Test Server',
    endpoints: {
      'POST /api/register-token': 'FCM token kaydet',
      'POST /api/send-notification': 'Tek kullanıcıya bildirim',
      'POST /api/send-invitation': 'Davetiye gönder',
      'POST /api/send-message': 'Mesaj bildirimi',
      'POST /api/send-bulk': 'Toplu bildirim',
      'GET /api/users': 'Tüm kullanıcıları listele'
    }
  });
});

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

// Toplu bildirim (tüm kullanıcılara)
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

// Server başlat
app.listen(PORT, () => {
  console.log(`\n🚀 Server çalışıyor: http://localhost:${PORT}`);
  console.log('\n📋 Test kullanıcıları:');
  Object.values(users).forEach(u => {
    console.log(`   - ${u.id}: ${u.name} (${u.email})`);
  });
  console.log('\n💡 Test için: http://localhost:3000\n');
});
