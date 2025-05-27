// ... tus imports ya están OK
import 'package:flutter/material.dart';
import '../../fluttermoji/fluttermoji.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config.dart';
import 'edit_profile_screen.dart';
import '../../fluttermoji/fluttermoji_assets/fluttermojimodel.dart';
import '../../fluttermoji/fluttermojiCustomizer.dart'; // Corrige el import según tu carpeta real

// -------------- MODELOS ----------------
class UsuarioRanking {
  final String id;
  final String nombre;
  final Map<String, dynamic> avatar;
  final int asistenciasEsteMes;
  final int pasosEsteMes;

  UsuarioRanking({
    required this.id,
    required this.nombre,
    required this.avatar,
    required this.asistenciasEsteMes,
    required this.pasosEsteMes,
  });

  factory UsuarioRanking.fromJson(Map<String, dynamic> json) {
    return UsuarioRanking(
      id: json['_id'],
      nombre: json['nombre'],
      avatar: json['avatar'] ?? {},
      asistenciasEsteMes: json['asistenciasEsteMes'] ?? 0,
      pasosEsteMes: json['pasosEsteMes'] ?? 0,
    );
  }
}

class LogroPrenda {
  final String key;
  final String value;
  final String nombre;
  final String categoria;
  final String descripcion;
  final String? logro;
  final bool conseguido;
  final String emoji;

  LogroPrenda({
    required this.key,
    required this.value,
    required this.nombre,
    required this.categoria,
    required this.descripcion,
    required this.logro,
    required this.conseguido,
    required this.emoji,
  });

  factory LogroPrenda.fromJson(Map<String, dynamic> json) {
    return LogroPrenda(
      key: json['key'],
      value: json['value'],
      nombre: json['nombre'],
      categoria: json['categoria'],
      descripcion: json['descripcion'],
      logro: json['logro'],
      conseguido: json['conseguido'] ?? false,
      emoji: json['emoji'] ?? "🎉",
    );
  }
}

