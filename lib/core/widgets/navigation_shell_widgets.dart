import 'package:flutter/material.dart';
import 'profile_avatar.dart';

class CustomNavigationBar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;

  const CustomNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  @override
  State<CustomNavigationBar> createState() => _CustomNavigationBarState();
}

class _CustomNavigationBarState extends State<CustomNavigationBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _indexAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    // Start at current index with no animation
    final idx = widget.selectedIndex.toDouble();
    _indexAnim = Tween<double>(begin: idx, end: idx).animate(_controller);
  }

  @override
  void didUpdateWidget(CustomNavigationBar old) {
    super.didUpdateWidget(old);
    if (old.selectedIndex != widget.selectedIndex) {
      // Grab the CURRENT animated position as the new start
      final currentPos = _indexAnim.value;
      _indexAnim = Tween<double>(
        begin: currentPos,
        end: widget.selectedIndex.toDouble(),
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutCubic,
      ));
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final count = widget.destinations.length;

    const double navHeight = 76.0;
    const double indicatorHeight = 54.0;
    const double hPad = 4.0; // inner side padding per edge

    return SafeArea(
      top: false,
      child: Padding(
        // Outer margin gives the "floating" gap from screen edges and bottom
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Container(
          height: navHeight,
          decoration: BoxDecoration(
            color: isDark
                ? theme.colorScheme.surfaceContainerHigh
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.40),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.11),
                blurRadius: 28,
                spreadRadius: -2,
                offset: const Offset(0, 8),
              ),
              // Subtle top glow for depth
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.04),
                blurRadius: 12,
                spreadRadius: 0,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: AnimatedBuilder(
              animation: _indexAnim,
              builder: (context, _) {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final totalWidth = constraints.maxWidth;
                    // Leave hPad on each side for inner breathing room
                    final usableWidth = totalWidth - hPad * 2;
                    final itemWidth = usableWidth / count;
                    final indicatorWidth = itemWidth * 0.90;
                    final indicatorLeft = hPad +
                        (_indexAnim.value * itemWidth) +
                        (itemWidth - indicatorWidth) / 2;

                    return Stack(
                      children: [
                        // ── Sliding pill ──
                        Positioned(
                          left: indicatorLeft,
                          top: (navHeight - indicatorHeight) / 2,
                          child: Container(
                            width: indicatorWidth,
                            height: indicatorHeight,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                        ),

                        // ── Tab items ──
                        Positioned.fill(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: hPad),
                            child: Row(
                              children: List.generate(count, (index) {
                                final dest = widget.destinations[index];
                                final isSelected =
                                    index == widget.selectedIndex;
                                final color = isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.58);

                                return Expanded(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () =>
                                        widget.onDestinationSelected(index),
                                    child: SizedBox(
                                      height: navHeight,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          AnimatedSwitcher(
                                            duration: const Duration(
                                                milliseconds: 280),
                                            child: Icon(
                                              isSelected
                                                  ? _resolveSelectedIcon(dest)
                                                  : _resolveIcon(dest),
                                              key: ValueKey(
                                                  'icon_${index}_$isSelected'),
                                              size: 23,
                                              color: color,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          AnimatedDefaultTextStyle(
                                            duration: const Duration(
                                                milliseconds: 280),
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: isSelected
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                              color: color,
                                              letterSpacing: 0,
                                              height: 1.0,
                                            ),
                                            child: Text(
                                              _resolveLabel(dest),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  IconData _resolveIcon(NavigationDestination dest) {
    final w = dest.icon;
    if (w is Icon) return w.icon ?? Icons.circle;
    return Icons.circle;
  }

  IconData _resolveSelectedIcon(NavigationDestination dest) {
    final w = dest.selectedIcon ?? dest.icon;
    if (w is Icon) return w.icon ?? Icons.circle;
    return Icons.circle;
  }

  String _resolveLabel(NavigationDestination dest) => dest.label;
}


class CustomNavigationRail extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationRailDestination> destinations;
  final Widget? leading;
  final Widget? trailing;

  const CustomNavigationRail({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    this.leading,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      backgroundColor: theme.colorScheme.surface,
      elevation: 0,
      indicatorColor: theme.colorScheme.primary.withValues(alpha: 0.1),
      labelType: NavigationRailLabelType.none,
      leading: leading,
      trailing: trailing,
      destinations: destinations,
    );
  }
}

class CustomSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<SidebarItem> items;
  final String activeOrgName;
  final VoidCallback? onOrgSwitch;
  final VoidCallback? onSettingsPressed;

  const CustomSidebar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.items,
    this.activeOrgName = 'Fraylon Technologies',
    this.onOrgSwitch,
    this.onSettingsPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 250,
      color: isDark ? theme.colorScheme.surface : const Color(0xFFF1F5F9), // Soft Sidebar grey
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Org / Workspace Switcher
          InkWell(
            onTap: onOrgSwitch,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 24,
                        height: 24,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      activeOrgName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: -0.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.unfold_more_rounded,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Menu navigation items
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = index == selectedIndex;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: InkWell(
                    onTap: () => onDestinationSelected(index),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary.withValues(alpha: 0.08)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? item.selectedIcon : item.icon,
                            size: 18,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item.label,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          if (item.badgeCount != null && item.badgeCount! > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                item.badgeCount!.toString(),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Profile / Quick Configuration Footer
          const Divider(height: 24),
          ProfileCard(
            name: 'Vigneswar Nalluri',
            email: 'vignesh@fraylontech.com',
            role: 'Lead Architect',
            onSettingsPressed: onSettingsPressed,
          ),
        ],
      ),
    );
  }
}

class SidebarItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final int? badgeCount;

  const SidebarItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    this.badgeCount,
  });
}
