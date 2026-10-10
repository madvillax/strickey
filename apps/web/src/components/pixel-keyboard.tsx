"use client";

import { useEffect, useRef, useState } from "react";
import { IconVolume, IconVolumeOff } from "@tabler/icons-react";
import { profiles, type SwitchProfile } from "@/lib/site";
import { useKeyboardAudio } from "./use-keyboard-audio";

type Key = { label: string; code: string; x: number; y: number; width: number };
type KeyDefinition = [string, string, number?];
const rows: KeyDefinition[][] = [
  [["ESC","Escape"],["1","Digit1"],["2","Digit2"],["3","Digit3"],["4","Digit4"],["5","Digit5"],["6","Digit6"],["7","Digit7"],["8","Digit8"],["9","Digit9"],["0","Digit0"],["-","Minus"],["=","Equal"],["DEL","Backspace",1.6]],
  [["TAB","Tab",1.4],["Q","KeyQ"],["W","KeyW"],["E","KeyE"],["R","KeyR"],["T","KeyT"],["Y","KeyY"],["U","KeyU"],["I","KeyI"],["O","KeyO"],["P","KeyP"],["[","BracketLeft"],["]","BracketRight"],["\\","Backslash",1.2]],
  [["CAP","CapsLock",1.7],["A","KeyA"],["S","KeyS"],["D","KeyD"],["F","KeyF"],["G","KeyG"],["H","KeyH"],["J","KeyJ"],["K","KeyK"],["L","KeyL"],[";","Semicolon"],["'","Quote"],["ENTER","Enter",1.8]],
  [["SHIFT","ShiftLeft",2.1],["Z","KeyZ"],["X","KeyX"],["C","KeyC"],["V","KeyV"],["B","KeyB"],["N","KeyN"],["M","KeyM"],[",","Comma"],[".","Period"],["/","Slash"],["SHIFT","ShiftRight",2.4]],
  [["FN","Fn"],["CTRL","ControlLeft",1.1],["ALT","AltLeft"],["CMD","MetaLeft",1.2],["STRICKEY","Space",6.5],["CMD","MetaRight",1.2],["ALT","AltRight"],["<","ArrowLeft"],[">","ArrowRight"]],
];
const keys: Key[] = rows.flatMap((row, rowIndex) => {
  const units = row.reduce((sum, key) => sum + (key[2] ?? 1), 0);
  const unit = (572 - (row.length - 1) * 5) / units;
  let left = 34;
  return row.map(([label, code, size = 1]) => {
    const key = { label, code, x: Math.round(left), y: 27 + rowIndex * 42, width: Math.round(unit * size) };
    left += unit * size + 5;
    return key;
  });
});
const glyphs: Record<string, number[]> = {
  A:[14,17,31,17,17], B:[30,17,30,17,30], C:[15,16,16,16,15], D:[30,17,17,17,30],
  E:[31,16,30,16,31], F:[31,16,30,16,16], G:[15,16,23,17,15], H:[17,17,31,17,17],
  I:[31,4,4,4,31], J:[7,2,2,18,12], K:[17,18,28,18,17], L:[16,16,16,16,31],
  M:[17,27,21,17,17], N:[17,25,21,19,17], O:[14,17,17,17,14], P:[30,17,30,16,16],
  Q:[14,17,21,18,13], R:[30,17,30,18,17], S:[15,16,14,1,30], T:[31,4,4,4,4],
  U:[17,17,17,17,14], V:[17,17,17,10,4], W:[17,17,21,27,17], X:[17,10,4,10,17],
  Y:[17,10,4,4,4], Z:[31,2,4,8,31],
  "0":[14,19,21,25,14],"1":[4,12,4,4,14],"2":[30,1,14,16,31],"3":[30,1,14,1,30],
  "4":[18,18,31,2,2],"5":[31,16,30,1,30],"6":[15,16,30,17,14],"7":[31,1,2,4,4],
  "8":[14,17,14,17,14],"9":[14,17,15,1,30],
  "-":[0,0,14,0,0],"=":[0,14,0,14,0],".":[0,0,0,0,4],",":[0,0,0,4,8],
  "/":[1,2,4,8,16],"\\":[16,8,4,2,1],"[":[6,4,4,4,6],"]":[12,4,4,4,12],
  ";":[0,4,0,4,8],"'":[4,4,0,0,0],"<":[2,4,8,4,2],">":[8,4,2,4,8],
};

