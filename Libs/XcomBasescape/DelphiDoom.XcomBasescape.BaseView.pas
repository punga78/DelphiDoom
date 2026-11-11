{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom basescape library - BaseView of OpenXcom (the grid of the   }
{  facilities of a base)                                                        }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBasescape.BaseView;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Xcom.Types, DelphiDoom.XcomSurface.Surface, DelphiDoom.XcomSurface.SurfaceSet,
  DelphiDoom.XcomSurface.Font,
  DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomMod.RuleBaseFacility, DelphiDoom.XcomSave.Base,
  DelphiDoom.XcomSave.BaseFacility, DelphiDoom.XcomSave.Craft, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Intf, DelphiDoom.XcomEngine.Action,
  DelphiDoom.XcomEngine.Language, DelphiDoom.XcomEngine.Timer, DelphiDoom.XcomEngine.InteractiveSurface;

type
  /// <summary>
  ///   The 6 x 6 grid of a base: the floor, the facilities (under construction with the days that are left), the
  ///   corridors between them and the crafts in their hangars. It knows which facility is under the mouse and, when a
  ///   size is asked for, shows a blinking selector. The base, the ruleset and the set of sprites are not owned
  /// </summary>
  TXcomBaseView = class(TXcomInteractiveSurface)
  public
    const
      BASE_SIZE = 6;
      GRID_SIZE = 32;
  strict private
    FRuleset: TXcomRuleset;
    FBase: TXcomBase;
    FTexture: TXcomSurfaceSet;
    FFacilities: array[0..BASE_SIZE - 1, 0..BASE_SIZE - 1] of TXcomBaseFacility;
    FSelected: TXcomBaseFacility;
    FBig: TXcomFont;
    FSmall: TXcomFont;
    FLanguage: TXcomLanguage;
    FGridX: Integer;
    FGridY: Integer;
    FSelectorSize: Integer;
    FSelector: TXcomSurface;
    FCellColor: Byte;
    FSelectorColor: Byte;
    FBlinkOn: Boolean;
    FTimer: TXcomTimer;
    FColors: TXcomColors;
    FHangars: TDictionary<TXcomBaseFacility, TXcomCraft>;
    procedure Blink;
    procedure DrawSelector(AOn: Boolean);
    function RuleOf(AFacility: TXcomBaseFacility): TXcomRuleBaseFacility;
  protected
    procedure MouseOver(AAction: TXcomAction); override;
    procedure MouseOut(AAction: TXcomAction); override;
  public
    constructor Create(const AClock: IXcomClock; ARuleset: TXcomRuleset; AWidth, AHeight, AX, AY: Integer);
    destructor Destroy; override;
    procedure InitText(ABig, ASmall: TXcomFont; ALanguage: TXcomLanguage); override;
    procedure SetColor(AColor: Byte); override;
    procedure SetSecondaryColor(AColor: Byte); override;
    procedure SetPalette(AColors: PXcomColor; AFirst: Integer = 0; ACount: Integer = 256); override;
    procedure Think; override;
    procedure Draw; override;
    procedure Blit(ATarget: TXcomSurface); override;
    /// <summary>BaseView::setBase: shows the base and fills the grid with its facilities</summary>
    procedure SetBase(ABase: TXcomBase);
    procedure SetTexture(ATexture: TXcomSurfaceSet);
    /// <summary>The facility under the mouse (nil if none)</summary>
    function SelectedFacility: TXcomBaseFacility;
    procedure ResetSelectedFacility;
    /// <summary>BaseView::setSelectable: a selector of ASize x ASize cells follows the mouse; 0 removes it</summary>
    procedure SetSelectable(ASize: Integer);
    /// <summary>BaseView::isPlaceable: the facility fits where the mouse is, touching one that is built (or any with the queue)</summary>
    function IsPlaceable(ARule: TXcomRuleBaseFacility; AAllowQueue: Boolean): Boolean;
    property GridX: Integer read FGridX;
    property GridY: Integer read FGridY;
    /// <summary>The facility of a cell of the grid (nil if empty)</summary>
    function FacilityAt(AX, AY: Integer): TXcomBaseFacility;
    /// <summary>The craft that is in the hangar (BaseFacility::getCraft, set when the view is drawn); nil if none</summary>
    function CraftOf(AFacility: TXcomBaseFacility): TXcomCraft;
  end;

