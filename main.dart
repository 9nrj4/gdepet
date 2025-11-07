import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:gde_pet/features/auth/welcome_screen.dart';
import 'package:gde_pet/features/main_nav_shell.dart';
import 'package:gde_pet/providers/auth_provider.dart';
import 'package:gde_pet/providers/profile_provider.dart';
import 'package:gde_pet/providers/pet_provider.dart';
import 'package:gde_pet/providers/favorites_provider.dart';
import 'package:gde_pet/firebase_options.dart';
import 'package:gde_pet/features/auth/email_verification_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => PetProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          scaffoldBackgroundColor: const Color(0xFFF9E1E1),
          fontFamily: 'Roboto',
          textTheme: const TextTheme(
            displayLarge: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E1E1E),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30.0),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 18.0,
              horizontal: 25.0,
            ),
          ),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _hasInitialized = false;
  String? _lastUid;
  bool _isWaitingForProfile = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final profileProvider = context.watch<ProfileProvider>();

    if (authProvider.isAuthenticated) {
      final user = authProvider.user!;
      final isEmailPasswordUser = user.providerData.any((p) => p.providerId == 'password');

      // Проверка верификации email для пользователей с email/password
      if (isEmailPasswordUser && !user.emailVerified) {
        _hasInitialized = false;
        _lastUid = null;
        _isWaitingForProfile = false;
        return const EmailVerificationScreen();
      }

      // Инициализируем данные только один раз или при смене пользователя
      if (!_hasInitialized || _lastUid != user.uid) {
        print("AuthWrapper: Initializing data for user ${user.uid}");
        _hasInitialized = true;
        _lastUid = user.uid;
        _isWaitingForProfile = true;
        
        // Подписываемся на профиль
        profileProvider.subscribeToProfile(user.uid);
        
        // Загружаем избранное
        final favoritesProvider = context.read<FavoritesProvider>();
        favoritesProvider.loadFavorites(user.uid);
        
        // ИСПРАВЛЕНИЕ: Устанавливаем таймаут для загрузки профиля
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted && _isWaitingForProfile && profileProvider.profile == null) {
            print("AuthWrapper: Profile loading timeout, forcing navigation");
            setState(() {
              _isWaitingForProfile = false;
            });
          }
        });
      }

      // ИСПРАВЛЕНИЕ: Показываем главный экран если:
      // 1. Профиль загружен
      // 2. ИЛИ прошел таймаут ожидания
      if (profileProvider.profile != null || !_isWaitingForProfile) {
        if (profileProvider.profile != null) {
          print("AuthWrapper: Profile loaded successfully");
        } else {
          print("AuthWrapper: Proceeding without profile (timeout)");
        }
        return const MainNavShell();
      }

      // Показываем загрузку
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Color(0xFFEE8A9A),
              ),
              SizedBox(height: 16),
              Text(
                'Загрузка профиля...',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // Пользователь не авторизован
    _hasInitialized = false;
    _lastUid = null;
    _isWaitingForProfile = false;
    return const WelcomeScreen();
  }
}