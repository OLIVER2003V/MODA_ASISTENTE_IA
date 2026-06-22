import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/admin_dashboard_service.dart';
import 'admin_hairstyle_page.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _bg        = Color(0xFF0F1117);
const _surface   = Color(0xFF1A1D2E);
const _surface2  = Color(0xFF232640);
const _border    = Color(0xFF2E3250);
const _textDim   = Color(0xFF8B8FA8);
const _green     = Color(0xFF10B981);
const _red       = Color(0xFFEF4444);
const _blue      = Color(0xFF6366F1);
const _purple    = Color(0xFF8B5CF6);
const _pink      = Color(0xFFEC4899);
const _amber     = Color(0xFFF59E0B);
const _cyan      = Color(0xFF06B6D4);

enum _Section { overview, growth, revenue, engagement, segments, users, hairstyles, activity }

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});
  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  _Section _section = _Section.overview;

  static const _nav = [
    (_Section.overview,    Icons.dashboard_rounded,      'Resumen'),
    (_Section.growth,      Icons.trending_up_rounded,    'Crecimiento'),
    (_Section.revenue,     Icons.attach_money_rounded,   'Ingresos'),
    (_Section.engagement,  Icons.favorite_rounded,       'Engagement'),
    (_Section.segments,    Icons.pie_chart_rounded,      'Segmentación'),
    (_Section.users,       Icons.people_rounded,         'Usuarios'),
    (_Section.hairstyles,  Icons.content_cut,            'Peinados'),
    (_Section.activity,    Icons.history_rounded,        'Bitácora'),
  ];

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width > 860;
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: _bg,
        colorScheme: const ColorScheme.dark(primary: _blue, surface: _surface),
      ),
      child: Scaffold(
        backgroundColor: _bg,
        appBar: wide ? null : AppBar(
          backgroundColor: _surface,
          title: const Text('Admin Panel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        drawer: wide ? null : _Sidebar(current: _section, onSelect: (s) { Navigator.pop(context); setState(() => _section = s); }, nav: _nav),
        body: wide
            ? Row(children: [
                _Sidebar(current: _section, onSelect: (s) => setState(() => _section = s), nav: _nav),
                Expanded(child: _body()),
              ])
            : _body(),
      ),
    );
  }

  Widget _body() => switch (_section) {
    _Section.overview   => const _OverviewTab(),
    _Section.growth     => const _GrowthTab(),
    _Section.revenue    => const _RevenueTab(),
    _Section.engagement => const _EngagementTab(),
    _Section.segments   => const _SegmentsTab(),
    _Section.users      => const _UsersTab(),
    _Section.hairstyles => const AdminHairstylePage(embedded: true),
    _Section.activity   => const _ActivityTab(),
  };
}

// ── Sidebar ───────────────────────────────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.current, required this.onSelect, required this.nav});
  final _Section current;
  final void Function(_Section) onSelect;
  final List<(_Section, IconData, String)> nav;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      color: _surface,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 40),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_blue, _purple]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('ModalA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              Text('Panel Admin', style: TextStyle(color: _textDim, fontSize: 11)),
            ]),
          ]),
        ),
        const SizedBox(height: 28),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 18),
          child: Text('NAVEGACIÓN', style: TextStyle(color: _textDim, fontSize: 10, letterSpacing: 1.5)),
        ),
        const SizedBox(height: 8),
        ...nav.map((t) => _NavItem(icon: t.$2, label: t.$3, selected: current == t.$1, onTap: () => onSelect(t.$1))),
        const Spacer(),
        Container(height: 1, color: _border),
        _NavItem(icon: Icons.arrow_back_rounded, label: 'Volver a la app', selected: false, onTap: () => Navigator.of(context).pop()),
        const SizedBox(height: 16),
      ]),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});
  final IconData icon; final String label; final bool selected; final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: selected ? _blue.withValues(alpha: 0.18) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: selected ? Border.all(color: _blue.withValues(alpha: 0.4)) : null,
      ),
      child: Row(children: [
        Icon(icon, color: selected ? _blue : _textDim, size: 18),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: selected ? Colors.white : _textDim, fontSize: 13, fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
      ]),
    ),
  );
}

// ── Shared scaffold ───────────────────────────────────────────────────────────

