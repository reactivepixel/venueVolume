using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Threading.Tasks;
using UnityEngine;
using UnityEngine.Rendering;

namespace UnitySplat
{
    public sealed class SplatViewer : MonoBehaviour
    {
        const int MaxSplats = 250000;
        struct Visible { public int Index; public float Depth; }
        static readonly IComparer<Visible> BackToFront = Comparer<Visible>.Create((a, b) => b.Depth.CompareTo(a.Depth));
        Camera view;
        Mesh mesh;
        Material material;
        Gaussian[] splats = Array.Empty<Gaussian>();
        Vector3[] vertices = Array.Empty<Vector3>();
        Vector2[] uv = Array.Empty<Vector2>();
        Color[] colors = Array.Empty<Color>();
        int[] triangles = Array.Empty<int>();
        Visible[] order = Array.Empty<Visible>();
        string filePath = "";
        string status = "Loading bundled demo...";
        float progress;
        float sceneScale = 1f;
        Vector3 sceneOffset;
        Vector3 sceneCenter;
        float yaw, pitch;
        bool captured = true;
        float moveSpeed = 3.5f;
        bool loading;

        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]
        static void Bootstrap()
        {
            if (FindObjectOfType<SplatViewer>() != null) return;
            var go = new GameObject("Gaussian Splat Viewer");
            go.AddComponent<SplatViewer>();
        }

        void Awake()
        {
            view = Camera.main;
            if (view == null)
            {
                var cameraObject = new GameObject("Fly Camera");
                cameraObject.tag = "MainCamera";
                view = cameraObject.AddComponent<Camera>();
                cameraObject.AddComponent<AudioListener>();
            }
            view.clearFlags = CameraClearFlags.SolidColor;
            view.backgroundColor = new Color(.06f, .075f, .1f);
            view.nearClipPlane = .03f;
            view.farClipPlane = 500f;
            view.fieldOfView = 70f;
            var shader = Resources.Load<Shader>("Shaders/Gaussian");
            if (shader == null) { status = "Missing UnitySplat/Gaussian shader."; return; }
            material = new Material(shader);
            mesh = new Mesh { name = "Depth sorted Gaussian quads", indexFormat = IndexFormat.UInt32 };
            Cursor.lockState = CursorLockMode.Locked;
            Cursor.visible = false;
            LoadBundled();
        }

        void OnDestroy()
        {
            if (mesh != null) Destroy(mesh);
            if (material != null) Destroy(material);
            Cursor.lockState = CursorLockMode.None;
            Cursor.visible = true;
        }

        void LoadBundled()
        {
            var demo = Resources.Load<TextAsset>("demo-room");
            if (demo == null) { status = "Bundled demo-room.ply missing."; return; }
            try
            {
                using (var bytes = new MemoryStream(demo.bytes)) Install(GaussianPly.Read(bytes), "Bundled demo room");
            }
            catch (Exception ex) { status = "Demo load failed: " + ex.Message; }
        }

        async void LoadFile()
        {
            if (loading) return;
            loading = true;
            try
            {
                if (string.IsNullOrWhiteSpace(filePath)) throw new IOException("Choose a .ply file.");
                if (!File.Exists(filePath)) throw new FileNotFoundException("File not found", filePath);
                status = "Loading " + Path.GetFileName(filePath) + "...";
                progress = 0;
                string selected = filePath;
                Gaussian[] parsed = await Task.Run(() => GaussianPly.Read(selected, p => progress = p));
                if (this != null) Install(parsed, Path.GetFileName(selected));
            }
            catch (Exception ex) { status = "Load failed: " + ex.Message; }
            finally { loading = false; }
        }

        void Install(Gaussian[] next, string name)
        {
            if (next.Length > MaxSplats) throw new InvalidDataException("This CPU demo supports at most " + MaxSplats + " splats. Use a smaller PLY.");
            if (next.Length == 0) throw new InvalidDataException("PLY has no splats.");
            splats = next;
            vertices = new Vector3[next.Length * 4];
            uv = new Vector2[next.Length * 4];
            colors = new Color[next.Length * 4];
            triangles = new int[next.Length * 6];
            order = new Visible[next.Length];
            var min = new Vector3(float.MaxValue, float.MaxValue, float.MaxValue);
            var max = new Vector3(float.MinValue, float.MinValue, float.MinValue);
            foreach (var g in splats)
            {
                var p = new Vector3(g.X, g.Y, g.Z);
                min = Vector3.Min(min, p); max = Vector3.Max(max, p);
            }
            sceneCenter = (min + max) * .5f;
            sceneOffset = Vector3.zero;
            sceneScale = 1f;
            Recenter();
            status = name + ": " + next.Length.ToString("N0") + " splats";
            progress = 1;
        }

