import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:http_certificate_pinning/http_certificate_pinning.dart';

/// SHA-256 fingerprint of the production TLS certificate served by
/// `sespima.web.id`, formatted like `AA:BB:CC:...` (colon-separated hex,
/// as required by the `http_certificate_pinning` package).
///
/// *** PLACEHOLDER — THIS IS NOT A REAL FINGERPRINT ***
/// This value was written from a sandbox with no network access, so the
/// live certificate could not be fetched. Before this pin is trustworthy,
/// replace it with the real value obtained via, e.g.:
///
/// ```
/// openssl s_client -connect sespima.web.id:443 -servername sespima.web.id -verify_return_error < /dev/null 2> /dev/null \
///   | openssl x509 -noout -fingerprint -sha256
/// ```
///
/// (or the equivalent value your CDN/host provides). Consider pinning the
/// CA/intermediate certificate rather than the leaf if certs auto-renew
/// (e.g. Let's Encrypt), otherwise every renewal will require an app
/// release to update this constant before the old pin expires.
///
/// While this remains the placeholder sentinel below,
/// [CertificatePinningGuardInterceptor] SKIPS enforcement entirely (with a
/// one-time logged warning) rather than rejecting every request — a wrong
/// or unfilled pin has a much worse blast radius (bricks connectivity for
/// every production user) than temporarily running without pinning.
const String kProductionCertSha256Pin = 'REPLACE_ME_WITH_REAL_SHA256_FINGERPRINT';

/// Hosts this pin applies to. Requests to any other host (should not
/// happen in this app — everything goes through API_BASE_URL — but kept
/// as a safety net) pass through unpinned.
const List<String> kCertificatePinnedHosts = ['sespima.web.id'];

bool get _isPlaceholderPin =>
    kProductionCertSha256Pin == 'REPLACE_ME_WITH_REAL_SHA256_FINGERPRINT';

/// Wraps [CertificatePinningInterceptor] so an unfilled/placeholder pin
/// degrades to "no enforcement" instead of failing closed.
///
/// [CertificatePinningInterceptor] (from `http_certificate_pinning`)
/// rejects EVERY request whose live certificate fingerprint isn't in the
/// allowed list — including the placeholder sentinel, which will never
/// match anything. Using it unguarded would mean the moment this
/// interceptor is wired in, no request could ever succeed until a human
/// fills in the real fingerprint. This guard makes that failure mode
/// impossible: enforcement only turns on once [kProductionCertSha256Pin]
/// has actually been replaced.
class CertificatePinningGuardInterceptor extends Interceptor {
  bool _warnedOnce = false;

  late final CertificatePinningInterceptor _delegate = CertificatePinningInterceptor(
    allowedSHAFingerprints: [kProductionCertSha256Pin],
  );

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_isPlaceholderPin) {
      if (!_warnedOnce) {
        _warnedOnce = true;
        developer.log(
          'Certificate pinning DISABLED: kProductionCertSha256Pin in '
          'lib/core/network/certificate_pinning_interceptor.dart is still '
          'the placeholder value. Fill in the real production SHA-256 '
          'fingerprint to enable enforcement.',
          name: 'CertPinning',
        );
      }
      return handler.next(options);
    }

    final host = options.uri.host;
    final isPinnedHost = kCertificatePinnedHosts.any((h) => host == h || host.endsWith('.$h'));
    if (!isPinnedHost) {
      return handler.next(options);
    }

    return _delegate.onRequest(options, handler);
  }
}
