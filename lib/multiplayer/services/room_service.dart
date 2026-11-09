import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import '../models/room_models.dart';

/// Callback types for room events
typedef OnRoomStateChanged = void Function(RoomState state);
typedef OnKickedCallback = void Function(String reason);
typedef OnToastCallback = void Function(String message);
typedef OnVipGiftedCallback = void Function(
  String giverName,
  String targetId,
  String targetName,
  bool isLifetime,
);
typedef OnRequestGiftPurchaseCallback = void Function(NetworkPlayer targetPlayer);

/// Zero-cost, resilient multiplayer room service for Wobbly Bottle
class RoomService {
  static final RoomService _instance = RoomService._internal();
  factory RoomService() => _instance;
  RoomService._internal();

  // Current session info
  String _myPlayerId = '';
  String _myPlayerName = 'Player';
  int _myColorIndex = 0;
  String _myEmoji = '🥳';
  bool _myIsVip = false;

  RoomState? _currentRoom;
  WebSocket? _socket;
  HttpServer? _localServer;
  final List<WebSocket> _localClientSockets = [];

  StreamSubscription? _socketSub;
  Timer? _heartbeatTimer;
  Timer? _turnTimer;
  Timer? _bgGraceTimer;

  // Stream for UI listening
  final StreamController<RoomState> _roomStateController =
      StreamController<RoomState>.broadcast();
  Stream<RoomState> get roomStateStream => _roomStateController.stream;

  OnKickedCallback? onKicked;
  OnToastCallback? onToast;
  OnVipGiftedCallback? onVipGifted;
  OnRequestGiftPurchaseCallback? onRequestGiftPurchase;

  // Getters
  String get myPlayerId => _myPlayerId;
  String get myPlayerName => _myPlayerName;
  int get myColorIndex => _myColorIndex;
  String get myEmoji => _myEmoji;
  bool get myIsVip => _myIsVip;
  RoomState? get currentRoom => _currentRoom;
  bool get isHost => _currentRoom != null && _currentRoom!.hostId == _myPlayerId;
  bool get isInRoom => _currentRoom != null;

  void initPlayer({
    required String name,
    required int colorIndex,
    required bool isVip,
    String emoji = '🥳',
  }) {
    if (_myPlayerId.isEmpty) {
      _myPlayerId = 'wb_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
    }
    _myPlayerName = name;
    _myColorIndex = colorIndex;
    _myEmoji = emoji;
    _myIsVip = isVip;
  }

  void updateMyEmoji(String newEmoji) {
    _myEmoji = newEmoji;
    if (_currentRoom == null) return;
    if (isHost) {
      for (var p in _currentRoom!.players) {
        if (p.id == _myPlayerId) {
          p.emoji = newEmoji;
        }
      }
      _broadcastSync();
    } else {
      _sendEvent(RoomEvent(
        type: 'UPDATE_EMOJI',
        senderId: _myPlayerId,
        payload: {'emoji': newEmoji},
      ));
    }
  }

  void broadcastVipGift({
    required String targetPlayerId,
    required String targetPlayerName,
    required bool isLifetime,
  }) {
    if (_currentRoom == null) return;
    final event = RoomEvent(
      type: 'GIFT_VIP',
      senderId: _myPlayerId,
      payload: {
        'giverName': _myPlayerName,
        'targetId': targetPlayerId,
        'targetName': targetPlayerName,
        'isLifetime': isLifetime,
      },
    );
    _sendEvent(event);
    if (isHost) {
      for (var p in _currentRoom!.players) {
        if (p.id == targetPlayerId) {
          p.isVip = true;
        }
      }
      _broadcastSync();
    }
  }

  /// Generates a random 6-digit room code (100000 - 999999)
  static String generateRoomCode() {
    final rand = Random();
    return (100000 + rand.nextInt(900000)).toString();
  }

