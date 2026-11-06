param([string]$VapidPublicKey = $env:VITE_VAPID_PUBLIC_KEY)
$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($VapidPublicKey)) { throw 'Provide the public VAPID key through VITE_VAPID_PUBLIC_KEY or -VapidPublicKey.' }
$workspace = Split-Path $PSScriptRoot -Parent
Push-Location (Join-Path $workspace 'apps/citizen-web')
try {
  $env:FIGMA_PUBLIC_URL = '/reporte-ciudadano-app'
  $env:VITE_VAPID_PUBLIC_KEY = $VapidPublicKey
  pnpm install --frozen-lockfile
  if ($LASTEXITCODE -ne 0) { throw 'Dependency installation failed.' }
  pnpm exec tsc --noEmit
  if ($LASTEXITCODE -ne 0) { throw 'Type checking failed.' }
  pnpm build
  if ($LASTEXITCODE -ne 0) { throw 'Web build failed.' }
  node (Join-Path $PSScriptRoot 'verify-citizen-assets.mjs')
  if ($LASTEXITCODE -ne 0) { throw 'Visual asset verification failed.' }
} finally { Pop-Location }