class _Tab extends StatelessWidget {
  const _Tab({required this.title, required this.child, this.subtitle, this.onRefresh});
  final String title;
  final String? subtitle;
  final Widget child;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) => Column(children: [
    Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
      color: _surface,
      child: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          if (subtitle != null) Text(subtitle!, style: const TextStyle(color: _textDim, fontSize: 12)),
        ]),
        const Spacer(),
        if (onRefresh != null)
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: _textDim, size: 20),
            onPressed: onRefresh,
            tooltip: 'Actualizar',
          ),
      ]),
    ),
    Container(height: 1, color: _border),
    Expanded(child: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: child,
    )),
  ]);
}

Widget _buildLoader() => const SizedBox(height: 300, child: Center(child: CircularProgressIndicator(color: _blue)));

Widget _buildError(String e, VoidCallback retry) => SizedBox(height: 300, child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
  const Icon(Icons.error_outline, color: _red, size: 48),
  const SizedBox(height: 12),
  Text(e, style: const TextStyle(color: _red), textAlign: TextAlign.center),
  const SizedBox(height: 16),
  ElevatedButton(onPressed: retry, child: const Text('Reintentar')),
])));

// ── KPI card ──────────────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.label, required this.value, required this.icon, required this.color, this.trend});
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final int? trend;

  @override
  Widget build(BuildContext context) {
    final up = (trend ?? 0) >= 0;
    return Container(
      width: 175,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 18),
          ),
          const Spacer(),
          if (trend != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (up ? _green : _red).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, size: 10, color: up ? _green : _red),
                Text('${trend!.abs()}%', style: TextStyle(fontSize: 10, color: up ? _green : _red, fontWeight: FontWeight.bold)),
              ]),
            ),
        ]),
        const SizedBox(height: 14),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: _textDim, fontSize: 12)),
      ]),
    );
  }
}

// ── Bar chart ─────────────────────────────────────────────────────────────────

class _BarChart extends StatelessWidget {
  const _BarChart({required this.labels, required this.series, required this.height});
  final List<String> labels;
  final List<({String name, Color color, List<num> data})> series;
  final double height;

  @override
  Widget build(BuildContext context) {
    final allVals = series.expand((s) => s.data).toList();
    final maxVal = allVals.isEmpty ? 1 : allVals.reduce(math.max);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Legend
      Wrap(spacing: 16, children: series.map((s) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: s.color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(s.name, style: const TextStyle(color: _textDim, fontSize: 11)),
      ])).toList()),
      const SizedBox(height: 12),
      SizedBox(
        height: height,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(labels.length, (i) {
            return Expanded(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                ...series.map((s) {
                  final frac = maxVal == 0 ? 0.0 : (s.data[i] / maxVal).clamp(0.0, 1.0).toDouble();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 400 + i * 20),
                      curve: Curves.easeOut,
                      height: math.max(3.0, frac * (height - 32)),
                      decoration: BoxDecoration(
                        color: s.color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 4),
                Text(labels[i], style: const TextStyle(color: _textDim, fontSize: 8), textAlign: TextAlign.center),
              ]),
            ));
          }),
        ),
      ),
    ]);
  }
}

// ── Donut chart ───────────────────────────────────────────────────────────────

class _DonutChart extends StatelessWidget {
  const _DonutChart({required this.data, required this.colors, required this.size});
  final List<({String label, int value})> data;
  final List<Color> colors;
  final double size;

  @override
  Widget build(BuildContext context) {
    final total = data.fold(0, (s, d) => s + d.value);
    if (total == 0) return const SizedBox.shrink();
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      CustomPaint(size: Size(size, size), painter: _DonutPainter(data: data, colors: colors, total: total)),
      const SizedBox(width: 16),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(data.length, (i) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: colors[i % colors.length], shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Expanded(child: Text(data[i].label, style: const TextStyle(color: _textDim, fontSize: 11), overflow: TextOverflow.ellipsis)),
            Text('${(data[i].value / total * 100).toStringAsFixed(1)}%', style: TextStyle(color: colors[i % colors.length], fontSize: 11, fontWeight: FontWeight.bold)),
          ]),
        )),
      )),
    ]);
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({required this.data, required this.colors, required this.total});
  final List<({String label, int value})> data;
  final List<Color> colors;
  final int total;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    double start = -math.pi / 2;
    for (int i = 0; i < data.length; i++) {
      final sweep = (data[i].value / total) * 2 * math.pi;
      canvas.drawArc(rect, start, sweep, false, Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.18
        ..strokeCap = StrokeCap.butt);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_) => true;
}

