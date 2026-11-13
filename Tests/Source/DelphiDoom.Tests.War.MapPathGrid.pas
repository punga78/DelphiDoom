{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - the occupation grid of the map       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.MapPathGrid;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.War.Types, DelphiDoom.War.Map.PathGrid;

type
  [TestFixture]
  [Category('war')]
  TTestWarPathGrid = class(TObject)
  private
    FGrid: TWarPathGrid;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeRendereFissiIlLegnoEdAcquaELiberoIlResto;
    [Test]
    procedure DovrebbeSollevareEccezioneSeLaMappaECorta;
    [Test]
    procedure DovrebbeScrivereLIdentificativoNeiDodiciBitAlti;
    [Test]
    procedure DovrebbeTroncareLIdentificativoASedici;
    [Test]
    procedure DovrebbeLiberareLeCaselle;
    [Test]
    procedure DovrebbeTagliareIlRettangoloAlBordoDellaMappa;
    [Test]
    procedure NonDovrebbeFareNienteSeLaPartenzaEFuoriDallaMappa;
    [Test]
    procedure DovrebbeSollevareEccezioneSeUnaCasellaEFuoriDallaMappa;
    [Test]
    procedure DovrebbeDireSeUnaCasellaEAccessibile;
    [Test]
    procedure DovrebbeDireSeUnaCasellaEFissa;
    [Test]
    procedure DovrebbeDareLaMappaIntera;
  end;

implementation

uses
  DelphiDoom.War.Level.Types, DelphiDoom.War.Map.Types, DelphiDoom.Tests.War.MapSupport;

{ TTestWarPathGrid }

procedure TTestWarPathGrid.Setup;
var
  LPassable: TArray<Word>;
begin
  LPassable := TMapFixtures.EmptyPassable;
  LPassable[0] := 128;
  LPassable[1] := 64;
  LPassable[2] := 16;
  FGrid := TWarPathGrid.Create(LPassable);
end;

procedure TTestWarPathGrid.TearDown;
begin
  FGrid.Free;
end;

procedure TTestWarPathGrid.DovrebbeRendereFissiIlLegnoEdAcquaELiberoIlResto;
begin
  Assert.AreEqual<Integer>(WAR_PATH_STATIC, FGrid.GetTileValueType(0, 0));
  Assert.AreEqual<Integer>(WAR_PATH_STATIC, FGrid.GetTileValueType(1, 0));
  Assert.AreEqual<Integer>(WAR_PATH_EMPTY, FGrid.GetTileValueType(2, 0));
  Assert.AreEqual<Integer>(WAR_PATH_EMPTY, FGrid.GetTileValueType(3, 0));
  Assert.AreEqual<Integer>(0, Integer(FGrid.GetTileEntityId(0, 0)));
end;

procedure TTestWarPathGrid.DovrebbeSollevareEccezioneSeLaMappaECorta;
begin
  Assert.WillRaise(
    procedure
    begin
      TWarPathGrid.Create(nil).Free;
    end, EWarException);
end;

procedure TTestWarPathGrid.DovrebbeScrivereLIdentificativoNeiDodiciBitAlti;
begin
  FGrid.SetStaticEntity(10, 20, 2, 3, 77);
  Assert.AreEqual<Integer>(77, Integer(FGrid.GetTileEntityId(11, 22)));
  Assert.AreEqual<Integer>((77 shl 4) or 1, Integer(FGrid.GetTileValue(10, 20)));
  Assert.IsTrue(FGrid.IsStatic(10, 20));
  Assert.IsFalse(FGrid.IsEmpty(11, 22));
  Assert.IsTrue(FGrid.IsEmpty(12, 20));
  Assert.IsTrue(FGrid.IsEmpty(10, 23));
end;

procedure TTestWarPathGrid.DovrebbeTroncareLIdentificativoASedici;
begin
  // the number is made of 16 bits, as in the original: the id 4097 comes back as 1
  FGrid.SetStaticEntity(5, 5, 1, 1, 4097);
  Assert.AreEqual<Integer>(1, Integer(FGrid.GetTileEntityId(5, 5)));
end;

procedure TTestWarPathGrid.DovrebbeLiberareLeCaselle;
begin
  FGrid.SetStaticEntity(10, 10, 3, 3, 9);
  FGrid.SetFreeTiles(10, 10, 3, 3);
  Assert.IsTrue(FGrid.IsEmpty(11, 11));
  Assert.AreEqual<Integer>(0, Integer(FGrid.GetTileValue(12, 12)));
end;

procedure TTestWarPathGrid.DovrebbeTagliareIlRettangoloAlBordoDellaMappa;
begin
  FGrid.SetStaticEntity(62, 62, 5, 5, 3);
  Assert.IsTrue(FGrid.IsStatic(63, 63));
  Assert.IsTrue(FGrid.IsStatic(62, 63));
end;

procedure TTestWarPathGrid.NonDovrebbeFareNienteSeLaPartenzaEFuoriDallaMappa;
begin
  FGrid.SetStaticEntity(-1, 5, 3, 3, 3);
  FGrid.SetStaticEntity(5, 64, 3, 3, 3);
  Assert.IsTrue(FGrid.IsEmpty(0, 5));
  Assert.IsTrue(FGrid.IsEmpty(0, 7));
end;

procedure TTestWarPathGrid.DovrebbeSollevareEccezioneSeUnaCasellaEFuoriDallaMappa;
begin
  Assert.IsFalse(TWarPathGrid.IsInside(64, 0));
  Assert.IsFalse(TWarPathGrid.IsInside(0, -1));
  Assert.IsTrue(TWarPathGrid.IsInside(63, 63));
  Assert.WillRaise(
    procedure
    begin
      FGrid.IsEmpty(64, 0);
    end, EWarException);
  Assert.WillRaise(
    procedure
    begin
      FGrid.GetTileValue(0, -1);
    end, EWarException);
end;

procedure TTestWarPathGrid.DovrebbeDireSeUnaCasellaEAccessibile;
begin
  // the corner (0, 0) is wood, (1, 0) is water, (2, 0) empty: (1, 0) touches an empty tile, (0, 0) touches only the water and the empty (0, 1)
  Assert.IsTrue(FGrid.IsTileAccessible(1, 0));
  FGrid.SetStaticEntity(10, 10, 3, 3, 4);
  Assert.IsTrue(FGrid.IsTileAccessible(11, 11) = False);
  Assert.IsTrue(FGrid.IsTileAccessible(10, 10));
end;

procedure TTestWarPathGrid.DovrebbeDireSeUnaCasellaEFissa;
begin
  Assert.IsTrue(FGrid.IsStatic(0, 0));
  Assert.IsFalse(FGrid.IsStatic(30, 30));
end;

procedure TTestWarPathGrid.DovrebbeDareLaMappaIntera;
var
  LValues: TArray<Word>;
begin
  LValues := FGrid.ToArray;
  Assert.AreEqual<Integer>(WAR_MAP_TILE_COUNT, Length(LValues));
  Assert.AreEqual<Integer>(1, Integer(LValues[0]));
  Assert.AreEqual<Integer>(0, Integer(LValues[2]));
end;

end.
