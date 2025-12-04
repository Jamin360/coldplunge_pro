import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class CreatePostWidget extends StatefulWidget {
  final VoidCallback? onPostCreated;

  const CreatePostWidget({
    super.key,
    this.onPostCreated,
  });

  @override
  State<CreatePostWidget> createState() => _CreatePostWidgetState();
}

class _CreatePostWidgetState extends State<CreatePostWidget>
    with TickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isRecording = false;
  XFile? _capturedImage;
  XFile? _capturedVideo;
  final ImagePicker _imagePicker = ImagePicker();

  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _temperatureController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  late AnimationController _slideAnimationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _initializeCamera();
    _slideAnimationController.forward();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _slideAnimationController.dispose();
    _captionController.dispose();
    _durationController.dispose();
    _temperatureController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      if (!kIsWeb) {
        final permission = await Permission.camera.request();
        if (!permission.isGranted) return;
      }

      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;

      final camera = kIsWeb
          ? _cameras.firstWhere(
              (c) => c.lensDirection == CameraLensDirection.front,
              orElse: () => _cameras.first,
            )
          : _cameras.firstWhere(
              (c) => c.lensDirection == CameraLensDirection.back,
              orElse: () => _cameras.first,
            );

      _cameraController = CameraController(
        camera,
        kIsWeb ? ResolutionPreset.medium : ResolutionPreset.high,
      );

      await _cameraController!.initialize();

      if (!kIsWeb) {
        try {
          await _cameraController!.setFocusMode(FocusMode.auto);
          await _cameraController!.setFlashMode(FlashMode.auto);
        } catch (e) {
          // Ignore unsupported features
        }
      }

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    }
  }

  Future<void> _capturePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      HapticFeedback.mediumImpact();
      final XFile photo = await _cameraController!.takePicture();
      setState(() {
        _capturedImage = photo;
        _capturedVideo = null;
      });
    } catch (e) {
      debugPrint('Photo capture error: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _capturedImage = image;
          _capturedVideo = null;
        });
      }
    } catch (e) {
      debugPrint('Gallery pick error: $e');
    }
  }

  Future<void> _startVideoRecording() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      HapticFeedback.mediumImpact();
      await _cameraController!.startVideoRecording();
      setState(() {
        _isRecording = true;
      });
    } catch (e) {
      debugPrint('Video recording start error: $e');
    }
  }

  Future<void> _stopVideoRecording() async {
    if (_cameraController == null || !_isRecording) return;

    try {
      HapticFeedback.mediumImpact();
      final XFile video = await _cameraController!.stopVideoRecording();
      setState(() {
        _isRecording = false;
        _capturedVideo = video;
        _capturedImage = null;
      });
    } catch (e) {
      debugPrint('Video recording stop error: $e');
    }
  }

  void _submitPost() {
    if (_captionController.text.trim().isEmpty &&
        _capturedImage == null &&
        _capturedVideo == null) {
      return;
    }

    HapticFeedback.lightImpact();

    // Here you would typically upload the media and create the post
    // For now, we'll just simulate success

    widget.onPostCreated?.call();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        height: 90.h,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(theme, colorScheme),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCameraSection(theme, colorScheme),
                      SizedBox(height: 4.h),
                      _buildSessionDetailsSection(theme, colorScheme),
                      SizedBox(height: 4.h),
                      _buildCaptionSection(theme, colorScheme),
                    ],
                  ),
                ),
              ),
              _buildSubmitButton(theme, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
            },
            child: Container(
              padding: EdgeInsets.all(2.w),
              child: CustomIconWidget(
                iconName: 'close',
                color: colorScheme.onSurface,
                size: 24,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Share Your Plunge',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(width: 10.w), // Balance the close button
        ],
      ),
    );
  }

  Widget _buildCameraSection(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      height: 50.h,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: _capturedImage != null || _capturedVideo != null
          ? _buildCapturedMedia(colorScheme)
          : _buildCameraPreview(theme, colorScheme),
    );
  }

  Widget _buildCameraPreview(ThemeData theme, ColorScheme colorScheme) {
    if (!_isCameraInitialized || _cameraController == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: colorScheme.primary),
            SizedBox(height: 2.h),
            Text(
              'Initializing Camera...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: CameraPreview(_cameraController!),
          ),
          Positioned(
            bottom: 4.h,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCameraButton(
                  icon: 'photo_library',
                  onTap: _pickFromGallery,
                  colorScheme: colorScheme,
                ),
                _buildCameraButton(
                  icon: 'camera_alt',
                  onTap: _capturePhoto,
                  colorScheme: colorScheme,
                  isLarge: true,
                ),
                _buildCameraButton(
                  icon: _isRecording ? 'stop' : 'videocam',
                  onTap:
                      _isRecording ? _stopVideoRecording : _startVideoRecording,
                  colorScheme: colorScheme,
                  isRecording: _isRecording,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapturedMedia(ColorScheme colorScheme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          if (_capturedImage != null)
            SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: kIsWeb
                  ? Image.network(
                      _capturedImage!.path,
                      fit: BoxFit.cover,
                    )
                  : Image.network(
                      _capturedImage!.path,
                      fit: BoxFit.cover,
                    ),
            ),
          if (_capturedVideo != null)
            Container(
              width: double.infinity,
              height: double.infinity,
              color: colorScheme.surfaceContainerHighest,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomIconWidget(
                      iconName: 'play_circle_filled',
                      color: colorScheme.primary,
                      size: 15.w,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Video Captured',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            top: 2.h,
            right: 2.h,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _capturedImage = null;
                  _capturedVideo = null;
                });
              },
              child: Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: CustomIconWidget(
                  iconName: 'close',
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraButton({
    required String icon,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    bool isLarge = false,
    bool isRecording = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isLarge ? 20.w : 15.w,
        height: isLarge ? 20.w : 15.w,
        decoration: BoxDecoration(
          color: isRecording
              ? colorScheme.error
              : Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: CustomIconWidget(
            iconName: icon,
            color: isRecording ? Colors.white : colorScheme.onSurface,
            size: isLarge ? 8.w : 6.w,
          ),
        ),
      ),
    );
  }

  Widget _buildSessionDetailsSection(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Session Details',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _durationController,
                decoration: InputDecoration(
                  labelText: 'Duration',
                  hintText: '5:30',
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(3.w),
                    child: CustomIconWidget(
                      iconName: 'timer',
                      color: colorScheme.primary,
                      size: 20,
                    ),
                  ),
                ),
                keyboardType: TextInputType.text,
              ),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: TextField(
                controller: _temperatureController,
                decoration: InputDecoration(
                  labelText: 'Temperature',
                  hintText: '38°F',
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(3.w),
                    child: CustomIconWidget(
                      iconName: 'thermostat',
                      color: colorScheme.secondary,
                      size: 20,
                    ),
                  ),
                ),
                keyboardType: TextInputType.text,
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        TextField(
          controller: _locationController,
          decoration: InputDecoration(
            labelText: 'Location (Optional)',
            hintText: 'Lake Tahoe, CA',
            prefixIcon: Padding(
              padding: EdgeInsets.all(3.w),
              child: CustomIconWidget(
                iconName: 'location_on',
                color: colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCaptionSection(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Caption',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        TextField(
          controller: _captionController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Share your cold plunge experience...',
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(ThemeData theme, ColorScheme colorScheme) {
    final canSubmit = _captionController.text.trim().isNotEmpty ||
        _capturedImage != null ||
        _capturedVideo != null;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: canSubmit ? _submitPost : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: canSubmit
                ? colorScheme.primary
                : colorScheme.surfaceContainerHighest,
            foregroundColor: canSubmit
                ? colorScheme.onPrimary
                : colorScheme.onSurfaceVariant,
            padding: EdgeInsets.symmetric(vertical: 4.h),
          ),
          child: Text(
            'Share Post',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