// ── Section card ──────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  const _Card({required this.child, this.title, this.padding = const EdgeInsets.all(18)});
  final Widget child;
  final String? title;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (title != null) Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
        child: Text(title!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
      ),
      if (title != null) const SizedBox(height: 12),
      Padding(padding: padding, child: child),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  OVERVIEW TAB
// ─────────────────────────────────────────────────────────────────────────────

class _OverviewTab extends StatefulWidget {
  const _OverviewTab();
  @override State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  AdminStats? _stats;
  Map<String, dynamic>? _metrics;
  bool _loading = true; String? _error;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final r = await Future.wait([AdminDashboardService.getStats(), AdminDashboardService.getMetrics()]);
      if (mounted) setState(() { _stats = r[0] as AdminStats; _metrics = r[1] as Map<String, dynamic>; _loading = false; });
    } catch (e) { if (mounted) setState(() { _error = e.toString(); _loading = false; }); }
  }

  @override
  Widget build(BuildContext context) => _Tab(
    title: 'Resumen ejecutivo',
    subtitle: 'Métricas clave del negocio',
    onRefresh: _load,
    child: _loading ? _buildLoader() : _error != null ? _buildError(_error!, _load) : _build(),
  );

  Widget _build() {
    final kpis = _metrics!['kpis'] as Map<String, dynamic>;
    final week = kpis['weekVsPrev'] as Map<String, dynamic>;
    final month = kpis['monthVsPrev'] as Map<String, dynamic>;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Fila 1
      Wrap(spacing: 12, runSpacing: 12, children: [
        _KpiCard(label: 'Usuarios totales',   value: '${_stats!.totalUsers}',        icon: Icons.people_rounded,      color: _blue,   trend: month['users'] as int?),
        _KpiCard(label: 'Premium',            value: '${_stats!.premiumUsers}',      icon: Icons.star_rounded,        color: _amber),
        _KpiCard(label: 'Gratuitos',          value: '${_stats!.freeUsers}',         icon: Icons.person_outline,      color: _textDim),
        _KpiCard(label: 'Nuevos esta semana', value: '${kpis['usersThisWeek']}',     icon: Icons.person_add_rounded,  color: _green,  trend: week['users'] as int?),
        _KpiCard(label: 'Outfits esta semana',value: '${kpis['outfitsThisWeek']}',   icon: Icons.checkroom_rounded,   color: _purple, trend: week['outfits'] as int?),
        _KpiCard(label: 'Posts esta semana',  value: '${kpis['postsThisWeek']}',     icon: Icons.photo_camera_rounded,color: _pink,   trend: week['posts'] as int?),
        _KpiCard(label: 'Peinados catálogo',  value: '${_stats!.totalHairstyles}',   icon: Icons.content_cut,         color: _cyan),
        _KpiCard(label: 'Chats IA',           value: '${_stats!.totalConversations}',icon: Icons.chat_bubble_rounded, color: _blue),
        _KpiCard(label: 'Prendas totales',    value: '${_stats!.totalGarments}',     icon: Icons.style_rounded,       color: _amber),
      ]),
      const SizedBox(height: 24),

      // Hoy
      _Card(title: 'Actividad de hoy', child: Row(children: [
        Expanded(child: _MiniStat('Usuarios nuevos', '${kpis['usersToday']}',   _blue,   Icons.person_add_rounded)),
        Expanded(child: _MiniStat('Outfits generados', '${kpis['outfitsToday']}', _purple, Icons.checkroom_rounded)),
        Expanded(child: _MiniStat('Posts publicados', '${kpis['postsToday']}',  _pink,   Icons.photo_camera_rounded)),
      ])),
    ]);
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(this.label, this.value, this.color, this.icon);
  final String label, value; final Color color; final IconData icon;
  @override
  Widget build(BuildContext context) => Column(children: [
    Icon(icon, color: color, size: 22),
    const SizedBox(height: 6),
    Text(value, style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.bold)),
    const SizedBox(height: 4),
    Text(label, style: const TextStyle(color: _textDim, fontSize: 11), textAlign: TextAlign.center),
  ]);
}

// ─────────────────────────────────────────────────────────────────────────────
//  GROWTH TAB
// ─────────────────────────────────────────────────────────────────────────────

class _GrowthTab extends StatefulWidget {
  const _GrowthTab();
  @override State<_GrowthTab> createState() => _GrowthTabState();
}

