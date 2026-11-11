{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape states library - ScannerView of OpenXcom (the   }
{  blips of the motion scanner)                                                 }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattleStates.ScannerView;

interface

uses
  System.SysUtils, DelphiDoom.XcomSurface.SurfaceSet, DelphiDoom.XcomEngine.InteractiveSurface,
  DelphiDoom.XcomBattle.Model, DelphiDoom.XcomBattle.SavedBattleGame;

type
  /// <summary>
  ///   The screen of the motion scanner: the units that moved in the 19 x 19 tiles around the unit that scans, on
  ///   every level, as blips of DETBLOB.DAT (the bigger the more they moved) that blink in two frames, and the arrow
  ///   of the direction the unit faces in the middle. Nothing is owned
  /// </summary>
  TXcomScannerView = class(TXcomInteractiveSurface)
  strict private
    FSet: TXcomSurfaceSet;
    FBattle: TXcomSavedBattleGame;
    FUnit: TXcomBattleUnit;
    FFrame: Integer;
  public
    const
      /// <summary>The tiles seen on every side of the unit</summary>
      RANGE = 9;
      /// <summary>The pixels of a tile on the scanner</summary>
      CELL = 8;
      /// <summary>The motion points of a step of the size of a blip</summary>
      MOTION_STEP = 5;
      /// <summary>The biggest blip</summary>
      MAX_BLIP = 5;
      /// <summary>The first frame of the arrows of the eight directions</summary>
      ARROW_FRAME = 7;
    /// <param name="ASet">DETBLOB.DAT; nil: nothing is drawn</param>
    /// <param name="AUnit">The unit that uses the scanner</param>
    constructor Create(AWidth, AHeight, AX, AY: Integer; ASet: TXcomSurfaceSet; ABattle: TXcomSavedBattleGame;
      AUnit: TXcomBattleUnit);
    procedure Draw; override;
    /// <summary>animate: the other frame of the blips</summary>
    procedure Animate;
    /// <summary>The frame of the blink (0 or 1)</summary>
    property Frame: Integer read FFrame;
  end;

implementation

uses
  DelphiDoom.XcomMod.MapBlock, DelphiDoom.XcomSurface.Surface, DelphiDoom.XcomSurface.Shade;

constructor TXcomScannerView.Create(AWidth, AHeight, AX, AY: Integer; ASet: TXcomSurfaceSet;
  ABattle: TXcomSavedBattleGame; AUnit: TXcomBattleUnit);
begin
  inherited Create(AWidth, AHeight, AX, AY);
  FSet := ASet;
  FBattle := ABattle;
  FUnit := AUnit;
  Redraw := True;
end;

procedure TXcomScannerView.Draw;
var
  LX: Integer;
  LY: Integer;
  LZ: Integer;
  LTile: TXcomTile;
  LFrame: Integer;
  LSurface: TXcomSurface;
begin
  // ScannerView::draw clears and leaves the surface to be drawn again at every blit
  Clear;
  if not Assigned(FSet) then
    Exit;
  for LX := -RANGE to RANGE do
    for LY := -RANGE to RANGE do
      for LZ := 0 to FBattle.MapSizeZ - 1 do
      begin
        LTile := FBattle.TileAt(TXcomPosition.Make(FUnit.Position.X + LX, FUnit.Position.Y + LY, LZ));
        if Assigned(LTile) and Assigned(LTile.CurrentUnit) and (LTile.CurrentUnit.MotionPoints <> 0) then
        begin
          LFrame := LTile.CurrentUnit.MotionPoints div MOTION_STEP;
          if LFrame >= 0 then
          begin
            if LFrame > MAX_BLIP then
              LFrame := MAX_BLIP;
            LSurface := FSet.GetFrame(LFrame + FFrame);
            if Assigned(LSurface) then
              TXcomSurfaceShader.Blit(LSurface, Self, X + (RANGE + LX) * CELL - 4, Y + (RANGE + LY) * CELL - 4, 0);
          end;
        end;
      end;
  // the arrow of the direction the unit is pointed
  LSurface := FSet.GetFrame(ARROW_FRAME + FUnit.Direction);
  if Assigned(LSurface) then
    TXcomSurfaceShader.Blit(LSurface, Self, X + RANGE * CELL - 4, Y + RANGE * CELL - 4, 0);
end;

procedure TXcomScannerView.Animate;
begin
  Inc(FFrame);
  if FFrame > 1 then
    FFrame := 0;
  Redraw := True;
end;

end.