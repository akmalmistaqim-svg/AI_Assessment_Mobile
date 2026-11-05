import 'package:flutter/material.dart';

class DexaBrand extends StatelessWidget {
  const DexaBrand({super.key});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          'assets/brand/dexa-mark.png',
          width: 44,
          height: 44,
          filterQuality: FilterQuality.high,
          excludeFromSemantics: true,
        ),
      ),
      const SizedBox(width: 12),
      const Expanded(
        child: Text(
          'Dexa Assessment',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 19,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
      ),
    ],
  );
}

class StudentAuthHeader extends StatelessWidget {
  const StudentAuthHeader({
    super.key,
    required this.registering,
    required this.onSwitch,
  });

  final bool registering;
  final VoidCallback? onSwitch;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    Widget tab(String label, bool selected, {Key? key}) {
      return Expanded(
        child: Semantics(
          selected: selected,
          button: true,
          child: InkWell(
            key: key,
            onTap: selected ? null : onSwitch,
            child: Container(
              alignment: Alignment.center,
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    width: selected ? 3 : 1,
                    color: selected ? colors.primary : colors.outlineVariant,
                  ),
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? colors.primary : colors.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DexaBrand(),
        const SizedBox(height: 20),
        Row(
          children: [
            tab('Masuk', !registering),
            tab(
              'Daftar',
              registering,
              key: registering ? null : const Key('student-open-register'),
            ),
          ],
        ),
      ],
    );
  }
}