class _GrowthTabState extends State<_GrowthTab> {
  Map<String, dynamic>? _data;
  bool _loading = true; String? _error;

  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final d = await AdminDashboardService.getMetrics();
      if (mounted) setState(() { _data = d; _loading = false; });
    } catch (e) { if (mounted) setState(() { _error = e.toString(); _loading = false; }); }
  }

  @override
  Widget build(BuildContext context) => _Tab(
    title: 'Crecimiento',
    subtitle: 'Tendencias de los últimos 30 días',
    onRefresh: _load,
    child: _loading ? _buildLoader() : _error != null ? _buildError(_error!, _load) : _build(),
  );

  Widget _build() {
    final series = _data!['series'] as Map<String, dynamic>;
    final labels  = (series['labels']  as List).cast<String>();
    final users   = (series['users']   as List).map((e) => (e as num)).toList();
    final outfits = (series['outfits'] as List).map((e) => (e as num)).toList();
    final posts   = (series['posts']   as List).map((e) => (e as num)).toList();

    // Mostrar solo cada 3 labels para no amontonar
    final sparseLabels = List.generate(labels.length, (i) => i % 3 == 0 ? labels[i] : '');

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _Card(title: 'Usuarios, outfits y posts — 30 días', child: _BarChart(
        labels: sparseLabels,
        height: 180,
        series: [
          (name: 'Usuarios',  color: _blue,   data: users),
          (name: 'Outfits',   color: _purple, data: outfits),
          (name: 'Posts',     color: _pink,   data: posts),
        ],
      )),
      _Card(title: 'Solo usuarios nuevos', child: _BarChart(
        labels: sparseLabels,
        height: 140,
        series: [(name: 'Usuarios', color: _green, data: users)],
      )),
      _Card(title: 'Outfits generados por día', child: _BarChart(
        labels: sparseLabels,
        height: 140,
        series: [(name: 'Outfits', color: _purple, data: outfits)],
      )),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  REVENUE TAB
// ─────────────────────────────────────────────────────────────────────────────

class _RevenueTab extends StatefulWidget {
  const _RevenueTab();
  @override State<_RevenueTab> createState() => _RevenueTabState();
}

class _RevenueTabState extends State<_RevenueTab> {
  Map<String, dynamic>? _data;
  bool _loading = true; String? _error;

  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final d = await AdminDashboardService.getRevenue();
      if (mounted) setState(() { _data = d; _loading = false; });
    } catch (e) { if (mounted) setState(() { _error = e.toString(); _loading = false; }); }
  }

  @override
  Widget build(BuildContext context) => _Tab(
    title: 'Ingresos',
    subtitle: 'Pagos y conversiones',
    onRefresh: _load,
    child: _loading ? _buildLoader() : _error != null ? _buildError(_error!, _load) : _build(),
  );

  Widget _build() {
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final fmtD = NumberFormat.currency(symbol: '\$');
    final total   = (_data!['totalAllTime']   as num).toDouble();
    final month   = (_data!['totalThisMonth'] as num).toDouble();
    final pct     = _data!['monthVsPrev'] as int;
    final conv    = (_data!['conversionRate'] as num).toDouble();
    final premium = _data!['premiumUsers'] as int;
    final free    = _data!['freeUsers'] as int;
    final recent  = (_data!['recentPayments'] as List).cast<Map<String, dynamic>>();
    final ds      = _data!['dailySeries'] as Map<String, dynamic>;
    final dlabels = (ds['labels'] as List).cast<String>();
    final damounts= (ds['amounts'] as List).map((e) => (e as num)).toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // KPIs
      Wrap(spacing: 12, runSpacing: 12, children: [
        _KpiCard(label: 'Total acumulado',       value: fmt.format(total),  icon: Icons.account_balance_wallet_rounded, color: _green),
        _KpiCard(label: 'Este mes',              value: fmt.format(month),  icon: Icons.calendar_month_rounded,         color: _amber, trend: pct),
        _KpiCard(label: 'Tasa de conversión',    value: '$conv%',           icon: Icons.swap_horiz_rounded,             color: _blue),
        _KpiCard(label: 'Usuarios premium',      value: '$premium',         icon: Icons.star_rounded,                   color: _purple),
      ]),
      const SizedBox(height: 16),

      // Gráfico ingresos 14 días
      _Card(title: 'Ingresos diarios — últimos 14 días', child: _BarChart(
        labels: dlabels,
        height: 140,
        series: [(name: 'USD', color: _green, data: damounts)],
      )),

      // Distribución Free vs Premium
      _Card(title: 'Distribución de plan', child: _DonutChart(
        size: 100,
        data: [
          (label: 'Premium', value: premium),
          (label: 'Free',    value: free),
        ],
        colors: [_amber, _textDim],
      )),

      // Historial de pagos
      _Card(
        title: 'Últimos pagos recibidos',
        padding: EdgeInsets.zero,
        child: Column(children: [
          ...recent.map((p) {
            final amt  = (p['amount'] as num).toDouble();
            final name = (p['userName'] as String?)?.isNotEmpty == true ? p['userName'] as String : p['userEmail'] as String;
            final date = DateTime.parse(p['createdAt'] as String);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _border))),
              child: Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: _green.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.receipt_long_rounded, color: _green, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                  Text(DateFormat('dd/MM/yyyy HH:mm').format(date), style: const TextStyle(color: _textDim, fontSize: 11)),
                ])),
                Text(fmtD.format(amt), style: const TextStyle(color: _green, fontWeight: FontWeight.bold, fontSize: 14)),
              ]),
            );
          }),
          if (recent.isEmpty) const Padding(
            padding: EdgeInsets.all(20),
            child: Text('Sin pagos registrados', style: TextStyle(color: _textDim), textAlign: TextAlign.center),
          ),
        ]),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  ENGAGEMENT TAB
