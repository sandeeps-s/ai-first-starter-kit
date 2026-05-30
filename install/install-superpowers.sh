#!/usr/bin/env bash
set -euo pipefail

# ----------------------------------------------------------------------------
# Install superpowers, PINNED, for governed team use.
#
# Two paths. Pick ONE and record the result in PROVENANCE.md.
# Verify the current install mechanics against the superpowers README before running —
# this ecosystem changes monthly.
# ----------------------------------------------------------------------------

# --- Path A: quick (Claude Code plugin marketplace) -------------------------
# Convenient, but tracks the marketplace's latest. Less control over version.
# Run this INSIDE a Claude Code session, not in this shell:
#
#   /plugin install superpowers@claude-plugins-official
#
# Use Path A only for spikes/experiments, not governed client work.

# --- Path B: governed (vendored + pinned submodule) -------------------------
# Recommended for client engagements. Pins to an exact commit/tag so an upstream
# change can't silently alter agent behavior mid-delivery.

PIN="${SUPERPOWERS_PIN:-}"   # set to a tag or commit SHA, e.g. v1.4.0 or a40c9f2
VENDOR_DIR="vendor/superpowers"

if [[ -z "$PIN" ]]; then
  echo "ERROR: set SUPERPOWERS_PIN to a tag or commit SHA before running."
  echo "  e.g.  SUPERPOWERS_PIN=v1.4.0 ./install/install-superpowers.sh"
  exit 1
fi

echo ">> Vendoring superpowers as a pinned submodule at $VENDOR_DIR (pin: $PIN)"
git submodule add https://github.com/obra/superpowers "$VENDOR_DIR" 2>/dev/null || true
git -C "$VENDOR_DIR" fetch --tags --quiet
git -C "$VENDOR_DIR" checkout --quiet "$PIN"
git submodule update --init --recursive

echo ">> Pinned. Now record this in PROVENANCE.md:"
echo "   superpowers | $(git -C "$VENDOR_DIR" rev-parse --short HEAD) | $PIN | workflow engine"
echo ">> Point Claude Code at the vendored skills (see ADOPTION.md) and commit the submodule."
