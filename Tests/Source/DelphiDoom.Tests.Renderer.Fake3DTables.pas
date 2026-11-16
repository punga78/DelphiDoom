{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the renderer library - the tables of the fake 3D view  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Renderer.Fake3DTables;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  /// <summary>
  ///   TRendererFake3DAnglesExact and TRendererFake3DTables (issue #40). At 32 bit each result is compared with
  ///   the old code of r_fake3d.pas computed by the FPU (copied here); the fingerprint of the results is a
  ///   constant and at 64 bit, where the renderer calls the classes, the same fingerprint must come out
  /// </summary>
  [TestFixture]
  [Category('renderer')]
  TTestRendererFake3DTables = class(TObject)
  public
    [Test]
    procedure DovrebbeDareGliAngoliDellaVistaComeLaFpu;
    [Test]
    procedure DovrebbeDareLeRigheDellaVistaComeLaFpu;
    [Test]
    procedure DovrebbeDareGliSpigoliDellaVistaComeLaFpu;
  end;

implementation

uses
  System.Math, DelphiDoom.Renderer.Intf, DelphiDoom.Renderer.Fake3DAngles,
  DelphiDoom.Renderer.Fake3DAnglesExact, DelphiDoom.Renderer.Fake3DTables,
  DelphiDoom.Tests.MathCore.Fingerprint;

const
  MIN_LOOK = 16 * -110;
  MAX_LOOK = 16 * 90;
  FRACUNIT = 65536;
  LOOK_DIRECTIONS: array[0..13] of Integer = (-1760, -1500, -1000, -500, -97, -16, -1, 1, 3, 16, 100, 500, 1000, 1440);
  WIDTHS: array[0..5] of Integer = (320, 640, 800, 1024, 1280, 1920);
  HEIGHTS: array[0..7] of Integer = (200, 240, 320, 400, 480, 600, 768, 1080);

var
  GCosines: TArray<Double>;

function CosineOf(ALookDirection: Integer): Double;
begin
  if Length(GCosines) = 0 then
    GCosines := TRendererFake3DAnglesExact.Cosines(MIN_LOOK, MAX_LOOK);
  Result := GCosines[ALookDirection - MIN_LOOK];
end;

{$IF SizeOf(Extended) > SizeOf(Double)}
// the expressions of R_ComputeFake3DTables of r_fake3d.pas, with the same types
procedure LegacyRows(L: Integer; c: Double; viewheight: Integer; var ylookup: TArray<Integer>);
var
  buffer: array of Double;
  buffer2: array of Double;
  c1, c2: Double;
  c1frac: Double;
  invc2: Double;
  r: Double;
  i: Integer;
begin
  SetLength(buffer, viewheight);
  SetLength(buffer2, viewheight);
  SetLength(ylookup, viewheight);
  c1 := 2 * (c - 1);
  c2 := 2 - c;
  invc2 := 1 / c2;
  c1frac := c1 / viewheight;
  buffer[0] := 0;
  for i := 1 to viewheight - 1 do
    buffer[i] := buffer[i - 1] + i * c1frac;
  for i := 0 to viewheight - 1 do
    buffer2[i] := buffer[i] + i * c2;
  r := Sqrt(3);
  if L >= 0 then
    for i := 0 to viewheight - 1 do
      ylookup[i] := Round(invc2 * (i + r * (buffer2[i] - i)));
  if L < 0 then
    for i := 0 to viewheight - 1 do
      ylookup[i] := Round(invc2 * (i - r * (buffer2[i] - i)));
end;

procedure LegacyEdges(l, maxbuffer: Integer; aspect: Double; viewwidth, viewheight, viewheightdiff,
  viewheightrest: Integer; var lefttop, righttop, leftbottom, rightbottom: Integer;
  var left, right, fracstep: TArray<Integer>);
var
  r: Double;
  leftstep, rightstep: Double;
  correction: Double;
  i, j: Integer;
begin
  if l >= 0 then
  begin
    lefttop := 0;
    righttop := viewwidth - 1;
    r := viewwidth / aspect;
    leftbottom := Round(viewwidth - r);
    rightbottom := viewwidth - leftbottom - 1;
    leftstep := leftbottom - lefttop;
    rightstep := rightbottom - righttop;
    r := FRACUNIT / viewwidth;
    for i := 0 to viewheightdiff do
    begin
      correction := l / maxbuffer * Sin(i / (viewheight + viewheightrest)) * viewheight / 10;
      left[i] := Round(lefttop + leftstep * i / viewheightdiff - correction);
      if left[i] < 0 then
        left[i] := 0;
      right[i] := Round(righttop + rightstep * i / viewheightdiff + correction);
      if right[i] >= viewwidth then
        right[i] := viewwidth - 1;
      fracstep[i] := Round((right[i] - left[i]) * r);
    end;
  end
  else
  begin
    r := viewwidth / aspect;
    lefttop := Round(viewwidth - r);
    righttop := viewwidth - lefttop - 1;
    leftbottom := 0;
    rightbottom := viewwidth - 1;
    leftstep := leftbottom - lefttop;
    rightstep := rightbottom - righttop;
    r := FRACUNIT / viewwidth;
    for i := 0 to viewheightdiff - 1 do
    begin
      j := i + viewheightrest;
      left[j] := Round(lefttop + leftstep * i / viewheightdiff);
      if left[j] < 0 then
        left[j] := 0;
      right[j] := Round(righttop + rightstep * i / viewheightdiff);
      if right[j] >= viewwidth then
        right[j] := viewwidth - 1;
      fracstep[j] := Round((right[j] - left[j]) * r);
    end;
  end;
end;
{$IFEND}

// what R_ComputeFake3DTables does with the rows between the two floating point parts
procedure ClampRows(L, AViewHeight: Integer; var ARows: TArray<Integer>; out AViewHeightDiff, AViewHeightRest: Integer);
var
  LIndex, LDelta: Integer;
begin
  if L < 0 then
  begin
    LDelta := AViewHeight - ARows[AViewHeight - 1] + 1;
    for LIndex := 0 to AViewHeight - 1 do
      ARows[LIndex] := ARows[LIndex] + LDelta;
  end;
  for LIndex := 0 to AViewHeight - 1 do
    if ARows[LIndex] < 0 then
      ARows[LIndex] := 0
    else if ARows[LIndex] >= AViewHeight then
      ARows[LIndex] := AViewHeight - 1;
  AViewHeightDiff := ARows[AViewHeight - 1] - ARows[0] + 1;
  if AViewHeightDiff >= AViewHeight then
    AViewHeightDiff := AViewHeight - 1;
  AViewHeightRest := AViewHeight - AViewHeightDiff;
end;

{ TTestRendererFake3DTables }

procedure TTestRendererFake3DTables.DovrebbeDareGliAngoliDellaVistaComeLaFpu;
var
  LFingerprint: TFingerprint;
  LExact: TArray<Double>;
  LIndex: Integer;
  {$IF SizeOf(Extended) > SizeOf(Double)}
  LNative: TArray<Double>;
  LAngles: IRendererFake3DAngles;
  LDifferent: Integer;
  {$IFEND}
begin
  LExact := TRendererFake3DAnglesExact.Cosines(MIN_LOOK, MAX_LOOK);
  Assert.AreEqual<Integer>(MAX_LOOK - MIN_LOOK + 1, Length(LExact));
  LFingerprint := TFingerprint.Create;
  try
    {$IF SizeOf(Extended) > SizeOf(Double)}
    LAngles := TRendererFake3DAngles.Create;
    LNative := LAngles.Cosines(MIN_LOOK, MAX_LOOK);
    LDifferent := 0;
    for LIndex := 0 to High(LExact) do
    begin
      if PUInt64(@LExact[LIndex])^ <> PUInt64(@LNative[LIndex])^ then
        Inc(LDifferent);
      Assert.AreEqual(LNative[LIndex], LExact[LIndex], 1E-15, Format('index %d', [LIndex]));
    end;
    // fcos is not correctly rounded: the last bit of a Double may differ, rarely
    Assert.IsTrue(LDifferent <= 10, Format('%d Doubles differ from the FPU', [LDifferent]));
    {$IFEND}
    for LIndex := 0 to High(LExact) do
      LFingerprint.AddDouble(LExact[LIndex]);
    Assert.AreEqual('45195B3E18602277/3201', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

procedure TTestRendererFake3DTables.DovrebbeDareLeRigheDellaVistaComeLaFpu;
var
  LFingerprint: TFingerprint;
  LDirection, LHeight, LIndex: Integer;
  LRows: TArray<Integer>;
  {$IF SizeOf(Extended) > SizeOf(Double)}
  LLegacy: TArray<Integer>;
  {$IFEND}
begin
  LFingerprint := TFingerprint.Create;
  try
    for LDirection in LOOK_DIRECTIONS do
      for LHeight in HEIGHTS do
      begin
        SetLength(LRows, LHeight);
        TRendererFake3DTables.RowLookup(LDirection, CosineOf(LDirection), LHeight, @LRows[0]);
        {$IF SizeOf(Extended) > SizeOf(Double)}
        LegacyRows(LDirection, CosineOf(LDirection), LHeight, LLegacy);
        for LIndex := 0 to LHeight - 1 do
          Assert.AreEqual(LLegacy[LIndex], LRows[LIndex], Format('look %d height %d row %d', [LDirection, LHeight, LIndex]));
        {$IFEND}
        for LIndex := 0 to LHeight - 1 do
          LFingerprint.AddInteger(LRows[LIndex]);
      end;
    Assert.AreEqual('9DDD949E9D4C90BE/57232', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

procedure TTestRendererFake3DTables.DovrebbeDareGliSpigoliDellaVistaComeLaFpu;
var
  LFingerprint: TFingerprint;
  LDirection, LHeight, LWidth, LIndex: Integer;
  LRows, LLeft, LRight, LStep: TArray<Integer>;
  LViewHeightDiff, LViewHeightRest: Integer;
  LAspect: Double;
  LLeftTop, LRightTop, LLeftBottom, LRightBottom: Integer;
  {$IF SizeOf(Extended) > SizeOf(Double)}
  LLeftL, LRightL, LStepL: TArray<Integer>;
  LLeftTopL, LRightTopL, LLeftBottomL, LRightBottomL: Integer;
  {$IFEND}
begin
  LFingerprint := TFingerprint.Create;
  try
    for LDirection in LOOK_DIRECTIONS do
      for LHeight in HEIGHTS do
        for LWidth in WIDTHS do
        begin
          if (LHeight * 2 > LWidth * 2) and (LWidth < 640) then
            Continue;
          SetLength(LRows, LHeight);
          TRendererFake3DTables.RowLookup(LDirection, CosineOf(LDirection), LHeight, @LRows[0]);
          ClampRows(LDirection, LHeight, LRows, LViewHeightDiff, LViewHeightRest);
          LAspect := TRendererFake3DTables.Aspect(CosineOf(LDirection));
          SetLength(LLeft, LHeight);
          SetLength(LRight, LHeight);
          SetLength(LStep, LHeight);
          TRendererFake3DTables.RowEdges(LDirection, MAX_LOOK, LAspect, LWidth, LHeight, LViewHeightDiff,
            LViewHeightRest, LLeftTop, LRightTop, LLeftBottom, LRightBottom, @LLeft[0], @LRight[0], @LStep[0]);
          {$IF SizeOf(Extended) > SizeOf(Double)}
          SetLength(LLeftL, LHeight);
          SetLength(LRightL, LHeight);
          SetLength(LStepL, LHeight);
          LegacyEdges(LDirection, MAX_LOOK, 2 - CosineOf(LDirection), LWidth, LHeight, LViewHeightDiff,
            LViewHeightRest, LLeftTopL, LRightTopL, LLeftBottomL, LRightBottomL, LLeftL, LRightL, LStepL);
          Assert.AreEqual(LLeftTopL, LLeftTop);
          Assert.AreEqual(LRightTopL, LRightTop);
          Assert.AreEqual(LLeftBottomL, LLeftBottom);
          Assert.AreEqual(LRightBottomL, LRightBottom);
          {$IFEND}
          LFingerprint.AddInteger(LLeftTop);
          LFingerprint.AddInteger(LRightBottom);
          for LIndex := 0 to LHeight - 1 do
          begin
            if ((LDirection >= 0) and (LIndex <= LViewHeightDiff)) or
              ((LDirection < 0) and (LIndex >= LViewHeightRest) and (LIndex < LViewHeightRest + LViewHeightDiff)) then
            begin
              {$IF SizeOf(Extended) > SizeOf(Double)}
              Assert.AreEqual(LLeftL[LIndex], LLeft[LIndex], Format('left %d %d %d %d', [LDirection, LHeight, LWidth, LIndex]));
              Assert.AreEqual(LRightL[LIndex], LRight[LIndex], Format('right %d %d %d %d', [LDirection, LHeight, LWidth, LIndex]));
              Assert.AreEqual(LStepL[LIndex], LStep[LIndex], Format('step %d %d %d %d', [LDirection, LHeight, LWidth, LIndex]));
              {$IFEND}
              LFingerprint.AddInteger(LLeft[LIndex]);
              LFingerprint.AddInteger(LRight[LIndex]);
              LFingerprint.AddInteger(LStep[LIndex]);
            end;
          end;
        end;
    Assert.AreEqual('E50E500930E6516C/841156', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

end.
