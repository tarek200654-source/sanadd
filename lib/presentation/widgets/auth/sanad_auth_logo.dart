import 'package:flutter/material.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/localization/app_localizations.dart';

/// The auth-header version of SANAD's existing mark.
///
/// The source image is a transparent 1024px square with its artwork centered
/// inside it at X=[176, 844], Y=[402, 692] (width: 668, height: 290, ratio: 2.30).
/// Sizing the image proportionally to an artwork width of ~92 logical px provides
/// an elegant, medium-small mark that sits harmoniously in the auth header.
class SanadAuthLogo extends StatelessWidget {
  const SanadAuthLogo({
    super.key,
    this.artworkWidth = 92,
  });

  final double artworkWidth;

  static const double _artworkToAssetRatio = 668.0 / 1024.0;
  static const double _artworkAspectRatio = 668.0 / 290.0;

  @override
  Widget build(BuildContext context) {
    final assetSize = artworkWidth / _artworkToAssetRatio;
    final viewportHeight = artworkWidth / _artworkAspectRatio;

    return Semantics(
      image: true,
      label: context.l10n.sanadLogoLabel,
      child: ExcludeSemantics(
        child: SizedBox(
          width: artworkWidth,
          height: viewportHeight.clamp(36.0, 48.0),
          child: ClipRect(
            child: OverflowBox(
              alignment: const Alignment(0, 0.08),
              minWidth: assetSize,
              maxWidth: assetSize,
              minHeight: assetSize,
              maxHeight: assetSize,
              child: Image.asset(
                AppAssets.sanadLogo,
                width: assetSize,
                height: assetSize,
                fit: BoxFit.contain,
                color: Colors.black,
                colorBlendMode: BlendMode.srcIn,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
