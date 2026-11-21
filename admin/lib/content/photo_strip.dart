import 'package:material_ui/material_ui.dart';

/// Bir yerin / işletmenin fotoğrafları: küçük önizlemeler (ilki KAPAK), kapak yap, sil, ekle.
class PhotoStrip extends StatelessWidget {
  const PhotoStrip({
    super.key,
    required this.photos,
    required this.uploading,
    required this.onAdd,
    required this.onRemove,
    required this.onMakeCover,
  });

  final List<Map<String, dynamic>> photos;
  final bool uploading;
  final VoidCallback? onAdd;
  final ValueChanged<int> onRemove;
  final ValueChanged<int> onMakeCover;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (var i = 0; i < photos.length; i++)
            SizedBox(
              width: 128,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AspectRatio(
                      aspectRatio: 4 / 3,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ColoredBox(
                            color: scheme.surfaceContainerHighest,
                            child: Image.network(
                              photos[i]['url'] as String,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined),
                            ),
                          ),
                          if (i == 0)
                            Positioned(
                              left: 4,
                              top: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: scheme.primary,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Kapak',
                                  style: TextStyle(color: scheme.onPrimary, fontSize: 11),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          (photos[i]['credit'] as String?) ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      if (i > 0)
                        IconButton(
                          tooltip: 'Kapak yap',
                          visualDensity: VisualDensity.compact,
                          iconSize: 18,
                          onPressed: () => onMakeCover(i),
                          icon: const Icon(Icons.star_outline),
                        ),
                      IconButton(
                        tooltip: 'Sil',
                        visualDensity: VisualDensity.compact,
                        iconSize: 18,
                        onPressed: () => onRemove(i),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          if (uploading)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            OutlinedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text(photos.isEmpty ? 'Fotoğraf ekle (en fazla 2 MB)' : 'Fotoğraf ekle'),
            ),
        ],
      ),
    );
  }
}
