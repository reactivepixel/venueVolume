#pragma once

// Deliberately independent of Unreal so the PLY decoder can be tested with a desktop C++ compiler.
#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <limits>
#include <sstream>
#include <string>
#include <vector>

namespace SplatPly {
struct Splat {
    float x, y, z;
    float color[3];
    float opacity;
    float scale[3];
    float rotation[4]; // w, x, y, z
};
struct Property { std::string name, type; };

inline size_t TypeSize(const std::string& t) {
    if (t == "char" || t == "uchar" || t == "int8" || t == "uint8") return 1;
    if (t == "short" || t == "ushort" || t == "int16" || t == "uint16") return 2;
    if (t == "int" || t == "uint" || t == "float" || t == "int32" || t == "uint32" || t == "float32") return 4;
    if (t == "double" || t == "float64") return 8;
    return 0;
}
inline double ReadNumber(const uint8_t* p, const std::string& t) {
    if (t == "float" || t == "float32") { float v; std::memcpy(&v, p, 4); return v; }
    if (t == "double" || t == "float64") { double v; std::memcpy(&v, p, 8); return v; }
    if (t == "char" || t == "int8") { int8_t v; std::memcpy(&v, p, 1); return v; }
    if (t == "uchar" || t == "uint8") return *p;
    if (t == "short" || t == "int16") { int16_t v; std::memcpy(&v, p, 2); return v; }
    if (t == "ushort" || t == "uint16") { uint16_t v; std::memcpy(&v, p, 2); return v; }
    if (t == "int" || t == "int32") { int32_t v; std::memcpy(&v, p, 4); return v; }
    uint32_t v; std::memcpy(&v, p, 4); return v;
}
inline bool Decode(const std::vector<uint8_t>& bytes, std::vector<Splat>& output, std::string& error) {
    output.clear(); error.clear();
    if (bytes.size() < 4 || !(std::memcmp(bytes.data(), "ply\n", 4) == 0 || (bytes.size() >= 5 && std::memcmp(bytes.data(), "ply\r\n", 5) == 0))) { error = "Missing PLY header"; return false; }
    size_t cursor = 0, count = 0;
    bool ascii = false, formatSeen = false, vertex = false, ended = false;
    std::vector<Property> props;
    while (cursor < bytes.size()) {
        const size_t end = std::find(bytes.begin() + cursor, bytes.end(), uint8_t('\n')) - bytes.begin();
        if (end == bytes.size()) { error = "Truncated PLY header"; return false; }
        std::string line(reinterpret_cast<const char*>(bytes.data() + cursor), end - cursor);
        if (!line.empty() && line.back() == '\r') line.pop_back();
        cursor = end + 1;
        std::istringstream in(line); std::string word; in >> word;
        if (word == "format") { std::string fmt, version; in >> fmt >> version; ascii = fmt == "ascii"; formatSeen = ascii || fmt == "binary_little_endian"; if (version != "1.0" || !formatSeen) { error = "Only PLY 1.0 ASCII or binary_little_endian is supported"; return false; } }
        else if (word == "element") { std::string name; size_t n = 0; in >> name >> n; vertex = name == "vertex"; if (vertex) { count = n; props.clear(); } else if (count == 0 && n > 0) { error = "Vertex element must precede other data"; return false; } }
        else if (word == "property" && vertex) { std::string type, name; in >> type >> name; if (type == "list" || TypeSize(type) == 0 || name.empty()) { error = "Unsupported vertex property type"; return false; } props.push_back({name,type}); }
        else if (word == "end_header") { ended = true; break; }
    }
    if (!ended || !formatSeen || !count || props.empty()) { error = "PLY needs a format and nonempty vertex element"; return false; }
    if (count > 1000000) { error = "PLY exceeds the demo renderer limit of 1,000,000 splats"; return false; }
    auto index = [&](const char* key) -> int { for (size_t i=0;i<props.size();++i) if (props[i].name == key) return int(i); return -1; };
    const char* required[] = {"x","y","z","f_dc_0","f_dc_1","f_dc_2","opacity","scale_0","scale_1","scale_2","rot_0","rot_1","rot_2","rot_3"};
    int ix[14]; for (int i=0;i<14;++i) { ix[i] = index(required[i]); if (ix[i] < 0) { error = std::string("Missing Gaussian property: ") + required[i]; return false; } }
    size_t stride = 0; for (const auto& p : props) stride += TypeSize(p.type);
    if (!ascii && (stride == 0 || count > (bytes.size() - cursor) / stride)) { error = "Truncated binary vertices"; return false; }
    output.reserve(count);
    std::vector<double> values(props.size());
    for (size_t row=0; row<count; ++row) {
        if (ascii) {
            if (cursor >= bytes.size()) { error = "Truncated ASCII vertices"; output.clear(); return false; }
            const size_t end = std::find(bytes.begin() + cursor, bytes.end(), uint8_t('\n')) - bytes.begin();
            std::string line(reinterpret_cast<const char*>(bytes.data()+cursor), end-cursor); cursor = std::min(end+1,bytes.size());
            std::istringstream in(line); for (double& v : values) if (!(in >> v)) { error = "Invalid ASCII vertex"; output.clear(); return false; }
        } else {
            for (size_t i=0;i<props.size();++i) { values[i] = ReadNumber(bytes.data()+cursor, props[i].type); cursor += TypeSize(props[i].type); }
        }
        for (int i : ix) if (!std::isfinite(values[i])) { error = "Non-finite Gaussian property"; output.clear(); return false; }
        for (int j=0;j<3;++j) if (std::abs(values[ix[j]]) > 1000000.0) { error = "Gaussian coordinate outside supported range"; output.clear(); return false; }
        Splat s{}; s.x=float(values[ix[0]]); s.y=float(values[ix[1]]); s.z=float(values[ix[2]]);
        constexpr double SH0 = 0.28209479177387814;
        for (int j=0;j<3;++j) { s.color[j]=float(std::clamp(0.5 + SH0*values[ix[3+j]],0.0,1.0)); s.scale[j]=float(std::exp(std::clamp(values[ix[7+j]],-12.0,5.0))); }
        const double logit=std::clamp(values[ix[6]],-20.0,20.0); s.opacity=float(1.0/(1.0+std::exp(-logit)));
        double qn=0; for (int j=0;j<4;++j) qn += values[ix[10+j]]*values[ix[10+j]];
        if (!std::isfinite(qn) || qn < 1e-12) { error = "Zero Gaussian quaternion"; output.clear(); return false; }
        for (int j=0;j<4;++j) s.rotation[j]=float(values[ix[10+j]]/std::sqrt(qn));
        output.push_back(s);
    }
    return true;
}
} // namespace SplatPly
