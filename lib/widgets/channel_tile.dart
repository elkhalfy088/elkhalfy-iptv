import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/content_models.dart';
import '../theme.dart';

class ChannelTile extends StatelessWidget {
  final LiveChannel channel;
  final bool isFav;
  final VoidCallback onTap;
  final VoidCallback onFav;

  const ChannelTile({
    super.key,
    required this.channel,
    required this.isFav,
    required this.onTap,
    required this.onFav,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppTheme.dividerColor, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            // Number
            if (channel.num > 0)
              SizedBox(
                width: 36,
                child: Text(
                  '${channel.num}',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ),
            // Logo
            Container(
              width: 44,
              height: 44,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: AppTheme.bgColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.dividerColor),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: channel.logo.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: channel.logo,
                        fit: BoxFit.contain,
                        placeholder: (_, __) => const Icon(
                            Icons.live_tv_rounded,
                            color: AppTheme.textSecondary,
                            size: 20),
                        errorWidget: (_, __, ___) => const Icon(
                            Icons.live_tv_rounded,
                            color: AppTheme.textSecondary,
                            size: 20),
                      )
                    : const Icon(Icons.live_tv_rounded,
                        color: AppTheme.textSecondary, size: 20),
              ),
            ),
            // Name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    channel.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppTheme.accentColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text('مباشر',
                          style: TextStyle(
                              color: AppTheme.accentColor, fontSize: 10)),
                    ],
                  )
                ],
              ),
            ),
            // Fav
            InkWell(
              onTap: onFav,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: isFav ? AppTheme.liveColor : AppTheme.textSecondary,
                  size: 18,
                ),
              ),
            ),
            // Play button
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  color: AppTheme.primaryColor, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
