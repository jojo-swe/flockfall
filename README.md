# Flockfall — Playable Godot Prototype

A buildable vertical-slice prototype combining a slingshot projectile, Peggle-like ricochets, and a deterministic match-3 cascade board.

## Requirements

- Godot 4.3 or newer
- No third-party add-ons
- No external art or sound assets required

## Run

1. Clone or download this repository.
2. Open Godot.
3. Choose **Import**.
4. Select `project.godot`.
5. Press **F6/F5** or click **Run Project**.

## Controls

- Mouse or touch: drag the bird backward from the sling.
- Release: fire.
- The landing column is chosen from the bird's horizontal position when it reaches the board.

## Implemented

- Portrait mobile layout at 720 × 1280
- Touch and mouse input
- Slingshot aiming and trajectory preview
- RigidBody2D projectile with bouncy pegs
- Four bird/block colors
- Logical 8 × 6 match-3 board
- Horizontal and vertical matching
- Multi-step cascades and combo scoring
- Screen shake, squash/stretch, particles, and score feedback
- Twenty-shot prototype round and restart flow

## Architecture

- `scripts/game.gd` — game loop, input, scoring, UI, and effects
- `scripts/bird.gd` — physical projectile
- `scripts/peg.gd` — static bounce bumper
- `scripts/grid_controller.gd` — deterministic board state and cascade resolver
- `scripts/block.gd` — animated block view
- `scenes/main.tscn` — main scene

The board deliberately uses logical cells and tweens instead of rigid-body blocks. This gives deterministic puzzle behavior and stable mobile performance while the bird and impact effects provide the physical spectacle.

## Status

This repository now contains the complete first playable prototype, not merely a design document. It still needs hands-on testing in Godot and balancing on a real Android device.
