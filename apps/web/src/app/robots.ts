import type { MetadataRoute } from "next";
import { absoluteURL, isIndexable } from "@/lib/seo";

export default function robots(): MetadataRoute.Robots {
  return isIndexable
    ? { rules: { userAgent: "*", allow: "/" }, sitemap: absoluteURL("/sitemap.xml") }
    : { rules: { userAgent: "*", disallow: "/" } };
}
