import 'package:flutter/material.dart';

class ChatBotViewModel extends ChangeNotifier {
  final String section;
  final TextEditingController questionController = TextEditingController();
  final List<Map<String, dynamic>> chatHistory = [];

  final Map<String, dynamic> knowledgeBase = {
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
    'requisitos': {
      'response': 'Para asistir a clase solo necesitas:\n'
          '• Ropa deportiva\n'
          '• Toalla\n'
          '• Agua\n'
          'Todo el material extra te lo proporcionamos en el centro.',
    },
    'cancelacion': {
      'response': 'Puedes cancelar una clase con al menos 3 horas de antelación.\n'
          'Si cancelas más tarde, no podrás recuperar esa reserva.',
    },
    'duracion': {
      'response': 'Cada clase tiene una duración de 1 hora.',
    },
    'precios': {
      'response': 'Para conocer los precios actuales, contáctanos por WhatsApp al 647449493.',
    },
    'contacto': {
      'response': 'Puedes contactarnos a través de:\n'
          '• WhatsApp: 647449493\n'
          '• Dirección: C. Sor Angela de la Cruz, 11130 Chiclana de la Frontera, Cádiz\n'
          '• Google Maps: https://maps.app.goo.gl/KpFojsnn44baaN7SA',
    },
    'modalidad': {
      'response': 'Ofrecemos clases tanto presenciales como online.\n'
          'También tienes acceso a videos en la app para entrenar cuando y donde quieras.',
    },
    'cambio': {
      'response': 'No puedes cambiar directamente de tipo de clase.\n'
          'Para cambiar de Pilates a Funcional (o viceversa), deberás contratar ese servicio.',
    },
    'nivel': {
      'response': 'Las clases están adaptadas para todos los niveles.\n'
          'No necesitas experiencia previa para comenzar.',
    },
    'puntualidad': {
      'response': 'Puedes llegar tarde, pero perderás parte del entrenamiento.\n'
          '¡Intenta llegar puntual para aprovechar al máximo tu clase!',
    },
    'general': {
      'response': '¿En qué más puedo ayudarte?\n'
          'Puedes preguntar sobre:\n'
          '• Horarios de clases\n'
          '• Servicios adicionales\n'
          '• Reservas\n'
          '• Requisitos para clases\n'
          '• Modalidad presencial/online\n'
          '• Contacto y ubicación\n'
          '• Niveles, duración, precios, etc.',
    },
  };

  ChatBotViewModel(this.section) {
    _addInitialMessage();
  }

  void _addInitialMessage() {
    chatHistory.add({
      'text': '¡Hola! Soy tu asistente de NewLife. ¿En qué puedo ayudarte?',
      'isBot': true,
      'timestamp': DateTime.now(),
    });
    chatHistory.add(_buildSectionInfo());
  }

  Map<String, dynamic> _buildSectionInfo() {
    String info;
    switch (section.toLowerCase()) {
      case 'pilates':
        info = 'Funcionalidades de Pilates:\n'
            '• Clases guiadas por profesionales\n'
            '• Rutinas personalizadas\n'
            '• Seguimiento de progreso';
        break;
      case 'funcional':
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

  void handleUserQuestion(VoidCallback onUpdate) {
    final userQuestion = questionController.text.trim();
    if (userQuestion.isEmpty) return;

    chatHistory.add({
      'text': userQuestion,
      'isBot': false,
      'timestamp': DateTime.now(),
    });

    final response = _processQuestion(userQuestion);

    Future.delayed(const Duration(milliseconds: 500), () {
      chatHistory.add({
        'text': response,
        'isBot': true,
        'timestamp': DateTime.now(),
      });
      onUpdate();
    });

    questionController.clear();
    onUpdate();
  }

  String _processQuestion(String question) {
    final lower = question.toLowerCase();

    if (lower.contains('horario')) {
      return knowledgeBase['horarios'][section.toLowerCase()]['response'];
    }
    if (lower.contains(RegExp(r'servicios|dieta|video|online'))) {
      return knowledgeBase['servicios']['response'];
    }
    if (lower.contains(RegExp(r'reserva|reservar|reservación'))) {
      return knowledgeBase['reservas']['response'];
    }
    if (lower.contains(RegExp(r'requisito|llevar|necesito'))) {
      return knowledgeBase['requisitos']['response'];
    }
    if (lower.contains(RegExp(r'cancelar|cancelación|penalización'))) {
      return knowledgeBase['cancelacion']['response'];
    }
    if (lower.contains(RegExp(r'duración|cuánto dura'))) {
      return knowledgeBase['duracion']['response'];
    }
    if (lower.contains(RegExp(r'precio|cuesta|tarifa|plan'))) {
      return knowledgeBase['precios']['response'];
    }
    if (lower.contains(RegExp(r'contacto|teléfono|dirección|ubicación|dónde'))) {
      return knowledgeBase['contacto']['response'];
    }
    if (lower.contains(RegExp(r'online|presencial|modalidad'))) {
      return knowledgeBase['modalidad']['response'];
    }
    if (lower.contains(RegExp(r'cambio|cambiar|otra clase|otra rutina'))) {
      return knowledgeBase['cambio']['response'];
    }
    if (lower.contains(RegExp(r'nivel|principiante|experiencia'))) {
      return knowledgeBase['nivel']['response'];
    }
    if (lower.contains(RegExp(r'tarde|puntualidad|retraso'))) {
      return knowledgeBase['puntualidad']['response'];
    }

    return knowledgeBase['general']['response'];
  }
}
