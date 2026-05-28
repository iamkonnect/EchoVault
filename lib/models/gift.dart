enum GiftCategory { percussion, wind, strings, special }
enum GiftTier { starter, mid, high, premium }

class Gift {
  final String id;
  final String nameKey; // For localization
  final String iconPath;
  final String soundPath;
  final int coinPrice;
  final GiftCategory category;
  final GiftTier tier;
  final bool isLimitedEdition;

  const Gift({
    required this.id,
    required this.nameKey,
    required this.iconPath,
    required this.soundPath,
    required this.coinPrice,
    required this.category,
    required this.tier,
    this.isLimitedEdition = false,
  });

  double get tshValue => coinPrice * 50.0;

  // Example of how you'd define the inventory based on your list
  static List<Gift> get inventory => [
    // Starter - Percussion
    const Gift(
      id: 'maracca',
      nameKey: 'giftMaracca',
      iconPath: 'assets/gifts/maracca.png',
      soundPath: 'assets/sounds/maracca.mp3',
      coinPrice: 5,
      category: GiftCategory.percussion,
      tier: GiftTier.starter,
    ),
    const Gift(
      id: 'tambourine',
      nameKey: 'giftTambourine',
      iconPath: 'assets/gifts/tambourine.png',
      soundPath: 'assets/sounds/tambourine.mp3',
      coinPrice: 8,
      category: GiftCategory.percussion,
      tier: GiftTier.starter,
    ),
    // Mid Tier - The Melodic Collection
    const Gift(
      id: 'guitar_acoustic',
      nameKey: 'giftGuitar',
      iconPath: 'assets/gifts/guitar.png',
      soundPath: 'assets/sounds/guitar.mp3',
      coinPrice: 250,
      category: GiftCategory.strings,
      tier: GiftTier.mid,
    ),
    // High Tier - The Brass & Orchestra
    const Gift(
      id: 'saxophone',
      nameKey: 'giftSaxophone',
      iconPath: 'assets/gifts/saxophone.png',
      soundPath: 'assets/sounds/saxophone.mp3',
      coinPrice: 600,
      category: GiftCategory.wind,
      tier: GiftTier.high,
    ),
    // Premium Tier - The Masterpiece Gifts
    const Gift(
      id: 'electric_guitar',
      nameKey: 'giftElectricGuitar',
      iconPath: 'assets/gifts/electric_guitar.png',
      soundPath: 'assets/sounds/electric_guitar.mp3',
      coinPrice: 1000,
      category: GiftCategory.special,
      tier: GiftTier.premium,
    ),
    const Gift(
      id: 'piano_grand',
      nameKey: 'giftPiano',
      iconPath: 'assets/gifts/piano.png',
      soundPath: 'assets/sounds/piano.mp3',
      coinPrice: 5000,
      category: GiftCategory.special,
      tier: GiftTier.premium,
    ),
    // ... add all 30 instruments here
  ];
}