// ─────────────────────────────────────────────────────────────────────────────

class _EngagementTab extends StatefulWidget {
  const _EngagementTab();
  @override State<_EngagementTab> createState() => _EngagementTabState();
}

class _EngagementTabState extends State<_EngagementTab> {
  Map<String, dynamic>? _data;
  bool _loading = true; String? _error;

  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final d = await AdminDashboardService.getEngagement();
      if (mounted) setState(() { _data = d; _loading = false; });
    } catch (e) { if (mounted) setState(() { _error = e.toString(); _loading = false; }); }
  }

  @override
  Widget build(BuildContext context) => _Tab(
    title: 'Engagement',
    subtitle: 'Interacciones y contenido popular',
    onRefresh: _load,
    child: _loading ? _buildLoader() : _error != null ? _buildError(_error!, _load) : _build(),
  );

  Widget _build() {
    final stats     = _data!['stats'] as Map<String, dynamic>;
    final topPosts  = (_data!['topPosts']      as List).cast<Map<String, dynamic>>();
    final topHairs  = (_data!['topHairstyles'] as List).cast<Map<String, dynamic>>();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(spacing: 12, runSpacing: 12, children: [
        _KpiCard(label: 'Reacciones esta semana', value: '${stats['reactionsThisWeek']}', icon: Icons.favorite_rounded,  color: _pink),
        _KpiCard(label: 'Comentarios esta semana',value: '${stats['commentsThisWeek']}',  icon: Icons.comment_rounded,   color: _blue),
        _KpiCard(label: 'Reacciones/post prom.',  value: '${stats['avgReactions']}',      icon: Icons.star_rounded,      color: _amber),
        _KpiCard(label: 'Comentarios/post prom.', value: '${stats['avgComments']}',       icon: Icons.chat_rounded,      color: _purple),
      ]),
      const SizedBox(height: 16),

      _Card(
        title: 'Top 5 posts con más reacciones',
        padding: EdgeInsets.zero,
        child: Column(children: topPosts.isEmpty
            ? [const Padding(padding: EdgeInsets.all(20), child: Text('Sin posts aún', style: TextStyle(color: _textDim), textAlign: TextAlign.center))]
            : topPosts.map((p) {
                final name = (p['userName'] as String?)?.isNotEmpty == true ? p['userName'] as String : p['userEmail'] as String? ?? '';
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _border))),
                  child: Row(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: p['imageUrl'] != null
                          ? Image.network(p['imageUrl'] as String, width: 48, height: 48, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(width: 48, height: 48, color: _surface2, child: const Icon(Icons.image, color: _textDim)))
                          : Container(width: 48, height: 48, color: _surface2, child: const Icon(Icons.photo, color: _textDim)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                      if ((p['caption'] as String?)?.isNotEmpty == true)
                        Text(p['caption'] as String, style: const TextStyle(color: _textDim, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ])),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.favorite, color: _pink, size: 12),
                        const SizedBox(width: 3),
                        Text('${p['reactions']}', style: const TextStyle(color: _pink, fontSize: 12, fontWeight: FontWeight.bold)),
                      ]),
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.comment, color: _blue, size: 12),
                        const SizedBox(width: 3),
                        Text('${p['comments']}', style: const TextStyle(color: _blue, fontSize: 12)),
                      ]),
                    ]),
                  ]),
                );
              }).toList()),
      ),

      _Card(
        title: 'Top 5 peinados favoritos',
        padding: EdgeInsets.zero,
        child: Column(children: topHairs.isEmpty
            ? [const Padding(padding: EdgeInsets.all(20), child: Text('Sin favoritos aún', style: TextStyle(color: _textDim), textAlign: TextAlign.center))]
            : topHairs.map((h) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _border))),
                child: Row(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: h['imageUrl'] != null
                        ? Image.network(h['imageUrl'] as String, width: 48, height: 48, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(width: 48, height: 48, color: _surface2))
                        : Container(width: 48, height: 48, color: _surface2, child: const Icon(Icons.content_cut, color: _textDim)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(h['gender'] as String? ?? 'UNISEX', style: const TextStyle(color: _cyan, fontSize: 11)),
                    Text(h['description'] as String? ?? '', style: const TextStyle(color: Colors.white, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    const Icon(Icons.favorite, color: _pink, size: 14),
                    Text('${h['favorites']}', style: const TextStyle(color: _pink, fontWeight: FontWeight.bold, fontSize: 14)),
                  ]),
                ]),
              )).toList()),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SEGMENTS TAB