  // =========================================================================
  // HOST: CREATE ROOM
  // =========================================================================
  Future<bool> createRoom({
    required String roomCode,
    required String pin,
    required WobblyGameMode mode,
    required List<bool> selectedPacks,
    int selectedObjectIndex = 0,
  }) async {
    await leaveRoom();

    final hostPlayer = NetworkPlayer(
      id: _myPlayerId,
      name: _myPlayerName,
      colorIndex: _myColorIndex,
      emoji: _myEmoji,
      isHost: true,
      isVip: _myIsVip,
    );

    _currentRoom = RoomState(
      roomCode: roomCode,
      pin: pin,
      mode: mode,
      hostId: _myPlayerId,
      status: RoomStatus.lobby,
      players: [hostPlayer],
      selectedPacks: List.from(selectedPacks),
      selectedObjectIndex: selectedObjectIndex,
    );

    // If VIP admin, allow spicy pack and champagne object
    if (!_myIsVip) {
      if (_currentRoom!.selectedObjectIndex == 4) {
        _currentRoom!.selectedObjectIndex = 0;
      }
      if (_currentRoom!.selectedPacks.length > 4) {
        _currentRoom!.selectedPacks[4] = false; // Spicy pack requires VIP host
      }
    }

    // Connect to WebSocket channel for this room
    final connected = await _connectSocket(roomCode);
    _emitState();
    _startHostWatchdog();
    return connected;
  }

  // =========================================================================
  // CLIENT: JOIN ROOM
  // =========================================================================
  Future<String?> joinRoom({
    required String roomCode,
    required String pin,
  }) async {
    await leaveRoom();

    final connected = await _connectSocket(roomCode);
    if (!connected) {
      return "Sunucuya bağlanılamadı. İnternet bağlantınızı kontrol edin.";
    }

    final completer = Completer<String?>();

    // Send JOIN request
    _sendEvent(RoomEvent(
      type: 'JOIN',
      senderId: _myPlayerId,
      payload: {
        'name': _myPlayerName,
        'colorIndex': _myColorIndex,
        'emoji': _myEmoji,
        'isVip': _myIsVip,
        'pin': pin,
      },
    ));

    // Wait up to 5 seconds for Host validation response
    Timer(const Duration(seconds: 5), () {
      if (!completer.isCompleted) {
        leaveRoom();
        completer.complete("Oda kurucusundan yanıt alınamadı (#$roomCode).");
      }
    });

    late StreamSubscription sub;
    sub = roomStateStream.listen((state) {
      final inList = state.players.any((p) => p.id == _myPlayerId);
      if (inList && !completer.isCompleted) {
        sub.cancel();
        completer.complete(null); // Success
      }
    });

    return completer.future;
  }

  // =========================================================================
  // GAMEPLAY ACTIONS
  // =========================================================================

  /// Any player can spin the bottle when status is lobby or turn completed
  void spinBottle({
    required double startAngle,
    required double targetAngle,
    required String bendVariant,
    required int answererIndex,
    required int questionerIndex,
  }) {
    if (_currentRoom == null) return;
    if (_currentRoom!.status == RoomStatus.spinning) return;

    final event = RoomEvent(
      type: 'SPIN',
      senderId: _myPlayerId,
      payload: {
        'startAngle': startAngle,
        'targetAngle': targetAngle,
        'bendVariant': bendVariant,
        'answererIndex': answererIndex,
        'questionerIndex': questionerIndex,
      },
    );

    if (isHost) {
      _handleSpinEvent(event);
    } else {
      _sendEvent(event);
    }
  }

  /// Answerer chooses Truth, Dare, or Free
  void chooseMode(String mode) {
    if (_currentRoom == null) return;

    final event = RoomEvent(
      type: 'CHOOSE',
      senderId: _myPlayerId,
      payload: {'mode': mode},
    );

    if (isHost) {
      _handleChooseEvent(event);
    } else {
      _sendEvent(event);
    }
  }

  /// Sync spin finish result (called after bottle stops)
  void syncSpinResult({
    required double angle,
    required String bendVariant,
    required int answererIndex,
    required int questionerIndex,
  }) {
    if (_currentRoom == null) return;

    final event = RoomEvent(
      type: 'SPIN_RESULT',
      senderId: _myPlayerId,
      payload: {
        'angle': angle,
        'bendVariant': bendVariant,
        'answererIndex': answererIndex,
        'questionerIndex': questionerIndex,
      },
    );

    if (isHost) {
      _handleSpinResult(event);
    } else {
      _sendEvent(event);
    }
  }

