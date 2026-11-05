{{flutter_js}}
{{flutter_build_config}}
// A release-specific URL bypasses stale HTTP and legacy Flutter worker entries.
// The stable build token keeps caching effective between visits to the same release.
for (const build of _flutter.buildConfig.builds) {
  if (build.mainJsPath) {
    build.mainJsPath += '?release={{flutter_service_worker_version}}';
  }
}
_flutter.loader.load({config: {canvasKitBaseUrl: 'canvaskit/'}});
