using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Text;

namespace UnitySplat
{
    // Deliberately has no Unity dependency so it can be checked with dotnet.
    public struct Gaussian
    {
        public float X, Y, Z, R, G, B, Opacity, Sx, Sy, Sz, Qw, Qx, Qy, Qz;
    }

    public static class GaussianPly
    {
        struct Property { public string Name, Type; }
        const float C0 = 0.2820947918f;

        public static Gaussian[] Read(string path, Action<float> progress = null)
        {
            using (var stream = File.OpenRead(path)) return Read(stream, progress);
        }

        public static Gaussian[] Read(Stream stream, Action<float> progress = null)
        {
            if (!stream.CanRead) throw new InvalidDataException("PLY stream is unreadable.");
            if (stream.CanSeek && stream.Length - stream.Position > 1024L * 1024 * 1024) throw new InvalidDataException("PLY exceeds 1 GiB demo limit.");
            string first = Line(stream);
            if (first != "ply") throw new InvalidDataException("Expected a PLY header.");
            string format = null;
            int count = -1;
            bool vertices = false;
            var props = new List<Property>();
            for (int i = 0; i < 4096; i++)
            {
                string line = Line(stream);
                if (line == null) throw new InvalidDataException("PLY header ended early.");
                if (line == "end_header") break;
                string[] t = line.Split(new[] { ' ' }, StringSplitOptions.RemoveEmptyEntries);
                if (t.Length == 0) continue;
                if (t[0] == "format")
                {
                    if (t.Length < 3 || t[2] != "1.0") throw new InvalidDataException("Unsupported PLY version.");
                    format = t[1];
                }
                else if (t[0] == "element")
                {
                    vertices = t.Length >= 3 && t[1] == "vertex";
                    if (vertices)
                    {
                        if (count >= 0) throw new InvalidDataException("Multiple vertex elements are unsupported.");
                        count = int.Parse(t[2], CultureInfo.InvariantCulture);
                        if (count < 0 || count > 250000) throw new InvalidDataException("This viewer supports at most 250,000 vertices.");
                    }
                    else if (count < 0) throw new InvalidDataException("Vertex must be the first PLY element.");
                }
                else if (vertices && t[0] == "property")
                {
                    if (t.Length != 3 || t[1] == "list") throw new InvalidDataException("Vertex list properties are unsupported.");
                    props.Add(new Property { Type = t[1], Name = t[2] });
                }
                if (i == 4095) throw new InvalidDataException("PLY header is too long.");
            }
            if (count < 0 || props.Count == 0) throw new InvalidDataException("PLY has no vertex element.");
            if (format != "ascii" && format != "binary_little_endian") throw new InvalidDataException("Use ASCII or binary little-endian PLY.");
            var names = new HashSet<string>();
            foreach (Property p in props) names.Add(p.Name);
            foreach (string required in new[] { "x", "y", "z", "f_dc_0", "f_dc_1", "f_dc_2", "opacity", "scale_0", "scale_1", "scale_2", "rot_0", "rot_1", "rot_2", "rot_3" })
                if (!names.Contains(required)) throw new InvalidDataException("Missing Gaussian property: " + required);
            var result = new Gaussian[count];
            var values = new Dictionary<string, float>(props.Count);
            using (var binary = new BinaryReader(stream, Encoding.ASCII, true))
            {
                for (int i = 0; i < count; i++)
                {
                    values.Clear();
                    if (format == "ascii")
                    {
                        string line = Line(stream);
                        if (line == null) throw new EndOfStreamException("PLY ended at vertex " + i);
                        string[] t = line.Split((char[])null, StringSplitOptions.RemoveEmptyEntries);
                        if (t.Length < props.Count) throw new InvalidDataException("Short vertex at " + i);
                        for (int j = 0; j < props.Count; j++) values[props[j].Name] = float.Parse(t[j], CultureInfo.InvariantCulture);
                    }
                    else
                    {
                        for (int j = 0; j < props.Count; j++) values[props[j].Name] = ReadNumber(binary, props[j].Type);
                    }
                    foreach (string required in new[] { "x", "y", "z", "f_dc_0", "f_dc_1", "f_dc_2", "opacity", "scale_0", "scale_1", "scale_2", "rot_0", "rot_1", "rot_2", "rot_3" })
                        if (!Finite(values[required])) throw new InvalidDataException("Non-finite " + required + " at vertex " + i);
                    double norm = Math.Sqrt((double)values["rot_0"] * values["rot_0"] + (double)values["rot_1"] * values["rot_1"] + (double)values["rot_2"] * values["rot_2"] + (double)values["rot_3"] * values["rot_3"]);
                    if (norm < 1e-12 || double.IsInfinity(norm)) throw new InvalidDataException("Invalid rotation at vertex " + i);
                    var g = new Gaussian {
                        X = values["x"], Y = values["y"], Z = values["z"],
                        R = Clamp01(.5f + C0 * values["f_dc_0"]), G = Clamp01(.5f + C0 * values["f_dc_1"]), B = Clamp01(.5f + C0 * values["f_dc_2"]),
                        Opacity = Sigmoid(values["opacity"]), Sx = ExpClamped(values["scale_0"]), Sy = ExpClamped(values["scale_1"]), Sz = ExpClamped(values["scale_2"]),
                        Qw = (float)(values["rot_0"] / norm), Qx = (float)(values["rot_1"] / norm), Qy = (float)(values["rot_2"] / norm), Qz = (float)(values["rot_3"] / norm)
                    };
                    if (!Finite(g.X) || !Finite(g.Y) || !Finite(g.Z) || !Finite(g.Qw) || !Finite(g.Qx) || !Finite(g.Qy) || !Finite(g.Qz))
                        throw new InvalidDataException("Non-finite Gaussian at vertex " + i);
                    result[i] = g;
                    if ((i & 1023) == 0) progress?.Invoke((float)i / Math.Max(1, count));
                }
            }
            progress?.Invoke(1);
            return result;
        }

        static float ReadNumber(BinaryReader b, string type)
        {
            switch (type)
            {
                case "float": case "float32": return b.ReadSingle();
                case "double": case "float64": return (float)b.ReadDouble();
                case "uchar": case "uint8": return b.ReadByte();
                case "char": case "int8": return b.ReadSByte();
                case "short": case "int16": return b.ReadInt16();
                case "ushort": case "uint16": return b.ReadUInt16();
                case "int": case "int32": return b.ReadInt32();
                case "uint": case "uint32": return b.ReadUInt32();
                default: throw new InvalidDataException("Unsupported PLY property type: " + type);
            }
        }
        static string Line(Stream s)
        {
            var bytes = new List<byte>();
            int c;
            while ((c = s.ReadByte()) != -1 && c != '\n')
            {
                bytes.Add((byte)c);
                if (bytes.Count > 65536) throw new InvalidDataException("PLY line exceeds 64 KiB.");
            }
            if (c == -1 && bytes.Count == 0) return null;
            if (bytes.Count > 0 && bytes[bytes.Count - 1] == '\r') bytes.RemoveAt(bytes.Count - 1);
            return Encoding.ASCII.GetString(bytes.ToArray());
        }
        static bool Finite(float x) { return !float.IsNaN(x) && !float.IsInfinity(x); }
        static float Clamp01(float x) { return Math.Max(0, Math.Min(1, x)); }
        static float Sigmoid(float x) { return x >= 0 ? 1f / (1f + (float)Math.Exp(-x)) : (float)Math.Exp(x) / (1f + (float)Math.Exp(x)); }
        static float ExpClamped(float x) { return (float)Math.Exp(Math.Max(-12f, Math.Min(6f, x))); }
    }
}