  /// Card drawn with prompt (called by Host or Answerer)
  void publishCard({
    required String mode,
    int? packIndex,
    int? questionIndex,
    String? promptOverride,
    int? answererIndex,
    int? questionerIndex,
  }) {
    if (_currentRoom == null) return;

    if (answererIndex != null && answererIndex >= 0) {
      _currentRoom!.answererIndex = answererIndex;
    }
    if (questionerIndex != null && questionerIndex >= 0) {
      _currentRoom!.questionerIndex = questionerIndex;
    }

    if (isHost) {
      _currentRoom!.status = RoomStatus.cardOpen;
      _currentRoom!.activeMode = mode;
      _currentRoom!.activePackIndex = packIndex;
      _currentRoom!.activeQuestionIndex = questionIndex;
      _currentRoom!.activePromptOverride = promptOverride;

      _broadcastSync();
      _startTurnTimer(); // 30-second response countdown
    } else {
      _sendEvent(RoomEvent(
        type: 'PUBLISH_CARD',
        senderId: _myPlayerId,
        payload: {
          'mode': mode,
          'packIndex': packIndex,
          'questionIndex': questionIndex,
          'promptOverride': promptOverride,
          'answererIndex': answererIndex,
          'questionerIndex': questionerIndex,
        },
      ));
    }
  }

  /// Complete task or accept group penalty
  void completeTurn({required bool tookPenalty}) {
    if (_currentRoom == null) return;

    final event = RoomEvent(
      type: 'DONE',
      senderId: _myPlayerId,
      payload: {'penalty': tookPenalty},
    );

    if (isHost) {
      _handleDoneEvent(event);
    } else {
      _sendEvent(event);
    }
  }

  /// Admin kicks a player (with 10-minute ban)
  void kickPlayer(String targetPlayerId) {
    if (!isHost || _currentRoom == null) return;
    if (targetPlayerId == _myPlayerId) return;

    final banExpires = DateTime.now().add(const Duration(minutes: 10)).millisecondsSinceEpoch;
    _currentRoom!.bannedPlayers[targetPlayerId] = banExpires;
    _currentRoom!.players.removeWhere((p) => p.id == targetPlayerId);

    _sendEvent(RoomEvent(
      type: 'KICK',
      senderId: _myPlayerId,
      payload: {'targetId': targetPlayerId},
    ));

    _broadcastSync();
  }

  /// Update pack selection (Host only)
  void updatePacks(List<bool> packs) {
    if (!isHost || _currentRoom == null) return;
    _currentRoom!.selectedPacks = List.from(packs);
    if (!_currentRoom!.isVipRoom && _currentRoom!.selectedPacks.length > 4) {
      _currentRoom!.selectedPacks[4] = false; // Non-vip cannot enable spicy pack
    }
    _broadcastSync();
  }

  /// Update selected bottle object (Host only)
  void updateBottleObject(int objectIndex) {
    if (!isHost || _currentRoom == null) return;
    if (objectIndex == 4 && !_currentRoom!.isVipRoom) {
      objectIndex = 0; // Champagne requires VIP
    }
    _currentRoom!.selectedObjectIndex = objectIndex;
    _broadcastSync();
  }

  /// Host transfers admin role to another player
  void transferHost(String targetPlayerId) {
    if (!isHost || _currentRoom == null) return;
    if (targetPlayerId == _myPlayerId) return;

    for (var p in _currentRoom!.players) {
      if (p.id == _myPlayerId) {
        p.isHost = false;
      } else if (p.id == targetPlayerId) {
        p.isHost = true;
      }
    }
    _currentRoom!.hostId = targetPlayerId;
    _broadcastSync();
  }

  /// Change room status (Host only: lobby, objects, packs, etc.)
  void setStatus(RoomStatus newStatus) {
    if (!isHost || _currentRoom == null) return;
    _currentRoom!.status = newStatus;
    _broadcastSync();
  }

  void proceedToObjects() {
    if (!isHost || _currentRoom == null) return;
    _currentRoom!.status = RoomStatus.objects;
    _broadcastSync();
  }

  void proceedToPacks({required int selectedObjectIndex}) {
    if (!isHost || _currentRoom == null) return;
    if (selectedObjectIndex == 4 && !_currentRoom!.isVipRoom) {
      selectedObjectIndex = 0;
    }
    _currentRoom!.selectedObjectIndex = selectedObjectIndex;
    _currentRoom!.status = RoomStatus.packs;
    _broadcastSync();
  }

