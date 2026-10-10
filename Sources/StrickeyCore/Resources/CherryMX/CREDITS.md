# Cherry MX recordings

Source: [Mechvibes](https://github.com/hainguyents13/mechvibes), by Hai Nguyen.
Pinned source revision: `326252a13e7bef4f1c35d08ef0189b5af6f8ba02`.

The CherryMX Red, Brown, and Blue **PBT keycap** recordings come from
`src/audio/cherrymx-{red,brown,blue}-pbt/sound.ogg` and their matching `config.json`.
They are distributed under the upstream MIT license, reproduced in
`LICENSE-Mechvibes.txt`. The original source contains no separate license for these packs.

Strickey extracts seven recorded keystrokes per switch: A/S/D/F variants, space,
return, and backspace. Each clip contains the recorded press and release. It plays
once on key-down; key-up does not trigger a duplicate recording.

Modifications: extract the upstream timing ranges, downmix to mono, resample to
44.1 kHz, linearly normalize peaks to 90%, and add 1 ms edge fades. No synthesized
sound, pitch changes, or saturation is added. `manifest.json` records source hashes,
clip offsets, and output checksums. Run `scripts/import-cherry-mx.py` to reproduce.

Cherry and Cherry MX are trademarks of their respective owners. Strickey is
independent and is not affiliated with or endorsed by Cherry or Mechvibes.
