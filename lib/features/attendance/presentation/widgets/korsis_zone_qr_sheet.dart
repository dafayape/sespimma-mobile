import 'dart:ui' as ui;
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/core/theme/app_colors.dart';
import 'package:sespimma/core/utils/icon_mapper.dart';
import 'package:sespimma/features/attendance/data/datasources/absensi_remote_data_source.dart';
import 'package:sespimma/features/attendance/domain/models/map_tile_mode.dart';
import 'package:sespimma/core/utils/app_notifier.dart';
import 'package:sespimma/injection_container.dart';

class KorsisZoneQrSheet extends StatefulWidget {
  final List<AttendanceZone> zones;

  const KorsisZoneQrSheet({super.key, required this.zones});

  @override
  State<KorsisZoneQrSheet> createState() => _KorsisZoneQrSheetState();
}

class _KorsisZoneQrSheetState extends State<KorsisZoneQrSheet> {
  late PageController _pageController;
  int _currentIndex = 0;
  bool _isPrinting = false;

  late final List<GlobalKey> _qrKeys;

  // Server-issued HMAC tokens (zone.id -> token), fetched up front since QR
  // generation used to be a synchronous build()-time helper but now needs
  // an authoritative token from the backend. A zone whose fetch fails is
  // simply absent from this map — its QR payload omits `token` rather than
  // crashing the whole sheet.
  Map<String, String> _tokens = {};
  bool _loadingTokens = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _qrKeys = List.generate(widget.zones.length, (_) => GlobalKey());
    _loadTokens();
  }

  Future<void> _loadTokens() async {
    final absensiSource = sl<AbsensiRemoteDataSource>();
    final Map<String, String> tokens = {};
    for (final zone in widget.zones) {
      try {
        final data = await absensiSource.fetchQrToken(zone.id);
        final token = data['token'];
        if (token is String) {
          tokens[zone.id] = token;
        }
      } catch (_) {
        // Leave this zone's token missing; handled gracefully in
        // _buildQrPayload (the `token` key is simply omitted for it).
      }
    }
    if (!mounted) return;
    setState(() {
      _tokens = tokens;
      _loadingTokens = false;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<Uint8List> _captureQrBytes(int index) async {
    final boundary =
        _qrKeys[index].currentContext!.findRenderObject()
            as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 4.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<void> _printOrSave(AttendanceZone zone, int index) async {
    if (_isPrinting) return;
    setState(() => _isPrinting = true);
    HapticFeedback.mediumImpact();
    try {
      final qrBytes = await _captureQrBytes(index);
      final pdfDoc = pw.Document();
      final qrImg = pw.MemoryImage(qrBytes);

      pdfDoc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a5,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context ctx) => pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                zone.activityName,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                zone.name,
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 13),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                zone.timeString,
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 11),
              ),
              pw.SizedBox(height: 24),
              pw.Center(child: pw.Image(qrImg, width: 260, height: 260)),
              pw.SizedBox(height: 20),
              pw.Text(
                'Scan QR Code ini melalui aplikasi SESPIMMA',
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
        ),
      );

      await Printing.layoutPdf(
        onLayout: (_) async => pdfDoc.save(),
        name: 'QR-${zone.name}',
      );
    } catch (e) {
      if (mounted) {
        AppNotifier.showError(context, 'Gagal membuat PDF: $e');
      }
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXxl),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: AppDimensions.lg),

          Center(
            child: Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.md),

          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Zona Aktif',
                style: TextStyle(
                  fontSize: AppDimensions.fontSm,
                  color: Colors.blueGrey.shade400,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade400.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${widget.zones.length}',
                  style: TextStyle(
                    fontSize: AppDimensions.fontSm,
                    color: Colors.green.shade900,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: _loadingTokens
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryNavy,
                    ),
                  )
                : PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _currentIndex = index);
                      HapticFeedback.lightImpact();
                    },
                    itemCount: widget.zones.length,
                    itemBuilder: (context, index) =>
                        _buildQrPage(widget.zones[index], index),
                  ),
          ),

          if (widget.zones.length > 1)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppDimensions.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.zones.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentIndex == i ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentIndex == i
                          ? AppColors.primaryNavy
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: AppDimensions.xxl),
        ],
      ),
    );
  }

  Widget _buildQrPage(AttendanceZone zone, int index) {
    final qrData = _buildQrPayload(zone);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.xxl,
        8,
        AppDimensions.xxl,
        0,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            zone.activityName,
            style: const TextStyle(
              fontSize: AppDimensions.fontXxl,
              fontWeight: FontWeight.w900,
              color: AppColors.primaryNavy,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            zone.name,
            style: TextStyle(
              fontSize: AppDimensions.fontLg,
              fontWeight: FontWeight.w600,
              color: Colors.blueGrey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            zone.timeString,
            style: TextStyle(
              fontSize: AppDimensions.fontSm,
              color: Colors.blueGrey.shade400,
            ),
          ),
          const SizedBox(height: AppDimensions.xxl),

          RepaintBoundary(
            key: _qrKeys[index],
            child: Container(
              padding: const EdgeInsets.all(AppDimensions.xl),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 240.0,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: AppColors.primaryNavy,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: AppColors.primaryNavy,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.xl),
          Text(
            'Minta serdik scan QR Code ini dari aplikasi mereka. Apabila fitur geofencing bermasalah',
            style: TextStyle(
              fontSize: AppDimensions.fontDefault,
              color: Colors.blueGrey.shade400,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isPrinting ? null : () => _printOrSave(zone, index),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryNavy,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.primaryNavy.withValues(
                  alpha: 0.4,
                ),
                padding: const EdgeInsets.symmetric(vertical: AppDimensions.lg),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                ),
                elevation: 0,
              ),
              icon: _isPrinting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Icon(AppIcons.printer, size: 20),
              label: Text(
                _isPrinting ? '' : 'SIMPAN QR CODE',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _buildQrPayload(AttendanceZone zone) {
    final yyyy = zone.startTime.year.toString().padLeft(4, '0');
    final mm = zone.startTime.month.toString().padLeft(2, '0');
    final dd = zone.startTime.day.toString().padLeft(2, '0');

    return json.encode({
      'type': 'attendance_sespimma',
      'zoneId': zone.id,
      'date': '$yyyy-$mm-$dd',
      'token': _tokens[zone.id],
    });
  }
}