implementation

uses
  System.Math, DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.Types;

constructor TXcomBaseView.Create(const AClock: IXcomClock; ARuleset: TXcomRuleset; AWidth, AHeight, AX, AY: Integer);
begin
  inherited Create(AWidth, AHeight, AX, AY);
  FRuleset := ARuleset;
  FBlinkOn := True;
  FHangars := TDictionary<TXcomBaseFacility, TXcomCraft>.Create;
  FTimer := TXcomTimer.Create(AClock, 100);
  FTimer.OnTimerSurface(Blink);
  FTimer.Start;
end;

destructor TXcomBaseView.Destroy;
begin
  FSelector.Free;
  FTimer.Free;
  FHangars.Free;
  inherited Destroy;
end;

procedure TXcomBaseView.InitText(ABig, ASmall: TXcomFont; ALanguage: TXcomLanguage);
begin
  FBig := ABig;
  FSmall := ASmall;
  FLanguage := ALanguage;
end;

procedure TXcomBaseView.SetColor(AColor: Byte);
begin
  FCellColor := AColor;
end;

procedure TXcomBaseView.SetSecondaryColor(AColor: Byte);
begin
  FSelectorColor := AColor;
end;

procedure TXcomBaseView.SetPalette(AColors: PXcomColor; AFirst, ACount: Integer);
var
  LColors: TArray<DelphiDoom.Xcom.Types.TXcomColor>;
  LIndex: Integer;
begin
  inherited SetPalette(AColors, AFirst, ACount);
  for LIndex := 0 to ACount - 1 do
    if AFirst + LIndex <= 255 then
      FColors[AFirst + LIndex] := PXcomColor(PByte(AColors) + LIndex * SizeOf(DelphiDoom.Xcom.Types.TXcomColor))^;
  if Assigned(FSelector) then
  begin
    SetLength(LColors, ACount);
    for LIndex := 0 to ACount - 1 do
      LColors[LIndex] := PXcomColor(PByte(AColors) + LIndex * SizeOf(DelphiDoom.Xcom.Types.TXcomColor))^;
    FSelector.SetColors(LColors, AFirst);
  end;
end;

function TXcomBaseView.RuleOf(AFacility: TXcomBaseFacility): TXcomRuleBaseFacility;
begin
  Result := FRuleset.Facilities.Find(AFacility.Rules.FacilityType);
end;

procedure TXcomBaseView.SetBase(ABase: TXcomBase);
var
  LX, LY: Integer;
  LFacility: TXcomBaseFacility;
  LRule: TXcomRuleBaseFacility;
begin
  FBase := ABase;
  FSelected := nil;
  for LX := 0 to BASE_SIZE - 1 do
    for LY := 0 to BASE_SIZE - 1 do
      FFacilities[LX, LY] := nil;
  for LFacility in FBase.Facilities do
  begin
    LRule := RuleOf(LFacility);
    for LY := LFacility.Y to LFacility.Y + LRule.Size - 1 do
      for LX := LFacility.X to LFacility.X + LRule.Size - 1 do
        FFacilities[LX, LY] := LFacility;
  end;
  Redraw := True;
end;

procedure TXcomBaseView.SetTexture(ATexture: TXcomSurfaceSet);
begin
  FTexture := ATexture;
end;

function TXcomBaseView.SelectedFacility: TXcomBaseFacility;
begin
  Result := FSelected;
end;

function TXcomBaseView.FacilityAt(AX, AY: Integer): TXcomBaseFacility;
begin
  Result := FFacilities[AX, AY];
end;

function TXcomBaseView.CraftOf(AFacility: TXcomBaseFacility): TXcomCraft;
begin
  if not FHangars.TryGetValue(AFacility, Result) then
    Result := nil;
end;

procedure TXcomBaseView.ResetSelectedFacility;
begin
  FFacilities[FSelected.X, FSelected.Y] := nil;
  FSelected := nil;
end;

procedure TXcomBaseView.DrawSelector(AOn: Boolean);
begin
  FSelector.DrawRect(0, 0, FSelector.Width, FSelector.Height, IfThen(AOn, FSelectorColor, 0));
  if AOn then
    FSelector.DrawRect(1, 1, FSelector.Width - 2, FSelector.Height - 2, 0);
end;