  void proceedToArena({required List<bool> selectedPacks}) {
    if (!isHost || _currentRoom == null) return;
    _currentRoom!.selectedPacks = List.from(selectedPacks);
    if (!_currentRoom!.isVipRoom && _currentRoom!.selectedPacks.length > 4) {
      _currentRoom!.selectedPacks[4] = false;
    }
    _currentRoom!.status = RoomStatus.decisionPending;
    _broadcastSync();
  }

  // =========================================================================
  // APP LIFECYCLE: BACKGROUND / AFK MANAGEMENT
  // =========================================================================
  void handleAppPaused() {
    if (_currentRoom == null) return;
    _sendEvent(RoomEvent(
      type: 'PAUSE',
      senderId: _myPlayerId,
      payload: {},
    ));

    // Start 3-minute grace timer on client side
    _bgGraceTimer?.cancel();
    _bgGraceTimer = Timer(const Duration(minutes: 3), () {
      leaveRoom();
    });
  }

  void handleAppResumed() {
    _bgGraceTimer?.cancel();
    if (_currentRoom != null) {
      _sendEvent(RoomEvent(
        type: 'RESUME',
        senderId: _myPlayerId,
        payload: {},
      ));
    }
  }

  // =========================================================================
  // LEAVE / CLEANUP
  // =========================================================================
  Future<void> leaveRoom() async {
    _heartbeatTimer?.cancel();
    _turnTimer?.cancel();
    _bgGraceTimer?.cancel();

    if (_currentRoom != null) {
      try {
        _sendEvent(RoomEvent(
          type: 'LEAVE',
          senderId: _myPlayerId,
          payload: {},
        ));
      } catch (_) {}
    }

    await _socketSub?.cancel();
    _socketSub = null;
    await _socket?.close();
    _socket = null;

    for (var s in _localClientSockets) {
      try {
        s.close();
      } catch (_) {}
    }
    _localClientSockets.clear();
    await _localServer?.close(force: true);
    _localServer = null;

    _currentRoom = null;
    _emitState();
  }

  // =========================================================================
  // WEBSOCKET RELAY & LOCAL SERVER
  // =========================================================================
  Future<bool> _connectSocket(String roomCode) async {
    try {
      // Free public resilient WebSocket pub/sub channel
      final uri = Uri.parse(
          'wss://free.blr2.piesocket.com/v3/wb_room_$roomCode?api_key=B9UKgvptNTWrZxfCUTquFp7nKVsYqu2LtmBao5Jg&notify_self=1');
      _socket = await WebSocket.connect(uri.toString())
          .timeout(const Duration(seconds: 4));

      _socketSub = _socket!.listen(
        (data) => _onRawMessage(data),
        onError: (err) => _onSocketError(err),
        onDone: () => _onSocketDone(),
      );

      // Start periodic ping/heartbeat every 15 seconds
      _heartbeatTimer?.cancel();
      _heartbeatTimer = Timer.periodic(const Duration(seconds: 15), (_) {
        if (_socket != null && _socket!.readyState == WebSocket.open) {
          _sendEvent(RoomEvent(
            type: 'PING',
            senderId: _myPlayerId,
            payload: {},
          ));
        }
      });

      return true;
    } catch (_) {
      // Fallback: If cloud broker unreachable, Host can act as local Wi-Fi server
      if (isHost && _localServer == null) {
        try {
          _localServer = await HttpServer.bind(InternetAddress.anyIPv4, 8492);
          _localServer!.listen((req) async {
            if (WebSocketTransformer.isUpgradeRequest(req)) {
              final ws = await WebSocketTransformer.upgrade(req);
              _localClientSockets.add(ws);
              ws.listen(
                (data) {
                  _onRawMessage(data);
                  // Relay to other local clients
                  for (var client in _localClientSockets) {
                    if (client != ws && client.readyState == WebSocket.open) {
                      client.add(data);
                    }
                  }
                },
                onDone: () => _localClientSockets.remove(ws),
                onError: (_) => _localClientSockets.remove(ws),
              );
            }
          });
          return true;
        } catch (_) {}
      }
      return false;
    }
  }

  void _sendEvent(RoomEvent event) {
    final raw = jsonEncode(event.toJson());
    if (_socket != null && _socket!.readyState == WebSocket.open) {
      _socket!.add(raw);
    }
    for (var s in _localClientSockets) {
      if (s.readyState == WebSocket.open) {
        s.add(raw);
      }
    }
  }

