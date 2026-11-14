unit DelphiDoom.Tests.Greed.MouseCursor;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Greed.Types, DelphiDoom.Greed.Frame.Intf,
  DelphiDoom.Greed.Mouse.Intf, DelphiDoom.Greed.MouseCursor;

type
  [TestFixture]
  [Category('greed')]
  TTestGreedMouseCursor = class(TObject)
  strict private
    FLump: TBytes;
    FCursor: TGreedMouseCursor;
    function Pixel(const AFrame: TGreedFrame; AX, AY: Integer): Integer;
    function Drawn(const AFrame: TGreedFrame): Integer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeRifiutareUnLumpTroppoCorto;
    [Test]
    procedure DovrebbeSaltareLOttoByteDellIntestazione;
    [Test]
    procedure DovrebbeDisegnareOgniPixelDueVolteSulQuadroDoppio;
    [Test]
    procedure DovrebbeDisegnareUnPixelPerPixelSulQuadroBasso;
    [Test]
    procedure NonDovrebbeDisegnareIColoriZeroEDuecentocinquantacinque;
    [Test]
    procedure DovrebbeTagliareCioCheEsceDalQuadro;
    [Test]
    procedure DovrebbeArrotondareLaPosizioneRaddoppiata;
    [Test]
    procedure NonDovrebbeDisegnareSuUnQuadroTroppoStretto;
  end;

implementation

{ TTestGreedMouseCursor }

procedure TTestGreedMouseCursor.Setup;
var
  LIndex: Integer;
begin
  // the header is full of a color that must never be seen; the pixels are 1 .. 250, with a 0 and a 255
  SetLength(FLump, GREED_MOUSE_CURSOR_HEADER_BYTES + GREED_MOUSE_SIZE * GREED_MOUSE_SIZE);
  for LIndex := 0 to GREED_MOUSE_CURSOR_HEADER_BYTES - 1 do
    FLump[LIndex] := 251;
  for LIndex := 0 to GREED_MOUSE_SIZE * GREED_MOUSE_SIZE - 1 do
    FLump[GREED_MOUSE_CURSOR_HEADER_BYTES + LIndex] := 1 + LIndex mod 250;
  FLump[GREED_MOUSE_CURSOR_HEADER_BYTES + 1] := 0;
  FLump[GREED_MOUSE_CURSOR_HEADER_BYTES + 2] := 255;
  FCursor := TGreedMouseCursor.Create(FLump);
end;

procedure TTestGreedMouseCursor.TearDown;
begin
  FCursor.Free;
end;

function TTestGreedMouseCursor.Pixel(const AFrame: TGreedFrame; AX, AY: Integer): Integer;
begin
  Result := AFrame.Pixels[AY * AFrame.Width + AX];
end;

function TTestGreedMouseCursor.Drawn(const AFrame: TGreedFrame): Integer;
var
  LIndex: Integer;
begin
  Result := 0;
  for LIndex := 0 to High(AFrame.Pixels) do
    if AFrame.Pixels[LIndex] <> 0 then
      Inc(Result);
end;

procedure TTestGreedMouseCursor.DovrebbeRifiutareUnLumpTroppoCorto;
begin
  Assert.WillRaise(
    procedure
    begin
      TGreedMouseCursor.Create(Copy(FLump, 0, Length(FLump) - 1));
    end, EGreedDataException);
  Assert.WillRaise(
    procedure
    begin
      TGreedMouseCursor.Create(nil);
    end, EGreedDataException);
end;

procedure TTestGreedMouseCursor.DovrebbeSaltareLOttoByteDellIntestazione;
var
  LFrame: TGreedFrame;
begin
  LFrame := TGreedFrame.Make(320, 200);
  FCursor.Draw(LFrame, 10, 20);
  Assert.AreEqual(1, Pixel(LFrame, 10, 20), 'the first pixel of the picture, not a byte of the header');
  Assert.AreEqual(17, Pixel(LFrame, 10, 21), 'the second row');
end;

procedure TTestGreedMouseCursor.DovrebbeDisegnareOgniPixelDueVolteSulQuadroDoppio;
var
  LFrame: TGreedFrame;