procedure TXcomBaseView.SetSelectable(ASize: Integer);
begin
  FSelectorSize := ASize;
  FreeAndNil(FSelector);
  if FSelectorSize > 0 then
  begin
    FSelector := TXcomSurface.Create(ASize * GRID_SIZE, ASize * GRID_SIZE, X, Y);
    FSelector.SetColors(FColors);
    DrawSelector(True);
    FSelector.Visible := False;
  end;
end;

function TXcomBaseView.IsPlaceable(ARule: TXcomRuleBaseFacility; AAllowQueue: Boolean): Boolean;
var
  LX, LY, LIndex, LSize: Integer;

  function Touches(AFacility: TXcomBaseFacility): Boolean;
  begin
    Result := Assigned(AFacility) and (AAllowQueue or (AFacility.BuildTime = 0));
  end;

begin
  LSize := ARule.Size;
  for LY := FGridY to FGridY + LSize - 1 do
    for LX := FGridX to FGridX + LSize - 1 do
    begin
      if (LX < 0) or (LX >= BASE_SIZE) or (LY < 0) or (LY >= BASE_SIZE) then
        Exit(False);
      if Assigned(FFacilities[LX, LY]) then
        Exit(False);
    end;
  for LIndex := 0 to LSize - 1 do
    if ((FGridX > 0) and Touches(FFacilities[FGridX - 1, FGridY + LIndex])) or
      ((FGridY > 0) and Touches(FFacilities[FGridX + LIndex, FGridY - 1])) or
      ((FGridX + LSize < BASE_SIZE) and Touches(FFacilities[FGridX + LSize, FGridY + LIndex])) or
      ((FGridY + LSize < BASE_SIZE) and Touches(FFacilities[FGridX + LIndex, FGridY + LSize])) then
      Exit(True);
  Result := False;
end;

procedure TXcomBaseView.Think;
begin
  inherited Think;
  FTimer.Think(False, True);
end;

procedure TXcomBaseView.Blink;
begin
  FBlinkOn := not FBlinkOn;
  if FSelectorSize > 0 then
    DrawSelector(FBlinkOn);
end;

procedure TXcomBaseView.Draw;
var
  LX, LY, LNum, LOutline: Integer;
  LFacility: TXcomBaseFacility;
  LRule: TXcomRuleBaseFacility;
  LFrame: TXcomSurface;
  LCraftIndex, LCellX: Integer;
  LText: TXcomText;
