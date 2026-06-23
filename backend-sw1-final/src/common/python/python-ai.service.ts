import { Injectable, Logger } from '@nestjs/common';

/** Shape returned by POST /face/analyze */
export interface FaceAnalysisResult {
  detected: boolean;
  face_shape: string | null;
  face_shape_note: string | null;
  ideal_query: string | null;
  measurements: Record<string, number | null> | null;
  embedding: number[] | null;
}

/** Shape returned by POST /hairstyle/recommend */
export interface HairstyleRankEntry {
  id: string;
  score: number;
  rank: number;
}
export interface HairstyleRecommendResult {
  detected: boolean;
  face_shape: string;
  face_shape_note: string | null;
  ideal_query: string;
  ranked: HairstyleRankEntry[];
  warnings: string[];
}

/** Shape returned by POST /garment/analyze */
export interface GarmentAnalysisResult {
  category: string;
  category_label: string;
  style: string;
  style_label: string;
  dominant_color: string | null;
  embedding: number[];
  confidence: { category: number; style: number };
}

/** Shape returned by POST /training/run */
export interface RetrainingResult {
  status: 'completed';
  message: string;
  metrics: {
    accuracy: number;
    f1_score: number;
    auc_roc: number;
    confusion_matrix: number[][];
    n_train: number;
    n_test: number;
    features: string[];
    clip_used: boolean;
    model: string;
    split: string;
  };
}

/** Shape returned by POST /outfit/score */
export interface OutfitCompatibilityResult {
  score: number;
  label: 'compatible' | 'incompatible';
  details: {
    style_consistency: number;
    color_harmony: number;
    formality_variance_inv: number;
    clip_text_similarity: number;
    category_balance: number;
  };
  warnings: string[];
  model_active: boolean;
}

/** Catalog item sent to Python's /hairstyle/recommend */
interface HairstyleCatalogItem {
  id: string;
  embedding: string | null;
  imageUrl: string | null;
  gender: string | null;
}

@Injectable()
export class PythonAiService {
  private readonly logger = new Logger(PythonAiService.name);
  private readonly baseUrl: string;

  constructor() {
    this.baseUrl = (
      process.env.PYTHON_AI_SERVICE_URL ?? 'http://localhost:8000'
    ).replace(/\/$/, '');
  }

  /** Returns true when the Python service is reachable. */
  async isAvailable(): Promise<boolean> {
    try {
      const res = await fetch(`${this.baseUrl}/health`, {
        signal: AbortSignal.timeout(3000),
      });
      return res.ok;
    } catch {
      return false;
    }
  }

  // ─── Face ──────────────────────────────────────────────────────────────────

  async analyzeFace(
    buffer: Buffer,
    mimetype: string,
  ): Promise<FaceAnalysisResult | null> {
    try {
      const form = new FormData();
      form.append(
        'file',
        new Blob([new Uint8Array(buffer)], { type: mimetype }),
        'face.jpg',
      );

      const res = await fetch(`${this.baseUrl}/face/analyze`, {
        method: 'POST',
        body: form,
        signal: AbortSignal.timeout(15_000),
      });

      if (!res.ok) {
        this.logger.warn(`/face/analyze returned HTTP ${res.status}`);
        return null;
      }
      return (await res.json()) as FaceAnalysisResult;
    } catch (err) {
      this.logger.warn(
        `Python service /face/analyze failed: ${(err as Error).message}`,
      );
      return null;
    }
  }

  // ─── Hairstyle ─────────────────────────────────────────────────────────────

