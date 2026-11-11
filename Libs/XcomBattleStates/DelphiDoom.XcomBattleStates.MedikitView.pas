{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape states library - MedikitView of OpenXcom (the   }
{  body of the wounded unit in the medi-kit screen)                             }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattleStates.MedikitView;

interface

uses
  System.SysUtils, DelphiDoom.XcomSurface.SurfaceSet, DelphiDoom.XcomEngine.Action,
  DelphiDoom.XcomEngine.InteractiveSurface, DelphiDoom.XcomUi.Text, DelphiDoom.XcomBattle.Model;

type
  /// <summary>Gives the text of a string of the language (Language::getString)</summary>
  TXcomMedikitTranslate = reference to function(const AId: string): string;

  /// <summary>
  ///   The body of the unit the medi-kit is used on: the six parts of MEDIBITS.DAT, in the color of the wounded
  ///   parts or in the one of the healthy ones. A click on a part selects it; the two texts show its name and its
  ///   fatal wounds. Nothing is owned: the set, the unit and the texts are the caller's
  /// </summary>
  TXcomMedikitView = class(TXcomInteractiveSurface)
  strict private
    FSet: TXcomSurfaceSet;
    FUnit: TXcomBattleUnit;
    FPartText: TXcomText;
    FWoundText: TXcomText;
    FTranslate: TXcomMedikitTranslate;
    FSelectedPart: Integer;
    FHealthyColor: Integer;
    FWoundedColor: Integer;
  protected
    procedure MouseClick(AAction: TXcomAction); override;
  public
    const
      /// <summary>The body parts of a unit</summary>
      PART_COUNT = 6;
      PART_STRINGS: array[0..PART_COUNT - 1] of string = ('STR_HEAD', 'STR_TORSO', 'STR_RIGHT_ARM', 'STR_LEFT_ARM',
        'STR_RIGHT_LEG', 'STR_LEFT_LEG');
      /// <summary>The colors of a ruleset without the element "body" of the interface "medikit"</summary>
      DEFAULT_HEALTHY_COLOR = 0;
      DEFAULT_WOUNDED_COLOR = 3;
    /// <param name="ASet">MEDIBITS.DAT; nil: nothing is drawn and no part can be clicked</param>
    /// <param name="AUnit">The wounded unit</param>
    /// <param name="APartText">Takes the name of the selected part at every draw</param>
    /// <param name="AWoundText">Takes the fatal wounds of the selected part at every draw</param>
    /// <param name="ATranslate">The language of the names of the parts</param>
    constructor Create(AWidth, AHeight, AX, AY: Integer; ASet: TXcomSurfaceSet; AUnit: TXcomBattleUnit;
      APartText, AWoundText: TXcomText; const ATranslate: TXcomMedikitTranslate);
    /// <summary>The color groups of the healthy and of the wounded parts (color and color2 of the element "body")</summary>
    procedure SetBodyColors(AHealthy, AWounded: Integer);
    procedure Draw; override;
    /// <summary>getSelectedPart</summary>
    property SelectedPart: Integer read FSelectedPart;
    /// <summary>updateSelectedPart: the first wounded part becomes the selected one; with no wound nothing changes</summary>
    procedure UpdateSelectedPart;
  end;

implementation

uses
  DelphiDoom.XcomSurface.Surface, DelphiDoom.XcomSurface.Shade;

constructor TXcomMedikitView.Create(AWidth, AHeight, AX, AY: Integer; ASet: TXcomSurfaceSet;
  AUnit: TXcomBattleUnit; APartText, AWoundText: TXcomText; const ATranslate: TXcomMedikitTranslate);
begin
  inherited Create(AWidth, AHeight, AX, AY);
  FSet := ASet;
  FUnit := AUnit;
  FPartText := APartText;
  FWoundText := AWoundText;
  FTranslate := ATranslate;
  FHealthyColor := DEFAULT_HEALTHY_COLOR;
  FWoundedColor := DEFAULT_WOUNDED_COLOR;
  UpdateSelectedPart;
  Redraw := True;
end;

procedure TXcomMedikitView.SetBodyColors(AHealthy, AWounded: Integer);
begin
  FHealthyColor := AHealthy;
  FWoundedColor := AWounded;
  Redraw := True;
end;

procedure TXcomMedikitView.Draw;
var
  LIndex: Integer;
  LFrame: TXcomSurface;
  LColor: Integer;
begin
  // MedikitView::draw does not clear the surface: the parts always cover the same pixels
  if Assigned(FSet) then
    for LIndex := 0 to FSet.TotalFrames - 1 do
    begin
      LFrame := FSet.GetFrame(LIndex);
      if not Assigned(LFrame) then
        Continue;
      if (LIndex < PART_COUNT) and (FUnit.GetFatalWound(LIndex) <> 0) then
        LColor := FWoundedColor
      else
        LColor := FHealthyColor;
      TXcomSurfaceShader.Blit(LFrame, Self, X, Y, 0, False, LColor);
    end;
  Redraw := False;
  if FSelectedPart = -1 then
    Exit;
  if Assigned(FTranslate) then
    FPartText.SetText(FTranslate(PART_STRINGS[FSelectedPart]))
  else
    FPartText.SetText(PART_STRINGS[FSelectedPart]);
  FWoundText.SetText(IntToStr(FUnit.GetFatalWound(FSelectedPart)));
end;

procedure TXcomMedikitView.MouseClick(AAction: TXcomAction);
var
  LIndex: Integer;
  LX: Integer;
  LY: Integer;
  LFrame: TXcomSurface;
begin
  if not Assigned(FSet) then
    Exit;
  LX := Trunc(AAction.RelativeXMouse / AAction.XScale);
  LY := Trunc(AAction.RelativeYMouse / AAction.YScale);
  for LIndex := 0 to FSet.TotalFrames - 1 do
  begin
    LFrame := FSet.GetFrame(LIndex);
    if Assigned(LFrame) and (LX >= 0) and (LY >= 0) and (LX < LFrame.Width) and (LY < LFrame.Height) and
      (LFrame.GetPixel(LX, LY) <> 0) then
    begin
      if LIndex < PART_COUNT then
        FSelectedPart := LIndex;
      Redraw := True;
      Break;
    end;
  end;
end;

procedure TXcomMedikitView.UpdateSelectedPart;
var
  LIndex: Integer;
begin
  for LIndex := 0 to PART_COUNT - 1 do
    if FUnit.GetFatalWound(LIndex) <> 0 then
    begin
      FSelectedPart := LIndex;
      Break;
    end;
end;

end.
