import 'package:flutter/material.dart';
import 'package:ltdd/widgets/navigation_provider.dart';

class HamburgerMenuButton extends StatelessWidget {
  const HamburgerMenuButton({super.key});

  void _showNavigationMenu(BuildContext context) {
    final provider = NavigationProvider.of(context);
    if (provider == null) return;

    final RenderBox? buttonBox = context.findRenderObject() as RenderBox?;
    if (buttonBox == null) return;

    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final Offset buttonPosition = buttonBox.localToGlobal(Offset.zero);
    
    // Calculate position - align menu to the right of the button
    final double menuWidth = 200.0;
    final double left = buttonPosition.dx + buttonBox.size.width - menuWidth;
    final double top = buttonPosition.dy + buttonBox.size.height + 8;
    final double right = overlay.size.width - left - menuWidth;
    final double bottom = overlay.size.height - top;
    
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(left, top, right, bottom),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: const Color(0xFF1A1A1A),
      elevation: 8,
      items: provider.isAdmin ? _buildAdminMenuItems(provider, context) : _buildUserMenuItems(provider, context),
    );
  }

  List<PopupMenuEntry<void>> _buildUserMenuItems(NavigationProvider provider, BuildContext context) {
    final currentIndex = provider.currentIndex;
    
    return [
      _buildMenuItem(
        context: context,
        icon: Icons.home,
        label: 'Trang Chủ',
        index: 0,
        currentIndex: currentIndex,
        onTap: () {
          provider.navigateTo(0);
          Navigator.pop(context);
        },
      ),
      _buildMenuItem(
        context: context,
        icon: Icons.person,
        label: 'Hồ Sơ',
        index: 1,
        currentIndex: currentIndex,
        onTap: () {
          provider.navigateTo(1);
          Navigator.pop(context);
        },
      ),
    ];
  }

  List<PopupMenuEntry<void>> _buildAdminMenuItems(NavigationProvider provider, BuildContext context) {
    final currentIndex = provider.currentIndex;
    
    return [
      _buildMenuItem(
        context: context,
        icon: Icons.home,
        label: 'Trang Chủ',
        index: 0,
        currentIndex: currentIndex,
        onTap: () {
          provider.navigateTo(0);
          Navigator.pop(context);
        },
      ),
      _buildMenuItem(
        context: context,
        icon: Icons.dashboard,
        label: 'Quản Lý',
        index: 1,
        currentIndex: currentIndex,
        onTap: () {
          provider.navigateTo(1);
          Navigator.pop(context);
        },
      ),
      _buildMenuItem(
        context: context,
        icon: Icons.person,
        label: 'Hồ Sơ',
        index: 2,
        currentIndex: currentIndex,
        onTap: () {
          provider.navigateTo(2);
          Navigator.pop(context);
        },
      ),
    ];
  }

  PopupMenuItem<void> _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required int index,
    required int currentIndex,
    required VoidCallback onTap,
  }) {
    final isActive = currentIndex == index;
    
    return PopupMenuItem<void>(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                color: isActive ? const Color(0xFFE50914) : Colors.white70,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isActive ? const Color(0xFFE50914) : Colors.white,
                    fontSize: 16,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              if (isActive)
                const Icon(
                  Icons.check,
                  color: Color(0xFFE50914),
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showNavigationMenu(context),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: const Icon(
          Icons.menu,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}

