import 'package:flutter/material.dart';

/// The 3 high-level game modes selectable from the home screen
enum WobblyGameMode {
  /// Single device pass & play at the table
  table,
  /// Multiplayer room in the same physical room (includes proximity/flirt dares)
  party,
  /// Remote multiplayer room across different houses (camera/screenshot/social dares)
  remote,
}

/// Status of the active multiplayer room
enum RoomStatus {
  lobby,
  objects,
  packs,
  spinning,
  decisionPending,
  cardOpen,
  adBreak,
}

/// Represents a connected player in the multiplayer room
class NetworkPlayer {
  final String id;
  String name;
  int colorIndex;
  bool isHost;
  bool isVip;
  bool isAfk;
  DateTime lastSeen;
  int completedTasks;
  int penaltiesTaken;

  NetworkPlayer({
    required this.id,
    required this.name,
    required this.colorIndex,
    this.isHost = false,
    this.isVip = false,
    this.isAfk = false,
    DateTime? lastSeen,
    this.completedTasks = 0,
    this.penaltiesTaken = 0,
  }) : lastSeen = lastSeen ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'colorIndex': colorIndex,
    'isHost': isHost,
    'isVip': isVip,
    'isAfk': isAfk,
    'completedTasks': completedTasks,
    'penaltiesTaken': penaltiesTaken,
    'lastSeen': lastSeen.millisecondsSinceEpoch,
  };

  factory NetworkPlayer.fromJson(Map<String, dynamic> json) => NetworkPlayer(
    id: json['id'] as String,
    name: json['name'] as String? ?? 'Player',
    colorIndex: json['colorIndex'] as int? ?? 0,
    isHost: json['isHost'] as bool? ?? false,
    isVip: json['isVip'] as bool? ?? false,
    isAfk: json['isAfk'] as bool? ?? false,
    completedTasks: json['completedTasks'] as int? ?? 0,
    penaltiesTaken: (json['penaltiesTaken'] ?? json['penaltyShots']) as int? ?? 0,
    lastSeen: json['lastSeen'] != null
        ? DateTime.fromMillisecondsSinceEpoch(json['lastSeen'] as int)
        : DateTime.now(),
  );

  Color get color {
    const playerColors = [
      Color(0xFF00F2FE), // Cyan
      Color(0xFFFF0844), // Pink/Red
      Color(0xFFFF9500), // Orange
      Color(0xFFAF52DE), // Purple
      Color(0xFFFFCC00), // Yellow
      Color(0xFF34C759), // Green
      Color(0xFF3B82F6), // Electric Blue
      Color(0xFFFF2E93), // Hot Magenta
      Color(0xFFA8FF00), // Neon Lime
      Color(0xFFFF6B4A), // Neon Coral
    ];
    if (colorIndex >= 0 && colorIndex < playerColors.length) {
      return playerColors[colorIndex];
    }
    return playerColors[0];
  }
}

/// The complete state of an active room
class RoomState {
  final String roomCode;
  final String pin;
  final WobblyGameMode mode;
  String hostId;
  RoomStatus status;
  List<NetworkPlayer> players;
  List<bool> selectedPacks;
  int selectedObjectIndex;
  
  // Active Spin synchronization
  double currentAngle;
  double targetAngle;
  String bendVariant; // "0", "l", "r"
  int answererIndex;
  int questionerIndex;

  // Active Card synchronization
  String? activeMode; // "TRUTH", "DARE", "FREE"
  int? activePackIndex;
  int? activeQuestionIndex;
  String? activePromptOverride; // fallback text if not from db

  // Cooldown / Kick tracking: map of playerId -> ban expiration timestamp
  Map<String, int> bannedPlayers;

  // Synchronization counter for ad breaks
  int spinCounter;

