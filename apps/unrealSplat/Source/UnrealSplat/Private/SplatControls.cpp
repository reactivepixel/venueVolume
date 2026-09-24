#include "SplatControls.h"
#include "SplatHUD.h"
#include "Blueprint/WidgetTree.h"
#include "Components/CanvasPanel.h"
#include "Components/CanvasPanelSlot.h"
#include "Components/HorizontalBox.h"
#include "Components/HorizontalBoxSlot.h"
#include "Components/VerticalBox.h"
#include "Components/Button.h"
#include "Components/EditableTextBox.h"
#include "Components/TextBlock.h"
#include "GameFramework/PlayerController.h"
#include "Misc/Paths.h"

TSharedRef<SWidget> USplatControls::RebuildWidget() {
    if (WidgetTree->RootWidget) return Super::RebuildWidget();
    auto* Root=WidgetTree->ConstructWidget<UCanvasPanel>(UCanvasPanel::StaticClass()); WidgetTree->RootWidget=Root;
    auto* Panel=WidgetTree->ConstructWidget<UVerticalBox>(UVerticalBox::StaticClass());
    auto* Slot=Root->AddChildToCanvas(Panel); Slot->SetAnchors(FAnchors(0,0,1,0)); Slot->SetOffsets(FMargin(16,12,16,100));
    auto* Heading=WidgetTree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass()); Heading->SetText(FText::FromString(TEXT("unrealSplat  |  WASD fly · Q/E rise · right-drag look · Shift sprint · F center · +/- scale"))); Heading->SetColorAndOpacity(FSlateColor(FLinearColor::White)); Panel->AddChildToVerticalBox(Heading);
    auto* Row=WidgetTree->ConstructWidget<UHorizontalBox>(UHorizontalBox::StaticClass()); Panel->AddChildToVerticalBox(Row);
    PathBox=WidgetTree->ConstructWidget<UEditableTextBox>(UEditableTextBox::StaticClass()); PathBox->SetHintText(FText::FromString(TEXT("Absolute path to Gaussian .ply")));
    auto* PathSlot=Row->AddChildToHorizontalBox(PathBox); PathSlot->SetSize(FSlateChildSize(ESlateSizeRule::Fill));
    auto* Load=WidgetTree->ConstructWidget<UButton>(UButton::StaticClass()); auto* LoadText=WidgetTree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass()); LoadText->SetText(FText::FromString(TEXT(" Load PLY "))); Load->AddChild(LoadText); Row->AddChildToHorizontalBox(Load); Load->OnClicked.AddDynamic(this,&USplatControls::LoadClicked);
    auto* Demo=WidgetTree->ConstructWidget<UButton>(UButton::StaticClass()); auto* DemoText=WidgetTree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass()); DemoText->SetText(FText::FromString(TEXT(" Demo room "))); Demo->AddChild(DemoText); Row->AddChildToHorizontalBox(Demo); Demo->OnClicked.AddDynamic(this,&USplatControls::DemoClicked);
    Status=WidgetTree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass()); Status->SetColorAndOpacity(FSlateColor(FLinearColor(0.8,0.95,1,1))); Panel->AddChildToVerticalBox(Status);
    return Super::RebuildWidget();
}
void USplatControls::SetStatus(const FString& Text) { if (Status) Status->SetText(FText::FromString(Text)); }
void USplatControls::SetPath(const FString& Path) { if (PathBox) PathBox->SetText(FText::FromString(Path)); }
void USplatControls::LoadClicked() { if (auto* H=GetOwningPlayer()?Cast<ASplatHUD>(GetOwningPlayer()->GetHUD()):nullptr) H->LoadPly(PathBox->GetText().ToString()); }
void USplatControls::DemoClicked() { const FString Path=FPaths::ConvertRelativePathToFull(FPaths::Combine(FPaths::ProjectContentDir(),TEXT("Splats/demo-room.ply"))); SetPath(Path); LoadClicked(); }
