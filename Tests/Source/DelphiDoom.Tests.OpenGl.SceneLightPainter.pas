{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TEngineGlSceneLightPainter - the discs of the lights   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.OpenGl.SceneLightPainter;

interface

uses
  System.Classes,
  DUnitX.TestFramework,
  DelphiDoom.DynLights.Types,
  DelphiDoom.Engine.GlScene.LightPainter,
  DelphiDoom.Tests.OpenGl.FakeGlLog;

type
  /// <summary>
  ///   The painter only reads the buffer of the lights and calls OpenGL, whatever the game is: the tests
  ///   give it a buffer made by hand (as a scene of Strife with lights would fill it) and read the calls
  ///   from fake OpenGL functions, then compare them with the text of before the class
  /// </summary>
  [TestFixture]
  [Category('opengl')]
  TTestOpenGlSceneLightPainter = class(TObject)
  strict private
    FPainter: TEngineGlSceneLightPainter;
    FFakeGl: TFakeGlLog;
    FLights: array[0..7] of TDynLightRender;
    procedure FillBuffer(ACount: Integer; ADuplicateEvery: Integer);
    function DrawnByClass(AYaw: Single): TStringList;
    function DrawnByOldText(AYaw: Single): TStringList;
    function CountOf(const ALines: TStringList; const APrefix: string): Integer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeNonChiamareOpenGlSenzaLuceAccesa;
    [Test]
    procedure DovrebbeNonChiamareOpenGlConIlBufferVuoto;
    [Test]
    procedure DovrebbeDisegnareUnDiscoDiDiciassetteVerticiPiuIlCentro;
    [Test]
    procedure DovrebbeRimettereLoStatoDopoIDischi;
    [Test]
    procedure DovrebbeDisegnareLaLucePiuLontanaPerPrima;
    [Test]
    procedure DovrebbeSaltareUnaLuceUgualeAQuellaAppenaDisegnata;
    [Test]
    procedure DovrebbeDisegnareUnaLuceUgualeSeNonEConsecutiva;
    [Test]
    procedure DovrebbeUsareLAngoloDelFotogramma;
    [Test]
    procedure DovrebbeDareLeStesseChiamateDelVecchioSuBufferCasuali;
    [Test]
    procedure DovrebbeDareLeStesseChiamateDelVecchioConLuciRipetute;
  end;

implementation

uses
  System.SysUtils,
  r_dynlights,
  r_lights,
  DelphiDoom.Tests.OpenGl.OldSceneLights;

const
  BUFFER_CAPACITY = 300;
  // 5 state calls before the discs, 4 after, 26 for each disc
  CALLS_OF_FRAME = 9;
  CALLS_OF_DISC = 26;

{ TTestOpenGlSceneLightPainter }

procedure TTestOpenGlSceneLightPainter.Setup;
var
  LIndex: Integer;
begin
  RandSeed := 249;
  FPainter := TEngineGlSceneLightPainter.Create;
  FFakeGl := TFakeGlLog.Create;
  FFakeGl.Install;
  GetMem(dlbuffer, BUFFER_CAPACITY * SizeOf(dlsortitem_t));
  FillChar(dlbuffer^, BUFFER_CAPACITY * SizeOf(dlsortitem_t), 0);
  numdlitems := 0;
  uselightboost := True;
  for LIndex := 0 to High(FLights) do
  begin
    FLights[LIndex].R := (LIndex + 1) * 0.125;
    FLights[LIndex].G := (8 - LIndex) * 0.125;
    FLights[LIndex].B := 0.5;
    FLights[LIndex].Radius := 16 + LIndex * 8;
  end;
end;

procedure TTestOpenGlSceneLightPainter.TearDown;
begin
  uselightboost := False;
  FreeMem(dlbuffer);
  dlbuffer := nil;
  numdlitems := 0;
  FFakeGl.Restore;
  FreeAndNil(FFakeGl);
  FreeAndNil(FPainter);
end;

// ADuplicateEvery > 0: every item of that step repeats the one before (same light, same place)
procedure TTestOpenGlSceneLightPainter.FillBuffer(ACount: Integer; ADuplicateEvery: Integer);
var
  LIndex: Integer;
begin
  numdlitems := ACount;
  for LIndex := 0 to ACount - 1 do
  begin
    if (ADuplicateEvery > 0) and (LIndex > 0) and (LIndex mod ADuplicateEvery = 0) then
      dlbuffer[LIndex] := dlbuffer[LIndex - 1]
    else
    begin
      dlbuffer[LIndex].l := @FLights[Random(Length(FLights))];
      dlbuffer[LIndex].squaredist := LIndex;
      dlbuffer[LIndex].x := Random(2000) - 1000;
      dlbuffer[LIndex].y := Random(500);
      dlbuffer[LIndex].z := Random(2000) - 1000;
    end;
  end;
end;

function TTestOpenGlSceneLightPainter.DrawnByClass(AYaw: Single): TStringList;
begin
  TFakeGlLog.Clear;
  FPainter.BeginFrame(AYaw);
  FPainter.Draw;
  Result := TStringList.Create;
  Result.AddStrings(TFakeGlLog.Lines);
end;

function TTestOpenGlSceneLightPainter.DrawnByOldText(AYaw: Single): TStringList;
begin
  TFakeGlLog.Clear;
  OldDrawDLights(AYaw);
  Result := TStringList.Create;
  Result.AddStrings(TFakeGlLog.Lines);
end;

function TTestOpenGlSceneLightPainter.CountOf(const ALines: TStringList; const APrefix: string): Integer;
var
  LIndex: Integer;
begin
  Result := 0;
  for LIndex := 0 to ALines.Count - 1 do
    if ALines[LIndex].StartsWith(APrefix) then
      Inc(Result);
end;

procedure TTestOpenGlSceneLightPainter.DovrebbeNonChiamareOpenGlSenzaLuceAccesa;
var
  LLines: TStringList;
begin
  uselightboost := False;
  FillBuffer(5, 0);
  LLines := DrawnByClass(10);
  try
    Assert.AreEqual(0, LLines.Count);
  finally
    LLines.Free;
  end;
end;

procedure TTestOpenGlSceneLightPainter.DovrebbeNonChiamareOpenGlConIlBufferVuoto;
var
  LLines: TStringList;
begin
  numdlitems := 0;
  LLines := DrawnByClass(10);
  try
    Assert.AreEqual(0, LLines.Count);
  finally
    LLines.Free;
  end;
end;

procedure TTestOpenGlSceneLightPainter.DovrebbeDisegnareUnDiscoDiDiciassetteVerticiPiuIlCentro;
var
  LLines: TStringList;
begin
  FillBuffer(1, 0);
  LLines := DrawnByClass(0);
  try
    Assert.AreEqual(CALLS_OF_FRAME + CALLS_OF_DISC, LLines.Count);
    Assert.AreEqual(1, CountOf(LLines, 'glBegin 0006'), 'one triangle fan');
    Assert.AreEqual(18, CountOf(LLines, 'glVertex3f'), 'centre and 17 rim points');
    Assert.AreEqual(2, CountOf(LLines, 'glColor4f'), 'centre colour and rim colour');
  finally
    LLines.Free;
  end;
end;

procedure TTestOpenGlSceneLightPainter.DovrebbeRimettereLoStatoDopoIDischi;
var
  LLines: TStringList;
begin
  FillBuffer(3, 0);
  LLines := DrawnByClass(0);
  try
    Assert.AreEqual('glMatrixMode 1700', LLines[0]);
    Assert.AreEqual('glDepthMask 0', LLines[1]);
    Assert.AreEqual('glDepthMask 1', LLines[LLines.Count - 4]);
    Assert.AreEqual('glEnable 0DE1', LLines[LLines.Count - 3]);
    Assert.AreEqual('glEnable 0BC0', LLines[LLines.Count - 2]);
    Assert.AreEqual('glBlendFunc 0302 0303', LLines[LLines.Count - 1]);
  finally
    LLines.Free;
  end;
end;

procedure TTestOpenGlSceneLightPainter.DovrebbeDisegnareLaLucePiuLontanaPerPrima;
var
  LLines: TStringList;
  LFirstTranslate: string;
  LLastTranslate: string;
  LIndex: Integer;
begin
  // the sort puts the closer light first, the painter walks the buffer backwards: the farthest light goes first
  FillBuffer(3, 0);
  LLines := DrawnByClass(0);
  try
    LFirstTranslate := '';
    LLastTranslate := '';
    for LIndex := 0 to LLines.Count - 1 do
      if LLines[LIndex].StartsWith('glTranslatef') then
      begin
        if LFirstTranslate = '' then
          LFirstTranslate := LLines[LIndex];
        LLastTranslate := LLines[LIndex];
      end;
    Assert.AreEqual(3, CountOf(LLines, 'glTranslatef'));
    Assert.AreNotEqual(LFirstTranslate, LLastTranslate);
    Assert.AreEqual(
      Format('glTranslatef %s %s %s', [IntToHex(PCardinal(@dlbuffer[2].x)^, 8),
        IntToHex(PCardinal(@dlbuffer[2].y)^, 8), IntToHex(PCardinal(@dlbuffer[2].z)^, 8)]),
      LFirstTranslate);
  finally
    LLines.Free;
  end;
end;

procedure TTestOpenGlSceneLightPainter.DovrebbeSaltareUnaLuceUgualeAQuellaAppenaDisegnata;
var
  LLines: TStringList;
begin
  FillBuffer(2, 0);
  dlbuffer[1] := dlbuffer[0];
  LLines := DrawnByClass(0);
  try
    Assert.AreEqual(1, CountOf(LLines, 'glTranslatef'));
  finally
    LLines.Free;
  end;
end;

procedure TTestOpenGlSceneLightPainter.DovrebbeDisegnareUnaLuceUgualeSeNonEConsecutiva;
var
  LLines: TStringList;
begin
  FillBuffer(3, 0);
  dlbuffer[2] := dlbuffer[0];
  LLines := DrawnByClass(0);
  try
    Assert.AreEqual(3, CountOf(LLines, 'glTranslatef'));
  finally
    LLines.Free;
  end;
end;

procedure TTestOpenGlSceneLightPainter.DovrebbeUsareLAngoloDelFotogramma;
var
  LLines: TStringList;
  LYaw: Single;
begin
  FillBuffer(1, 0);
  LYaw := 37.5;
  LLines := DrawnByClass(LYaw);
  try
    Assert.AreEqual(
      Format('glRotatef %s %s %s %s', [IntToHex(PCardinal(@LYaw)^, 8), '00000000', '3F800000', '00000000']),
      LLines[7]);  // after the five state calls, glPushMatrix and glTranslatef
  finally
    LLines.Free;
  end;
end;

procedure TTestOpenGlSceneLightPainter.DovrebbeDareLeStesseChiamateDelVecchioSuBufferCasuali;
var
  LCount: Integer;
  LNew: TStringList;
  LOld: TStringList;
begin
  for LCount := 0 to 40 do
  begin
    FillBuffer(LCount, 0);
    LNew := DrawnByClass(LCount * 11.25);
    LOld := DrawnByOldText(LCount * 11.25);
    try
      Assert.AreEqual(LOld.Text, LNew.Text, 'lights ' + IntToStr(LCount));
    finally
      LOld.Free;
      LNew.Free;
    end;
  end;
end;

procedure TTestOpenGlSceneLightPainter.DovrebbeDareLeStesseChiamateDelVecchioConLuciRipetute;
var
  LStep: Integer;
  LNew: TStringList;
  LOld: TStringList;
begin
  for LStep := 1 to 5 do
  begin
    FillBuffer(120, LStep);
    LNew := DrawnByClass(90);
    LOld := DrawnByOldText(90);
    try
      Assert.AreEqual(LOld.Text, LNew.Text, 'step ' + IntToStr(LStep));
    finally
      LOld.Free;
      LNew.Free;
    end;
  end;
end;

end.
