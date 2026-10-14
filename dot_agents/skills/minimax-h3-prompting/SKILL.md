---
name: minimax-h3-prompting
description: MiniMax H3 video prompts (image-to-video, first/last frame, reference-to-video with audio), Flux / FLUX.2 klein start-frame image prompts, and LoRA picks with strengths for a scene. Use when writing or fixing an H3 or Flux prompt, planning a scene or shot, or choosing LoRAs for ComfyUI.
---

# 🎬 MiniMax AI Video Creation Workflow

A modular, production-tested guide for generating realistic live-action AI videos using **Flux** (for starting reference frames) and **MiniMax H3** (for multimodal video generation and lip-sync).

Running locally in ComfyUI (the `comfyui-runner` RunPod pod)? Models, sampler settings, workflows, and the H3 still-image nodes are in [`local-comfyui.md`](local-comfyui.md). LoRA choice is section 7.

## 1. Core Agent Interaction Rules (MUST FOLLOW)

- **Step-by-Step Execution:** Execute strictly one scene/task at a time. Never rush ahead.
- **No Unapproved Execution:** Do not write files or video prompts without explicit user confirmation. Discuss and align on concepts, locations, and outfits first.
- **No Premature Video Prompting:** NEVER write video prompts before reference images are generated, placed in `AI/Images/{scene}/`, and visually inspected. Prompts must match the actual generated assets.
- **No Assumptions / Minimal Fluff:** Answer concisely. If requirements are unclear, ask directly instead of guessing.
- **Character Consistency Confirmation:** At the very start of any project, ask:
  > *"Do you want to keep the exact same character identity across all scenes, or do you want random/different characters for each scene?"*

---

## 2. The 5-Step Production Workflow

Follow this sequence for every scene:

```
[1. Concept & Scene Planning] ➡️ [2. Draft Image Prompts] ➡️ [3. Generate Reference Images] ➡️ [4. Review Generated Assets] ➡️ [5. Write MiniMax Video Prompts]
```

1. **Concept & Scene Planning:** Decide location, wardrobe, camera style (Selfie vs. Third-Person Candid), and spoken dialogue.
2. **Draft Image Prompts:** Create image prompts (With Reference + Standalone) enforcing deep depth-of-field and raw realism.
3. **Generate Reference Images:** Generate images using Flux.
4. **Review Assets:** Check real generated poses, framing, lighting, and expressions before touching video prompts.
5. **Write Matched MiniMax Prompts:** Write video prompts tailored 1:1 to the actual image framing, audio duration, and lip-sync speech.

---

## 📸 3. Image Prompting Rules (Flux / Starting Frames)

These rules hold for any Flux model. On the pod the start-frame model is FLUX.2 klein 9B with SNOFS merged in: write full natural-language sentences (it was not trained on tags) and use its vocabulary list in [`local-comfyui.md`](local-comfyui.md).

### A. The "No Phone in Frame" Rule for Selfies (CRITICAL)
* **Never write:** *"holding phone extended in front of her"*, *"holding smartphone"*, or *"holding camera"*.
* **Why:** AI will physically place a floating or distorted smartphone into the subject's hands.
* **Correct Syntax:** Use *"Raw handheld smartphone selfie of [Subject]... She looks directly into the front-facing camera lens..."* This sets the front-camera perspective without adding a phone prop.

### B. Smartphone Optics & Sharp Backgrounds
* **Enforce:** `deep depth-of-field with subject and background both kept in sharp focus`, `crisp background detail`, `no artificial portrait mode blur`.
* **Avoid:** Artificial background bokeh or cinematic lens jargon (e.g. avoid "85mm f/1.2", "heavy bokeh"). Real smartphone wide lenses keep both subject and environment clear.

### C. Raw Natural Aesthetics
* **Enforce:** `raw handheld smartphone photo aesthetic`, `visible skin texture with visible pores`, `natural skin grain`, `no digital airbrushing`, `true-to-life color science`.
* **No Negative Phrasing:** Never use "no blur", "no freckles". State desired features positively (e.g., "clear skin with authentic micro-texture").