begin
  LFrame := TGreedFrame.Make(640, 400);
  FCursor.Draw(LFrame, 100, 50);
  // the pixel 3 of the first row (the color 4) is the block of 2 x 2 at 206, 100
  Assert.AreEqual(4, Pixel(LFrame, 206, 100));
  Assert.AreEqual(4, Pixel(LFrame, 207, 100));
  Assert.AreEqual(4, Pixel(LFrame, 206, 101));
  Assert.AreEqual(4, Pixel(LFrame, 207, 101));
  Assert.AreEqual(5, Pixel(LFrame, 208, 100));
  // the last pixel of the picture: row 15, column 15, color 1 + 255 mod 250
  Assert.AreEqual(6, Pixel(LFrame, 200 + 31, 100 + 31));
  Assert.AreEqual(0, Pixel(LFrame, 200 + 32, 100 + 31), 'nothing beyond the 16 pixels');
  Assert.AreEqual((GREED_MOUSE_SIZE * GREED_MOUSE_SIZE - 2) * 4, Drawn(LFrame));
end;

procedure TTestGreedMouseCursor.DovrebbeDisegnareUnPixelPerPixelSulQuadroBasso;
var
  LFrame: TGreedFrame;
begin
  LFrame := TGreedFrame.Make(320, 200);
  FCursor.Draw(LFrame, 100, 50);
  Assert.AreEqual(4, Pixel(LFrame, 103, 50));
  Assert.AreEqual(5, Pixel(LFrame, 104, 50));
  Assert.AreEqual(GREED_MOUSE_SIZE * GREED_MOUSE_SIZE - 2, Drawn(LFrame));
end;

procedure TTestGreedMouseCursor.NonDovrebbeDisegnareIColoriZeroEDuecentocinquantacinque;
var
  LFrame: TGreedFrame;
  LIndex: Integer;
begin
  LFrame := TGreedFrame.Make(320, 200);
  for LIndex := 0 to High(LFrame.Pixels) do
    LFrame.Pixels[LIndex] := 77;
  FCursor.Draw(LFrame, 0, 0);
  Assert.AreEqual(1, Pixel(LFrame, 0, 0));
  Assert.AreEqual(77, Pixel(LFrame, 1, 0), 'the color 0 lets the picture show');
  Assert.AreEqual(77, Pixel(LFrame, 2, 0), 'and so does the color 255');
  Assert.AreEqual(4, Pixel(LFrame, 3, 0));
end;

procedure TTestGreedMouseCursor.DovrebbeTagliareCioCheEsceDalQuadro;
var
  LFrame: TGreedFrame;
  LOther: TGreedFrame;
begin
  LFrame := TGreedFrame.Make(640, 400);
  // the pointer can be at the last pixel of the screen: one pixel of it is inside
  FCursor.Draw(LFrame, 319, 199);
  Assert.AreEqual(1, Pixel(LFrame, 638, 398));
  Assert.AreEqual(1, Pixel(LFrame, 639, 399));
  Assert.AreEqual(4, Drawn(LFrame));
  LOther := TGreedFrame.Make(640, 400);
  FCursor.Draw(LOther, -20, -20);
  Assert.AreEqual(0, Drawn(LOther), 'all of it is outside');
end;

procedure TTestGreedMouseCursor.DovrebbeArrotondareLaPosizioneRaddoppiata;
var
  LFrame: TGreedFrame;
begin
  LFrame := TGreedFrame.Make(640, 400);
  // 2 * 10.25 = 20.5 rounds to 20 (to the even one), 2 * 10.75 = 21.5 to 22
  FCursor.Draw(LFrame, 10.25, 10.75);
  Assert.AreEqual(1, Pixel(LFrame, 20, 22));
  Assert.AreEqual(0, Pixel(LFrame, 20, 21));
end;

procedure TTestGreedMouseCursor.NonDovrebbeDisegnareSuUnQuadroTroppoStretto;
var
  LFrame: TGreedFrame;
  LOther: TGreedFrame;
begin
  LFrame := TGreedFrame.Make(160, 100);
  FCursor.Draw(LFrame, 5, 5);
  Assert.AreEqual(0, Drawn(LFrame));
  // a frame that says more pixels than it has
  LOther := TGreedFrame.Make(320, 200);
  LOther.Height := 300;
  FCursor.Draw(LOther, 5, 5);
  Assert.AreEqual(0, Drawn(LOther));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGreedMouseCursor);

end.
