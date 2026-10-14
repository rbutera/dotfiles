# Local ComfyUI setup (comfyui-runner pod, `minimax-h3` manifest)

The `comfyui-runner` repo deploys a RunPod RTX 5090 with everything below. The ComfyUI MCP server (`comfyui`, registered in that repo's `.mcp.json`) can submit workflows, upload start images, and fetch outputs.

## Workflows on the pod

- `MiniMax-H3-Nexus-V1.1`: all-in-one H3 video. Four modules (T2V, single-image I2V, first/last frame, reference-to-video); turn on one with the green group bypasser. Defaults: 8 steps with the official 8-step turbo LoRA, 24 fps, duration in seconds (max 15). Its LoRA stack node has four slots.
- `Flux2-Klein9B-SNOFS-Edit`: FLUX.2 klein 9B (SNOFS merge) image edit with one or two reference images.
- Templates shipped by the node packs (Workflow > Browse Templates): ComfyUI-MiniMax-H3-Edit (`H3_Edit_Mixed_References`, character sheets) and MiniMax H3 Image Studio (`H3_GENERATE`, `H3_EDIT`).
- ComfyUI's official templates (`video_minimax_h3_i2v`, `video_minimax_h3_r2v`, ...) expect the official checkpoint filenames: swap the loaders to the files below.

## MiniMax H3 (video + audio)

- **Checkpoint:** `DasiwaMinimaxH3_HybridV4_int8.safetensors`. Hybrid: works in both fl2va (image-to-video, first/last frame, text-to-video) and ref2va (reference-to-video) workflows.
- **Text encoder:** `qwen3vl_32b_minimax_h3_nvfp4_awq.safetensors` (CLIPLoader type `minimax`). **VAEs:** `minimax_h3_video_vae_fp16` (or `_int8_convrot`), `minimax_h3_audio_vae_fp32`.
- **Without turbo:** 20-25 steps, res_multistep or euler, simple scheduler, shift video 10-12 / audio 3-5.
- **With one turbo LoRA:** 4 or 8 steps, euler or lcm, simple, shift video 6-12 / audio 3-5. Speech needs at least 12 steps to converge.
- **CFG:** 1 through BasicGuider. There is no negative prompt.
- **Resolution:** native 1344x768 (16:9, 768 short edge), multiples of 32. Avoid exactly 1.0 MP. Drafts at 864x480 run much faster.
- **Length:** frames at 24 fps on a 17k+5 grid. 124 frames is about 5 s; the trained range runs to about 362 frames (15 s).
- `MiniMaxH3MemoryEfficientSageAttentionPatch` (KJNodes) is bypassed in the Nexus workflow: it breaks on the 5090 with the installed sageattention.

## FLUX.2 klein 9B + SNOFS (start frames and image edits)

- **Files:** `snofs_v14_klein9b_distilled_fp8.safetensors` (UNETLoader), `qwen_3_8b_fp8mixed.safetensors` (CLIPLoader type `flux2`), `full_encoder_small_decoder.safetensors` (VAE).
- **Settings (distilled):** 4 steps, CFG 1, euler, Flux2Scheduler, about 1 MP. Editing attaches each reference image through a `ReferenceLatent` node.
- **Prompting:** SNOFS was trained on full natural-language sentences, not tags. Describe states ("her panties are pulled down to her thighs") rather than tag phrases ("panty pull"). Terms that work: boudoir, braless, sheer, wet clothes, undressing, hand in panties, selfie / mirror selfie, snapchat caption, ipcam / nightvision ipcam, massage, missionary / cowgirl / reverse cowgirl / doggystyle / prone / spooning position, blowjob, deepthroat, handjob, cunnilingus, fingering, masturbating, dildo, strap-on dildo, hitachi magic wand, cum, condoms, pregnant (with trimester).
- **Gotcha:** close-up skin can get a texture artifact. The author's fix is "goosebumps" in the negative prompt, which needs CFG above 1 and a real negative text encode (the template zeroes the negative at CFG 1).
- Klein edits are weak at changing face angle or expression.

## H3 still images (the "H3 edit" approach)

H3 is a video model; these packs pull a single image out of it, so start frames match H3's own look.

- **ComfyUI-MiniMax-H3-Edit:** samples a short clip (5 frames by default) and keeps the sharpest, most stable frame. Edit and semantic-generate roles use fl2va; native-reference generate uses ref2va. The hybrid checkpoint should cover both (unverified by the pack's author).
- **MiniMax H3 Image Studio:** samples one latent frame through a dedicated still decoder (`H3ImageToImagePrepare`, `H3ReferenceEditPrepare`). Defaults: 3 MP, 50 steps, er_sde/simple. Turbo recipe: `minimax_h3_turbo_v4_step600_ema_pruned_comfyui` at 0.38, 20 steps.
- Pair either pack with `h3_photoreal_ph0t0r34l_1024-step00003990` (trigger `ph0t0r34l`) for photoreal stills. Both packs call themselves experimental.
