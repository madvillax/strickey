// CommonJS keeps this configuration loadable by next.config.ts at build AND
// server startup, including Node.js versions without native TypeScript loading.
// Never use VERCEL_URL: it identifies a deployment, not the canonical website.
const configuredURL =
  process.env.NEXT_PUBLIC_SITE_URL ||
  (process.env.VERCEL_PROJECT_PRODUCTION_URL
    ? `https://${process.env.VERCEL_PROJECT_PRODUCTION_URL}`
    : "http://localhost:3000");
const parsedURL = new URL(configuredURL);

if (!["http:", "https:"].includes(parsedURL.protocol) || parsedURL.username || parsedURL.password) {
  throw new Error("NEXT_PUBLIC_SITE_URL must be an HTTP(S) website URL without credentials.");
}

module.exports = {
  siteOrigin: parsedURL.origin,
  isIndexable:
    process.env.VERCEL_ENV !== "preview" &&
    process.env.VERCEL_ENV !== "development" &&
    !["localhost", "127.0.0.1", "[::1]"].includes(parsedURL.hostname),
};