### D. Consistent Character Architecture
If using a recurring character across scenes, lock their physical attributes verbatim in every prompt:
* **Hair:** Length, cut, part, and color (e.g., *shoulder-length wavy brown hair with subtle golden highlights and middle part*).
* **Face & Skin:** Facial bone structure, eye color, skin undertone, natural brow shape, minimal natural makeup.
* **Wardrobe Continuity:** Plan outfits in pairs of 2 scenes (e.g., 2 scenes in loungewear, 2 scenes in workout clothes, 2 in casual streetwear) for realistic continuity.

---

## 🎥 4. MiniMax H3 Video Prompting Rules

MiniMax H3 is a multimodal video model that requires precise syntax for motion, speech, and composition retention.

### Pick the format by mode first (CRITICAL)
H3 has two prompt formats, and the mode decides which one. MiniMax's official guides are bundled: read the matching one before writing.

| Mode | Inputs | Format | Guide |
|---|---|---|---|
| T2VA | text only | 3 fields, no instruction line | `references/base-en.txt` |
| I2VA (image-to-video) | one start image | fixed first-frame line + 3 fields | `references/base-en.txt` |
| FL2VA (first + last frame) | start and end image | fixed alignment line + 3 fields | `references/base-en.txt` |
| Ref2VA (reference-to-video) | up to 9 images, 3 videos, 3 audio clips (identity, voice, lip-sync to a voiceover) | the 6-section structure in B below | `references/ref-en.txt` |

Base-mode skeleton (I2VA). The first line is fixed text, then one blank line:

```text
For the target video, at 0.00 seconds into the target video, <Picture 1> (from [Shot 1]) is fully referenced.

integrated_multimodal_description: [Shot 1] Live-action, raw handheld smartphone selfie aesthetic, beginning exactly from <Picture 1>: [subject, outfit, setting anchors from the image]. [Action onset, continuous development, result.] She (S1) says: <d>[English] [line] </d>
[Shot 2] At 00:03.000, the camera cuts to ...

overall_soundscape: [ambient sound, physical action sounds, non-verbal human sounds, 1-4 sentences].

non_diegetic_music: N/A
```

The first shot has no timestamp; later shots start with `At MM:SS.mmm`. Give every voice a stable speaker ID such as `(S1)`. H3 samples with no negative prompt, so a banned element named in the prompt gets drawn: describe what is there instead ("the wall behind her is plain").

### A. The "NO Shot-Framing Words" Rule (CRITICAL GOTCHA)
* **DO NOT** use shot framing words like `medium shot`, `close-up`, `tight close-up`, `wide shot`, or `medium-close` when describing the shot that starts from `<Picture 1>` (the `summary`, `detailed_description`, or `[Shot 1]` line). Later cuts to a new angle may name their framing.
* **Why:** MiniMax treats framing words as zoom/re-crop commands, which distorts or crops your carefully generated starting image (`<Picture 1>`).
* **Correct Syntax:**
  * Standard: `a portrait of <Subject 1> as in <Picture 1>`
  * Selfie: `a selfie portrait of <Subject 1> as in <Picture 1>`
  * Environment: `a portrait of <Subject 1> standing in the kitchen as in <Picture 1>`

### B. The Ref2VA 6-Section Structure
Every reference-mode (Ref2VA) prompt MUST follow these 6 exact headers in order:

