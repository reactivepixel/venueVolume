#pragma once
#include "CoreMinimal.h"
#include "GameFramework/HUD.h"
#include "SplatHUD.generated.h"
class UTexture2D;
namespace SplatPly { struct Splat; }

UCLASS()
class UNREALSPLAT_API ASplatHUD : public AHUD
{
    GENERATED_BODY()
public:
    virtual void BeginPlay() override;
    virtual void DrawHUD() override;
    void LoadPly(const FString& Path);
    void SetSceneScale(float Value) { SceneScale=FMath::Clamp(Value,0.05f,20.f); }
    float GetSceneScale() const { return SceneScale; }
    const FString& GetStatus() const { return StatusMessage; }
    const FString& GetCurrentPath() const { return CurrentPath; }
private:
    UPROPERTY() TObjectPtr<UTexture2D> Frame;
    TArray<uint8> FrameBytes;
    TArray<FVector3f> Positions;
    TArray<FVector3f> Colors;
    TArray<FVector3f> Scales;
    TArray<FQuat4f> Rotations;
    TArray<float> Opacities;
    FVector SourceOrigin=FVector::ZeroVector;
    float SceneScale=1.f;
    int32 Width=640, Height=360;
    FString CurrentPath;
    FString StatusMessage;
    void RenderFrame();
    void SetStatus(const FString& Message);
};
