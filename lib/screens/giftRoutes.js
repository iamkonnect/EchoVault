const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/auth'); // Assume auth middleware exists

// GET /api/gifts - Fetch available gifts (posted via admin dashboard)
router.get('/', async (req, res) => {
    try {
        // In a real app, fetch from MongoDB/PostgreSQL
        const gifts = [
            { id: 'rose', name: 'Rose', price: 1.00, icon: '🌹' },
            { id: 'diamond', name: 'Diamond', price: 50.00, icon: '💎' },
            { id: 'crown', name: 'Crown', price: 100.00, icon: '👑' }
        ];
        res.json({ success: true, data: gifts });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

// POST /api/gifts/send - Handle gifting with revenue splits
router.post('/send', authMiddleware, async (req, res) => {
    const { receiverId, giftId, isShortChallenge, listenerId } = req.body;
    
    // Logic for splits as per requirements:
    // Standard: Admin 20%, Streamer 80%
    // Shorts Challenge (Listener created): Artist 40, Listener 60, Admin 20 (scaled to 100%)
    
    try {
        // 1. Fetch gift price from DB
        const giftPrice = 10.00; // Example placeholder
        let adminCut, artistCut, listenerCut;

        if (isShortChallenge && listenerId) {
            // Requirements specified 40/60/20 split
            // We treat these as parts of 120 total or normalize to 100. 
            // Let's assume Admin takes 20% flat, then split remaining 80% between Artist and Listener.
            adminCut = giftPrice * 0.20;
            const remaining = giftPrice - adminCut;
            artistCut = remaining * 0.40;
            listenerCut = remaining * 0.60;
        } else {
            // Standard 80/20 split
            adminCut = giftPrice * 0.20;
            artistCut = giftPrice * 0.80;
            listenerCut = 0;
        }

        // 2. Update Balances in DB (Logic would happen in Controller)
        res.json({ success: true, message: 'Gift sent!', splits: { adminCut, artistCut, listenerCut } });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

module.exports = router;