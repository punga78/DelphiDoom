{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the video library - the grid of tiles of a page        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Video.TileGrid;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Video.TileGrid;

type
  [TestFixture]
  [Category('video')]
  TTestVideoTileGrid = class(TObject)
  strict private
    /// <summary>The loops of V_TileScreen8 as they were, copied from the old text (the oracle)</summary>
    class function OldPositions(const AWidth, AHeight, ALeft, ATop: Integer): string; static;
    class function Describe(const APoints: TArray<TVideoTilePosition>): string; static;
  public
    [Test]
    procedure DovrebbeIniziareDaZeroSenzaScostamento;
    [Test]
    procedure DovrebbeIniziareFuoriDallaPaginaConLoScostamento;
    [Test]
    procedure DovrebbeRiempireLaPaginaColonnaPerColonna;
    [Test]
    procedure DovrebbeDareUnaListaVuotaSeLaPatchNonHaDimensione;
    [Test]
    procedure DovrebbeRiprodurreIlCicloDelVecchioCodice;
  end;

implementation

class function TTestVideoTileGrid.OldPositions(const AWidth, AHeight, ALeft, ATop: Integer): string;
var
  LX, LY, LStartX, LStartY: Integer;
begin
  Result := '';
  if ALeft = 0 then
    LStartX := 0
  else
    LStartX := -AWidth;
  if ATop = 0 then
    LStartY := 0
  else
    LStartY := -AHeight;
  LX := LStartX;
  while LX < 320 do
  begin
    LY := LStartY;
    while LY < 200 do
    begin
      Result := Result + Format('%d,%d;', [LX, LY]);
      LY := LY + AHeight;
    end;
    LX := LX + AWidth;
  end;
end;

class function TTestVideoTileGrid.Describe(const APoints: TArray<TVideoTilePosition>): string;
var
  LPoint: TVideoTilePosition;
begin
  Result := '';
  for LPoint in APoints do
    Result := Result + Format('%d,%d;', [LPoint.X, LPoint.Y]);
end;

procedure TTestVideoTileGrid.DovrebbeIniziareDaZeroSenzaScostamento;
begin
  Assert.AreEqual(0, TVideoTileGrid.Start(0, 64));
end;

procedure TTestVideoTileGrid.DovrebbeIniziareFuoriDallaPaginaConLoScostamento;
begin
  Assert.AreEqual(-64, TVideoTileGrid.Start(5, 64));
  Assert.AreEqual(-64, TVideoTileGrid.Start(-5, 64));
end;

procedure TTestVideoTileGrid.DovrebbeRiempireLaPaginaColonnaPerColonna;
var
  LPoints: TArray<TVideoTilePosition>;
begin
  LPoints := TVideoTileGrid.Positions(160, 100, 0, 0, 320, 200);
  Assert.AreEqual(4, Length(LPoints));
  Assert.AreEqual('0,0;0,100;160,0;160,100;', Describe(LPoints));
end;

procedure TTestVideoTileGrid.DovrebbeDareUnaListaVuotaSeLaPatchNonHaDimensione;
begin
  Assert.AreEqual(0, Length(TVideoTileGrid.Positions(0, 64, 0, 0, 320, 200)));
  Assert.AreEqual(0, Length(TVideoTileGrid.Positions(64, 0, 0, 0, 320, 200)));
  Assert.AreEqual(0, Length(TVideoTileGrid.Positions(-3, 64, 1, 1, 320, 200)));
end;

procedure TTestVideoTileGrid.DovrebbeRiprodurreIlCicloDelVecchioCodice;
const
  CSizes: array[0..8] of Integer = (1, 7, 16, 64, 100, 128, 200, 320, 321);
var
  LWidth, LHeight, LLeft, LTop: Integer;
  LIndexW, LIndexH: Integer;
begin
  for LIndexW := Low(CSizes) to High(CSizes) do
    for LIndexH := Low(CSizes) to High(CSizes) do
      for LLeft := 0 to 1 do
        for LTop := 0 to 1 do
        begin
          LWidth := CSizes[LIndexW];
          LHeight := CSizes[LIndexH];
          Assert.AreEqual(OldPositions(LWidth, LHeight, LLeft, LTop),
            Describe(TVideoTileGrid.Positions(LWidth, LHeight, LLeft, LTop, 320, 200)),
            Format('%dx%d offset %d,%d', [LWidth, LHeight, LLeft, LTop]));
        end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestVideoTileGrid);

end.
