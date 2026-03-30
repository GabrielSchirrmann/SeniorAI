import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const SeniorAIApp());
}

class SeniorAIApp extends StatelessWidget {
  const SeniorAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SeniorAI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFD5E6)),
        useMaterial3: true,
      ),
      home: const ChatPage(),
    );
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _aguardandoResposta = false;
  bool _mostraBotoes = false;
  bool _audioTocando = false;

static const Color primaryColor = Color(0xFFFD5E6);
static const Color bgColor = Color(0xFFECEFF1);
static const Color assistantBubble = Color(0xFF121313);
static const Color userBubble = Color(0xFF121313);
static const Color mistGrey = Color(0xFFECEFF1);
static const Color spaceBlack = Color(0xFF121313);

  final String _apiUrl = 'http://localhost:8080/perguntar';
  final String _resetUrl = 'http://localhost:8080/resetar';

  Future<void> _enviarMensagem(String texto) async {
    if (texto.trim().isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'text': texto});
      _aguardandoResposta = true;
      _mostraBotoes = false;
    });
    _controller.clear();
    _rolarParaBaixo();

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mensagem': texto}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _messages.add({'role': 'assistant', 'text': data['resposta']});
          _mostraBotoes = true;
        });
      } else {
        _adicionarErro('Erro ao conectar com a IA.');
      }
    } catch (e) {
      _adicionarErro('Não foi possível conectar. Verifique o servidor.');
    }

    setState(() => _aguardandoResposta = false);
    _rolarParaBaixo();
  }

  Future<void> _reiniciarChat() async {
    try {
      await http.post(Uri.parse(_resetUrl));
    } catch (_) {}
    setState(() {
      _messages.clear();
      _mostraBotoes = false;
      _audioTocando = false;
    });
  }

  void _adicionarErro(String msg) {
    setState(() {
      _messages.add({'role': 'error', 'text': msg});
    });
  }

  void _rolarParaBaixo() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _simularAudio() {
    setState(() => _audioTocando = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _audioTocando = false);
    });
  }

  Widget _buildAvatar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFFFE0DE), width: 1)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.elderly, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SeniorAI',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D2D2D),
                ),
              ),
              Text(
                'Assistente Tecnológico',
                style: TextStyle(fontSize: 13, color: Colors.black45),
              ),
            ],
          ),
          const Spacer(),
          // Indicador de áudio tocando
          if (_audioTocando)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEDEC),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.volume_up, color: primaryColor, size: 18),
                  SizedBox(width: 4),
                  Text('Falando...', style: TextStyle(color: primaryColor, fontSize: 13)),
                ],
              ),
            ),
          const SizedBox(width: 8),
          // Botão reiniciar
          Tooltip(
            message: 'Reiniciar conversa',
            child: InkWell(
              onTap: () => _confirmarReinicio(),
              borderRadius: BorderRadius.circular(10),
              child: Container(
  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
  decoration: BoxDecoration(
    color: mistGrey,
    borderRadius: BorderRadius.circular(10),
  ),
              child: const Row(
                children: [
                  Text('Reiniciar chat',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: spaceBlack)),
                  SizedBox(width: 6),
                  Icon(Icons.refresh_rounded, color: spaceBlack, size: 20),
                ],
              ),
            ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmarReinicio() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reiniciar conversa?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'O histórico da conversa atual será apagado e você poderá começar do zero.',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.black45)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _reiniciarChat();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Reiniciar'),
          ),
        ],
      ),
    );
  }

  Widget _buildMensagem(Map<String, String> msg) {
    final isUser = msg['role'] == 'user';
    final isError = msg['role'] == 'error';

    return Padding(
      padding: EdgeInsets.only(
        left: isUser ? 60 : 16,
        right: isUser ? 16 : 60,
        top: 4,
        bottom: 4,
      ),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: isError
                ? Colors.red[50]
                : isUser
                    ? userBubble
                    : assistantBubble,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isUser ? 18 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser && !isError)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.elderly, size: 14, color: primaryColor),
                      const SizedBox(width: 4),
                      const Text('SeniorAI',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white60,
                          fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      // Botão ouvir resposta
                      const Spacer(),
                      InkWell(
                        onTap: _simularAudio,
                        child: const Row(
                          children: [
                            Icon(Icons.volume_up_rounded,
                                size: 16, color: Colors.white),
                            SizedBox(width: 4),
                            Text('Ouvir',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              Text(
                msg['text'] ?? '',
                style: TextStyle(
                  fontSize: 17,
                  color: Colors.white,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          // Avatar + Header
          _buildAvatar(),

          // Área de mensagens
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEDEC),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.elderly,
                              color: primaryColor, size: 40),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Olá! Como posso te ajudar?',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D2D2D)),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Descreva seu problema ou aperte o microfone.',
                          style:
                              TextStyle(fontSize: 16, color: Colors.black45),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) => _buildMensagem(_messages[i]),
                  ),
          ),

          // Indicador digitando
          if (_aguardandoResposta)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: primaryColor),
                  ),
                  const SizedBox(width: 8),
                  const Text('SeniorAI está digitando...',
                      style: TextStyle(fontSize: 14, color: Colors.black45)),
                ],
              ),
            ),

          // Botões Sim/Não
          if (_mostraBotoes)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _enviarMensagem('Sim, consegui!'),
                      label: const Text('Consegui',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _enviarMensagem(
                          'Não consegui, pode explicar de outro jeito?'),
                      label: const Text('Não consegui',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5252),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Campo de texto + botões
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFFFE0DE))),
            ),
            child: Row(
              children: [
                // Botão microfone
                Container(
                  width: 52,
                  height: 52,
                  margin: const EdgeInsets.only(right: 10),
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mistGrey,
                      foregroundColor: spaceBlack,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: EdgeInsets.zero,
                      elevation: 0,
                    ),
                    child: const Icon(Icons.mic_rounded, size: 26),
                  ),
                ),
                // Campo de texto
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(fontSize: 17),
                    decoration: InputDecoration(
                      hintText: 'Descreva seu problema...',
                      hintStyle: const TextStyle(
                          fontSize: 17, color: Color(0xFF6B6B6B)),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: Color(0xFFFFD5D2)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: Color(0xFFFFD5D2)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: primaryColor, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    onSubmitted: _enviarMensagem,
                  ),
                ),
                const SizedBox(width: 10),
                // Botão enviar
                Container(
                  width: 52,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => _enviarMensagem(_controller.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mistGrey,
                      foregroundColor: spaceBlack,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: EdgeInsets.zero,
                      elevation: 0,
                    ),
                    child: const Icon(Icons.send_rounded, size: 22),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}