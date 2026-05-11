# App Icons for WealthLens

## Instructions for Production Icons

To generate proper app icons for all platforms, you need to:

1. **Create or obtain a high-resolution app icon** (at least 1024x1024 pixels)
   - Save it as `app_icon.png` in this directory
   - The icon should be simple, recognizable at small sizes, and follow platform guidelines

2. **For Android adaptive icons** (optional but recommended):
   - Create `app_icon_foreground.png` - the foreground layer (1024x1024)
   - The background color is set to `#0066CC` in `flutter_launcher_icons.yaml`

3. **Run the icon generator**:
   ```bash
   flutter pub get
   flutter pub run flutter_launcher_icons
   ```

## Icon Requirements by Platform

### Android
- Must follow Material Design guidelines
- Adaptive icons: 1024x1024 foreground + background
- Legacy icons: 512x512, 192x192, 144x144, 96x96, 72x72, 48x48, 36x36

### iOS
- Must follow Apple Human Interface Guidelines
- Required sizes: 20pt, 29pt, 40pt, 60pt, 76pt, 83.5pt (all in 1x, 2x, 3x)
- App Store: 1024x1024 pixels

### Web
- 192x192 and 512x512 for manifest
- Maskable icons for PWA support

### macOS
- 16x16, 32x32, 64x64, 128x128, 256x256, 512x512, 1024x1024

### Windows
- 16x16, 24x24, 32x32, 48x48, 64x64, 128x128, 256x256, 512x512

## Current Status
- [ ] App icon designed/obtained
- [ ] Icon placed in assets/icons/app_icon.png
- [ ] Icons generated for all platforms
- [ ] Tested on all target platforms
