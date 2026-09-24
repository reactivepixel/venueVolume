#include "SplatGameMode.h"
#include "SplatPawn.h"
#include "SplatHUD.h"
#include "SplatPlayerController.h"
ASplatGameMode::ASplatGameMode() {
    DefaultPawnClass=ASplatPawn::StaticClass();
    HUDClass=ASplatHUD::StaticClass();
    PlayerControllerClass=ASplatPlayerController::StaticClass();
}
