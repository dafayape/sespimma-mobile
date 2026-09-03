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

          final isSiswa = state.user.roleId == 'siswa' && navItems.length == 4;

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
              floatingActionButton: isSiswa ? _buildCenterQrFab() : null,
              floatingActionButtonLocation: isSiswa ? FloatingActionButtonLocation.centerDocked : null,
              bottomNavigationBar: isSiswa
                  ? _buildSiswaBottomBar(safeIndex, navItems)
                  : (navItems.length < 2
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
                        )),
            ),
          );
        }

        return const Scaffold(
          body: Center(child: CircularProgressIndicator(color: _primaryNavy)),
        );
      },
    );
  }

  Widget _buildCenterQrFab() {
    return Container(
      width: 58,
      height: 58,
      margin: const EdgeInsets.only(top: 18),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _primaryNavy,
        border: Border.all(color: Colors.white, width: 3.5),
        boxShadow: [
          BoxShadow(
            color: _primaryNavy.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            HapticFeedback.mediumImpact();
            Navigator.pushNamed(context, '/scan-qr');
          },
          child: const Icon(
            Icons.qr_code_scanner_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }

  Widget _buildSiswaBottomBar(int currentIndex, List<NavItem> navItems) {
    final leftItems = navItems.sublist(0, 2);
    final rightItems = navItems.sublist(2, 4);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        bottom: true,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(leftItems.length, (i) {
                    final item = leftItems[i];
                    final index = i;
                    final isSelected = currentIndex == index;
                    return _buildNavItemButton(item, isSelected, () {
                      setState(() => _currentIndex = index);
                    });
                  }),
                ),
              ),
              const SizedBox(width: 64),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(rightItems.length, (i) {
                    final item = rightItems[i];
                    final index = i + 2;
                    final isSelected = currentIndex == index;
                    return _buildNavItemButton(item, isSelected, () {
                      setState(() => _currentIndex = index);
                    });
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItemButton(NavItem item, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? item.activeIcon : item.icon,
              size: 24,
              color: isSelected ? _primaryNavy : Colors.blueGrey.shade400,
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? _primaryNavy : Colors.blueGrey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
