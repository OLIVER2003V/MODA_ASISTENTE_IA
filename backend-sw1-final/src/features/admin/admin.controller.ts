import {
  Controller,
  Post,
  Get,
  Patch,
  Body,
  Param,
  UseGuards,
  Headers,
  Query,
} from '@nestjs/common';
import { AdminService } from './admin.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { AdminGuard } from 'src/common/guards/admin.guard';

@Controller('admin')
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  // Bootstrap — no requiere JWT, usa secret header
  @Post('promote')
  promoteToAdmin(
    @Body('email') email: string,
    @Headers('x-promote-secret') secret: string,
  ) {
    return this.adminService.promoteToAdmin(email, secret);
  }

  // ── Dashboard (todos requieren JWT + AdminGuard) ───────────────────────────

  @Get('stats')
  @UseGuards(JwtAuthGuard, AdminGuard)
  getStats() {
    return this.adminService.getStats();
  }

  @Get('users')
  @UseGuards(JwtAuthGuard, AdminGuard)
  getUsers(
    @Query('page') page = '1',
    @Query('limit') limit = '20',
    @Query('search') search = '',
    @Query('role') role = '',
  ) {
    return this.adminService.getUsers(+page, +limit, search, role);
  }

  @Patch('users/:id')
  @UseGuards(JwtAuthGuard, AdminGuard)
  updateUser(
    @Param('id') id: string,
    @Body() body: { role?: string; isActive?: boolean },
  ) {
    return this.adminService.updateUser(id, body as any);
  }

  @Get('reports')
  @UseGuards(JwtAuthGuard, AdminGuard)
  getReports() {
    return this.adminService.getReports();
  }

  @Get('metrics')
  @UseGuards(JwtAuthGuard, AdminGuard)
  getMetrics() {
    return this.adminService.getMetrics();
  }

  @Get('revenue')
  @UseGuards(JwtAuthGuard, AdminGuard)
  getRevenue() {
    return this.adminService.getRevenue();
  }

  @Get('engagement')
  @UseGuards(JwtAuthGuard, AdminGuard)
  getEngagement() {
    return this.adminService.getEngagement();
  }

  @Get('segments')
  @UseGuards(JwtAuthGuard, AdminGuard)
  getSegments() {
    return this.adminService.getSegments();
  }

  @Get('activity')
  @UseGuards(JwtAuthGuard, AdminGuard)
  getActivity() {
    return this.adminService.getActivity();
  }

  // ── Backup ────────────────────────────────────────────────────────────────

  @Post('backup/trigger')
  @UseGuards(JwtAuthGuard, AdminGuard)
  triggerBackup(@Body('reason') reason?: string) {
    return this.adminService.triggerBackup(reason);
  }

  @Get('backup/list')
  @UseGuards(JwtAuthGuard, AdminGuard)
  listBackups() {
    return this.adminService.listBackups();
  }
}
