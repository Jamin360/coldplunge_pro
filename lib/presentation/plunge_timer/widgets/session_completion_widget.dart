import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../services/storage_service.dart';

class SessionCompletionWidget extends StatefulWidget {
  final int duration;
  final double? temperature;
  final Function(int mood, String notes) onSaveSession;
  final VoidCallback onDiscardSession;

  const SessionCompletionWidget({
    super.key,
    required this.duration,
    this.temperature,
    required this.onSaveSession,
    required this.onDiscardSession,
  });

  @override
  State<SessionCompletionWidget> createState() =>
      _SessionCompletionWidgetState();
}

class _SessionCompletionWidgetState extends State<SessionCompletionWidget> {
  final StorageService _storageService = StorageService();
  final TextEditingController _notesController = TextEditingController();
  XFile? _selectedImage;
  File? _imageFile;
  bool _isSaving = false;
  int _selectedMood = 2; // Default to Neutral

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    if (seconds >= 60) {
      final minutes = seconds ~/ 60;
      final remainingSeconds = seconds % 60;
      return '${minutes}m ${remainingSeconds}s';
    }
    return '${seconds}s';
  }

  Future<void> _pickImage() async {
    final XFile? image =
        await _storageService.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = image;
        _imageFile = File(image.path);
      });
    }
  }

  Future<void> _takePhoto() async {
    final XFile? image =
        await _storageService.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _selectedImage = image;
        _imageFile = File(image.path);
      });
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _imageFile = null;
    });
  }

  String _getMoodLabel(int mood) {
    switch (mood) {
      case 1:
        return 'Anxious';
      case 2:
        return 'Neutral';
      case 3:
        return 'Energized';
      default:
        return 'Neutral';
    }
  }

  IconData _getMoodIcon(int mood) {
    switch (mood) {
      case 1:
        return Icons.sentiment_dissatisfied;
      case 2:
        return Icons.sentiment_neutral;
      case 3:
        return Icons.sentiment_very_satisfied;
      default:
        return Icons.sentiment_neutral;
    }
  }

  void _handleSaveSession() {
    widget.onSaveSession(_selectedMood, _notesController.text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E88E5), Color(0xFF0D47A1)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              size: 20.w,
              color: Colors.white,
            ),
            SizedBox(height: 2.h),
            Text(
              'Session Complete!',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 2.h),

            // Session stats
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(51),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        'Duration',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.white70,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        _formatDuration(widget.duration),
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  if (widget.temperature != null)
                    Column(
                      children: [
                        Text(
                          'Temperature',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.white70,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          '${widget.temperature!.toStringAsFixed(1)}°F',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            SizedBox(height: 3.h),

            // Post-session mood selector
            Text(
              'How do you feel after the plunge?',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [1, 2, 3].map((mood) {
                final isSelected = _selectedMood == mood;
                return GestureDetector(
                  onTap: () => setState(() => _selectedMood = mood),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 1.h,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withAlpha(51),
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(
                        color: Colors.white,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _getMoodIcon(mood),
                          size: 10.w,
                          color: isSelected
                              ? const Color(0xFF1E88E5)
                              : Colors.white70,
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          _getMoodLabel(mood),
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: isSelected
                                ? const Color(0xFF1E88E5)
                                : Colors.white70,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 3.h),

            // Session notes
            Text(
              'Add notes (optional)',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            TextField(
              controller: _notesController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'How was the experience?',
                hintStyle: TextStyle(
                  color: Colors.white60,
                  fontSize: 12.sp,
                ),
                filled: true,
                fillColor: Colors.white.withAlpha(51),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: const BorderSide(color: Colors.white),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: const BorderSide(color: Colors.white),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: const BorderSide(color: Colors.white, width: 2),
                ),
              ),
            ),
            SizedBox(height: 3.h),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : widget.onDiscardSession,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 1.5.h),
                      side: const BorderSide(color: Colors.white),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    child: Text(
                      'Discard',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _handleSaveSession,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 1.5.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            'Save Session',
                            style: TextStyle(
                              color: const Color(0xFF1E88E5),
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