// -------------- PROFILE SCREEN --------------
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String? _name;
  String? _email;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() { _loading = true; _error = null; });
    try {
      final token = await _storage.read(key: 'jwt_token');
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/usuarios/perfil'),
        headers: { 'Authorization': 'Bearer $token' },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final avatarJson = data['avatar'];
        _name = data['nombre'] ?? "Usuario";
        _email = data['correo'] ?? "";
        if (avatarJson != null) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('fluttermojiSelectedOptions', avatarJson);
        }
      } else {
        _error = 'Error al obtener el perfil';
      }
    } catch (e) {
      _error = "Error de conexión";
    } finally {
      setState(() { _loading = false; });
    }
  }

  Future<void> _guardarAvatar() async {
    final token = await _storage.read(key: 'jwt_token');
    final avatarJson = await FluttermojiFunctions().encodeMySVGtoString();
    await http.put(
      Uri.parse('${AppConstants.baseUrl}/api/usuarios/avatar'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'avatar': avatarJson}),
    );
  }

  Future<Map<String, Set<int>>> _fetchPrendasDesbloqueadas() async {
    final token = await _storage.read(key: 'jwt_token');
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/api/usuarios/prendas/desbloqueadas'),
      headers: { 'Authorization': 'Bearer $token' },
    );
    if (response.statusCode == 200) {
      final prendas = jsonDecode(response.body) as List;
      Map<String, Set<int>> map = {};
      for (final prenda in prendas) {
        final key = prenda['key'];
        final idx = prenda['idx'];
        if (idx != null && idx is int) {
          map.putIfAbsent(key, () => <int>{}).add(idx);
        }
      }
      return map;
    }
    throw Exception('Error al cargar prendas desbloqueadas');
  }

  void _editarAvatar() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    Map<String, Set<int>> prendasDesbloqueadas = {};
    try {
      prendasDesbloqueadas = await _fetchPrendasDesbloqueadas();
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar tus prendas desbloqueadas')),
      );
      return;
    }

    Navigator.of(context).pop();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FluttermojiCustomizer(
          prendasDesbloqueadasPorAtributo: prendasDesbloqueadas,
        ),
      ),
    );
    await _guardarAvatar();
    setState(() {});
  }

  void _editarPerfil() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          initialName: _name ?? "",
          initialEmail: _email ?? "",
        ),
      ),
    );
    if (result == true) {
      _fetchProfile();
    }
  }

  void _showSettingsDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Container(
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person, color: Color(0xFF1E88E5)),
                title: const Text('Editar perfil'),
                onTap: () {
                  Navigator.pop(ctx);
                  _editarPerfil();
                },
              ),
              ListTile(
                leading: const Icon(Icons.face, color: Color(0xFF42A5F5)),
                title: const Text('Editar avatar'),
                onTap: () {
                  Navigator.pop(ctx);
                  _editarAvatar();
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Cerrar sesión'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _storage.delete(key: 'jwt_token');
                  if (mounted) Navigator.of(context).pushReplacementNamed('/login');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E88E5),
        title: const Text('Mi Perfil', style: TextStyle(color: Colors.white)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              child: Center(
                child: Card(
                  elevation: 12,
                  margin: const EdgeInsets.only(top: 20, bottom: 28),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Text(_error!,
                                style: const TextStyle(color: Colors.red, fontSize: 16)),
                          ),
                        FluttermojiCircleAvatar(
                          backgroundColor: Colors.blue[50],
                          radius: 70,
                        ),
                        const SizedBox(height: 18),
                        Text(
                          _name ?? "",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            color: Color(0xFF1E88E5),
                          ),
                        ),
                        Text(
                          _email ?? "",
                          style: const TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.person, size: 22),
                          label: const Text("Editar perfil"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E88E5),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            textStyle: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          onPressed: _editarPerfil,
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.face, size: 22),
                          label: const Text("Editar avatar"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF42A5F5),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            textStyle: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          onPressed: _editarAvatar,
                        ),
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (_) => RankingModal(),
                            );
                          },
                          child: Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 5,
                            child: ListTile(
                              leading: Icon(Icons.emoji_events, color: Colors.amber, size: 40),
                              title: Text('Ranking mensual'),
                              subtitle: Text('¿Quién va primero en la liga este mes?'),
                              trailing: Icon(Icons.arrow_forward_ios),
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (_) => LogrosModal(),
                            );
                          },
                          child: Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 5,
                            child: ListTile(
                              leading: Icon(Icons.stars, color: Colors.blue, size: 40),
                              title: Text('Logros y recompensas'),
                              subtitle: Text('¡Descubre qué has desbloqueado!'),
                              trailing: Icon(Icons.arrow_forward_ios),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

// -------------- RANKING MODAL --------------
class RankingModal extends StatefulWidget {
  @override
  State<RankingModal> createState() => _RankingModalState();
}

class _RankingModalState extends State<RankingModal> {
  late Future<List<UsuarioRanking>> futureRanking;

  @override
  void initState() {
    super.initState();
    futureRanking = fetchRankingUsuarios();
  }

  Future<List<UsuarioRanking>> fetchRankingUsuarios() async {
    final token = await FlutterSecureStorage().read(key: 'jwt_token');
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/api/usuarios/ranking-mensual'),
      headers: { 'Authorization': 'Bearer $token' },
    );

    if (response.statusCode != 200) throw Exception('Error obteniendo ranking');

    final List data = jsonDecode(response.body);

    return data.map<UsuarioRanking>((json) => UsuarioRanking.fromJson(json)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(16),
        width: 350,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Ranking mensual', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            FutureBuilder<List<UsuarioRanking>>(
              future: futureRanking,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                final ranking = snapshot.data!;
                if (ranking.isEmpty) return Text("Aún no hay asistencias este mes");
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: ranking.length,
                  itemBuilder: (context, index) {
                    final usuario = ranking[index];
                    return ListTile(
                      leading: GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => Dialog(
                              child: Container(
                                padding: EdgeInsets.all(20),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(usuario.nombre, style: TextStyle(fontSize: 22)),
                                    SizedBox(height: 16),
                                    FluttermojiCircleAvatar(
                                      radius: 60,
                                      avatarJson: jsonEncode(usuario.avatar),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                        child: FluttermojiCircleAvatar(
                          radius: 22,
                          avatarJson: jsonEncode(usuario.avatar),
                        ),
                      ),
                      title: Text(usuario.nombre),
                      subtitle: Text('Asistencias: ${usuario.asistenciasEsteMes}, Pasos: ${usuario.pasosEsteMes}'),
                      trailing: index == 0
                          ? Icon(Icons.emoji_events, color: Colors.amber)
                          : index == 1
                              ? Icon(Icons.emoji_events, color: Colors.grey)
                              : index == 2
                                  ? Icon(Icons.emoji_events, color: Colors.brown)
                                  : null,
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// -------------- LOGROS MODAL --------------
class LogrosModal extends StatefulWidget {
  @override
  State<LogrosModal> createState() => _LogrosModalState();
}

class _LogrosModalState extends State<LogrosModal> {
  late Future<List<LogroPrenda>> futureLogros;

  @override
  void initState() {
    super.initState();
    futureLogros = fetchLogros();
  }

  Future<List<LogroPrenda>> fetchLogros() async {
    final token = await FlutterSecureStorage().read(key: 'jwt_token');
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/api/usuarios/prendas/progreso'),
      headers: { 'Authorization': 'Bearer $token' },
    );

    if (response.statusCode != 200) throw Exception('Error obteniendo logros');

    final List data = jsonDecode(response.body);
    return data.map<LogroPrenda>((json) => LogroPrenda.fromJson(json)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(16),
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Logros y recompensas', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            FutureBuilder<List<LogroPrenda>>(
              future: futureLogros,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                final logros = snapshot.data!;
                if (logros.isEmpty) return Text("No hay logros definidos");
                return SizedBox(
                  height: 450,
                  child: ListView.separated(
                    itemCount: logros.length,
                    separatorBuilder: (_, __) => Divider(height: 10),
                    itemBuilder: (context, idx) {
                      final logro = logros[idx];
                      return ListTile(
                        leading: Text(logro.emoji, style: TextStyle(fontSize: 28)),
                        title: Text(logro.nombre, style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(logro.descripcion),
                            if (!logro.conseguido)
                              Padding(
                                padding: const EdgeInsets.only(top: 5.0),
                                child: ProgresoLogroWidget(logro: logro),
                              )
                          ],
                        ),
                        trailing: logro.conseguido
                          ? Icon(Icons.check_circle, color: Colors.green)
                          : Icon(Icons.lock_outline, color: Colors.grey),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// -------------- PROGRESO DE LOGRO (para mostrar 8/10, pasos, etc) --------------
class ProgresoLogroWidget extends StatefulWidget {
  final LogroPrenda logro;

  ProgresoLogroWidget({required this.logro});

  @override
  State<ProgresoLogroWidget> createState() => _ProgresoLogroWidgetState();
}

class _ProgresoLogroWidgetState extends State<ProgresoLogroWidget> {
  int? totalAsistencias;
  int? rachaActual;
  int? pasosHoy;
  int? kcalHoy;

  @override
  void initState() {
    super.initState();
    obtenerProgreso();
  }

  Future<void> obtenerProgreso() async {
    final token = await FlutterSecureStorage().read(key: 'jwt_token');
    if (widget.logro.logro?.contains("asistencia") == true || widget.logro.logro?.contains("racha") == true) {
      final res = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/usuarios/perfil'),
        headers: { 'Authorization': 'Bearer $token' },
      );
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        final asistencias = json['asistencias'] as List? ?? [];
        totalAsistencias = asistencias.length;

        List<DateTime> fechas = [];
        if (json['asistenciasFechas'] != null) {
          fechas = (json['asistenciasFechas'] as List)
              .map<DateTime>((f) => DateTime.parse(f)).toList();
        }
        fechas.sort();
        int racha = 1, maxRacha = 1;
        for (int i = 1; i < fechas.length; i++) {
          if (fechas[i].difference(fechas[i - 1]).inDays == 1) {
            racha++;
          } else {
            racha = 1;
          }
          if (racha > maxRacha) maxRacha = racha;
        }
        rachaActual = racha;
      }
    }
    if (widget.logro.logro?.contains("pasos") == true || widget.logro.logro?.contains("kcal") == true) {
      final hoy = DateTime.now();
      final fechaHoy = "${hoy.year}-${hoy.month.toString().padLeft(2, '0')}-${hoy.day.toString().padLeft(2, '0')}";
      final res = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/salud/dia/$fechaHoy'),
        headers: { 'Authorization': 'Bearer $token' },
      );
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        pasosHoy = json['pasos'] ?? 0;
        kcalHoy = (json['kcalQuemadas'] ?? 0) + (json['kcalQuemadasManual'] ?? 0);
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final logro = widget.logro.logro;
    if (logro == null) return SizedBox();
    if (logro.contains("asistencia_") && logro.contains("_total") && totalAsistencias != null) {
      final req = int.parse(RegExp(r'asistencia_(\d+)_total').firstMatch(logro)!.group(1)!);
      return Text('Progreso: $totalAsistencias / $req asistencias');
    }
    if (logro.contains("asistencia_") && logro.contains("_seguidas") && rachaActual != null) {
      final req = int.parse(RegExp(r'asistencia_(\d+)_seguidas').firstMatch(logro)!.group(1)!);
      return Text('Racha actual: $rachaActual / $req');
    }
    if (logro.contains("racha_") && rachaActual != null) {
      final req = int.parse(RegExp(r'racha_(\d+)_seguidas').firstMatch(logro)!.group(1)!);
      return Text('Racha actual: $rachaActual / $req');
    }
    if (logro.contains("pasos_") && pasosHoy != null) {
      final req = int.parse(RegExp(r'pasos_(\d+)_dia').firstMatch(logro)!.group(1)!);
      return Text('Hoy: $pasosHoy / $req pasos');
    }
    if (logro.contains("kcal_") && kcalHoy != null) {
      final req = int.parse(RegExp(r'kcal_(\d+)_dia').firstMatch(logro)!.group(1)!);
      return Text('Hoy: $kcalHoy / $req kcal');
    }
    return SizedBox();
  }
}
