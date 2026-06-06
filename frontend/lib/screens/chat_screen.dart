import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/ai_services.dart';
import '../core/theme.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  bool _cargando = false;
  bool _inputActivo = false;

  List<_Mensaje> _mensajes = [];

  // Sugerencias rápidas de inicio
  final List<String> _sugerencias = [
    '¿Qué alimentos suben más la glucosa?',
    '¿Cómo afecta el estrés a mi diabetes?',
    '¿Cuándo debo medir mi glucosa?',
    '¿Es normal tener 140 mg/dL después de comer?',
  ];

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _focusNode.addListener(() {
      setState(() => _inputActivo = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _enviar([String? textoDirecto]) async {
      final texto = (textoDirecto ?? _controller.text).trim();
      if (texto.isEmpty || _cargando) return;
  
      HapticFeedback.lightImpact();
  
      final msgUser = _Mensaje(
        role: _Rol.user,
        text: texto,
        animController: AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 350),
        ),
      );
  
      setState(() {
        _mensajes.add(msgUser);
        _cargando = true;
        _controller.clear();
      });
  
      msgUser.animController.forward();
      _scrollToBottom();
  
      // ── Llamada al service tipado ─────────────────────────────────────────
      // Cambia userId: 1 por el ID real cuando tengas auth
      final resp = await AIService.enviarMensaje(texto, /* userId: 14 */);
  
      final msgAI = _Mensaje(
        role: resp.success ? _Rol.ai : _Rol.error,
        text: resp.displayText,
        animController: AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 450),
        ),
      );
  
      setState(() {
        _mensajes.add(msgAI);
        _cargando = false;
      });
  
      msgAI.animController.forward();
      _scrollToBottom();
    }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = _mensajes.isEmpty && !_cargando;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // ── Cuerpo del chat
          Expanded(
            child: isEmpty ? _buildEmptyState() : _buildChatList(),
          ),

          // ── Indicador de escritura IA
          if (_cargando) _buildTypingIndicator(),

          // ── Input
          _buildInputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.background,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: AppTheme.textSecondary, size: 18),
        onPressed: () => Navigator.maybePop(context),
      ),
      title: Row(
        children: [
          // Avatar con pulso
          Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, __) => Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.accent.withOpacity(0.12 * _pulseAnim.value),
                  ),
                ),
              ),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accentDim,
                  border: Border.all(color: AppTheme.accent.withOpacity(0.5)),
                ),
                child: const Icon(Icons.psychology_rounded,
                    color: AppTheme.accent, size: 17),
              ),
            ],
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('GlucoAI',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3)),
              Text('Asistente de diabetes',
                  style: TextStyle(
                      color: AppTheme.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
      actions: [
        // Estado online
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppTheme.success.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.success.withOpacity(0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.success,
                ),
              ),
              const SizedBox(width: 5),
              const Text('En línea',
                  style: TextStyle(
                      color: AppTheme.success,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppTheme.border),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        children: [
          // ── Hero
          _HeroSection(),
          const SizedBox(height: 36),

          // ── Sugerencias
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Preguntas frecuentes',
                style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3)),
          ),
          const SizedBox(height: 12),
          ...List.generate(_sugerencias.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _SugerenciaCard(
                texto: _sugerencias[i],
                delay: i * 60,
                onTap: () => _enviar(_sugerencias[i]),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: _mensajes.length,
      itemBuilder: (context, i) {
        final msg = _mensajes[i];
        final prev = i > 0 ? _mensajes[i - 1] : null;
        final showDate = prev == null || prev.role != msg.role;
        return _MensajeBubble(
          // final isUser = msg.role == _Rol.user;
      // final isError = msg.role == _Rol.error;
          msg: msg,
          showAvatar: showDate,
          onLongPress: () => _copiar(msg.text),
        );
      },
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(18),
            ),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.psychology_rounded,
                  color: AppTheme.accent, size: 14),
              const SizedBox(width: 8),
              _DotsIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      decoration: BoxDecoration(
        color: AppTheme.background,
        border: const Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Campo de texto
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _inputActivo
                      ? AppTheme.accent.withOpacity(0.5)
                      : AppTheme.border,
                  width: _inputActivo ? 1.5 : 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      maxLines: 4,
                      minLines: 1,
                      style: const TextStyle(
                          color: AppTheme.textPrimary, fontSize: 15),
                      decoration: const InputDecoration(
                        hintText: 'Pregúntame sobre tu glucosa...',
                        hintStyle: TextStyle(
                            color: AppTheme.textMuted, fontSize: 15),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      onSubmitted: (_) => _enviar(),
                      textInputAction: TextInputAction.send,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Botón enviar
          GestureDetector(
            onTap: _cargando ? null : _enviar,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _cargando
                    ? AppTheme.textMuted
                    : AppTheme.accent,
                boxShadow: _cargando
                    ? null
                    : [
                        BoxShadow(
                          color: AppTheme.accent.withOpacity(0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Icon(
                _cargando ? Icons.hourglass_empty_rounded : Icons.arrow_upward_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _copiar(String texto) {
    Clipboard.setData(ClipboardData(text: texto));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Copiado al portapapeles'),
        backgroundColor: AppTheme.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ── Hero vacío ────────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Icono con capas
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accent.withOpacity(0.06),
              ),
            ),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accentDim,
                border: Border.all(
                    color: AppTheme.accent.withOpacity(0.3), width: 1.5),
              ),
              child: const Icon(Icons.psychology_alt_rounded,
                  color: AppTheme.accent, size: 36),
            ),
            // Orbe decorativo
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.success,
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text('GlucoAI',
            style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8)),
        const SizedBox(height: 8),
        const Text(
          'Tu asistente médico inteligente\nespecializado en diabetes',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              height: 1.5),
        ),
        const SizedBox(height: 20),
        // Chips de capacidades
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _CapChip(icon: Icons.bloodtype_rounded,       label: 'Glucosa'),
            _CapChip(icon: Icons.restaurant_rounded,      label: 'Nutrición'),
            _CapChip(icon: Icons.medication_rounded,      label: 'Medicamentos'),
            _CapChip(icon: Icons.fitness_center_rounded,  label: 'Ejercicio'),
          ],
        ),
      ],
    );
  }
}

