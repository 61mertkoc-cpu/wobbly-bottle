import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/room_models.dart';
import '../services/room_service.dart';

class RoomLobbyScreen extends StatefulWidget {
  final bool isVip;
  final int currentLangIndex;
  final Function(String en, String tr, String de, String es, String fr, [String? ru]) loc;
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

  String _t(String en, String tr, String de, String es, String fr, [String? ru]) {
    return widget.loc(en, tr, de, es, fr, ru);
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
        content: Text(_t("Room code & PIN copied! 📋", "Oda kodu ve şifre kopyalandı! 📋", "Raumcode kopiert! 📋", "¡Código copiado! 📋", "Code copié ! 📋")),
        backgroundColor: const Color(0xFF00F2FE),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showPlayerActionSheet(NetworkPlayer player) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: player.color.withValues(alpha: 0.8), width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  backgroundColor: player.color,
                  radius: 16,
                  child: Text(
                    player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  player.name,
                  style: TextStyle(
                    color: player.color,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Option 1: Transfer Host
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFCC00).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text("👑", style: TextStyle(fontSize: 20)),
              ),
              title: Text(
                _t("Transfer Host Role", "Host Yetkisini Devret", "Host-Rechte übertragen", "Transferir anfitrión", "Transférer le rôle d'hôte"),
                style: const TextStyle(color: Color(0xFFFFCC00), fontWeight: FontWeight.w900),
              ),
              subtitle: Text(
                _t("Make this player the room admin", "Bu oyuncuyu odanın kurucusu yap", "Diesen Spieler zum Host machen", "Hacer anfitrión a este jugador", "Rendre ce joueur hôte"),
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _confirmTransferHost(player);
              },
            ),

            const Divider(color: Colors.white12),

