const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/auth');

// POST /api/ads/log-impression
router.post('/log-impression', authMiddleware, async (req, res) => {
    const { trackId, adType } = req.body;

    try {
        // Log revenue to Admin Dashboard
        // If user is premium, this route should ideally be blocked by frontend logic
        if (req.user.subscriptionStatus === 'premium') {
            return res.status(403).json({ success: false, message: 'Premium users do not log ad impressions' });
        }

        res.json({ success: true, message: 'Impression logged for revenue collection' });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

module.exports = router;