```text
subject_definitions:
<Subject 1> is the [character description from <Picture 1> including hair, outfit, accessories, and initial pose].
<Subject 2> is the [environment/background description from <Picture 1>].
<Audio 1> is the spoken voiceover audio track from [filename.mp3].

summary:
[reference generation] A [X]-second live-action video featuring <Subject 1> at <Subject 2>, speaking directly into the camera lens, synchronized with <Audio 1>.

retention_analysis:
<Subject 1> (appears in [Shot 1]): fully_preserved - facial features, hair, outfit, and pose retained from <Picture 1>.
<Subject 2> (appears in [Shot 1]): fully_preserved - background setting, furniture, and lighting retained from <Picture 1>.
<Audio 1> (appears in [Shot 1]): fully_preserved - vocal delivery, tone, and lip-sync precisely synchronized to the speech.

detailed_description:
Live-action, raw handheld smartphone selfie aesthetic under [lighting conditions]. Natural skin texture and pores with no airbrushing. Deep depth-of-field keeping subject and background in sharp focus. Subtle handheld micro-drift.
[Shot 1] At 00:00.000, a selfie portrait of <Subject 1> as in <Picture 1>. She maintains direct eye contact with the camera lens with [expression], her mouth moving in precise synchronization with <Audio 1> to deliver: <d>[English] [Spoken dialogue line here] </d> until 00:[XX].000.

overall_soundscape:
[Subtle ambient room tone/background sound] beneath the clear voice from <Audio 1>.

non_diegetic_music:
N/A
```

### C. Dialogue & Audio Sync Formatting
* **Dialogue Tags:** Wrap spoken dialogue in `<d>[Language] ... </d>` tags.
* **Audio Reference:** Declare `<Audio 1>` in `subject_definitions` and `retention_analysis` to enforce accurate lip-synchronization with your voiceover track.
* **Timestamps:** Every shot line must start with `At 00:00.000` and specify the end timestamp matching audio length (e.g., `until 00:05.000`).

### D. Safe Motions vs. Problematic Motions
* **Supported & Stable:** Direct eye contact with lens, natural talking/lip-sync, subtle smiles, nodding, head tilts, subtle body sway, gentle handheld float.
* **Avoid:** Sudden 180-degree head turns, rapid spinning, wildly waving hands in front of face, or complex multi-limb movements that cause AI hallucination or limb merging.

---

## ⏱️ 5. Typical Timing Guidelines

* **Flash Cuts / Punchy Words:** 1.0s – 2.0s
* **Short Phrases (2–5 words):** 2.5s – 4.0s
* **Standard Sentences:** 4.0s – 6.0s
* **Long Multi-phrase Sentences:** 6.0s – 8.0s

---

## 📦 6. Dual-Format Standard Output

For every completed scene, always provide both:
1. **Unified Video Prompt:** Full multi-shot continuous scene render covering all dialogue lines in one timeline.
2. **Single-Shot Video Prompts:** Modular individual prompts (Shot 1, Shot 2, etc.) mapped directly 1:1 to each specific generated image file (`1.png`, `2.png`, etc.) for maximum control and stability.

---

## 🧩 7. LoRA Selection (local ComfyUI)

When the user gives a scene or prompt, recommend a LoRA stack alongside the prompt. The catalog of LoRAs installed on the pod, with filenames, triggers, strengths, and stacking rules, is [`loras.md`](loras.md).

1. **Tag the concepts** in the request: nudity level, each sex act or body detail, camera move, motion intensity, audio (moans, speech), look (digicam, cinematic, photoreal).
2. **Map each concept to one catalog row.** Use the role order in `loras.md`: at most one NSFW base unlock, then act LoRAs, then detail, motion, and look LoRAs.
3. **Match the mode.** Take the fl2va file for I2VA / FL2VA / T2VA and the ref2va file for Ref2VA when the catalog lists both.
4. **Apply the stacking rules** in `loras.md` (total-weight budget, one turbo LoRA at most, lower strengths when stacked).
5. **Write trigger words into the prompt** at the point the concept appears.

Done when every concept tagged in step 1 is covered by a stack row or named as uncovered, and the output carries a stack table next to the prompt:

| LoRA file | Strength | Why |
|---|---|---|
| `MysticXXX_MMH3-V4.safetensors` | 0.8 | base NSFW anatomy |

