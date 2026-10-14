# 🎬 Scene [X]: [Scene Title]

**Setting & Location:** [e.g. Modern living room / Coffee shop / Studio]  
**Wardrobe & Look:** [e.g. Casual olive hoodie / Chic business casual / Workout gear]  
**Camera Style:** [e.g. Handheld front-facing smartphone selfie / Candid third-person]  

---

## 🎙️ Spoken Dialogue (Locked)

> *"[Insert spoken dialogue sentence here]"*

---

## 📸 Image Prompts (Flux)

### **Hero Prompt (With Reference):**
```text
Use @image1 @image2 @image3 as the main identity reference. Preserve recognizable facial features, bone structure, eye colour, skin tone, natural facial proportions, and [insert hair cut, color, and style].

Raw handheld smartphone selfie of a [young woman / young man] [describe pose/action, e.g. sitting comfortably on a couch]. They look directly into the front-facing camera lens with an [expression, e.g. engaging, warm, confident conversational expression].

They feature natural skin texture with visible pores, authentic micro-texture, and true skin grain, wearing [insert outfit details] and accessorized with [insert accessories].

The background shows [insert detailed environment/room description]. Deep depth-of-field with subject and background both kept in sharp focus, crisp background detail, no artificial portrait mode blur. No digital airbrushing, true-to-life color science. [Insert natural lighting description], slight wide-angle barrel distortion from front-facing smartphone lens, 16:9 aspect ratio.
```

### **Hero Prompt (Standalone / Direct):**
```text
Raw handheld smartphone selfie of a [young woman / young man] [describe pose/action]. They look directly into the front-facing camera lens with an [expression].

They feature [insert hair description], [skin tone], natural skin texture with visible pores, authentic micro-texture, and true skin grain, wearing [insert outfit details] and accessorized with [insert accessories].

The background shows [insert detailed environment description]. Deep depth-of-field with subject and background both kept in sharp focus, crisp background detail, no artificial portrait mode blur. No digital airbrushing, true-to-life color science. [Insert lighting description], slight wide-angle barrel distortion from front-facing smartphone lens, 16:9 aspect ratio.
```

---

## 🎥 MiniMax H3 Video Prompt

*(REMINDER: Do NOT use shot-framing words like "medium shot" or "close-up" in summary or detailed_description to prevent unwanted zoom/cropping).*

```text
subject_definitions:
<Subject 1> is the person from <Picture 1>, featuring [brief physical recap: hair, skin, outfit, and initial pose from image].
<Subject 2> is the [environment/background description from <Picture 1>].
<Audio 1> is the spoken voiceover audio track from [audio_file.mp3].

summary:
[reference generation] A [X]-second live-action video featuring <Subject 1> at <Subject 2>, speaking directly into the smartphone camera lens, synchronized with <Audio 1>.

retention_analysis:
<Subject 1> (appears in [Shot 1]): fully_preserved - facial features, hair, outfit, and selfie pose retained from <Picture 1>.
<Subject 2> (appears in [Shot 1]): fully_preserved - background setting, furniture, and lighting retained from <Picture 1>.
<Audio 1> (appears in [Shot 1]): fully_preserved - vocal delivery, tone, and lip-sync precisely synchronized to the speech.

detailed_description:
Live-action, raw handheld smartphone selfie video aesthetic under [lighting description]. Visible skin texture and pores with no airbrushing. Deep depth-of-field keeping subject and background in sharp focus. Subtle handheld micro-drift.
[Shot 1] At 00:00.000, a selfie portrait of <Subject 1> as in <Picture 1>. She maintains direct eye contact with the camera lens with [expression], her mouth moving in precise synchronization with <Audio 1> to deliver: <d>[English] [Insert exact dialogue line] </d> until 00:[XX].000.

overall_soundscape:
[Subtle ambient room tone/background sound] beneath the clear voice from <Audio 1>.

non_diegetic_music:
N/A
```
