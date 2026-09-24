import { Controller, Get } from '@nestjs/common';

@Controller()
export class AppController {
  @Get()
  getRoot() {
    return {
      status: 'online',
      name: 'SAMUDRA API — Sistem Antisipasi & Mitigasi Tsunami',
      version: '1.0.0',
      docs: '/api/docs',
      serverTime: new Date().toISOString(),
      endpoints: {
        latest_earthquake: '/api/earthquakes/latest',
        risk_calculation: '/api/earthquakes/risk?latitude={lat}&longitude={lng}',
        auth_login: '/api/auth/login',
        auth_register: '/api/auth/register',
      },
    };
  }
}