// ─────────────────────────────────────────────────────────────────────────────

class _SegmentsTab extends StatefulWidget {
  const _SegmentsTab();
  @override State<_SegmentsTab> createState() => _SegmentsTabState();
}

class _SegmentsTabState extends State<_SegmentsTab> {
  Map<String, dynamic>? _data;
  bool _loading = true; String? _error;

  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final d = await AdminDashboardService.getSegments();
      if (mounted) setState(() { _data = d; _loading = false; });
    } catch (e) { if (mounted) setState(() { _error = e.toString(); _loading = false; }); }
  }

  List<({String label, int value})> _toList(dynamic raw) =>
    (raw as List).map((e) => (label: e['label'] as String, value: e['value'] as int)).toList();

  @override
  Widget build(BuildContext context) => _Tab(
    title: 'Segmentación',
    subtitle: 'Demografía y perfil de usuarios',
    onRefresh: _load,
    child: _loading ? _buildLoader() : _error != null ? _buildError(_error!, _load) : _build(),
  );

  Widget _build() {
    final profile  = _data!['profileCompletion'] as Map<String, dynamic>;
    final gender   = _toList(_data!['gender']);
    final bodyType = _toList(_data!['bodyType']);
    final skinTone = _toList(_data!['skinTone']);
    final ageGroups= _toList(_data!['ageGroups']);

    final withP = profile['withProfile'] as int;
    final total = profile['total'] as int;
    final pct      = total > 0 ? (withP / total * 100).toStringAsFixed(0) : '0';

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Perfil completado
      _Card(title: 'Completitud de perfil', child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('$pct%', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$withP de $total usuarios tienen perfil completo', style: const TextStyle(color: _textDim, fontSize: 12)),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: total > 0 ? withP / total : 0,
                minHeight: 8,
                backgroundColor: _surface2,
                valueColor: const AlwaysStoppedAnimation(_blue),
              ),
            ),
          ])),
        ]),
      ])),

      // Género
      _Card(title: 'Distribución por género', child: _DonutChart(
        size: 100, data: gender,
        colors: [_pink, _blue, _cyan, _textDim],
      )),

      // Grupos de edad
      _Card(title: 'Grupos de edad', child: _BarChart(
        labels: ageGroups.map((e) => e.label).toList(),
        height: 130,
        series: [(name: 'Usuarios', color: _purple, data: ageGroups.map((e) => e.value).toList())],
      )),

      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: _Card(title: 'Tipo de cuerpo', child: _DonutChart(
          size: 90, data: bodyType,
          colors: [_amber, _green, _blue, _pink, _purple, _textDim],
        ))),
        const SizedBox(width: 12),
        Expanded(child: _Card(title: 'Tono de piel', child: _DonutChart(
          size: 90, data: skinTone,
          colors: [_amber, _pink, _cyan, _purple, _textDim],
        ))),
      ]),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  USERS TAB (existing, dark-themed)
