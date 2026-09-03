import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../utils/nav_items_helper.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  static const Color _primaryNavy = Color(0xFF001C40);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthSuccess) {
          final navItems = getNavItemsByRole(state.user.roleId);
          final safeIndex = _currentIndex >= navItems.length
              ? 0
              : _currentIndex;

          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: const SystemUiOverlayStyle(
              systemNavigationBarColor: Colors.white,
              systemNavigationBarIconBrightness: Brightness.dark,
              systemNavigationBarDividerColor: Colors.transparent,
            ),
            child: Scaffold(
              body: IndexedStack(
                key: ValueKey('nav_stack_${state.user.roleId}'),
                index: safeIndex,
                children: navItems.map((item) {
                  return KeyedSubtree(
                    key: ValueKey(
                      'nav_screen_${item.label}_${state.user.roleId}',
                    ),
                    child: item.screen,
                  );
                }).toList(),
              ),
              bottomNavigationBar: navItems.length < 2
                  ? null
                  : Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        top: false,
                        bottom: true,
                        child: BottomNavigationBar(
                          currentIndex: safeIndex,
                          onTap: (index) {
                            setState(() {
                              _currentIndex = index;
                            });
                          },
                          type: BottomNavigationBarType.fixed,
                          backgroundColor: Colors.white,
                          selectedItemColor: _primaryNavy,
                          unselectedItemColor: Colors.blueGrey.shade400,
                          selectedFontSize: 12,
                          unselectedFontSize: 11,
                          selectedLabelStyle: const TextStyle(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                          unselectedLabelStyle: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                          elevation: 0,
                          items: navItems.map((item) {
                            return BottomNavigationBarItem(
                              icon: Padding(
                                padding: const EdgeInsets.only(
                                  bottom: 6.0,
                                  top: 4.0,
                                ),
                                child: Icon(item.icon, size: 24),
                              ),
                              activeIcon: Padding(
                                padding: const EdgeInsets.only(
                                  bottom: 6.0,
                                  top: 4.0,
                                ),
                                child: Icon(item.activeIcon, size: 24),
                              ),
                              label: item.label,
                            );
                          }).toList(),
                        ),
                      ),
                    ),
            ),
          );
        }

        return const Scaffold(
          body: Center(child: CircularProgressIndicator(color: _primaryNavy)),
        );
      },
    );
  }
}
