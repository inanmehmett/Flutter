import 'package:flutter/material.dart';

class FontSettingsView extends StatelessWidget {
  final double currentFontSize;
  final ValueChanged<double> onFontSizeChanged;
  final ThemeMode currentTheme;
  final ValueChanged<ThemeMode> onThemeChanged;
  final VoidCallback onClose;

  const FontSettingsView({
    super.key,
    required this.currentFontSize,
    required this.onFontSizeChanged,
    required this.currentTheme,
    required this.onThemeChanged,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Reading Settings',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: onClose,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildThemeSection(),
          const SizedBox(height: 24),
          _buildFontSizeSection(),
          const SizedBox(height: 24),
          _buildFontTypeSection(),
        ],
      ),
    );
  }

  Widget _buildThemeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Theme',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ThemeButton(
                icon: Icons.light_mode,
                title: 'Light',
                isSelected: currentTheme == ThemeMode.light,
                onTap: () => onThemeChanged(ThemeMode.light),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _ThemeButton(
                icon: Icons.dark_mode,
                title: 'Dark',
                isSelected: currentTheme == ThemeMode.dark,
                onTap: () => onThemeChanged(ThemeMode.dark),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFontSizeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Text Size',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _FontSizeButton(
              size: 16,
              label: 'Small',
              isSelected: currentFontSize == 16,
              onTap: () => onFontSizeChanged(16),
            ),
            _FontSizeButton(
              size: 20,
              label: 'Medium',
              isSelected: currentFontSize == 20,
              onTap: () => onFontSizeChanged(20),
            ),
            _FontSizeButton(
              size: 24,
              label: 'Large',
              isSelected: currentFontSize == 24,
              onTap: () => onFontSizeChanged(24),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFontTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Font',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SegmentedButton<FontType>(
          segments: FontType.values.map((type) {
            return ButtonSegment<FontType>(
              value: type,
              label: Text(type.displayName),
            );
          }).toList(),
          selected: {FontType.system},
          onSelectionChanged: (Set<FontType> selected) {
            // Handle font type change
          },
        ),
      ],
    );
  }
}

class _ThemeButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeButton({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FontSizeButton extends StatelessWidget {
  final double size;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FontSizeButton({
    required this.size,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              'Aa',
              style: TextStyle(
                fontSize: size,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum FontType {
  system,
  serif,
  monospace;

  String get displayName {
    switch (this) {
      case FontType.system:
        return 'System';
      case FontType.serif:
        return 'Serif';
      case FontType.monospace:
        return 'Monospace';
    }
  }
}
