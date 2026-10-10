"use client";

import { useState } from "react";
import Image from "next/image";
import { IconBrandApple, IconKeyboard, IconVolume, IconLock, IconPlayerPlay, IconCheck } from "@tabler/icons-react";
import { profiles, type SwitchProfile } from "@/lib/site";
import { useKeyboardAudio } from "./use-keyboard-audio";

export function AppMockup() {
  const [open, setOpen] = useState(true);
  const [profile, setProfile] = useState<SwitchProfile>("brown");
  const [volume, setVolume] = useState(70);
  const [enabled, setEnabled] = useState(true);
  const [previewing, setPreviewing] = useState(false);
  const audio = useKeyboardAudio(profile, enabled ? volume / 100 : 0);
  const selected = profiles.find((item) => item.id === profile)!;
  async function preview() {
    setPreviewing(true);
    if (audio.status !== "ready") await audio.toggle();
    for (let i = 0; i < 4; i++) {
      await audio.play(i === 3 ? "enter" : "regular");
      await new Promise((resolve) => setTimeout(resolve, 150));
    }
    setPreviewing(false);
  }
  return <div className="desktop-mockup">
    <div className="mac-menu">
      <div className="mac-menu-left"><IconBrandApple size={17} fill="currentColor" /><strong>Finder</strong><span>File</span><span>Edit</span><span>View</span></div>
      <button aria-label={open ? "Close strickey preview panel" : "Open strickey preview panel"} aria-expanded={open}
        onClick={() => setOpen(!open)} className="mac-status-icon"><IconKeyboard size={18} stroke={1.6} /></button>
    </div>
    <div className="wallpaper-shape shape-left" /><div className="wallpaper-shape shape-right" />
    <div className="desktop-word" aria-hidden="true">hello,<br />good feeling.</div>
    {open ? <div className="app-popover">
      <div className="app-heading">
        <Image src="/generated/strickey-logo.png" width={35} height={35} alt="" />
        <div><strong>strickey</strong><span>Make every key feel good.</span></div>
        <button role="switch" aria-checked={enabled} aria-label="Enable preview keyboard sounds"
          className={"app-toggle " + (enabled ? "is-on" : "")} onClick={() => setEnabled(!enabled)}><span /></button>
      </div>
      <div className="app-status"><IconCheck size={13} />{enabled ? "Ready for your next keystroke" : "Sounds are paused"}</div>
      <span className="app-section-label">SWITCH PROFILE</span>
      <div className="app-switches">
        {profiles.map((item) => <button key={item.id} onClick={() => setProfile(item.id)}
          aria-pressed={profile === item.id} className={profile === item.id ? "selected" : ""}>
          <IconKeyboard size={19} stroke={1.4} /><span>{item.short}</span>
        </button>)}
      </div>
      <p className="app-feeling">{selected.feeling}</p>
      <div className="app-volume-label"><span>Keyboard volume</span><span>{volume}%</span></div>
      <label className="app-volume"><IconVolume size={14} stroke={1.7} />
        <input type="range" min={0} max={100} value={volume} onChange={(event) => setVolume(Number(event.target.value))}
          aria-label="App preview keyboard volume" /></label>
      <div className="app-output"><span>Mac default output</span>
        <button onClick={() => void preview()} disabled={!enabled || previewing}><IconPlayerPlay size={11} />
          {previewing ? "Playing…" : "Preview"}</button></div>
      {audio.status === "error" ? <p role="alert" className="app-error">Audio couldn’t load. Try Preview again.</p> : null}
      <div className="app-privacy"><IconLock size={12} /> Only sound. Nothing saved.</div>
    </div> : null}
    <span className="mockup-caption">Click the menu bar icon. Make it yours.</span>
  </div>;
}
