import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/admin_dashboard_service.dart';
import 'admin_hairstyle_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  AdminDashboardPage — layout de sidebar para web
// ─────────────────────────────────────────────────────────────────────────────

enum _Section { overview, users, hairstyles, reports, activity }

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  _Section _section = _Section.overview;

  static const _navItems = [
    (_Section.overview,   Icons.dashboard_outlined,  'Resumen'),
    (_Section.users,      Icons.people_outline,       'Usuarios'),
    (_Section.hairstyles, Icons.content_cut,          'Peinados'),
    (_Section.reports,    Icons.bar_chart,            'Reportes'),
    (_Section.activity,   Icons.history,              'Bitácora'),
  ];

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: wide
          ? null
          : AppBar(
              title: const Text('Admin Panel'),
              centerTitle: true,
              backgroundColor: AppPalette.primary,
              foregroundColor: Colors.white,
            ),
      drawer: wide ? null : _Sidebar(current: _section, onSelect: _setSection, items: _navItems),
      body: wide
          ? Row(children: [
              _Sidebar(current: _section, onSelect: _setSection, items: _navItems),
              Expanded(child: _body()),
            ])
          : _body(),
    );
  }

  void _setSection(_Section s) => setState(() => _section = s);

  Widget _body() {
    return switch (_section) {
      _Section.overview   => const _OverviewTab(),
      _Section.users      => const _UsersTab(),
      _Section.hairstyles => const _HairstylesTab(),
      _Section.reports    => const _ReportsTab(),
      _Section.activity   => const _ActivityTab(),
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Sidebar
// ─────────────────────────────────────────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.current, required this.onSelect, required this.items});

  final _Section current;
  final void Function(_Section) onSelect;
  final List<(_Section, IconData, String)> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: const Color(0xFF1A1D2E),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 48),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: AppPalette.primary, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('ModalA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Text('Admin Panel', style: TextStyle(color: Colors.white54, fontSize: 11)),
              ]),
            ]),
          ),
          const SizedBox(height: 32),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text('MENÚ', style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1.5)),
          ),
          const SizedBox(height: 8),
          ...items.map((t) => _NavTile(
                icon: t.$2, label: t.$3,
                selected: current == t.$1,
                onTap: () { Navigator.pop(context); onSelect(t.$1); },
              )),
          const Spacer(),
          const Divider(color: Colors.white12),
          _NavTile(
            icon: Icons.arrow_back,
            label: 'Volver a la app',
            selected: false,
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({required this.icon, required this.label, required this.selected, required this.onTap});
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? AppPalette.primary.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: selected ? Border.all(color: AppPalette.primary.withValues(alpha: 0.4)) : null,
        ),
        child: Row(children: [
          Icon(icon, color: selected ? AppPalette.primary : Colors.white54, size: 18),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: selected ? Colors.white : Colors.white70, fontSize: 14, fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Resumen
// ─────────────────────────────────────────────────────────────────────────────

class _OverviewTab extends StatefulWidget {
  const _OverviewTab();
  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  AdminStats? _stats;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final s = await AdminDashboardService.getStats();
      if (mounted) setState(() { _stats = s; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _TabScaffold(
      title: 'Resumen general',
      onRefresh: _load,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorBox(_error!, onRetry: _load)
              : _StatsGrid(_stats!),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid(this.s);
  final AdminStats s;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _KpiData('Usuarios totales', s.totalUsers, Icons.people, const Color(0xFF6C63FF)),
      _KpiData('Usuarios premium', s.premiumUsers, Icons.star, const Color(0xFFF59E0B)),
      _KpiData('Usuarios gratuitos', s.freeUsers, Icons.person_outline, const Color(0xFF10B981)),
      _KpiData('Usuarios activos', s.activeUsers, Icons.verified_user, const Color(0xFF3B82F6)),
      _KpiData('Peinados en catálogo', s.totalHairstyles, Icons.content_cut, const Color(0xFFEC4899)),
      _KpiData('Outfits generados', s.totalOutfits, Icons.checkroom, const Color(0xFF8B5CF6)),
      _KpiData('Posts publicados', s.totalPosts, Icons.photo_camera, const Color(0xFFEF4444)),
      _KpiData('Prendas subidas', s.totalGarments, Icons.style, const Color(0xFF14B8A6)),
      _KpiData('Chats de IA', s.totalConversations, Icons.chat_bubble_outline, const Color(0xFF6366F1)),
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: cards.map((c) => _KpiCard(data: c)).toList(),
    );
  }
}

class _KpiData {
  const _KpiData(this.label, this.value, this.icon, this.color);
  final String label;
  final int value;
  final IconData icon;
  final Color color;
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.data});
  final _KpiData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: data.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(data.icon, color: data.color, size: 22),
        ),
        const SizedBox(height: 16),
        Text('${data.value}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(data.label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Usuarios
// ─────────────────────────────────────────────────────────────────────────────

class _UsersTab extends StatefulWidget {
  const _UsersTab();
  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  AdminUsersResult? _result;
  bool _loading = true;
  String? _error;
  final _searchCtrl = TextEditingController();
  String _roleFilter = '';
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final r = await AdminDashboardService.getUsers(
        page: _page, search: _searchCtrl.text.trim(), role: _roleFilter,
      );
      if (mounted) setState(() { _result = r; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _toggleRole(AdminUser u) async {
    final newRole = u.isAdmin ? 'CLIENT' : 'ADMIN';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(u.isAdmin ? 'Quitar admin' : 'Hacer admin'),
        content: Text('¿Cambiar rol de ${u.displayName} a $newRole?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirmar')),
        ],
      ),
    );
    if (confirm != true) return;
    await AdminDashboardService.updateUser(u.id, role: newRole);
    _load();
  }

  Future<void> _toggleActive(AdminUser u) async {
    await AdminDashboardService.updateUser(u.id, isActive: !u.isActive);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return _TabScaffold(
      title: 'Gestión de usuarios',
      onRefresh: _load,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filtros
          Row(children: [
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre o email...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onSubmitted: (_) { _page = 1; _load(); },
              ),
            ),
            const SizedBox(width: 12),
            DropdownButton<String>(
              value: _roleFilter.isEmpty ? '' : _roleFilter,
              hint: const Text('Rol'),
              items: const [
                DropdownMenuItem(value: '', child: Text('Todos')),
                DropdownMenuItem(value: 'ADMIN', child: Text('Admin')),
                DropdownMenuItem(value: 'CLIENT', child: Text('Cliente')),
              ],
              onChanged: (v) { setState(() { _roleFilter = v ?? ''; _page = 1; }); _load(); },
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () { _page = 1; _load(); },
              icon: const Icon(Icons.filter_list, size: 16),
              label: const Text('Filtrar'),
              style: ElevatedButton.styleFrom(backgroundColor: AppPalette.primary, foregroundColor: Colors.white),
            ),
          ]),
          const SizedBox(height: 16),

          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
          else if (_error != null)
            _ErrorBox(_error!, onRetry: _load)
          else ...[
            // Contador
            Text('${_result!.total} usuarios encontrados', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            const SizedBox(height: 12),

            // Tabla
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF8F9FF)),
                  columns: const [
                    DataColumn(label: Text('Usuario', style: TextStyle(fontWeight: FontWeight.w600))),
                    DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.w600))),
                    DataColumn(label: Text('Rol', style: TextStyle(fontWeight: FontWeight.w600))),
                    DataColumn(label: Text('Plan', style: TextStyle(fontWeight: FontWeight.w600))),
                    DataColumn(label: Text('Prendas', style: TextStyle(fontWeight: FontWeight.w600))),
                    DataColumn(label: Text('Outfits', style: TextStyle(fontWeight: FontWeight.w600))),
                    DataColumn(label: Text('Registro', style: TextStyle(fontWeight: FontWeight.w600))),
                    DataColumn(label: Text('Acciones', style: TextStyle(fontWeight: FontWeight.w600))),
                  ],
                  rows: _result!.users.map((u) => DataRow(cells: [
                    DataCell(Row(children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppPalette.primary.withValues(alpha: 0.15),
                        backgroundImage: u.profilePhoto != null ? NetworkImage(u.profilePhoto!) : null,
                        child: u.profilePhoto == null
                            ? Text(u.displayName[0].toUpperCase(), style: TextStyle(color: AppPalette.primary, fontWeight: FontWeight.bold, fontSize: 12))
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text(u.displayName, style: const TextStyle(fontWeight: FontWeight.w500)),
                    ])),
                    DataCell(Text(u.email, style: const TextStyle(fontSize: 13))),
                    DataCell(_RoleBadge(u.role)),
                    DataCell(_PlanBadge(u.subscriptionStatus)),
                    DataCell(Text('${u.garments}', textAlign: TextAlign.center)),
                    DataCell(Text('${u.outfits}', textAlign: TextAlign.center)),
                    DataCell(Text(DateFormat('dd/MM/yy').format(u.createdAt))),
                    DataCell(Row(children: [
                      Tooltip(
                        message: u.isAdmin ? 'Quitar admin' : 'Hacer admin',
                        child: IconButton(
                          icon: Icon(u.isAdmin ? Icons.admin_panel_settings : Icons.person_add_alt,
                              color: u.isAdmin ? Colors.amber : Colors.grey, size: 18),
                          onPressed: () => _toggleRole(u),
                        ),
                      ),
                      Tooltip(
                        message: u.isActive ? 'Desactivar cuenta' : 'Activar cuenta',
                        child: IconButton(
                          icon: Icon(u.isActive ? Icons.block : Icons.check_circle_outline,
                              color: u.isActive ? Colors.red : Colors.green, size: 18),
                          onPressed: () => _toggleActive(u),
                        ),
                      ),
                    ])),
                  ])).toList(),
                ),
              ),
            ),

            // Paginación
            if (_result!.pages > 1) ...[
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _page > 1 ? () { setState(() => _page--); _load(); } : null,
                ),
                Text('Página $_page de ${_result!.pages}', style: const TextStyle(fontSize: 13)),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _page < _result!.pages ? () { setState(() => _page++); _load(); } : null,
                ),
              ]),
            ],
          ],
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge(this.role);
  final String role;
  @override
  Widget build(BuildContext context) {
    final isAdmin = role == 'ADMIN';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isAdmin ? Colors.amber.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(isAdmin ? 'Admin' : 'Cliente',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
              color: isAdmin ? Colors.amber[800] : Colors.grey[600])),
    );
  }
}