  void _onRawMessage(dynamic data) {
    try {
      final json = jsonDecode(data.toString()) as Map<String, dynamic>;
      final event = RoomEvent.fromJson(json);
      _handleIncomingEvent(event);
    } catch (_) {}
  }

  void _handleIncomingEvent(RoomEvent event) {
    if (event.type == 'PING') {
      if (isHost && _currentRoom != null) {
        final player = _currentRoom!.players.cast<NetworkPlayer?>().firstWhere(
          (p) => p?.id == event.senderId,
          orElse: () => null,
        );
        if (player != null) {
          player.lastSeen = DateTime.now();
          player.isAfk = false;
        }
      }
      return;
    }

    if (event.type == 'KICK') {
      final targetId = event.payload['targetId'] as String?;
      if (targetId == _myPlayerId) {
        leaveRoom();
        onKicked?.call("Oda kurucusu tarafından odadan çıkarıldınız. (10 dk ban)");
      }
      return;
    }

    if (event.type == 'GIFT_VIP') {
      final giverName = event.payload['giverName']?.toString() ?? 'Player';
      final targetId = event.payload['targetId']?.toString() ?? '';
      final targetName = event.payload['targetName']?.toString() ?? 'Player';
      final isLifetime = event.payload['isLifetime'] as bool? ?? true;
      if (targetId == _myPlayerId) {
        _myIsVip = true;
      }
      if (isHost && _currentRoom != null) {
        for (var p in _currentRoom!.players) {
          if (p.id == targetId) {
            p.isVip = true;
          }
        }
        _broadcastSync();
      }
      onVipGifted?.call(giverName, targetId, targetName, isLifetime);
      return;
    }

    if (isHost) {
      // Host handles client incoming requests
      switch (event.type) {
        case 'JOIN':
          _handleJoinRequest(event);
          break;
        case 'LEAVE':
          _handleLeaveRequest(event);
          break;
        case 'UPDATE_EMOJI':
          if (_currentRoom != null) {
            final newEmoji = event.payload['emoji']?.toString() ?? '🥳';
            for (var p in _currentRoom!.players) {
              if (p.id == event.senderId) {
                p.emoji = newEmoji;
              }
            }
            _broadcastSync();
          }
          break;
        case 'SPIN':
          _handleSpinEvent(event);
          break;
        case 'SPIN_RESULT':
          _handleSpinResult(event);
          break;
        case 'PUBLISH_CARD':
          _handlePublishCardEvent(event);
          break;
        case 'CHOOSE':
          _handleChooseEvent(event);
          break;
        case 'DONE':
          _handleDoneEvent(event);
          break;
        case 'PAUSE':
          _handlePlayerPause(event.senderId, true);
          break;
        case 'RESUME':
          _handlePlayerPause(event.senderId, false);
          break;
      }
    } else {
      // Client handles state synchronization from Host
      if (event.type == 'SYNC') {
        final stateJson = event.payload['state'] as Map<String, dynamic>?;
        if (stateJson != null) {
          _currentRoom = RoomState.fromJson(stateJson);
          _emitState();
        }
      }
    }
  }

  // =========================================================================
  // HOST DISPATCH LOGIC
  // =========================================================================
  void _handleJoinRequest(RoomEvent event) {
    if (_currentRoom == null) return;
    final pin = event.payload['pin']?.toString().trim();
    if (pin != _currentRoom!.pin) {
      // Wrong PIN
      return;
    }

    // Check ban
    final now = DateTime.now().millisecondsSinceEpoch;
    final banExpire = _currentRoom!.bannedPlayers[event.senderId];
    if (banExpire != null && banExpire > now) {
      // Player is banned for 10 minutes
      return;
    }

    final name = event.payload['name']?.toString() ?? 'Player';
    final colorIdx = event.payload['colorIndex'] as int? ?? 0;
    final emoji = event.payload['emoji']?.toString() ?? '🥳';
    final isVip = event.payload['isVip'] as bool? ?? false;

    // Check if player already in list (reconnect)
    final existingIndex =
        _currentRoom!.players.indexWhere((p) => p.id == event.senderId);
    if (existingIndex >= 0) {
      _currentRoom!.players[existingIndex].name = name;
      _currentRoom!.players[existingIndex].colorIndex = colorIdx;
      _currentRoom!.players[existingIndex].emoji = emoji;
      _currentRoom!.players[existingIndex].isVip = isVip;
      _currentRoom!.players[existingIndex].isAfk = false;
      _currentRoom!.players[existingIndex].lastSeen = DateTime.now();
    } else {
      if (_currentRoom!.players.length >= 10) return; // Max 10 players
      _currentRoom!.players.add(NetworkPlayer(
        id: event.senderId,
        name: name,
        colorIndex: colorIdx,
        emoji: emoji,
        isHost: false,
        isVip: isVip,
      ));
    }

    _broadcastSync();
  }

