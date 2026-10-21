import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { HttpService } from '@nestjs/axios';
import { Earthquake } from './entities/earthquake.entity';
import * as xml2js from 'xml2js';
import { firstValueFrom } from 'rxjs';
import { parse } from 'date-fns';

@Injectable()
export class EarthquakesService {
  private readonly logger = new Logger(EarthquakesService.name);

  constructor(
    @InjectRepository(Earthquake)
    private earthquakesRepository: Repository<Earthquake>,
    private httpService: HttpService,
  ) {}

  async fetchAndSaveLatestEarthquake(): Promise<void> {
    try {
      const response = await firstValueFrom(
        this.httpService.get('https://data.bmkg.go.id/DataMKG/TEWS/autogempa.xml', {
          responseType: 'text',
        }),
      );

      const parser = new xml2js.Parser({ explicitArray: false });
      const result = await parser.parseStringPromise(response.data);
      const gempa = result.Infogempa.gempa;

      // Extract values
      const dateStr = gempa.Tanggal;
      const timeStr = gempa.Jam;
      // Combine and parse '18 Sep 2026' and '10:00:00 WIB'
      let occurredAt = new Date();
      if (gempa.DateTime) {
        const parsed = new Date(gempa.DateTime);
        if (!isNaN(parsed.getTime())) occurredAt = parsed;
      } else {
        const monthMap: Record<string, string> = {
          Jan: 'Jan', Feb: 'Feb', Mar: 'Mar', Apr: 'Apr', Mei: 'May', Jun: 'Jun',
          Jul: 'Jul', Agu: 'Aug', Sep: 'Sep', Okt: 'Oct', Nov: 'Nov', Des: 'Dec',
        };
        let normalizedDate = dateStr;
        for (const [idMonth, enMonth] of Object.entries(monthMap)) {
          normalizedDate = normalizedDate.replace(idMonth, enMonth);
        }
        const parsed = new Date(`${normalizedDate} ${timeStr.replace(' WIB', '')} GMT+0700`);
        if (!isNaN(parsed.getTime())) {
          occurredAt = parsed;
        }
      }

      // Koordinat: "5.59 LS - 110.15 BT" => BMKG provides coordinates as "-5.59,110.15" in <point> or <Lintang> etc.
      // Koordinat: BMKG provides coordinates as "-5.59,110.15" in <point><coordinates>
      const coords = gempa.point.coordinates.split(',');
      const latitude = parseFloat(coords[0]);
      const longitude = parseFloat(coords[1]);

      const magnitude = parseFloat(gempa.Magnitude);
      const depthKm = parseFloat(gempa.Kedalaman.replace(/ km/i, ''));
      const potentialTsunami = gempa.Potensi.toLowerCase().includes('tsunami');
      
      const bmkgRefId = `${gempa.Tanggal}-${gempa.Jam}-${magnitude}-${depthKm}`; // unique enough

      // Check if exists
      const existing = await this.earthquakesRepository.findOne({ where: { bmkgRefId } });
      if (!existing) {
        const newEarthquake = this.earthquakesRepository.create({
          bmkgRefId,
          magnitude,
          depthKm,
          latitude,
          longitude,
          region: gempa.Wilayah,
          potentialTsunami,
          occurredAt,
        });
        await this.earthquakesRepository.save(newEarthquake);
        this.logger.log(`New earthquake saved: ${gempa.Wilayah} - Mag ${magnitude}`);
      }
    } catch (error) {
      this.logger.error('Failed to fetch/save BMKG data', error);
    }
  }

  async getLatestEarthquake(): Promise<Earthquake | null> {
    const list = await this.earthquakesRepository.find({
      order: { occurredAt: 'DESC' },
      take: 1,
    });
    return list.length > 0 ? list[0] : null;
  }

  calculateRisk(earthquake: Earthquake | null, userLat: number, userLng: number) {
    if (!earthquake) return { risk: 'Aman', distance: null };

    const distance = this.haversineDistance(userLat, userLng, earthquake.latitude, earthquake.longitude);

    let risk = 'Aman';
    if (earthquake.potentialTsunami) {
       if (distance < 50) risk = 'Awas';
       else if (distance < 200) risk = 'Siaga';
       else if (distance < 500) risk = 'Waspada';
    } else {
       if (earthquake.magnitude >= 6.0 && distance < 100) risk = 'Waspada';
       else if (earthquake.magnitude >= 5.0 && distance < 50) risk = 'Waspada';
    }

    return {
      risk,
      distance,
      earthquake,
    };
  }

  private haversineDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
    const R = 6371; // Radius of Earth in km
    const dLat = this.deg2rad(lat2 - lat1);
    const dLon = this.deg2rad(lon2 - lon1);
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(this.deg2rad(lat1)) * Math.cos(this.deg2rad(lat2)) *
      Math.sin(dLon / 2) * Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
  }

  private deg2rad(deg: number): number {
    return deg * (Math.PI / 180);
  }
}
