import release from "../../public/downloads/release.json";
import { download, repository } from "./site";
import { absoluteURL, siteDescription, siteTitle } from "./seo";

export const structuredData = {
  "@context": "https://schema.org",
  "@graph": [
    {
      "@type": "WebSite",
      "@id": absoluteURL("/#website"),
      url: absoluteURL("/"),
      name: "strickey",
      description: siteDescription,
      inLanguage: "en",
    },
    {
      "@type": "WebPage",
      "@id": absoluteURL("/#webpage"),
      url: absoluteURL("/"),
      name: siteTitle,
      description: siteDescription,
      inLanguage: "en",
      isPartOf: { "@id": absoluteURL("/#website") },
      mainEntity: { "@id": absoluteURL("/#software") },
    },
    {
      "@type": "SoftwareApplication",
      "@id": absoluteURL("/#software"),
      name: "strickey",
      url: absoluteURL("/"),
      description: siteDescription,
      image: absoluteURL("/social/strickey.png"),
      operatingSystem: "macOS 14 or later",
      applicationCategory: "UtilitiesApplication",
      softwareVersion: release.version,
      downloadUrl: absoluteURL(download),
      license: repository + "/blob/main/LICENSE",
      isAccessibleForFree: true,
      offers: { "@type": "Offer", price: "0", priceCurrency: "USD", url: absoluteURL("/") },
      author: { "@type": "Person", name: "Mohit Sharma", url: "https://github.com/madvillax" },
      sameAs: [repository],
      featureList: [
        "Cherry MX Red, Brown, and Blue switch recordings",
        "Independent volume control",
        "Native macOS menu bar app",
        "Apple Silicon and Intel support",
      ],
    },
  ],
};
