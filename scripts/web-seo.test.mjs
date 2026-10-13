import assert from "node:assert/strict";
import { before, test } from "node:test";

const baseURL = process.env.SEO_TEST_BASE_URL || "http://localhost:3000";
let html;
let canonical;
let indexable;

async function get(path, options) {
  return fetch(new URL(path, baseURL), { signal: AbortSignal.timeout(15_000), ...options });
}

function meta(name) {
  return html.match(new RegExp(`<meta (?:name|property)="${name}" content="([^"]*)"`))?.[1];
}

before(async () => {
  const response = await get("/");
  assert.equal(response.status, 200);
  html = await response.text();
  canonical = html.match(/<link rel="canonical" href="([^"]+)"/)?.[1];
  assert.ok(canonical, "Homepage needs a canonical URL");
  assert.equal(new URL(canonical).pathname, "/");
  if (process.env.SEO_EXPECT_SITE_URL) {
    assert.equal(canonical, new URL(process.env.SEO_EXPECT_SITE_URL).origin);
  }
  indexable = !meta("robots")?.includes("noindex");
  if (process.env.SEO_EXPECT_INDEXABLE) {
    assert.equal(indexable, process.env.SEO_EXPECT_INDEXABLE === "true");
  }
  if (indexable) {
    assert.doesNotMatch(response.headers.get("x-robots-tag") || "", /noindex/);
  } else {
    assert.match(response.headers.get("x-robots-tag") || "", /noindex/);
  }
});

test("homepage has searchable metadata and complete social cards", async () => {
  assert.match(html, /<html[^>]+lang="en"/);
  assert.match(html, /<title>[^<]*Mechanical Keyboard Sounds for Mac[^<]*<\/title>/);
  assert.equal((html.match(/<h1\b/g) || []).length, 1);
  assert.ok(meta("description")?.includes("Cherry MX"));
  assert.ok(meta("robots"));
  assert.equal(meta("og:url"), canonical);
  assert.equal(meta("og:site_name"), "strickey");
  assert.ok(meta("og:title"));
  assert.ok(meta("og:description"));
  assert.equal(meta("og:image:width"), "1200");
  assert.equal(meta("og:image:height"), "630");
  assert.equal(meta("twitter:card"), "summary_large_image");
  const image = meta("og:image");
  assert.equal(image, new URL("/social/strickey.png", canonical).href);
  assert.equal(meta("twitter:image"), image);
  const response = await get(new URL(image).pathname);
  assert.equal(response.status, 200);
  assert.match(response.headers.get("content-type"), /image\/png/);
});

test("server-rendered structured data describes the real software release", async () => {
  const scripts = [...html.matchAll(/<script type="application\/ld\+json">([\s\S]*?)<\/script>/g)];
  assert.equal(scripts.length, 1);
  const data = JSON.parse(scripts[0][1]);
  assert.equal(data["@context"], "https://schema.org");
  const website = data["@graph"].find((entry) => entry["@type"] === "WebSite");
  const page = data["@graph"].find((entry) => entry["@type"] === "WebPage");
  const app = data["@graph"].find((entry) => entry["@type"] === "SoftwareApplication");
  assert.equal(website.url, canonical);
  assert.equal(page.url, canonical);
  assert.equal(page.mainEntity["@id"], app["@id"]);
  assert.equal(app.operatingSystem, "macOS 14 or later");
  assert.equal(app.offers.price, "0");
  assert.equal(app.aggregateRating, undefined);
  const response = await get("/downloads/release.json");
  assert.equal(response.status, 200);
  const release = await response.json();
  assert.equal(app.softwareVersion, release.version);
  assert.equal(app.downloadUrl, new URL(`/downloads/${release.filename}`, canonical).href);
  const download = await get(new URL(app.downloadUrl).pathname, { method: "HEAD" });
  assert.equal(download.status, 200);
  assert.match(download.headers.get("x-robots-tag") || "", /noindex/);
});

test("robots and sitemap agree with the indexing policy and canonical", async () => {
  const robots = await get("/robots.txt");
  assert.equal(robots.status, 200);
  const rules = await robots.text();
  assert.match(rules, /User-Agent: \*/i);
  const sitemap = await get("/sitemap.xml");
  assert.equal(sitemap.status, 200);
  assert.match(sitemap.headers.get("content-type"), /xml/);
  const xml = await sitemap.text();
  const locations = [...xml.matchAll(/<loc>([^<]+)<\/loc>/g)].map((match) => match[1]);
  if (indexable) {
    assert.match(rules, /Allow: \/(?:\r?\n|$)/);
    assert.ok(rules.includes(`Sitemap: ${new URL("/sitemap.xml", canonical).href}`));
    assert.deepEqual(locations, [canonical]);
  } else {
    assert.match(rules, /Disallow: \/(?:\r?\n|$)/);
    assert.deepEqual(locations, []);
  }
});
