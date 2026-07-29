import 'dart:developer' as developer;
import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:http_certificate_pinning/http_certificate_pinning.dart';

/// SHA-256 fingerprint(s) of the production TLS certificate(s) served by
/// `sespima.web.id`, as hex strings (colons optional — the plugin strips
/// them before comparing; see `http_certificate_pinning`'s
/// `HttpCertificatePinning.check()`).
///
/// IMPORTANT — this package (confirmed by reading its Android platform
/// source, `HttpCertificatePinningPlugin.kt`) hashes the **entire leaf
/// certificate's DER encoding** (`cert.encoded`) with SHA-256, NOT the
/// SPKI/public-key. Do NOT use a value produced by a "public key pin"
/// pipeline (e.g. `openssl x509 -pubkey | openssl pkey -pubin ... | openssl
/// enc -base64`) — that is a different hash over different input bytes,
/// base64 instead of hex, and will simply never match, silently locking
/// out every production user once enforcement is enabled.
///
/// Get the correct value with:
/// ```
/// echo | openssl s_client -connect sespima.web.id:443 -servername sespima.web.id 2>/dev/null \
///   | openssl x509 -noout -fingerprint -sha256
/// ```
/// This prints e.g. `sha256 Fingerprint=AA:BB:CC:...` — put just the hex
/// (colons are fine, they're stripped automatically) into the list below.
///
/// This is a LEAF certificate pin: Let's Encrypt renews the leaf roughly
/// every ~90 days, and each renewal changes this fingerprint even though
/// the domain/key policy hasn't changed — so treat updating this list as a
/// recurring operational task, not a one-time setup. Prefer listing both
/// the current AND (once available) the intermediate CA's fingerprint as a
/// second, more stable entry so a routine leaf renewal alone doesn't lock
/// the app out before this list is updated.
///
/// While this list contains ONLY the placeholder sentinel below,
/// [CertificatePinningGuardInterceptor] SKIPS enforcement entirely (with a
/// one-time logged warning) rather than rejecting every request — a wrong
/// or unfilled pin has a much worse blast radius (bricks connectivity for
/// every production user) than temporarily running without pinning.
const List<String> kProductionCertSha256Pins = [
  // Leaf cert for sespima.web.id, captured 2026-07-29. Let's Encrypt
  // renews this roughly every ~90 days (next renewal ~2026-10) — this
  // value WILL go stale then. Re-run the openssl command in the doc
  // comment above before it does, or every production user gets locked
  // out the moment the cert rotates. Consider also adding the
  // intermediate CA's fingerprint as a second, more stable backup entry.
  '7D:C1:ED:A7:84:A4:D0:88:A4:79:DD:66:F3:A6:03:2C:6F:1C:CD:F3:5B:5E:10:22:16:F4:27:22:CB:61:E4:CD',
];

/// Hosts this pin applies to. Requests to any other host (should not
/// happen in this app — everything goes through API_BASE_URL — but kept
/// as a safety net) pass through unpinned.
const List<String> kCertificatePinnedHosts = ['sespima.web.id'];

bool get _isPlaceholderPin =>
    kProductionCertSha256Pins.every((p) => p == 'REPLACE_ME_WITH_REAL_SHA256_FINGERPRINT');

/// Wraps [CertificatePinningInterceptor] so an unfilled/placeholder pin
/// degrades to "no enforcement" instead of failing closed.
///
/// [CertificatePinningInterceptor] (from `http_certificate_pinning`)
/// rejects EVERY request whose live certificate fingerprint isn't in the
/// allowed list — including the placeholder sentinel, which will never
/// match anything. Using it unguarded would mean the moment this
/// interceptor is wired in, no request could ever succeed until a human
/// fills in the real fingerprint. This guard makes that failure mode
/// impossible: enforcement only turns on once [kProductionCertSha256Pins]
/// has actually been replaced.
///
/// iOS-only. Android now pins at the OS/network-stack level instead, via
/// `android/app/src/main/res/xml/network_security_config.xml` — a
/// `<pin-set>` keyed on the certificate's SPKI (public key) hash rather
/// than this package's whole-leaf-certificate hash. SPKI pinning survives
/// every Let's Encrypt renewal as long as the VPS's certbot config reuses
/// the same private key (`reuse_key = True`); this Dio-level plugin does
/// NOT support SPKI pinning (confirmed by reading its native source — see
/// [kProductionCertSha256Pins] doc), so it would still need a fresh
/// fingerprint every ~90 days if left active. Keeping BOTH active on
/// Android would reintroduce exactly that fragility (whichever one goes
/// stale first blocks every request), so this class no-ops on Android and
/// leaves enforcement entirely to the network security config. iOS has no
/// equivalent declarative SPKI-pinning mechanism (Apple requires a native
/// `URLSessionDelegate`/`SecTrust` implementation for true SPKI pinning,
/// out of scope here — no Mac/Xcode available to build or verify one), so
/// it keeps relying on this package's leaf(+intermediate) whole-cert pin,
/// still subject to the routine leaf-renewal update cadence documented on
/// [kProductionCertSha256Pins].
class CertificatePinningGuardInterceptor extends Interceptor {
  bool _warnedOnce = false;

  late final CertificatePinningInterceptor _delegate = CertificatePinningInterceptor(
    allowedSHAFingerprints: kProductionCertSha256Pins,
  );

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!Platform.isIOS) {
      // Android: enforcement lives in network_security_config.xml instead
      // (see class doc). Nothing to do here.
      return handler.next(options);
    }

    if (_isPlaceholderPin) {
      if (!_warnedOnce) {
        _warnedOnce = true;
        developer.log(
          'Certificate pinning DISABLED: kProductionCertSha256Pins in '
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
