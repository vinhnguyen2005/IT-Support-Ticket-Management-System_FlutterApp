import 'dart:io';

import 'package:flutter/material.dart';

class TicketAttachmentField extends StatelessWidget {
  const TicketAttachmentField({
    super.key,
    required this.filePath,
    required this.isEditing,
    required this.isBusy,
    required this.onPick,
    required this.onClear,
  });

  final String? filePath;
  final bool isEditing;
  final bool isBusy;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final selectedPath = filePath;
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Attachment', style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            if (isEditing)
              FilledButton.tonalIcon(
                onPressed: isBusy ? null : onPick,
                icon: const Icon(Icons.upload_file),
                label: Text(selectedPath == null ? 'Upload image' : 'Replace'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (selectedPath == null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              border: Border.all(color: colors.outlineVariant),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(Icons.image_outlined, size: 36, color: colors.primary),
                const SizedBox(height: 10),
                Text(
                  'No image selected',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Upload a screenshot or photo to help explain the issue.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          )
        else
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              onTap: () => _showPreview(context, selectedPath),
              leading: _ImageThumbnail(filePath: selectedPath),
              title: Text(
                _fileName(selectedPath),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: const Text('Tap to view image'),
              trailing: isEditing
                  ? IconButton(
                      tooltip: 'Cancel attachment',
                      onPressed: isBusy ? null : onClear,
                      icon: const Icon(Icons.close),
                    )
                  : const Icon(Icons.open_in_full),
            ),
          ),
      ],
    );
  }

  static Future<void> _showPreview(
    BuildContext context,
    String filePath,
  ) async {
    final file = File(filePath);
    if (!await file.exists()) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This image is no longer available.')),
      );
      return;
    }

    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4,
              child: Image.file(file, fit: BoxFit.contain),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton.filledTonal(
                tooltip: 'Close preview',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _fileName(String filePath) {
    return filePath.replaceAll('\\', '/').split('/').last;
  }
}

class _ImageThumbnail extends StatelessWidget {
  const _ImageThumbnail({required this.filePath});

  final String filePath;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.file(
        File(filePath),
        width: 52,
        height: 52,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const SizedBox(
          width: 52,
          height: 52,
          child: Icon(Icons.broken_image_outlined),
        ),
      ),
    );
  }
}
