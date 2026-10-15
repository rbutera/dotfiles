# H3 LoRA catalog (installed on the comfyui-runner pod)

Every file below is in `ComfyUI/models/loras/` on a pod booted with the `minimax-h3` manifest. That manifest (`comfyui-runner/manifests/minimax-h3.json`) is the source of truth for what is installed. To add a LoRA, add it there and restart the pod.

The checkpoint is DaSiWa Hybrid v4: a pruned build that loads both fl2va and ref2va LoRAs. Strengths are the authors' recommendations; "start" means the author gave none.

## Stacking rules

- **Budget:** keep the summed strength of unlock + act LoRAs around 2.0. Past that, anatomy and faces degrade. Sliders and VBVR are cheap and sit outside the budget.
- **One NSFW base unlock** (Mystic XXX, Unlocked V2, HMNSFW AIO, or SexGod). Two unlocks fight each other.
- **One turbo LoRA at most.** Turbo shifts the look, so drop other LoRAs by about 0.1-0.2 when one is on.
- **Mode files:** where a row lists an fl2va and a ref2va file, load the one matching the mode.
- **Try the base model alone first** before stacking. Add LoRAs for concepts it gets wrong.

## 1. NSFW base unlocks (pick one)

| File | Mode | Trigger | Strength | Use for |
|---|---|---|---|---|
| `MysticXXX_MMH3-V4.safetensors` / `MysticXXX_MMH3-V4-ref2va.safetensors` | fl2va / ref2va | none | 1.0 (0.2-1.0) | Default unlock. General nude anatomy for T2V, I2V, first/last frame. The ref2va file is experimental and not audio-trained. |
| `Minimax_H3_Unlocked_V2.safetensors` | fl2va | `nude`, `topless`, `bare breasts`, `naked` | 0.5 (0.3-1.0) | Solo or couple nudity with explicit genital detail from text. |
| `HMNSFW-AIO-V2.5.safetensors` | fl2va | none | 0.5-0.9 | All-in-one sex motion: penetration, oral, handjob, fingering, toys, cumshots. Best when the scene mixes several acts. |
| `SexGod_NaughtyTimes_v3_rank64_pruned_NOADALN.safetensors` | fl2va | none | 1.0 | Broad sex LoRA (pruned build, weaker than its unpruned original). Author tested euler/simple at 30-40 steps; turbo untested. |

## 2. Sex acts and body detail

| File | Mode | Trigger | Strength | Use for |
|---|---|---|---|---|
| `MISSIONLG_H3_v1.safetensors` | fl2va | `MISSIONLG` (optional) | 1.0 | Missionary with hip-grinding motion; four camera angles (side, beside her head, behind him, above). The start image must already show the couple in position. |
| `HMMisDogV1.5.safetensors` | fl2va | none | 1.0 (start) | Male-POV missionary and doggystyle. Shows the anus often, so steer that in the prompt. |
| `MM-H3_Blowjob_v3.safetensors` | fl2va (ref2va reported OK) | `bl0w_j0b` | 1.0 | Blowjob motion and anatomy. |
| `HMCumshot_V1.0.safetensors` | fl2va | none | 0.7 (0.9 on ref2va) | Ejaculation, cum travel and texture. Describe the sound explicitly or the audio comes out loud. |
| `hmmasturbation_v2.safetensors` | fl2va | none | 1.0 (start) | Female solo masturbation, fingering, squirting. Pair with HMPussy at 0.4-0.8. |
| `HMPussy_minimax-h3_epoch20.safetensors` | fl2va | `pussy` | 1.0 alone, 0.4-0.8 under a motion LoRA | Female genital and anus anatomy (shaved, hairy, innie...). Stills-trained, so also good for H3 start frames. |
| `breastplayjiggle_h3_v2.safetensors` | fl2va | none | 0.7-0.8 (lower on ref2va) | Hands on breasts: grabbing, squeezing, sucking, plus jiggle. 1.0 corrupts fingers. |
| `bounceV07_fl2va-000230_Intense.safetensors` | fl2va (works on ref2va) | `her breast is bouncing up and down` or `... from left to right` | 1.0 (start) | Natural breast bounce when walking, dancing, bending. |

## 3. Realism and look

| File | Mode | Trigger | Strength | Use for |
|---|---|---|---|---|
| `PlagueKind-tiddies-realismslider.safetensors` | any | none | 1.0-2.0 (breaks above 2.0) | Photorealism and breast/nipple detail. Outside the budget. |
| `DetailSlider-V1.safetensors` | any | none | -2 to 2 | Texture and small detail without changing composition. Outside the budget. |
| `minimax-h3-digicam.safetensors` | ref2va, T2V (not for I2V) | `d1g1cam` | 1.0 T2V, 1.2 ref2va | Y2K digicam: flash, noise, amateur realism. Stack with act LoRAs. |
| `MinimaxH3_cinematic_texture_DY.safetensors` | any | `DY` | 0.7 (0.5 for high motion) | Removes the plastic AI look: natural light, skin texture. |
| `H3-Icy-real-v1_000004200.safetensors` | ref2va, T2V | `icyrealism` | 0.8 (start) | Candid social-media realism. Strongest for stills. |
| `h3_photoreal_ph0t0r34l_1024-step00003990.safetensors` | fl2va | `ph0t0r34l` | 1.0 (start) | Turns H3 into a photoreal still-image generator: use with the H3 still-image nodes. |

