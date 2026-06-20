import { IsOptional, IsIn } from 'class-validator';
import { Transform } from 'class-transformer';

export class UploadHairstylesDto {
  @IsOptional()
  @Transform(({ value }) => (value === '' ? undefined : value))
  @IsIn(['MALE', 'FEMALE', 'UNISEX'])
  gender?: string;
}
