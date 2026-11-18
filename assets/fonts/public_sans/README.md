# Public Sans

Bundled for the HealthMate app and admin website. This is a free alternative
chosen for a similar typography style to X; it is not X's custom Chirp font.

Unmodified upstream files from the Public Sans project:
https://github.com/uswds/public-sans/tree/c7923167a592d941646f99fb7b5fba17aa7d69e1

- Flutter: `fonts/ttf/PublicSans-{Regular,Medium,SemiBold,Bold}.ttf`.
- Admin: `fonts/webfonts/PublicSans-{Regular,Medium,SemiBold,Bold}.woff2`,
  copied to `admin-web/dist/fonts/public_sans/`.
- Weights: 400, 500, 600, 700. All four TTF files contain the 134
  precomposed Vietnamese characters checked during import.
- Copyright 2015 The Public Sans Project Authors. SIL Open Font License 1.1;
  full license in `OFL.txt`, included in Flutter assets and the web directory.
- Exact URLs, byte sizes and SHA-256 hashes: `manifest.json`.

No remote font provider, runtime download or additional Flutter package.
The old Inter source files are retained for provenance but are no longer
registered as the product UI font.
