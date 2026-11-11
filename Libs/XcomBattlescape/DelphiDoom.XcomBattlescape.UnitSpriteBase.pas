{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape library - what every drawing routine of a      }
{  unit shares (UnitSprite of OpenXcom: the unit, the objects in its hands,    }
{  the sets of frames, drawRecolored and sortRifles)                           }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattlescape.UnitSpriteBase;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.XcomSurface.Surface, DelphiDoom.XcomSurface.SurfaceSet,
  DelphiDoom.XcomBattle.Model;

type
  /// <summary>
  ///   The state of UnitSprite and the three things its drawing routines share: the blit of a frame, the blit with
  ///   the colors of the unit and the choice of the hand that holds a two handed weapon. The routines are in the
  ///   classes that derive from this one (TXcomUnitSpriteUfo, TXcomUnitSprite)
  /// </summary>
  TXcomUnitSpriteBase = class
  protected
    const
      /// <summary>The sprites are drawn on a surface of double width</summary>
      OFF_X_SPRITE = 16;
    var
      FUnit: TXcomBattleUnit;
      FItemR: TXcomBattleItem;
      FItemL: TXcomBattleItem;
      FUnitSurface: TXcomSurfaceSet;
      FItemSurfaceR: TXcomSurfaceSet;
      FItemSurfaceL: TXcomSurfaceSet;
      FPart: Integer;
      FAnimationFrame: Integer;
      FDrawingRoutine: Integer;
      FHelmet: Boolean;
      FTarget: TXcomSurface;
    /// <summary>drawRecolored: the frame at its position with the color groups of the unit replaced</summary>
    procedure DrawRecolored(const ASource: TXcomSurface);
    /// <summary>Surface::blit of a frame at its position</summary>
    procedure Blit(const ASource: TXcomSurface);
    /// <summary>sortRifles: with a two handed weapon only one hand holds an object</summary>
    procedure SortRifles;
  public
    /// <param name="AHelmet">Whether the battle is underwater (the aquanauts wear a helmet)</param>
    constructor Create(AHelmet: Boolean);
    /// <summary>setBattleUnit</summary>
    procedure SetBattleUnit(const AUnit: TXcomBattleUnit; APart: Integer);
    /// <summary>setSurfaces</summary>
    procedure SetSurfaces(const AUnitSurface, AItemSurfaceR, AItemSurfaceL: TXcomSurfaceSet);
    /// <summary>setAnimationFrame</summary>
    procedure SetAnimationFrame(AFrame: Integer);
  end;

implementation

uses
  DelphiDoom.XcomMod.Armor, DelphiDoom.XcomMod.RuleItem, DelphiDoom.XcomBattle.Types;

constructor TXcomUnitSpriteBase.Create(AHelmet: Boolean);
begin
  inherited Create;
  FHelmet := AHelmet;
end;

procedure TXcomUnitSpriteBase.SetSurfaces(const AUnitSurface, AItemSurfaceR, AItemSurfaceL: TXcomSurfaceSet);
begin
  FUnitSurface := AUnitSurface;
  FItemSurfaceR := AItemSurfaceR;
  FItemSurfaceL := AItemSurfaceL;
end;

procedure TXcomUnitSpriteBase.SetAnimationFrame(AFrame: Integer);
begin
  FAnimationFrame := AFrame;
end;

procedure TXcomUnitSpriteBase.SetBattleUnit(const AUnit: TXcomBattleUnit; APart: Integer);
begin
  FUnit := AUnit;
  FDrawingRoutine := FUnit.Armor.DrawingRoutine;
  FPart := APart;
  FItemR := FUnit.GetItem('STR_RIGHT_HAND');
  if Assigned(FItemR) and FItemR.Rules.FixedWeapon then
    FItemR := nil;
  FItemL := FUnit.GetItem('STR_LEFT_HAND');
  if Assigned(FItemL) and FItemL.Rules.FixedWeapon then
    FItemL := nil;
end;

procedure TXcomUnitSpriteBase.Blit(const ASource: TXcomSurface);
begin
  ASource.Blit(FTarget);
end;

procedure TXcomUnitSpriteBase.DrawRecolored(const ASource: TXcomSurface);
var
  LPairs: TArray<TPair<Integer, Integer>>;
  LX: Integer;
  LY: Integer;
  LSource: Byte;
  LDestX: Integer;
  LDestY: Integer;
  LIndex: Integer;
  LFound: Boolean;
begin
  LPairs := FUnit.RecolorPairs;
  if Length(LPairs) = 0 then
  begin
    Blit(ASource);
    Exit;
  end;
  // ColorReplace: the pixels of a color group in the list take the new group, the others stay
  for LY := 0 to ASource.Height - 1 do
    for LX := 0 to ASource.Width - 1 do
    begin
      LSource := ASource.GetPixel(LX, LY);
      LDestX := LX + ASource.X;
      LDestY := LY + ASource.Y;
      if (LSource = 0) or (LDestX < 0) or (LDestY < 0) or (LDestX >= FTarget.Width) or (LDestY >= FTarget.Height) then
        Continue;
      LFound := False;
      for LIndex := 0 to High(LPairs) do
        if (LSource and $F0) = LPairs[LIndex].Key then
        begin
          FTarget.SetPixel(LDestX, LDestY, Byte(LPairs[LIndex].Value + (LSource and $0F)));
          LFound := True;
          Break;
        end;
      if not LFound then
        FTarget.SetPixel(LDestX, LDestY, LSource);
    end;
end;

procedure TXcomUnitSpriteBase.SortRifles;
begin
  if Assigned(FItemR) and FItemR.Rules.TwoHanded then
  begin
    if Assigned(FItemL) and FItemL.Rules.TwoHanded then
    begin
      if FUnit.GetActiveHand = 'STR_LEFT_HAND' then
        FItemR := FItemL;
      FItemL := nil;
    end
    else if FUnit.Status <> STATUS_AIMING then
      FItemL := nil;
  end
  else if Assigned(FItemL) and FItemL.Rules.TwoHanded then
  begin
    if FUnit.Status <> STATUS_AIMING then
      FItemR := nil;
  end;
end;

end.
