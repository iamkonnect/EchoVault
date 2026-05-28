import 'package:flutter/material.dart';

/// Enum for different verification icon styles
enum VerificationIconStyle {
  musicNote,    // 🎵 Music note
  star,         // ⭐ Star
  checkmark,    // ✓ Checkmark in circle
  verified,     // Verified badge
  badge,        // Custom badge
}

/// Widget to display artist name with verification badge
class VerifiedArtistName extends StatelessWidget {
  final String artistName;
  final bool isVerified;
  final VerificationIconStyle iconStyle;
  final double iconSize;
  final Color iconColor;
  final TextStyle textStyle;
  final EdgeInsets padding;

  const VerifiedArtistName({
    super.key,
    required this.artistName,
    this.isVerified = false,
    this.iconStyle = VerificationIconStyle.musicNote,
    this.iconSize = 18.0,
    this.iconColor = Colors.amber,
    this.textStyle = const TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 16,
      color: Colors.white,
    ),
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(artistName, style: textStyle),
        if (isVerified) ...[
          const SizedBox(width: 6),
          _buildVerificationIcon(),
        ],
      ],
    );
  }

  /// Build verification icon based on style
  Widget _buildVerificationIcon() {
    IconData iconData;
    
    switch (iconStyle) {
      case VerificationIconStyle.musicNote:
        iconData = Icons.music_note;
        break;
      case VerificationIconStyle.star:
        iconData = Icons.star;
        break;
      case VerificationIconStyle.checkmark:
        iconData = Icons.check_circle;
        break;
      case VerificationIconStyle.verified:
        iconData = Icons.verified;
        break;
      case VerificationIconStyle.badge:
        // Return a custom badge widget
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [iconColor.withOpacity(0.8), iconColor.withOpacity(0.5)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified, size: iconSize * 0.8, color: Colors.white),
              const SizedBox(width: 2),
              Text(
                'Verified',
                style: TextStyle(
                  fontSize: iconSize * 0.7,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
    }

    return Icon(
      iconData,
      size: iconSize,
      color: iconColor,
    );
  }
}

/// Card widget for displaying artist with verification status
class ArtistCard extends StatelessWidget {
  final String artistId;
  final String artistName;
  final String artistEmail;
  final bool isVerified;
  final VoidCallback? onTap;
  final bool showVerificationBadge;

  const ArtistCard({
    super.key,
    required this.artistId,
    required this.artistName,
    required this.artistEmail,
    this.isVerified = false,
    this.onTap,
    this.showVerificationBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isVerified ? Colors.amber.withOpacity(0.5) : Colors.white10,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Artist Avatar
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Colors.purple.shade300,
                    Colors.purple.shade700,
                  ],
                ),
              ),
              child: Center(
                child: Text(
                  artistName.isNotEmpty ? artistName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Artist Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name with Verification
                  VerifiedArtistName(
                    artistName: artistName,
                    isVerified: isVerified && showVerificationBadge,
                    iconStyle: VerificationIconStyle.musicNote,
                    iconColor: Colors.amber,
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Email
                  Text(
                    artistEmail,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Verification Status
            if (showVerificationBadge)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isVerified
                      ? Colors.green.withOpacity(0.2)
                      : Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isVerified
                        ? Colors.green.withOpacity(0.5)
                        : Colors.orange.withOpacity(0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isVerified ? Icons.check_circle : Icons.hourglass_empty,
                      size: 14,
                      color:
                          isVerified ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isVerified ? 'Verified' : 'Pending',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isVerified ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// List of artists with verification status
class VerifiedArtistsList extends StatelessWidget {
  final List<Map<String, dynamic>> artists;
  final Function(String artistId)? onArtistTap;
  final bool showVerificationStatus;

  const VerifiedArtistsList({
    super.key,
    required this.artists,
    this.onArtistTap,
    this.showVerificationStatus = true,
  });

  @override
  Widget build(BuildContext context) {
    if (artists.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const Icon(
                Icons.music_note,
                size: 64,
                color: Colors.white30,
              ),
              const SizedBox(height: 16),
              Text(
                'No artists yet',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: artists.length,
      itemBuilder: (context, index) {
        final artist = artists[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ArtistCard(
            artistId: artist['id'] ?? '',
            artistName: artist['name'] ?? 'Unknown',
            artistEmail: artist['email'] ?? '',
            isVerified: artist['isVerified'] ?? false,
            showVerificationBadge: showVerificationStatus,
            onTap: () => onArtistTap?.call(artist['id'] ?? ''),
          ),
        );
      },
    );
  }
}

/// Example usage in your main app
class ArtistProfileHeader extends StatelessWidget {
  final String artistName;
  final String artistBio;
  final bool isVerified;
  final int followerCount;

  const ArtistProfileHeader({
    super.key,
    required this.artistName,
    required this.artistBio,
    this.isVerified = false,
    this.followerCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.shade700,
            Colors.purple.shade900,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Artist Name with Verification
          Row(
            children: [
              Expanded(
                child: VerifiedArtistName(
                  artistName: artistName,
                  isVerified: isVerified,
                  iconStyle: VerificationIconStyle.badge,
                  iconColor: Colors.amber,
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Bio
          Text(
            artistBio,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          // Followers
          Row(
            children: [
              const Icon(
                Icons.people,
                size: 16,
                color: Colors.white70,
              ),
              const SizedBox(width: 8),
              Text(
                '$followerCount Followers',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 16),
              if (isVerified)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.music_note,
                        size: 12,
                        color: Colors.amber,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Verified Artist',
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
