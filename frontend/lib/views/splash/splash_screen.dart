import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/splash_viewmodel.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late SplashViewModel splashVM;

  @override
  void initState() {
    super.initState();
    splashVM = SplashViewModel(this);
    splashVM.addListener(_handleNavigation);
  }

  void _handleNavigation() {
    // Lógica original intacta
    if (!splashVM.isLoading && splashVM.nextRoute != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        switch (splashVM.nextRoute) {
          case '/admin':
            Navigator.pushReplacementNamed(context, '/admin');
            break;
          case '/online':
            Navigator.pushReplacementNamed(context, '/online');
            break;
          case '/client':
            Navigator.pushReplacementNamed(context, '/client');
            break;
          default:
            Navigator.pushReplacementNamed(context, '/login');
        }
      });
    }
  }

  @override
  void dispose() {
    splashVM.removeListener(_handleNavigation);
    splashVM.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Capturamos el color primario del tema
    final primaryColor = Theme.of(context).colorScheme.primary;

    return ChangeNotifierProvider.value(
      value: splashVM,
      child: Consumer<SplashViewModel>(
        builder: (context, vm, child) {
          return Scaffold(
            body: ScreenUtilInit(
              designSize: const Size(360, 690),
              builder: (context, child) {
                return Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      // CAMBIO: Gradiente Teal consistente con el Login
                      colors: [
                        primaryColor.withOpacity(0.6), 
                        primaryColor,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ScaleTransition(
                          scale: vm.scaleAnimation,
                          child: Image.asset(
                            'assets/images/NewLifeLogo2026.png',
                            height: 200.h,
                            width: 200.w,
                          ),
                        ),
                        SizedBox(height: 30.h),
                        const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                        SizedBox(height: 20.h),
                        AnimatedOpacity(
                          opacity: vm.hasError ? 0.0 : 1.0,
                          duration: const Duration(milliseconds: 300),
                          child: const Text(
                            'Iniciando sesión...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}