#pragma once
#include "CoreMinimal.h"
#include "GameFramework/Pawn.h"
#include "SplatPawn.generated.h"

UCLASS()
class UNREALSPLAT_API ASplatPawn : public APawn
{
    GENERATED_BODY()
public:
    ASplatPawn();
    UPROPERTY(VisibleAnywhere) TObjectPtr<class UCameraComponent> Camera;
    virtual void BeginPlay() override;
    virtual void Tick(float DeltaSeconds) override;
    virtual void SetupPlayerInputComponent(UInputComponent* Input) override;
    void Recenter();
    void ScaleUp();
    void ScaleDown();
private:
    void Forward(float V) { ForwardValue = V; }
    void Right(float V) { RightValue = V; }
    void Up(float V) { UpValue = V; }
    void Yaw(float V);
    void Pitch(float V);
    void FastOn() { bFast = true; }
    void FastOff() { bFast = false; }
    float ForwardValue=0, RightValue=0, UpValue=0;
    bool bFast=false;
};
