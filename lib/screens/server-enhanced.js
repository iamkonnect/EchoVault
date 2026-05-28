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
  cors: { origin: '*', methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'] }
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

// ============ IN-MEMORY DATA STORES ============
let users = [
  { 
    id: 'user1', 
    username: 'demo', 
    email: 'demo@echovault.com', 
    isArtist: true,
    isVerified: true,
    walletBalance: 1000,
    followers: [],
    following: [],
    liked_tracks: [],
    liked_shorts: []
  }
];

let artists = [
  { 
    id: 'artist1', 
    name: 'Demo Artist', 
    userId: 'user1',
    music: [], 
    streams: [], 
    revenue: 1250.50,
    isVerified: true
  }
];

let tracks = [
  { id: '1', title: 'Demo Track 1', artistId: 'artist1', plays: 12500, genre: 'house', likes: 450 },
  { id: '2', title: 'Lo-Fi Chill', artistId: 'artist1', plays: 8560, genre: 'lofi', likes: 230 }
];

let albums = [{ id: 'alb1', title: 'Demo Album', artistId: 'artist1', tracks: ['1'] }];

let shorts = [
  { 
    id: 'short1', 
    title: 'Demo Short', 
    artistId: 'artist1', 
    description: 'Demo short video',
    views: 5000, 
    likes: 120,
    comments: [],
    thumbnail: 'https://via.placeholder.com/300x500',
    trending: true
  }
];

let categories = [
  'All', 'Afro Jazz', 'Amapiano', 'Bongo Flavour', 'Genge', 'Genge Tone', 
  'Dancehall', 'Reggae', 'Singeli', 'Hip Hop', 'Rhumba', 'Lingala', 
  'RnB', 'Soul Music', 'Soulpiano', 'Zouk', 'Taarab'
];

let liveStreams = [
  { 
    id: 'live1', 
    title: 'DJ Set Live', 
    artistId: 'artist1', 
    viewers: 1247, 
    isLive: true,
    thumbnail: 'https://via.placeholder.com/400x300',
    description: 'Late night DJ session'
  }
];

let gifts = [
  { id: 'gift1', name: 'Rose', price: 5, icon: '🌹' }, 
  { id: 'gift2', name: 'Rocket', price: 50, icon: '🚀' },
  { id: 'gift3', name: 'Diamond', price: 100, icon: '💎' }
];

let conversations = [];
let messages = [];
let notifications = [];
let playlists = [];
let transactions = [];
let activeRooms = new Map();

// ============ AUTH MIDDLEWARE ============
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

// ============ HELPER FUNCTIONS ============
function generateId(prefix = 'id') {
  return `${prefix}_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
}

// ============ AUTH ENDPOINTS ============
app.post('/api/auth/register', (req, res) => {
  const { email, username, password, name } = req.body;
  const existingUser = users.find(u => u.email === email);
  
  if (existingUser) {
    return res.status(400).json({ success: false, error: 'User already exists' });
  }

  const user = { 
    id: generateId('user'),
    email, 
    username: username || email.split('@')[0], 
    name,
    isArtist: false,
    isVerified: false,
    walletBalance: 0,
    followers: [],
    following: [],
    liked_tracks: [],
    liked_shorts: []
  };
  users.push(user);
  
  const token = jwt.sign({ id: user.id, username: user.username }, JWT_SECRET, { expiresIn: '24h' });
  res.json({ success: true, data: { user, token } });
});

app.post('/api/auth/login', (req, res) => {
  const { email, password } = req.body;
  const user = users.find(u => u.email === email);
  
  if (!user) {
    return res.status(401).json({ success: false, error: 'Invalid credentials' });
  }
  
  const token = jwt.sign({ id: user.id, username: user.username }, JWT_SECRET, { expiresIn: '24h' });
  res.json({ success: true, data: { user, token } });
});

app.post('/api/auth/logout', authMiddleware, (req, res) => {
  res.json({ success: true, message: 'Logged out successfully' });
});

app.post('/api/auth/refresh', authMiddleware, (req, res) => {
  const token = jwt.sign({ id: req.user.id, username: req.user.username }, JWT_SECRET, { expiresIn: '24h' });
  res.json({ success: true, data: { token } });
});

// ============ USER ENDPOINTS ============
app.get('/api/user/profile', authMiddleware, (req, res) => {
  const user = users.find(u => u.id === req.user.id);
  res.json({ success: true, data: user || { id: req.user.id, username: req.user.username } });
});

app.get('/api/user/liked-tracks', authMiddleware, (req, res) => {
  const user = users.find(u => u.id === req.user.id);
  const likedTracks = tracks.filter(t => user?.liked_tracks?.includes(t.id));
  res.json({ success: true, data: likedTracks });
});

app.post('/api/user/:userId/follow', authMiddleware, (req, res) => {
  const { userId } = req.params;
  const user = users.find(u => u.id === req.user.id);
  const targetUser = users.find(u => u.id === userId);
  
  if (!targetUser) return res.status(404).json({ success: false, error: 'User not found' });
  
  if (!user.following.includes(userId)) {
    user.following.push(userId);
    targetUser.followers.push(req.user.id);
  }
  
  res.json({ success: true, message: 'Following user' });
});

app.delete('/api/user/:userId/unfollow', authMiddleware, (req, res) => {
  const { userId } = req.params;
  const user = users.find(u => u.id === req.user.id);
  const targetUser = users.find(u => u.id === userId);
  
  if (!targetUser) return res.status(404).json({ success: false, error: 'User not found' });
  
  user.following = user.following.filter(id => id !== userId);
  targetUser.followers = targetUser.followers.filter(id => id !== req.user.id);
  
  res.json({ success: true, message: 'Unfollowed user' });
});

app.get('/api/user/following', authMiddleware, (req, res) => {
  const user = users.find(u => u.id === req.user.id);
  const following = users.filter(u => user?.following?.includes(u.id));
  res.json({ success: true, data: following });
});

app.get('/api/user/followers', authMiddleware, (req, res) => {
  const user = users.find(u => u.id === req.user.id);
  const followers = users.filter(u => user?.followers?.includes(u.id));
  res.json({ success: true, data: followers });
});

// ============ TRACKS ENDPOINTS ============
app.get('/api/tracks', (req, res) => {
  res.json({ success: true, data: tracks });
});

app.get('/api/tracks/featured', (req, res) => {
  res.json({ success: true, data: tracks });
});

app.get('/api/tracks/trending', (req, res) => {
  const sorted = [...tracks].sort((a, b) => b.plays - a.plays);
  res.json({ success: true, data: sorted });
});

app.get('/api/tracks/search', (req, res) => {
  const q = req.query.q || '';
  const filtered = tracks.filter(t => 
    t.title.toLowerCase().includes(q.toLowerCase())
  );
  res.json({ success: true, data: filtered });
});

app.get('/api/tracks/recommendations', (req, res) => {
  res.json({ success: true, data: tracks });
});

app.get('/api/tracks/genre/:genre', (req, res) => {
  const filtered = tracks.filter(t => t.genre === req.params.genre);
  res.json({ success: true, data: filtered });
});

app.get('/api/tracks/:id', (req, res) => {
  const track = tracks.find(t => t.id === req.params.id);
  res.json({ success: true, data: track || tracks[0] });
});

app.post('/api/tracks/:id/like', authMiddleware, (req, res) => {
  const track = tracks.find(t => t.id === req.params.id);
  const user = users.find(u => u.id === req.user.id);
  
  if (!track) return res.status(404).json({ success: false, error: 'Track not found' });
  
  if (!user.liked_tracks.includes(req.params.id)) {
    user.liked_tracks.push(req.params.id);
    track.likes = (track.likes || 0) + 1;
  }
  
  res.json({ success: true, message: 'Track liked' });
});

app.delete('/api/tracks/:id/like', authMiddleware, (req, res) => {
  const track = tracks.find(t => t.id === req.params.id);
  const user = users.find(u => u.id === req.user.id);
  
  if (!track) return res.status(404).json({ success: false, error: 'Track not found' });
  
  user.liked_tracks = user.liked_tracks.filter(id => id !== req.params.id);
  track.likes = Math.max(0, (track.likes || 0) - 1);
  
  res.json({ success: true, message: 'Track unliked' });
});

// ============ ALBUMS & ARTISTS ============
app.get('/api/albums/:id', (req, res) => {
  res.json({ success: true, data: albums[0] });
});

app.get('/api/albums/:id/tracks', (req, res) => {
  res.json({ success: true, data: tracks });
});

app.get('/api/artists/:id', (req, res) => {
  res.json({ success: true, data: artists[0] });
});

app.get('/api/artists/:id/tracks', (req, res) => {
  const artistTracks = tracks.filter(t => t.artistId === req.params.id);
  res.json({ success: true, data: artistTracks });
});

// ============ ARTIST ENDPOINTS ============
app.get('/api/artist/dashboard', authMiddleware, (req, res) => {
  res.json({
    success: true,
    data: {
      totalStreams: 15000,
      totalViews: 25000,
      earnings: 1250.50,
      musicCount: 2,
      shortsCount: 1,
      liveStreamCount: 1
    }
  });
});

app.get('/api/artist/my-music', authMiddleware, (req, res) => {
  const artistMusic = tracks.filter(t => t.artistId === req.user.id);
  res.json({ success: true, data: artistMusic });
});

app.get('/api/artist/insights', authMiddleware, (req, res) => {
  res.json({ success: true, data: { streams: 15000, avgViewers: 500, peakViewers: 1247 } });
});

app.get('/api/artist/live-insights', authMiddleware, (req, res) => {
  res.json({ success: true, data: { peakViewers: 1247, totalLiveTime: 120, avgViewersPerLive: 500 } });
});

app.get('/api/artist/shorts-insights', authMiddleware, (req, res) => {
  res.json({ success: true, data: { views: 5000, likes: 120, comments: 45 } });
});

app.get('/api/artist/revenue', authMiddleware, (req, res) => {
  res.json({ success: true, data: { total: 1250.50, pending: 200, withdrawn: 1050.50 } });
});

app.get('/api/artist/payouts', authMiddleware, (req, res) => {
  res.json({ 
    success: true, 
    data: [
      { id: 'p1', amount: 500, status: 'paid', date: '2024-01-15' },
      { id: 'p2', amount: 550.50, status: 'paid', date: '2024-02-15' }
    ] 
  });
});

app.post('/api/artist/withdraw', authMiddleware, (req, res) => {
  const { amount } = req.body;
  res.json({ success: true, data: { message: 'Withdrawal requested', amount, status: 'pending' } });
});

app.post('/api/artist/verify', authMiddleware, (req, res) => {
  const user = users.find(u => u.id === req.user.id);
  if (user) {
    user.isVerified = true;
  }
  res.json({ success: true, message: 'Artist verification submitted' });
});

app.get('/api/artist/verification-status', authMiddleware, (req, res) => {
  const user = users.find(u => u.id === req.user.id);
  res.json({ success: true, data: { isVerified: user?.isVerified || false, status: user?.isVerified ? 'verified' : 'pending' } });
});

// ============ UPLOADS ============
app.post('/api/artist/upload/audio', authMiddleware, upload.single('audioFile'), (req, res) => {
  const track = {
    id: generateId('track'),
    title: req.body.title,
    artistId: req.user.id,
    genre: req.body.genre || 'general',
    filePath: req.file?.path,
    plays: 0,
    likes: 0,
    createdAt: new Date()
  };
  tracks.push(track);
  res.json({ success: true, data: track });
});

app.post('/api/artist/upload/video', authMiddleware, upload.single('videoFile'), (req, res) => {
  res.json({ success: true, data: { filePath: req.file?.path, title: req.body.title } });
});

app.post('/api/artist/upload/shorts', authMiddleware, upload.single('shortFile'), (req, res) => {
  const short = {
    id: generateId('short'),
    title: req.body.title,
    description: req.body.description,
    artistId: req.user.id,
    filePath: req.file?.path,
    thumbnail: req.body.thumbnail,
    views: 0,
    likes: 0,
    comments: [],
    createdAt: new Date()
  };
  shorts.push(short);
  res.json({ success: true, data: short });
});

app.put('/api/artist/music/:id', authMiddleware, (req, res) => {
  const track = tracks.find(t => t.id === req.params.id);
  if (!track) return res.status(404).json({ success: false, error: 'Track not found' });
  
  Object.assign(track, req.body);
  res.json({ success: true, message: 'Track updated' });
});

app.delete('/api/artist/music/:id', authMiddleware, (req, res) => {
  tracks = tracks.filter(t => t.id !== req.params.id);
  res.json({ success: true, message: 'Track deleted' });
});

app.get('/api/artist/music/:id/stats', authMiddleware, (req, res) => {
  const track = tracks.find(t => t.id === req.params.id);
  res.json({ success: true, data: { plays: track?.plays || 0, likes: track?.likes || 0 } });
});

// ============ LIVE STREAMS ============
app.get('/api/live/streams/active', (req, res) => {
  res.json({ success: true, data: liveStreams });
});

app.get('/api/live/streams/:id', (req, res) => {
  const stream = liveStreams.find(s => s.id === req.params.id);
  res.json({ success: true, data: stream || liveStreams[0] });
});

app.post('/api/artist/start-stream', authMiddleware, (req, res) => {
  const { title, description, thumbnail } = req.body;
  const streamId = generateId('live');
  const newStream = { 
    id: streamId, 
    title, 
    description,
    thumbnail,
    artistId: req.user.id, 
    viewers: 0, 
    isLive: true,
    createdAt: new Date()
  };
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
  res.json({ success: true, message: 'Stream ended' });
});

// ============ SHORTS ENDPOINTS ============
app.get('/api/shorts', (req, res) => {
  res.json({ success: true, data: shorts });
});

app.get('/api/shorts/:id', (req, res) => {
  const short = shorts.find(s => s.id === req.params.id);
  res.json({ success: true, data: short });
});

app.get('/api/shorts/trending', (req, res) => {
  const trending = shorts.filter(s => s.trending);
  res.json({ success: true, data: trending });
});

app.get('/api/shorts/by-category/:category', (req, res) => {
  // Shorts would be associated with categories in a real DB
  res.json({ success: true, data: shorts });
});

app.post('/api/shorts/:id/like', authMiddleware, (req, res) => {
  const short = shorts.find(s => s.id === req.params.id);
  const user = users.find(u => u.id === req.user.id);
  
  if (!short) return res.status(404).json({ success: false, error: 'Short not found' });
  
  if (!user.liked_shorts.includes(req.params.id)) {
    user.liked_shorts.push(req.params.id);
    short.likes = (short.likes || 0) + 1;
  }
  
  res.json({ success: true, message: 'Short liked' });
});

app.delete('/api/shorts/:id/like', authMiddleware, (req, res) => {
  const short = shorts.find(s => s.id === req.params.id);
  const user = users.find(u => u.id === req.user.id);
  
  if (!short) return res.status(404).json({ success: false, error: 'Short not found' });
  
  user.liked_shorts = user.liked_shorts.filter(id => id !== req.params.id);
  short.likes = Math.max(0, (short.likes || 0) - 1);
  
  res.json({ success: true, message: 'Short unliked' });
});

app.post('/api/shorts/:id/comment', authMiddleware, (req, res) => {
  const { text } = req.body;
  const short = shorts.find(s => s.id === req.params.id);
  const user = users.find(u => u.id === req.user.id);
  
  if (!short) return res.status(404).json({ success: false, error: 'Short not found' });
  
  const comment = {
    id: generateId('comment'),
    userId: req.user.id,
    username: user?.username,
    text,
    createdAt: new Date()
  };
  
  short.comments.push(comment);
  res.json({ success: true, data: comment });
});

app.get('/api/shorts/:id/comments', (req, res) => {
  const short = shorts.find(s => s.id === req.params.id);
  res.json({ success: true, data: short?.comments || [] });
});

// ============ CATEGORIES ============
app.get('/api/categories', (req, res) => {
  res.json({ success: true, data: categories });
});

app.get('/api/categories/:category/tracks', (req, res) => {
  const categoryTracks = tracks.filter(t => t.genre === req.params.category);
  res.json({ success: true, data: categoryTracks });
});

// ============ MESSAGING ============
app.post('/api/messages/send', authMiddleware, (req, res) => {
  const { receiverId, text } = req.body;
  
  if (!receiverId || !text) {
    return res.status(400).json({ success: false, error: 'Missing receiverId or text' });
  }

  // Find or create conversation
  let conversation = conversations.find(c => 
    (c.user1 === req.user.id && c.user2 === receiverId) ||
    (c.user1 === receiverId && c.user2 === req.user.id)
  );

  if (!conversation) {
    conversation = {
      id: generateId('conv'),
      user1: req.user.id,
      user2: receiverId,
      createdAt: new Date()
    };
    conversations.push(conversation);
  }

  const message = {
    id: generateId('msg'),
    conversationId: conversation.id,
    senderId: req.user.id,
    receiverId,
    text,
    read: false,
    createdAt: new Date()
  };

  messages.push(message);
  
  // Emit via WebSocket
  io.emit('newMessage', message);

  res.json({ success: true, data: message });
});

app.get('/api/messages/conversations', authMiddleware, (req, res) => {
  const userConversations = conversations.filter(c => 
    c.user1 === req.user.id || c.user2 === req.user.id
  );

  const conversationData = userConversations.map(conv => {
    const otherUserId = conv.user1 === req.user.id ? conv.user2 : conv.user1;
    const otherUser = users.find(u => u.id === otherUserId);
    const lastMessage = messages
      .filter(m => m.conversationId === conv.id)
      .sort((a, b) => b.createdAt - a.createdAt)[0];

    return {
      id: conv.id,
      user: otherUser,
      lastMessage: lastMessage?.text || 'No messages',
      lastMessageTime: lastMessage?.createdAt,
      unreadCount: messages.filter(m => 
        m.conversationId === conv.id && 
        m.receiverId === req.user.id && 
        !m.read
      ).length
    };
  });

  res.json({ success: true, data: conversationData });
});

app.get('/api/messages/conversations/:conversationId/messages', authMiddleware, (req, res) => {
  const conversationMessages = messages.filter(m => 
    m.conversationId === req.params.conversationId
  ).sort((a, b) => a.createdAt - b.createdAt);

  res.json({ success: true, data: conversationMessages });
});

app.put('/api/messages/:messageId/read', authMiddleware, (req, res) => {
  const message = messages.find(m => m.id === req.params.messageId);
  if (!message) return res.status(404).json({ success: false, error: 'Message not found' });
  
  message.read = true;
  res.json({ success: true, message: 'Message marked as read' });
});

app.get('/api/messages/unread-count', authMiddleware, (req, res) => {
  const unreadCount = messages.filter(m => 
    m.receiverId === req.user.id && !m.read
  ).length;
  
  res.json({ success: true, data: { unreadCount } });
});

// ============ PLAYLISTS ============
app.get('/api/user/playlists', authMiddleware, (req, res) => {
  const userPlaylists = playlists.filter(p => p.userId === req.user.id);
  res.json({ success: true, data: userPlaylists });
});

app.post('/api/playlists/create', authMiddleware, (req, res) => {
  const { name, description } = req.body;
  const playlist = {
    id: generateId('playlist'),
    userId: req.user.id,
    name,
    description,
    tracks: [],
    createdAt: new Date()
  };
  playlists.push(playlist);
  res.json({ success: true, data: playlist });
});

app.post('/api/playlists/:id/add-track', authMiddleware, (req, res) => {
  const { trackId } = req.body;
  const playlist = playlists.find(p => p.id === req.params.id);
  
  if (!playlist) return res.status(404).json({ success: false, error: 'Playlist not found' });
  if (!playlist.tracks.includes(trackId)) {
    playlist.tracks.push(trackId);
  }
  
  res.json({ success: true, message: 'Track added to playlist' });
});

app.delete('/api/playlists/:id/remove-track/:trackId', authMiddleware, (req, res) => {
  const playlist = playlists.find(p => p.id === req.params.id);
  
  if (!playlist) return res.status(404).json({ success: false, error: 'Playlist not found' });
  
  playlist.tracks = playlist.tracks.filter(id => id !== req.params.trackId);
  res.json({ success: true, message: 'Track removed from playlist' });
});

app.delete('/api/playlists/:id', authMiddleware, (req, res) => {
  playlists = playlists.filter(p => p.id !== req.params.id);
  res.json({ success: true, message: 'Playlist deleted' });
});

// ============ NOTIFICATIONS ============
app.get('/api/notifications', authMiddleware, (req, res) => {
  const userNotifications = notifications.filter(n => n.userId === req.user.id);
  res.json({ success: true, data: userNotifications });
});

app.post('/api/notifications/:id/read', authMiddleware, (req, res) => {
  const notification = notifications.find(n => n.id === req.params.id);
  if (!notification) return res.status(404).json({ success: false, error: 'Notification not found' });
  
  notification.read = true;
  res.json({ success: true, message: 'Notification marked as read' });
});

app.delete('/api/notifications/:id', authMiddleware, (req, res) => {
  notifications = notifications.filter(n => n.id !== req.params.id);
  res.json({ success: true, message: 'Notification deleted' });
});

// ============ GIFTS ============
app.get('/api/gifts', (req, res) => {
  res.json({ success: true, data: gifts });
});

app.post('/api/gifts/send', authMiddleware, (req, res) => {
  const { receiverId, giftId, streamId, quantity = 1 } = req.body;
  const gift = gifts.find(g => g.id === giftId);
  const sender = users.find(u => u.id === req.user.id);
  const receiver = users.find(u => u.id === receiverId);

  if (!gift || !sender || !receiver) {
    return res.status(404).json({ success: false, error: 'Gift, sender, or receiver not found' });
  }

  const totalAmount = gift.price * quantity;
  
  if (sender.walletBalance < totalAmount) {
    return res.status(400).json({ success: false, error: 'Insufficient balance' });
  }

  sender.walletBalance -= totalAmount;
  receiver.walletBalance += totalAmount * 0.8; // 80% to receiver, 20% to platform

  io.to(streamId || receiverId).emit('newGift', {
    giftId,
    senderName: sender.username,
    quantity,
    streamId
  });

  res.json({ success: true, message: 'Gift sent', data: { totalAmount, sentTo: receiver.username } });
});

// ============ WALLET ============
app.get('/api/wallet/balance', authMiddleware, (req, res) => {
  const user = users.find(u => u.id === req.user.id);
  res.json({ success: true, data: { balance: user?.walletBalance || 0 } });
});

app.get('/api/wallet/transactions', authMiddleware, (req, res) => {
  const userTransactions = transactions.filter(t => t.userId === req.user.id);
  res.json({ success: true, data: userTransactions });
});

// ============ SEARCH ============
app.get('/api/search', (req, res) => {
  const q = req.query.q || '';
  
  const trackResults = tracks.filter(t => 
    t.title.toLowerCase().includes(q.toLowerCase())
  );
  
  const artistResults = users.filter(u => 
    u.username.toLowerCase().includes(q.toLowerCase()) && u.isArtist
  );
  
  const shortResults = shorts.filter(s => 
    s.title.toLowerCase().includes(q.toLowerCase())
  );

  res.json({ 
    success: true, 
    data: {
      tracks: trackResults,
      artists: artistResults,
      shorts: shortResults
    }
  });
});

app.get('/api/search/suggestions', (req, res) => {
  const suggestions = [
    ...tracks.map(t => ({ type: 'track', title: t.title })),
    ...users.filter(u => u.isArtist).map(u => ({ type: 'artist', title: u.username }))
  ].slice(0, 10);

  res.json({ success: true, data: suggestions });
});

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

  socket.on('sendGift', (data) => {
    io.to(data.streamId).emit('newGift', data);
  });

  socket.on('sendChatMessage', (data) => {
    io.to(data.streamId).emit('newChatMessage', data);
  });

  socket.on('sendMessage', (data) => {
    io.to(data.receiverId).emit('newMessage', data);
  });

  socket.on('disconnect', () => {
    for (let [streamId, room] of activeRooms) {
      room.viewers = room.viewers.filter(id => id !== socket.id);
      room.viewersCount = room.viewers.length;
    }
  });
});

// ============ 404 HANDLER ============
app.use((req, res) => {
  res.status(404).json({ success: false, error: 'Endpoint not found', path: req.path });
});

server.listen(PORT, () => {
  console.log(`🎵 EchoVault Server running on http://localhost:${PORT}`);
  console.log(`📁 Upload directory: uploads/`);
  console.log(`🔌 WebSocket enabled for real-time features`);
  console.log('\n✅ All endpoints loaded:');
  console.log('  - Authentication (4)');
  console.log('  - Tracks (8)');
  console.log('  - Shorts (6)');
  console.log('  - Artists (15)');
  console.log('  - Messaging (5)');
  console.log('  - Playlists (5)');
  console.log('  - Notifications (3)');
  console.log('  - User Actions (4)');
  console.log('  - Gifts (2)');
  console.log('  - Wallet (2)');
  console.log('  - Search (2)');
  console.log('\n📊 Total: 56+ endpoints ready for use');
});

module.exports = app;
