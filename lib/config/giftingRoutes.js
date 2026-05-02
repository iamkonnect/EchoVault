const express = require('express');
const router = express.Router();
const giftingController = require('../controllers/giftingController');
const authMiddleware = require('../middleware/authMiddleware');

// Publicly available list of gifts
router.get('/list', giftingController.getGifts); // Fetches items from GiftManagement

// Protected route to send a gift
router.post('/send', authMiddleware, giftingController.sendGift); // Processes the transaction

module.exports = router;