        void Recenter()
        {
            // Room fixture is authored with the viewer in its center. Other PLYs start at their bounds center.
            view.transform.position = sceneOffset + sceneCenter * sceneScale;
            yaw = 0; pitch = 0;
            view.transform.rotation = Quaternion.identity;
        }

        void Update()
        {
            if (Input.GetKeyDown(KeyCode.Escape)) captured = !captured;
            if (Input.GetMouseButtonDown(1)) captured = true;
            Cursor.lockState = captured ? CursorLockMode.Locked : CursorLockMode.None;
            Cursor.visible = !captured;
            if (captured && Input.GetKeyDown(KeyCode.R)) Recenter();
            if (captured)
            {
                yaw += Input.GetAxisRaw("Mouse X") * 2f;
                pitch = Mathf.Clamp(pitch - Input.GetAxisRaw("Mouse Y") * 2f, -89f, 89f);
                view.transform.rotation = Quaternion.Euler(pitch, yaw, 0);
                float h = (Input.GetKey(KeyCode.D) ? 1 : 0) - (Input.GetKey(KeyCode.A) ? 1 : 0);
                float f = (Input.GetKey(KeyCode.W) ? 1 : 0) - (Input.GetKey(KeyCode.S) ? 1 : 0);
                float v = (Input.GetKey(KeyCode.E) ? 1 : 0) - (Input.GetKey(KeyCode.Q) ? 1 : 0);
                Vector3 motion = view.transform.right * h + view.transform.forward * f + Vector3.up * v;
                float speed = moveSpeed * (Input.GetKey(KeyCode.LeftShift) ? 3f : 1f);
                view.transform.position += Vector3.ClampMagnitude(motion, 1f) * speed * Time.deltaTime;
            }
            if (splats.Length > 0 && material != null) RebuildAndDraw();
        }

        void RebuildAndDraw()
        {
            Transform ct = view.transform;
            int n = 0;
            for (int i = 0; i < splats.Length; i++)
            {
                var g = splats[i];
                Vector3 p = sceneOffset + new Vector3(g.X, g.Y, g.Z) * sceneScale;
                Vector3 local = ct.InverseTransformPoint(p);
                if (local.z <= view.nearClipPlane || local.z >= view.farClipPlane) continue;
                order[n++] = new Visible { Index = i, Depth = local.z };
            }
            Array.Sort(order, 0, n, BackToFront);
            int drawn = 0;
            for (int k = 0; k < n; k++)
            {
                var g = splats[order[k].Index];
                Vector3 center = sceneOffset + new Vector3(g.X, g.Y, g.Z) * sceneScale;
                Vector3 loc = ct.InverseTransformPoint(center);
                float z = loc.z;
                Quaternion rot = new Quaternion(g.Qx, g.Qy, g.Qz, g.Qw);
                float qmag = Mathf.Sqrt(rot.x * rot.x + rot.y * rot.y + rot.z * rot.z + rot.w * rot.w);
                rot = qmag > .00001f ? new Quaternion(rot.x / qmag, rot.y / qmag, rot.z / qmag, rot.w / qmag) : Quaternion.identity;
                Vector3 a = ct.InverseTransformDirection(rot * Vector3.right) * (g.Sx * sceneScale);
                Vector3 b = ct.InverseTransformDirection(rot * Vector3.up) * (g.Sy * sceneScale);
                Vector3 c = ct.InverseTransformDirection(rot * Vector3.forward) * (g.Sz * sceneScale);
                // Perspective Jacobian, in view-plane world units at the splat depth.
                float dx = loc.x / z, dy = loc.y / z;
                float ax = a.x - dx * a.z, ay = a.y - dy * a.z;
                float bx = b.x - dx * b.z, by = b.y - dy * b.z;
                float cx = c.x - dx * c.z, cy = c.y - dy * c.z;
                float xx = ax * ax + bx * bx + cx * cx;
                float xy = ax * ay + bx * by + cx * cy;
                float yy = ay * ay + by * by + cy * cy;
                float delta = Mathf.Sqrt(Mathf.Max(0, (xx - yy) * (xx - yy) + 4 * xy * xy));
                float l0 = Mathf.Max(1e-9f, .5f * (xx + yy + delta));
                float l1 = Mathf.Max(1e-9f, .5f * (xx + yy - delta));
                Vector2 major = Mathf.Abs(xy) > 1e-8f ? new Vector2(l0 - yy, xy).normalized : (xx >= yy ? Vector2.right : Vector2.up);
                Vector2 minor = new Vector2(-major.y, major.x);
                Vector2 e0 = major * (3f * Mathf.Sqrt(l0));
                Vector2 e1 = minor * (3f * Mathf.Sqrt(l1));
                // Bound oversized splats when flying through a center.
                float cap = z * 3f;
                e0 = Vector2.ClampMagnitude(e0, cap); e1 = Vector2.ClampMagnitude(e1, cap);
                Vector3 u = ct.right * e0.x + ct.up * e0.y;
                Vector3 v = ct.right * e1.x + ct.up * e1.y;
                int vi = drawn * 4, ti = drawn * 6;
                vertices[vi] = center - u - v; vertices[vi + 1] = center + u - v;
                vertices[vi + 2] = center + u + v; vertices[vi + 3] = center - u + v;
                uv[vi] = new Vector2(-3, -3); uv[vi + 1] = new Vector2(3, -3);
                uv[vi + 2] = new Vector2(3, 3); uv[vi + 3] = new Vector2(-3, 3);
                Color col = new Color(g.R, g.G, g.B, g.Opacity);
                colors[vi] = colors[vi + 1] = colors[vi + 2] = colors[vi + 3] = col;
                triangles[ti] = vi; triangles[ti + 1] = vi + 1; triangles[ti + 2] = vi + 2;
                triangles[ti + 3] = vi; triangles[ti + 4] = vi + 2; triangles[ti + 5] = vi + 3;
                drawn++;
            }
            mesh.Clear();
            if (drawn == 0) return;
            mesh.SetVertices(vertices, 0, drawn * 4);
            mesh.SetUVs(0, uv, 0, drawn * 4);
            mesh.SetColors(colors, 0, drawn * 4);
            mesh.SetTriangles(triangles, 0, drawn * 6, 0, false, 0);
            mesh.bounds = new Bounds(ct.position, Vector3.one * 1000f);
            Graphics.DrawMesh(mesh, Matrix4x4.identity, material, 0, view);
        }

