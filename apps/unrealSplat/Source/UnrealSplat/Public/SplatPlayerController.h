#pragma once
#include "CoreMinimal.h"
#include "GameFramework/PlayerController.h"
#include "SplatPlayerController.generated.h"
class USplatControls;
UCLASS()
class UNREALSPLAT_API ASplatPlayerController : public APlayerController
{
    GENERATED_BODY()
public:
    virtual void BeginPlay() override;
    UPROPERTY() TObjectPtr<USplatControls> Controls;
};
