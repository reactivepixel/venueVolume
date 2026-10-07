#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;
[[ stitchable ]] half4 paletteSwatch(float2 position, half4 color, float2 size, float kind, float phase) {
    float2 uv = position / size;
    float v = 0;
    float3 base = float3(.08,.15,.16), light = float3(.68,.9,.77);
    if (kind < .5) { v = pow(.5+.5*sin(uv.x*14-phase*6.283),2.0)*(.35+.65*exp(-pow((uv.y-.5)*3,2.0))); }
    else if (kind < 1.5) { v = exp(-dot((uv-.5)*float2(1,1.5),(uv-.5)*float2(1,1.5))*7)*(.5+.4*sin(phase*6.283)); light=float3(.55,.8,.82); }
    else if (kind < 2.5) { v=step(.5,fract(uv.x*5-phase))*.85; }
    else if (kind < 3.5) { float q=.5+.5*sin(uv.x*5+phase*6.283);base=mix(float3(.16,.13,.55),float3(.65,.1,.2),q);light=mix(float3(.3,.4,1),float3(1,.25,.3),q);v=.6; }
    else { base=float3(.3,.2,.1);light=float3(1,.78,.44);v=.3+.6*exp(-length(uv-.5)*3); }
    return half4(half3(mix(base,light,v)), 1);
}