  /** Compute and return the CLIP embedding for a hairstyle image. */
  async embedHairstyle(
    buffer: Buffer,
    mimetype: string,
  ): Promise<number[] | null> {
    try {
      const form = new FormData();
      form.append(
        'file',
        new Blob([new Uint8Array(buffer)], { type: mimetype }),
        'hairstyle.jpg',
      );

      const res = await fetch(`${this.baseUrl}/hairstyle/embed`, {
        method: 'POST',
        body: form,
        signal: AbortSignal.timeout(30_000),
      });

      if (!res.ok) {
        this.logger.warn(`/hairstyle/embed returned HTTP ${res.status}`);
        return null;
      }
      const data = (await res.json()) as { embedding: number[] };
      return data.embedding;
    } catch (err) {
      this.logger.warn(
        `Python service /hairstyle/embed failed: ${(err as Error).message}`,
      );
      return null;
    }
  }

  /** Rank catalog hairstyles for the given face photo. */
  async recommendHairstyles(
    faceBuffer: Buffer,
    mimetype: string,
    catalog: HairstyleCatalogItem[],
    userGender?: string | null,
  ): Promise<HairstyleRecommendResult | null> {
    try {
      const form = new FormData();
      form.append(
        'file',
        new Blob([new Uint8Array(faceBuffer)], { type: mimetype }),
        'face.jpg',
      );
      form.append('hairstyles', JSON.stringify(catalog));
      if (userGender) form.append('user_gender', userGender);

      const res = await fetch(`${this.baseUrl}/hairstyle/recommend`, {
        method: 'POST',
        body: form,
        // Allow time for on-the-fly image downloads inside Python
        signal: AbortSignal.timeout(60_000),
      });

      if (!res.ok) {
        const body = await res.text();
        this.logger.warn(
          `/hairstyle/recommend returned HTTP ${res.status}: ${body}`,
        );
        return null;
      }
      return (await res.json()) as HairstyleRecommendResult;
    } catch (err) {
      this.logger.warn(
        `Python service /hairstyle/recommend failed: ${(err as Error).message}`,
      );
      return null;
    }
  }

  // ─── Garment ───────────────────────────────────────────────────────────────

  async analyzeGarment(
    buffer: Buffer,
    mimetype: string,
  ): Promise<GarmentAnalysisResult | null> {
    try {
      const form = new FormData();
      form.append(
        'file',
        new Blob([new Uint8Array(buffer)], { type: mimetype }),
        'garment.jpg',
      );

      const res = await fetch(`${this.baseUrl}/garment/analyze`, {
        method: 'POST',
        body: form,
        signal: AbortSignal.timeout(30_000),
      });

      if (!res.ok) {
        this.logger.warn(`/garment/analyze returned HTTP ${res.status}`);
        return null;
      }
      return (await res.json()) as GarmentAnalysisResult;
    } catch (err) {
      this.logger.warn(
        `Python service /garment/analyze failed: ${(err as Error).message}`,
      );
      return null;
    }
  }

  // ─── Training ─────────────────────────────────────────────────────────────

  async triggerRetraining(): Promise<RetrainingResult | null> {
    try {
      const res = await fetch(`${this.baseUrl}/training/run`, {
        method: 'POST',
        signal: AbortSignal.timeout(120_000),
      });
      if (!res.ok) {
        this.logger.warn(`/training/run returned HTTP ${res.status}`);
        return null;
      }
      return (await res.json()) as RetrainingResult;
    } catch (err) {
      this.logger.warn(
        `Python service /training/run failed: ${(err as Error).message}`,
      );
      return null;
    }
  }

  // ─── Outfit Compatibility ──────────────────────────────────────────────────

  async scoreOutfitCompatibility(
    garments: Array<{ category: string; description: string }>,
    event: string,
  ): Promise<OutfitCompatibilityResult | null> {
    try {
      const res = await fetch(`${this.baseUrl}/outfit/score`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ garments, event }),
        signal: AbortSignal.timeout(5_000),
      });

      if (!res.ok) {
        this.logger.warn(`/outfit/score returned HTTP ${res.status}`);
        return null;
      }
      return (await res.json()) as OutfitCompatibilityResult;
    } catch (err) {
      this.logger.warn(
        `Python service /outfit/score failed: ${(err as Error).message}`,
      );
      return null;
    }
  }
}
