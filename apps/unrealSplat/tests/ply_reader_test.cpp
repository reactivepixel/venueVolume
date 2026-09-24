#include "../Source/UnrealSplat/Private/PlyReader.h"
#include <cassert>
#include <fstream>
#include <iostream>
#include <iterator>

static std::vector<uint8_t> load(const char* path) {
    std::ifstream f(path,std::ios::binary); assert(f);
    return std::vector<uint8_t>(std::istreambuf_iterator<char>(f),{});
}
int main(int argc,char** argv) {
    assert(argc == 5);
    std::vector<SplatPly::Splat> pts; std::string err;
    std::vector<SplatPly::Splat> tinyReference;
    for (int i=1;i<5;++i) {
        assert(SplatPly::Decode(load(argv[i]),pts,err));
        assert(!pts.empty());
        for (const auto& p : pts) {
            assert(std::isfinite(p.x)&&std::isfinite(p.y)&&std::isfinite(p.z));
            assert(p.opacity>0&&p.opacity<1);
            for (float s:p.scale) assert(s>0);
            for (float c:p.color) assert(c>=0&&c<=1);
        }
        if (i==1) { assert(pts.size()==3); tinyReference=pts; }
        if (i==2 || i==3) {
            assert(pts.size()==tinyReference.size());
            for (size_t j=0;j<pts.size();++j) {
                assert(std::abs(pts[j].x-tinyReference[j].x)<1e-5f);
                assert(std::abs(pts[j].y-tinyReference[j].y)<1e-5f);
                assert(std::abs(pts[j].z-tinyReference[j].z)<1e-5f);
                assert(std::abs(pts[j].opacity-tinyReference[j].opacity)<1e-5f);
                for (int k=0;k<3;++k) { assert(std::abs(pts[j].color[k]-tinyReference[j].color[k])<1e-5f); assert(std::abs(pts[j].scale[k]-tinyReference[j].scale[k])<1e-5f); }
            }
        }
        if (i==4) assert(pts.size()==6806);
        std::cout << argv[i] << ": " << pts.size() << " Gaussians\n";
    }
    auto bad=load(argv[1]); bad.resize(12);
    assert(!SplatPly::Decode(bad,pts,err));
    std::string crlf="ply\r\nformat ascii 1.0\r\nelement vertex 1\r\n";
    for (auto name : {"x","y","z","f_dc_0","f_dc_1","f_dc_2","opacity","scale_0","scale_1","scale_2","rot_0","rot_1","rot_2","rot_3"}) crlf+="property float "+std::string(name)+"\r\n";
    crlf+="end_header\r\n0 0 0 0 0 0 0 0 0 0 1 0 0 0\r\n";
    assert(SplatPly::Decode(std::vector<uint8_t>(crlf.begin(),crlf.end()),pts,err));
    assert(pts.size()==1);
}