## 4. Motion and camera

| File | Mode | Trigger | Strength | Use for |
|---|---|---|---|---|
| `H3_Motion_BoosterV2.safetensors` / `ref2VA_Motion_v2.safetensors` | fl2va / ref2va | `dynv2` | 1.0 (start) | Harder impact, rebound, secondary body motion, contact sounds. Put moans in spoken lines, not the soundscape. |
| `h3_Better_NSFW_Motion_V1.safetensors` | ref2va | none | 0.9 | Smoother NSFW body motion. Trained on 3D animation, may push toward a 3D look. |
| `mvmt_h3_lora_v1_500.safetensors` | fl2va | none | 0.4-0.8 | More natural general human movement (SFW). Keep prompts short. |
| `BUNNY_Motion_Repair_V2.safetensors` | any | none | 0.8-1.0 (start) | Continuity repair for hard motion: spins, flips, dance. |
| `H3_VBVR_Pro_attn_only.safetensors` | any | none | 1.0 (0.5 when stacked) | Better prompt following and physical logic. Tiny, outside the budget. |
| `motion_speed_slider_mmh3_v1.1.safetensors` | any | none | 4 default (-8 to 8) | Positive = faster action, negative = slow motion. Below 4 does almost nothing. |
| `camera_motion_h3_lora_v1_3000_pruned.safetensors` | fl2va | `camera motion` (must start the prompt) | 0.8-1.0 | Push-in, pull-back, orbit, tracking, crane, pan. Unstable above 1.2. |

## 5. Audio

| File | Mode | Trigger | Strength | Use for |
|---|---|---|---|---|
| `moawxx_000002500.safetensors` | fl2va | `moawxx` | 0.6-0.85 | Female pleasure moans synced with writhing and trembling. Trained at 256px: high strength softens the image. |

## 6. Turbo (speed), one at a time

| File | Mode | Strength | Settings |
|---|---|---|---|
| `minimax_h3_fl2v_turbo_8step_v1.0_comfyui_bf16.safetensors` | fl2va | 1.0 | Official. 8 steps (the Nexus workflow default). |
| `minimax_h3_fl2v_turbo_4step_v1.0_768p_comfyui_bf16.safetensors` | fl2va | 1.0 | Official. 4 steps, tuned for 768p. |
| `minimax_h3_ref2v_turbo_4step_v0.1_comfyui_bf16.safetensors` | ref2va | 1.0 | Official preview. 4 steps. |
| `minimax_h3_PDMD_DMAD_4step_r256_add_fro1_turbo_lora.safetensors` | both | 1.0 | DaSiWa's own turbo, built for the hybrid checkpoint. euler, simple or beta, 4 steps. |
| `minimax_h3_dmad_full_dareties_v4_step600_comfy_fro.safetensors` | both | 1.0 | DMAD + larryvrh merge, good audio. 6-8 steps, er_sde or lcm, simple. |
| `minimax_h3_turbo_v4_step600_ema_pruned_comfyui.safetensors` | both | 0.38 for stills | larryvrh v4. Image Studio's still-image turbo recipe at 20 steps. |

## 7. Style (painterly, semi-real, anime)

For a painted look, leave every section 3 realism LoRA off and describe the style in the prompt ("semi-realistic digital painting, visible brushwork, as in <Picture 1>") in place of the template's "Live-action, raw handheld smartphone" wording. NSFW act LoRAs were trained on real footage and pull toward photoreal as strength rises: start them about 0.2 lower. None of these were tested on the pod yet.

| File | Mode | Trigger | Strength | Use for |
|---|---|---|---|---|
| `Painterly_H3_cosmic_v1.safetensors` | fl2va (start) | none | 0.6-0.8 (start) | General painterly look. Author gave no notes. |
| `SabudenegoH3MiniMax_minimaxh3_3274992_epoch_7.safetensors` | fl2va (start) | `Erotic digital painting video that features` (opens the prompt) | 0.8 (start) | Explicit digital-painting hentai style (Shrekman). |
| `H3_Ref2V_Anime_Slider_v1.safetensors` | ref2va, T2V | none | -5 to 5; +3 = flat 2D anime, -3 = photoreal | Dial the style. Small positive values (+1 to +2) for semi-real. Outside the budget. |
| `H3_R16_2.5d_style_v2_000003500.safetensors` | fl2va (start) | none | 0.8 (start) | 2.5D illustrated look (Illustrious-style renders). |
| `minimax_h3_style_transfer_v1.0_r64.safetensors` | style-transfer workflow | `style_transfer:` | per workflow | Restyles an existing video to match a style image, keeping motion and timing. Use with the `MiniMax-H3-StyleTransfer` workflow: render the explicit clip first, then restyle it with a painted frame as the style reference. Doubles GPU time. |
