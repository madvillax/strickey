import seoConfig from "../../seo.config.cjs";

// Keep canonicals, social metadata, robots, and the sitemap on the same origin.
export const siteURL = new URL(seoConfig.siteOrigin);
export const isIndexable = seoConfig.isIndexable;
export const siteTitle = "strickey — Free Mechanical Keyboard Sounds for Mac";
export const siteDescription =
  "Add real Cherry MX mechanical keyboard sounds to your Mac. Choose Red, Brown, or Blue switches in a free, open-source menu bar app. No extra hardware needed.";
export const socialPreview = {
  url: "/social/strickey.png",
  width: 1200,
  height: 630,
  alt: "strickey. All the clack. None of the keyboard.",
  type: "image/png",
};

export function absoluteURL(path: string) {
  // Next.js emits the root canonical without a trailing slash by default.
  return path === "/" ? siteURL.origin : new URL(path, siteURL).href;
}
