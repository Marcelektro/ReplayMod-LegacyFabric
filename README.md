# ReplayMod for Fabric (1.8.9)

A set of patches that make [ReplayMod](https://github.com/ReplayMod/ReplayMod) work on Fabric-style loaders for
Minecraft 1.8.9, specifically on [Ornithe](https://ornithemc.net), which is what Polyfrost's [OneClient](https://polyfrost.org/projects/oneclient) uses for 1.8.9.

The Fabric target is compiled against Legacy Fabric's mappings, see [below](#how-the-jar-is-built), but the jar that
comes out is made for Ornithe and does not need Legacy Fabric or any other loader API.

## Project state

**Status: working prototype.** 

The build produces a jar (`*-ornithe.jar`) which records, saves and
plays back replays in a OneClient 1.8.9 instance (Ornithe, Fabric Loader 0.20.1, Java 25, with OneClient's own mods).

It is listed in OneConfig and adds a button to OneClient's main menu.
See [Progress](#progress) and [Known gaps](#known-gaps).

This is not a fork. Like Paper does for Spigot, this repository only contains patches that are applied
on top of a pinned upstream revision (see `upstream.conf`). Upstream is not redistributed.

## Using it

Download the latest `ReplayMod-*-1.8.9-ornithe.jar` from the [Releases](../../releases) page and put it into
the `mods` folder of an Ornithe 1.8.9 instance (e.g. OneClient's mods folder).

To build it yourself, see [Workflow](#workflow); the jar ends up in
`versions/1.8.9-fabric/build/libs/*-ornithe.jar`.

## Releases

Pushing a tag like `v2.6.28-1` (upstream ReplayMod version, then our own revision) makes GitHub Actions
(`.github/workflows/build.yml`) apply the patches, build the jar with that version and publish a GitHub Release
with the jar and an SHA-256 file. 
Pushes to `main` and pull requests are only built, and the jar is attached to the workflow run.

## Layout

| Path                 | Contents                                                            |
|----------------------|---------------------------------------------------------------------|
| `upstream.conf`      | Upstream URL and the pinned commit the patches apply to             |
| `patches/replaymod/` | Patch series for the ReplayMod repository                           |
| `patches/jgui/`      | Patch series for the `jGui` submodule                               |
| `scripts/apply.sh`   | Checks out upstream into the work directory and applies all patches |
| `scripts/rebuild.sh` | Writes commits made in the work directory back into `patches/`      |

## How the jar is built

Loom can build against Legacy Fabric's mappings for 1.8.9 but not (yet) against Ornithe's. 

So the mod is compiled and remapped with Legacy Fabric's, and the final step 
(`tools/OrnitheRetarget.java`, run by the `ornitheJar` task) translates the jar to Ornithe's names. 

Both sets of mappings derive from the same obfuscated names, which makes that a mechanical
translation of classes, members, Mixin refmaps, the access widener and Mixin target strings.

`./gradlew :1.8.9-fabric:build` leaves the result in `versions/1.8.9-fabric/build/libs/*-ornithe.jar`. The other jars
in that folder use Legacy Fabric's names and are only intermediate. (`runClient` also runs with Legacy Fabric's names,
so test the final jar in an Ornithe instance.)

## Workflow

Requirements: `git`, `bash`, and JDKs for Gradle (21 works). 

Builds are heavy (several GB of Gradle/Minecraft caches); set `WORK_DIR` and `GRADLE_USER_HOME` to a RAM disk if you want to spare your SSD.

```sh
scripts/apply.sh                 # creates ./work (override with WORK_DIR=...)
cd work
./gradlew :1.8.9-fabric:build    # builds the Ornithe jar
# ... edit, then commit inside work/ (and inside work/jGui for jGui changes)
cd .. && scripts/rebuild.sh      # turns your commits into patches
```

`apply.sh` refuses to run if the work directory has changes that were not written back with
`rebuild.sh`; pass `--force` to discard them.

To move to a newer upstream: change `UPSTREAM_COMMIT`, run `scripts/apply.sh`, resolve any conflicts
(`git am --continue` in the work directory), then run `scripts/rebuild.sh`.

## Progress

- [x] Patch tooling (`apply.sh` / `rebuild.sh`)
- [x] Stock 1.8.9 Forge target builds (needs a one-line mapping fix, patch 0001)
- [x] `1.8.9-fabric` project: Legacy Fabric yarn + intermediary, access widener
- [x] jGui: screen, input, tick and HUD callbacks driven from Mixins instead of Forge events
- [x] ReplayMod compiles for Fabric on 1.8.9; the other targets (Forge 1.8.9/1.12.2, Fabric 1.14.4/1.16.1) still compile
- [x] Fabric entrypoint, `fabric.mod.json`, settings, key bindings (without any loader API)
- [x] Ornithe retargeting of the jar as part of the build
- [x] Listed in OneConfig/OneClient's mod list with buttons for the Replay Viewer and ReplayMod's settings
- [x] Button on OneClient's main menu (which is not a vanilla screen)
- [x] Tested in a OneClient 1.8.9 instance: "Record Singleplayer", recording, saving the `.mcpr`, Replay Viewer,
  loading a replay, replay overlay, camera movement and speed (scroll wheel), seeking forwards and backwards,
  exiting the replay
- [x] Test video rendering (needs FFmpeg), keyframes/paths and the camera roll
- [x] Release builds (clean version string, CI)

## Known gaps

- Forge-only compat code is disabled: ShadersMod/OptiFine hooks, MapWriter, BetterSprinting, Orange's 1.7 animations.
- No Mod Menu integration, and servers are not told that the client understands ReplayMod's restrictions channel.
- The FML handshake handling used for recording on Forge servers does not exist here.
- Camera roll, hiding of the camera entity and the HUD hooks are new Mixins (`MixinLegacy*`) that have only been
  exercised by the tests above.
- Only OneConfig is used to list the mod in OneClient; ReplayMod's own settings still live in its own screen, which
  the OneConfig entry opens, rather than being mirrored into OneConfig.
- Local builds still get a version ending in `-dirty` (the jGui submodule is moved off upstream's pinned commit); set
  `REPLAYMOD_VERSION=...` to override it, as the release workflow does.
- Netty may log `LEAK: ByteBuf.release() was not called` around seeking. In a minimal setup without OneClient's mods
  a ViaVersion error from ReplayStudio's bundled copy was also logged while loading a replay; neither had an
  effect in testing.
- Vanilla 1.8.9 consumes the buffer of custom payload packets when they are written, which Forge patches; a Mixin
  does that here, since recording otherwise breaks the server brand packet.
- The mod's jGui assets are found through the mod jar; the development fallback is only for `runClient`.

## License

ReplayMod is licensed under GPL-3.0-or-later and so are these patches. See `LICENSE.md`.

## Contact

If you have any questions, feel free to ask me on [my Discord server](https://marcloud.net/discord)! ^^
