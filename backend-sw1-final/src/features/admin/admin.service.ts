import { Injectable, Logger } from '@nestjs/common';

export interface BackupRun {
  id: number;
  runNumber: number;
  status: string;
  conclusion: string | null;
  createdAt: string;
  runUrl: string;
  triggeredBy: string;
}

export interface TriggerResult {
  triggered: boolean;
  message: string;
}

@Injectable()
export class AdminService {
  private readonly logger = new Logger(AdminService.name);

  private readonly owner = 'OLIVER2003V';
  private readonly repo = 'MODA_ASISTENTE_IA';
  private readonly workflowId = 'database-backup.yml';

  private get token(): string | undefined {
    return process.env.GITHUB_PERSONAL_TOKEN;
  }

  private get headers() {
    return {
      Authorization: `Bearer ${this.token}`,
      Accept: 'application/vnd.github+json',
      'Content-Type': 'application/json',
      'X-GitHub-Api-Version': '2022-11-28',
    };
  }

  async triggerBackup(
    reason = 'Manual backup via app',
  ): Promise<TriggerResult> {
    if (!this.token) {
      return {
        triggered: false,
        message: 'GITHUB_PERSONAL_TOKEN no configurado en el servidor',
      };
    }

    const url = `https://api.github.com/repos/${this.owner}/${this.repo}/actions/workflows/${this.workflowId}/dispatches`;
    try {
      const res = await fetch(url, {
        method: 'POST',
        headers: this.headers,
        body: JSON.stringify({ ref: 'main', inputs: { reason } }),
        signal: AbortSignal.timeout(10_000),
      });

      if (res.status === 204) {
        return { triggered: true, message: 'Respaldo iniciado correctamente' };
      }

      const body = await res.text();
      this.logger.warn(`GitHub dispatch returned ${res.status}: ${body}`);
      return { triggered: false, message: `Error de GitHub: ${res.status}` };
    } catch (err) {
      this.logger.error(`triggerBackup failed: ${(err as Error).message}`);
      return { triggered: false, message: 'No se pudo contactar con GitHub' };
    }
  }

  async listBackups(): Promise<BackupRun[]> {
    if (!this.token) return [];

    const url = `https://api.github.com/repos/${this.owner}/${this.repo}/actions/workflows/${this.workflowId}/runs?per_page=10`;
    try {
      const res = await fetch(url, {
        headers: this.headers,
        signal: AbortSignal.timeout(8_000),
      });
      if (!res.ok) return [];

      const data = (await res.json()) as { workflow_runs: any[] };
      return (data.workflow_runs ?? []).map((r) => ({
        id: r.id as number,
        runNumber: r.run_number as number,
        status: r.status as string,
        conclusion: r.conclusion as string | null,
        createdAt: r.created_at as string,
        runUrl: r.html_url as string,
        triggeredBy: (r.triggering_actor?.login ?? r.event) as string,
      }));
    } catch (err) {
      this.logger.warn(`listBackups failed: ${(err as Error).message}`);
      return [];
    }
  }
}