class _PlanBadge extends StatelessWidget {
  const _PlanBadge(this.status);
  final String status;
  @override
  Widget build(BuildContext context) {
    final isPremium = status == 'PREMIUM';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isPremium ? AppPalette.primary.withValues(alpha: 0.12) : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(isPremium ? 'Premium' : 'Free',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
              color: isPremium ? AppPalette.primary : Colors.grey[600])),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Peinados (embed AdminHairstylePage)
// ─────────────────────────────────────────────────────────────────────────────

class _HairstylesTab extends StatelessWidget {
  const _HairstylesTab();
  @override
  Widget build(BuildContext context) {
    return const AdminHairstylePage(embedded: true);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Reportes
// ─────────────────────────────────────────────────────────────────────────────

class _ReportsTab extends StatefulWidget {
  const _ReportsTab();
  @override
  State<_ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<_ReportsTab> {
  AdminReports? _reports;
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final r = await AdminDashboardService.getReports();
      if (mounted) setState(() { _reports = r; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _TabScaffold(
      title: 'Reportes y estadísticas',
      onRefresh: _load,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorBox(_error!, onRetry: _load)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Últimos 7 días', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    const SizedBox(height: 20),
                    _ChartCard(
                      title: 'Nuevos usuarios por día',
                      color: const Color(0xFF6C63FF),
                      labels: _reports!.labels,
                      values: _reports!.userGrowth,
                    ),
                    const SizedBox(height: 20),
                    _ChartCard(
                      title: 'Outfits generados por día',
                      color: const Color(0xFF8B5CF6),
                      labels: _reports!.labels,
                      values: _reports!.outfitGrowth,
                    ),
                    const SizedBox(height: 20),
                    _ChartCard(
                      title: 'Posts publicados por día',
                      color: const Color(0xFFEC4899),
                      labels: _reports!.labels,
                      values: _reports!.postGrowth,
                    ),
                  ],
                ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.color, required this.labels, required this.values});
  final String title;
  final Color color;
  final List<String> labels;
  final List<int> values;

  @override
  Widget build(BuildContext context) {
    final maxVal = values.isEmpty ? 1 : values.reduce(math.max);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 4),
          Text('Total: ${values.fold(0, (a, b) => a + b)}',
              style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(values.length, (i) {
                final frac = maxVal == 0 ? 0.0 : values[i] / maxVal;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (values[i] > 0)
                          Text('${values[i]}',
                              style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOut,
                          height: math.max(4.0, frac * 90),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(labels[i], style: const TextStyle(fontSize: 9, color: Colors.grey),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Bitácora
// ─────────────────────────────────────────────────────────────────────────────

class _ActivityTab extends StatefulWidget {
  const _ActivityTab();
  @override
  State<_ActivityTab> createState() => _ActivityTabState();
}

class _ActivityTabState extends State<_ActivityTab> {
  List<ActivityEvent>? _events;
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final ev = await AdminDashboardService.getActivity();
      if (mounted) setState(() { _events = ev; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  static const _typeColors = {
    'USER_REGISTER':   Color(0xFF10B981),
    'OUTFIT_CREATE':   Color(0xFF8B5CF6),
    'POST_CREATE':     Color(0xFFEC4899),
    'HAIRSTYLE_UPLOAD': Color(0xFF3B82F6),
  };

  @override
  Widget build(BuildContext context) {
    return _TabScaffold(
      title: 'Bitácora de actividad',
      onRefresh: _load,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorBox(_error!, onRetry: _load)
              : _events!.isEmpty
                  ? const Center(child: Text('No hay actividad registrada aún.'))
                  : Column(
                      children: _events!.map((e) {
                        final color = _typeColors[e.type] ?? Colors.grey;
                        final diff = DateTime.now().difference(e.createdAt);
                        final timeAgo = diff.inMinutes < 60
                            ? '${diff.inMinutes}m atrás'
                            : diff.inHours < 24
                                ? '${diff.inHours}h atrás'
                                : DateFormat('dd/MM HH:mm').format(e.createdAt);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
                          ),
                          child: Row(children: [
                            Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                              child: Icon(_iconFor(e.icon), color: color, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(e.label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                              if (e.detail.isNotEmpty)
                                Text(e.detail, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                            ])),
                            Text(timeAgo, style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                          ]),
                        );
                      }).toList(),
                    ),
    );
  }

  IconData _iconFor(String name) {
    return switch (name) {
      'person_add'    => Icons.person_add,
      'checkroom'     => Icons.checkroom,
      'photo_camera'  => Icons.photo_camera,
      'content_cut'   => Icons.content_cut,
      _               => Icons.circle,
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Shared widgets
// ─────────────────────────────────────────────────────────────────────────────

class _TabScaffold extends StatelessWidget {
  const _TabScaffold({required this.title, required this.child, this.onRefresh});
  final String title;
  final Widget child;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          color: Colors.white,
          child: Row(children: [
            Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const Spacer(),
            if (onRefresh != null)
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                tooltip: 'Actualizar',
                onPressed: onRefresh,
              ),
          ]),
        ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: child,
          ),
        ),
      ],
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox(this.error, {this.onRetry});
  final String error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 48),
        const SizedBox(height: 12),
        Text(error, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
        if (onRetry != null) ...[
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ]),
    );
  }
}
