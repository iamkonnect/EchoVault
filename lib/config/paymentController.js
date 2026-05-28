/**
 * Payment Controller
 * Handles coin package retrieval, payment initiation, and webhook processing.
 */
const prisma = require('../utils/prisma'); // Assuming prisma client is here

// Mock payment gateway services (replace with actual SDK integrations)
const paypalService = {
    initiate: async (amount, userId, transactionId) => {
        // Simulate API call to PayPal
        console.log(`Initiating PayPal payment for user ${userId}, amount ${amount}, transaction ${transactionId}`);
        // In a real scenario, this would return a PayPal redirect URL or approval ID
        return {
            success: true,
            redirectUrl: `https://mock-paypal.com/pay?amount=${amount}&tx=${transactionId}`,
            gatewayTransactionId: `paypal_tx_${Date.now()}`
        };
    },
    verifyWebhook: (payload, signature) => {
        // Simulate PayPal webhook verification logic
        return true; // Always true for mock
    }
};

const mobileMoneyService = {
    initiate: async (amount, phoneNumber, userId, transactionId) => {
        // Simulate API call to M-Pesa, Airtel Money, etc.
        console.log(`Initiating Mobile Money payment for user ${userId}, phone ${phoneNumber}, amount ${amount}, transaction ${transactionId}`);
        // In a real scenario, this would trigger a STK push or return a payment reference
        return {
            success: true,
            message: 'STK push initiated. Awaiting confirmation.',
            gatewayTransactionId: `momo_tx_${Date.now()}`
        };
    },
    verifyWebhook: (payload, signature) => {
        // Simulate Mobile Money webhook verification logic
        return true; // Always true for mock
    }
};

const stripeService = { // For Credit/Debit Cards
    initiate: async (amount, userId, transactionId) => {
        // Simulate API call to Stripe
        console.log(`Initiating Stripe payment for user ${userId}, amount ${amount}, transaction ${transactionId}`);
        // In a real scenario, this would return a client secret for frontend to complete payment
        return {
            success: true,
            clientSecret: `stripe_client_secret_${Date.now()}`,
            gatewayTransactionId: `stripe_tx_${Date.now()}`
        };
    },
    verifyWebhook: (payload, signature) => {
        // Simulate Stripe webhook verification logic
        return true; // Always true for mock
    }
};

exports.getCoinPackages = async (req, res) => {
    try {
        const packages = await prisma.coinPackage.findMany({
            where: { isActive: true },
            orderBy: { price: 'asc' }
        });
        return res.json({ success: true, data: packages });
    } catch (error) {
        console.error('Error fetching coin packages:', error);
        return res.status(500).json({ success: false, message: 'Failed to fetch coin packages' });
    }
};

exports.initiatePayment = async (req, res) => {
    const { packageId, customAmount, paymentMethod, phoneNumber } = req.body;
    const userId = req.user.id; // Assuming user ID from auth middleware

    try {
        let amountToPay;
        let coinsToReceive;

        if (packageId) {
            const coinPackage = await prisma.coinPackage.findUnique({ where: { id: packageId } });
            if (!coinPackage || !coinPackage.isActive) {
                return res.status(404).json({ success: false, message: 'Coin package not found or inactive' });
            }
            amountToPay = coinPackage.price;
            coinsToReceive = coinPackage.coins;
        } else if (customAmount && customAmount > 0) {
            amountToPay = parseFloat(customAmount);
            // Define your custom amount to coin conversion rate
            coinsToReceive = Math.floor(amountToPay * 100); // Example: $1 = 100 coins
        } else {
            return res.status(400).json({ success: false, message: 'Invalid package or amount' });
        }

        // Create a pending transaction record
        const transaction = await prisma.transaction.create({
            data: {
                userId: userId,
                amount: amountToPay,
                type: 'COIN_PURCHASE',
                status: 'PENDING',
                description: `Purchase ${coinsToReceive} coins via ${paymentMethod}`,
                paymentGateway: paymentMethod,
            }
        });

        let paymentResponse;
        switch (paymentMethod) {
            case 'PAYPAL':
                paymentResponse = await paypalService.initiate(amountToPay, userId, transaction.id);
                break;
            case 'MOBILE_MONEY':
                if (!phoneNumber) return res.status(400).json({ success: false, message: 'Phone number required for Mobile Money' });
                paymentResponse = await mobileMoneyService.initiate(amountToPay, phoneNumber, userId, transaction.id);
                break;
            case 'STRIPE': // For Credit/Debit Cards
                paymentResponse = await stripeService.initiate(amountToPay, userId, transaction.id);
                break;
            default:
                return res.status(400).json({ success: false, message: 'Unsupported payment method' });
        }

        if (paymentResponse.success) {
            // Update transaction with gateway details
            await prisma.transaction.update({
                where: { id: transaction.id },
                data: { gatewayTransactionId: paymentResponse.gatewayTransactionId }
            });
            return res.json({ success: true, message: 'Payment initiated', paymentDetails: paymentResponse });
        } else {
            // Mark transaction as failed if initiation fails
            await prisma.transaction.update({ where: { id: transaction.id }, data: { status: 'FAILED' } });
            return res.status(500).json({ success: false, message: paymentResponse.message || 'Payment initiation failed' });
        }
    } catch (error) {
        console.error('Error initiating payment:', error);
        return res.status(500).json({ success: false, message: 'Internal server error during payment initiation' });
    }
};

exports.handlePaymentWebhook = async (req, res) => {
    const { gatewayName } = req.params;
    // This is where payment gateways will send notifications about completed payments.
    // You'll need to implement specific logic for each gateway to verify the webhook
    // (e.g., check signatures, transaction IDs) and then update the user's balance.
    console.log(`Received webhook from ${gatewayName}:`, req.body);

    try {
        // Example: Verify webhook and extract transaction details
        const isValid = true; // Replace with actual gateway-specific verification
        const gatewayTransactionId = req.body.transactionId; // Example
        const status = req.body.status; // 'COMPLETED', 'FAILED', etc.
        const amountPaid = req.body.amount; // Amount confirmed by gateway

        if (!isValid) {
            return res.status(400).json({ success: false, message: 'Invalid webhook signature' });
        }

        const transaction = await prisma.transaction.findFirst({
            where: { gatewayTransactionId: gatewayTransactionId, status: 'PENDING' }
        });

        if (!transaction) {
            return res.status(404).json({ success: false, message: 'Transaction not found or already processed' });
        }

        if (status === 'COMPLETED' && amountPaid >= transaction.amount) {
            // Update user's wallet balance and mark transaction as completed
            await prisma.$transaction([
                prisma.user.update({
                    where: { id: transaction.userId },
                    data: { walletBalance: { increment: transaction.amount * 100 } } // Assuming $1 = 100 coins
                }),
                prisma.transaction.update({
                    where: { id: transaction.id },
                    data: { status: 'COMPLETED', description: `Coins purchased: ${transaction.amount * 100}` }
                })
            ]);
            console.log(`User ${transaction.userId} credited with ${transaction.amount * 100} coins.`);
            return res.json({ success: true, message: 'Payment successfully processed' });
        } else {
            // Mark transaction as failed
            await prisma.transaction.update({
                where: { id: transaction.id },
                data: { status: 'FAILED', description: `Payment failed via webhook: ${status}` }
            });
            return res.status(200).json({ success: true, message: 'Payment marked as failed' }); // Respond 200 to webhook
        }
    } catch (error) {
        console.error('Error processing payment webhook:', error);
        return res.status(500).json({ success: false, message: 'Internal server error processing webhook' });
    }
};