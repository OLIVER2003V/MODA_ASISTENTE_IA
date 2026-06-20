import { Module } from '@nestjs/common';
import { PythonAiService } from './python-ai.service';

@Module({
  providers: [PythonAiService],
  exports:   [PythonAiService],
})
export class PythonAiModule {}