  void _handleLeaveRequest(RoomEvent event) {
    if (_currentRoom == null) return;
    _currentRoom!.players.removeWhere((p) => p.id == event.senderId);

    // Host Migration: If host left, assign 2nd player as new host!
    if (event.senderId == _currentRoom!.hostId && _currentRoom!.players.isNotEmpty) {
      _currentRoom!.players[0].isHost = true;
      _currentRoom!.hostId = _currentRoom!.players[0].id;

      // Check VIP status of new host
      if (!_currentRoom!.isVipRoom) {
        if (_currentRoom!.selectedObjectIndex == 4) {
          _currentRoom!.selectedObjectIndex = 0;
        }
        if (_currentRoom!.selectedPacks.length > 4) {
          _currentRoom!.selectedPacks[4] = false;
        }
      }
      onToast?.call("${_currentRoom!.players[0].name} yeni oda kurucusu oldu! 👑");
    }

    _broadcastSync();
  }

  void _handleSpinEvent(RoomEvent event) {
    if (_currentRoom == null) return;
    _turnTimer?.cancel();

    _currentRoom!.status = RoomStatus.spinning;
    _currentRoom!.currentAngle = (event.payload['startAngle'] as num).toDouble();
    _currentRoom!.targetAngle = (event.payload['targetAngle'] as num).toDouble();
    _currentRoom!.bendVariant = event.payload['bendVariant']?.toString() ?? "0";
    _currentRoom!.answererIndex = event.payload['answererIndex'] as int? ?? -1;
    _currentRoom!.questionerIndex = event.payload['questionerIndex'] as int? ?? -1;
    _currentRoom!.activeMode = null;
    _currentRoom!.activePromptOverride = null;

    _currentRoom!.spinCounter++;
    _broadcastSync();

    // After 3.5s spin animation, transition to decisionPending
    Timer(const Duration(milliseconds: 3500), () {
      if (_currentRoom != null && _currentRoom!.status == RoomStatus.spinning) {
        _currentRoom!.status = RoomStatus.decisionPending;
        _broadcastSync();
        _startTurnTimer(); // 30-second response countdown
      }
    });
  }

  void _handleSpinResult(RoomEvent event) {
    if (_currentRoom == null) return;
    _currentRoom!.status = RoomStatus.decisionPending;
    _currentRoom!.currentAngle = (event.payload['angle'] as num).toDouble();
    _currentRoom!.targetAngle = (event.payload['angle'] as num).toDouble();
    _currentRoom!.bendVariant = event.payload['bendVariant']?.toString() ?? "0";
    _currentRoom!.answererIndex = event.payload['answererIndex'] as int? ?? 0;
    _currentRoom!.questionerIndex = event.payload['questionerIndex'] as int? ?? 0;
    _currentRoom!.activeMode = null;
    _currentRoom!.activePromptOverride = null;
    _broadcastSync();
    _startTurnTimer();
  }

  void _handleChooseEvent(RoomEvent event) {
    if (_currentRoom == null) return;
    final mode = event.payload['mode']?.toString() ?? 'TRUTH';
    _currentRoom!.activeMode = mode;
    _broadcastSync();
  }

  void _handlePublishCardEvent(RoomEvent event) {
    if (_currentRoom == null) return;
    final mode = event.payload['mode']?.toString() ?? 'TRUTH';
    final packIndex = event.payload['packIndex'] as int?;
    final questionIndex = event.payload['questionIndex'] as int?;
    final promptOverride = event.payload['promptOverride'] as String?;
    final answererIndex = event.payload['answererIndex'] as int?;
    final questionerIndex = event.payload['questionerIndex'] as int?;

    _currentRoom!.status = RoomStatus.cardOpen;
    _currentRoom!.activeMode = mode;
    _currentRoom!.activePackIndex = packIndex;
    _currentRoom!.activeQuestionIndex = questionIndex;
    _currentRoom!.activePromptOverride = promptOverride;
    if (answererIndex != null && answererIndex >= 0) {
      _currentRoom!.answererIndex = answererIndex;
    }
    if (questionerIndex != null && questionerIndex >= 0) {
      _currentRoom!.questionerIndex = questionerIndex;
    }

    _broadcastSync();
    _startTurnTimer(); // 30-second response countdown
  }

