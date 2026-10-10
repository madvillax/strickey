"use client";

import { useEffect, useRef } from "react";

export function Reveal({ children, className = "" }: { children: React.ReactNode; className?: string }) {
  const ref = useRef<HTMLDivElement>(null);
  useEffect(() => {
    const node = ref.current;
    if (!node) return;
    const reduce = window.matchMedia("(prefers-reduced-motion: reduce)");
    // SSR is visible by default; only defer sections still below the viewport.
    if (!reduce.matches && node.getBoundingClientRect().top > window.innerHeight) node.classList.add("reveal-pending");
    const observer = new IntersectionObserver(([entry]) => {
      if (entry.isIntersecting) { node.classList.remove("reveal-pending"); observer.disconnect(); }
    }, { threshold: 0.08 });
    const show = () => { if (reduce.matches) node.classList.remove("reveal-pending"); };
    observer.observe(node);
    reduce.addEventListener("change", show);
    return () => { observer.disconnect(); reduce.removeEventListener("change", show); node.classList.remove("reveal-pending"); };
  }, []);
  return <div ref={ref} className={"reveal " + className}>{children}</div>;
}
