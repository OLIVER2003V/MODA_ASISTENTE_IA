export interface SocialBrandingImagen {
  titulo: string;
  paleta: string[]; // exactly 3 validated hex colors
  keywords: string[]; // 5 descriptive keywords
  tips: string[]; // 3 actionable styling tips
}

export interface SocialBrandingContenido {
  tipos: string[]; // 4 content format ideas
  frecuencia: string; // e.g. "3-4 veces por semana"
  ideas: string[]; // 3 concrete post ideas
}

export interface SocialBrandingHorarios {
  mejores: string[]; // 3 best time slots
  evitar: string; // times to avoid
}

export interface SocialBrandingTono {
  titulo: string;
  descripcion: string;
  tips: string[]; // 3 communication tips
}

export interface CaptionSet {
  idea: string;
  corta: string; // < 60 chars + hashtags
  media: string; // 100–160 chars + hashtags
  larga: string; // 200+ chars + hashtags
}

export interface CalendarDay {
  day: string; // e.g. "Lunes"
  type: string; // "OUTFIT" | "PHOTO" | "TIP" | "REST"
  hour: string; // e.g. "18:00"
  idea: string; // brief description
}

export interface SocialBrandingResponse {
  network: string;
  hasProfile: boolean;
  imagen: SocialBrandingImagen;
  contenido: SocialBrandingContenido;
  horarios: SocialBrandingHorarios;
  hashtags: string[];
  tono: SocialBrandingTono;
  captionTemplates: CaptionSet[];
  contentCalendar: CalendarDay[];
  trendingSearches: string[];
  profileChecklist: string[];
}

export interface UserStyleProfile {
  styles: string[];
  colors: string[];
  avoidColors: string[];
  gender: string | null;
  age: number | null;
  profession: string | null;
  bodyType: string | null;
  skinTone: string | null;
}
