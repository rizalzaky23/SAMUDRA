import { Test, TestingModule } from '@nestjs/testing';
import { EarthquakesController } from './earthquakes.controller';

describe('EarthquakesController', () => {
  let controller: EarthquakesController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [EarthquakesController],
    }).compile();

    controller = module.get<EarthquakesController>(EarthquakesController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });
});