  RoomState({
    required this.roomCode,
    required this.pin,
    required this.mode,
    required this.hostId,
    this.status = RoomStatus.lobby,
    List<NetworkPlayer>? players,
    List<bool>? selectedPacks,
    this.selectedObjectIndex = 0,
    this.currentAngle = 0.0,
    this.targetAngle = 0.0,
    this.bendVariant = "0",
    this.answererIndex = -1,
    this.questionerIndex = -1,
    this.activeMode,
    this.activePackIndex,
    this.activeQuestionIndex,
    this.activePromptOverride,
    Map<String, int>? bannedPlayers,
    this.spinCounter = 0,
  })  : players = players ?? [],
        selectedPacks = selectedPacks ?? [true, false, false, false, false, false],
        bannedPlayers = bannedPlayers ?? {};

  bool get isVipRoom {
    final host = players.cast<NetworkPlayer?>().firstWhere(
      (p) => p?.id == hostId,
      orElse: () => null,
    );
    return host?.isVip ?? false;
  }

  Map<String, dynamic> toJson() => {
    'roomCode': roomCode,
    'pin': pin,
    'mode': mode.name,
    'hostId': hostId,
    'status': status.name,
    'players': players.map((p) => p.toJson()).toList(),
    'selectedPacks': selectedPacks,
    'selectedObjectIndex': selectedObjectIndex,
    'currentAngle': currentAngle,
    'targetAngle': targetAngle,
    'bendVariant': bendVariant,
    'answererIndex': answererIndex,
    'questionerIndex': questionerIndex,
    'activeMode': activeMode,
    'activePackIndex': activePackIndex,
    'activeQuestionIndex': activeQuestionIndex,
    'activePromptOverride': activePromptOverride,
    'bannedPlayers': bannedPlayers,
    'spinCounter': spinCounter,
  };

  factory RoomState.fromJson(Map<String, dynamic> json) => RoomState(
    roomCode: json['roomCode'] as String,
    pin: json['pin'] as String,
    mode: WobblyGameMode.values.firstWhere(
      (m) => m.name == json['mode'],
      orElse: () => WobblyGameMode.party,
    ),
    hostId: json['hostId'] as String,
    status: RoomStatus.values.firstWhere(
      (s) => s.name == json['status'],
      orElse: () => RoomStatus.lobby,
    ),
    players: (json['players'] as List<dynamic>?)
            ?.map((p) => NetworkPlayer.fromJson(p as Map<String, dynamic>))
            .toList() ??
        [],
    selectedPacks: (json['selectedPacks'] as List<dynamic>?)
            ?.map((e) => e as bool)
            .toList() ??
        [true, false, false, false, false, false],
    selectedObjectIndex: json['selectedObjectIndex'] as int? ?? 0,
    currentAngle: (json['currentAngle'] as num?)?.toDouble() ?? 0.0,
    targetAngle: (json['targetAngle'] as num?)?.toDouble() ?? 0.0,
    bendVariant: json['bendVariant'] as String? ?? "0",
    answererIndex: json['answererIndex'] as int? ?? -1,
    questionerIndex: json['questionerIndex'] as int? ?? -1,
    activeMode: json['activeMode'] as String?,
    activePackIndex: json['activePackIndex'] as int?,
    activeQuestionIndex: json['activeQuestionIndex'] as int?,
    activePromptOverride: json['activePromptOverride'] as String?,
    bannedPlayers: (json['bannedPlayers'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(k, v as int),
        ) ??
        {},
    spinCounter: json['spinCounter'] as int? ?? 0,
  );
}

/// Network event packet passed over the real-time channel
class RoomEvent {
  final String type; // "JOIN", "LEAVE", "SYNC", "SPIN", "CHOOSE", "CARD", "DONE", "KICK", "PING"
  final String senderId;
  final Map<String, dynamic> payload;
  final int timestamp;

  RoomEvent({
    required this.type,
    required this.senderId,
    required this.payload,
    int? timestamp,
  }) : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toJson() => {
    'type': type,
    'senderId': senderId,
    'payload': payload,
    'timestamp': timestamp,
  };

  factory RoomEvent.fromJson(Map<String, dynamic> json) => RoomEvent(
    type: json['type'] as String,
    senderId: json['senderId'] as String? ?? '',
    payload: (json['payload'] as Map<String, dynamic>?) ?? {},
    timestamp: json['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
  );
}
