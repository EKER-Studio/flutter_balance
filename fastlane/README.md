# Fastlane Metadata for Google Play Store

This directory contains automated store metadata and promotional graphics managed according to the [Fastlane Supply](https://docs.fastlane.tools/actions/supply/) standard.

## Directory Structure

```text
fastlane/
└── metadata/
    └── android/
        └── <locale>/                 # BCP-47 locale (e.g., pl-PL, en-US, de-DE...)
            ├── title.txt              # App title (max 30 characters)
            ├── short_description.txt  # Short description (max 80 characters, policy-compliant)
            ├── full_description.txt   # Full description (max 4000 characters)
            ├── changelogs/
            │   └── <versionCode>.txt  # Release notes for specific build number (e.g. 8.txt, max 500 characters)
            └── images/
                ├── featureGraphic.png # Store banner / feature graphic (1024x500 px)
                └── phoneScreenshots/  # 8 curated phone screenshots (01_dashboard.png .. 08_settings.png)
```

## Video URL Convention (`video.txt`)

* **No promo video?** Do **NOT** create a `video.txt` file (and do not leave an empty file or comments). Fastlane reads `video.txt` directly as a YouTube URL string. Creating an empty file or adding `# comments` causes the Google Play API to reject the upload with an `Invalid promotional video URL` error.
* **When you add a video:** Create `video.txt` inside the desired `<locale>/` directory containing only the raw YouTube URL (e.g. `https://www.youtube.com/watch?v=...`).

## Usage with Fastlane Supply

To validate or update store listings directly via CI/CD or CLI:

```bash
# Upload metadata and screenshots to Google Play
fastlane supply

# Upload metadata only (skipping screenshots)
fastlane supply --skip_upload_images --skip_upload_screenshots

# Upload changelogs only
fastlane supply --skip_upload_metadata --skip_upload_images --skip_upload_screenshots
```

## Supported Locales in this Repository

### Primary Locales (Metadata + Feature Graphic + Phone Screenshots)
* `en-US` — English (United States) [Default]
* `pl-PL` — Polish (Poland)
* `de-DE` — German (Germany)
* `es-ES` — Spanish (Spain)
* `fr-FR` — French (France)
* `it-IT` — Italian (Italy)
* `ja-JP` — Japanese (Japan)
* `ko-KR` — Korean (South Korea)
* `nl-NL` — Dutch (Netherlands)
* `pt-BR` — Portuguese (Brazil)

### Regional Variants (Metadata + Changelogs)
* `es-419` — Spanish (Latin America)
* `es-US` — Spanish (United States)
* `fr-CA` — French (Canada)
* `pt-PT` — Portuguese (Portugal)
* `en-AU`, `en-CA`, `en-GB`, `en-IN`, `en-SG`, `en-ZA` — Regional English variants
