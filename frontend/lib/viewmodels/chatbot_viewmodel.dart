import 'package:flutter/material.dart';

class ChatBotViewModel extends ChangeNotifier {
  final String section;
  final TextEditingController questionController = TextEditingController();
  final List<Map<String, dynamic>> chatHistory = [];

  // Opciones rápidas
  final List<String> quickOptions = [
    'Información',
    'Horarios',
    'Precios',
    'Matrícula',
    '¿Qué traer?',
    'Ubicación',
    'Contacto'
  ];

  final Map<String, dynamic> knowledgeBase = {
    'funcional_info': {
      'response': '💪 ENTRENAMIENTO FUNCIONAL:\n\nEs una disciplina de alta intensidad adaptada a tu nivel en NewLife. Son clases dirigidas por un instructor certificado con una duración de 60 minutos. Trabajamos fuerza y agilidad usando movimientos naturales del cuerpo.',
    },
    'pilates_info': {
      'response': '🧘 PILATES:\n\nSe enfoca en el control del cuerpo y la corrección postural. Son clases dirigidas por un instructor certificado con una duración de 60 minutos. Es un método ideal para fortalecer la espalda y el abdomen de forma segura y eficaz.',
    },
    'horarios': {
      'funcional': {
        'response': '🕒 HORARIOS FUNCIONAL:\n\n• Lunes, Miércoles y Viernes:\n 8:00 a 9:00,\n 9:00 a 10:00,\n 10:00 a 11:00,\n 18:30 a 19:30,\n 19:30 a 20:30,\n 20:30 a 21:30.\n• Martes y Jueves:\n 9:00 a 10:00,\n 18:00 a 19:00.',
      },
      'pilates': {
        'response': '🕒 HORARIOS PILATES:\n\n• Lunes y Miércoles:\n 17:30 a 18:30.\n• Martes y Jueves:\n 8:00 a 9:00,\n 9:00 a 10:00,\n 10:00 a 11:00,\n 11:00 a 12:00,\n 19:00 a 20:00,\n 20:00 a 21:00.',
      },
    },
    // --- PRECIOS DIVIDIDOS ---
    'precios_pilates': {
      'response': '💰 TARIFAS PILATES:\n\n• 2 sesiones semanales: 39€/mes.\n\nSi necesitas un plan personalizado, consúltanos por WhatsApp.',
    },
    'precios_funcional': {
      'response': '💰 TARIFAS FUNCIONAL:\n\n• 2 sesiones semanales: 43€/mes.\n• 3 sesiones semanales: 51€/mes.\n\nSi necesitas un plan personalizado, consúltanos por WhatsApp.',
    },
    'matricula': {
      'response': '📝 MATRÍCULA:\n\nLa matrícula es de 15€.',
    },
    'requisitos_pilates': {
      'response': '🎒 ¿QUÉ TRAER A PILATES?\n\n1. Ropa deportiva cómoda.\n2. Toalla grande.\n3. Botella de agua.\n4. La actividad se realiza en calcetines.\n\nTodo el material de entrenamiento lo ponemos nosotros.',
    },
    'requisitos_funcional': {
      'response': '🎒 ¿QUÉ TRAER A FUNCIONAL?\n\n1. Ropa deportiva cómoda.\n2. Toalla pequeña para el sudor.\n3. Botella de agua.\n4. Guantes.\n\nTodo el material de entrenamiento lo ponemos nosotros.',
    },
    'ubicacion': {
      'response': '📍 UBICACIÓN:\n\nEl centro deportivo NewLife se encuentra en la calle C. Sor Angela de la Cruz, Chiclana.',
    },
    'contacto': {
      'response': '📞 CONTACTO:\n\n• Tel/WhatsApp: 647 449 493\n• Ubicación: C. Sor Angela de la Cruz, Chiclana.',
    },
  };

  ChatBotViewModel(this.section) {
    _addInitialMessage();
  }

  void _addInitialMessage() {
    chatHistory.add({
      'text': '¡Hola! Bienvenido a NewLife 💪. Soy tu asistente para la sección de $section.\n\n¿En qué puedo ayudarte? Pulsa un botón o escribe tu duda.',
      'isBot': true,
      'timestamp': DateTime.now(),
    });
  }

  void processInput(String text, VoidCallback onUpdate) {
    if (text.trim().isEmpty) return;

    chatHistory.add({'text': text, 'isBot': false, 'timestamp': DateTime.now()});
    final response = _processQuestion(text);

    Future.delayed(const Duration(milliseconds: 400), () {
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

    // 1. Información dinámica
    if (lower.contains('informaci') || lower.contains('info')) {
      if (section.toLowerCase().contains('pilates')) {
        return knowledgeBase['pilates_info']['response'];
      } else {
        return knowledgeBase['funcional_info']['response'];
      }
    }

    // 2. Horarios
    if (lower.contains('horario')) return knowledgeBase['horarios'][section.toLowerCase()]['response'];

    // 3. Precios DINÁMICOS SEGÚN SECCIÓN
    if (lower.contains('precio') || lower.contains('tarifa') || lower.contains('cuanto vale') || lower.contains('cuesta')) {
      if (section.toLowerCase().contains('pilates')) {
        return knowledgeBase['precios_pilates']['response'];
      } else {
        return knowledgeBase['precios_funcional']['response'];
      }
    }

    // 4. Matrícula
    if (lower.contains('matrícula') || lower.contains('matricula')) {
      return knowledgeBase['matricula']['response'];
    }

    // 5. Qué traer (Dinámico según sección)
    if (lower.contains('traer') || lower.contains('necesito') || lower.contains('llevar')) {
      if (section.toLowerCase().contains('pilates')) {
        return knowledgeBase['requisitos_pilates']['response'];
      } else {
        return knowledgeBase['requisitos_funcional']['response'];
      }
    }

    // 6. Ubicación
    if (lower.contains('donde') || lower.contains('ubicación') || lower.contains('ubicacion') || lower.contains('sitio')) {
      return knowledgeBase['ubicacion']['response'];
    }

    // 7. Contacto
    if (lower.contains('contacto') || lower.contains('whatsapp') || lower.contains('telefono')) {
      return knowledgeBase['contacto']['response'];
    }

    return 'No estoy seguro de cómo responder a eso. Prueba a pulsar uno de los botones de arriba para obtener información detallada. 😊';
  }
}