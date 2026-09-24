# unitySplat

A self-contained Unity 2022.3.72f1 Built-in Render Pipeline desktop demo. Open this folder as a Unity project in Unity Hub, open `Assets/Scenes/Demo.unity`, and press Play. The bundled 6,806-splat room loads automatically and places the camera at its center, 1.5 m above the floor. `File > Build Settings` already includes the demo scene for a desktop build. A Unity Editor installation is required; this repository cannot build or run the player with `dotnet` alone.

Controls: WASD moves, Q/E descends/ascends, Shift moves faster, mouse looks, R returns to the center, and Escape releases or captures the pointer. Right-click captures it again. The panel accepts an absolute `.ply` path. **Browse** uses the Editor file picker in Play mode or `zenity` in a Linux standalone player; the path field also works without `zenity`. **Demo** restores the bundled room. The slider changes scene scale.

The importer reads standard trained Gaussian PLY vertices in ASCII or binary little-endian format, with properties in any order. It requires `x/y/z`, `f_dc_0..2`, `opacity`, `scale_0..2`, and `rot_0..3`; normal and higher-order SH columns are ignored. SH DC is converted to RGB with `0.5 + 0.2820947918 * f_dc`, opacity uses sigmoid, and scales use `exp`. Rotations use normalized `wxyz`. The first PLY element must be `vertex`; trailing nonvertex elements are ignored. The demo limits input to 250,000 vertices and 1 GiB.

Each frame the CPU projects the full 3D Gaussian covariance through the perspective Jacobian, eigen-decomposes its screen ellipse, and sorts centers from back to front. The GPU blends quads with `exp(-r²/2)` alpha. This is a compact demonstration renderer: very large captures will be CPU and draw bandwidth limited; transparency is center-sorted rather than exact per-fragment order. Higher-order spherical harmonics, occlusion-aware depth tests against other geometry, collision, gravity, and walkable floor physics are not implemented. Movement is free flight. The bundled room was authored Y-up in metres; arbitrary trained captures may need a coordinate conversion before import.

The shared room is packaged as `Assets/Resources/demo-room.bytes` so Unity imports
it as a `TextAsset`; its contents remain an ordinary ASCII PLY. To refresh it,
copy `../../assets/splats/demo-room.ply` to that path.

Parser regression checks run without Unity using the .NET 10 SDK. From this directory:

```bash
DOTNET_CLI_HOME=/tmp/unitysplat-dotnet dotnet run --project ParserTests/ParserTests.csproj --configfile ParserTests/NuGet.Config
```

The renderer uses Unity's [`Mesh.SetVertices`](https://docs.unity3d.com/2022.3/Documentation/ScriptReference/Mesh.SetVertices.html) and [`Mesh.SetTriangles`](https://docs.unity3d.com/2022.3/Documentation/ScriptReference/Mesh.SetTriangles.html) slice APIs for a sorted dynamic mesh. Unity [2022.3.72f1 release](https://unity.com/releases/editor/whats-new/2022.3.72f1) pins the project version. No external Unity packages are required.
