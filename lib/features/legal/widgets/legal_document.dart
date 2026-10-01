import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../ui/primitives/primitives.dart';
import '../../../ui/components/glass_page_scaffold.dart';

class LegalSection {
  const LegalSection({required this.title, required this.content});

  final String title;
  final String content;
}

/// Editorial reading layout for legal documents: a narrow (680px) measure,
/// numbered eyebrow section labels and generous line height.
class LegalDocument extends StatelessWidget {
  const LegalDocument({
    super.key,
    required this.title,
    required this.lastUpdated,
    required this.sections,
    required this.disclaimer,
  });

  static const double _measure = 680;

  final String title;
  final String lastUpdated;
  final List<LegalSection> sections;
  final String disclaimer;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final s = AppSurfaces.of(context);

    return GlassPageScaffold(
      eyebrow: 'Legal',
      title: title,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppTokens.space6,
          AppTokens.space8,
          AppTokens.space6,
          AppTokens.space12 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _measure),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: t.displaySmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -1),
                ),
                const SizedBox(height: AppTokens.space3),
                Text(
                  'Last updated: $lastUpdated',
                  style: t.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: AppTokens.space6),
                Divider(height: 1, color: s.microBorderStrong),
                const SizedBox(height: AppTokens.space8),
                for (var i = 0; i < sections.length; i++)
                  StaggerIn(
                    index: i,
                    child: _LegalSectionView(number: i + 1, section: sections[i]),
                  ),
                const SizedBox(height: AppTokens.space4),
                GlassPanel(
                  padding: const EdgeInsets.all(AppTokens.space4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: StatusDot(color: AppColorScheme.snackWarning),
                      ),
                      const SizedBox(width: AppTokens.space3),
                      Expanded(
                        child: Text(
                          disclaimer,
                          style: t.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: AppColorScheme.snackWarning,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LegalSectionView extends StatelessWidget {
  const _LegalSectionView({required this.number, required this.section});

  final int number;
  final LegalSection section;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.space8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Eyebrow('Section ${number.toString().padLeft(2, '0')}', accent: true),
          const SizedBox(height: AppTokens.space2),
          Text(
            section.title,
            style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3),
          ),
          const SizedBox(height: AppTokens.space3),
          Text(
            section.content,
            style: t.bodyLarge?.copyWith(height: 1.7, color: cs.onSurface.withValues(alpha: 0.86)),
          ),
        ],
      ),
    );
  }
}
