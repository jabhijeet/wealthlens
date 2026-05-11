# Store Screenshots Guide for WealthLens

## Required Screenshots

### Google Play Store
- **Minimum**: 2 screenshots
- **Maximum**: 8 screenshots
- **Required dimensions**: 
  - Recommended: 1080 x 1920 px (16:9 aspect ratio)
  - Also accepted: 1080 x 2160 px (18:9)
- **Formats**: JPEG or PNG (24-bit PNG with no alpha)

### Apple App Store
- **iPhone**: 3-10 screenshots
  - 6.5" Display: 1242 x 2688 px (iPhone 11 Pro Max, XS Max)
  - 5.5" Display: 1242 x 2208 px (iPhone 8 Plus)
- **iPad**: Optional but recommended
  - 12.9" Display: 2048 x 2732 px
- **Formats**: JPEG or PNG

## Recommended Screenshots to Capture

1. **Dashboard Screen** (`lib/features/dashboard/dashboard_screen.dart`)
   - Show portfolio summary with total value
   - Display asset allocation chart
   - Highlight key metrics (returns, gains/losses)

2. **Holdings Screen** (`lib/features/holdings/holdings_screen.dart`)
   - List of all holdings
   - Show different investment types (stocks, mutual funds, crypto)
   - Display current values and returns

3. **Add Holding Screen** (`lib/features/holdings/add_holding_screen.dart`)
   - Form to add new investment
   - Show instrument picker
   - Display transaction details

4. **Insights Screen** (`lib/features/insights/insights_screen.dart`)
   - AI chat interface
   - Show sample financial insights
   - Highlight AI-powered recommendations

5. **Analytics/Charts** (from Dashboard)
   - Portfolio performance chart
   - Asset allocation pie chart
   - XIRR returns visualization

6. **Settings Screen** (`lib/features/settings/settings_screen.dart`)
   - Show security options (biometric, encryption)
   - Display theme toggle (dark/light mode)
   - Show backup/export options

7. **Import Screen** (`lib/features/import/import_screen.dart`)
   - Document scanning feature
   - PDF/Excel import options
   - Show OCR in action

8. **Calculators** (`lib/features/systematic/systematic_plans_screen.dart`)
   - SIP calculator
   - Loan amortization schedule
   - PPF/FD calculators

## Screenshot Guidelines

### Do's:
- Use the app in **light mode** for screenshots (more appealing)
- Ensure all text is readable and not cut off
- Show realistic data (not "Lorem Ipsum")
- Highlight key features in each screenshot
- Use consistent branding (blue theme: #0066CC)

### Don'ts:
- Don't show personal/real financial data
- Don't include notifications or status bar with personal info
- Don't use blurry or low-quality images
- Don't show incomplete loading states

## How to Capture Screenshots

### Android (using emulator or device):
```bash
# Using Android emulator
# Press Camera button in emulator toolbar

# Using physical device
# Press Power + Volume Down simultaneously
```

### iOS (requires macOS):
```bash
# Using iOS Simulator
# Device → Screenshot (or Cmd+S)

# Using physical device
# Press Side Button + Volume Up (iPhone X and later)
```

## Screenshot Annotation (Optional)
Consider adding small captions to explain features:
- Use tools like Canva, Figma, or Photoshop
- Keep text minimal and readable
- Maintain consistent style across all screenshots

## Upload Instructions

### Google Play Console:
1. Go to "Store presence" → "Main store listing"
2. Scroll to "Screenshots" section
3. Upload for each device type (Phone, 7-inch tablet, 10-inch tablet)

### App Store Connect:
1. Go to "App Store" tab
2. Select "App Information" or "iOS App"
3. Upload screenshots for each display size

## Placeholder Note
Since actual screenshots require running the app, use the Flutter development tools to launch the app and capture these screenshots manually before submitting to stores.
