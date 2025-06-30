import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/online_client_viewmodel.dart';
import '../client/rutinas_screen.dart';
import '../client/diet_screen.dart';
import '../client/video_screen.dart';
import '../client/profile_screen.dart';
import '../client/salud_screen.dart';

class OnlineClientScreen extends StatefulWidget {
  const OnlineClientScreen({Key? key}) : super(key: key);

  @override
  State<OnlineClientScreen> createState() => _OnlineClientScreenState();
}

class _OnlineClientScreenState extends State<OnlineClientScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    RutinasScreen(),
    DietScreen(),
    VideoScreen(),
    ProfileScreen(),
    SaludScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Provider lo inicializa aquí, idealmente usa Future.microtask para no romper el build
    Future.microtask(() =>
      Provider.of<OnlineClientViewModel>(context, listen: false).fetchProfile()
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OnlineClientViewModel(),
      child: Consumer<OnlineClientViewModel>(
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
                  label: 'Rutinas',
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
