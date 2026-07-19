## 2026-07-19

**Problem/motivation:** Chaching's nightly history refresh existed only as a hand-installed, Kinto-specific launch agent, so Latios and Nimbus could not publish their local usage into the shared PostgreSQL pool.

**Changes:** Added a `chaching` host group for Kinto, Latios, and Nimbus, exported `CHACHING_DATABASE_URL` on those hosts from `op://dev/Neon Chaching Connection String/credential`, and added a portable macOS launch agent that resolves the globally installed Chaching CLI from each machine's managed toolchain paths and runs `chaching stats --no-art` nightly at 23:50.
