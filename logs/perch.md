# Perch

## 2026-10-02: WorkOS staging env

- **Why:** Perch auth (#242) moves to WorkOS AuthKit (Rai's go, 2 Oct). The Perch Service on nimbus needs the staging client ID and API key.
- **What:** added `private_dot_perch/private_private/private_workos.env.tmpl`, rendering `~/.perch/private/workos.env` (mode 600) from the 1Password item "WorkOS Perch Test API Key" (username = client ID, credential = API key). The vault is assumed `Private`; adjust if the item lives elsewhere.
- **Not applied yet:** Rai applies it next time he's on nimbus with a 1Password session. Until then, a hand-written copy exists at that path. Lancelot and latios need no secret (the client ID is public, baked into the Unity build).
