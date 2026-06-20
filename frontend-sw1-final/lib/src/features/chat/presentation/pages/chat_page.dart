import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../core/services/chat_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/post_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../outfit/presentation/pages/outfit_history_page.dart';
import '../../../outfit/presentation/providers/outfit_history_provider.dart';
import '../../../subscription/presentation/pages/subscription_page.dart';
import '../../../subscription/presentation/providers/subscription_provider.dart';
import 'face_scan_page.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  ChatConversation? _conversation;
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isSharing = false;
  bool _isShared = false;
  bool _isSendingImage = false;

  // Audio recording state
  final _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  bool _isTranscribing = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;

  List<ChatConversation> _history = [];
  bool _isLoadingHistory = false;
  bool _hairstyleExpanded = false;
  String? _faceImagePath;

  late AnimationController _typingController;

  @override
  void initState() {
    super.initState();
    _typingController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
    _messageController.addListener(() {
      if (mounted) setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final sub = context.read<SubscriptionProvider>();
      await sub.loadStatus();
      if (!mounted) return;
      if (sub.isPremium) {
        _initConversation();
      } else {
        setState(() => _isLoading = false);
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingController.dispose();
    _audioRecorder.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  Future<void> _initConversation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await StorageService.getUser();
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      double? lat, lon;
      try {
        LocationPermission perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) {
          perm = await Geolocator.requestPermission();
        }
        if (perm == LocationPermission.whileInUse || perm == LocationPermission.always) {
          final pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
          ).timeout(const Duration(seconds: 5));
          lat = pos.latitude;
          lon = pos.longitude;
        }
      } catch (_) {
        // Si no hay ubicación, el backend usa el clima del perfil
      }

      final conversation = await ChatService.createConversation(user.id, lat: lat, lon: lon);
      if (!mounted) return;

      setState(() {
        _conversation = conversation;
        _messages = List.from(conversation.messages);
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _showError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> _sendMessage(String content) async {
    if (content.trim().isEmpty || _conversation == null || _isSending) return;

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content.trim(),
      role: 'USER',
      conversationId: _conversation!.id,
      createdAt: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isSending = true;
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      final updated =
          await ChatService.sendMessage(_conversation!.id, content.trim());
      if (!mounted) return;

      setState(() {
        _conversation = updated;
        _messages = List.from(updated.messages);
        _isSending = false;
        _isShared = false;
      });

      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
      });
      _showError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> _newConversation() async {
    setState(() {
      _conversation = null;
      _messages = [];
      _isSharing = false;
      _isShared = false;
    });
    await _initConversation();
  }

  Future<void> _loadHistory() async {
    if (_isLoadingHistory) return;

    setState(() {
      _isLoadingHistory = true;
    });

    try {
      final user = await StorageService.getUser();
      if (user == null) throw Exception('Usuario no autenticado');

      final conversations = await ChatService.getConversations(user.id);
      if (!mounted) return;

      setState(() {
        _history = conversations;
        _isLoadingHistory = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingHistory = false;
      });
      _showError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  void _loadConversation(ChatConversation conversation) {
    Navigator.of(context).pop(); // cerrar drawer
    setState(() {
      _conversation = conversation;
      _messages = List.from(conversation.messages);
      _isSharing = false;
      _isShared = false;
    });
    _scrollToBottom();
  }

  Future<void> _shareOutfit() async {
    final outfit = _conversation?.outfit;
    if (outfit == null || _isSharing) return;

    setState(() {
      _isSharing = true;
    });

    try {
      await PostService.createOutfitPost(outfit.id);
      if (!mounted) return;
      setState(() {
        _isShared = true;
        _isSharing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text('Outfit compartido en la comunidad'),
            ],
          ),
          backgroundColor: AppPalette.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSharing = false;
      });
      _showError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> _openFaceScan() async {
    final result = await Navigator.push<String?>(
      context,
      MaterialPageRoute(builder: (_) => const FaceScanPage()),
    );

    if (result != null && result.isNotEmpty && mounted) {
      await _sendFaceImage(File(result));
    }
  }

  // ── Audio recording ───────────────────────────────────────────────────────────

  Future<void> _startRecording() async {
    if (_conversation == null || _isSending) return;
    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      _showError('Permiso de micrófono denegado. Actívalo en la configuración del dispositivo.');
      return;
    }
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/chat_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _audioRecorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000, sampleRate: 44100),
      path: path,
    );
    setState(() {
      _isRecording = true;
      _recordingSeconds = 0;
    });
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _recordingSeconds++);
    });
  }

  Future<void> _stopAndSendRecording() async {
    _recordingTimer?.cancel();
    final path = await _audioRecorder.stop();
    setState(() => _isRecording = false);
    if (path == null || !mounted) return;
    await _sendAudioMessage(File(path));
  }

  Future<void> _cancelRecording() async {
    _recordingTimer?.cancel();
    await _audioRecorder.cancel();
    if (mounted) setState(() { _isRecording = false; _recordingSeconds = 0; });
  }

  Future<void> _sendAudioMessage(File audioFile) async {
    if (_conversation == null) return;
    setState(() => _isTranscribing = true);
    _scrollToBottom();
    try {
      final updated = await ChatService.sendAudio(_conversation!.id, audioFile);
      if (!mounted) return;
      setState(() {
        _conversation = updated;
        _messages = List.from(updated.messages);
        _isTranscribing = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isTranscribing = false);
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      // Borrar el archivo temporal
      try { audioFile.deleteSync(); } catch (_) {}
    }
  }

  Future<void> _sendFaceImage(File imageFile) async {
    if (_conversation == null || _isSendingImage) return;

    setState(() {
      _isSendingImage = true;
      _faceImagePath = imageFile.path;
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: '[Imagen de rostro enviada]',
        role: 'USER',
        conversationId: _conversation!.id,
        createdAt: DateTime.now(),
      ));
    });
    _scrollToBottom();

    try {
      final updated =
          await ChatService.sendFaceImage(_conversation!.id, imageFile);
      if (!mounted) return;

      setState(() {
        _conversation = updated;
        _messages = List.from(updated.messages);
        _isSendingImage = false;
      });

      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSendingImage = false;
      });
      _showError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppPalette.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool get _isAwaitingHairstyleChoice =>
      _conversation?.status == 'AWAITING_HAIRSTYLE_CHOICE';
  bool get _isAwaitingFaceImage =>
      _conversation?.status == 'AWAITING_FACE_IMAGE';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.aiAssistant),
        actions: [
          IconButton(
            icon: const Icon(Icons.style_outlined),
            tooltip: 'Mis outfits',
            onPressed: () {
              context.read<OutfitHistoryProvider>().load();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const OutfitHistoryPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              _loadHistory();
              _scaffoldKey.currentState?.openEndDrawer();
            },
            tooltip: 'Historial de chats',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading || _isSending ? null : _newConversation,
            tooltip: 'Nueva conversacion',
          ),
        ],
      ),
      endDrawer: _buildHistoryDrawer(),
      body: SafeArea(
        child: Builder(builder: (context) {
          final sub = context.watch<SubscriptionProvider>();
          if (sub.isLoadingStatus && _messages.isEmpty) {
            return _buildLoadingView();
          }
          if (!sub.isPremium) {
            return _buildPremiumGate();
          }
          if (_isLoading && _messages.isEmpty) {
            return _buildLoadingView();
          }
          return Column(
            children: [
              Expanded(child: _buildMessageList()),
              _buildChatInput(),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildHistoryDrawer() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AppPalette.gray700 : AppPalette.gray200,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: AppPalette.accentGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.history,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Historial de Chats',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading || _isSending
                          ? null
                          : () {
                              Navigator.of(context).pop();
                              _newConversation();
                            },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Nueva conversacion'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoadingHistory
                  ? const Center(child: CircularProgressIndicator())
                  : _history.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 48,
                                color: isDark
                                    ? AppPalette.gray600
                                    : AppPalette.gray300,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Sin conversaciones',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: isDark
                                      ? AppPalette.gray500
                                      : AppPalette.gray400,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _history.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                            color: isDark
                                ? AppPalette.gray700
                                : AppPalette.gray200,
                          ),
                          itemBuilder: (context, index) {
                            final conv = _history[index];
                            return _buildHistoryTile(conv);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTile(ChatConversation conv) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSelected = _conversation?.id == conv.id;
    final isCompleted = conv.status == 'COMPLETED';

    // Obtener preview del ultimo mensaje del asistente
    String preview = 'Sin mensajes';
    for (final msg in conv.messages.reversed) {
      if (msg.role == 'ASSISTANT') {
        preview = msg.content;
        break;
      }
    }
    if (preview.length > 80) {
      preview = '${preview.substring(0, 80)}...';
    }

    // Formatear fecha
    final now = DateTime.now();
    final diff = now.difference(conv.createdAt);
    String dateLabel;
    if (diff.inMinutes < 1) {
      dateLabel = 'Ahora';
    } else if (diff.inHours < 1) {
      dateLabel = 'Hace ${diff.inMinutes} min';
    } else if (diff.inDays < 1) {
      dateLabel = 'Hace ${diff.inHours}h';
    } else if (diff.inDays == 1) {
      dateLabel = 'Ayer';
    } else if (diff.inDays < 7) {
      dateLabel = 'Hace ${diff.inDays} dias';
    } else {
      dateLabel =
          '${conv.createdAt.day}/${conv.createdAt.month}/${conv.createdAt.year}';
    }

    return Material(
      color: isSelected
          ? (isDark
              ? AppPalette.accent.withOpacity(0.15)
              : AppPalette.accent.withOpacity(0.08))
          : Colors.transparent,
      child: InkWell(
        onTap: () => _loadConversation(conv),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppPalette.success.withOpacity(0.1)
                      : (isDark
                          ? AppPalette.gray700
                          : AppPalette.gray100),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isCompleted ? Icons.check_circle_outline : Icons.chat_bubble_outline,
                  size: 18,
                  color: isCompleted
                      ? AppPalette.success
                      : (isDark ? AppPalette.gray400 : AppPalette.gray500),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conv.event ?? 'Conversacion',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppPalette.gray100
                                  : AppPalette.gray800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          dateLabel,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            color: isDark
                                ? AppPalette.gray500
                                : AppPalette.gray400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      preview,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppPalette.gray400
                            : AppPalette.gray500,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (conv.outfit != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.checkroom,
                              size: 13, color: AppPalette.accent),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              conv.outfit!.name,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppPalette.accent,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumGate() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: AppPalette.accentGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome,
                  color: Colors.white, size: 40),
            ),
            const SizedBox(height: 24),
            Text(
              'Asistente IA Premium',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'El asistente de outfits con IA es una función exclusiva de StyleAI Premium. Generá looks personalizados sin límites.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const SubscriptionPage()),
                  );
                  if (!mounted) return;
                  final sub = context.read<SubscriptionProvider>();
                  await sub.loadStatus(force: true);
                  if (!mounted) return;
                  if (sub.isPremium) {
                    setState(() => _isLoading = true);
                    _initConversation();
                  }
                },
                icon: const Icon(Icons.workspace_premium),
                label: const Text('Obtener Premium'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppPalette.accentGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome,
              size: 36,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Iniciando asistente...',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 160,
            child: LinearProgressIndicator(
              backgroundColor: AppPalette.softGray.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(AppPalette.accent),
            ),
          ),
        ],
      ),
    );
  }

  // Devuelve el índice del mensaje ASSISTANT después del cual insertar el outfit card.
  // Busca el mensaje que menciona el nombre del outfit; si no, el último ASSISTANT.
  int _findOutfitAnchorIndex(ChatOutfit outfit) {
    for (int i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i].role == 'ASSISTANT' &&
          _messages[i].content.contains(outfit.name)) {
        return i;
      }
    }
    for (int i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i].role == 'ASSISTANT') return i;
    }
    return _messages.length - 1;
  }

  int _findHairstyleAnchorIndex() {
    for (int i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i].role == 'ASSISTANT' &&
          _messages[i].content.contains('Peinado recomendado')) {
        return i;
      }
    }
    for (int i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i].role == 'ASSISTANT') return i;
    }
    return _messages.length - 1;
  }

  Widget _buildMessageList() {
    final outfit = _conversation?.outfit;
    final hairstyle = _conversation?.recommendedHairstyle;

    final int outfitAnchor = outfit != null ? _findOutfitAnchorIndex(outfit) : -1;
    final int hairstyleAnchor = hairstyle != null ? _findHairstyleAnchorIndex() : -1;

    final List<Widget> items = [];
    for (int i = 0; i < _messages.length; i++) {
      items.add(_buildMessageBubble(_messages[i]));
      if (outfit != null && i == outfitAnchor) {
        items.add(_buildOutfitCard(outfit));
      }
      if (hairstyle != null && i == hairstyleAnchor) {
        items.add(_buildHairstyleCard(hairstyle));
      }
    }

    if (_isSending || _isSendingImage) {
      items.add(_buildTypingIndicator());
    }

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: items,
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.role == 'USER';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: AppPalette.accentGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? AppPalette.accent
                    : (isDark ? AppPalette.gray700 : AppPalette.gray100),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
              ),
              child: message.content == '[Imagen de rostro enviada]' && _faceImagePath != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            File(_faceImagePath!),
                            width: 160,
                            height: 160,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Foto de rostro enviada',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    )
                  : MarkdownBody(
                data: message.content,
                styleSheet: MarkdownStyleSheet(
                  p: theme.textTheme.bodyMedium?.copyWith(
                    color: isUser
                        ? Colors.white
                        : (isDark ? AppPalette.gray100 : AppPalette.gray800),
                    height: 1.4,
                  ),
                  strong: theme.textTheme.bodyMedium?.copyWith(
                    color: isUser
                        ? Colors.white
                        : (isDark ? AppPalette.gray100 : AppPalette.gray800),
                    fontWeight: FontWeight.bold,
                    height: 1.4,
                  ),
                  em: theme.textTheme.bodyMedium?.copyWith(
                    color: isUser
                        ? Colors.white
                        : (isDark ? AppPalette.gray100 : AppPalette.gray800),
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: AppPalette.accentGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.auto_awesome,
              size: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? AppPalette.gray700 : AppPalette.gray100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
            ),
            child: AnimatedBuilder(
              animation: _typingController,
              builder: (context, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final delay = i * 0.33;
                    final t = (_typingController.value + delay) % 1.0;
                    // Sine wave: always produces values in [0.3, 1.0]
                    final double opacity = 0.3 + 0.7 * ((1.0 + math.sin(t * 2.0 * math.pi)) / 2.0);
                    return Padding(
                      padding: EdgeInsets.only(right: i < 2 ? 4 : 0),
                      child: Opacity(
                        opacity: opacity,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppPalette.gray400
                                : AppPalette.gray500,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutfitCard(ChatOutfit outfit) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: AppPalette.accentGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.auto_awesome,
              size: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header del outfit
                    Row(
                      children: [
                        Icon(Icons.checkroom,
                            color: AppPalette.accent, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            outfit.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (outfit.score != null && outfit.score! > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppPalette.accent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star,
                                    size: 14, color: AppPalette.accent),
                                const SizedBox(width: 4),
                                Text(
                                  '${outfit.score}',
                                  style: TextStyle(
                                    color: AppPalette.accent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                    if (outfit.description != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        outfit.description!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? AppPalette.gray300
                              : AppPalette.gray600,
                        ),
                      ),
                    ],

                    // Prendas en scroll horizontal
                    if (outfit.garmentOutfits.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 140,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: outfit.garmentOutfits.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final go = outfit.garmentOutfits[index];
                            final garment = go.garment;
                            return _buildGarmentItem(garment, go.order);
                          },
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Boton compartir
                    if (!_isShared)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isSharing ? null : _shareOutfit,
                          icon: _isSharing
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.share, size: 18),
                          label: Text(
                            _isSharing
                                ? 'Compartiendo...'
                                : 'Compartir en Comunidad',
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: AppPalette.darkNavy,
                          ),
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppPalette.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppPalette.success.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle,
                                color: AppPalette.success, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Compartido en la comunidad',
                              style: TextStyle(
                                color: AppPalette.success,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGarmentItem(ChatGarment? garment, int order) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      width: 100,
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: 100,
                  decoration: BoxDecoration(
                    color: isDark ? AppPalette.gray700 : AppPalette.gray100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppPalette.gray600 : AppPalette.gray200,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: garment?.path != null
                      ? Image.network(
                          garment!.path!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Icon(
                              Icons.checkroom,
                              color: isDark
                                  ? AppPalette.gray500
                                  : AppPalette.gray400,
                              size: 28,
                            ),
                          ),
                        )
                      : Center(
                          child: Icon(
                            Icons.checkroom,
                            color: isDark
                                ? AppPalette.gray500
                                : AppPalette.gray400,
                            size: 28,
                          ),
                        ),
                ),
                Positioned(
                  top: 4,
                  left: 4,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AppPalette.accent,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$order',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            garment?.name ?? 'Prenda',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          if (garment?.category != null)
            Text(
              garment!.category!,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: isDark ? AppPalette.gray400 : AppPalette.gray500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  Widget _buildChatInput() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isAwaitingHairstyleChoice && !_isSending) return _buildHairstyleChoiceButtons(theme, isDark);
    if (_isAwaitingFaceImage && !_isSendingImage) return _buildFaceScanButton(theme, isDark);
    if (_isSendingImage) return _buildSendingImageIndicator(theme, isDark);
    if (_isRecording) return _buildRecordingPanel(theme, isDark);
    if (_isTranscribing) return _buildTranscribingPanel(theme, isDark);

    final canSend = !_isSending && _conversation != null;
    final hasText = _messageController.text.trim().isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (canSend && !_isSending) _buildQuickReplies(isDark),
        Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? (isDark ? AppPalette.gray800 : AppPalette.white),
        border: Border(
          top: BorderSide(color: isDark ? AppPalette.gray700 : AppPalette.gray200),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              enabled: canSend,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.send,
              onSubmitted: canSend ? _sendMessage : null,
              decoration: InputDecoration(
                hintText: _isSending ? '...' : AppLocalizations.of(context)!.typeMessage,
                filled: true,
                fillColor: isDark ? AppPalette.gray700 : AppPalette.gray100,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: AppPalette.accent, width: 1.5)),
                disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Send cuando hay texto, Mic cuando está vacío
          if (hasText)
            _buildSendButton(canSend, isDark)
          else
            _buildMicButton(canSend, isDark),
        ],
      ),
        ),
      ],
    );
  }

  Widget _buildQuickReplies(bool isDark) {
    final hasOutfit = _conversation?.outfit != null;
    final chips = hasOutfit
        ? ['Pedir otro outfit', 'Más formal', 'Más casual', 'Para mañana']
        : ['Para el trabajo', 'Para una fiesta', 'Para el gym', 'Para una cita'];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _sendMessage(chips[index]),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? AppPalette.gray700 : AppPalette.gray100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppPalette.gray600 : AppPalette.gray300,
                ),
              ),
              child: Text(
                chips[index],
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppPalette.gray200 : AppPalette.gray700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSendButton(bool canSend, bool isDark) {
    return Material(
      color: canSend ? AppPalette.accent : (isDark ? AppPalette.gray700 : AppPalette.gray300),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: canSend ? () => _sendMessage(_messageController.text) : null,
        child: Container(
          width: 44, height: 44, alignment: Alignment.center,
          child: Icon(
            Icons.send_rounded,
            color: canSend ? Colors.white : (isDark ? AppPalette.gray500 : AppPalette.gray400),
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildMicButton(bool canSend, bool isDark) {
    return Material(
      color: canSend
          ? AppPalette.accent.withValues(alpha: 0.12)
          : (isDark ? AppPalette.gray700 : AppPalette.gray200),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: canSend ? _startRecording : null,
        child: Container(
          width: 44, height: 44, alignment: Alignment.center,
          child: Icon(
            Icons.mic_none,
            color: canSend ? AppPalette.accent : (isDark ? AppPalette.gray500 : AppPalette.gray400),
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildRecordingPanel(ThemeData theme, bool isDark) {
    final mm = _recordingSeconds ~/ 60;
    final ss = _recordingSeconds % 60;
    final timeStr = '${mm.toString().padLeft(2, '0')}:${ss.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? (isDark ? AppPalette.gray800 : AppPalette.white),
        border: Border(top: BorderSide(color: isDark ? AppPalette.gray700 : AppPalette.gray200)),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _typingController,
            builder: (_, __) => Container(
              width: 12, height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color.lerp(Colors.red, Colors.redAccent, _typingController.value),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            timeStr,
            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.recording,
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
          ),
          TextButton(
            onPressed: _cancelRecording,
            child: Text('Cancelar', style: TextStyle(color: AppPalette.error)),
          ),
          const SizedBox(width: 4),
          Material(
            color: AppPalette.accent,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: _stopAndSendRecording,
              child: Container(
                width: 44, height: 44, alignment: Alignment.center,
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranscribingPanel(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? (isDark ? AppPalette.gray800 : AppPalette.white),
        border: Border(top: BorderSide(color: isDark ? AppPalette.gray700 : AppPalette.gray200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
              width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: 12),
          Text(
            AppLocalizations.of(context)!.transcribing,
            style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }

  Widget _buildHairstyleChoiceButtons(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ??
            (isDark ? AppPalette.gray800 : AppPalette.white),
        border: Border(
          top: BorderSide(
            color: isDark ? AppPalette.gray700 : AppPalette.gray200,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Te gustaria recibir una recomendacion de peinado?',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? AppPalette.gray200 : AppPalette.gray700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _sendMessage('no'),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('No, gracias'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(
                      color: isDark ? AppPalette.gray600 : AppPalette.gray300,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _sendMessage('si'),
                  icon: const Icon(Icons.face, size: 18),
                  label: const Text('Si, quiero'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: AppPalette.accent,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFaceScanButton(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ??
            (isDark ? AppPalette.gray800 : AppPalette.white),
        border: Border(
          top: BorderSide(
            color: isDark ? AppPalette.gray700 : AppPalette.gray200,
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _openFaceScan,
          icon: const Icon(Icons.face_retouching_natural, size: 22),
          label: const Text('Escanear rostro'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: AppPalette.accent,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSendingImageIndicator(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ??
            (isDark ? AppPalette.gray800 : AppPalette.white),
        border: Border(
          top: BorderSide(
            color: isDark ? AppPalette.gray700 : AppPalette.gray200,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppPalette.accent,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Analizando tu rostro...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppPalette.accent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHairstyleCard(RecommendedHairstyle hairstyle) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: AppPalette.accentGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.auto_awesome,
              size: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.content_cut,
                            color: AppPalette.accent, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Peinado Recomendado',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (hairstyle.imageUrl != null) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          hairstyle.imageUrl!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 120,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppPalette.gray700
                                  : AppPalette.gray100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.content_cut,
                                size: 40,
                                color: isDark
                                    ? AppPalette.gray500
                                    : AppPalette.gray400,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      hairstyle.description,
                      maxLines: _hairstyleExpanded ? null : 4,
                      overflow: _hairstyleExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? AppPalette.gray300 : AppPalette.gray600,
                        height: 1.5,
                      ),
                    ),
                    if (hairstyle.description.length > 200) ...[
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () => setState(() => _hairstyleExpanded = !_hairstyleExpanded),
                        child: Text(
                          _hairstyleExpanded ? 'Ver menos' : 'Ver más',
                          style: TextStyle(
                            color: AppPalette.accent,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
