import { cp, mkdir } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import path from "node:path";

// The Swift app remains the source of truth for the logo and recorded sounds.
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const destination = path.join(root, "apps/web/public/generated");
const recordings = path.join(root, "Sources/StrickeyCore/Resources/CherryMX");
await mkdir(path.join(destination, "sounds"), { recursive: true });
await cp(path.join(root, "assets/strickey-logo.png"), path.join(destination, "strickey-logo.png"));
await cp(recordings, path.join(destination, "sounds"), { recursive: true });
console.log("Synced strickey logo, recordings, and sound attribution to the website.");
