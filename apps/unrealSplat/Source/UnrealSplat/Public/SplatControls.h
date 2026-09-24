#pragma once
#include "CoreMinimal.h"
#include "Blueprint/UserWidget.h"
#include "SplatControls.generated.h"
class UEditableTextBox;
class UTextBlock;

UCLASS()
class UNREALSPLAT_API USplatControls : public UUserWidget
{
    GENERATED_BODY()
public:
    virtual TSharedRef<SWidget> RebuildWidget() override;
    void SetStatus(const FString& Text);
    void SetPath(const FString& Path);
private:
    UPROPERTY() TObjectPtr<UEditableTextBox> PathBox;
    UPROPERTY() TObjectPtr<UTextBlock> Status;
    UFUNCTION() void LoadClicked();
    UFUNCTION() void DemoClicked();
};
