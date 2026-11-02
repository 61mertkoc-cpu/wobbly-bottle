import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/room_models.dart';
import '../services/room_service.dart';

class RoomLobbyScreen extends StatefulWidget {
  final bool isVip;
  final int currentLangIndex;
  final Function(String en, String tr, String de, String es, String fr) loc;
  final VoidCallback onStartGame;
  final VoidCallback onLeaveRoom;

  const RoomLobbyScreen({
    super.key,
    required this.isVip,
    required this.currentLangIndex,
    required this.loc,
    required this.onStartGame,
    required this.onLeaveRoom,
  });

  @override
  State<RoomLobbyScreen> createState() => _RoomLobbyScreenState();
}

class _RoomLobbyScreenState extends State<RoomLobbyScreen> {
  final RoomService _roomService = RoomService();

  String _t(String en, String tr, String de, String es, String fr) {
    return widget.loc(en, tr, de, es, fr);
  }

  void _copyRoomDetails(RoomState state) {
    final text = _t(
      "Join my Wobbly Bottle party! 🍾\nRoom Code: #${state.roomCode}\nPIN: ${state.pin}",
      "Wobbly Bottle partime katıl! 🍾\nOda Kodu: #${state.roomCode}\nŞifre: ${state.pin}",
      "Komm zu meiner Wobbly Bottle Party! 🍾\nRaumcode: #${state.roomCode}\nPIN: ${state.pin}",
      "¡Únete a mi fiesta de Wobbly Bottle! 🍾\nCódigo de sala: #${state.roomCode}\nPIN: ${state.pin}",
      "Rejoins ma soirée Wobbly Bottle ! 🍾\nCode de salle : #${state.roomCode}\nPIN : ${state.pin}",
    );
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_t("Room code & PIN copied to clipboard! 📋", "Oda kodu ve şifre kopyalandı! 📋", "Raumcode kopiert! 📋", "¡Código copiado! 📋", "Code copié ! 📋")),
        backgroundColor: const Color(0xFF00F2FE),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _confirmKick(NetworkPlayer player) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFFF0844), width: 2),
        ),
        title: Text(
          _t("Kick Player?", "Oyuncuyu At?", "Spieler kicken?", "¿Expulsar jugador?", "Expulser le joueur ?"),
          style: const TextStyle(color: Color(0xFFFF0844), fontWeight: FontWeight.bold),
        ),
        content: Text(
          _t(
            "Do you want to kick ${player.name}? They will be banned for 10 minutes.",
            "${player.name} adlı oyuncuyu odadan atmak istiyor musunuz? 10 dakika boyunca bu odaya tekrar giremeyecek.",
            "Möchtest du ${player.name} kicken? 10 Minuten gesperrt.",
            "¿Quieres expulsar a ${player.name}? Estará bloqueado por 10 minutos.",
            "Voulez-vous expulser ${player.name} ? Il sera banni pendant 10 minutes.",
          ),
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(_t("Cancel", "İptal", "Abbrechen", "Cancelar", "Annuler"), style: const TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF0844)),
            onPressed: () {
              Navigator.pop(ctx);
              _roomService.kickPlayer(player.id);
            },
            child: Text(_t("Kick", "At", "Kicken", "Expulsar", "Expulser"), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<RoomState>(
      stream: _roomService.roomStateStream,
      initialData: _roomService.currentRoom,
      builder: (context, snapshot) {
        final state = snapshot.data ?? _roomService.currentRoom;
        if (state == null) {
          return const Scaffold(
            backgroundColor: Color(0xFF030712),
            body: Center(child: CircularProgressIndicator(color: Color(0xFF00F2FE))),
          );
        }

        final isHost = _roomService.isHost;

        return Scaffold(
          backgroundColor: const Color(0xFF030712),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Row: Back / Leave + Room Code Banner
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.exit_to_app, color: Color(0xFFFF0844), size: 28),
                        onPressed: widget.onLeaveRoom,
                      ),
                      GestureDetector(
                        onTap: () => _copyRoomDetails(state),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF00F2FE), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00F2FE).withValues(alpha: 0.3),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Text(
                                "#${state.roomCode}",
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF00F2FE),
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFCC00),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  "PIN: ${state.pin}",
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.copy, color: Colors.white70, size: 16),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 48), // Balance spacing
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Mode Tag Badge
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: state.mode == WobblyGameMode.party
                            ? const Color(0xFFFFCC00).withValues(alpha: 0.2)
                            : const Color(0xFFFF0844).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: state.mode == WobblyGameMode.party
                              ? const Color(0xFFFFCC00)
                              : const Color(0xFFFF0844),
                        ),
                      ),
                      child: Text(
                        state.mode == WobblyGameMode.party
                            ? _t("🍻 HOUSE PARTY (IN-PERSON)", "🍻 EV PARTİSİ (AYNI ODADAYIZ)", "🍻 HAUSPARTY (VOR ORT)", "🍻 FIESTA EN CASA", "🍻 SOIRÉE MAISON")
                            : _t("🌍 REMOTE PARTY (ONLINE)", "🌍 UZAKTAN MOD (ONLINE)", "🌍 ONLINE-PARTY", "🌍 FIESTA A DISTANCIA", "🌍 SOIRÉE EN LIGNE"),
                        style: TextStyle(
                          color: state.mode == WobblyGameMode.party ? const Color(0xFFFFCC00) : const Color(0xFFFF0844),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // VIP Perk Banner if room is VIP
                  if (state.isVipRoom)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2A1B00), Color(0xFF1E112A)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFFCC00), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFCC00).withValues(alpha: 0.3),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Text("👑", style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _t("VIP ROOM: +18 Spicy & Champagne Unlocked for All!",
                                 "VIP ODA: +18 Baharatlı ve Şampanya Herkese Açık!",
                                 "VIP-RAUM: +18 Scharf & Champagner für alle!",
                                 "¡SALA VIP: +18 Picante y Champán para todos!",
                                 "SALLE VIP : +18 Épicé et Champagne pour tous !"),
                              style: const TextStyle(color: Color(0xFFFFCC00), fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Player Count Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _t("PLAYERS (${state.players.length}/10)",
                           "OYUNCULAR (${state.players.length}/10)",
                           "SPIELER (${state.players.length}/10)",
                           "JUGADORES (${state.players.length}/10)",
                           "JOUEURS (${state.players.length}/10)"),
                        style: const TextStyle(
                          color: Color(0xFF00F2FE),
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          letterSpacing: 1.2,
                        ),
                      ),
                      if (isHost)
                        Text(
                          _t("YOU ARE HOST 👑", "SEN ODA KURUCUSUSUN 👑", "DU BIST HOST 👑", "ERES EL ANFITRIÓN 👑", "VOUS ÊTES L'HÔTE 👑"),
                          style: const TextStyle(
                            color: Color(0xFFFFCC00),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Connected Players List
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: state.players.length,
                      itemBuilder: (ctx, idx) {
                        final p = state.players[idx];
                        final isMe = p.id == _roomService.myPlayerId;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: p.color.withValues(alpha: 0.6),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Avatar circle with color + VIP / Host Crown
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: p.color,
                                      boxShadow: [
                                        BoxShadow(
                                          color: p.color.withValues(alpha: 0.6),
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Golden VIP or Host Crown floating above avatar!
                                  if (p.isVip || p.isHost)
                                    Positioned(
                                      top: -12,
                                      left: 0,
                                      right: 0,
                                      child: Center(
                                        child: Text(
                                          p.isHost ? "👑" : "✨",
                                          style: const TextStyle(fontSize: 15),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 14),

                              // Name + badges
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          p.name,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 16,
                                            shadows: isMe
                                                ? [
                                                    Shadow(
                                                      color: p.color.withValues(alpha: 0.8),
                                                      blurRadius: 10,
                                                    )
                                                  ]
                                                : null,
                                          ),
                                        ),
                                        if (isMe)
                                          Padding(
                                            padding: const EdgeInsets.only(left: 6.0),
                                            child: Text(
                                              _t("(You)", "(Sen)", "(Du)", "(Tú)", "(Toi)"),
                                              style: TextStyle(
                                                color: p.color,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        if (p.isHost)
                                          Container(
                                            margin: const EdgeInsets.only(right: 6),
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFFCC00).withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: const Color(0xFFFFCC00), width: 0.8),
                                            ),
                                            child: const Text("HOST", style: TextStyle(color: Color(0xFFFFCC00), fontSize: 9, fontWeight: FontWeight.bold)),
                                          ),
                                        if (p.isVip)
                                          Container(
                                            margin: const EdgeInsets.only(right: 6),
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFF2E93).withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: const Color(0xFFFF2E93), width: 0.8),
                                            ),
                                            child: const Text("VIP 👑", style: TextStyle(color: Color(0xFFFF2E93), fontSize: 9, fontWeight: FontWeight.bold)),
                                          ),
                                        if (p.isAfk)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(_t("In Background", "Arka Planda", "Hintergrund", "En segundo plano", "En arrière-plan"), style: const TextStyle(color: Colors.orangeAccent, fontSize: 9)),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Kick button (Host only, cannot kick self)
                              if (isHost && !isMe)
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: Color(0xFFFF0844), size: 22),
                                  onPressed: () => _confirmKick(p),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // Bottom Action: Start Game (Host) or Waiting Animation (Client)
                  if (isHost)
                    ElevatedButton(
                      onPressed: state.players.length >= 2 ? widget.onStartGame : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00F2FE),
                        disabledBackgroundColor: Colors.white12,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        elevation: 8,
                        shadowColor: const Color(0xFF00F2FE).withValues(alpha: 0.5),
                      ),
                      child: Text(
                        state.players.length >= 2
                            ? _t("START GAME 🚀", "OYUNU BAŞLAT 🚀", "SPIEL STARTEN 🚀", "INICIAR JUEGO 🚀", "COMMENCER LE JEU 🚀")
                            : _t("WAITING FOR PLAYERS (MIN 2)...", "OYUNCU BEKLENİYOR (MİN 2)...", "WARTE AUF SPIELER (MIN 2)...", "ESPERANDO JUGADORES (MIN 2)...", "EN ATTENTE DE JOUEURS (MIN 2)..."),
                        style: TextStyle(
                          color: state.players.length >= 2 ? Colors.black : Colors.white38,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFF00F2FE).withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(color: Color(0xFF00F2FE), strokeWidth: 2.5),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _t("Waiting for host to start... ⏳", "Oda kurucusunun başlatması bekleniyor... ⏳", "Warte auf Spielleiter... ⏳", "Esperando al anfitrión... ⏳", "En attente de l'hôte... ⏳"),
                            style: const TextStyle(color: Color(0xFF00F2FE), fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
