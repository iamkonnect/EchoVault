const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/auth');

// POST /api/streams/join-request - Listener/Artist wants to join a live
router.post('/join-request', authMiddleware, async (req, res) => {
    const { streamId } = req.body;
    const userId = req.user.id;

    try {
        // 1. Emit socket event to the streamer to Accept or Deny
        // io.to(streamId).emit('join_request', { userId, name: req.user.name });
        res.json({ success: true, message: 'Request sent to host' });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

// PATCH /api/streams/handle-request - Host accepts or denies
router.patch('/handle-request', authMiddleware, async (req, res) => {
    const { userId, status } = req.body; // status: 'ACCEPTED' or 'DENIED'

    try {
        if (status === 'ACCEPTED') {
            // Logic to update stream permissions for the user
        }
        res.json({ success: true, status });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

router.post('/start', authMiddleware, async (req, res) => {
    // Logic to initialize live stream metadata
    res.json({ success: true, data: { streamId: 'stream_123', token: 'live_token' } });
});

module.exports = router;