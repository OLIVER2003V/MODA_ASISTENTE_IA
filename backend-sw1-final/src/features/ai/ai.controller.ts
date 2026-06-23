import {
  Controller,
  Post,
  Get,
  Body,
  Param,
  HttpCode,
  UseInterceptors,
  UploadedFile,
  BadRequestException,
  NotFoundException,
  ServiceUnavailableException,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { AiService } from './ai.service';
import {
  AskQuestionDto,
  AnalyzeImageDto,
  FixMultiplicityDto,
  ValidateDiagramDto,
  GenerateOutfitDto,
} from './dto';
import { Express } from 'express';

@Controller('ai')
export class AiController {
  constructor(private readonly aiService: AiService) {}

  @Post('ask')
  async askQuestion(@Body() askQuestionDto: AskQuestionDto) {
    return this.aiService.askQuestion(askQuestionDto);
  }

  @Post('fix-multiplicity')
  async fixMultiplicity(@Body() fixMultiplicityDto: FixMultiplicityDto) {
    return this.aiService.fixMultiplicity(fixMultiplicityDto.gojsDiagram);
  }

  @Post('analyze-image')
  @UseInterceptors(
    FileInterceptor('image', {
      limits: {
        fileSize: 20 * 1024 * 1024, // 20MB máximo
      },
      fileFilter: (req, file, callback) => {
        // Verificar que sea una imagen
        if (!file.mimetype.startsWith('image/')) {
          return callback(
            new BadRequestException('Solo se permiten archivos de imagen'),
            false,
          );
        }

        // Tipos de imagen soportados por OpenAI Vision
        const allowedMimeTypes = [
          'image/jpeg',
          'image/jpg',
          'image/png',
          'image/gif',
          'image/webp',
        ];

        if (!allowedMimeTypes.includes(file.mimetype)) {
          return callback(
            new BadRequestException(
              'Formato de imagen no soportado. Use: JPEG, PNG, GIF o WebP',
            ),
            false,
          );
        }

        callback(null, true);
      },
    }),
  )
  async analyzeImage(
    @UploadedFile() file: Express.Multer.File,
    @Body() analyzeImageDto: AnalyzeImageDto,
  ) {
    if (!file) {
      throw new BadRequestException('No se ha proporcionado ninguna imagen');
    }

    return this.aiService.analyzeImage(
      file.buffer,
      file.mimetype,
      analyzeImageDto.additionalContext,
    );
  }

  @Post('validate-diagram')
  async validateDiagram(@Body() validateDiagramDto: ValidateDiagramDto) {
    return this.aiService.validateAndCorrectDiagram(
      validateDiagramDto.gojsDiagram,
    );
  }

  @Post('generate-outfit')
  async generateOutfit(@Body() generateOutfitDto: GenerateOutfitDto) {
    return this.aiService.generateOutfit(generateOutfitDto);
  }

  @Post('retrain')
  async retrainModel() {
    const result = await this.aiService.retrainCompatibilityModel();
    if (!result)
      throw new ServiceUnavailableException('Python AI service no disponible');
    return result;
  }

  @Post('translate')
  async translate(@Body('text') text: string) {
    if (!text) throw new BadRequestException('Se requiere texto');
    return this.aiService.translateToSpanish(text);
  }

  @Post('generate-outfit-preview')
  async generateOutfitPreview(
    @Body('prompt') prompt: string,
    @Body('userId') userId?: string,
    @Body('outfitName') outfitName?: string,
  ) {
    if (!prompt) throw new BadRequestException('Se requiere un prompt');
    return this.aiService.generateOutfitPreview(prompt, userId, outfitName);
  }

  // ─── HU-18: Async queue endpoints (202/polling pattern) ─────────────────

  @Post('queue-generate')
  @HttpCode(202)
  queueOutfitGeneration(@Body() dto: GenerateOutfitDto) {
    const task = this.aiService.enqueueOutfitGeneration(dto);
    return {
      taskId: task.id,
      status: task.status,
      message: 'Outfit generation queued',
    };
  }

  @Get('task/:taskId')
  getTaskStatus(@Param('taskId') taskId: string) {
    const task = this.aiService.getTask(taskId);
    if (!task) throw new NotFoundException(`Task ${taskId} not found`);
    return {
      taskId: task.id,
      status: task.status,
      createdAt: task.createdAt,
      updatedAt: task.updatedAt,
      result: task.status === 'done' ? task.result : undefined,
      error: task.status === 'error' ? task.error : undefined,
    };
  }

  @Post('analyze-selfie')
  @UseInterceptors(
    FileInterceptor('file', {
      limits: { fileSize: 10 * 1024 * 1024 },
      fileFilter: (_, file, cb) => {
        const allowedMimes = [
          'image/jpeg',
          'image/jpg',
          'image/png',
          'image/webp',
        ];
        const ext = (file.originalname.split('.').pop() ?? '').toLowerCase();
        const allowedExts = ['jpg', 'jpeg', 'png', 'webp'];
        if (allowedMimes.includes(file.mimetype) || allowedExts.includes(ext)) {
          return cb(null, true);
        }
        cb(
          new BadRequestException('Solo se permiten imágenes JPG, PNG o WebP'),
          false,
        );
      },
    }),
  )
  async analyzeSelfie(
    @UploadedFile() file: Express.Multer.File,
    @Body('isFullBody') isFullBody?: string,
  ) {
    if (!file)
      throw new BadRequestException('No se proporcionó ninguna imagen');
    return this.aiService.analyzeSelfie(
      file.buffer,
      file.mimetype,
      isFullBody === 'true',
    );
  }
}