class _CapChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _CapChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.accent),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ── Sugerencia card ───────────────────────────────────────────────────────────

class _SugerenciaCard extends StatefulWidget {
  final String texto;
  final int delay;
  final VoidCallback onTap;
  const _SugerenciaCard(
      {required this.texto, required this.delay, required this.onTap});

  @override
  State<_SugerenciaCard> createState() => _SugerenciaCardState();
}

class _SugerenciaCardState extends State<_SugerenciaCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) {
            setState(() => _pressed = false);
            widget.onTap();
          },
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _pressed ? AppTheme.accentDim : AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _pressed
                    ? AppTheme.accent.withOpacity(0.4)
                    : AppTheme.border,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.chat_bubble_outline_rounded,
                    size: 16, color: AppTheme.accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(widget.texto,
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          height: 1.3)),
                ),
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 12, color: AppTheme.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Bubble de mensaje ─────────────────────────────────────────────────────────

class _MensajeBubble extends StatelessWidget {
  final _Mensaje msg;
  final bool showAvatar;
  final VoidCallback onLongPress;
  const _MensajeBubble(
      {required this.msg, required this.showAvatar, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.role == _Rol.user;

    return FadeTransition(
      opacity: msg.animController,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(isUser ? 0.3 : -0.3, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: msg.animController,
          curve: Curves.easeOutCubic,
        )),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              // Avatar IA
              if (!isUser) ...[
                Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(right: 8, bottom: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.accentDim,
                    border:
                        Border.all(color: AppTheme.accent.withOpacity(0.3)),
                  ),
                  child: const Icon(Icons.psychology_rounded,
                      color: AppTheme.accent, size: 15),
                ),
              ],

              // Burbuja
              Flexible(
                child: GestureDetector(
                  onLongPress: onLongPress,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.72,
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: isUser ? AppTheme.accent : AppTheme.surface,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft:
                            Radius.circular(isUser ? 18 : 4),
                        bottomRight:
                            Radius.circular(isUser ? 4 : 18),
                      ),
                      border: isUser
                          ? null
                          : Border.all(color: AppTheme.border),
                      boxShadow: isUser
                          ? [
                              BoxShadow(
                                color: AppTheme.accent.withOpacity(0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      msg.text,
                      style: TextStyle(
                        color: isUser
                            ? Colors.white
                            : AppTheme.textPrimary,
                        fontSize: 14,
                        height: 1.45,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ),

              // Espacio derecho para mensajes IA
              if (!isUser) const SizedBox(width: 36),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Dots typing indicator ─────────────────────────────────────────────────────

class _DotsIndicator extends StatefulWidget {
  @override
  State<_DotsIndicator> createState() => _DotsIndicatorState();
}

class _DotsIndicatorState extends State<_DotsIndicator>
    with TickerProviderStateMixin {
  final List<AnimationController> _ctrls = [];
  final List<Animation<double>> _anims = [];

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < 3; i++) {
      final c = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      );
      _ctrls.add(c);
      _anims.add(Tween<double>(begin: 0, end: -5).animate(
        CurvedAnimation(parent: c, curve: Curves.easeInOut),
      ));
      Future.delayed(Duration(milliseconds: i * 140), () {
        if (mounted) c.repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _anims[i],
          builder: (_, __) => Transform.translate(
            offset: Offset(0, _anims[i].value),
            child: Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accent,
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ── Modelos internos ──────────────────────────────────────────────────────────

enum _Rol { user, ai, error }

class _Mensaje {
  final _Rol role;
  final String text;
  final AnimationController animController;

  _Mensaje({
    required this.role,
    required this.text,
    required this.animController,
  });
}