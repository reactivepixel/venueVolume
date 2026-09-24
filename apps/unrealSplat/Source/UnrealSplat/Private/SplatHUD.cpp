#include "SplatHUD.h"
#include "SplatControls.h"
#include "SplatPlayerController.h"
#include "PlyReader.h"
#include "Engine/Texture2D.h"
#include "Engine/Canvas.h"
#include "GameFramework/PlayerController.h"
#include "GameFramework/Pawn.h"
#include "Math/RotationMatrix.h"
#include <cfloat>
#include "Camera/PlayerCameraManager.h"
#include "Misc/FileHelper.h"
#include "Misc/Paths.h"
#include "HAL/PlatformFileManager.h"
#include <algorithm>
#include <vector>

namespace {
struct Projected {
    float X,Y,Inv00,Inv01,Inv11,Radius,Depth,Alpha;
    FVector3f Color;
};
FVector MapSource(const FVector& V) { return FVector(V.X,V.Z,V.Y); }
}

void ASplatHUD::BeginPlay() {
    Super::BeginPlay();
    Frame=UTexture2D::CreateTransient(Width,Height,PF_B8G8R8A8);
    if (Frame) { Frame->SRGB=true; Frame->Filter=TF_Bilinear; Frame->NeverStream=true; Frame->UpdateResource(); }
    LoadPly(FPaths::ConvertRelativePathToFull(FPaths::Combine(FPaths::ProjectContentDir(),TEXT("Splats/demo-room.ply"))));
}
void ASplatHUD::SetStatus(const FString& Message) {
    StatusMessage=Message;
    if (auto* PC=Cast<ASplatPlayerController>(GetOwningPlayerController()); PC && PC->Controls) PC->Controls->SetStatus(Message);
}
void ASplatHUD::LoadPly(const FString& Path) {
    const FString Full=FPaths::ConvertRelativePathToFull(Path.TrimStartAndEnd());
    if (!Full.EndsWith(TEXT(".ply"),ESearchCase::IgnoreCase)) { SetStatus(TEXT("Choose a .ply file")); return; }
    const int64 Size=FPlatformFileManager::Get().GetPlatformFile().FileSize(*Full);
    if (Size < 0) { SetStatus(FString::Printf(TEXT("File not found: %s"),*Full)); return; }
    if (Size > 256ll*1024*1024) { SetStatus(TEXT("PLY exceeds this demo's 256 MB input limit")); return; }
    TArray<uint8> Bytes;
    if (!FFileHelper::LoadFileToArray(Bytes,*Full)) { SetStatus(FString::Printf(TEXT("Cannot read: %s"),*Full)); return; }
    std::vector<uint8_t> Raw(Bytes.GetData(),Bytes.GetData()+Bytes.Num());
    std::vector<SplatPly::Splat> Decoded; std::string Error;
    if (!SplatPly::Decode(Raw,Decoded,Error)) { SetStatus(FString::Printf(TEXT("PLY error: %s"),UTF8_TO_TCHAR(Error.c_str()))); return; }
    FVector Min(DBL_MAX), Max(-DBL_MAX);
    for (const auto& S : Decoded) { const FVector P(S.x,S.y,S.z); Min=Min.ComponentMin(P); Max=Max.ComponentMax(P); }
    SourceOrigin=FVector((Min.X+Max.X)*0.5,(Min.Y+Max.Y)*0.5,(Min.Z+Max.Z)*0.5);
    Positions.Reset(Decoded.size()); Colors.Reset(Decoded.size()); Scales.Reset(Decoded.size()); Rotations.Reset(Decoded.size()); Opacities.Reset(Decoded.size());
    const size_t Step=std::max<size_t>(1,(Decoded.size()+29999)/30000);
    for (size_t Index=0; Index<Decoded.size(); Index+=Step) {
        const auto& S=Decoded[Index];
        Positions.Add(FVector3f(S.x,S.y,S.z)); Colors.Add(FVector3f(S.color[0],S.color[1],S.color[2]));
        Scales.Add(FVector3f(S.scale[0],S.scale[1],S.scale[2]));
        Rotations.Add(FQuat4f(S.rotation[1],S.rotation[2],S.rotation[3],S.rotation[0])); Opacities.Add(S.opacity);
    }
    CurrentPath=Full; SceneScale=1.f;
    if (auto* PC=Cast<ASplatPlayerController>(GetOwningPlayerController()); PC && PC->Controls) PC->Controls->SetPath(Full);
    SetStatus(FString::Printf(TEXT("Loaded %d Gaussians (%d displayed) | %s | scale %.2fx"),int32(Decoded.size()),Positions.Num(),*FPaths::GetCleanFilename(Full),SceneScale));
    if (auto* Pawn=GetOwningPlayerController()->GetPawn()) { Pawn->SetActorLocation(FVector::ZeroVector); Pawn->SetActorRotation(FRotator::ZeroRotator); }
}
void ASplatHUD::DrawHUD() {
    Super::DrawHUD();
    if (!Canvas || !Frame) return;
    const float Aspect=Canvas->SizeX/FMath::Max(1.f,float(Canvas->SizeY));
    const int32 NewHeight=FMath::Clamp(FMath::RoundToInt(Width/Aspect),256,640);
    if (NewHeight!=Height) { Height=NewHeight; Frame=UTexture2D::CreateTransient(Width,Height,PF_B8G8R8A8); Frame->SRGB=true; Frame->Filter=TF_Bilinear; Frame->NeverStream=true; Frame->UpdateResource(); }
    RenderFrame();
    DrawTexture(Frame,0,0,Canvas->SizeX,Canvas->SizeY,0,0,1,1,FLinearColor::White,BLEND_Opaque,1.f,false);
    DrawText(FString::Printf(TEXT("%d splats   %.2fx"),Positions.Num(),SceneScale),FLinearColor::White,16,Canvas->SizeY-36,nullptr,1.f,false);
}
void ASplatHUD::RenderFrame() {
    const int32 Pixels=Width*Height;
    FrameBytes.SetNumUninitialized(Pixels*4);
    for (int32 i=0;i<Pixels;++i) { FrameBytes[i*4+0]=24; FrameBytes[i*4+1]=16; FrameBytes[i*4+2]=11; FrameBytes[i*4+3]=255; }
    if (!Positions.IsEmpty()) {
        const auto* PC=GetOwningPlayerController();
        const FVector Camera=PC->PlayerCameraManager->GetCameraLocation();
        const FRotator Rotation=PC->PlayerCameraManager->GetCameraRotation();
        const FVector Forward=Rotation.Vector(), Right=FRotationMatrix(Rotation).GetUnitAxis(EAxis::Y), Up=FRotationMatrix(Rotation).GetUnitAxis(EAxis::Z);
        const float Focal=0.5f*Width/FMath::Tan(FMath::DegreesToRadians(PC->PlayerCameraManager->GetFOVAngle()*0.5f));
        std::vector<Projected> Visible; Visible.reserve(Positions.Num());
        for (int32 i=0;i<Positions.Num();++i) {
            const FVector Src(Positions[i]); const FVector World=MapSource(Src-SourceOrigin)*(100.f*SceneScale);
            const FVector R=World-Camera; const float D=float(FVector::DotProduct(R,Forward)); if (D<2.f || D>100000.f) continue;
            const float Side=float(FVector::DotProduct(R,Right)), High=float(FVector::DotProduct(R,Up));
            const float PX=Width*0.5f+Focal*Side/D, PY=Height*0.5f-Focal*High/D;
            const FQuat Q(Rotations[i].X,Rotations[i].Y,Rotations[i].Z,Rotations[i].W); const FVector3f S=Scales[i];
            const FVector Axes[3]={MapSource(Q.RotateVector(FVector::ForwardVector))*S.X*100.f*SceneScale,MapSource(Q.RotateVector(FVector::RightVector))*S.Y*100.f*SceneScale,MapSource(Q.RotateVector(FVector::UpVector))*S.Z*100.f*SceneScale};
            float C00=0.3f,C01=0,C11=0.3f;
            for (const FVector& A : Axes) {
                const float Ad=float(FVector::DotProduct(A,Forward)), As=float(FVector::DotProduct(A,Right)), Ah=float(FVector::DotProduct(A,Up));
                const float Jx=Focal*(As*D-Side*Ad)/(D*D), Jy=-Focal*(Ah*D-High*Ad)/(D*D);
                C00+=Jx*Jx; C01+=Jx*Jy; C11+=Jy*Jy;
            }
            const float Det=C00*C11-C01*C01; if (Det<1e-8f || !FMath::IsFinite(Det)) continue;
            const float Trace=C00+C11, Lambda=0.5f*(Trace+FMath::Sqrt(FMath::Max(0.f,(C00-C11)*(C00-C11)+4*C01*C01)));
            const float Radius=FMath::Min(96.f,3.f*FMath::Sqrt(Lambda));
            if (PX+Radius<0 || PX-Radius>=Width || PY+Radius<0 || PY-Radius>=Height) continue;
            Visible.push_back({PX,PY,C11/Det,-C01/Det,C00/Det,Radius,D,Opacities[i],Colors[i]});
        }
        std::sort(Visible.begin(),Visible.end(),[](const Projected& A,const Projected& B){return A.Depth>B.Depth;});
        for (const Projected& S : Visible) {
            const int32 X0=FMath::Max(0,FMath::FloorToInt(S.X-S.Radius)), X1=FMath::Min(Width-1,FMath::CeilToInt(S.X+S.Radius));
            const int32 Y0=FMath::Max(0,FMath::FloorToInt(S.Y-S.Radius)), Y1=FMath::Min(Height-1,FMath::CeilToInt(S.Y+S.Radius));
            const int32 RGB[3]={FMath::RoundToInt(S.Color.Z*255),FMath::RoundToInt(S.Color.Y*255),FMath::RoundToInt(S.Color.X*255)};
            for (int32 Y=Y0;Y<=Y1;++Y) for (int32 X=X0;X<=X1;++X) {
                const float U=X+0.5f-S.X,V=Y+0.5f-S.Y;
                const float R2=S.Inv00*U*U+2*S.Inv01*U*V+S.Inv11*V*V;
                if (R2>9.f) continue;
                const float A=S.Alpha*FMath::Exp(-0.5f*R2); if (A<0.003f) continue;
                uint8* P=FrameBytes.GetData()+4*(Y*Width+X);
                for (int32 C=0;C<3;++C) P[C]=uint8(FMath::Clamp(FMath::RoundToInt(RGB[C]*A+P[C]*(1-A)),0,255));
            }
        }
    }
    const int32 Size=FrameBytes.Num(); uint8* Upload=(uint8*)FMemory::Malloc(Size); FMemory::Memcpy(Upload,FrameBytes.GetData(),Size);
    auto* Region=new FUpdateTextureRegion2D(0,0,0,0,Width,Height);
    Frame->UpdateTextureRegions(0,1,Region,Width*4,4,Upload,[](uint8* Data,const FUpdateTextureRegion2D* Regions){FMemory::Free(Data);delete Regions;});
}
