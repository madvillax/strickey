import Image from "next/image";

export function Brand({ inverted = false }: { inverted?: boolean }) {
  return <a href="#top" className={"brand " + (inverted ? "brand-inverted" : "")} aria-label="strickey home">
    <Image src="/generated/strickey-logo.png" alt="" width={36} height={36} priority />
    <span>strickey</span>
  </a>;
}
