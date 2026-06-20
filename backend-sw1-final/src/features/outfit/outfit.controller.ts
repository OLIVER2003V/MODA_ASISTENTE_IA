import { Controller, Get, Post, Patch, Param, Delete, Body } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { OutfitService } from './outfit.service';
import { UpdateOutfitDto } from './dto/update-outfit.dto';
import { Auth }    from '../auth/decorators/auth.decorator';
import { GetUser } from '../auth/decorators/get-user.decorator';
import { User }    from 'generated/prisma/client';

@ApiTags('outfit')
@Controller('outfit')
export class OutfitController {
  constructor(private readonly outfitService: OutfitService) {}

  @Post('manual')
  @Auth()
  @ApiOperation({ summary: 'Create outfit manually with selected garments' })
  createManual(@Body() dto: { name: string; garmentIds: string[] }, @GetUser() user: User) {
    return this.outfitService.createManual(dto.name, dto.garmentIds, user.id);
  }

  @Get('user/:userId')
  @ApiOperation({ summary: 'Get all outfits for a user' })
  findByUserId(@Param('userId') userId: string) {
    return this.outfitService.findByUserId(userId);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get outfit by ID' })
  findOne(@Param('id') id: string) {
    return this.outfitService.findOne(id);
  }

  @Patch(':id')
  @Auth()
  @ApiOperation({ summary: 'Update outfit name/description' })
  update(@Param('id') id: string, @Body() dto: UpdateOutfitDto, @GetUser() user: User) {
    return this.outfitService.update(id, dto, user.id);
  }

  @Delete(':id')
  @Auth()
  @ApiOperation({ summary: 'Delete outfit' })
  remove(@Param('id') id: string, @GetUser() user: User) {
    return this.outfitService.remove(id, user.id);
  }

  @Post(':id/try-on')
  @Auth()
  @ApiOperation({ summary: 'Generate realistic try-on image for an outfit' })
  generateTryOn(@Param('id') id: string, @GetUser() user: User) {
    return this.outfitService.generateTryOn(id, user.id);
  }

  @Post(':id/try-on/regenerate')
  @Auth()
  @ApiOperation({ summary: 'Force regenerate try-on image (ignores cache)' })
  regenerateTryOn(@Param('id') id: string, @GetUser() user: User) {
    return this.outfitService.regenerateTryOn(id, user.id);
  }
}
