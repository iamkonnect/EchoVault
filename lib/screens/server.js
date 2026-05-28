const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const cors = require('cors');
const jwt = require('jsonwebtoken');
const multer = require('multer');
const path = require('path');

const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
  cors: { origin: '*', methods: ['GET', 'POST', 'PUT', 'DELETE'] }
});

const PORT = process.env.PORT || 3000;
const JWT_SECRET = 'echovault_secret_key_2024';

app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));
app.use('/uploads', express.static('uploads'));

// Multer for file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, 'uploads/'),
  filename: (req, file, cb) => cb(null, Date.now() + '-' + file.originalname)
});
const upload = multer({ storage });

// Mock Data Stores
let users = [{ id: 'user1', username: 'demo', email: 'demo@echovault.com', isArtist: true }];
let artists = [{ id: 'artist1', name: 'Demo Artist', music: [], streams: [], revenue: 1250.50 }];
let tracks = [
  { id: '1', title: 'Demo Track 1', artistId: 'artist1', plays: 12500, genre: 'house' },
  { id: '2', title: 'Lo-Fi Chill', artistId: 'artist1', plays: 8560, genre: 'lofi' }
];
let albums = [{ id: 'alb1', title: 'Demo Album', artistId: 'artist1', tracks: ['1'] }];
let liveStreams = [
  { id: 'live1', title: 'DJ Set Live', artistId: 'artist1', viewers: 1247, isLive: true }
];
let gifts = [{ id: 'gift1', name: 'Rose', price: 5 }, { id: 'gift2', name: 'Rocket', price: 50 }];
let activeRooms = new Map();

// Auth Middleware
const authMiddleware = (req, res, next) => {
  const token = req.headers.authorization?.replace('Bearer ', '');
  if (!token) return res.status(401).json({ success: false, error: 'No token' });
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    req.user = decoded;
    next();
  } catch (e) {
    res.status(401).json({ success: false, error: 'Invalid token' });
  }
};

// ============ AUTH ENDPOINTS ============
app.post('/api/auth/register', (req, res) => {
  const { email, username, password } = req.body;
  const user = { id: `user_${Date.now()}`, email, username, isArtist: false };
  users.push(user);
  const token = jwt.sign({ id: user.id, username }, JWT_SECRET, { expiresIn: '24h' });
  res.json({ success: true, data: { user, token } });
});

app.post('/api/auth/login', (req, res) => {
  const { email, password } = req.body;
  const user = users.find(u => u.email === email);
  if (!user) return res.status(401).json({ success: false, error: 'Invalid credentials' });
  const token = jwt.sign({ id: user.id, username: user.username }, JWT_SECRET, { expiresIn: '24h' });
  res.json({ success: true, data: { user, token } });
});

app.post('/api/auth/refresh', authMiddleware, (req, res) => {
  const token = jwt.sign({ id: req.user.id, username: req.user.username }, JWT_SECRET, { expiresIn: '24h' });
  res.json({ success: true, data: { token } });
});

app.post('/api/auth/logout', authMiddleware, (req, res) => {
  res.json({ success: true });
});

// ============ USER ENDPOINTS ============
app.get('/api/user/profile', authMiddleware, (req, res) => {
  const user = users.find(u => u.id === req.user.id);
  res.json({ success: true, data: user || { id: req.user.id, username: req.user.username } });
});

app.get('/api/user/liked-tracks', authMiddleware, (req, res) => {
  res.json({ success: true, data: tracks.slice(0, 5) });
});

// ============ TRACKS ENDPOINTS ============
app.get('/api/tracks/featured', (req, res) => res.json({ success: true, data: tracks }));
app.get('/api/tracks/trending', (req, res) => res.json({ success: true, data: tracks }));
app.get('/api/tracks/search', (req, res) => {
  const q = req.query.q || '';
  const filtered = tracks.filter(t => t.title.toLowerCase().includes(q.toLowerCase()));
  res.json({ success: true, data: filtered });
});
app.get('/api/tracks/recommendations', (req, res) => res.json({ success: true, data: tracks }));
app.get('/api/tracks/genre/:genre', (req, res) => {
  const filtered = tracks.filter(t => t.genre === req.params.genre);
  res.json({ success: true, data: filtered });
});
app.get('/api/tracks/:id', (req, res) => {
  const track = tracks.find(t => t.id === req.params.id);
  res.json({ success: true, data: track || tracks[0] });
});

// ============ ALBUMS & ARTISTS ============
app.get('/api/albums/:id', (req, res) => res.json({ success: true, data: albums[0] }));
app.get('/api/albums/:id/tracks', (req, res) => res.json({ success: true, data: tracks }));
app.get('/api/artists/:id', (req, res) => res.json({ success: true, data: artists[0] }));
app.get('/api/artists/:id/tracks', (req, res) => res.json({ success: true, data: tracks }));

// ============ ARTIST ENDPOINTS ============
app.get('/api/artist/dashboard', authMiddleware, (req, res) => {
  res.json({
    success: true,
    data: {
      totalStreams: 15,
      totalViews: 25000,
      earnings: 1250.50,
      musicCount: 12
    }
  });
});

app.get('/api/artist/my-music', authMiddleware, (req, res) => {
  res.json({ success: true, data: tracks });
});

// Frontend alias (artist music list)
app.get('/api/artist/music', authMiddleware, (req, res) => {
  res.json({ success: true, data: tracks });
});

