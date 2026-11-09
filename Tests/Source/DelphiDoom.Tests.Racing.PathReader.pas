{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TRacingPathReader                                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Racing.PathReader;

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  [TestFixture]
  [Category('racing')]
  TTestRacingPathReader = class(TObject)
  strict private
    function Things(const AValues: array of SmallInt): TBytes;
    function PathPoints(const ASpeeds: array of Integer): TBytes;
  public
    [Test]
    procedure DovrebbeLeggereIPuntiDaiLump;
    [Test]
    procedure DovrebbeSaltareLeCoseCheNonSonoDelPercorso;
    [Test]
    procedure DovrebbeDividereLaVelocitaDelLump;
    [Test]
    procedure DovrebbeLeggerePiuPuntiDelleCoseSenzaFermarsi;
    [Test]
    procedure DovrebbeFermarsiQuandoIlLumpDelPercorsoFinisce;
    [Test]
    procedure DovrebbeLeggereIPuntiDaUnTesto;
    [Test]
    procedure DovrebbeIgnorareICommentiEIlTestoIncompleto;
    [Test]
    procedure DovrebbeLeggereZeroPerUnNumeroSbagliato;
    [Test]
    procedure DovrebbeDareUnElencoVuotoPerDueLumpVuoti;
  end;

implementation

uses
  DelphiDoom.Racing.Types, DelphiDoom.Racing.PathReader;

{ TTestRacingPathReader }

function TTestRacingPathReader.Things(const AValues: array of SmallInt): TBytes;
begin
  SetLength(Result, Length(AValues) * SizeOf(SmallInt));
  if Length(AValues) > 0 then
    Move(AValues[0], Result[0], Length(Result));
end;

function TTestRacingPathReader.PathPoints(const ASpeeds: array of Integer): TBytes;
var
  LIndex, LZero: Integer;
begin
  SetLength(Result, Length(ASpeeds) * 16);
  LZero := 0;
  for LIndex := 0 to High(ASpeeds) do
  begin
    Move(LZero, Result[LIndex * 16], 4);
    Move(LZero, Result[LIndex * 16 + 4], 4);
    Move(LZero, Result[LIndex * 16 + 8], 4);
    Move(ASpeeds[LIndex], Result[LIndex * 16 + 12], 4);
  end;
end;

procedure TTestRacingPathReader.DovrebbeLeggereIPuntiDaiLump;
var
  LPoints: TArray<TRacingPathThing>;
begin
  // x, y, angle, type, options for each thing
  LPoints := TRacingPathReader.FromLumps(Things([100, 200, 90, 512, 7, -50, 60, 180, 512, 7]), PathPoints([0, 0]));
  Assert.AreEqual(2, Length(LPoints));
  Assert.AreEqual(100, LPoints[0].X);
  Assert.AreEqual(200, LPoints[0].Y);
  Assert.AreEqual(90, LPoints[0].Angle);
  Assert.AreEqual(-50, LPoints[1].X);
  Assert.AreEqual(180, LPoints[1].Angle);
end;

procedure TTestRacingPathReader.DovrebbeSaltareLeCoseCheNonSonoDelPercorso;
var
  LPoints: TArray<TRacingPathThing>;
begin
  LPoints := TRacingPathReader.FromLumps(
    Things([1, 1, 0, 1, 7, 100, 200, 90, 512, 7, 3, 3, 0, 241, 7]), PathPoints([0]));
  Assert.AreEqual(1, Length(LPoints));
  Assert.AreEqual(100, LPoints[0].X);
end;

procedure TTestRacingPathReader.DovrebbeDividereLaVelocitaDelLump;
var
  LPoints: TArray<TRacingPathThing>;
begin
  LPoints := TRacingPathReader.FromLumps(Things([0, 0, 0, 512, 7, 0, 0, 0, 512, 7]), PathPoints([102400, 10239]));
  Assert.AreEqual(10, LPoints[0].Speed);
  Assert.AreEqual(0, LPoints[1].Speed);
end;

procedure TTestRacingPathReader.DovrebbeLeggerePiuPuntiDelleCoseSenzaFermarsi;
var
  LPoints: TArray<TRacingPathThing>;
begin
  // Three points in the lump of the path, two things: the third point is not read
  LPoints := TRacingPathReader.FromLumps(Things([0, 0, 0, 512, 7, 0, 0, 0, 512, 7]), PathPoints([10240, 20480, 30720]));
  Assert.AreEqual(2, Length(LPoints));
  Assert.AreEqual(1, LPoints[0].Speed);
  Assert.AreEqual(2, LPoints[1].Speed);
end;

procedure TTestRacingPathReader.DovrebbeFermarsiQuandoIlLumpDelPercorsoFinisce;
var
  LPoints: TArray<TRacingPathThing>;
begin
  LPoints := TRacingPathReader.FromLumps(Things([0, 0, 0, 512, 7, 0, 0, 0, 512, 7, 0, 0, 0, 512, 7]), PathPoints([10240]));
  Assert.AreEqual(1, Length(LPoints));
end;

procedure TTestRacingPathReader.DovrebbeLeggereIPuntiDaUnTesto;
var
  LPoints: TArray<TRacingPathThing>;
begin
  LPoints := TRacingPathReader.FromText('10 20 90 100' + #13#10 + '-30, 40, 180, 120');
  Assert.AreEqual(2, Length(LPoints));
  Assert.AreEqual(10, LPoints[0].X);
  Assert.AreEqual(20, LPoints[0].Y);
  Assert.AreEqual(90, LPoints[0].Angle);
  Assert.AreEqual(100, LPoints[0].Speed);
  Assert.AreEqual(-30, LPoints[1].X);
  Assert.AreEqual(120, LPoints[1].Speed);
end;

procedure TTestRacingPathReader.DovrebbeIgnorareICommentiEIlTestoIncompleto;
var
  LPoints: TArray<TRacingPathThing>;
begin
  LPoints := TRacingPathReader.FromText('// the path' + #10 + '1 2 3 4 // a point' + #10 + '5 6 7');
  Assert.AreEqual(1, Length(LPoints));
  Assert.AreEqual(4, LPoints[0].Speed);
end;

procedure TTestRacingPathReader.DovrebbeLeggereZeroPerUnNumeroSbagliato;
var
  LPoints: TArray<TRacingPathThing>;
begin
  LPoints := TRacingPathReader.FromText('abc 2 3 4');
  Assert.AreEqual(1, Length(LPoints));
  Assert.AreEqual(0, LPoints[0].X);
  Assert.AreEqual(2, LPoints[0].Y);
end;

procedure TTestRacingPathReader.DovrebbeDareUnElencoVuotoPerDueLumpVuoti;
begin
  Assert.AreEqual(0, Length(TRacingPathReader.FromLumps(nil, nil)));
  Assert.AreEqual(0, Length(TRacingPathReader.FromText('')));
end;

end.
