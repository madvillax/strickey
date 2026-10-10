# strickey website

The landing page workspace for strickey. Built with Next.js App Router, React, TypeScript, Tailwind CSS v4, native CSS animation, and Geist Pixel Square. The Swift macOS app stays at the repository root.

The hero uses Manrope for its headline, secondary copy, and controls, with Geist Pixel Square reserved for the blue “clack.” word. Other sections retain Geist Pixel Square.

## Local development

Run these commands from the repository root with Node.js 22+:

~~~sh
npm install
npm run dev
~~~

Open http://localhost:3000. Development and build hooks copy the source logo and recordings into public/generated. Those generated copies are ignored by Git.

~~~sh
npm run lint
npm run typecheck
npm run build
npm run start
~~~

## Page behavior

- The eight-bit keyboard animates key presses and responds to typing in its demo input or clicks on its drawn keys. Automatic animation honors reduced motion and visibility.
- Sound starts only after pressing **Turn sound on**. The demo plays the same Red, Brown, and Blue recordings as the native app.
- The interactive app preview supports profile selection, volume, pause, sample playback, and opening/closing the menu bar panel.
- The website is permanently dark, with a pure-black background and bright blue footer. It has no theme toggle or stored appearance preference.
- Download buttons save the universal DMG directly from this site's public/downloads directory, with no GitHub redirect or API dependency.

## Download package

The current universal DMG, SHA-256 sidecar, and release.json metadata are committed in public/downloads so local development and deployed sites serve the same file. The build fails if the package is missing or its size/checksum does not match.

To update through GitHub Actions, run **Build release artifacts** with the desired version. Download the **strickey-website-download** artifact from the finished run, extract its files into apps/web/public/downloads, and commit the updated package and metadata. The site's buttons use the filename from release.json automatically.

For a local package build, the root package:web npm script builds and verifies a universal DMG in an isolated temporary tree, then prepares the website files. It never rebuilds or stops the app at the project's dist/Strickey.app path.

The current DMG is ad-hoc signed and not notarized. Apple may require a user to approve opening it; the FAQ links to [Apple's installation guidance](https://support.apple.com/en-us/102445). Developer ID signing and notarization are covered in the repository's release guide.

## Deployment

Deploy this as a Next.js project with **Root Directory: apps/web**. On Vercel, enable **Include source files outside of the Root Directory** so the asset hook can read the Swift recordings and root logo. Use the repository's npm workspace lockfile for installation.

See [Vercel's monorepo guide](https://vercel.com/docs/monorepos) and [shared source file settings](https://vercel.com/docs/monorepos/monorepo-faq).

Set NEXT_PUBLIC_SITE_URL to the final public site URL for social metadata. On Vercel, the fallback uses VERCEL_PROJECT_PRODUCTION_URL before the deployment-specific VERCEL_URL, keeping social image links on the public production domain. Local builds use localhost. No secrets or API keys are required.

Open Graph and Twitter use the 1200×630 hero image in public/social/strickey.png, with the preview title and site name set to strickey. Twitter uses a large image card.

## Design and assets

The supplied references guide the centered launch hero, varied product tiles, and oversized footer wordmark. The site uses a deliberately restrained layout with a focused keyboard animation (design variance 5, motion intensity 5, visual density 3). Functional controls are pills, feature tiles have 24px corners, and the app preview keeps the native panel's smaller radii.

The pixel Mac illustration and its generation prompt are documented in [ASSETS.md](ASSETS.md). Logo and audio attribution remain in their original repository files.

Dependency verification found no production dependency vulnerabilities. npm currently reports five related audit entries for the upstream braces dependency used by Next's development-only ESLint tooling; there is no patched braces release available at the time of verification. This dependency is not part of the website runtime or macOS app.
