import type { MetadataRoute } from "next";
import { absoluteURL, isIndexable } from "@/lib/seo";

export default function sitemap(): MetadataRoute.Sitemap {
  // Only indexable pages belong here, not anchor links or downloadable files.
  // Add real content modification dates when pages have a maintained date;
  // a build timestamp is not a meaningful lastmod signal.
  return isIndexable ? [{ url: absoluteURL("/") }] : [];
}
