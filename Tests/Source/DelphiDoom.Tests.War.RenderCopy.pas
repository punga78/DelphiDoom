{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - the copy 1:1 of the blitter          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.RenderCopy;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.War.Graphics.Types, DelphiDoom.War.Render.Types,
  DelphiDoom.War.Render.Blitter;

type
  /// <summary>
  ///   A copy that is all inside the canvas goes straight (DrawCopy); a copy that goes over the edge goes pixel by pixel
  ///   through the general blit. The pixels they both draw must be the same, for every alpha, on a canvas that is opaque
  ///   and on one that is not
  /// </summary>
  [TestFixture]
  [Category('war')]
  TTestWarRenderCopy = class(TObject)
  strict private
    function Source: TWarImage;
    function Canvas(AAlpha: Integer): TWarImageBlitter;
    procedure Copy(const ACanvas: TWarImageBlitter; AX: Integer);
  public
    [Test]
    [TestCase('Tela opaca', '255')]
    [TestCase('Tela con alfa', '100')]
    procedure DovrebbeDisegnareLaCopiaDirettaComeQuellaPixelPerPixel(AAlpha: Integer);
    [Test]
    procedure DovrebbeSostituireIPixelOpachiELasciareITrasparenti;
  end;

implementation

{ TTestWarRenderCopy }

function TTestWarRenderCopy.Source: TWarImage;
var
  LIndex: Integer;
begin
  // 16 x 3 pixels with every kind of alpha: transparent, opaque and the partial ones in between
  Result.Width := 16;
  Result.Height := 3;
  SetLength(Result.Pixels, 16 * 3 * 4);
  for LIndex := 0 to 16 * 3 - 1 do
  begin
    Result.Pixels[LIndex * 4] := (LIndex * 37 + 11) and $FF;
    Result.Pixels[LIndex * 4 + 1] := (LIndex * 91 + 5) and $FF;
    Result.Pixels[LIndex * 4 + 2] := (LIndex * 53 + 200) and $FF;
    case LIndex mod 6 of
      0: Result.Pixels[LIndex * 4 + 3] := 0;
      1: Result.Pixels[LIndex * 4 + 3] := 255;
      2: Result.Pixels[LIndex * 4 + 3] := 128;
      3: Result.Pixels[LIndex * 4 + 3] := 255;
      4: Result.Pixels[LIndex * 4 + 3] := 17;
    else
      Result.Pixels[LIndex * 4 + 3] := 254;
    end;
  end;
end;

function TTestWarRenderCopy.Canvas(AAlpha: Integer): TWarImageBlitter;
var
  LColor: TWarRgba;
begin
  Result := TWarImageBlitter.Create(32, 8);
  LColor.R := 60;
  LColor.G := 120;
  LColor.B := 180;
  LColor.A := AAlpha;
  Result.Clear(LColor);
end;

procedure TTestWarRenderCopy.Copy(const ACanvas: TWarImageBlitter; AX: Integer);
var
  LBlit: TWarBlit;
begin
  LBlit.Source.X := 0;
  LBlit.Source.Y := 0;
  LBlit.Source.Width := 16;
  LBlit.Source.Height := 3;
  LBlit.Destination.X := AX;
  LBlit.Destination.Y := 2;
  LBlit.Destination.Width := 16;
  LBlit.Destination.Height := 3;
  LBlit.FlipHorizontal := False;
  LBlit.FlipVertical := False;
  LBlit.Color.R := 255;
  LBlit.Color.G := 255;
  LBlit.Color.B := 255;
  LBlit.Color.A := 255;
  ACanvas.Draw(Source, LBlit);
end;

procedure TTestWarRenderCopy.DovrebbeDisegnareLaCopiaDirettaComeQuellaPixelPerPixel(AAlpha: Integer);
var
  LInside: TWarImageBlitter;
  LOver: TWarImageBlitter;
  LRow: Integer;
  LColumn: Integer;
  LChannel: Integer;
  LCompared: Integer;
begin
  LInside := Canvas(AAlpha);
  LOver := Canvas(AAlpha);
  try
    // all inside the canvas at x = 0 (direct); the same picture one pixel to the left goes over the edge (pixel by pixel)
    Copy(LInside, 0);
    Copy(LOver, -1);
    LCompared := 0;
    for LRow := 2 to 4 do
      for LColumn := 1 to 14 do
        for LChannel := 0 to 3 do
        begin
          Assert.AreEqual<Integer>(LOver.Pixels[((LRow * 32) + LColumn - 1) * 4 + LChannel],
            LInside.Pixels[((LRow * 32) + LColumn) * 4 + LChannel],
            Format('riga %d colonna %d canale %d', [LRow, LColumn, LChannel]));
          Inc(LCompared);
        end;
    Assert.AreEqual(3 * 14 * 4, LCompared);
  finally
    LOver.Free;
    LInside.Free;
  end;
end;

procedure TTestWarRenderCopy.DovrebbeSostituireIPixelOpachiELasciareITrasparenti;
var
  LCanvas: TWarImageBlitter;
begin
  LCanvas := Canvas(255);
  try
    Copy(LCanvas, 4);
    // the pixel 0 of the row 0 is transparent (alpha 0): the canvas stays as it was; the pixel 1 is opaque: it is the source
    Assert.AreEqual<Integer>(60, LCanvas.Pixels[(2 * 32 + 4) * 4]);
    Assert.AreEqual<Integer>(Source.Pixels[4], LCanvas.Pixels[(2 * 32 + 5) * 4]);
    Assert.AreEqual<Integer>(255, LCanvas.Pixels[(2 * 32 + 5) * 4 + 3]);
  finally
    LCanvas.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestWarRenderCopy);

end.
