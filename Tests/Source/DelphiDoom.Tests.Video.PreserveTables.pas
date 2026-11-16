{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the video library - preserve tables and screen layout   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Video.PreserveTables;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Video.PreserveTables,
  DelphiDoom.Video.ScreenLayout;

type
  [TestFixture]
  [Category('video')]
  TTestVideoPreserveTables = class(TObject)
  strict private
    FTables: TVideoPreserveTables;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDareLeCoordinateStesseSeLoSchermoE320x200;
    [Test]
    procedure DovrebbeRiprodurreLaFormulaDelVecchioCodice;
    [Test]
    procedure DovrebbeUsareLaLarghezzaDellaSorgenteNelleDueFormeDiX;
    [Test]
    procedure DovrebbeDareIlBordoOltreLaSorgente;
    [Test]
    procedure DovrebbeCalcolareIMoltiplicatoriInteri;
    [Test]
    procedure DovrebbeGestireUnaSorgenteNonStandard;
  end;

  [TestFixture]
  [Category('video')]
  TTestVideoScreenLayout = class(TObject)
  public
    [Test]
    procedure DovrebbeSostituireLaDimensioneMenoUno;
    [Test]
    procedure DovrebbeCalcolareLaDimensioneInByte;
    [Test]
    procedure DovrebbeDareLAreaGLDi512SottoI1024;
    [Test]
    procedure DovrebbeDareLAreaGLDi1024DaI1024;
    [Test]
    procedure DovrebbeDareQuadrataLAreaGLSeLoSchermoESvolto;
  end;

implementation

{ TTestVideoPreserveTables }

procedure TTestVideoPreserveTables.Setup;
begin
  FTables := TVideoPreserveTables.Create;
end;

procedure TTestVideoPreserveTables.TearDown;
begin
  FreeAndNil(FTables);
end;

procedure TTestVideoPreserveTables.DovrebbeDareLeCoordinateStesseSeLoSchermoE320x200;
var
  LIndex: Integer;
begin
  FTables.Calculate(320, 200);
  for LIndex := 1 to 319 do
    Assert.AreEqual(LIndex, FTables.MapX(LIndex));
  for LIndex := 1 to 199 do
    Assert.AreEqual(LIndex, FTables.MapY(LIndex));
end;

procedure TTestVideoPreserveTables.DovrebbeRiprodurreLaFormulaDelVecchioCodice;
var
  LIndex: Integer;
begin
  FTables.Calculate(1024, 768);
  for LIndex := 1 to 319 do
    Assert.AreEqual<Integer>(Trunc(LIndex * 1024 / 320), FTables.MapX(LIndex));
  for LIndex := 1 to 199 do
    Assert.AreEqual<Integer>(Trunc(LIndex * 768 / 200), FTables.MapY(LIndex));
end;

procedure TTestVideoPreserveTables.DovrebbeUsareLaLarghezzaDellaSorgenteNelleDueFormeDiX;
var
  LIndex: Integer;
begin
  FTables.Calculate(1280, 800);
  for LIndex := 1 to 425 do
    Assert.AreEqual<Integer>(Trunc(LIndex * 1280 / 426), FTables.MapX(426, LIndex));
  for LIndex := 1 to 319 do
    Assert.AreEqual(FTables.MapX(LIndex), FTables.MapX(320, LIndex));
end;

procedure TTestVideoPreserveTables.DovrebbeDareIlBordoOltreLaSorgente;
begin
  FTables.Calculate(800, 600);
  Assert.AreEqual(0, FTables.MapX(0));
  Assert.AreEqual(0, FTables.MapX(-5));
  Assert.AreEqual(800, FTables.MapX(320));
  Assert.AreEqual(800, FTables.MapX(1000));
  Assert.AreEqual(800, FTables.MapX(426, 426));
  Assert.AreEqual(0, FTables.MapY(0));
  Assert.AreEqual(600, FTables.MapY(200));
end;

procedure TTestVideoPreserveTables.DovrebbeCalcolareIMoltiplicatoriInteri;
begin
  FTables.Calculate(640, 400);
  Assert.AreEqual(2, FTables.WidthMultiplier);
  Assert.AreEqual(2, FTables.HeightMultiplier);
  FTables.Calculate(800, 600);
  Assert.AreEqual(0, FTables.WidthMultiplier);
  Assert.AreEqual(3, FTables.HeightMultiplier);
end;

procedure TTestVideoPreserveTables.DovrebbeGestireUnaSorgenteNonStandard;
begin
  FTables.Calculate(1000, 600);
  Assert.AreEqual<Integer>(Trunc(100 * 1000 / 640), FTables.MapX(640, 100));
  Assert.AreEqual(1000, FTables.MapX(640, 640));
end;

{ TTestVideoScreenLayout }

procedure TTestVideoScreenLayout.DovrebbeSostituireLaDimensioneMenoUno;
begin
  Assert.AreEqual(640, TVideoScreenLayout.Resolve(-1, 640));
  Assert.AreEqual(320, TVideoScreenLayout.Resolve(320, 640));
end;

procedure TTestVideoScreenLayout.DovrebbeCalcolareLaDimensioneInByte;
begin
  Assert.AreEqual(640 * 400 * 4, TVideoScreenLayout.ByteSize(-1, -1, 4, 640, 400));
  Assert.AreEqual(320 * 200, TVideoScreenLayout.ByteSize(320, 200, 1, 640, 400));
end;

procedure TTestVideoScreenLayout.DovrebbeDareLAreaGLDi512SottoI1024;
var
  LSize: TVideoGlDrawSize;
begin
  LSize := TVideoScreenLayout.GlDrawSize(800, 600);
  Assert.AreEqual(512, LSize.Width);
  Assert.AreEqual<Integer>(Round(600 * 512 / 800), LSize.Height);
  Assert.AreEqual(512, LSize.TextureWidth);
  Assert.AreEqual(512, LSize.TextureHeight);
end;

procedure TTestVideoScreenLayout.DovrebbeDareLAreaGLDi1024DaI1024;
var
  LSize: TVideoGlDrawSize;
begin
  LSize := TVideoScreenLayout.GlDrawSize(1920, 1080);
  Assert.AreEqual(1024, LSize.Width);
  Assert.AreEqual<Integer>(Round(1080 * 1024 / 1920), LSize.Height);
  Assert.AreEqual(1024, LSize.TextureWidth);
  Assert.AreEqual(1024, LSize.TextureHeight);
end;

procedure TTestVideoScreenLayout.DovrebbeDareQuadrataLAreaGLSeLoSchermoESvolto;
var
  LSize: TVideoGlDrawSize;
begin
  LSize := TVideoScreenLayout.GlDrawSize(600, 800);
  Assert.AreEqual(512, LSize.Height);
  LSize := TVideoScreenLayout.GlDrawSize(1200, 1200);
  Assert.AreEqual(1024, LSize.Height);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestVideoPreserveTables);
  TDUnitX.RegisterTestFixture(TTestVideoScreenLayout);

end.
