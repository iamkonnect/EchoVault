const express = require('express');
const router = express.Router();
const paymentController = require('../controllers/paymentController');
const authMiddleware = require('../middleware/authMiddleware'); // Assuming this path

// GET /api/payments/coin-packages
// Fetches a list of predefined coin packages for users to purchase
router.get('/coin-packages', authMiddleware, paymentController.getCoinPackages);

// POST /api/payments/initiate
// Initiates a payment process for purchasing coins
router.post('/initiate', authMiddleware, paymentController.initiatePayment);

// POST /api/payments/webhook/:gatewayName
// Webhook endpoint for payment gateways to notify about transaction status
// This route might not need authMiddleware depending on gateway security (e.g., signature verification)
router.post('/webhook/:gatewayName', paymentController.handlePaymentWebhook);

module.exports = router;