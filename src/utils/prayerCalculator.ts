// محرك حساب مواقيت الصلاة الفلكي مطابق لخوارزمية تطبيق صلاتي (Prayer Calculator)
export interface PrayerMethod {
  id: string;
  apiId: number;
  arLabel: string;
  enLabel: string;
  fajrAngle: number;
  ishaAngle: number | null;
  ishaMinutes?: number;
}

export const PRAYER_METHODS: Record<string, PrayerMethod> = {
  egyptian: {
    id: 'egyptian',
    apiId: 5,
    arLabel: 'الهيئة المصرية العامة للمساحة',
    enLabel: 'Egyptian General Authority',
    fajrAngle: 19.5,
    ishaAngle: 17.5,
  },
  ummAlQura: {
    id: 'ummAlQura',
    apiId: 4,
    arLabel: 'أم القرى — مكة المكرمة',
    enLabel: 'Umm Al-Qura, Makkah',
    fajrAngle: 18.5,
    ishaAngle: null,
    ishaMinutes: 90,
  },
  mwl: {
    id: 'mwl',
    apiId: 3,
    arLabel: 'رابطة العالم الإسلامي',
    enLabel: 'Muslim World League',
    fajrAngle: 18.0,
    ishaAngle: 17.0,
  },
  isna: {
    id: 'isna',
    apiId: 2,
    arLabel: 'الجمعية الإسلامية لأمريكا الشمالية (ISNA)',
    enLabel: 'ISNA (North America)',
    fajrAngle: 15.0,
    ishaAngle: 15.0,
  },
  karachi: {
    id: 'karachi',
    apiId: 1,
    arLabel: 'جامعة العلوم الإسلامية — كراتشي',
    enLabel: 'University of Islamic Sciences, Karachi',
    fajrAngle: 18.0,
    ishaAngle: 18.0,
  },
  dubai: {
    id: 'dubai',
    apiId: 16,
    arLabel: 'الإمارات — دبي',
    enLabel: 'Dubai (UAE)',
    fajrAngle: 18.2,
    ishaAngle: 18.2,
  },
  kuwait: {
    id: 'kuwait',
    apiId: 9,
    arLabel: 'الكويت',
    enLabel: 'Kuwait',
    fajrAngle: 18.0,
    ishaAngle: 17.5,
  },
  qatar: {
    id: 'qatar',
    apiId: 10,
    arLabel: 'قطر',
    enLabel: 'Qatar',
    fajrAngle: 18.0,
    ishaAngle: null,
    ishaMinutes: 90,
  },
  singapore: {
    id: 'singapore',
    apiId: 11,
    arLabel: 'سنغافورة',
    enLabel: 'Singapore',
    fajrAngle: 20.0,
    ishaAngle: 18.0,
  },
  turkey: {
    id: 'turkey',
    apiId: 13,
    arLabel: 'تركيا — ديانت',
    enLabel: 'Turkey (Diyanet)',
    fajrAngle: 18.0,
    ishaAngle: 17.0,
  },
  tehran: {
    id: 'tehran',
    apiId: 7,
    arLabel: 'إيران — طهران',
    enLabel: 'Tehran',
    fajrAngle: 17.7,
    ishaAngle: 14.0,
  },
  morocco: {
    id: 'morocco',
    apiId: 21,
    arLabel: 'المملكة المغربية',
    enLabel: 'Morocco',
    fajrAngle: 19.0,
    ishaAngle: 17.0,
  },
  algeria: {
    id: 'algeria',
    apiId: 19,
    arLabel: 'الجمهورية الجزائرية',
    enLabel: 'Algeria',
    fajrAngle: 18.0,
    ishaAngle: 17.0,
  },
  tunisia: {
    id: 'tunisia',
    apiId: 20,
    arLabel: 'الجمهورية التونسية',
    enLabel: 'Tunisia',
    fajrAngle: 18.0,
    ishaAngle: 18.0,
  },
  jordan: {
    id: 'jordan',
    apiId: 23,
    arLabel: 'المملكة الأردنية الهاشمية',
    enLabel: 'Jordan',
    fajrAngle: 18.0,
    ishaAngle: 18.0,
  },
};

export interface CityData {
  ar: string;
  en: string;
  countryAr: string;
  countryEn: string;
  lat: number;
  lng: number;
  defaultMethod: string;
}

