import type { Metadata } from "next";
import { GeistPixelSquare } from "geist/font/pixel";
import localFont from "next/font/local";
import "./globals.css";

const Manrope = localFont({ src: "./fonts/manrope-latin.woff2", variable: "--font-manrope", weight: "200 800", display: "swap" });
const productionDomain = process.env.VERCEL_PROJECT_PRODUCTION_URL || process.env.VERCEL_URL;
const siteURL = process.env.NEXT_PUBLIC_SITE_URL || (productionDomain ? "https://" + productionDomain : "http://localhost:3000");
const socialPreview = { url: "/social/strickey.png", width: 1200, height: 630, alt: "strickey. All the clack. None of the keyboard.", type: "image/png" };

export const metadata: Metadata = {
  metadataBase: new URL(siteURL),
  title: "strickey",
  description: "Real Cherry MX keyboard sounds for your Mac. A tiny, free, open-source menu bar app with switch profiles and independent volume.",
  icons: { icon: "/generated/strickey-logo.png", apple: "/generated/strickey-logo.png" },
  openGraph: { title: "strickey", siteName: "strickey", url: "/", description: "Bring the sounds of mechanical switches to your everyday typing.", type: "website", images: [socialPreview] },
  twitter: { card: "summary_large_image", title: "strickey", description: "A tiny mechanical keyboard soundtrack for your Mac.", images: [socialPreview] },
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en" data-theme="dark">
      <body className={GeistPixelSquare.variable + " " + Manrope.variable + " antialiased"}>{children}</body>
    </html>
  );
}
