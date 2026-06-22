import { Injectable, Logger, ForbiddenException, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from 'src/common/prisma/prisma.service';
import { UserRole } from 'generated/prisma/client';

export interface BackupRun {
  id: number;
  runNumber: number;
  status: string;
  conclusion: string | null;
  createdAt: string;
  runUrl: string;
  triggeredBy: string;
}

export interface TriggerResult {
  triggered: boolean;
  message: string;
}

@Injectable()
export class AdminService {
  private readonly logger = new Logger(AdminService.name);

  constructor(private readonly prisma: PrismaService) {}

  async promoteToAdmin(email: string, secret: string): Promise<{ email: string; role: string }> {
    const expected = process.env.ADMIN_PROMOTE_SECRET;
    if (!expected || secret !== expected) {
      throw new ForbiddenException('Invalid promote secret');
    }
    const user = await this.prisma.user.findUnique({ where: { email } });
    if (!user) throw new NotFoundException(`User ${email} not found`);
    const updated = await this.prisma.user.update({
      where: { email },
      data: { role: 'ADMIN' },
      select: { email: true, role: true },
    });
    this.logger.log(`Promoted ${email} to ADMIN`);
    return updated;
  }

  private readonly owner = 'OLIVER2003V';
  private readonly repo = 'MODA_ASISTENTE_IA';
  private readonly workflowId = 'database-backup.yml';

  private get token(): string | undefined {
    return process.env.GITHUB_PERSONAL_TOKEN;
  }

  private get headers() {
    return {
      Authorization: `Bearer ${this.token}`,
      Accept: 'application/vnd.github+json',
      'Content-Type': 'application/json',
      'X-GitHub-Api-Version': '2022-11-28',
    };
  }

  // ── Dashboard stats ───────────────────────────────────────────────────────

  async getStats() {
    const [
      totalUsers,
      premiumUsers,
      totalHairstyles,
      totalOutfits,
      totalPosts,
      totalGarments,
      totalConversations,
      activeUsers,
    ] = await Promise.all([
      this.prisma.user.count(),
      this.prisma.subscription.count({ where: { status: 'PREMIUM' } }),
      this.prisma.hairstyle.count(),
      this.prisma.outfit.count(),
      this.prisma.post.count(),
      this.prisma.garment.count(),
      this.prisma.conversation.count(),
      this.prisma.user.count({ where: { isActive: true } }),
    ]);
    return {
      totalUsers,
      premiumUsers,
      freeUsers: totalUsers - premiumUsers,
      activeUsers,
      totalHairstyles,
      totalOutfits,
      totalPosts,
      totalGarments,
      totalConversations,
    };
  }

  // ── Users management ─────────────────────────────────────────────────────

  async getUsers(page = 1, limit = 20, search = '', role = '') {
    const skip = (page - 1) * limit;
    const where: any = {};
    if (search) {
      where.OR = [
        { email: { contains: search, mode: 'insensitive' } },
        { name: { contains: search, mode: 'insensitive' } },
      ];
    }
    if (role === 'ADMIN' || role === 'CLIENT') {
      where.role = role as UserRole;
    }

    const [users, total] = await Promise.all([
      this.prisma.user.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        select: {
          id: true,
          email: true,
          name: true,
          role: true,
          isActive: true,
          profilePhoto: true,
          createdAt: true,
          _count: {
            select: { posts: true, closets: true },
          },
          subscription: { select: { status: true } },
        },
      }),
      this.prisma.user.count({ where }),
    ]);

    return {
      users: users.map((u) => {
        const { subscription, ...rest } = u;
        return {
          ...rest,
          subscriptionStatus: subscription?.status ?? 'FREE',
        };
      }),
      total,
      page,
      pages: Math.ceil(total / limit),
    };
  }

  async updateUser(id: string, data: { role?: UserRole; isActive?: boolean }) {
    const user = await this.prisma.user.findUnique({ where: { id } });
    if (!user) throw new NotFoundException('User not found');
    if (data.role && !['ADMIN', 'CLIENT'].includes(data.role)) {
      throw new BadRequestException('Invalid role');
    }
    return this.prisma.user.update({
      where: { id },
      data,
      select: { id: true, email: true, role: true, isActive: true },
    });
  }

  // ── Reports ───────────────────────────────────────────────────────────────

  async getReports() {
    const now = new Date();
    const days = Array.from({ length: 7 }, (_, i) => {
      const d = new Date(now);
      d.setDate(d.getDate() - (6 - i));
      d.setHours(0, 0, 0, 0);
      return d;
    });

    const [userGrowth, outfitGrowth, postGrowth] = await Promise.all([
      Promise.all(
        days.map((d) => {
          const next = new Date(d);
          next.setDate(next.getDate() + 1);
          return this.prisma.user.count({
            where: { createdAt: { gte: d, lt: next } },
          });
        }),
      ),
      Promise.all(
        days.map((d) => {
          const next = new Date(d);
          next.setDate(next.getDate() + 1);
          return this.prisma.outfit.count({
            where: { createdAt: { gte: d, lt: next } },
          });
        }),
      ),
      Promise.all(
        days.map((d) => {
          const next = new Date(d);
          next.setDate(next.getDate() + 1);
          return this.prisma.post.count({
            where: { createdAt: { gte: d, lt: next } },
          });
        }),
      ),
    ]);

    const labels = days.map((d) =>
      d.toLocaleDateString('es', { weekday: 'short', day: 'numeric' }),
    );

    return { labels, userGrowth, outfitGrowth, postGrowth };
  }

  // ── Activity log ─────────────────────────────────────────────────────────

  async getActivity() {
    const [recentUsers, recentOutfits, recentPosts, recentHairstyles] =
      await Promise.all([
        this.prisma.user.findMany({
          take: 8,
          orderBy: { createdAt: 'desc' },
          select: { id: true, email: true, name: true, role: true, createdAt: true },
        }),
        this.prisma.outfit.findMany({
          take: 8,
          orderBy: { createdAt: 'desc' },
          select: {
            id: true,
            name: true,
            score: true,
            createdAt: true,
          },
        }),
        this.prisma.post.findMany({
          take: 8,
          orderBy: { createdAt: 'desc' },
          select: {
            id: true,
            caption: true,
            reactionCount: true,
            createdAt: true,
            user: { select: { email: true, name: true } },
          },
        }),
        this.prisma.hairstyle.findMany({
          take: 5,
          orderBy: { createdAt: 'desc' },
          select: { id: true, description: true, gender: true, createdAt: true, imageUrl: true },
        }),
      ]);

    const events = [
      ...recentUsers.map((u) => ({
        type: 'USER_REGISTER',
        label: `Nuevo usuario: ${u.name ?? u.email}`,
        detail: u.email,
        icon: 'person_add',
        createdAt: u.createdAt.toISOString(),
      })),
      ...recentOutfits.map((o) => ({
        type: 'OUTFIT_CREATE',
        label: `Outfit generado: ${o.name ?? 'Sin nombre'}`,
        detail: `score: ${o.score}`,
        icon: 'checkroom',
        createdAt: o.createdAt.toISOString(),
      })),
      ...recentPosts.map((p) => ({
        type: 'POST_CREATE',
        label: `Post publicado`,
        detail: p.user?.email ?? '',
        icon: 'photo_camera',
        createdAt: p.createdAt.toISOString(),
      })),
      ...recentHairstyles.map((h) => ({
        type: 'HAIRSTYLE_UPLOAD',
        label: `Peinado subido al catálogo`,
        detail: h.gender ?? 'UNISEX',
        icon: 'content_cut',
        imageUrl: h.imageUrl,
        createdAt: h.createdAt.toISOString(),
      })),
    ].sort(
      (a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime(),
    );

    return { events: events.slice(0, 25) };
  }

  // ── Advanced metrics ─────────────────────────────────────────────────────

  async getMetrics() {
    const now = new Date();

    const startOf = (daysAgo: number, hour = 0) => {
      const d = new Date(now);
      d.setDate(d.getDate() - daysAgo);
      d.setHours(hour, 0, 0, 0);
      return d;
    };

    const todayStart  = startOf(0);
    const weekStart   = startOf(7);
    const monthStart  = startOf(30);
    const prevWeekStart  = startOf(14);
    const prevMonthStart = startOf(60);

    const [
      usersToday, usersThisWeek, usersThisMonth,
      usersPrevWeek, usersPrevMonth,
      outfitsToday, outfitsThisWeek,
      outfitsPrevWeek,
      postsToday, postsThisWeek,
      postsPrevWeek,
      activeThisWeek,
    ] = await Promise.all([
      this.prisma.user.count({ where: { createdAt: { gte: todayStart } } }),
      this.prisma.user.count({ where: { createdAt: { gte: weekStart } } }),
      this.prisma.user.count({ where: { createdAt: { gte: monthStart } } }),
      this.prisma.user.count({ where: { createdAt: { gte: prevWeekStart, lt: weekStart } } }),
      this.prisma.user.count({ where: { createdAt: { gte: prevMonthStart, lt: monthStart } } }),
      this.prisma.outfit.count({ where: { createdAt: { gte: todayStart } } }),
      this.prisma.outfit.count({ where: { createdAt: { gte: weekStart } } }),
      this.prisma.outfit.count({ where: { createdAt: { gte: prevWeekStart, lt: weekStart } } }),
      this.prisma.post.count({ where: { createdAt: { gte: todayStart } } }),
      this.prisma.post.count({ where: { createdAt: { gte: weekStart } } }),
      this.prisma.post.count({ where: { createdAt: { gte: prevWeekStart, lt: weekStart } } }),
      this.prisma.post.count({ where: { createdAt: { gte: weekStart } } }),
    ]);

    const pct = (cur: number, prev: number) =>
      prev === 0 ? (cur > 0 ? 100 : 0) : Math.round(((cur - prev) / prev) * 100);

    // 30-day daily series
    const days30 = Array.from({ length: 30 }, (_, i) => startOf(29 - i));
    const [series30Users, series30Outfits, series30Posts] = await Promise.all([
      Promise.all(days30.map((d, i) => {
        const next = days30[i + 1] ?? now;
        return this.prisma.user.count({ where: { createdAt: { gte: d, lt: next } } });
      })),
      Promise.all(days30.map((d, i) => {
        const next = days30[i + 1] ?? now;
        return this.prisma.outfit.count({ where: { createdAt: { gte: d, lt: next } } });
      })),
      Promise.all(days30.map((d, i) => {
        const next = days30[i + 1] ?? now;
        return this.prisma.post.count({ where: { createdAt: { gte: d, lt: next } } });
      })),
    ]);

    const labels30 = days30.map((d) =>
      d.toLocaleDateString('es', { day: 'numeric', month: 'short' }),
    );

    return {
      kpis: {
        usersToday,    usersThisWeek,    usersThisMonth,
        outfitsToday,  outfitsThisWeek,
        postsToday,    postsThisWeek,    activeThisWeek,
        weekVsPrev: {
          users:   pct(usersThisWeek,   usersPrevWeek),
          outfits: pct(outfitsThisWeek, outfitsPrevWeek),
          posts:   pct(postsThisWeek,   postsPrevWeek),
        },
        monthVsPrev: {
          users: pct(usersThisMonth, usersPrevMonth),
        },
      },
      series: { labels: labels30, users: series30Users, outfits: series30Outfits, posts: series30Posts },
    };
  }

  // ── Revenue ───────────────────────────────────────────────────────────────

  async getRevenue() {
    const now = new Date();
    const monthStart = new Date(now); monthStart.setDate(monthStart.getDate() - 30); monthStart.setHours(0,0,0,0);
    const prevMonthStart = new Date(now); prevMonthStart.setDate(prevMonthStart.getDate() - 60); prevMonthStart.setHours(0,0,0,0);

    const [paymentsAll, paymentsMonth, paymentsPrevMonth, recentPayments, premiumUsers, totalUsers] = await Promise.all([
      this.prisma.payment.aggregate({ where: { status: 'SUCCEEDED' }, _sum: { amount: true } }),
      this.prisma.payment.aggregate({ where: { status: 'SUCCEEDED', createdAt: { gte: monthStart } }, _sum: { amount: true } }),
      this.prisma.payment.aggregate({ where: { status: 'SUCCEEDED', createdAt: { gte: prevMonthStart, lt: monthStart } }, _sum: { amount: true } }),
      this.prisma.payment.findMany({
        where: { status: 'SUCCEEDED' },
        take: 10,
        orderBy: { createdAt: 'desc' },
        select: { id: true, amount: true, currency: true, createdAt: true, user: { select: { email: true, name: true } } },
      }),
      this.prisma.subscription.count({ where: { status: 'PREMIUM' } }),
      this.prisma.user.count(),
    ]);

    // 14-day daily revenue series
    const days14 = Array.from({ length: 14 }, (_, i) => {
      const d = new Date(now); d.setDate(d.getDate() - (13 - i)); d.setHours(0,0,0,0); return d;
    });
    const dailyRevenue = await Promise.all(days14.map((d, i) => {
      const next = days14[i + 1] ?? now;
      return this.prisma.payment.aggregate({ where: { status: 'SUCCEEDED', createdAt: { gte: d, lt: next } }, _sum: { amount: true } });
    }));

    const totalAll    = (paymentsAll._sum.amount ?? 0) / 100;
    const totalMonth  = (paymentsMonth._sum.amount ?? 0) / 100;
    const totalPrev   = (paymentsPrevMonth._sum.amount ?? 0) / 100;
    const pct = totalPrev === 0 ? (totalMonth > 0 ? 100 : 0) : Math.round(((totalMonth - totalPrev) / totalPrev) * 100);

    return {
      totalAllTime: totalAll,
      totalThisMonth: totalMonth,
      monthVsPrev: pct,
      conversionRate: totalUsers > 0 ? Math.round((premiumUsers / totalUsers) * 1000) / 10 : 0,
      premiumUsers,
      freeUsers: totalUsers - premiumUsers,
      recentPayments: recentPayments.map((p) => ({
        id: p.id,
        amount: p.amount / 100,
        currency: p.currency,
        createdAt: p.createdAt.toISOString(),
        userEmail: p.user?.email ?? '',
        userName: p.user?.name ?? '',
      })),
      dailySeries: {
        labels: days14.map((d) => d.toLocaleDateString('es', { day: 'numeric', month: 'short' })),
        amounts: dailyRevenue.map((r) => (r._sum.amount ?? 0) / 100),
      },
    };
  }

  // ── Engagement ────────────────────────────────────────────────────────────

  async getEngagement() {
    const weekStart = new Date(); weekStart.setDate(weekStart.getDate() - 7); weekStart.setHours(0,0,0,0);

    const [topPosts, topHairstyles, commentsThisWeek, reactionsThisWeek, totalComments, totalReactions] = await Promise.all([
      this.prisma.post.findMany({
        take: 5,
        orderBy: { reactionCount: 'desc' },
        select: { id: true, imageUrl: true, caption: true, reactionCount: true, commentCount: true, createdAt: true, user: { select: { email: true, name: true } } },
      }),
      this.prisma.hairstyle.findMany({
        take: 5,
        orderBy: { favorites: { _count: 'desc' } },
        select: { id: true, imageUrl: true, description: true, gender: true, _count: { select: { favorites: true } } },
      }),
      this.prisma.comment.count({ where: { createdAt: { gte: weekStart } } }),
      this.prisma.postInteraction.count({ where: { createdAt: { gte: weekStart } } }),
      this.prisma.comment.count(),
      this.prisma.postInteraction.count(),
    ]);

    const totalPosts = await this.prisma.post.count();
    const avgReactions = totalPosts > 0 ? Math.round((totalReactions / totalPosts) * 10) / 10 : 0;
    const avgComments  = totalPosts > 0 ? Math.round((totalComments  / totalPosts) * 10) / 10 : 0;

    return {
      topPosts: topPosts.map((p) => ({
        id: p.id,
        imageUrl: p.imageUrl,
        caption: p.caption ?? '',
        reactions: p.reactionCount,
        comments: p.commentCount,
        userEmail: p.user?.email ?? '',
        userName: p.user?.name ?? '',
        createdAt: p.createdAt.toISOString(),
      })),
      topHairstyles: topHairstyles.map((h) => ({
        id: h.id,
        imageUrl: h.imageUrl,
        description: h.description,
        gender: h.gender,
        favorites: h._count.favorites,
      })),
      stats: { commentsThisWeek, reactionsThisWeek, avgReactions, avgComments, totalComments, totalReactions },
    };
  }

  // ── Segments ──────────────────────────────────────────────────────────────

  async getSegments() {
    const attrs = await this.prisma.userAttribute.findMany({
      select: { gender: true, age: true, bodyType: true, skinTone: true, hairColor: true },
    });

    const count = <T extends string>(field: (a: typeof attrs[0]) => T | null | undefined) => {
      const map: Record<string, number> = {};
      for (const a of attrs) {
        const v = field(a) ?? 'Sin datos';
        map[v] = (map[v] ?? 0) + 1;
      }
      return Object.entries(map).sort((x, y) => y[1] - x[1]).map(([label, value]) => ({ label, value }));
    };

    const ageGroups = { '18-25': 0, '26-35': 0, '36-45': 0, '46+': 0, 'Sin datos': 0 };
    for (const a of attrs) {
      if (!a.age) { ageGroups['Sin datos']++; continue; }
      if (a.age <= 25) ageGroups['18-25']++;
      else if (a.age <= 35) ageGroups['26-35']++;
      else if (a.age <= 45) ageGroups['36-45']++;
      else ageGroups['46+']++;
    }

    const totalUsers = await this.prisma.user.count();
    const withProfile = attrs.length;

    return {
      profileCompletion: { withProfile, withoutProfile: totalUsers - withProfile, total: totalUsers },
      gender:   count((a) => a.gender),
      bodyType: count((a) => a.bodyType),
      skinTone: count((a) => a.skinTone),
      hairColor: count((a) => a.hairColor),
      ageGroups: Object.entries(ageGroups).map(([label, value]) => ({ label, value })),
    };
  }

  async triggerBackup(
    reason = 'Manual backup via app',
  ): Promise<TriggerResult> {
    if (!this.token) {
      return {
        triggered: false,
        message: 'GITHUB_PERSONAL_TOKEN no configurado en el servidor',
      };
    }

    const url = `https://api.github.com/repos/${this.owner}/${this.repo}/actions/workflows/${this.workflowId}/dispatches`;
    try {
      const res = await fetch(url, {
        method: 'POST',
        headers: this.headers,
        body: JSON.stringify({ ref: 'main', inputs: { reason } }),
        signal: AbortSignal.timeout(10_000),
      });

      if (res.status === 204) {
        return { triggered: true, message: 'Respaldo iniciado correctamente' };
      }

      const body = await res.text();
      this.logger.warn(`GitHub dispatch returned ${res.status}: ${body}`);
      return { triggered: false, message: `Error de GitHub: ${res.status}` };
    } catch (err) {
      this.logger.error(`triggerBackup failed: ${(err as Error).message}`);
      return { triggered: false, message: 'No se pudo contactar con GitHub' };
    }
  }

  async listBackups(): Promise<BackupRun[]> {
    if (!this.token) return [];

    const url = `https://api.github.com/repos/${this.owner}/${this.repo}/actions/workflows/${this.workflowId}/runs?per_page=10`;
    try {
      const res = await fetch(url, {
        headers: this.headers,
        signal: AbortSignal.timeout(8_000),
      });
      if (!res.ok) return [];

      const data = (await res.json()) as { workflow_runs: any[] };
      return (data.workflow_runs ?? []).map((r) => ({
        id: r.id as number,
        runNumber: r.run_number as number,
        status: r.status as string,
        conclusion: r.conclusion as string | null,
        createdAt: r.created_at as string,
        runUrl: r.html_url as string,
        triggeredBy: (r.triggering_actor?.login ?? r.event) as string,
      }));
    } catch (err) {
      this.logger.warn(`listBackups failed: ${(err as Error).message}`);
      return [];
    }
  }
}
