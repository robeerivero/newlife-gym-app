import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/client_viewmodel.dart';
import 'class_screen.dart';
import 'diet_screen.dart';
import 'video_screen.dart';
import 'profile_screen.dart';
import 'salud_screen.dart';

class ClientScreen extends StatefulWidget {
  const ClientScreen({Key? key}) : super(key: key);

  @override
  State<ClientScreen> createState() => _ClientScreenState();
}

class _ClientScreenState extends State<ClientScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    ClassScreen(),
    DietScreen(),
    VideoScreen(),
    ProfileScreen(),
    SaludScreen(),
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
      Provider.of<ClientViewModel>(context, listen: false).fetchProfile()
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ClientViewModel(),
      child: Consumer<ClientViewModel>(
        builder: (context, vm, child) {
          return Scaffold(
            body: vm.isLoading
                ? const Center(child: CircularProgressIndicator())
                : vm.errorMessage != null
                    ? Center(child: Text(vm.errorMessage!))
                    : _screens[_selectedIndex],
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) => setState(() => _selectedIndex = index),
              selectedItemColor: const Color(0xFF1E88E5),
              unselectedItemColor: Colors.grey,
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.fitness_center),
                  label: 'Clases',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.restaurant),
                  label: 'Dietas',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.video_library),
                  label: 'Videos',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'Perfil',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.favorite),
                  label: 'Salud',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
