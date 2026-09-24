#include "SplatPlayerController.h"
#include "SplatControls.h"
#include "SplatHUD.h"
#include "Blueprint/UserWidget.h"
void ASplatPlayerController::BeginPlay() {
    Super::BeginPlay();
    bShowMouseCursor=true; bEnableClickEvents=true; bEnableMouseOverEvents=true;
    Controls=CreateWidget<USplatControls>(this,USplatControls::StaticClass());
    if (Controls) { Controls->AddToViewport(10); if (auto* H=Cast<ASplatHUD>(GetHUD())) { Controls->SetStatus(H->GetStatus()); Controls->SetPath(H->GetCurrentPath()); } }
    FInputModeGameAndUI Mode; Mode.SetLockMouseToViewportBehavior(EMouseLockMode::DoNotLock); Mode.SetHideCursorDuringCapture(false); SetInputMode(Mode);
}
