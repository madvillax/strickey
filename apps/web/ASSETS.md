# Website assets

public/images/pixel-mac.png is an original supporting illustration generated with the built-in image generation tool. It was inspected and saved into this workspace. The interactive hero keyboard is drawn in code rather than generated as a static image.

Final image prompt:

> Use case: illustration-story. Asset type: supporting feature illustration for strickey, a minimal Mac keyboard sound app website. A lovingly crafted 8-bit pixel art silver laptop at a gentle three-quarter isometric angle, open with a bright Finder-blue desktop screen showing a simple white smiling pixel face. Compact soft white keyboard with two pale-blue keys. A few small black pixel sound-note marks around it. Authentic crisp square pixel clusters, limited colors, no smoothing, no 3D clay render, no gradients in pixel art. Palette silver, white, black, Finder sky blue and a tiny pastel pink accent. Laptop centered, complete silhouette visible, plenty of transparent margin around object. No logos, no written words, no labels, no watermark. Genuinely transparent background. Designed to sit on a pale pink panel of a clean Geist-font landing page.

The final page uses the image on a blue/neutral panel; pink was removed from the website palette at the user's request.

public/generated/strickey-logo.png is copied from the existing assets/strickey-logo.png. public/generated/sounds is copied from Sources/StrickeyCore/Resources/CherryMX, including the original Mechvibes license and credits. These outputs are generated before development/build and are not tracked twice.

## Geist Pixel Square

The site uses the official Geist Pixel Square export from geist/font/pixel in the geist 1.7.2 npm package, following [Vercel's font installation guide](https://vercel.com/font?type=pixel). The package integrates next/font/local and serves its bundled WOFF2, so builds and page rendering do not fetch fonts from a third-party font service. Square is the solid pixel variant and ships at weight 500.

The package's SIL Open Font License is copied to src/app/fonts/OFL.txt. Preserve this notice when updating the font dependency.

## Manrope in the hero

The hero's ordinary text uses the locally served Manrope Latin variable font from Google Fonts, supporting weights 200-800. Its original font file is committed at src/app/fonts/manrope-latin.woff2, with the matching license in OFL-Manrope.txt. The blue “clack.” word continues to use Geist Pixel Square.

Source: https://fonts.gstatic.com/s/manrope/v20/xn7gYHE41ni1AdIRggexSvfedN4.woff2.

## Social preview

public/social/strickey.png is a 1200×630 browser-rendered image of the actual dark hero. The compact capture retains the strickey logo, original headline and secondary copy, and the real pixel keyboard; navigation links, download controls, and demo controls are hidden in this social-card composition. Reduced motion keeps the keyboard static for capture.

This image is used by Open Graph and Twitter with the title strickey. Regenerate it from the rendered hero if the headline, fonts, keyboard, or branding change.
