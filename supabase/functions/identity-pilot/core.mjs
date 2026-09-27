import fixtures from './fixtures.json' with { type: 'json' };

export class PilotError extends Error {
  constructor(message, status = 400) { super(message); this.status = status; }
}
export const uuid = value => typeof value === 'string' && /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(value);
export async function validateSynthetic(side, bytes) {
  const fixture = fixtures[side];
  if (!fixture || !(bytes instanceof Uint8Array) || bytes.length !== fixture.bytes) {
    throw new PilotError('Solo se aceptan las muestras sintéticas incluidas.');
  }
  const hash = Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256', bytes)), b => b.toString(16).padStart(2, '0')).join('');
  if (hash !== fixture.sha256) throw new PilotError('El archivo no es una muestra sintética autorizada.');
  return { mime: 'image/png', width: fixture.width, height: fixture.height, bytes: bytes.length };
}
// OCR solo extrae información. Este piloto no procesa documentos personales.
export class OcrProvider {
  async extract(_images) { throw new Error('Implementar adaptador OCR'); }
}
export class DisabledOcrProvider extends OcrProvider {
  async extract(_images) { return { status: 'disabled', fields: {} }; }
}
export class IdentityVerificationProvider {
  async evaluate(_input) { throw new Error('Implementar proveedor de verificación'); }
}
export class ManualPilotProvider extends IdentityVerificationProvider {
  async evaluate(input) {
    if (input.synthetic !== true) throw new PilotError('La verificación real está deshabilitada.', 403);
    return { status: 'UNDER_REVIEW', verified: false, provider: 'manual-pilot' };
  }
}
export async function readLimitedBody(request, maxBytes = 45000) {
  if (!request.body) throw new PilotError('Falta la solicitud.');
  const reader = request.body.getReader(); const chunks = []; let size = 0;
  try {
    for (;;) {
      const {done, value} = await reader.read(); if (done) break;
      size += value.byteLength;
      if (size > maxBytes) { await reader.cancel(); throw new PilotError('Solicitud demasiado grande.', 413); }
      chunks.push(value);
    }
  } finally { reader.releaseLock(); }
  const bytes = new Uint8Array(size); let offset = 0;
  for (const chunk of chunks) { bytes.set(chunk, offset); offset += chunk.length; }
  try { return JSON.parse(new TextDecoder().decode(bytes)); }
  catch { throw new PilotError('JSON inválido.'); }
}
