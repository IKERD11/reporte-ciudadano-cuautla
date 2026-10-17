import type {Report, Summary} from './api';

// Dates in this pilot refer to Cuautla's calendar, not the browser's timezone.
export function municipalDate(value: string): string {
  return value ? `${value}T00:00:00-06:00` : '';
}

export function summarizeReports(rows: Report[]): Summary {
  const group = (key: 'category' | 'status') => [...new Set(rows.map(r => r[key]))]
    .map(name => ({name, count: rows.filter(r => r[key] === name).length}));
  return {
    total: rows.length,
    pending: rows.filter(r => ['RECIBIDO','EN_REVISION','VALIDADO','ASIGNADO'].includes(r.status_code)).length,
    progress: rows.filter(r => r.status_code === 'EN_ATENCION').length,
    resolved: rows.filter(r => ['RESUELTO','CERRADO'].includes(r.status_code)).length,
    resolution_days: null,
    categories: group('category'), statuses: group('status'), weeks: [],
  };
}

export function reportsCsv(rows: Report[]): string {
  const cell = (value: unknown) => {
    let text = String(value ?? '');
    // Untrusted descriptions must not become spreadsheet formulas.
    if (/^[\s]*[=+@-]/.test(text) || /^[\t\r\n]/.test(text)) text = "'" + text;
    return '"' + text.replaceAll('"', '""') + '"';
  };
  return '\uFEFF' + [
    ['Folio','Descripción','Dirección','Categoría','Estado','Prioridad','Fecha UTC'],
    ...rows.map(r => [r.folio,r.description,r.address,r.category,r.status,r.priority,r.created_at]),
  ].map(row => row.map(cell).join(',')).join('\r\n');
}
