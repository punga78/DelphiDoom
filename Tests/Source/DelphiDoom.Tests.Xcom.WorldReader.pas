{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the xcom formats library - WORLD.DAT                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (no code of OpenXcom in this unit)                                           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Xcom.WorldReader;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Xcom.Types, DelphiDoom.Xcom.Intf;

type
  [TestFixture]
  [Category('xcom')]
  TTestXcomWorldReader = class(TObject)
  private
    FReader: IXcomWorldReader;
    function Polygon(const AValues: array of SmallInt): TBytes;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeConvertireGliOttaviDiGradoInRadianti;
    [Test]
    procedure DovrebbeLeggereUnTriangolo;
    [Test]
    procedure DovrebbeLeggereUnQuadrilatero;
    [Test]
    procedure DovrebbeLeggereLaTextureDallaParolaOtto;
    [Test]
    procedure DovrebbeLeggereLeCoordinateNegative;
    [Test]
    procedure DovrebbeIgnorareIByteDiUnPoligonoIncompleto;
    [Test]
    procedure DovrebbeLeggereIlGloboVuoto;
  end;

implementation

uses
  System.Math, DelphiDoom.Xcom.Factory;

{ TTestXcomWorldReader }

function TTestXcomWorldReader.Polygon(const AValues: array of SmallInt): TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, Length(AValues) * 2);
  for LIndex := 0 to High(AValues) do
  begin
    Result[LIndex * 2] := Byte(AValues[LIndex] and $FF);
    Result[LIndex * 2 + 1] := Byte((AValues[LIndex] shr 8) and $FF);
  end;
end;

procedure TTestXcomWorldReader.Setup;
begin
  FReader := TXcomFactory.CreateWorldReader;
end;

procedure TTestXcomWorldReader.TearDown;
begin
  FReader := nil;
end;

procedure TTestXcomWorldReader.DovrebbeConvertireGliOttaviDiGradoInRadianti;
begin
  Assert.AreEqual(0.0, FReader.ToRadians(0), 0.0);
  Assert.AreEqual(Pi, FReader.ToRadians(1440), 1E-12, '1440 * 0.125 = 180 degrees');
  Assert.AreEqual(Pi / 180.0, FReader.ToRadians(8), 1E-15, '8 eighths are a degree');
  Assert.AreEqual(-Pi / 2, FReader.ToRadians(-720), 1E-12);
end;

procedure TTestXcomWorldReader.DovrebbeLeggereUnTriangolo;
var
  LPolygons: TArray<TXcomWorldPolygon>;
begin
  LPolygons := FReader.Read(Polygon([8, 16, 24, 32, 40, 48, -1, 0, 5, 0]));
  Assert.AreEqual(1, Integer(Length(LPolygons)));
  Assert.AreEqual(3, LPolygons[0].Points);
  Assert.AreEqual(FReader.ToRadians(40), LPolygons[0].Longitude[2], 0.0);
  Assert.AreEqual(FReader.ToRadians(48), LPolygons[0].Latitude[2], 0.0);
end;

procedure TTestXcomWorldReader.DovrebbeLeggereUnQuadrilatero;
var
  LPolygons: TArray<TXcomWorldPolygon>;
begin
  LPolygons := FReader.Read(Polygon([1, 2, 3, 4, 5, 6, 7, 8, 9, 0]));
  Assert.AreEqual(4, LPolygons[0].Points);
  Assert.AreEqual(FReader.ToRadians(7), LPolygons[0].Longitude[3], 0.0);
  Assert.AreEqual(FReader.ToRadians(8), LPolygons[0].Latitude[3], 0.0);
end;

procedure TTestXcomWorldReader.DovrebbeLeggereLaTextureDallaParolaOtto;
begin
  Assert.AreEqual(9, FReader.Read(Polygon([1, 2, 3, 4, 5, 6, 7, 8, 9, 0]))[0].Texture);
  Assert.AreEqual(-3, FReader.Read(Polygon([1, 2, 3, 4, 5, 6, -1, 8, -3, 0]))[0].Texture);
end;

procedure TTestXcomWorldReader.DovrebbeLeggereLeCoordinateNegative;
begin
  Assert.AreEqual(-Pi / 180.0, FReader.Read(Polygon([-8, 0, 0, 0, 0, 0, -1, 0, 0, 0]))[0].Longitude[0], 1E-15);
end;

procedure TTestXcomWorldReader.DovrebbeIgnorareIByteDiUnPoligonoIncompleto;
var
  LBytes: TBytes;
begin
  LBytes := Polygon([1, 2, 3, 4, 5, 6, -1, 8, 9, 0]);
  SetLength(LBytes, 31);
  Assert.AreEqual(1, Integer(Length(FReader.Read(LBytes))));
end;

procedure TTestXcomWorldReader.DovrebbeLeggereIlGloboVuoto;
begin
  Assert.AreEqual(0, Integer(Length(FReader.Read(nil))));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomWorldReader);

end.
