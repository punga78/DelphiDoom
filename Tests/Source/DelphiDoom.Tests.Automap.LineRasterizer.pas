{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TAutomapLineRasterizer                                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Automap.LineRasterizer;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Automap.Types,
  DelphiDoom.Automap.LineRasterizer, DelphiDoom.Tests.Automap.OldLine;

type
  [TestFixture]
  [Category('automap')]
  TTestAutomapLineRasterizer = class(TObject)
  private
    FPixels: array[0..63] of Byte;
    FTarget: TAutomapRasterTarget;
    function Line(AX1, AY1, AX2, AY2: Integer): TAutomapFrameLine;
    function Row(ARow: Integer): string;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeDisegnareGliStessiPixelDelVecchioCodice;
    [Test]
    procedure DovrebbeDisegnareUnPuntoPerUnaLineaSenzaLunghezza;
    [Test]
    procedure DovrebbeDisegnareUnaLineaOrizzontaleConGliEstremi;
    [Test]
    procedure DovrebbeDisegnareUnaLineaVerticaleAllIndietro;
    [Test]
    procedure DovrebbeDisegnareLaDiagonale;
    [Test]
    procedure DovrebbeLasciareFuoriIlBordoDellaFinestraInOverlay;
    [Test]
    procedure DovrebbeScrivereIlColoreA32Bit;
  end;

implementation

{ TTestAutomapLineRasterizer }

procedure TTestAutomapLineRasterizer.Setup;
begin
  FillChar(FPixels, SizeOf(FPixels), 0);
  FTarget.Pixels := @FPixels[0];
  FTarget.Width := 8;
  FTarget.Clipped := False;
  FTarget.ClipLeft := 0;
  FTarget.ClipTop := 0;
  FTarget.ClipRight := 0;
  FTarget.ClipBottom := 0;
end;

function TTestAutomapLineRasterizer.Line(AX1, AY1, AX2, AY2: Integer): TAutomapFrameLine;
begin
  Result.A.X := AX1;
  Result.A.Y := AY1;
  Result.B.X := AX2;
  Result.B.Y := AY2;
end;

function TTestAutomapLineRasterizer.Row(ARow: Integer): string;
var
  LColumn: Integer;
begin
  Result := '';
  for LColumn := 0 to 7 do
    if FPixels[ARow * 8 + LColumn] <> 0 then
      Result := Result + '#'
    else
      Result := Result + '.';
end;

procedure TTestAutomapLineRasterizer.DovrebbeDisegnareGliStessiPixelDelVecchioCodice;
const
  SCENARIOS = 300;
  LINES = 80;
var
  LScenario, LLine, LIndex: Integer;
  LSeed: Cardinal;
  LWidth, LHeight: Integer;
  LOld: TOldAutomapLine;
  LNew8: array of Byte;
  LNew32: array of Cardinal;
  LTarget: TAutomapRasterTarget;
  LSegment: TAutomapFrameLine;
  LColor: Integer;
  LWhere: string;

  function Next(ARange: Integer): Integer;
  begin
    LSeed := LSeed * 1664525 + 1013904223;
    Result := Integer((LSeed shr 8) mod Cardinal(ARange));
  end;

begin
  for LScenario := 1 to SCENARIOS do
  begin
    LSeed := Cardinal(LScenario) * 40503;
    LWidth := 1 + Next(200);
    LHeight := 1 + Next(120);
    LOld := TOldAutomapLine.Create;
    try
      LOld.f_w := LWidth;
      LOld.Is32Bit := Next(2) = 1;
      LOld.Overlay := Next(2) = 1;
      // a window of the view inside the frame, sometimes empty or as large as the frame
      LOld.viewwindowx := Next(LWidth);
      LOld.viewwindowy := Next(LHeight);
      LOld.viewwidth := Next(LWidth - LOld.viewwindowx + 1);
      LOld.viewheight := Next(LHeight - LOld.viewwindowy + 1);
      for LIndex := 0 to 255 do
        LOld.videopal[LIndex] := Cardinal(Next(1 shl 24)) or $FF000000;
      SetLength(LOld.fb, LWidth * LHeight);
      SetLength(LOld.fb32, LWidth * LHeight);
      SetLength(LNew8, LWidth * LHeight);
      SetLength(LNew32, LWidth * LHeight);
      for LIndex := 0 to LWidth * LHeight - 1 do
      begin
        LOld.fb[LIndex] := Byte(LIndex);
        LOld.fb32[LIndex] := Cardinal(LIndex) * 2654435761;
        LNew8[LIndex] := LOld.fb[LIndex];
        LNew32[LIndex] := LOld.fb32[LIndex];
      end;

      LTarget.Width := LWidth;
      LTarget.Clipped := LOld.Overlay;
      LTarget.ClipLeft := LOld.viewwindowx;
      LTarget.ClipTop := LOld.viewwindowy;
      LTarget.ClipRight := LOld.viewwindowx + LOld.viewwidth;
      LTarget.ClipBottom := LOld.viewwindowy + LOld.viewheight;

      for LLine := 1 to LINES do
      begin
        LSegment := Line(Next(LWidth), Next(LHeight), Next(LWidth), Next(LHeight));
        LColor := Next(256);
        LOld.AM_drawFline(LSegment, LColor);
        // what AM_drawFline of the facade does
        if LOld.Is32Bit then
        begin
          LTarget.Pixels := @LNew32[0];
          TAutomapLineRasterizer.Draw32(LTarget, LSegment, LOld.videopal[LColor]);
        end
        else
        begin
          LTarget.Pixels := @LNew8[0];
          TAutomapLineRasterizer.Draw8(LTarget, LSegment, LColor);
        end;

        if not (CompareMem(@LOld.fb[0], @LNew8[0], LWidth * LHeight) and
          CompareMem(@LOld.fb32[0], @LNew32[0], LWidth * LHeight * SizeOf(Cardinal))) then
        begin
          LWhere := Format('scenario %d linea %d: (%d,%d)-(%d,%d) su %dx%d, 32 bit %s, overlay %s',
            [LScenario, LLine, LSegment.A.X, LSegment.A.Y, LSegment.B.X, LSegment.B.Y, LWidth,
             LHeight, BoolToStr(LOld.Is32Bit, True), BoolToStr(LOld.Overlay, True)]);
          Assert.Fail('dovrebbe scrivere gli stessi pixel del vecchio: ' + LWhere);
        end;
      end;
    finally
      LOld.Free;
    end;
  end;
  Assert.Pass;
end;

procedure TTestAutomapLineRasterizer.DovrebbeDisegnareUnPuntoPerUnaLineaSenzaLunghezza;
begin
  TAutomapLineRasterizer.Draw8(FTarget, Line(3, 2, 3, 2), 7);
  Assert.AreEqual('...#....', Row(2));
  Assert.AreEqual('........', Row(1));
  Assert.AreEqual('........', Row(3));
  Assert.AreEqual<Byte>(7, FPixels[2 * 8 + 3], 'dovrebbe scrivere il colore');
end;

procedure TTestAutomapLineRasterizer.DovrebbeDisegnareUnaLineaOrizzontaleConGliEstremi;
begin
  TAutomapLineRasterizer.Draw8(FTarget, Line(1, 4, 6, 4), 1);
  Assert.AreEqual('.######.', Row(4));
  Assert.AreEqual('........', Row(3));
  Assert.AreEqual('........', Row(5));
end;

procedure TTestAutomapLineRasterizer.DovrebbeDisegnareUnaLineaVerticaleAllIndietro;
var
  LRow: Integer;
begin
  TAutomapLineRasterizer.Draw8(FTarget, Line(5, 6, 5, 1), 1);
  Assert.AreEqual('........', Row(0));
  for LRow := 1 to 6 do
    Assert.AreEqual('.....#..', Row(LRow), 'riga ' + IntToStr(LRow));
  Assert.AreEqual('........', Row(7));
end;

procedure TTestAutomapLineRasterizer.DovrebbeDisegnareLaDiagonale;
var
  LRow: Integer;
begin
  TAutomapLineRasterizer.Draw8(FTarget, Line(0, 0, 7, 7), 1);
  for LRow := 0 to 7 do
    Assert.AreEqual(StringOfChar('.', LRow) + '#' + StringOfChar('.', 7 - LRow), Row(LRow),
      'riga ' + IntToStr(LRow));
end;

procedure TTestAutomapLineRasterizer.DovrebbeLasciareFuoriIlBordoDellaFinestraInOverlay;
begin
  // the window of the view is x 2..5, y 3..5: its first row and column are not drawn (the old
  // code compares with <=), the last ones are outside
  FTarget.Clipped := True;
  FTarget.ClipLeft := 2;
  FTarget.ClipTop := 3;
  FTarget.ClipRight := 6;
  FTarget.ClipBottom := 6;
  TAutomapLineRasterizer.Draw8(FTarget, Line(0, 4, 7, 4), 1);
  Assert.AreEqual('...###..', Row(4), 'dentro la finestra solo oltre la prima colonna');
  TAutomapLineRasterizer.Draw8(FTarget, Line(0, 3, 7, 3), 1);
  Assert.AreEqual('........', Row(3), 'la prima riga della finestra resta fuori');
  TAutomapLineRasterizer.Draw8(FTarget, Line(0, 6, 7, 6), 1);
  Assert.AreEqual('........', Row(6), 'sotto la finestra non si disegna');
end;

procedure TTestAutomapLineRasterizer.DovrebbeScrivereIlColoreA32Bit;
var
  LPixels: array[0..15] of Cardinal;
  LTarget: TAutomapRasterTarget;
begin
  FillChar(LPixels, SizeOf(LPixels), 0);
  LTarget := FTarget;
  LTarget.Pixels := @LPixels[0];
  LTarget.Width := 4;
  TAutomapLineRasterizer.Draw32(LTarget, Line(0, 1, 3, 2), $FF123456);
  Assert.AreEqual(Cardinal($FF123456), LPixels[4], 'primo estremo');
  Assert.AreEqual(Cardinal($FF123456), LPixels[11], 'secondo estremo');
  Assert.AreEqual(Cardinal(0), LPixels[0], 'la riga sopra resta com''era');
  Assert.AreEqual(Cardinal(0), LPixels[12], 'la riga sotto resta com''era');
end;

end.
