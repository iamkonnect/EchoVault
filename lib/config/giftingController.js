/**
 * Gifting Controller
 * Handles revenue splits, tax calculations, and balance updates for Streamers and Listeners.
 */
const prisma = require('../../../Desktop/echo-vault-backend/src/utils/prisma');

// Helper to calculate tax based on country (Mock logic - replace with a real tax API/Table)
const calculateTax = (amount, country) => {
    const taxRates = {
        'US': 0.10,
        'UK': 0.20,
        'KE': 0.16,
        'NG': 0.075,
        'DEFAULT': 0.15
    };
    const rate = taxRates[country] || taxRates['DEFAULT'];
    return amount * rate;
};

exports.getGifts = async (req, res) => {
    try {
        // Fetch gifts that were uploaded via the Admin Management panel
        const gifts = await prisma.giftTemplate.findMany({
            where: { isActive: true },
            orderBy: { price: 'asc' }
        });
        return res.json({ success: true, data: gifts });
    } catch (error) {
        return res.status(500).json({ success: false, message: 'Failed to fetch gifts' });
    }
};

exports.sendGift = async (req, res) => {
    const { 
        giftId, 
        receiverId,      // The Artist/Streamer
        isShortChallenge, 
        challengerId,    // The Listener who created the challenge
        amount: bodyAmount // Face value of the gift from request (unused for security)
    } = req.body;

    try {
        // 1. Fetch Sender, Receiver, Challenger, and the actual Gift details from DB
        const [sender, artist, challenger, gift] = await Promise.all([
            prisma.user.findUnique({ where: { id: req.user.id } }),
            prisma.user.findUnique({ where: { id: receiverId } }),
            challengerId ? prisma.user.findUnique({ where: { id: challengerId } }) : null,
            prisma.giftTemplate.findUnique({ where: { id: giftId } })
        ]);

        if (!artist || !gift) {
            return res.status(404).json({ success: false, message: "Artist or Gift type not found" });
        }

        // Use the price stored in the DB for security, not what was sent from the frontend body
        const amount = gift.price;
        
        // REQUIREMENT NO. 5: Verification Check
        if (!artist.isVerified) {
            return res.status(403).json({ success: false, message: "Artist is not verified to receive gifts" });
        }

        // Check sender balance
        if (sender.walletBalance < amount) {
            return res.status(400).json({ success: false, message: "Insufficient balance" });
        }

        let adminShare = 0;
        let artistShare = 0;
        let listenerShare = 0;

        /**
         * REQUIREMENT NO. 4: Shorts Revenue Split
         * If Listener created challenge: Artist 40, Listener 60, Admin 20.
         * Note: These are parts of a whole. Since 40+60+20 = 120, we treat them as weights 
         * or take Admin 20% first then split 40/60 of the remainder.
         */
        if (isShortChallenge && challengerId) {
            // Calculate Admin 20% first
            adminShare = amount * 0.20;
            const remainingRevenue = amount - adminShare;

            // Split remaining revenue between Artist (40%) and Listener (60%)
            artistShare = remainingRevenue * 0.40;
            listenerShare = remainingRevenue * 0.60;
        } 
        /**
         * If Artist created the challenge: Artist 80, Admin 20.
         */
        else if (isShortChallenge && !challengerId) {
            adminShare = amount * 0.20;
            artistShare = amount * 0.80;
        }
        /**
         * STANDARD GIFTING (Requirement No. 3)
         */
        else {
            adminShare = amount * 0.20;
            artistShare = amount * 0.80;
        }

        // 2. Apply Country-Specific Tax on the Artist's Net earnings
        const taxAmount = calculateTax(artistShare, artist.country || 'DEFAULT');
        const artistFinalNet = artistShare - taxAmount;

        // 3. Database Operations (Atomic Transaction)
        await prisma.$transaction([
            // Deduct from sender
            prisma.user.update({
                where: { id: sender.id },
                data: { walletBalance: { decrement: amount } }
            }),
            // Credit Artist
            prisma.user.update({
                where: { id: receiverId },
                data: { walletBalance: { increment: artistFinalNet } }
            }),
            // Credit Challenger (if applicable)
            ...(listenerShare > 0 && challengerId ? [
                prisma.user.update({
                    where: { id: challengerId },
                    data: { walletBalance: { increment: listenerShare } }
                })
            ] : []),
            // Record transaction for history
            prisma.transaction.create({
                data: {
                    userId: sender.id,
                    amount: amount,
                    type: 'GIFT_SENT',
                    status: 'COMPLETED',
                    description: `Sent gift ${giftId} to ${artist.name}`
                }
            })
        ]);

        return res.json({
            success: true,
            message: "Gift processed successfully",
            payoutDetails: {
                total: amount,
                platformRevenue: (adminShare + taxAmount).toFixed(2),
                artistNet: artistFinalNet.toFixed(2),
                listenerNet: listenerShare.toFixed(2),
            }
        });
    } catch (error) {
        return res.status(500).json({ success: false, error: error.message });
    }
};