// ─────────────────────────────────────────────────────────────────────────────

class _UsersTab extends StatefulWidget {
  const _UsersTab();
  @override State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  AdminUsersResult? _result;
  bool _loading = true; String? _error;
  final _search = TextEditingController();
  String _role = ''; int _page = 1;

  @override void initState() { super.initState(); _load(); }
  @override void dispose() { _search.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final r = await AdminDashboardService.getUsers(page: _page, search: _search.text.trim(), role: _role);
      if (mounted) setState(() { _result = r; _loading = false; });
    } catch (e) { if (mounted) setState(() { _error = e.toString(); _loading = false; }); }
  }

  Future<void> _toggleRole(AdminUser u) async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: _surface,
      title: Text(u.isAdmin ? 'Quitar admin' : 'Hacer admin', style: const TextStyle(color: Colors.white)),
      content: Text('¿Cambiar rol de ${u.displayName}?', style: const TextStyle(color: _textDim)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirmar')),
      ],
    ));
    if (confirm != true) return;
    await AdminDashboardService.updateUser(u.id, role: u.isAdmin ? 'CLIENT' : 'ADMIN');
    _load();
  }

  Future<void> _toggleActive(AdminUser u) async {
    await AdminDashboardService.updateUser(u.id, isActive: !u.isActive);
    _load();
  }

  @override
  Widget build(BuildContext context) => _Tab(
    title: 'Usuarios',
    subtitle: 'Gestión y control de cuentas',
    onRefresh: _load,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: TextField(
          controller: _search,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Buscar...', hintStyle: const TextStyle(color: _textDim),
            prefixIcon: const Icon(Icons.search, color: _textDim, size: 18),
            filled: true, fillColor: _surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _border)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          onSubmitted: (_) { _page = 1; _load(); },
        )),
        const SizedBox(width: 10),
        DropdownButtonHideUnderline(child: DropdownButton<String>(
          value: _role.isEmpty ? '' : _role,
          dropdownColor: _surface,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          items: const [
            DropdownMenuItem(value: '', child: Text('Todos')),
            DropdownMenuItem(value: 'ADMIN', child: Text('Admin')),
            DropdownMenuItem(value: 'CLIENT', child: Text('Cliente')),
          ],
          onChanged: (v) { setState(() { _role = v ?? ''; _page = 1; }); _load(); },
        )),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: () { _page = 1; _load(); },
          style: ElevatedButton.styleFrom(backgroundColor: _blue),
          child: const Text('Buscar'),
        ),
      ]),
      const SizedBox(height: 14),
      if (_loading) _buildLoader()
      else if (_error != null) _buildError(_error!, _load)
      else ...[
        Text('${_result!.total} usuarios', style: const TextStyle(color: _textDim, fontSize: 12)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(_surface2),
              dataRowColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.hovered) ? _surface2 : _surface),
              columns: const [
                DataColumn(label: Text('Usuario', style: TextStyle(color: _textDim, fontSize: 12))),
                DataColumn(label: Text('Email',   style: TextStyle(color: _textDim, fontSize: 12))),
                DataColumn(label: Text('Rol',     style: TextStyle(color: _textDim, fontSize: 12))),
                DataColumn(label: Text('Plan',    style: TextStyle(color: _textDim, fontSize: 12))),
                DataColumn(label: Text('Armarios',style: TextStyle(color: _textDim, fontSize: 12))),
                DataColumn(label: Text('Posts',   style: TextStyle(color: _textDim, fontSize: 12))),
                DataColumn(label: Text('Registro',style: TextStyle(color: _textDim, fontSize: 12))),
                DataColumn(label: Text('Acciones',style: TextStyle(color: _textDim, fontSize: 12))),
              ],
              rows: _result!.users.map((u) => DataRow(cells: [
                DataCell(Row(children: [
                  CircleAvatar(radius: 14, backgroundColor: _blue.withValues(alpha: 0.2),
                    backgroundImage: u.profilePhoto != null ? NetworkImage(u.profilePhoto!) : null,
                    child: u.profilePhoto == null ? Text(u.displayName[0].toUpperCase(), style: const TextStyle(color: _blue, fontSize: 11, fontWeight: FontWeight.bold)) : null),
                  const SizedBox(width: 8),
                  Text(u.displayName, style: const TextStyle(color: Colors.white, fontSize: 13)),
                ])),
                DataCell(Text(u.email, style: const TextStyle(color: _textDim, fontSize: 12))),
                DataCell(_Chip(u.isAdmin ? 'Admin' : 'Cliente', u.isAdmin ? _amber : _textDim)),
                DataCell(_Chip(u.isPremium ? 'Premium' : 'Free', u.isPremium ? _purple : _textDim)),
                DataCell(Text('${u.closets}', style: const TextStyle(color: Colors.white))),
                DataCell(Text('${u.posts}',   style: const TextStyle(color: Colors.white))),
                DataCell(Text(DateFormat('dd/MM/yy').format(u.createdAt), style: const TextStyle(color: _textDim, fontSize: 12))),
                DataCell(Row(children: [
                  Tooltip(message: u.isAdmin ? 'Quitar admin' : 'Hacer admin',
                    child: IconButton(icon: Icon(u.isAdmin ? Icons.admin_panel_settings : Icons.person_add_alt,
                        color: u.isAdmin ? _amber : _textDim, size: 17), onPressed: () => _toggleRole(u))),
                  Tooltip(message: u.isActive ? 'Desactivar' : 'Activar',
                    child: IconButton(icon: Icon(u.isActive ? Icons.block : Icons.check_circle_outline,
                        color: u.isActive ? _red : _green, size: 17), onPressed: () => _toggleActive(u))),
                ])),
              ])).toList(),
            ),
          ),
        ),
        if (_result!.pages > 1) Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton(icon: const Icon(Icons.chevron_left, color: _textDim), onPressed: _page > 1 ? () { setState(() => _page--); _load(); } : null),
            Text('$_page / ${_result!.pages}', style: const TextStyle(color: _textDim)),
            IconButton(icon: const Icon(Icons.chevron_right, color: _textDim), onPressed: _page < _result!.pages ? () { setState(() => _page++); _load(); } : null),
          ]),
        ),
      ],
    ]),
  );
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, this.color);
  final String label; final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  ACTIVITY TAB
