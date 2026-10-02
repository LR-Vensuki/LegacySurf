# Surf client core

An unchanged copy of `client/core` from [seg6/surf](https://github.com/seg6/surf):
the C99 library shared by Surf clients. It has no UI, network, TLS, decoder,
renderer, audio, filesystem, thread, or Rust dependency.

The core handles control events and commands, browser state, connection state,
input ordering, media admission, clock synchronization, and pipeline metrics.
Its JSON decoder uses a workspace supplied by the host. Decoded strings and
collections remain valid until that workspace is reused.

Public headers live under `include/surf`. Media parsers return borrowed views,
so the host retains ownership of the source buffer.

Legacy Surf compiles `src/*.c` straight into the app (see the Makefile). The
host tests and the CMake build stay upstream; when updating the core, take it
from the same upstream commit as `Classes/` and run its tests there.
