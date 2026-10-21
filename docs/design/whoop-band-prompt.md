# Realistic onboarding band

Generated with the built-in image generation tool. Asset: `assets/images/whoop_band_realistic.png`.

Prompt: Photorealistic premium product cutout for a medical app onboarding. A black WHOOP-style screenless fitness band with a tightly woven charcoal textile strap forming a closed oval loop, compact low-profile matte graphite clasp/housing across the top and subtle brushed metal edges. Three-quarter elevated front/top view showing the exterior woven strap and clasp, not the underside sensors. Fine realistic fabric fibers, premium studio lighting, entire band visible, upright diagonal oval filling 85% of the square. Transparent background. No display, logos, text, hands, floor, cast shadow, UI, or extra objects. Intended to appear beside a separate live heart-rate readout.

## Branded variant

Asset: `assets/images/sanad_band_branded.png`. Edited with the built-in image tool using the original band and SANAD logo references. Prompt: Change only the front matte graphite clasp by applying the original Arabic SANAD logotype and small English SANAD as a light silver laser engraving, centered at 48% of plate width, with perspective matched to its surface. Preserve geometry, texture, lighting, framing, and transparent background. No new objects or UI.

## Lengthwise logo

Asset: `assets/images/sanad_band_vertical.png`. Built-in image edit prompt: Rotate only the complete existing engraved SANAD logo 90 degrees clockwise in the plane of the clasp, lengthwise along its long axis. Preserve the original Arabic shapes and small English SANAD as one rotated unit. Center at 45% of plate length, matching its perspective. Preserve all band geometry, fabric, lighting and transparency.

## Current implementation: preserve the original logo

The onboarding now uses the unbranded `assets/images/whoop_band_realistic.png`. The original `assets/images/sanad_logo.png` is rendered separately by Flutter with transparent padding cropped, a silver color filter, and a lengthwise transform on the clasp. The generated branded variants are retained as earlier assets but are no longer referenced by the onboarding. This preserves the actual original logo contours instead of regenerating them. The logo is centered within the clasp plane with a lengthwise affine transform and balanced margins. The callout begins beneath the sensor housing inside the loop, then follows a short elbow to the top edge of the readout.