// ─────────────────────────────────────────────────────────────────────────────

class _ActivityTab extends StatefulWidget {
  const _ActivityTab();
  @override State<_ActivityTab> createState() => _ActivityTabState();
}

class _ActivityTabState extends State<_ActivityTab> {
  List<ActivityEvent>? _events;
  bool _loading = true; String? _error;

  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final ev = await AdminDashboardService.getActivity();
      if (mounted) setState(() { _events = ev; _loading = false; });
    } catch (e) { if (mounted) setState(() { _error = e.toString(); _loading = false; }); }
  }

  static const _colors = {
    'USER_REGISTER':    _green,
    'OUTFIT_CREATE':    _purple,
    'POST_CREATE':      _pink,
    'HAIRSTYLE_UPLOAD': _cyan,
  };

  @override
  Widget build(BuildContext context) => _Tab(
    title: 'Bitácora de actividad',
    subtitle: 'Eventos recientes del sistema',
    onRefresh: _load,
    child: _loading ? _buildLoader() : _error != null ? _buildError(_error!, _load)
        : _events!.isEmpty
            ? const Center(child: Text('Sin actividad registrada.', style: TextStyle(color: _textDim)))
            : Column(children: _events!.map((e) {
                final color = _colors[e.type] ?? _textDim;
                final diff  = DateTime.now().difference(e.createdAt);
                final ago   = diff.inMinutes < 60 ? '${diff.inMinutes}m'
                    : diff.inHours < 24 ? '${diff.inHours}h'
                    : DateFormat('dd/MM HH:mm').format(e.createdAt);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
                  child: Row(children: [
                    Container(width: 38, height: 38,
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                      child: Icon(_iconFor(e.icon), color: color, size: 17)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(e.label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                      if (e.detail.isNotEmpty) Text(e.detail, style: const TextStyle(color: _textDim, fontSize: 11)),
                    ])),
                    Text(ago, style: const TextStyle(color: _textDim, fontSize: 11)),
                  ]),
                );
              }).toList()),
  );

  IconData _iconFor(String n) => switch (n) {
    'person_add'   => Icons.person_add,
    'checkroom'    => Icons.checkroom,
    'photo_camera' => Icons.photo_camera,
    'content_cut'  => Icons.content_cut,
    _              => Icons.circle,
  };
}
