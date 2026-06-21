import { Controller, Post, Get, Body, UseGuards } from '@nestjs/common';
import { AdminService } from './admin.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Controller('admin')
@UseGuards(JwtAuthGuard)
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  @Post('backup/trigger')
  triggerBackup(@Body('reason') reason?: string) {
    return this.adminService.triggerBackup(reason);
  }

  @Get('backup/list')
  listBackups() {
    return this.adminService.listBackups();
  }
}
