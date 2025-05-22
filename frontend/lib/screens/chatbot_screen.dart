import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:convert';

class ChatBotScreen extends StatefulWidget {
  final String section;

  const ChatBotScreen({super.key, required this.section});

  @override
  State<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  final TextEditingController _questionController = TextEditingController();
  final List<Map<String, dynamic>> _chatHistory = [];

  final Map<String, dynamic> _knowledgeBase = {
    'horarios': {
      'funcional': {
        'response': 'Horarios de Funcional:\n'
            '• Lunes, Miércoles y Viernes:\n'
            '   - 8:00-9:00\n'
            '   - 9:00-10:00\n'
            '   - 10:00-11:00\n'
            '   - 18:30-19:30\n'
            '   - 19:30-20:30\n'
            '   - 20:30-21:30\n'
            '• Martes y Jueves:\n'
            '   - 18:00-19:00',
      },
      'pilates': {
        'response': 'Horarios de Pilates:\n'
            '• Martes y Jueves:\n'
            '   - 8:00-9:00\n'
            '   - 9:00-10:00\n'
            '   - 10:00-11:00\n'
            '   - 11:00-12:00\n'
            '   - 19:00-20:00\n'
            '   - 20:00-21:00',
      },
    },
    'servicios': {
      'response': 'Otros servicios disponibles:\n'
          '• Planes de dieta personalizados\n'
          '• Videos adicionales de entrenamiento\n'
          '• Entrenamiento online en vivo\n'
          '• Seguimiento de progreso',
    },
    'reservas': {
      'response': 'Para poder reservar ponte en contacto con nosotros:\n'
          '• Por WhatsApp: 647449493',
    },
    'general': {
      'response': '¿En qué más puedo ayudarte?\n'
          'Puedes preguntar sobre:\n'
          '• Horarios de clases\n'
          '• Servicios adicionales\n'
          '• Reservas\n'
          '• Requisitos para las clases',
    }
  };

  @override
  void initState() {
    super.initState();
    _addInitialMessage();
  }

  void _addInitialMessage() {
    _chatHistory.add({
      'text': '¡Hola! Soy tu asistente de NewLife. ¿En qué puedo ayudarte?',
      'isBot': true,
      'timestamp': DateTime.now(),
    });
    _chatHistory.add(_buildSectionInfo());
  }

  Map<String, dynamic> _buildSectionInfo() {
    String info;
    switch (widget.section) {
      case 'Pilates':
        info = 'Funcionalidades de Pilates:\n'
            '• Clases guiadas por profesionales\n'
            '• Rutinas personalizadas\n'
            '• Seguimiento de progreso';
        break;
      case 'Funcional':
        info = 'Funcionalidades de Entrenamiento Funcional:\n'
            '• Entrenamiento intensivo\n'
            '• Mejora de condición física\n'
            '• Ejercicios con peso corporal';
        break;
      default:
        info = 'Funcionalidades generales:\n'
            '• Acceso a todas las clases\n'
            '• Registro de actividad\n'
            '• Seguimiento nutricional';
    }

    return {
      'text': info,
      'isBot': true,
      'timestamp': DateTime.now(),
    };
  }

  void _handleUserQuestion() {
    final userQuestion = _questionController.text.trim();
    if (userQuestion.isEmpty) return;

    setState(() {
      _chatHistory.add({
        'text': userQuestion,
        'isBot': false,
        'timestamp': DateTime.now(),
      });
    });

    final response = _processQuestion(userQuestion);

    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _chatHistory.add({
          'text': response,
          'isBot': true,
          'timestamp': DateTime.now(),
        });
      });
    });

    _questionController.clear();
  }

  String _processQuestion(String question) {
    final lowerQuestion = question.toLowerCase();

    if (lowerQuestion.contains('horario')) {
      return _knowledgeBase['horarios'][widget.section.toLowerCase()]['response'];
    }

    if (lowerQuestion.contains(RegExp(r'servicios|dieta|video|online'))) {
      return _knowledgeBase['servicios']['response'];
    }

    if (lowerQuestion.contains(RegExp(r'reserva|reservar|reservación'))) {
      return _knowledgeBase['reservas']['response'];
    }

    return _knowledgeBase['general']['response'];
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Asistente de ${widget.section}',
          style: TextStyle(
            fontSize: isDesktop ? 18 : 18.sp,
          ),
        ),
        backgroundColor: const Color(0xFF42A5F5),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16.w),
              itemCount: _chatHistory.length,
              itemBuilder: (context, index) {
                final message = _chatHistory[index];
                return _buildChatBubble(
                  message['text'],
                  isBot: message['isBot'],
                  isDesktop: isDesktop,
                );
              },
            ),
          ),
          _buildInputField(isDesktop),
        ],
      ),
    );
  }

  Widget _buildChatBubble(String text, {required bool isBot, required bool isDesktop}) {
    return Align(
      alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4.h),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isBot ? Colors.grey[300] : const Color(0xFF42A5F5),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isBot ? Radius.zero : const Radius.circular(16),
            bottomRight: isBot ? const Radius.circular(16) : Radius.zero,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isBot ? Colors.black : Colors.white,
            fontSize: isDesktop ? 16 : 16.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(bool isDesktop) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _questionController,
              decoration: InputDecoration(
                hintText: 'Escribe tu pregunta...',
                hintStyle: TextStyle(
                  fontSize: isDesktop ? 14 : 14.sp,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20.w,
                  vertical: 14.h,
                ),
              ),
              style: TextStyle(fontSize: isDesktop ? 14 : 14.sp),
              onSubmitted: (_) => _handleUserQuestion(),
            ),
          ),
          SizedBox(width: 10.w),
          IconButton(
            icon: Icon(Icons.send, color: const Color(0xFF42A5F5)),
            onPressed: _handleUserQuestion,
          ),
        ],
      ),
    );
  }
}