app.get('/api/artist/insights', authMiddleware, (req, res) => res.json({ success: true, data: { streams: 15, avgViewers: 500 } }));
app.get('/api/artist/live-insights', authMiddleware, (req, res) => res.json({ success: true, data: { peakViewers: 1247 } }));
app.get('/api/artist/shorts-insights', authMiddleware, (req, res) => res.json({ success: true, data: { views: 5000 } }));
// Frontend aliases (earnings/withdrawals)
app.get('/api/artist/earnings', authMiddleware, (req, res) => res.json({ success: true, data: { total: 1250.50, pending: 200 } }));
app.get('/api/artist/withdrawals', authMiddleware, (req, res) => res.json({ success: true, data: [{ id: 'p1', amount: 100, status: 'paid' }] }));

// Legacy endpoints
app.get('/api/artist/revenue', authMiddleware, (req, res) => res.json({ success: true, data: { total: 1250.50, pending: 200 } }));
app.get('/api/artist/payouts', authMiddleware, (req, res) => res.json({ success: true, data: [{ id: 'p1', amount: 100, status: 'paid' }] }));

app.post('/api/artist/withdraw', authMiddleware, (req, res) => {
  res.json({ success: true, data: { message: 'Withdrawal requested', amount: req.body.amount } });
});

// ============ UPLOADS ============
// Frontend alias (audio upload)
app.post('/api/tracks/upload', authMiddleware, upload.single('audioFile'), (req, res) => {
  res.json({ success: true, data: { filePath: req.file?.path, title: req.body.title } });
});

// Legacy endpoint
app.post('/api/artist/upload/audio', authMiddleware, upload.single('audioFile'), (req, res) => {
  res.json({ success: true, data: { filePath: req.file?.path, title: req.body.title } });
});
app.post('/api/artist/upload/video', authMiddleware, upload.single('videoFile'), (req, res) => {
  res.json({ success: true, data: { filePath: req.file?.path } });
});
app.post('/api/artist/upload/shorts', authMiddleware, upload.single('shortFile'), (req, res) => {
  res.json({ success: true, data: { filePath: req.file?.path } });
});

app.put('/api/artist/music/:id', authMiddleware, (req, res) => res.json({ success: true }));
app.delete('/api/artist/music/:id', authMiddleware, (req, res) => res.json({ success: true }));
app.get('/api/artist/music/:id/stats', authMiddleware, (req, res) => res.json({ success: true, data: { plays: 1000 } }));

// ============ LIVE STREAMS ============
app.get('/api/live/streams/active', (req, res) => {
  res.json({ success: true, data: liveStreams });
});
app.get('/api/live/streams/:id', (req, res) => {
  const stream = liveStreams.find(s => s.id === req.params.id);
  res.json({ success: true, data: stream || liveStreams[0] });
});
app.post('/api/artist/start-stream', authMiddleware, (req, res) => {
  const streamId = `live_${Date.now()}`;
  const newStream = { ...req.body, id: streamId, viewers: 0, isLive: true };
  liveStreams.push(newStream);
  activeRooms.set(streamId, { viewers: [], gifts: [], messages: [], viewersCount: 0 });
  io.emit('newLiveStream', newStream);
  res.json({ success: true, data: newStream });
});
app.post('/api/artist/stop-stream', authMiddleware, (req, res) => {
  const { streamId } = req.body;
  liveStreams = liveStreams.filter(s => s.id !== streamId);
  activeRooms.delete(streamId);
  io.emit('streamEnded', streamId);
  res.json({ success: true });
});

// ============ GIFTS ============
app.get('/api/gifts/packages', (req, res) => res.json({ success: true, data: gifts }));
// Legacy gifting endpoint
app.post('/api/gifts/send', authMiddleware, (req, res) => {
  io.to(req.body.streamId || req.body.entityId).emit('newGift', req.body);
  res.json({ success: true });
});

// Frontend alias (backend mounts at /api/gifting)
app.post('/api/gifting/send', authMiddleware, (req, res) => {
  io.to(req.body.streamId || req.body.entityId).emit('newGift', req.body);
  res.json({ success: true });
});

// ============ CHAT ============
// Legacy endpoint
app.get('/api/chat/conversations', authMiddleware, (req, res) => {
  res.json({ success: true, data: [{ id: 'conv1', withUser: 'Artist1', lastMsg: 'Hi!' }] });
});

// Frontend alias (messages)
app.get('/api/messages/conversations', authMiddleware, (req, res) => {
  res.json({ success: true, data: [{ id: 'conv1', user: { id: 'artist1', username: 'Artist1' }, lastMessage: 'Hi!', lastMessageTime: new Date().toISOString(), unreadCount: 0 }] });
});
app.get('/api/playlists/:id', (req, res) => res.json({ success: true, data: { tracks: tracks.slice(0, 3) } }));

// ============ SOCKET.IO ============
io.on('connection', (socket) => {
  console.log('User connected:', socket.id);

  socket.on('joinStream', (streamId) => {
    socket.join(streamId);
    const room = activeRooms.get(streamId) || { viewers: [], gifts: [], messages: [], viewersCount: 0 };
    room.viewers.push(socket.id);
    room.viewersCount = room.viewers.length;
    activeRooms.set(streamId, room);
    socket.to(streamId).emit('userJoinedStream', { totalViewers: room.viewersCount });
    socket.emit('roomData', room);
  });

  socket.on('sendGift', (data) => io.to(data.streamId).emit('newGift', data));
  socket.on('sendChatMessage', (data) => io.to(data.streamId).emit('newChatMessage', data));

  socket.on('disconnect', () => {
    for (let [streamId, room] of activeRooms) {
      room.viewers = room.viewers.filter(id => id !== socket.id);
      room.viewersCount = room.viewers.length;
    }
  });
});

// 404 Handler
app.use((req, res) => res.status(404).json({ success: false, error: 'Endpoint not found' }));

server.listen(PORT, () => {
  console.log(`EchoVault Server running on http://localhost:${PORT}`);
  console.log(`Upload dir: uploads/`);
});

