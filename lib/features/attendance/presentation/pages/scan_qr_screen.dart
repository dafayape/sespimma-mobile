import 'package:sespimma/core/constants/app_dimensions.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:sespimma/core/utils/icon_mapper.dart';

import '../../../../core/theme/app_colors.dart';

class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen>
    with SingleTickerProviderStateMixin {
  late final MobileScannerController _controller;
  late final AnimationController _animController;
  late final Animation<double> _laserAnimation;

  bool _isScanning = true;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.1, end: 0.9).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (!_isScanning) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      setState(() => _isScanning = false);
      HapticFeedback.heavyImpact();

      final String? code = barcodes.first.rawValue;

      if (mounted) {
        _showResultDialog(code ?? 'Unknown QR Code');
      }
    }
  }

  void _showResultDialog(String code) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
          ),
          title: Row(
            children: [
              const Icon(
                AppIcons.checkCircleFill,
                color: AppColors.successGreen,
              ),
              const SizedBox(width: AppDimensions.md - 4),
              const Text(
                'QR Code Terdeteksi',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Data QR:',
                style: TextStyle(
                  fontSize: AppDimensions.fontMd,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: AppDimensions.xs),
              Text(
                code,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: AppDimensions.fontXl,
                ),
              ),
              const SizedBox(height: AppDimensions.md),
              const Text(
                'Absensi Anda telah diverifikasi melalui QR Code.',
                style: TextStyle(
                  fontSize: AppDimensions.fontLg,
                  color: Colors.blueGrey,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text(
                'OK',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scanArea = MediaQuery.of(context).size.width * 0.7;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _buildTransparentAppBar(context),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),

          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.6),
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Center(
                  child: Container(
                    height: scanArea,
                    width: scanArea,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusXxl,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Center(
            child: SizedBox(
              width: scanArea,
              height: scanArea,
              child: Stack(
                children: [_buildCorners(scanArea), _buildLaser(scanArea)],
              ),
            ),
          ),

          _buildControls(context, scanArea),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildTransparentAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AppBar(
            backgroundColor: AppColors.primaryNavy.withValues(alpha: 0.6),
            elevation: 0,
            centerTitle: true,
            title: const Text(
              'Scan QR Code',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: AppDimensions.fontXxl,
                letterSpacing: 0.5,
              ),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildCorners(double size) {
    const double cornerSize = 40;
    const double thickness = 5;
    const Color cornerColor = Colors.white;

    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          child: _buildCornerPart(
            top: thickness,
            left: 0,
            width: cornerSize,
            height: thickness,
            color: cornerColor,
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          child: _buildCornerPart(
            top: 0,
            left: 0,
            width: thickness,
            height: cornerSize,
            color: cornerColor,
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: _buildCornerPart(
            top: thickness,
            right: 0,
            width: cornerSize,
            height: thickness,
            color: cornerColor,
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: _buildCornerPart(
            top: 0,
            right: 0,
            width: thickness,
            height: cornerSize,
            color: cornerColor,
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          child: _buildCornerPart(
            bottom: thickness,
            left: 0,
            width: cornerSize,
            height: thickness,
            color: cornerColor,
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          child: _buildCornerPart(
            bottom: 0,
            left: 0,
            width: thickness,
            height: cornerSize,
            color: cornerColor,
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: _buildCornerPart(
            bottom: thickness,
            right: 0,
            width: cornerSize,
            height: thickness,
            color: cornerColor,
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: _buildCornerPart(
            bottom: 0,
            right: 0,
            width: thickness,
            height: cornerSize,
            color: cornerColor,
          ),
        ),
      ],
    );
  }

  Widget _buildCornerPart({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double width,
    required double height,
    required Color color,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd + 2),
      ),
    );
  }

  Widget _buildLaser(double size) {
    return AnimatedBuilder(
      animation: _laserAnimation,
      builder: (context, child) {
        return Positioned(
          top: size * _laserAnimation.value,
          left: 20,
          right: 20,
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.8),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0),
                  Colors.white,
                  Colors.white.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildControls(BuildContext context, double scanArea) {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 60,
      left: 0,
      right: 0,
      child: Column(
        children: [
          const Text(
            'Posisikan QR Code di dalam kotak',
            style: TextStyle(
              color: Colors.white,
              fontSize: AppDimensions.fontLg,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppDimensions.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildControlCircle(
                icon: ValueListenableBuilder(
                  valueListenable: _controller,
                  builder: (context, state, child) {
                    final bool isTorchOn = state.torchState == TorchState.on;
                    return Icon(
                      isTorchOn
                          ? AppIcons.flashlightFill
                          : AppIcons.flashlightBold,
                      color: Colors.white,
                      size: AppDimensions.iconLg,
                    );
                  },
                ),
                onTap: () {
                  HapticFeedback.selectionClick();
                  _controller.toggleTorch();
                },
              ),
              const SizedBox(width: AppDimensions.lg),
              _buildControlCircle(
                icon: const Icon(
                  AppIcons.arrowsClockwiseBold,
                  color: Colors.white,
                  size: AppDimensions.iconLg,
                ),
                onTap: () {
                  HapticFeedback.selectionClick();
                  _controller.switchCamera();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlCircle({
    required Widget icon,
    required VoidCallback onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.white.withValues(alpha: 0.2),
          child: InkWell(
            onTap: onTap,
            child: Container(
              width: 60,
              height: 60,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: icon,
            ),
          ),
        ),
      ),
    );
  }
}
