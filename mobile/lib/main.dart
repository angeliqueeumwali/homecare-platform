import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mobile/constants/app_config.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/providers/service_provider.dart';
import 'package:mobile/providers/provider_viewmodel.dart';
import 'package:mobile/services/api_client.dart';
import 'package:mobile/services/assignment_service.dart';
import 'package:mobile/services/notification_service.dart';
import 'package:mobile/services/payment_service.dart';
import 'package:mobile/services/provider_service.dart';
import 'package:mobile/services/quote_service.dart';
import 'package:mobile/services/service_category_service.dart';
import 'package:mobile/services/service_request_service.dart';
import 'package:mobile/theme/colors.dart';
import 'package:mobile/screens/auth/auth_screens.dart';
import 'package:mobile/screens/auth/login_register_screens.dart';
import 'package:mobile/screens/customer/notification_screen.dart';
import 'package:mobile/screens/customer/payment_screen.dart';

import 'package:mobile/screens/customer/quotes_screen.dart';
import 'package:mobile/screens/customer/request_detail_screen.dart';
import 'package:mobile/screens/customer/request_history_screen.dart';
import 'package:mobile/screens/customer/service_categories_screen.dart';
import 'package:mobile/screens/customer/service_request_screen.dart';
import 'package:mobile/screens/main_navigation.dart';
import 'package:mobile/screens/provider/provider_dashboard.dart';
import 'package:mobile/models/service_request_model.dart';
import 'package:mobile/providers/review_viewmodel.dart';
import 'package:mobile/services/review_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HomecareApp());
}

class HomecareApp extends StatelessWidget {
  const HomecareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ProxyProvider<AuthProvider, ApiClient>(
          update: (_, auth, __) => auth.apiClient,
        ),
        ChangeNotifierProxyProvider<ApiClient, ServiceCategoryViewModel>(
          create: (context) => ServiceCategoryViewModel(
            ServiceCategoryService(
              Provider.of<ApiClient>(context, listen: false),
            ),
          ),
          update: (_, apiClient, __) =>
              ServiceCategoryViewModel(ServiceCategoryService(apiClient)),
        ),
        ChangeNotifierProxyProvider<ApiClient, ServiceRequestViewModel>(
          create: (context) => ServiceRequestViewModel(
            ServiceRequestService(
              Provider.of<ApiClient>(context, listen: false),
            ),
          ),
          update: (_, apiClient, __) =>
              ServiceRequestViewModel(ServiceRequestService(apiClient)),
        ),
        ChangeNotifierProxyProvider<ApiClient, ProviderViewModel>(
          create: (context) => ProviderViewModel(
            ProviderService(Provider.of<ApiClient>(context, listen: false)),
            AssignmentService(Provider.of<ApiClient>(context, listen: false)),
            QuoteService(Provider.of<ApiClient>(context, listen: false)),
          ),
          update: (_, apiClient, __) => ProviderViewModel(
            ProviderService(apiClient),
            AssignmentService(apiClient),
            QuoteService(apiClient),
          ),
        ),
        ChangeNotifierProxyProvider<ApiClient, PaymentViewModel>(
          create: (context) => PaymentViewModel(
            PaymentService(Provider.of<ApiClient>(context, listen: false)),
          ),
          update: (_, apiClient, __) =>
              PaymentViewModel(PaymentService(apiClient)),
        ),
        ChangeNotifierProxyProvider<ApiClient, NotificationViewModel>(
          create: (context) => NotificationViewModel(
            NotificationService(Provider.of<ApiClient>(context, listen: false)),
          ),
          update: (_, apiClient, __) =>
              NotificationViewModel(NotificationService(apiClient)),
        ),
        ChangeNotifierProxyProvider<ApiClient, QuoteViewModel>(
          create: (context) => QuoteViewModel(
            QuoteService(Provider.of<ApiClient>(context, listen: false)),
          ),
          update: (_, apiClient, __) => QuoteViewModel(QuoteService(apiClient)),
        ),
        ChangeNotifierProxyProvider<ApiClient, ReviewViewModel>(
          create: (context) => ReviewViewModel(
            ReviewService(Provider.of<ApiClient>(context, listen: false)),
          ),
          update: (_, apiClient, __) =>
              ReviewViewModel(ReviewService(apiClient)),
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return MaterialApp(
            title: AppStrings.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            initialRoute: '/',
            onGenerateRoute: (settings) {
              if (settings.name == '/') {
                return MaterialPageRoute(
                  builder: (_) => const SplashScreenWrapper(),
                );
              }
              if (settings.name?.startsWith('/request/') == true) {
                final id = settings.name!.split('/').last;
                return MaterialPageRoute(
                  builder: (_) => ServiceRequestDetailScreen(requestId: id),
                );
              }
              if (settings.name == '/service-request') {
                // A service chosen on a details screen is passed in so the
                // first item is pre-filled.
                final args = settings.arguments;
                return MaterialPageRoute(
                  builder: (_) => ServiceRequestScreen(
                    preselectedCategory: args is ServiceCategoryModel
                        ? args
                        : null,
                  ),
                );
              }
              if (settings.name?.startsWith('/assignment/') == true) {
                final id = settings.name!.split('/').last;
                return MaterialPageRoute(
                  builder: (_) => AssignmentDetailScreen(assignmentId: id),
                );
              }
              if (settings.name == '/quotes') {
                return MaterialPageRoute(builder: (_) => const QuotesScreen());
              }
              if (settings.name?.startsWith('/quotes/') == true) {
                final id = settings.name!.split('/').last;
                return MaterialPageRoute(
                  builder: (_) => QuotesScreen(requestId: id),
                );
              }
              return null;
            },
            routes: {
              '/onboarding': (context) => const OnboardingScreen(),
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/customer': (context) => const MainNavigationScreen(),
              '/payments': (context) => const PaymentScreen(),
              '/notifications': (context) => const NotificationScreen(),
              '/request-list': (context) => const ServiceRequestHistoryScreen(),
              '/categories': (context) => const ServiceCategoriesScreen(),
              '/provider/profile': (context) => const ProviderProfileScreen(),
              '/provider/services': (context) => const ProviderServicesScreen(),
              '/provider/location': (context) => const ProviderLocationScreen(),
            },
          );
        },
      ),
    );
  }
}

class SplashScreenWrapper extends StatefulWidget {
  const SplashScreenWrapper({super.key});

  @override
  State<SplashScreenWrapper> createState() => _SplashScreenWrapperState();
}

class _SplashScreenWrapperState extends State<SplashScreenWrapper> {
  @override
  void initState() {
    super.initState();
    _checkInitialState();
  }

  Future<void> _checkInitialState() async {
    await Future.delayed(const Duration(seconds: 2));
    final auth = context.read<AuthProvider>();
    await auth.init();

    if (!mounted) return;
    if (!auth.isAuthenticated) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } else {
      Navigator.pushNamedAndRemoveUntil(context, '/customer', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}
