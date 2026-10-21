import { Module, Global } from '@nestjs/common';
import { StorageService } from './storage.service';
import { StorageController } from './storage.controller';

/**
 * StorageModule bersifat Global sehingga StorageService bisa
 * di-inject ke module mana saja tanpa perlu import ulang.
 */
@Global()
@Module({
  controllers: [StorageController],
  providers: [StorageService],
  exports: [StorageService],
})
export class StorageModule {}