begin
  inherited Draw;
  for LX := 0 to BASE_SIZE - 1 do
    for LY := 0 to BASE_SIZE - 1 do
    begin
      LFrame := FTexture.GetFrame(0);
      LFrame.X := LX * GRID_SIZE;
      LFrame.Y := LY * GRID_SIZE;
      LFrame.Blit(Self);
    end;
  LCraftIndex := 0;
  for LFacility in FBase.Facilities do
  begin
    LRule := RuleOf(LFacility);
    LNum := 0;
    for LY := LFacility.Y to LFacility.Y + LRule.Size - 1 do
      for LX := LFacility.X to LFacility.X + LRule.Size - 1 do
      begin
        LOutline := Max(LRule.Size * LRule.Size, 3);
        if LFacility.BuildTime = 0 then
          LFrame := FTexture.GetFrame(LRule.SpriteShape + LNum)
        else
          LFrame := FTexture.GetFrame(LRule.SpriteShape + LNum + LOutline);
        LFrame.X := LX * GRID_SIZE;
        LFrame.Y := LY * GRID_SIZE;
        LFrame.Blit(Self);
        Inc(LNum);
      end;
  end;
  // the corridors between two facilities that are built
  for LFacility in FBase.Facilities do
  begin
    if LFacility.BuildTime <> 0 then
      Continue;
    LRule := RuleOf(LFacility);
    LCellX := LFacility.X + LRule.Size;
    if LCellX < BASE_SIZE then
      for LY := LFacility.Y to LFacility.Y + LRule.Size - 1 do
        if Assigned(FFacilities[LCellX, LY]) and (FFacilities[LCellX, LY].BuildTime = 0) then
        begin
          LFrame := FTexture.GetFrame(7);
          LFrame.X := LCellX * GRID_SIZE - GRID_SIZE div 2;
          LFrame.Y := LY * GRID_SIZE;
          LFrame.Blit(Self);
        end;
    LY := LFacility.Y + LRule.Size;
    if LY < BASE_SIZE then
      for LX := LFacility.X to LFacility.X + LRule.Size - 1 do
        if Assigned(FFacilities[LX, LY]) and (FFacilities[LX, LY].BuildTime = 0) then
        begin
          LFrame := FTexture.GetFrame(8);
          LFrame.X := LX * GRID_SIZE;
          LFrame.Y := LY * GRID_SIZE - GRID_SIZE div 2;
          LFrame.Blit(Self);
        end;
  end;
  for LFacility in FBase.Facilities do
  begin
    LRule := RuleOf(LFacility);
    LNum := 0;
    for LY := LFacility.Y to LFacility.Y + LRule.Size - 1 do
      for LX := LFacility.X to LFacility.X + LRule.Size - 1 do
      begin
        if LRule.Size = 1 then
        begin
          LFrame := FTexture.GetFrame(LRule.SpriteFacility + LNum);
          LFrame.X := LX * GRID_SIZE;
          LFrame.Y := LY * GRID_SIZE;
          LFrame.Blit(Self);
        end;
        Inc(LNum);
      end;
    FHangars.Remove(LFacility);
    if (LFacility.BuildTime = 0) and (LRule.Crafts > 0) then
      if LCraftIndex < FBase.Crafts.Count then
      begin
        if FBase.Crafts[LCraftIndex].Status <> 'STR_OUT' then
        begin
          FHangars.AddOrSetValue(LFacility, FBase.Crafts[LCraftIndex]);
          LFrame := FTexture.GetFrame(FBase.Crafts[LCraftIndex].Rules.Sprite + 33);
          LFrame.X := LFacility.X * GRID_SIZE + (LRule.Size - 1) * GRID_SIZE div 2 + 2;
          LFrame.Y := LFacility.Y * GRID_SIZE + (LRule.Size - 1) * GRID_SIZE div 2 - 4;
          LFrame.Blit(Self);
        end;
        Inc(LCraftIndex);
      end;
    if LFacility.BuildTime > 0 then
    begin
      LText := TXcomText.Create(GRID_SIZE * LRule.Size, 16, 0, 0);
      try
        LText.SetPalette(@FColors[0], 0, 256);
        LText.InitText(FBig, FSmall, FLanguage);
        LText.X := LFacility.X * GRID_SIZE;
        LText.Y := LFacility.Y * GRID_SIZE + (GRID_SIZE * LRule.Size - 16) div 2;
        LText.SetBig;
        LText.SetAlign(haCenter);
        LText.SetColor(FCellColor);
        LText.SetText(IntToStr(LFacility.BuildTime));
        LText.Blit(Self);
      finally
        LText.Free;
      end;
    end;
  end;
end;

procedure TXcomBaseView.Blit(ATarget: TXcomSurface);
begin
  inherited Blit(ATarget);
  if Assigned(FSelector) then
    FSelector.Blit(ATarget);
end;

procedure TXcomBaseView.MouseOver(AAction: TXcomAction);
begin
  FGridX := Floor(AAction.RelativeXMouse / (GRID_SIZE * AAction.XScale));
  FGridY := Floor(AAction.RelativeYMouse / (GRID_SIZE * AAction.YScale));
  if (FGridX >= 0) and (FGridX < BASE_SIZE) and (FGridY >= 0) and (FGridY < BASE_SIZE) then
  begin
    FSelected := FFacilities[FGridX, FGridY];
    if FSelectorSize > 0 then
    begin
      if (FGridX + FSelectorSize - 1 < BASE_SIZE) and (FGridY + FSelectorSize - 1 < BASE_SIZE) then
      begin
        FSelector.X := X + FGridX * GRID_SIZE;
        FSelector.Y := Y + FGridY * GRID_SIZE;
        FSelector.Visible := True;
      end
      else
        FSelector.Visible := False;
    end;
  end
  else
  begin
    FSelected := nil;
    if FSelectorSize > 0 then
      FSelector.Visible := False;
  end;
  inherited MouseOver(AAction);
end;

procedure TXcomBaseView.MouseOut(AAction: TXcomAction);
begin
  FSelected := nil;
  if FSelectorSize > 0 then
    FSelector.Visible := False;
  inherited MouseOut(AAction);
end;

end.
