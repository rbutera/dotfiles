# 📋 MiniMax & Flux Baseline Reference Prompts

Production-tested reference templates for Image Generation (Flux) and Video Generation (MiniMax H3). Use these templates as the foundation for any new scene.

---

## 1. Baseline Image Prompt — With Reference Image (Flux)

*Use this when referencing existing character images (@image1 @image2 @image3) to maintain face and identity consistency.*

```text
Use @image1 @image2 @image3 as the main identity reference. Preserve recognizable facial features, bone structure, eye colour, skin tone, natural facial proportions, and [insert hair style, length, and color].

Raw handheld smartphone selfie of a [young woman / young man] [action or posture, e.g., sitting relaxed on a sofa / standing in a modern cafe]. They look directly into the front-facing camera lens with an [expression, e.g., engaging, confident, warm conversational expression].

They feature natural skin texture with visible pores, authentic micro-texture, and true skin grain, wearing [insert outfit details] and accessorized with [insert jewelry or accessories].

The background shows [insert detailed environment/location description]. Deep depth-of-field with subject and background both kept in sharp focus, crisp background detail, no artificial portrait mode blur. No digital airbrushing, true-to-life color science. [Insert lighting description], slight wide-angle barrel distortion from front-facing smartphone lens, 16:9 aspect ratio.
```

---

## 2. Baseline Image Prompt — Standalone (No Reference)

*Use this when creating a fresh character from scratch.*

```text
Raw handheld smartphone selfie of a [young woman / young man] [action or posture, e.g., sitting relaxed on a sofa / standing in a modern kitchen]. They look directly into the front-facing camera lens with an [expression, e.g., engaging, friendly, confident conversational expression].

They feature [insert distinct hair description: color, cut, texture], [skin tone description], natural skin texture with visible pores, authentic micro-texture, and true skin grain, wearing [insert outfit details] and accessorized with [insert accessories].

The background shows [insert detailed environment/location description]. Deep depth-of-field with subject and background both kept in sharp focus, crisp background detail, no artificial portrait mode blur. No digital airbrushing, true-to-life color science. [Insert lighting description], slight wide-angle barrel distortion from front-facing smartphone lens, 16:9 aspect ratio.
```

---

## 3. Baseline MiniMax H3 Video Prompt — Single Shot (With Spoken Audio / Lip-Sync)

*Use when pairing a generated starting image (`<Picture 1>`) with a pre-recorded voiceover audio file (`<Audio 1>`).*

```text
subject_definitions:
<Subject 1> is the person from <Picture 1>, featuring [brief physical recap: hair, skin, outfit, and initial pose from image].
<Subject 2> is the [environment/background description from <Picture 1>].
<Audio 1> is the spoken voiceover audio track from [audio_file.mp3].

summary:
[reference generation] A [X]-second live-action video featuring <Subject 1> at <Subject 2>, speaking directly into the smartphone camera lens, synchronized with <Audio 1>.

retention_analysis:
<Subject 1> (appears in [Shot 1]): fully_preserved - facial features, hair, outfit, and initial pose retained from <Picture 1>.
<Subject 2> (appears in [Shot 1]): fully_preserved - background setting, furniture, and lighting retained from <Picture 1>.
<Audio 1> (appears in [Shot 1]): fully_preserved - vocal delivery, tone, and lip-sync precisely synchronized to the speech.

detailed_description:
Live-action, raw handheld smartphone selfie video aesthetic under [lighting description]. Visible skin texture and pores with no airbrushing. Deep depth-of-field keeping subject and background in sharp focus. Subtle, natural handheld micro-drift.
[Shot 1] At 00:00.000, a selfie portrait of <Subject 1> as in <Picture 1>. She maintains direct eye contact with the camera lens with [expression], her mouth moving in precise synchronization with <Audio 1> to deliver: <d>[English] [Insert exact spoken dialogue line] </d> until 00:[XX].000.

overall_soundscape:
[Subtle background ambient sound] beneath the clear voice from <Audio 1>.

non_diegetic_music:
N/A
```

---

## 4. Baseline MiniMax H3 Video Prompt — Direct Generation (Without External Audio File)

*Use when generating video with native MiniMax speech/lip-sync directly from the text prompt.*

```text
subject_definitions:
<Subject 1> is the person from <Picture 1>, featuring [brief physical recap: hair, skin, outfit, and initial pose from image].
<Subject 2> is the [environment/background description from <Picture 1>].

summary:
[reference generation] A [X]-second live-action video featuring <Subject 1> at <Subject 2>, speaking directly into the smartphone selfie camera lens with natural motion.

retention_analysis:
<Subject 1> (appears in [Shot 1]): fully_preserved - facial features, hair, outfit, and pose retained from <Picture 1>.
<Subject 2> (appears in [Shot 1]): fully_preserved - background setting and lighting retained from <Picture 1>.

detailed_description:
Live-action, realistic handheld smartphone selfie video under [lighting description]. Visible authentic skin grain and pores with no airbrushing. Deep depth-of-field with background kept in crisp focus. Gentle handheld camera float.
[Shot 1] At 00:00.000, a selfie portrait of <Subject 1> as in <Picture 1>. She looks directly into the smartphone camera lens with [expression], speaking with natural lip movements: <d>[English] [Insert exact spoken dialogue line] </d> until 00:[XX].000.

overall_soundscape:
[Describe ambient room tone and environmental sounds].

non_diegetic_music:
N/A
```

---

## 5. Baseline MiniMax H3 Video Prompt — Multi-Shot / Jump Cuts (Unified)

*Use when animating multiple cuts across images (`<Picture 1>`, `<Picture 2>`) in one continuous timeline.*

```text
subject_definitions:
<Subject 1> is the person from <Picture 1> and <Picture 2>, featuring [consistent physical appearance and wardrobe].
<Subject 2> is the [setting/location description from references].
<Audio 1> is the full continuous voiceover audio track.

summary:
[reference generation] A [X]-second live-action video featuring <Subject 1> at <Subject 2>, delivering dialogue across fast jump cuts, looking directly into the camera lens.

retention_analysis:
<Subject 1> (appears in [Shot 1], [Shot 2]): fully_preserved - facial features, hair, and outfit retained from <Picture 1> and <Picture 2>.
<Subject 2> (appears in [Shot 1], [Shot 2]): fully_preserved - environment and lighting retained from <Picture 1> and <Picture 2>.
<Audio 1> (appears in [Shot 1], [Shot 2]): fully_preserved - vocal delivery and lip-sync across all cuts synchronized with <Audio 1>.

detailed_description:
Live-action, raw handheld smartphone vlog aesthetic under natural lighting. Deep depth-of-field with background kept crisp. Organic handheld camera motion.
[Shot 1] At 00:00.000, a selfie portrait of <Subject 1> as in <Picture 1>. She looks into the camera lens and delivers: <d>[English] [First line of speech] </d> until 00:[XX].000.
[Shot 2] At 00:[XX].000, fast jump-cut to a selfie portrait of <Subject 1> as in <Picture 2>. She maintains direct eye contact and delivers: <d>[English] [Second line of speech] </d> until 00:[XX].000.

overall_soundscape:
Natural room tone and ambient background beneath the dialogue track from <Audio 1>.

non_diegetic_music:
N/A
```
