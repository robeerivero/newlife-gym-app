import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/client_viewmodel.dart';
import 'class_screen.dart';
import 'premium_diet_display_screen.dart';
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
    PremiumDietDisplayScreen(),
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
              // Usa el color primario del tema (Teal)
              selectedItemColor: Theme.of(context).colorScheme.primary,
              // Usa un color sutil del tema para los no seleccionados
              unselectedItemColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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