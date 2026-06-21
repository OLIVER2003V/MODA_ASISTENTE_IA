import { Controller, Post, Get, Body, UseGuards, Headers } from '@nestjs/common';
import { AdminService } from './admin.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Controller('admin')
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  // No requiere JWT — usa secret header para bootstrap del primer admin
  @Post('promote')
  promoteToAdmin(
    @Body('email') email: string,
    @Headers('x-promote-secret') secret: string,
  ) {
    return this.adminService.promoteToAdmin(email, secret);
  }

  @Post('backup/trigger')
  @UseGuards(JwtAuthGuard)
  triggerBackup(@Body('reason') reason?: string) {
    return this.adminService.triggerBackup(reason);
  }

  @Get('backup/list')
  @UseGuards(JwtAuthGuard)
  listBackups() {
    return this.adminService.listBackups();
  }
}
