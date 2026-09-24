using System;
using System.IO;
using System.Text;
using UnitySplat;

static void Check(bool condition, string message)
{
    if (!condition) throw new Exception(message);
}
static void Near(float x, float y, string message)
{
    Check(Math.Abs(x - y) < 0.001f, message + ": " + x + " vs " + y);
}
static void MustFail(string source, string expected)
{
    try { GaussianPly.Read(new MemoryStream(Encoding.ASCII.GetBytes(source))); }
    catch (InvalidDataException ex) { Check(ex.Message.Contains(expected), ex.Message); return; }
    throw new Exception("Expected invalid input: " + expected);
}

var fixture = Path.Combine(AppContext.BaseDirectory, "Fixtures");
var ascii = GaussianPly.Read(Path.Combine(fixture, "tiny-ascii.ply"));
var binary = GaussianPly.Read(Path.Combine(fixture, "tiny-binary.ply"));
var reorder = GaussianPly.Read(Path.Combine(fixture, "tiny-reordered-binary.ply"));
Check(ascii.Length == 3 && binary.Length == 3 && reorder.Length == 3, "fixture counts");
for (int i = 0; i < 3; i++)
{
    Near(ascii[i].X, binary[i].X, "binary x"); Near(ascii[i].Y, binary[i].Y, "binary y");
    Near(ascii[i].Z, reorder[i].Z, "reordered z"); Near(ascii[i].R, reorder[i].R, "reordered red");
    Near(ascii[i].Opacity, binary[i].Opacity, "opacity"); Near(ascii[i].Sx, binary[i].Sx, "scale");
    Near(ascii[i].Qw, reorder[i].Qw, "rotation");
}
Near(ascii[0].R, 1, "SH DC red"); Near(ascii[0].G, 0, "SH DC green"); Near(ascii[0].Opacity, .5f, "sigmoid zero");
var crlf = File.ReadAllText(Path.Combine(fixture, "tiny-ascii.ply")).Replace("\n", "\r\n");
Check(GaussianPly.Read(new MemoryStream(Encoding.ASCII.GetBytes(crlf))).Length == 3, "CRLF support");
var missing = File.ReadAllText(Path.Combine(fixture, "tiny-ascii.ply")).Replace("property float rot_3", "property float missing");
MustFail(missing, "Missing Gaussian property");
var invalid = File.ReadAllText(Path.Combine(fixture, "tiny-ascii.ply")).Replace("1.7724539 -1.7724539", "NaN -1.7724539");
MustFail(invalid, "Non-finite");
MustFail("ply\nformat ascii 1.0\nelement face 1\nproperty int i\nelement vertex 0\nproperty float x\nend_header\n", "Vertex must be the first");
Console.WriteLine("Gaussian PLY parser: ASCII, little-endian binary, reordered columns, transforms, CRLF and malformed input passed.");
