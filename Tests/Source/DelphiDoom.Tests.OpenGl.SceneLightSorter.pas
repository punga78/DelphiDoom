{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TEngineGlSceneLightSorter - the sort of the lights     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.OpenGl.SceneLightSorter;

interface

uses
  DUnitX.TestFramework,
  DelphiDoom.DynLights.Types,
  DelphiDoom.Engine.GlScene.LightSorter;

type
  [TestFixture]
  [Category('opengl')]
  TTestOpenGlSceneLightSorter = class(TObject)
  strict private
    FSorter: TEngineGlSceneLightSorter;
    FLights: array[0..63] of TDynLightRender;
    procedure FillBuffer(ACount, ADistanceRange: Integer);
    procedure CheckSameAsOld(ACount, ADistanceRange: Integer);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeNonFareNullaSeIlBufferEVuoto;
    [Test]
    procedure DovrebbeMettereLaLuceVicinaPerPrima;
    [Test]
    procedure DovrebbeLasciareUnaSolaLuce;
    [Test]
    procedure DovrebbeDareLoStessoOrdineDelVecchioConDistanzeTutteDiverse;
    [Test]
    procedure DovrebbeDareLoStessoOrdineDelVecchioConMoltiPariMerito;
    [Test]
    procedure DovrebbeDareLoStessoOrdineDelVecchioConDistanzeTutteUguali;
    [Test]
    procedure DovrebbeDareLoStessoOrdineDelVecchioSuBufferDiOgniLunghezza;
  end;

implementation

uses
  System.SysUtils,
  r_dynlights,
  DelphiDoom.Tests.OpenGl.OldSceneLights;

const
  BUFFER_CAPACITY = 300;

{ TTestOpenGlSceneLightSorter }

procedure TTestOpenGlSceneLightSorter.Setup;
begin
  RandSeed := 249;
  FSorter := TEngineGlSceneLightSorter.Create;
  GetMem(dlbuffer, BUFFER_CAPACITY * SizeOf(dlsortitem_t));
  FillChar(dlbuffer^, BUFFER_CAPACITY * SizeOf(dlsortitem_t), 0);
  numdlitems := 0;
end;

procedure TTestOpenGlSceneLightSorter.TearDown;
begin
  FreeMem(dlbuffer);
  dlbuffer := nil;
  numdlitems := 0;
  FreeAndNil(FSorter);
end;

procedure TTestOpenGlSceneLightSorter.FillBuffer(ACount, ADistanceRange: Integer);
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(FLights) do
    FLights[LIndex].Radius := LIndex + 1;
  numdlitems := ACount;
  for LIndex := 0 to ACount - 1 do
  begin
    dlbuffer[LIndex].l := @FLights[Random(Length(FLights))];
    dlbuffer[LIndex].squaredist := Random(ADistanceRange);
    dlbuffer[LIndex].x := LIndex;
    dlbuffer[LIndex].y := Random(1000);
    dlbuffer[LIndex].z := Random(1000);
  end;
end;

// The same buffer is sorted by the text of before and by the class, and the records must end in the same places
procedure TTestOpenGlSceneLightSorter.CheckSameAsOld(ACount, ADistanceRange: Integer);
var
  LOriginal: array of dlsortitem_t;
  LExpected: array of dlsortitem_t;
  LIndex: Integer;
begin
  FillBuffer(ACount, ADistanceRange);
  SetLength(LOriginal, ACount + 1);
  SetLength(LExpected, ACount + 1);
  if ACount > 0 then
    Move(dlbuffer^, LOriginal[0], ACount * SizeOf(dlsortitem_t));
  OldSortDlights;
  if ACount > 0 then
  begin
    Move(dlbuffer^, LExpected[0], ACount * SizeOf(dlsortitem_t));
    Move(LOriginal[0], dlbuffer^, ACount * SizeOf(dlsortitem_t));
  end;
  FSorter.Sort;
  for LIndex := 0 to ACount - 1 do
  begin
    Assert.IsTrue(LExpected[LIndex].l = dlbuffer[LIndex].l, 'light ' + IntToStr(LIndex));
    Assert.AreEqual<Single>(LExpected[LIndex].squaredist, dlbuffer[LIndex].squaredist, 'dist ' + IntToStr(LIndex));
    Assert.AreEqual<Single>(LExpected[LIndex].x, dlbuffer[LIndex].x, 'x ' + IntToStr(LIndex));
    Assert.AreEqual<Single>(LExpected[LIndex].y, dlbuffer[LIndex].y, 'y ' + IntToStr(LIndex));
    Assert.AreEqual<Single>(LExpected[LIndex].z, dlbuffer[LIndex].z, 'z ' + IntToStr(LIndex));
  end;
end;

procedure TTestOpenGlSceneLightSorter.DovrebbeNonFareNullaSeIlBufferEVuoto;
begin
  numdlitems := 0;
  FSorter.Sort;
  Assert.AreEqual(0, numdlitems);
end;

procedure TTestOpenGlSceneLightSorter.DovrebbeMettereLaLuceVicinaPerPrima;
begin
  numdlitems := 3;
  dlbuffer[0].squaredist := 30;
  dlbuffer[1].squaredist := 10;
  dlbuffer[2].squaredist := 20;
  FSorter.Sort;
  Assert.AreEqual<Single>(10, dlbuffer[0].squaredist);
  Assert.AreEqual<Single>(20, dlbuffer[1].squaredist);
  Assert.AreEqual<Single>(30, dlbuffer[2].squaredist);
end;

procedure TTestOpenGlSceneLightSorter.DovrebbeLasciareUnaSolaLuce;
begin
  numdlitems := 1;
  dlbuffer[0].squaredist := 5;
  dlbuffer[0].x := 7;
  FSorter.Sort;
  Assert.AreEqual<Single>(5, dlbuffer[0].squaredist);
  Assert.AreEqual<Single>(7, dlbuffer[0].x);
end;

procedure TTestOpenGlSceneLightSorter.DovrebbeDareLoStessoOrdineDelVecchioConDistanzeTutteDiverse;
begin
  CheckSameAsOld(200, 1000000);
end;

procedure TTestOpenGlSceneLightSorter.DovrebbeDareLoStessoOrdineDelVecchioConMoltiPariMerito;
begin
  CheckSameAsOld(250, 6);
end;

procedure TTestOpenGlSceneLightSorter.DovrebbeDareLoStessoOrdineDelVecchioConDistanzeTutteUguali;
begin
  CheckSameAsOld(120, 1);
end;

procedure TTestOpenGlSceneLightSorter.DovrebbeDareLoStessoOrdineDelVecchioSuBufferDiOgniLunghezza;
var
  LCount: Integer;
begin
  for LCount := 0 to 40 do
    CheckSameAsOld(LCount, 1 + LCount mod 7);
end;

end.
