import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';

import '../../../core/app_export.dart';

class MessageInputWidget extends StatefulWidget {
  final Function(String) onSendMessage;
  final Function(List<Map<String, dynamic>>) onSendAttachments;
  final Function(String) onSendVoiceNote;

  const MessageInputWidget({
    super.key,
    required this.onSendMessage,
    required this.onSendAttachments,
    required this.onSendVoiceNote,
  });

  @override
  State<MessageInputWidget> createState() => _MessageInputWidgetState();
}

class _MessageInputWidgetState extends State<MessageInputWidget> {
  final TextEditingController _messageController = TextEditingController();
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  bool _showAttachmentOptions = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _messageController.dispose();
    _audioRecorder.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color:
                AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          if (_showAttachmentOptions) _buildAttachmentOptions(),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _toggleAttachmentOptions,
                    child: Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: _showAttachmentOptions
                            ? AppTheme.lightTheme.colorScheme.primary
                                .withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(2.w),
                      ),
                      child: CustomIconWidget(
                        iconName:
                            _showAttachmentOptions ? 'close' : 'attach_file',
                        color: _showAttachmentOptions
                            ? AppTheme.lightTheme.colorScheme.primary
                            : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        size: 24,
                      ),
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(6.w),
                        border: Border.all(
                          color: AppTheme.lightTheme.colorScheme.outline
                              .withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: _messageController,
                        focusNode: _focusNode,
                        maxLines: 4,
                        minLines: 1,
                        decoration: InputDecoration(
                          hintText: 'Type your message...',
                          hintStyle: AppTheme.lightTheme.textTheme.bodyMedium
                              ?.copyWith(
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.7),
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 4.w, vertical: 2.h),
                        ),
                        style: AppTheme.lightTheme.textTheme.bodyMedium,
                        onChanged: (value) => setState(() {}),
                      ),
                    ),
                  ),
                  SizedBox(width: 2.w),
                  if (_messageController.text.trim().isNotEmpty)
                    GestureDetector(
                      onTap: _sendMessage,
                      child: Container(
                        padding: EdgeInsets.all(2.5.w),
                        decoration: BoxDecoration(
                          color: AppTheme.lightTheme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(6.w),
                        ),
                        child: CustomIconWidget(
                          iconName: 'send',
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: _isRecording ? _stopRecording : _startRecording,
                      child: Container(
                        padding: EdgeInsets.all(2.5.w),
                        decoration: BoxDecoration(
                          color: _isRecording
                              ? AppTheme.lightTheme.colorScheme.error
                              : AppTheme.lightTheme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(6.w),
                        ),
                        child: CustomIconWidget(
                          iconName: _isRecording ? 'stop' : 'mic',
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentOptions() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color:
                AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildAttachmentOption(
            'Camera',
            'camera_alt',
            AppTheme.lightTheme.colorScheme.primary,
            _pickImageFromCamera,
          ),
          _buildAttachmentOption(
            'Gallery',
            'photo_library',
            AppTheme.lightTheme.colorScheme.secondary,
            _pickImageFromGallery,
          ),
          _buildAttachmentOption(
            'Document',
            'description',
            AppTheme.lightTheme.colorScheme.tertiary,
            _pickDocument,
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentOption(
      String label, String iconName, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(3.w),
              border: Border.all(
                color: color.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: CustomIconWidget(
              iconName: iconName,
              color: color,
              size: 24,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            label,
            style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _toggleAttachmentOptions() {
    setState(() {
      _showAttachmentOptions = !_showAttachmentOptions;
    });
    if (!_showAttachmentOptions) {
      _focusNode.requestFocus();
    }
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      widget.onSendMessage(message);
      _messageController.clear();
      setState(() {});
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.camera);

      if (image != null) {
        final attachments = [
          {
            'type': 'image',
            'name': image.name,
            'path': image.path,
            'size': await image.length(),
          }
        ];
        widget.onSendAttachments(attachments);
        _toggleAttachmentOptions();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to capture image');
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final picker = ImagePicker();
      final images = await picker.pickMultiImage();

      if (images.isNotEmpty) {
        final attachments = <Map<String, dynamic>>[];
        for (final image in images) {
          attachments.add({
            'type': 'image',
            'name': image.name,
            'path': image.path,
            'size': await image.length(),
          });
        }
        widget.onSendAttachments(attachments);
        _toggleAttachmentOptions();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to select images');
    }
  }

  Future<void> _pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
        allowMultiple: true,
      );

      if (result != null) {
        final attachments = result.files
            .map((file) => {
                  'type': file.extension ?? 'document',
                  'name': file.name,
                  'path': file.path,
                  'size': file.size,
                  'bytes': kIsWeb ? file.bytes : null,
                })
            .toList();

        widget.onSendAttachments(attachments);
        _toggleAttachmentOptions();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to select documents');
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        await _audioRecorder.start(const RecordConfig(),
            path: 'voice_note.m4a');
        setState(() {
          _isRecording = true;
        });
      } else {
        _showErrorSnackBar('Microphone permission required');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to start recording');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
      });

      if (path != null) {
        widget.onSendVoiceNote(path);
      }
    } catch (e) {
      setState(() {
        _isRecording = false;
      });
      _showErrorSnackBar('Failed to stop recording');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.lightTheme.colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
