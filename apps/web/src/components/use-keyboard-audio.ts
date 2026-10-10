"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import type { SwitchProfile } from "@/lib/site";

type AudioStatus = "off" | "loading" | "ready" | "error";
type KeyKind = "regular" | "space" | "enter" | "delete";
const downloads = new Map<string, Promise<ArrayBuffer>>();

function loadRecording(file: string) {
  let request = downloads.get(file);
  if (!request) {
    request = fetch("/generated/sounds/" + file).then((response) => {
      if (!response.ok) throw new Error("Recording unavailable");
      return response.arrayBuffer();
    }).catch((error) => { downloads.delete(file); throw error; });
    downloads.set(file, request);
  }
  return request;
}

export function useKeyboardAudio(profile: SwitchProfile, volume: number) {
  const [status, setStatus] = useState<AudioStatus>("off");
  const context = useRef<AudioContext | null>(null);
  const buffers = useRef(new Map<string, AudioBuffer>());
  const current = useRef({ profile, volume });
  const enabled = useRef(false);
  useEffect(() => { current.current = { profile, volume }; }, [profile, volume]);
  useEffect(() => () => { enabled.current = false; void context.current?.close(); context.current = null; }, []);

  const ensureBuffer = useCallback(async (file: string) => {
    const audio = context.current;
    if (!audio) return null;
    let buffer = buffers.current.get(file);
    if (!buffer) {
      const bytes = await loadRecording(file);
      buffer = await audio.decodeAudioData(bytes.slice(0));
      buffers.current.set(file, buffer);
    }
    return buffer;
  }, []);

  const play = useCallback(async (kind: KeyKind = "regular") => {
    if (!enabled.current) return;
    const audio = context.current;
    if (!audio) return;
    const { profile: selected, volume: gain } = current.current;
    const suffix = kind === "regular" ? "regular-" + Math.floor(Math.random() * 4) : kind;
    try {
      const buffer = await ensureBuffer(selected + "-" + suffix + ".wav");
      if (!buffer || !enabled.current || context.current !== audio) return;
      if (audio.state === "suspended") await audio.resume();
      const source = audio.createBufferSource();
      const volumeNode = audio.createGain();
      source.buffer = buffer;
      volumeNode.gain.value = gain;
      source.connect(volumeNode).connect(audio.destination);
      source.start();
    } catch {
      enabled.current = false;
      setStatus("error");
    }
  }, [ensureBuffer]);

  const toggle = useCallback(async () => {
    if (enabled.current) {
      enabled.current = false;
      setStatus("off");
      await context.current?.suspend();
      return;
    }
    setStatus("loading");
    try {
      if (!context.current) context.current = new AudioContext();
      await context.current.resume();
      await Promise.all(Array.from({ length: 4 }, (_, index) =>
        ensureBuffer(current.current.profile + "-regular-" + index + ".wav")));
      enabled.current = true;
      setStatus("ready");
      await play();
    } catch {
      enabled.current = false;
      setStatus("error");
    }
  }, [ensureBuffer, play]);

  return { status, toggle, play };
}
