---
title: "Bobo Particles"
---
# Bobo Particle Simulator
[Bobo Particle Accelerator](https://oddcomputer.com/math/bobo.html)

Deterministic particle motion simulator.

Has more in common with Conway's Life than it does with a gravity sim.

Particles are only influenced by the closest particle to them at the beginning of each turn.

Two particle types: nearest and bobo
*nearest - these receive an acceleration of -1, 0, or 1 in each of the x and y directions each turn, depending on closest neighbor.
*bobo - do not move, on influence passing 'nearest' particles.
