---
type: product
status: defined-domain
owner: product
updated: 2026-09-19
---

# Product Brief

## Problem hypothesis

Lighting control can force users to choose between limited, approachable tools and powerful systems with steep learning curves. Setup, fixture configuration, programming, and live recovery create friction that distracts from the desired visual result.

## Product hypothesis

A software-first DMX controller can combine a visual, learnable workflow with the predictability required for live use. The product should help a user progress from connected fixtures to a controllable look quickly, while keeping addressing, output, and transitions inspectable.

## Confirmed product scope

Venue Volume is a React-based SaaS DMX/Art-Net controller. A project is called a **show**. A show owns multiple configuration templates, each containing a saved CAD drawing and inventory covering lighting fixtures and other production equipment. It also owns venues, reusable DMX presets, cues, and scripts.

A venue can start from a configuration template and adapt it locally. Presets reduce repetitive fixture programming. Cues represent moments/states and assign presets and other configuration to the venue's fixtures. Scripts define the expected cue sequence. Show-level defaults apply unless a venue overrides them.

The full application contracts are in [[Features/Feature Catalog]]. [[Design/Screen Inventory]] maps 35 proposed screens to those contracts, and [[Design/Interaction Coverage]] records the limits of the interactive mockups.

## Confirmed live operating direction

A touch-oriented detached lighting desk provides fixture/group/venue adjustment, cue/script transport, song restart, inspectable targets, MIDI-triggered calls, and synchronized venue editing without reload. Pre-programming, programming, and live are distinct colored workflows. See [[Features/F16 - Workflow modes and live programmer]], [[Features/F17 - Script transport and MIDI triggers]], and [[Features/F18 - Persistent console and live updates]].

## Candidate users

These are research segments, not yet chosen markets:

- Operators in small and midsize music venues
- Musicians and touring acts without a dedicated lighting programmer
- Houses of worship and community theaters
- Mobile event and production teams
- Lighting enthusiasts and small installations

## Candidate jobs

- Discover or define fixtures and patch them correctly.
- Build a useful look quickly.
- Create scenes, cues, chases, and parameter effects.
- Run a show confidently from mouse, keyboard, touch, MIDI, or other control surfaces.
- Understand output state and recover safely from device or network failures.
- Reuse a show when the fixture inventory or venue changes.

## Initial product principles

- **Live safety first:** destructive or surprising output changes require clear intent.
- **Visible state:** the user can understand what is currently driving each parameter.
- **Fast path, deep model:** common workflows are direct without hiding essential lighting concepts.
- **Hardware independence:** the show model is not needlessly coupled to one interface.
- **Graceful degradation:** disconnects and partial failures are clear and recoverable.
- **Interoperability:** established protocols and portable data are preferred where practical.

## Non-goals for the first prototype

- Replacing full-scale touring consoles
- Supporting every fixture or protocol
- Production authentication, collaboration, or billing in the design prototype (their intended SaaS surfaces and requirements are documented)
- Marketplace and enterprise administration beyond basic workspace/show access
- Pixel mapping and media-server functionality unless research identifies them as the wedge

## Success evidence for R&D

- A target user can connect, patch, and control a representative rig with minimal assistance.
- Output timing and failure behavior meet a documented threshold on selected hardware.
- Users can build and run a short show faster or with fewer errors than their current workflow.
- The team can represent representative fixtures without repeated schema changes.

## Related

- [[User Research Plan]]
- [[Features/Feature Catalog]]
- [[Design/Design Overview]]
- [[../03 Engineering/Domain Model|Domain model]]
- [[../03 Engineering/System Context|System context]]
- [[../04 Research/R&D Backlog|R&D backlog]]
