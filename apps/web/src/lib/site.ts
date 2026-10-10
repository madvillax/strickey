import release from "../../public/downloads/release.json";

export const repository = "https://github.com/madvillax/strickey";
export const downloadFilename = release.filename;
export const download = "/downloads/" + downloadFilename;
export const profiles = [
  { id: "red", name: "Cherry MX Red", short: "Red", feeling: "Smooth & mellow", description: "A soft, linear sound for getting into your flow." },
  { id: "brown", name: "Cherry MX Brown", short: "Brown", feeling: "Warm & tactile", description: "A little texture. A lovely, balanced clack." },
  { id: "blue", name: "Cherry MX Blue", short: "Blue", feeling: "Crisp & clicky", description: "The unmistakable click of a classic mechanical switch." },
] as const;
export type SwitchProfile = typeof profiles[number]["id"];