            // Option 2: Kick Player
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF0844).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.remove_circle, color: Color(0xFFFF0844), size: 24),
              ),
              title: Text(
                _t("Kick from Room (10 Min)", "Odadan At (10 Dk)", "Aus Raum kicken (10 Min)", "Expulsar de la sala (10 min)", "Expulser de la salle (10 min)"),
                style: const TextStyle(color: Color(0xFFFF0844), fontWeight: FontWeight.w900),
              ),
              subtitle: Text(
                _t("Ban for 10 minutes from this room", "10 dakika boyunca bu odaya giremez", "10 Minuten für diesen Raum sperren", "Bloquear durante 10 minutos", "Bannir pendant 10 minutes"),
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _confirmKick(player);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmTransferHost(NetworkPlayer player) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFFFCC00), width: 2),
        ),
        title: Text(
          _t("Transfer Host?", "Host Yetkisini Devret?", "Host übertragen?", "¿Transferir anfitrión?", "Transférer l'hôte ?"),
          style: const TextStyle(color: Color(0xFFFFCC00), fontWeight: FontWeight.bold),
        ),
        content: Text(
          _t(
            "Are you sure you want to transfer host privileges to ${player.name}? You will become a regular player.",
            "Host yetkisini ${player.name} adlı oyuncuya devretmek istediğinize emin misiniz? Siz normal oyuncu olacaksınız.",
            "Möchtest du die Host-Rechte an ${player.name} übertragen? Du wirst normaler Spieler.",
            "¿Seguro que quieres transferir el anfitrión a ${player.name}? Serás jugador normal.",
            "Êtes-vous sûr de vouloir transférer l'hôte à ${player.name} ? Vous deviendrez un joueur ordinaire.",
          ),
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(_t("Cancel", "İptal", "Abbrechen", "Cancelar", "Annuler"), style: const TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFCC00), foregroundColor: Colors.black),
            onPressed: () {
              Navigator.pop(ctx);
              _roomService.transferHost(player.id);
            },
            child: Text(_t("Yes, Transfer", "Evet, Devret", "Ja, übertragen", "Sí, transferir", "Oui, transférer"), style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
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
            "Are you sure you want to kick ${player.name}? They will be banned for 10 minutes.",
            "${player.name} adlı oyuncuyu odadan atmak istediğinize emin misiniz? 10 dakika boyunca bu odaya tekrar giremeyecek.",
            "Möchtest du ${player.name} kicken? 10 Minuten gesperrt.",
            "¿Seguro que quieres expulsar a ${player.name}? 10 minutos de bloqueo.",
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
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF0844), foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              _roomService.kickPlayer(player.id);
            },
            child: Text(_t("Kick", "At", "Kicken", "Expulsar", "Expulser"), style: const TextStyle(fontWeight: FontWeight.bold)),
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
          body: Stack(
            children: [
              // Vibrant game background
              Positioned.fill(
                child: Image.asset(
                  'assets/game_bg.png',
                  fit: BoxFit.cover,
                ),
              ),
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.82),
                ),
              ),

              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top Row: Exit Button + Neon Wobbly Bottle Logo + Balance
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: widget.onLeaveRoom,
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFFF0844), width: 1.5),
                              ),
                              child: const Icon(Icons.arrow_back_ios_new, color: Color(0xFFFF0844), size: 20),
                            ),
                          ),
                          Image.asset(
                            'assets/wobbly_logo.png',
                            height: 56,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 42),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Mode Tag Badge
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: state.mode == WobblyGameMode.party
                                ? const Color(0xFFFFCC00).withValues(alpha: 0.18)
                                : const Color(0xFFFF0844).withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: state.mode == WobblyGameMode.party
                                  ? const Color(0xFFFFCC00)
                                  : const Color(0xFFFF0844),
                              width: 1.2,
                            ),
                          ),
                          child: Text(
                            state.mode == WobblyGameMode.party
                                ? _t("🍻 HOUSE PARTY (IN-PERSON)", "🍻 EV PARTİSİ (AYNI ODADAYIZ)", "🍻 HAUSPARTY (VOR ORT)", "🍻 FIESTA EN CASA", "🍻 SOIRÉE MAISON")
                                : _t("🌍 REMOTE PARTY (ONLINE)", "🌍 UZAKTAN MOD (ONLINE)", "🌍 ONLINE-PARTY", "🌍 FIESTA A DISTANCIA", "🌍 SOIRÉE EN LIGNE"),
                            style: TextStyle(
                              color: state.mode == WobblyGameMode.party ? const Color(0xFFFFCC00) : const Color(0xFFFF0844),
                              fontWeight: FontWeight.bold,
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Room Info Bar: Room Code on Left + PIN on Right (Tap to Copy)
                      GestureDetector(
                        onTap: () => _copyRoomDetails(state),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A1828),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFF00F2FE), width: 1.8),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00F2FE).withValues(alpha: 0.25),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Room Code
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00F2FE).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFF00F2FE), width: 1),
                                ),
                                child: Text(
                                  "#${state.roomCode}",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF00F2FE),
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                              const Spacer(),

                              // PIN Box
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFCC00),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.lock, size: 14, color: Colors.black),
                                    const SizedBox(width: 4),
                                    Text(
                                      "PIN: ${state.pin}",
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.copy, color: Color(0xFF00F2FE), size: 18),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

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
                              fontSize: 13.5,
                              letterSpacing: 1.2,
                            ),
                          ),
                          if (isHost)
                            Text(
                              _t("YOU ARE HOST", "SEN ODA KURUCUSUSUN", "DU BIST HOST", "ERES EL ANFITRIÓN", "VOUS ÊTES L'HÔTE"),
                              style: const TextStyle(
                                color: Color(0xFFFFCC00),
                                fontWeight: FontWeight.w900,
                                fontSize: 11.5,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Connected Players in 2-Column Grid matching Single-Phone Setup Screen
                      Expanded(
                        child: GridView.builder(
                          physics: const BouncingScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 2.15,
                          ),
                          itemCount: state.players.length,
                          itemBuilder: (ctx, idx) {
                            final p = state.players[idx];
                            final isMe = p.id == _roomService.myPlayerId;

                            // Badge calculation:
                            // Crown is strictly for VIP.
                            // Badges: VIP HOST, HOST, VIP.
                            String? badgeText;
                            Color badgeColor = const Color(0xFF00F2FE);

                            if (p.isHost && p.isVip) {
                              badgeText = "VIP HOST";
                              badgeColor = const Color(0xFFFFCC00);
                            } else if (p.isHost) {
                              badgeText = "HOST";
                              badgeColor = const Color(0xFF00F2FE);
                            } else if (p.isVip) {
                              badgeText = "VIP";
                              badgeColor = const Color(0xFFFFCC00);
                            }

                            return GestureDetector(
                              onTap: () {
                                if (isHost && !isMe) {
                                  _showPlayerActionSheet(p);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0A1828),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: p.color,
                                    width: isMe ? 2.5 : 1.8,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: p.color.withValues(alpha: 0.25),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    // Avatar circle with color + VIP Crown (Crown ONLY for VIP!)
                                    Stack(
                                      clipBehavior: Clip.none,
                                      alignment: Alignment.center,
                                      children: [
                                        Container(
                                          width: 38,
                                          height: 38,
                                          decoration: BoxDecoration(
                                            color: p.color.withValues(alpha: 0.25),
                                            shape: BoxShape.circle,
                                            border: Border.all(color: p.color, width: 2),
                                          ),
                                          child: Center(
                                            child: Text(
                                              p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                                              style: TextStyle(
                                                color: p.color,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        // CROWN: ONLY FOR VIP (Host does NOT get crown unless VIP)
                                        if (p.isVip)
                                          const Positioned(
                                            top: -11,
                                            child: Text("👑", style: TextStyle(fontSize: 13)),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(width: 8),

                                    // Name + Badge Row
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            isMe ? "${p.name} (${_t('You', 'Sen', 'Du', 'Tú', 'Toi')})" : p.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Row(
                                            children: [
                                              if (badgeText != null)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                  decoration: BoxDecoration(
                                                    color: badgeColor.withValues(alpha: 0.2),
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(color: badgeColor, width: 0.8),
                                                  ),
                                                  child: Text(
                                                    badgeText,
                                                    style: TextStyle(
                                                      color: badgeColor,
                                                      fontSize: 8.5,
                                                      fontWeight: FontWeight.w900,
                                                    ),
                                                  ),
                                                ),
                                              if (p.isAfk) ...[
                                                const SizedBox(width: 4),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                                  decoration: BoxDecoration(
                                                    color: Colors.orange.withValues(alpha: 0.2),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: const Text("AFK", style: TextStyle(color: Colors.orangeAccent, fontSize: 8)),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Host indicator dots / icon if host can manage player
                                    if (isHost && !isMe)
                                      Icon(Icons.more_vert, color: Colors.white.withValues(alpha: 0.5), size: 16),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Bottom Action Button:
                      // Host: "NESNELERE DEVAM ET ➔" (navigates to Objects screen)
                      // Client: "KURUCU OYUNU BAŞLATACAK... ⏳"
                      if (isHost)
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: state.players.length >= 2
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF00F2FE).withValues(alpha: 0.35),
                                      blurRadius: 12,
                                    ),
                                  ]
                                : null,
                          ),
                          child: ElevatedButton(
                            onPressed: state.players.length >= 2 ? widget.onStartGame : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00F2FE),
                              disabledBackgroundColor: Colors.white12,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            ),
                            child: Text(
                              state.players.length >= 2
                                  ? _t("CONTINUE TO OBJECTS ➔", "NESNELERE DEVAM ET ➔", "WEITER ZU OBJEKTEN ➔", "CONTINUAR A OBJETOS ➔", "CONTINUER AUX OBJETS ➔")
                                  : _t("WAITING FOR PLAYERS (MIN 2)...", "OYUNCU BEKLENİYOR (MİN 2)...", "WARTE AUF SPIELER (MIN 2)...", "ESPERANDO JUGADORES (MIN 2)...", "EN ATTENTE DE JOUEURS (MIN 2)..."),
                              style: TextStyle(
                                color: state.players.length >= 2 ? Colors.black : Colors.white38,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A1828),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFF00F2FE).withValues(alpha: 0.5)),
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
                                _t("Waiting for host to proceed... ⏳", "Oda kurucusunun devam etmesi bekleniyor... ⏳", "Warte auf Spielleiter... ⏳", "Esperando al anfitrión... ⏳", "En attente de l'hôte... ⏳"),
                                style: const TextStyle(color: Color(0xFF00F2FE), fontWeight: FontWeight.bold, fontSize: 13.5),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
