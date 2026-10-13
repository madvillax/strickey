import type { Metadata } from "next";
import { GeistPixelSquare } from "geist/font/pixel";
import localFont from "next/font/local";
import { isIndexable, siteURL, siteTitle, siteDescription, socialPreview } from "@/lib/seo";
import "./globals.css";

const Manrope = localFont({ src: "./fonts/manrope-latin.woff2", variable: "--font-manrope", weight: "200 800", display: "swap" });
export const metadata: Metadata = {
  metadataBase: siteURL,
  title: { default: siteTitle, template: "%s | strickey" },
  description: siteDescription,
  applicationName: "strickey",
  authors: [{ name: "Mohit Sharma", url: "https://github.com/madvillax" }],
  robots: isIndexable
    ? { index: true, follow: true, googleBot: { index: true, follow: true, "max-image-preview": "large", "max-snippet": -1, "max-video-preview": -1 } }
    : { index: false, follow: false },
  verification: {
    google: process.env.GOOGLE_SITE_VERIFICATION,
    other: process.env.BING_SITE_VERIFICATION ? { "msvalidate.01": process.env.BING_SITE_VERIFICATION } : undefined,
  },
  icons: { icon: "/generated/strickey-logo.png", apple: "/generated/strickey-logo.png" },
  openGraph: { title: siteTitle, siteName: "strickey", url: "/", locale: "en_US", description: siteDescription, type: "website", images: [socialPreview] },
  twitter: { card: "summary_large_image", title: siteTitle, description: siteDescription, images: [socialPreview] },
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en" data-theme="dark">
      <body className={GeistPixelSquare.variable + " " + Manrope.variable + " antialiased"}>{children}</body>
    </html>
  );
}
