import type { NextConfig } from "next";
import path from "node:path";

const repositoryRoot = path.resolve(process.cwd(), "../..");
const nextConfig: NextConfig = {
  poweredByHeader: false,
  devIndicators: false,
  outputFileTracingRoot: repositoryRoot,
  turbopack: { root: repositoryRoot },
  experimental: { optimizePackageImports: ["@tabler/icons-react"] },
  async headers() {
    return [{
      source: "/downloads/:filename(.*\\.dmg)",
      headers: [
        { key: "Content-Disposition", value: "attachment" },
        { key: "Content-Type", value: "application/x-apple-diskimage" },
        { key: "Cache-Control", value: "public, max-age=0, must-revalidate" },
      ],
    }];
  },
};
export default nextConfig;