export const CITIES_LIST: CityData[] = [
  { ar: 'القاهرة', en: 'Cairo', countryAr: 'مصر', countryEn: 'Egypt', lat: 30.0444, lng: 31.2357, defaultMethod: 'egyptian' },
  { ar: 'الجيزة', en: 'Giza', countryAr: 'مصر', countryEn: 'Egypt', lat: 30.0131, lng: 31.2089, defaultMethod: 'egyptian' },
  { ar: 'الإسكندرية', en: 'Alexandria', countryAr: 'مصر', countryEn: 'Egypt', lat: 31.2001, lng: 29.9187, defaultMethod: 'egyptian' },
  { ar: 'مكة المكرمة', en: 'Makkah', countryAr: 'السعودية', countryEn: 'Saudi Arabia', lat: 21.3891, lng: 39.8579, defaultMethod: 'ummAlQura' },
  { ar: 'المدينة المنورة', en: 'Madinah', countryAr: 'السعودية', countryEn: 'Saudi Arabia', lat: 24.4672, lng: 39.6111, defaultMethod: 'ummAlQura' },
  { ar: 'الرياض', en: 'Riyadh', countryAr: 'السعودية', countryEn: 'Saudi Arabia', lat: 24.7136, lng: 46.6753, defaultMethod: 'ummAlQura' },
  { ar: 'دبي', en: 'Dubai', countryAr: 'الإمارات', countryEn: 'UAE', lat: 25.2048, lng: 55.2708, defaultMethod: 'dubai' },
  { ar: 'أبوظبي', en: 'Abu Dhabi', countryAr: 'الإمارات', countryEn: 'UAE', lat: 24.4539, lng: 54.3773, defaultMethod: 'dubai' },
  { ar: 'القدس الشريف', en: 'Jerusalem', countryAr: 'فلسطين', countryEn: 'Palestine', lat: 31.7683, lng: 35.2137, defaultMethod: 'jordan' },
  { ar: 'غزة', en: 'Gaza', countryAr: 'فلسطين', countryEn: 'Palestine', lat: 31.5017, lng: 34.4668, defaultMethod: 'egyptian' },
  { ar: 'عمّان', en: 'Amman', countryAr: 'الأردن', countryEn: 'Jordan', lat: 31.9454, lng: 35.9284, defaultMethod: 'jordan' },
  { ar: 'الدوحة', en: 'Doha', countryAr: 'قطر', countryEn: 'Qatar', lat: 25.2854, lng: 51.5310, defaultMethod: 'qatar' },
  { ar: 'الكويت', en: 'Kuwait City', countryAr: 'الكويت', countryEn: 'Kuwait', lat: 29.3759, lng: 47.9774, defaultMethod: 'kuwait' },
  { ar: 'المنامة', en: 'Manama', countryAr: 'البحرين', countryEn: 'Bahrain', lat: 26.2285, lng: 50.5860, defaultMethod: 'mwl' },
  { ar: 'مسقط', en: 'Muscat', countryAr: 'عمان', countryEn: 'Oman', lat: 23.5880, lng: 58.3829, defaultMethod: 'mwl' },
  { ar: 'بيروت', en: 'Beirut', countryAr: 'لبنان', countryEn: 'Lebanon', lat: 33.8938, lng: 35.5018, defaultMethod: 'mwl' },
  { ar: 'دمشق', en: 'Damascus', countryAr: 'سوريا', countryEn: 'Syria', lat: 33.5138, lng: 36.2765, defaultMethod: 'mwl' },
  { ar: 'بغداد', en: 'Baghdad', countryAr: 'العراق', countryEn: 'Iraq', lat: 33.3152, lng: 44.3661, defaultMethod: 'mwl' },
  { ar: 'الرباط', en: 'Rabat', countryAr: 'المغرب', countryEn: 'Morocco', lat: 34.0209, lng: -6.8416, defaultMethod: 'morocco' },
  { ar: 'الدار البيضاء', en: 'Casablanca', countryAr: 'المغرب', countryEn: 'Morocco', lat: 33.5731, lng: -7.5898, defaultMethod: 'morocco' },
  { ar: 'الجزائر', en: 'Algiers', countryAr: 'الجزائر', countryEn: 'Algeria', lat: 36.7538, lng: 3.0588, defaultMethod: 'algeria' },
  { ar: 'تونس', en: 'Tunis', countryAr: 'تونس', countryEn: 'Tunisia', lat: 36.8065, lng: 10.1815, defaultMethod: 'tunisia' },
  { ar: 'طرابلس', en: 'Tripoli', countryAr: 'ليبيا', countryEn: 'Libya', lat: 32.8872, lng: 13.1913, defaultMethod: 'egyptian' },
  { ar: 'الخرطوم', en: 'Khartoum', countryAr: 'السودان', countryEn: 'Sudan', lat: 15.5007, lng: 32.5599, defaultMethod: 'egyptian' },
  { ar: 'صنعاء', en: 'Sanaa', countryAr: 'اليمن', countryEn: 'Yemen', lat: 15.3694, lng: 44.1910, defaultMethod: 'ummAlQura' },
  { ar: 'إستانبول', en: 'Istanbul', countryAr: 'تركيا', countryEn: 'Turkey', lat: 41.0082, lng: 28.9784, defaultMethod: 'turkey' },
  { ar: 'لندن', en: 'London', countryAr: 'بريطانيا', countryEn: 'UK', lat: 51.5074, lng: -0.1278, defaultMethod: 'mwl' },
  { ar: 'نيويورك', en: 'New York', countryAr: 'أمريكا', countryEn: 'USA', lat: 40.7128, lng: -74.0060, defaultMethod: 'isna' },
  { ar: 'باريس', en: 'Paris', countryAr: 'فرنسا', countryEn: 'France', lat: 48.8566, lng: 2.3522, defaultMethod: 'mwl' },
  { ar: 'كراتشي', en: 'Karachi', countryAr: 'باكستان', countryEn: 'Pakistan', lat: 24.8607, lng: 67.0011, defaultMethod: 'karachi' },
  { ar: 'جاكرتا', en: 'Jakarta', countryAr: 'إندونيسيا', countryEn: 'Indonesia', lat: -6.2088, lng: 106.8456, defaultMethod: 'singapore' },
  { ar: 'كوالالمبور', en: 'Kuala Lumpur', countryAr: 'ماليزيا', countryEn: 'Malaysia', lat: 3.1390, lng: 101.6869, defaultMethod: 'singapore' },
];

