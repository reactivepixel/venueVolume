#include "SplatPawn.h"
#include "Components/InputComponent.h"
#include "InputCoreTypes.h"
#include "GameFramework/PlayerController.h"
#include "SplatGameMode.h"
#include "SplatHUD.h"
#include "Engine/World.h"
#include "Camera/CameraComponent.h"
#include "Components/SceneComponent.h"

ASplatPawn::ASplatPawn() { RootComponent=CreateDefaultSubobject<USceneComponent>(TEXT("Root")); Camera=CreateDefaultSubobject<UCameraComponent>(TEXT("Camera")); Camera->SetupAttachment(RootComponent); Camera->FieldOfView=90.f; PrimaryActorTick.bCanEverTick=true; bUseControllerRotationYaw=false; AutoPossessPlayer=EAutoReceiveInput::Player0; }
void ASplatPawn::BeginPlay() { Super::BeginPlay(); Recenter(); }
void ASplatPawn::Recenter() { SetActorLocation(FVector::ZeroVector); SetActorRotation(FRotator::ZeroRotator); }
void ASplatPawn::ScaleUp() { if (auto* H=Cast<ASplatHUD>(GetWorld()->GetFirstPlayerController()->GetHUD())) H->SetSceneScale(H->GetSceneScale()*1.2f); }
void ASplatPawn::ScaleDown() { if (auto* H=Cast<ASplatHUD>(GetWorld()->GetFirstPlayerController()->GetHUD())) H->SetSceneScale(H->GetSceneScale()/1.2f); }
void ASplatPawn::Yaw(float V) { if (auto* P=GetWorld()->GetFirstPlayerController(); P && P->IsInputKeyDown(EKeys::RightMouseButton)) AddActorWorldRotation(FRotator(0,V*0.12f,0)); }
void ASplatPawn::Pitch(float V) { if (auto* P=GetWorld()->GetFirstPlayerController(); P && P->IsInputKeyDown(EKeys::RightMouseButton)) { FRotator R=GetActorRotation(); R.Pitch=FMath::ClampAngle(R.Pitch+V*0.12f,-89.f,89.f); SetActorRotation(R); } }
void ASplatPawn::Tick(float Dt) { Super::Tick(Dt); const float Speed=(bFast?800.f:220.f)*Dt; const FVector Delta=GetActorForwardVector()*ForwardValue+GetActorRightVector()*RightValue+FVector::UpVector*UpValue; AddActorWorldOffset(Delta.GetClampedToMaxSize(1.f)*Speed,false); }
void ASplatPawn::SetupPlayerInputComponent(UInputComponent* Input) {
    Super::SetupPlayerInputComponent(Input);
    Input->BindAxis("MoveForward",this,&ASplatPawn::Forward); Input->BindAxis("MoveRight",this,&ASplatPawn::Right); Input->BindAxis("MoveUp",this,&ASplatPawn::Up);
    Input->BindAxis("LookYaw",this,&ASplatPawn::Yaw); Input->BindAxis("LookPitch",this,&ASplatPawn::Pitch);
    Input->BindAction("Fast",IE_Pressed,this,&ASplatPawn::FastOn); Input->BindAction("Fast",IE_Released,this,&ASplatPawn::FastOff);
    Input->BindAction("Recenter",IE_Pressed,this,&ASplatPawn::Recenter); Input->BindAction("ScaleUp",IE_Pressed,this,&ASplatPawn::ScaleUp); Input->BindAction("ScaleDown",IE_Pressed,this,&ASplatPawn::ScaleDown);
}
