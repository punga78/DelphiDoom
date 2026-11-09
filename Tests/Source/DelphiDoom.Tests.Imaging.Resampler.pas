{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TImagingLanczosResampler                                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Imaging.Resampler;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.Imaging.Intf;

type
  /// <summary>
  ///   Tests\Data\Imaging\lanczos.golden.txt has the 160x50 pictures that the resampler of Graphics32 (TKernelResampler
  ///   with TLanczosKernel, as ee_textart of ENDEDIT uses it) made from the pictures of TResampleCases, written by
  ///   Tools\Verifica\164\H3.dpr (the old BitmapLanczosDraw, compiled with the original Graphics32). The two must be
  ///   the same, pixel by pixel: Win32 compiles both with the same Single arithmetic
  /// </summary>
  [TestFixture]
  [Category('imaging')]
  TTestImagingResampler = class(TObject)
  strict private
    FResampler: IImagingResampler;
    function Solid(AWidth, AHeight: Integer; AColor: Cardinal): TArray<Cardinal>;
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure DovrebbeDareLaDimensioneChiesta;
    [Test]
    procedure DovrebbeLasciareUnaPitturaDelloStessoColoreDelloStessoColore;
    [Test]
    procedure DovrebbeCopiareUnaPitturaDellaStessaDimensione;
    [Test]
    procedure DovrebbeRiempireConUnSoloPixel;
    [Test]
    procedure DovrebbeTenereIlColoreDiUnaMetaSolida;
    [Test]
    procedure DovrebbeNonUscireDalLimiteDeiCanali;
    [Test]
    procedure DovrebbeTrattareIlCanaleAlphaComeGliAltri;
    [Test]
    procedure DovrebbeRifiutareUnaDimensioneNonValida;
    [Test]
    procedure DovrebbeRifiutareUnaPitturaDiLunghezzaSbagliata;
    [Test]
    procedure DovrebbeIngrandireUnaPitturaPiccola;
    [Test]
    procedure DovrebbeDareGliStessiPixelDiGraphics32;
  end;

implementation

uses
  DelphiDoom.Imaging.Types, DelphiDoom.Imaging.Resampler,
  DelphiDoom.Tests.Imaging.Golden, DelphiDoom.Tests.Imaging.ResampleCases, DelphiDoom.Tests.Endoom.Digest;

{ TTestImagingResampler }

procedure TTestImagingResampler.Setup;
begin
  FResampler := TImagingLanczosResampler.Create;
end;

function TTestImagingResampler.Solid(AWidth, AHeight: Integer; AColor: Cardinal): TArray<Cardinal>;
var
  LIndex: Integer;
begin
  SetLength(Result, AWidth * AHeight);
  for LIndex := 0 to High(Result) do
    Result[LIndex] := AColor;
end;

procedure TTestImagingResampler.DovrebbeDareLaDimensioneChiesta;
begin
  Assert.AreEqual(160 * 50, Length(FResampler.Resample(Solid(640, 400, 0), 640, 400, 160, 50)));
  Assert.AreEqual(7 * 3, Length(FResampler.Resample(Solid(5, 9, 0), 5, 9, 7, 3)));
end;

procedure TTestImagingResampler.DovrebbeLasciareUnaPitturaDelloStessoColoreDelloStessoColore;
var
  LResult: TArray<Cardinal>;
  LPixel: Cardinal;
begin
  LResult := FResampler.Resample(Solid(300, 200, $FF336699), 300, 200, 160, 50);
  for LPixel in LResult do
    Assert.AreEqual(Int64($FF336699), Int64(LPixel));
  LResult := FResampler.Resample(Solid(20, 20, $00FFFFFF), 20, 20, 160, 50);
  for LPixel in LResult do
    Assert.AreEqual(Int64($00FFFFFF), Int64(LPixel));
end;

procedure TTestImagingResampler.DovrebbeCopiareUnaPitturaDellaStessaDimensione;
var
  LSource: TArray<Cardinal>;
  LWidth: Integer;
  LHeight: Integer;
  LResult: TArray<Cardinal>;
  LIndex: Integer;
begin
  LSource := TResampleCases.Build(7, LWidth, LHeight);
  Assert.AreEqual(160, LWidth);
  Assert.AreEqual(50, LHeight);
  LResult := FResampler.Resample(LSource, LWidth, LHeight, 160, 50);
  for LIndex := 0 to High(LSource) do
    Assert.AreEqual(Int64(LSource[LIndex] and $FFFFFF), Int64(LResult[LIndex] and $FFFFFF));
end;

procedure TTestImagingResampler.DovrebbeRiempireConUnSoloPixel;
var
  LResult: TArray<Cardinal>;
  LPixel: Cardinal;
begin
  LResult := FResampler.Resample([$336699], 1, 1, 160, 50);
  Assert.AreEqual(160 * 50, Length(LResult));
  for LPixel in LResult do
    Assert.AreEqual(Int64($336699), Int64(LPixel and $FFFFFF));
end;

procedure TTestImagingResampler.DovrebbeTenereIlColoreDiUnaMetaSolida;
var
  LSource: TArray<Cardinal>;
  LResult: TArray<Cardinal>;
  LX: Integer;
  LY: Integer;
begin
  // left half red, right half blue: far from the edge between them the colors do not change
  SetLength(LSource, 400 * 100);
  for LY := 0 to 99 do
    for LX := 0 to 399 do
      if LX < 200 then
        LSource[LY * 400 + LX] := $FF0000
      else
        LSource[LY * 400 + LX] := $0000FF;
  LResult := FResampler.Resample(LSource, 400, 100, 160, 50);
  Assert.AreEqual(Int64($FF0000), Int64(LResult[10 * 160 + 5] and $FFFFFF));
  Assert.AreEqual(Int64($0000FF), Int64(LResult[10 * 160 + 150] and $FFFFFF));
end;

procedure TTestImagingResampler.DovrebbeNonUscireDalLimiteDeiCanali;
var
  LSource: TArray<Cardinal>;
  LResult: TArray<Cardinal>;
  LPixel: Cardinal;
  LX: Integer;
begin
  // the kernel has negative lobes: a black and white stripe overshoots, and the channel is cut at 0 and 255
  SetLength(LSource, 64);
  for LX := 0 to 63 do
    if Odd(LX div 4) then
      LSource[LX] := $FFFFFF
    else
      LSource[LX] := 0;
  LResult := FResampler.Resample(LSource, 64, 1, 160, 1);
  for LPixel in LResult do
  begin
    Assert.IsTrue((LPixel and $FF) <= 255);
    Assert.AreEqual(Int64(LPixel and $FF), Int64((LPixel shr 8) and $FF));
  end;
end;

procedure TTestImagingResampler.DovrebbeTrattareIlCanaleAlphaComeGliAltri;
var
  LResult: TArray<Cardinal>;
begin
  LResult := FResampler.Resample(Solid(10, 10, $80102030), 10, 10, 20, 20);
  Assert.AreEqual(Int64($80102030), Int64(LResult[0]));
  Assert.AreEqual(Int64($80102030), Int64(LResult[399]));
end;

procedure TTestImagingResampler.DovrebbeRifiutareUnaDimensioneNonValida;
begin
  Assert.WillRaise(
    procedure
    begin
      FResampler.Resample(Solid(1, 1, 0), 1, 1, 0, 5);
    end, EImagingException);
  Assert.WillRaise(
    procedure
    begin
      FResampler.Resample(Solid(1, 1, 0), 1, 1, 5, -1);
    end, EImagingException);
  Assert.WillRaise(
    procedure
    begin
      FResampler.Resample(nil, 0, 0, 5, 5);
    end, EImagingException);
end;

procedure TTestImagingResampler.DovrebbeRifiutareUnaPitturaDiLunghezzaSbagliata;
begin
  Assert.WillRaise(
    procedure
    begin
      FResampler.Resample(Solid(3, 3, 0), 4, 3, 5, 5);
    end, EImagingException);
end;

procedure TTestImagingResampler.DovrebbeIngrandireUnaPitturaPiccola;
var
  LResult: TArray<Cardinal>;
begin
  // 2x1 black and white to 8x1: the first and the last pixels keep their color, between them it goes from one to the other
  LResult := FResampler.Resample([$000000, $FFFFFF], 2, 1, 8, 1);
  Assert.AreEqual(Int64(0), Int64(LResult[0] and $FF));
  Assert.AreEqual(Int64($FF), Int64(LResult[7] and $FF));
  Assert.IsTrue((LResult[3] and $FF) < (LResult[4] and $FF));
end;

procedure TTestImagingResampler.DovrebbeDareGliStessiPixelDiGraphics32;
var
  LCase: Integer;
  LWidth: Integer;
  LHeight: Integer;
  LSource: TArray<Cardinal>;
  LResult: TArray<Cardinal>;
  LMasked: TArray<Cardinal>;
  LIndex: Integer;
begin
  for LCase := 0 to TResampleCases.Count - 1 do
  begin
    LSource := TResampleCases.Build(LCase, LWidth, LHeight);
    LResult := FResampler.Resample(LSource, LWidth, LHeight, 160, 50);
    // the old picture was read as a color of Windows: red, green and blue only
    SetLength(LMasked, Length(LResult));
    for LIndex := 0 to High(LResult) do
      LMasked[LIndex] := LResult[LIndex] and $FFFFFF;
    TImagingGolden.Check('lanczos.golden.txt', TResampleCases.Name(LCase), TEndoomDigest.OfCardinals(LMasked));
  end;
end;

end.