export class PrayerEngine {
  private static d2r(d: number): number {
    return (d * Math.PI) / 180.0;
  }
  private static r2d(r: number): number {
    return (r * 180.0) / Math.PI;
  }
  private static sin(d: number): number {
    return Math.sin(this.d2r(d));
  }
  private static cos(d: number): number {
    return Math.cos(this.d2r(d));
  }
  private static tan(d: number): number {
    return Math.tan(this.d2r(d));
  }

  private static fixAngle(a: number): number {
    a = a - 360.0 * Math.floor(a / 360.0);
    return a < 0 ? a + 360.0 : a;
  }

  private static fixHour(h: number): number {
    h = h - 24.0 * Math.floor(h / 24.0);
    return h < 0 ? h + 24.0 : h;
  }

  private static julianDate(year: number, month: number, day: number): number {
    if (month <= 2) {
      year -= 1;
      month += 12;
    }
    const a = Math.floor(year / 100);
    const b = 2 - a + Math.floor(a / 4);
    return Math.floor(365.25 * (year + 4716)) + Math.floor(30.6001 * (month + 1)) + day + b - 1524.5;
  }

  private static sunPosition(jd: number): { decl: number; eqt: number } {
    const d = jd - 2451545.0;
    const g = this.fixAngle(357.529 + 0.98560028 * d);
    const q = this.fixAngle(280.459 + 0.98564736 * d);
    const l = this.fixAngle(q + 1.915 * this.sin(g) + 0.02 * this.sin(2 * g));
    const e = 23.439 - 0.00000036 * d;
    const ra = this.fixHour(this.r2d(Math.atan2(this.cos(e) * this.sin(l), this.cos(l))) / 15.0);
    const decl = this.r2d(Math.asin(this.sin(e) * this.sin(l)));
    return { decl, eqt: q / 15.0 - ra };
  }

