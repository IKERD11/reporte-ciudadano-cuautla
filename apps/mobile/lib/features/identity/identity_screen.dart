import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../auth/application/auth_controller.dart';
import 'identity_repository.dart';

class IdentityScreen extends StatefulWidget {
  const IdentityScreen({
    super.key,
    required this.repository,
    required this.auth,
  });
  final IdentityRepository repository;
  final AuthController auth;
  @override
  State<IdentityScreen> createState() => _IdentityScreenState();
}

class _IdentityScreenState extends State<IdentityScreen> {
  bool busy = true, accepted = false;
  String? error;
  Map<String, dynamic>? data;
  late final String userId;
  late final String requestKey;
  @override
  void initState() {
    super.initState();
    userId = widget.auth.account!.id;
    final random = Random.secure();
    final bytes = List.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 15) | 64;
    bytes[8] = (bytes[8] & 63) | 128;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    requestKey =
        '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
    widget.auth.addListener(authChanged);
    unawaited(run(widget.repository.context));
  }

  void authChanged() {
    if (mounted && widget.auth.account?.id != userId) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    widget.auth.removeListener(authChanged);
    super.dispose();
  }

  Future<void> run(Future<Map<String, dynamic>> Function() action) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final value = await action().timeout(const Duration(seconds: 30));
      if (mounted && widget.auth.account?.id == userId) {
        setState(() => data = value);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => error =
              'No se pudo completar la operación. Comprueba la conexión. Si el servicio aún no está desplegado, vuelve a intentarlo cuando esté habilitado.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = data?['case'] as Map?;
    final expired =
        current?['deleted_at'] != null || current?['status'] == 'EXPIRED';
    final status = current?['status'];
    final labels = {
      'PENDING': 'Pendiente de muestras',
      'DOCUMENT_CAPTURED': 'Ambas muestras recibidas',
      'PROCESSING': 'Procesando',
      'UNDER_REVIEW': 'En revisión de prueba',
      'REJECTED': 'Prueba rechazada',
      'EXPIRED': 'Muestras vencidas',
    };
    return Scaffold(
      appBar: AppBar(title: const Text('Prueba de identidad')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Chip(label: Text('SOLO MUESTRAS SINTÉTICAS')),
                const SizedBox(height: 20),
                Text(
                  'Comprueba el flujo sin usar tu INE',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                const Text(
                  'La captura con cámara y la selección de archivos personales están deshabilitadas. Esta prueba nunca verifica tu identidad ni habilita reportes.',
                ),
                const SizedBox(height: 24),
                const Text(
                  'Consentimiento de prueba · synthetic-v1',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Finalidad: probar la carga privada y el seguimiento de una solicitud. Se usan dos imágenes sin datos personales, vinculadas a tu cuenta. Las imágenes vencen a las 24 horas; el proceso de purga elimina sus archivos. Se conserva el registro de la prueba y su consentimiento. Este texto no sustituye el aviso de privacidad para INE reales.',
                ),
                if (busy)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: LinearProgressIndicator(),
                  ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Semantics(liveRegion: true, child: Text(error!)),
                  ),
                if (data == null)
                  OutlinedButton(
                    onPressed: busy
                        ? null
                        : () => run(widget.repository.context),
                    child: const Text('Reintentar conexión'),
                  ),
                if (data != null && current == null) ...[
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: accepted,
                    onChanged: busy
                        ? null
                        : (v) => setState(() => accepted = v ?? false),
                    title: const Text(
                      'Acepto realizar la prueba con muestras sintéticas.',
                    ),
                  ),
                  FilledButton(
                    onPressed: busy || !accepted
                        ? null
                        : () => run(() => widget.repository.begin(requestKey)),
                    child: const Text('Iniciar prueba'),
                  ),
                ],
                if (current != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    labels[status] ?? 'Estado no disponible',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    'Eliminación prevista: ${current['delete_after'] ?? 'Sin fecha'}',
                  ),
                  if (current['review'] == 'simulation_approved')
                    const Text(
                      'Revisión de prueba aprobada. Tu identidad real sigue sin verificar.',
                    ),
                  if (expired)
                    const Text(
                      'La prueba venció. No hay acceso a sus imágenes.',
                    ),
                  if (!expired &&
                      ['PENDING', 'DOCUMENT_CAPTURED'].contains(status)) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Guía: encuadre completo, buena iluminación, sin reflejos y texto legible. En este piloto se utilizan las muestras preparadas.',
                    ),
                    for (final side in ['front', 'back'])
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Column(
                          children: [
                            Image.asset(
                              'assets/identity/$side.png',
                              height: 170,
                              semanticLabel:
                                  'Muestra sintética sin validez, ${side == 'front' ? 'frente' : 'reverso'}',
                            ),
                            OutlinedButton(
                              onPressed:
                                  busy || current['${side}_uploaded'] == true
                                  ? null
                                  : () => run(
                                      () => widget.repository.upload(
                                        current['id'] as String,
                                        side,
                                      ),
                                    ),
                              child: Text(
                                current['${side}_uploaded'] == true
                                    ? 'Muestra recibida'
                                    : 'Cargar muestra de ${side == 'front' ? 'frente' : 'reverso'}',
                              ),
                            ),
                          ],
                        ),
                      ),
                    FilledButton(
                      onPressed:
                          busy ||
                              current['front_uploaded'] != true ||
                              current['back_uploaded'] != true
                          ? null
                          : () => run(
                              () => widget.repository.submit(
                                current['id'] as String,
                              ),
                            ),
                      child: const Text('Enviar a revisión de prueba'),
                    ),
                  ],
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: busy
                        ? null
                        : () => run(widget.repository.context),
                    child: const Text('Actualizar estado'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
