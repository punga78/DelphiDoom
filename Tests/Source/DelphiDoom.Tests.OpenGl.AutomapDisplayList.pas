{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the OpenGL automap - the items of a frame              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.OpenGl.AutomapDisplayList;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.GlAutomap.Types,
  DelphiDoom.GlAutomap.Intf,
  DelphiDoom.GlAutomap.Factory,
  DelphiDoom.Tests.OpenGl.OldAutomapBuffer;

type
  [TestFixture]
  [Category('opengl')]
  TTestOpenGlAutomapDisplayList = class(TObject)
  strict private
    FList: IGlAutomapDisplayList;
    FOld: TOldAutomapBuffer;
    function ItemAt(const AIndex: Integer): PGlAutomapItem;
    function FloorOf(const ASector: old_sector_t): TGlAutomapFloor;
    function SameBits(const ALeft, ARight: Single): Boolean;
    function Difference(const AIndex: Integer): string;
    procedure AddRandomItem(const AIndex: Integer);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDareGliStessiElementiDelVecchioSu20000ElementiCasuali;
    [Test]
    procedure DovrebbeEssereVuotaAppenaCreata;
    [Test]
    procedure DovrebbeDareIlRettangoloDelloSfondoDallOrigine;
    [Test]
    procedure DovrebbeConvertireIlColoreInTreFrazioniDi255;
    [Test]
    procedure DovrebbeConvertireLeCoordinateDiTextureInFlat;
    [Test]
    procedure DovrebbeNonAvereAngoloSeIlPavimentoNonERuotato;
    [Test]
    procedure DovrebbeConvertireLAngoloInGradiEIlCentroInFlat;
    [Test]
    procedure DovrebbePortareOndulazioneEScorrimentoDelPavimento;
    [Test]
    procedure DovrebbeTenereLOrdineOltreIlPrimoBlocco;
    [Test]
    procedure DovrebbeRipartireDaZeroDopoClear;
    [Test]
    procedure DovrebbeRestareUsabileDopoRelease;
  end;

implementation

{ TTestOpenGlAutomapDisplayList }

procedure TTestOpenGlAutomapDisplayList.Setup;
begin
  FList := TGlAutomapFactory.CreateDisplayList;
  old_InitAutomap(FOld);
end;

procedure TTestOpenGlAutomapDisplayList.TearDown;
begin
  FList := nil;
  old_ShutDownAutomap(FOld);
end;

function TTestOpenGlAutomapDisplayList.ItemAt(const AIndex: Integer): PGlAutomapItem;
begin
  Result := FList.First;
  Inc(Result, AIndex);
end;

function TTestOpenGlAutomapDisplayList.FloorOf(const ASector: old_sector_t): TGlAutomapFloor;
begin
  Result.Flat := ASector.floorpic;
  Result.Ripples := False;
  Result.OffsetX := 0;
  Result.OffsetY := 0;
  Result.Angle := ASector.floorangle;
  Result.AngleX := ASector.flooranglex;
  Result.AngleY := ASector.floorangley;
end;

function TTestOpenGlAutomapDisplayList.SameBits(const ALeft, ARight: Single): Boolean;
begin
  Result := PCardinal(@ALeft)^ = PCardinal(@ARight)^;
end;

function TTestOpenGlAutomapDisplayList.Difference(const AIndex: Integer): string;
var
  LOld: Pglamrenderitem_t;
  LNew: PGlAutomapItem;
begin
  // every kind is compared on the fields it fills: the others are whatever the block had
  Result := '';
  LOld := @FOld.amrenderitems[AIndex];
  LNew := ItemAt(AIndex);
  case LOld.itemtype of
    GL_AM_QUAD, GL_AM_LINE:
      begin
        if (LOld.itemtype = GL_AM_QUAD) <> (LNew.Kind = gakBackground) then
          Exit('kind');
        if (LOld.itemtype = GL_AM_LINE) <> (LNew.Kind = gakLine) then
          Exit('kind');
        if (LOld.x1 <> LNew.X1) or (LOld.y1 <> LNew.Y1) or (LOld.x2 <> LNew.X2) or (LOld.y2 <> LNew.Y2) then
          Exit('corners');
        if not (SameBits(LOld.r, LNew.Red) and SameBits(LOld.g, LNew.Green) and SameBits(LOld.b, LNew.Blue)) then
          Exit('colour');
      end;
    GL_AM_PATCH:
      begin
        if LNew.Kind <> gakPatch then
          Exit('kind');
        if (LOld.x1 <> LNew.X1) or (LOld.y1 <> LNew.Y1) or (LOld.lump <> LNew.Lump) then
          Exit('patch');
      end;
    GL_AM_TRIANGLE:
      begin
        if LNew.Kind <> gakTriangle then
          Exit('kind');
        if (LOld.x1 <> LNew.X1) or (LOld.y1 <> LNew.Y1) or (LOld.x2 <> LNew.X2) or (LOld.y2 <> LNew.Y2) or
           (LOld.x3 <> LNew.X3) or (LOld.y3 <> LNew.Y3) then
          Exit('corners');
        if not (SameBits(LOld.u1, LNew.U1) and SameBits(LOld.v1, LNew.V1) and SameBits(LOld.u2, LNew.U2) and
           SameBits(LOld.v2, LNew.V2) and SameBits(LOld.u3, LNew.U3) and SameBits(LOld.v3, LNew.V3)) then
          Exit('texture coordinates');
        if not (SameBits(LOld.r, LNew.Red) and SameBits(LOld.g, LNew.Green) and SameBits(LOld.b, LNew.Blue)) then
          Exit('colour');
        if (LOld.lump <> LNew.Lump) or (LOld.flat <> LNew.Flat) then
          Exit('lump or flat');
        if LOld.hasangle <> LNew.HasAngle then
          Exit('has angle');
        if LOld.hasangle and not (SameBits(LOld.angle, LNew.Angle) and SameBits(LOld.anglex, LNew.AngleX) and
           SameBits(LOld.angley, LNew.AngleY)) then
          Exit('angle');
      end;
  end;
end;

procedure TTestOpenGlAutomapDisplayList.AddRandomItem(const AIndex: Integer);
var
  LValues: array[0..11] of Integer;
  LValue: Integer;
  LColor: Cardinal;
  LLump: Integer;
  LSector: old_sector_t;
begin
  for LValue := 0 to High(LValues) do
    case Random(4) of
      0: LValues[LValue] := Random(4000) - 1000;
      1: LValues[LValue] := Random(MaxInt);
      2: LValues[LValue] := -Random(MaxInt);
    else
      LValues[LValue] := (Random(512) - 256) * FRACUNIT + Random(FRACUNIT);
    end;
  LColor := Cardinal(Random(MaxInt)) xor (Cardinal(Random(2)) shl 31);
  LLump := Random(5000);
  case AIndex mod 5 of
    0:
      begin
        old_ClearAMBuffer(FOld, LValues[0], LValues[1], LColor);
        FList.AddBackground(LValues[0], LValues[1], LColor);
      end;
    1:
      begin
        old_AddAutomapPatch(FOld, LValues[0], LValues[1], LLump);
        FList.AddPatch(LValues[0], LValues[1], LLump);
      end;
    2:
      begin
        old_AddAutomapLine(FOld, LValues[0], LValues[1], LValues[2], LValues[3], LColor);
        FList.AddLine(LValues[0], LValues[1], LValues[2], LValues[3], LColor);
      end;
  else
    begin
      LSector.floorpic := SmallInt(Random(65536) - 32768);
      if Random(3) = 0 then
        LSector.floorangle := 0
      else
        LSector.floorangle := Cardinal(Random(MaxInt)) xor (Cardinal(Random(2)) shl 31);
      LSector.flooranglex := LValues[4] xor LValues[7];
      LSector.floorangley := LValues[5] xor LValues[9];
      old_AddAutomapTriangle(FOld,
        LValues[0], LValues[1], LValues[2], LValues[3],
        LValues[4], LValues[5], LValues[6], LValues[7],
        LValues[8], LValues[9], LValues[10], LValues[11],
        LColor, LLump, @LSector);
      FList.AddTriangle(
        LValues[0], LValues[1], LValues[2], LValues[3],
        LValues[4], LValues[5], LValues[6], LValues[7],
        LValues[8], LValues[9], LValues[10], LValues[11],
        LColor, LLump, FloorOf(LSector));
    end;
  end;
end;

procedure TTestOpenGlAutomapDisplayList.DovrebbeDareGliStessiElementiDelVecchioSu20000ElementiCasuali;
const
  FRAME_COUNT = 40;
  ITEMS_PER_FRAME = 500;
var
  LFrame, LIndex, LDifferences: Integer;
  LFirst, LWhat: string;
begin
  RandSeed := 17708;
  LDifferences := 0;
  LFirst := '';
  for LFrame := 1 to FRAME_COUNT do
  begin
    for LIndex := 0 to ITEMS_PER_FRAME - 1 do
      AddRandomItem(LFrame + LIndex);
    Assert.AreEqual(FOld.numamitems, FList.Count, 'count of frame ' + IntToStr(LFrame));
    for LIndex := 0 to ITEMS_PER_FRAME - 1 do
    begin
      LWhat := Difference(LIndex);
      if LWhat <> '' then
      begin
        Inc(LDifferences);
        if LFirst = '' then
          LFirst := Format('frame %d item %d: %s', [LFrame, LIndex, LWhat]);
      end;
    end;
    // the end of a frame of the old code (gld_DrawAutomap) and of the new one
    FOld.numamitems := 0;
    FList.Clear;
  end;
  Assert.AreEqual(0, LDifferences, LFirst);
end;

procedure TTestOpenGlAutomapDisplayList.DovrebbeEssereVuotaAppenaCreata;
begin
  Assert.AreEqual(0, FList.Count);
  Assert.IsTrue(FList.First = nil);
end;

procedure TTestOpenGlAutomapDisplayList.DovrebbeDareIlRettangoloDelloSfondoDallOrigine;
var
  LItem: PGlAutomapItem;
begin
  FList.AddBackground(640, 400, $000000);

  LItem := FList.First;
  Assert.AreEqual(1, FList.Count);
  Assert.IsTrue(LItem.Kind = gakBackground);
  Assert.AreEqual(0, LItem.X1);
  Assert.AreEqual(0, LItem.Y1);
  Assert.AreEqual(640, LItem.X2);
  Assert.AreEqual(400, LItem.Y2);
end;

procedure TTestOpenGlAutomapDisplayList.DovrebbeConvertireIlColoreInTreFrazioniDi255;
var
  LItem: PGlAutomapItem;
begin
  FList.AddLine(1, 2, 3, 4, $FF8000);

  LItem := FList.First;
  Assert.IsTrue(LItem.Kind = gakLine);
  Assert.AreEqual(Single(1.0), LItem.Red);
  Assert.AreEqual(Single(128 / 255), LItem.Green);
  Assert.AreEqual(Single(0.0), LItem.Blue);
  Assert.AreEqual(3, LItem.X2);
  Assert.AreEqual(4, LItem.Y2);
end;

procedure TTestOpenGlAutomapDisplayList.DovrebbeConvertireLeCoordinateDiTextureInFlat;
var
  LItem: PGlAutomapItem;
  LFloor: TGlAutomapFloor;
begin
  LFloor := Default(TGlAutomapFloor);
  LFloor.Flat := 7;

  // 64 units of the map are one flat
  FList.AddTriangle(
    10, 11, 64 * 65536, 128 * 65536,
    20, 21, 32 * 65536, -64 * 65536,
    30, 31, 0, 96 * 65536,
    $FFFFFF, 123, LFloor);

  LItem := FList.First;
  Assert.IsTrue(LItem.Kind = gakTriangle);
  Assert.AreEqual(Single(1.0), LItem.U1);
  Assert.AreEqual(Single(2.0), LItem.V1);
  Assert.AreEqual(Single(0.5), LItem.U2);
  Assert.AreEqual(Single(-1.0), LItem.V2);
  Assert.AreEqual(Single(0.0), LItem.U3);
  Assert.AreEqual(Single(1.5), LItem.V3);
  Assert.AreEqual(30, LItem.X3);
  Assert.AreEqual(31, LItem.Y3);
  Assert.AreEqual(123, LItem.Lump);
  Assert.AreEqual(7, LItem.Flat);
end;

procedure TTestOpenGlAutomapDisplayList.DovrebbeNonAvereAngoloSeIlPavimentoNonERuotato;
var
  LFloor: TGlAutomapFloor;
begin
  LFloor := Default(TGlAutomapFloor);
  LFloor.AngleX := 5 * 65536;

  FList.AddTriangle(0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 1, LFloor);

  Assert.IsFalse(FList.First.HasAngle);
end;

procedure TTestOpenGlAutomapDisplayList.DovrebbeConvertireLAngoloInGradiEIlCentroInFlat;
var
  LItem: PGlAutomapItem;
  LFloor: TGlAutomapFloor;
begin
  LFloor := Default(TGlAutomapFloor);
  LFloor.Angle := $40000000;
  LFloor.AngleX := 128 * 65536;
  LFloor.AngleY := -32 * 65536;

  FList.AddTriangle(0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 1, LFloor);

  LItem := FList.First;
  Assert.IsTrue(LItem.HasAngle);
  Assert.AreEqual(Single(90.0), LItem.Angle, Single(0.0001));
  Assert.AreEqual(Single(2.0), LItem.AngleX);
  Assert.AreEqual(Single(-0.5), LItem.AngleY);
end;

procedure TTestOpenGlAutomapDisplayList.DovrebbePortareOndulazioneEScorrimentoDelPavimento;
var
  LItem: PGlAutomapItem;
  LFloor: TGlAutomapFloor;
begin
  LFloor := Default(TGlAutomapFloor);
  LFloor.Ripples := True;
  LFloor.OffsetX := 3 * 65536;
  LFloor.OffsetY := -9;

  FList.AddTriangle(0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 1, LFloor);

  LItem := FList.First;
  Assert.IsTrue(LItem.Ripples);
  Assert.AreEqual(3 * 65536, LItem.OffsetX);
  Assert.AreEqual(-9, LItem.OffsetY);
end;

procedure TTestOpenGlAutomapDisplayList.DovrebbeTenereLOrdineOltreIlPrimoBlocco;
const
  ITEM_COUNT = 1000;
var
  LIndex: Integer;
begin
  for LIndex := 0 to ITEM_COUNT - 1 do
    FList.AddPatch(LIndex, -LIndex, LIndex * 2);

  Assert.AreEqual(ITEM_COUNT, FList.Count);
  for LIndex := 0 to ITEM_COUNT - 1 do
  begin
    Assert.AreEqual(LIndex, ItemAt(LIndex).X1);
    Assert.AreEqual(-LIndex, ItemAt(LIndex).Y1);
    Assert.AreEqual(LIndex * 2, ItemAt(LIndex).Lump);
  end;
end;

procedure TTestOpenGlAutomapDisplayList.DovrebbeRipartireDaZeroDopoClear;
begin
  FList.AddLine(1, 1, 2, 2, 0);
  FList.AddLine(3, 3, 4, 4, 0);

  FList.Clear;
  Assert.AreEqual(0, FList.Count);
  Assert.IsTrue(FList.First = nil);

  FList.AddPatch(9, 8, 7);
  Assert.AreEqual(1, FList.Count);
  Assert.IsTrue(FList.First.Kind = gakPatch);
  Assert.AreEqual(9, FList.First.X1);
end;

procedure TTestOpenGlAutomapDisplayList.DovrebbeRestareUsabileDopoRelease;
begin
  FList.AddLine(1, 1, 2, 2, 0);

  FList.Release;
  Assert.AreEqual(0, FList.Count);
  Assert.IsTrue(FList.First = nil);

  FList.AddLine(5, 6, 7, 8, $0000FF);
  Assert.AreEqual(1, FList.Count);
  Assert.AreEqual(5, FList.First.X1);
  Assert.AreEqual(Single(1.0), FList.First.Blue);
end;

end.
