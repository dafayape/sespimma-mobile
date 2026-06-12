import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:ui';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:talker_bloc_logger/talker_bloc_logger.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/utils/app_logger.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/pages/forgot_password_screen.dart';
import 'features/auth/presentation/pages/login_screen.dart';
import 'features/auth/presentation/pages/reset_password_screen.dart';
import 'features/auth/presentation/pages/splash_screen.dart';
import 'features/auth/presentation/pages/edit_profile_screen.dart';
import 'features/auth/presentation/pages/help_faq_screen.dart';
import 'features/report/presentation/pages/report_screen.dart';
import 'features/attendance/presentation/pages/attendance_screen.dart';
import 'features/attendance/presentation/pages/scan_qr_screen.dart';
import 'features/assignment/presentation/pages/assignment_detail_screen.dart';
import 'features/assignment/presentation/pages/create_task_screen.dart';
import 'features/assignment/presentation/pages/monitoring_task_screen.dart';
import 'features/assessment/presentation/widgets/lookup_selection_dialog.dart';
import 'features/leadership_report/presentation/pages/leadership_report_screen.dart';
import 'features/leadership_dashboard/presentation/pages/pimpinan_home_screen.dart';
import 'features/assessment/presentation/pages/serdik_sosiometri_screen.dart';
import 'shared/widgets/main_nav_screen.dart';
import 'injection_container.dart' as di;

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    talker.handle(details.exception, details.stack);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    talker.handle(error, stack);
    return true;
  };

  Bloc.observer = TalkerBlocObserver(talker: talker);
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  await dotenv.load(fileName: ".env");

  await initializeDateFormatting('id_ID', null);

  await di.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [BlocProvider(create: (_) => di.sl<AuthBloc>())],
      child: MaterialApp(
        title: 'SESPIMMA',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF001C40),
            primary: const Color(0xFF001C40),
          ),
          scaffoldBackgroundColor: const Color(0xFFF8F9FA),
          fontFamily: 'Inter',
          appBarTheme: const AppBarTheme(
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
              systemNavigationBarColor: Colors.white,
              systemNavigationBarIconBrightness: Brightness.dark,
              systemNavigationBarDividerColor: Colors.transparent,
            ),
          ),
        ),
        home: TalkerWrapper(talker: talker, child: const SplashScreen()),
        builder: (context, child) {
          return TalkerWrapper(
            talker: talker,
            child: child ?? const SizedBox(),
          );
        },
        routes: {
          '/login': (context) => const LoginScreen(),
          '/forgot-password': (context) => const ForgotPasswordScreen(),
          '/reset-password': (context) => const ResetPasswordScreen(),
          '/main': (context) => const MainNavigationScreen(),
          '/edit-profile': (context) => const EditProfileScreen(),
          '/help-faq': (context) => const HelpFaqScreen(),
          '/report': (context) => const ReportScreen(),
          '/attendance': (context) => const AttendanceScreen(),
          '/scan-qr': (context) => const ScanQrScreen(),
          '/assignment-detail': (context) => const AssignmentDetailScreen(),
          '/buat-tugas': (context) => const CreateTaskScreen(),
          '/monitoring-tugas': (context) => const MonitoringTaskScreen(),
          '/lookup-selection': (context) => const LookupSelectionDialog(),
          '/leadership-report': (context) => const LeadershipReportScreen(),
          '/pimpinan-home': (context) => const PimpinanHomeScreen(),
          '/serdik-sosiometri': (context) => const SerdikSosiometriScreen(),
        },
      ),
    );
  }
}
