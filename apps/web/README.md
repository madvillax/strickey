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

Set `NEXT_PUBLIC_SITE_URL` to the final HTTPS production origin **before building** (see `.env.example`). This controls canonical links, social image URLs, structured data, robots, and the sitemap. On Vercel, `VERCEL_PROJECT_PRODUCTION_URL` is the fallback; deployment-specific `VERCEL_URL` is deliberately not used. Local builds use localhost. No secrets or API keys are required.

## SEO

- Next.js serves `/robots.txt` and `/sitemap.xml` from `src/app/robots.ts` and `src/app/sitemap.ts`. Only the canonical homepage is listed; downloads and section anchors are not pages.
- The homepage has a self-referencing canonical, descriptive title/description, and Open Graph/Twitter large-image cards using `public/social/strickey.png` (1200×630).
- Server-rendered JSON-LD describes the website, page, and free macOS software. Software version and download URL track `public/downloads/release.json`. No ratings or reviews are fabricated; software rich results are not guaranteed.
- Vercel previews/development and localhost builds are `noindex`, block crawling, and return an empty sitemap. Preview detection uses `VERCEL_ENV`; on other hosts, explicitly set `VERCEL_ENV=preview` for staging builds. Rebuild after changing the URL or deployment environment.
- Downloads have `X-Robots-Tag: noindex` headers. They remain crawlable on production so search engines can see that directive.
- Optional `GOOGLE_SITE_VERIFICATION` and `BING_SITE_VERIFICATION` environment variables emit ownership verification tags. Use the token values, not full HTML tags.

### Launch checklist

1. Set the production URL, deploy, and verify that HTTP/nonpreferred-domain URLs redirect to the preferred HTTPS origin in your hosting configuration.
2. Check `/robots.txt`, `/sitemap.xml`, the canonical link, and social previews on the deployed site. Production must not emit `noindex`.
3. Verify ownership in Google Search Console and Bing Webmaster Tools; submit `/sitemap.xml` and request indexing of the homepage.
4. Validate the page with Google's Rich Results Test and Schema.org Validator. Run PageSpeed Insights on mobile and desktop to assess Core Web Vitals.
5. Monitor indexing and search performance. These files provide technical SEO foundations, not a guarantee of rankings.

### SEO regression checks

With the built site running (`npm run build` then `npm run start`), run from the repository root:

~~~sh
npm run test:seo
~~~

The tests check rendered HTML, JSON-LD, robots, sitemap, social image availability, and download indexing headers. To test a deployed site, set `SEO_TEST_BASE_URL` to its URL. `SEO_EXPECT_SITE_URL` can independently assert the expected canonical origin, and `SEO_EXPECT_INDEXABLE=true` (or `false`) asserts the expected indexing policy.

## Design and assets

The supplied references guide the centered launch hero, varied product tiles, and oversized footer wordmark. The site uses a deliberately restrained layout with a focused keyboard animation (design variance 5, motion intensity 5, visual density 3). Functional controls are pills, feature tiles have 24px corners, and the app preview keeps the native panel's smaller radii.

The pixel Mac illustration and its generation prompt are documented in [ASSETS.md](ASSETS.md). Logo and audio attribution remain in their original repository files.

Dependency verification found no production dependency vulnerabilities. npm currently reports five related audit entries for the upstream braces dependency used by Next's development-only ESLint tooling; there is no patched braces release available at the time of verification. This dependency is not part of the website runtime or macOS app.
