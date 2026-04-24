import 'package:hive/hive.dart';

part 'track.g.dart';

@HiveType(typeId: 0)
class Track extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  Artist? artist;

  @HiveField(3)
  List<Artist>? artists;

  @HiveField(4)
  Album? album;

  @HiveField(5)
  int duration;

  @HiveField(6)
  String? audioQuality;

  @HiveField(7)
  bool isExplicit;

  @HiveField(8)
  String? cover;

  @HiveField(9)
  String? type; // 'track', 'video'

  @HiveField(10)
  int? popularity;

  @HiveField(11)
  String? releaseDate;

  Track({
    required this.id,
    required this.title,
    this.artist,
    this.artists,
    this.album,
    required this.duration,
    this.audioQuality,
    this.isExplicit = false,
    this.cover,
    this.type,
    this.popularity,
    this.releaseDate,
  });
}

@HiveType(typeId: 1)
class Artist {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? picture;

  @HiveField(3)
  List<String>? artistTypes;

  Artist({
    required this.id,
    required this.name,
    this.picture,
    this.artistTypes,
  });
}

@HiveType(typeId: 2)
class Album {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  Artist? artist;

  @HiveField(3)
  int? numberOfTracks;

  @HiveField(4)
  String? releaseDate;

  @HiveField(5)
  String? cover;

  @HiveField(6)
  String? type; // 'ALBUM', 'EP', 'SINGLE'

  @HiveField(7)
  int? totalDiscs;

  @HiveField(8)
  int? numberOfTracksOnDisc;

  Album({
    required this.id,
    required this.title,
    this.artist,
    this.numberOfTracks,
    this.releaseDate,
    this.cover,
    this.type,
    this.totalDiscs,
    this.numberOfTracksOnDisc,
  });
}