function pixelRect(ctx: CanvasRenderingContext2D, x: number, y: number, w: number, h: number, step = 3) {
  ctx.fillRect(x + step, y, w - step * 2, h);
  ctx.fillRect(x, y + step, w, h - step * 2);
}
function legend(ctx: CanvasRenderingContext2D, label: string, centerX: number, y: number) {
  const scale = label.length > 2 ? 1 : 2;
  const start = Math.round(centerX - (label.length * 6 - 1) * scale / 2);
  for (let i = 0; i < label.length; i++) {
    const bitmap = glyphs[label[i]];
    bitmap?.forEach((bits, row) => {
      for (let col = 0; col < 5; col++) {
        if (bits & (1 << (4 - col))) ctx.fillRect(start + (i * 6 + col) * scale, y + row * scale, scale, scale);
      }
    });
  }
}

export function PixelKeyboard() {
  const [profile, setProfile] = useState<SwitchProfile>("brown");
  const { status, toggle, play } = useKeyboardAudio(profile, 0.7);
  const canvas = useRef<HTMLCanvasElement>(null);
  const input = useRef<HTMLInputElement>(null);
  const activeKeys = useRef(new Map<string, number>());
  const userTyped = useRef(false);
  const visible = useRef(true);
  const repaint = useRef<(() => void) | null>(null);

  useEffect(() => {
    const node = canvas.current;
    const ctx = node?.getContext("2d");
    if (!node || !ctx) return;
    ctx.imageSmoothingEnabled = false;
    const reduce = window.matchMedia("(prefers-reduced-motion: reduce)");
    const observer = new IntersectionObserver(([entry]) => { visible.current = entry.isIntersecting; });
    observer.observe(node);
    let frame = 0;
    let previous = 0;
    let previousFrame = 0;
    let character = 0;
    const timeouts = new Set<ReturnType<typeof setTimeout>>();
    const phrase = "typing feels good.";
    function draw(time: number) {
      if (ctx && visible.current && !document.hidden && (reduce.matches || time - previousFrame >= 32)) {
        previousFrame = time;
        ctx.clearRect(0, 0, 640, 260);
        ctx.fillStyle = "#c4ceda";
        pixelRect(ctx, 12, 15, 616, 240, 10);
        ctx.fillStyle = "#303743";
        pixelRect(ctx, 12, 8, 616, 237, 10);
        ctx.fillStyle = "#e5eaf0";
        pixelRect(ctx, 16, 8, 608, 228, 8);
        ctx.fillStyle = "#f7f9fc";
        pixelRect(ctx, 20, 12, 600, 217, 6);
        for (const key of keys) {
          const age = time - (activeKeys.current.get(key.code) ?? -1000);
          const down = age < (reduce.matches ? 60 : 170);
          const y = key.y + (down ? 4 : 0);
          const blue = key.code === "Space";
          ctx.fillStyle = "#939ca9";
          pixelRect(ctx, key.x, key.y + 5, key.width, 32, 3);
          ctx.fillStyle = down || blue ? "#0072ed" : "#b8c1cf";
          pixelRect(ctx, key.x, y, key.width, 32, 3);
          ctx.fillStyle = down ? "#69b2ff" : blue ? "#a4d1ff" : "#ffffff";
          pixelRect(ctx, key.x + 2, y, key.width - 4, 27, 2);
          ctx.fillStyle = down ? "#162e47" : blue ? "#315571" : "#5c6673";
          legend(ctx, key.label, key.x + key.width / 2, y + (key.label.length > 2 ? 11 : 9));
        }
      }
      if (!reduce.matches) frame = requestAnimationFrame(draw);
    }
    function restart() { cancelAnimationFrame(frame); draw(performance.now()); }
    reduce.addEventListener("change", restart);
    repaint.current = () => {
      if (!reduce.matches) return;
      draw(performance.now());
      const timeout = setTimeout(() => { draw(performance.now()); timeouts.delete(timeout); }, 180);
      timeouts.add(timeout);
    };
    draw(performance.now());
    const interval = window.setInterval(() => {
      if (reduce.matches || document.hidden || !visible.current || userTyped.current || document.activeElement === input.current) return;
      const now = performance.now();
      if (now - previous < 150) return;
      previous = now;
      if (character > phrase.length + 7) character = 0;
      if (character <= phrase.length) {
        if (input.current) input.current.value = phrase.slice(0, character);
        const letter = phrase[character - 1];
        const code = letter === " " ? "Space" : letter === "." ? "Period" : "Key" + (letter?.toUpperCase() ?? "");
        if (letter) {
          activeKeys.current.set(code, now);
          void play(letter === " " ? "space" : "regular");
        }
      }
      character++;
    }, 180);
    return () => {
      cancelAnimationFrame(frame); clearInterval(interval); observer.disconnect();
      reduce.removeEventListener("change", restart); timeouts.forEach(clearTimeout); repaint.current = null;
    };
  }, [play]);

  function physicalKey(event: React.KeyboardEvent<HTMLInputElement>) {
    if (event.metaKey || event.ctrlKey || event.altKey || event.repeat) return;
    userTyped.current = true;
    activeKeys.current.set(event.code, performance.now());
    repaint.current?.();
    if (event.key === "Tab" || event.key === "Shift") return;
    void play(event.code === "Space" ? "space" : event.key === "Enter" ? "enter" : event.key === "Backspace" ? "delete" : "regular");
  }
  function clickKey(event: React.PointerEvent<HTMLCanvasElement>) {
    const bounds = event.currentTarget.getBoundingClientRect();
    const x = (event.clientX - bounds.left) * 640 / bounds.width;
    const y = (event.clientY - bounds.top) * 260 / bounds.height;
    const key = keys.find((key) => x >= key.x && x <= key.x + key.width && y >= key.y && y <= key.y + 37);
    if (!key) return;
    activeKeys.current.set(key.code, performance.now());
    repaint.current?.();
    void play(key.code === "Space" ? "space" : key.code === "Enter" ? "enter" : key.code === "Backspace" ? "delete" : "regular");
    input.current?.focus();
  }
  return <div className="keyboard-demo" id="sounds">
    <div className="typing-prompt">
      <span className="typing-mark" aria-hidden="true">&gt;</span>
      <input ref={input} aria-label="Type here to try the keyboard sounds" placeholder="type something good."
        maxLength={64} autoComplete="off" spellCheck={false}
        onFocus={() => { if (!userTyped.current && input.current) input.current.value = ""; }}
        onKeyDown={physicalKey} onChange={() => { userTyped.current = true; }} />
      <span className="typing-caret" aria-hidden="true" />
    </div>
    <canvas ref={canvas} width={640} height={260} className="pixel-keyboard"
      onPointerDown={clickKey} role="img" aria-label="Animated eight-bit mechanical keyboard. Click its keys or type in the field above." />
    <div className="demo-toolbar">
      <div className="profile-buttons" aria-label="Keyboard switch profile">
        {profiles.map((item) => <button key={item.id} aria-pressed={profile === item.id}
          onClick={() => setProfile(item.id)}><span className={"switch-chip chip-" + item.id} />MX {item.short}</button>)}
      </div>
      <button className="sound-button" onClick={() => void toggle()} disabled={status === "loading"}
        aria-pressed={status === "ready"}>
        {status === "ready" ? <IconVolume size={17} stroke={1.7} /> : <IconVolumeOff size={17} stroke={1.7} />}
        {status === "ready" ? "Sound on" : status === "loading" ? "Loading…" : status === "error" ? "Retry sound" : "Turn sound on"}
      </button>
    </div>
    <p className="demo-caption" role="status">{status === "error" ? "Couldn't load the recordings. Try again." : "Real switch recordings. Try the keys above."}</p>
  </div>;
}