        void OnGUI()
        {
            Cursor.lockState = captured ? CursorLockMode.Locked : CursorLockMode.None;
            var old = GUI.skin.label.fontSize;
            GUI.skin.label.fontSize = 14;
            GUILayout.BeginArea(new Rect(12, 12, Mathf.Min(600, Screen.width - 24), 180), GUI.skin.box);
            GUILayout.Label("unitySplat  |  WASD move · Q/E up/down · Shift fast · Mouse look · R recenter · Esc UI");
            GUILayout.Label(status + (progress < 1 ? "  " + Mathf.RoundToInt(progress * 100) + "%" : ""));
            GUILayout.BeginHorizontal();
            filePath = GUILayout.TextField(filePath, GUILayout.MinWidth(200));
            if (GUILayout.Button("Browse", GUILayout.Width(75))) Browse();
            GUI.enabled = !loading;
            if (GUILayout.Button("Load PLY", GUILayout.Width(85))) LoadFile();
            GUI.enabled = true;
            GUILayout.EndHorizontal();
            GUILayout.BeginHorizontal();
            if (GUILayout.Button("Demo", GUILayout.Width(70))) LoadBundled();
            if (GUILayout.Button("Recenter", GUILayout.Width(80))) Recenter();
            GUILayout.Label("Scale " + sceneScale.ToString("F2"), GUILayout.Width(90));
            float nextScale = GUILayout.HorizontalSlider(sceneScale, .1f, 5f);
            if (Mathf.Abs(nextScale - sceneScale) > .001f) { sceneScale = nextScale; }
            GUILayout.EndHorizontal();
            GUILayout.EndArea();
            GUI.skin.label.fontSize = old;
        }

        void Browse()
        {
#if UNITY_EDITOR
            string selected = UnityEditor.EditorUtility.OpenFilePanel("Open Gaussian PLY", "", "ply");
            if (!string.IsNullOrEmpty(selected)) filePath = selected;
#elif UNITY_STANDALONE_LINUX
            try
            {
                var process = new System.Diagnostics.Process();
                process.StartInfo = new System.Diagnostics.ProcessStartInfo("zenity", "--file-selection --file-filter=*.ply") { UseShellExecute = false, RedirectStandardOutput = true, CreateNoWindow = true };
                process.Start();
                string selected = process.StandardOutput.ReadToEnd().Trim();
                process.WaitForExit();
                if (process.ExitCode == 0 && !string.IsNullOrEmpty(selected)) filePath = selected;
            }
            catch (Exception ex) { status = "Browse unavailable (install zenity or enter a path): " + ex.Message; }
#else
            status = "Enter a .ply path in the field above.";
#endif
        }
    }
}
