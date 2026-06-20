import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/services/subscription_service.dart';
import '../../../../core/services/currency_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/subscription_provider.dart';

// ── Datos de planes ───────────────────────────────────────────────────────────

class _Plan {
  final String id;
  final double usdPrice;
  final String? badge;
  const _Plan({required this.id, required this.usdPrice, this.badge});
}

const _plans = [
  _Plan(id: 'monthly', usdPrice: 9.99),
  _Plan(id: 'annual', usdPrice: 79.99, badge: 'save33'),
];

// ── Benefits ──────────────────────────────────────────────────────────────────

const _benefits = [
  (Icons.auto_awesome, 'unlimitedAI', 'unlimitedAIDesc'),
  (Icons.content_cut, 'hairstyleRec', 'hairstyleRecDesc'),
  (Icons.face_retouching_natural, 'virtualTryOn', 'virtualTryOnDesc'),
  (Icons.star_outline, 'priorityAccess', 'priorityAccessDesc'),
];

String _benefitTitle(AppLocalizations l, String key) {
  switch (key) {
    case 'unlimitedAI':
      return l.unlimitedAI;
    case 'hairstyleRec':
      return l.hairstyleRec;
    case 'virtualTryOn':
      return l.virtualTryOn;
    default:
      return l.priorityAccess;
  }
}

String _benefitDesc(AppLocalizations l, String key) {
  switch (key) {
    case 'unlimitedAIDesc':
      return l.unlimitedAIDesc;
    case 'hairstyleRecDesc':
      return l.hairstyleRecDesc;
    case 'virtualTryOnDesc':
      return l.virtualTryOnDesc;
    default:
      return l.priorityAccessDesc;
  }
}

// ── Page ──────────────────────────────────────────────────────────────────────

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  String _selectedPlan = 'annual';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubscriptionProvider>().loadStatus();
    });
  }

  Future<void> _subscribe() async {
    final provider = context.read<SubscriptionProvider>();
    final ok = await provider.startCheckout(_selectedPlan);
    if (!mounted) return;

    final l = AppLocalizations.of(context)!;
    if (ok) {
      _showSnack(l.premiumActive, success: true);
    } else if (provider.checkoutError != null) {
      _showSnack(provider.checkoutError!);
      provider.resetCheckout();
    }
  }

  void _showSnack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: success ? AppPalette.success : AppPalette.error,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.subscriptionTitle)),
      body: Consumer<SubscriptionProvider>(
        builder: (context, provider, _) {
          if (provider.isLoadingStatus) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.isPremium) {
            return _PremiumActiveView(info: provider.info);
          }

          return _UpgradeView(
            selectedPlan: _selectedPlan,
            onPlanChanged: (p) => setState(() => _selectedPlan = p),
            onSubscribe: _subscribe,
            isLoading: provider.checkoutState == CheckoutState.loadingCheckout ||
                provider.checkoutState == CheckoutState.processingPayment,
            statusLabel: _statusLabel(l, provider.info.status),
          );
        },
      ),
    );
  }

  String _statusLabel(AppLocalizations l, String status) {
    switch (status) {
      case 'PAST_DUE':
        return l.pastDue;
      case 'CANCELLED':
        return l.cancelledPlan;
      default:
        return l.freePlan;
    }
  }
}

// ── Vista: usuario FREE / CANCELLED / PAST_DUE ────────────────────────────────

class _UpgradeView extends StatelessWidget {
  final String selectedPlan;
  final ValueChanged<String> onPlanChanged;
  final VoidCallback onSubscribe;
  final bool isLoading;
  final String statusLabel;

  const _UpgradeView({
    required this.selectedPlan,
    required this.onPlanChanged,
    required this.onSubscribe,
    required this.isLoading,
    required this.statusLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);

    return SingleChildScrollView(
      child: Column(
        children: [
          _HeroHeader(statusLabel: statusLabel),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 28),

                // ── Beneficios ────────────────────────────────────────
                Text(
                  l.whatsIncluded,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ..._benefits.map(
                  (b) => _BenefitTile(
                    icon: b.$1,
                    title: _benefitTitle(l, b.$2),
                    subtitle: _benefitDesc(l, b.$3),
                  ),
                ),

                const SizedBox(height: 32),

                // ── Selector de plan ──────────────────────────────────
                Text(
                  l.choosePlan,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: _plans
                      .map(
                        (p) => Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: p.id == 'monthly' ? 8 : 0,
                              left: p.id == 'annual' ? 8 : 0,
                            ),
                            child: _PlanCard(
                              plan: p,
                              selected: selectedPlan == p.id,
                              locale: locale,
                              onTap: () => onPlanChanged(p.id),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),

                // ── Nota de moneda ────────────────────────────────────
                if (CurrencyService.infoForLocale(locale).code != 'USD') ...[
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      l.chargedUSD,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.45),
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],

                const SizedBox(height: 28),

                // ── CTA ───────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: isLoading ? null : onSubscribe,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            l.subscribeNow,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 12),
                Center(
                  child: Text(
                    l.securePayment,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.55),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 36),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Vista: usuario PREMIUM ─────────────────────────────────────────────────────

class _PremiumActiveView extends StatelessWidget {
  final SubscriptionInfo info;
  const _PremiumActiveView({required this.info});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: AppPalette.accentGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppPalette.accent.withValues(alpha: 0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.workspace_premium,
              color: Colors.white,
              size: 48,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l.premiumActive,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (info.currentPeriodEnd != null)
            Text(
              l.planRenews(_formatDate(info.currentPeriodEnd!)),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              ),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 32),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.activeBenefits,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ..._benefits.map(
                    (b) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Icon(b.$1, color: AppPalette.accent, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _benefitTitle(l, b.$2),
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                          const Icon(
                            Icons.check_circle,
                            color: AppPalette.success,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    return '${dt.day} de ${months[dt.month - 1]} de ${dt.year}';
  }
}

// ── Hero header ───────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  final String statusLabel;
  const _HeroHeader({required this.statusLabel});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 36),
      decoration: BoxDecoration(gradient: AppPalette.accentGradient),
      child: Column(
        children: [
          const Icon(Icons.workspace_premium, color: Colors.white, size: 56),
          const SizedBox(height: 12),
          Text(
            l.premiumTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusLabel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Benefit tile ──────────────────────────────────────────────────────────────

class _BenefitTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _BenefitTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppPalette.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppPalette.accent, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Plan card con precio en moneda local ──────────────────────────────────────

class _PlanCard extends StatelessWidget {
  final _Plan plan;
  final bool selected;
  final Locale locale;
  final VoidCallback onTap;

  const _PlanCard({
    required this.plan,
    required this.selected,
    required this.locale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

    final label = plan.id == 'monthly' ? l.monthly : l.annual;
    final period = plan.id == 'monthly' ? l.perMonth : l.perYear;
    final usdText =
        '\$${plan.usdPrice.toStringAsFixed(2)}';
    final badge = plan.badge == 'save33' ? l.save33 : null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.3),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (badge != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppPalette.success,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Text(
              label,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              usdText,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
              ),
            ),
            Text(
              period,
              style: theme.textTheme.bodySmall?.copyWith(
                color:
                    theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            // Precio en moneda local
            FutureBuilder<ConvertedPrice?>(
              future: CurrencyService.convert(plan.usdPrice, locale),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: SizedBox(
                      height: 12,
                      width: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.4),
                      ),
                    ),
                  );
                }
                final price = snap.data;
                if (price == null || !price.isConverted) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    l.approxLocal(price.formatted, price.currencyCode),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.5),
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