  public static calculateRawTimes({
    date,
    latitude,
    longitude,
    method,
    madhab = 'shafi',
    dhuhrMinutes = 0,
    maghribMinutes = 0,
    elevation = 0,
    tzOffsetHours,
  }: {
    date: Date;
    latitude: number;
    longitude: number;
    method: PrayerMethod;
    madhab?: 'shafi' | 'hanafi';
    dhuhrMinutes?: number;
    maghribMinutes?: number;
    elevation?: number;
    tzOffsetHours?: number;
  }): Record<string, number> {
    const jdBase = this.julianDate(date.getFullYear(), date.getMonth() + 1, date.getDate()) - longitude / (15.0 * 24.0);

    const sunAt = (tHours: number) => this.sunPosition(jdBase + tHours / 24.0);

    const transitTime = this.fixHour(12.0 - sunAt(12).eqt);
    const decl = sunAt(12).decl;

    const hourAngleFromAltitude = (altitude: number): number => {
      const cosH = (this.sin(altitude) - this.sin(decl) * this.sin(latitude)) / (this.cos(decl) * this.cos(latitude));
      if (cosH < -1 || cosH > 1) return NaN;
      return this.r2d(Math.acos(cosH)) / 15.0;
    };

    const fajrAngle = method.fajrAngle;
    const ishaAngle = method.ishaAngle;

    const riseSetAltitude = -0.833 - 0.0347 * Math.sqrt(Math.max(0, Math.min(elevation, 6000)));
    const asrFactor = madhab === 'hanafi' ? 2.0 : 1.0;

    const asrTime = (): number => {
      const angle = this.r2d(Math.atan(1.0 / (asrFactor + this.tan(Math.abs(latitude - decl)))));
      const h = hourAngleFromAltitude(angle);
      return transitTime + (isNaN(h) ? 5.0 : h);
    };

    let fajrH = hourAngleFromAltitude(-fajrAngle);
    let sunriseH = hourAngleFromAltitude(riseSetAltitude);
    let sunsetH = hourAngleFromAltitude(riseSetAltitude);

    if (isNaN(sunriseH) || isNaN(sunsetH)) {
      sunriseH = 6.0;
      sunsetH = 6.0;
    }
    const nightLength = Math.max(0, Math.min(24.0, 24.0 - 2 * sunsetH));
    const asr = asrTime();

    let isha: number;
    if (ishaAngle !== null && ishaAngle !== undefined) {
      const h = hourAngleFromAltitude(-ishaAngle);
      const fallback = sunsetH + nightLength / 7.0;
      isha = transitTime + (isNaN(h) ? fallback : h);
    } else {
      isha = transitTime + sunsetH + (method.ishaMinutes ?? 90) / 60.0;
    }

    if (isNaN(fajrH)) {
      fajrH = sunriseH + nightLength / 7.0;
    }

    const offset = tzOffsetHours !== undefined ? tzOffsetHours : -date.getTimezoneOffset() / 60.0;
    const gmtDiff = offset - longitude / 15.0;
    const adjust = (t: number) => this.fixHour(t + gmtDiff);

    return {
      fajr: adjust(transitTime - (isNaN(fajrH) ? 0 : fajrH)),
      sunrise: adjust(transitTime - (isNaN(sunriseH) ? 0 : sunriseH)),
      dhuhr: adjust(transitTime + dhuhrMinutes / 60.0),
      asr: adjust(asr),
      maghrib: adjust(transitTime + (isNaN(sunsetH) ? 0 : sunsetH) + maghribMinutes / 60.0),
      isha: adjust(isha),
    };
  }

  public static getPrayerDates({
    date,
    latitude,
    longitude,
    method,
    madhab = 'shafi',
    dhuhrMinutes = 0,
    maghribMinutes = 0,
    elevation = 0,
    adjustments = {},
    tzOffsetHours,
  }: {
    date: Date;
    latitude: number;
    longitude: number;
    method: PrayerMethod;
    madhab?: 'shafi' | 'hanafi';
    dhuhrMinutes?: number;
    maghribMinutes?: number;
    elevation?: number;
    adjustments?: Record<string, number>;
    tzOffsetHours?: number;
  }): Record<string, Date> {
    const raw = this.calculateRawTimes({
      date,
      latitude,
      longitude,
      method,
      madhab,
      dhuhrMinutes,
      maghribMinutes,
      elevation,
      tzOffsetHours,
    });

    const result: Record<string, Date> = {};
    const base = new Date(date.getFullYear(), date.getMonth(), date.getDate());

    for (const [key, hours] of Object.entries(raw)) {
      const adj = adjustments[key] ?? 0;
      const totalHours = hours + adj / 60.0;
      const d = new Date(base.getTime() + Math.round(totalHours * 3600 * 1000));
      result[key] = d;
    }

    return result;
  }

  public static qiblaDirection(latitude: number, longitude: number): number {
    const kaabaLat = 21.4225;
    const kaabaLng = 39.8262;
    const phiK = this.d2r(kaabaLat);
    const phi = this.d2r(latitude);
    const dLng = this.d2r(kaabaLng - longitude);
    const y = Math.sin(dLng);
    const x = Math.cos(phi) * Math.tan(phiK) - Math.sin(phi) * Math.cos(dLng);
    const deg = this.r2d(Math.atan2(y, x));
    return (deg + 360.0) % 360.0;
  }

  public static distanceToKaaba(latitude: number, longitude: number): number {
    const kaabaLat = 21.4225;
    const kaabaLng = 39.8262;
    const r = 6371.0;
    const dLat = this.d2r(kaabaLat - latitude);
    const dLng = this.d2r(kaabaLng - longitude);
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      this.cos(latitude) * this.cos(kaabaLat) * Math.sin(dLng / 2) * Math.sin(dLng / 2);
    return 2 * r * Math.asin(Math.sqrt(a));
  }
}
