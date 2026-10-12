---
# hyai-flake-gth0
title: 02 Package the HostYourAI CLI
status: completed
type: milestone
priority: normal
created_at: 2026-10-12T16:30:33Z
updated_at: 2026-10-12T17:00:25Z
---

Turn the flake into something that installs the HostYourAI (hyai) CLI. Distribution form is not decided yet: prebuilt release artifact, source build, or a registry package. This milestone first establishes how hyai ships, then writes the derivation, pins a version and hash, and exposes it as packages.default and an overlay. Ends when 'nix run github:mipmip/hyai-flake' starts the CLI on x86_64-linux and aarch64-darwin.