  void _handleDoneEvent(RoomEvent event) {
    if (_currentRoom == null) return;
    _turnTimer?.cancel();

    final tookPenalty = event.payload['penalty'] as bool? ?? false;
    if (_currentRoom!.answererIndex >= 0 &&
        _currentRoom!.answererIndex < _currentRoom!.players.length) {
      if (tookPenalty) {
        _currentRoom!.players[_currentRoom!.answererIndex].penaltiesTaken++;
      } else {
        _currentRoom!.players[_currentRoom!.answererIndex].completedTasks++;
      }
    }

    // Check for ad break every 5 spins
    if (_currentRoom!.spinCounter > 0 && _currentRoom!.spinCounter % 5 == 0) {
      _currentRoom!.status = RoomStatus.adBreak;
      _broadcastSync();

      // Resume back to ready after 6-second synchronized ad break
      Timer(const Duration(seconds: 6), () {
        if (_currentRoom != null && _currentRoom!.status == RoomStatus.adBreak) {
          _currentRoom!.status = RoomStatus.decisionPending;
          _currentRoom!.activeMode = null;
          _currentRoom!.activePromptOverride = null;
          _broadcastSync();
        }
      });
    } else {
      _currentRoom!.status = RoomStatus.decisionPending;
      _currentRoom!.activeMode = null;
      _currentRoom!.activePromptOverride = null;
      _broadcastSync();
    }
  }

  void _handlePlayerPause(String playerId, bool isPaused) {
    if (_currentRoom == null) return;
    final player = _currentRoom!.players.cast<NetworkPlayer?>().firstWhere(
      (p) => p?.id == playerId,
      orElse: () => null,
    );
    if (player != null) {
      player.isAfk = isPaused;
      _broadcastSync();
    }
  }

  void _startTurnTimer() {
    _turnTimer?.cancel();
    // 30 seconds response countdown
    _turnTimer = Timer(const Duration(seconds: 30), () {
      if (_currentRoom != null &&
          (_currentRoom!.status == RoomStatus.decisionPending ||
              _currentRoom!.status == RoomStatus.cardOpen)) {
        // Player timed out! Apply penalty and proceed
        onToast?.call("30 saniye doldu! Grubun verdiği cezayı çekme vakti! 💀");
        _handleDoneEvent(RoomEvent(
          type: 'DONE',
          senderId: isHost ? _myPlayerId : '',
          payload: {'penalty': true},
        ));
      }
    });
  }

  void _startHostWatchdog() {
    // Check every 30s for players inactive > 3 minutes (grace period)
    Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_currentRoom == null || !isHost) {
        timer.cancel();
        return;
      }
      final now = DateTime.now();
      final expired = <String>[];
      for (var p in _currentRoom!.players) {
        if (p.id != _myPlayerId && now.difference(p.lastSeen).inMinutes >= 3) {
          expired.add(p.id);
        }
      }
      if (expired.isNotEmpty) {
        _currentRoom!.players.removeWhere((p) => expired.contains(p.id));
        _broadcastSync();
      }
    });
  }

  void _broadcastSync() {
    if (_currentRoom == null || !isHost) return;
    _sendEvent(RoomEvent(
      type: 'SYNC',
      senderId: _myPlayerId,
      payload: {'state': _currentRoom!.toJson()},
    ));
    _emitState();
  }

  void _emitState() {
    if (_currentRoom != null) {
      _roomStateController.add(_currentRoom!);
    }
  }

  void _onSocketError(dynamic err) {
    // Keep local room alive during transient reconnects
  }

  void _onSocketDone() {
    // Attempt reconnect if still in room
    if (_currentRoom != null) {
      Timer(const Duration(seconds: 2), () {
        if (_currentRoom != null) {
          _connectSocket(_currentRoom!.roomCode);
        }
      });
    }
  }
}
