import { readFile } from "node:fs/promises";
import { createHash } from "node:crypto";
import { fileURLToPath } from "node:url";
import path from "node:path";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const folder = path.join(root, "apps/web/public/downloads");
const release = JSON.parse(await readFile(path.join(folder, "release.json"), "utf8"));
if (!/^\d+\.\d+\.\d+$/.test(release.version)
  || release.filename !== "Strickey-" + release.version + "-universal.dmg"
  || !/^[a-f0-9]{64}$/.test(release.sha256)) {
  throw new Error("Invalid website download metadata.");
}
const bytes = await readFile(path.join(folder, release.filename));
const hash = createHash("sha256").update(bytes).digest("hex");
const checksum = (await readFile(path.join(folder, release.filename + ".sha256"), "utf8")).trim().split(/\s+/)[0];
if (hash !== release.sha256 || hash !== checksum || bytes.length !== release.size) {
  throw new Error("Website DMG size/checksum does not match the release metadata.");
}
console.log("Verified website package: " + release.filename);
