{******************************************************************************}
{                                                                              }
{  DelphiDoom: parity of the codebook modes with the code of Quake III Arena   }
{                                                                              }
{  The golden file (Tests\Data\Cinematic\modes.golden.txt) is the output of     }
{  decodeCodeBook of cl_cin.c compiled with the i686 gcc of w64devkit          }
{  (Tools\Verifica\114\modeextract.c): for every combination of 32 bit, 16 bit  }
{  and gray pixels with normal, smootheddouble and half, three chunks of bytes  }
{  of a fixed generator (flags 0, $1004, $0003) and a CRC-32 of vq2, vq4 and   }
{  vq8 after each chunk; the first line is the CRC-32 of yuv_to_rgb.            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Cinematic.ModeParity;

interface

uses
  System.SysUtils, System.Classes,
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('cinematic')]
  [Category('parity')]
  TTestRoqModeParity = class(TObject)
  strict private
    FLines: TStringList;
    procedure RunScenario(APixelSize: Integer; AHalf, ASmoothed: Boolean);
    function Digest(const ABytes: TBytes): string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDareLeStesseImprontaDelCPerOgniModo;
  end;

implementation

uses
  DelphiDoom.MathCore.Crc32,
  DelphiDoom.Cinematic.Types,
  DelphiDoom.Cinematic.ModeCodebook,
  DelphiDoom.Cinematic.Factory,
  DelphiDoom.Tests.Cinematic.Support;

{$Q-}
{$R-}

{ TTestRoqModeParity }

procedure TTestRoqModeParity.Setup;
begin
  FLines := TStringList.Create;
end;

procedure TTestRoqModeParity.TearDown;
begin
  FLines.Free;
end;

function TTestRoqModeParity.Digest(const ABytes: TBytes): string;
begin
  Result := LowerCase(IntToHex(TCrc32.Calculate(ABytes[0], Length(ABytes)), 8));
end;

procedure TTestRoqModeParity.RunScenario(APixelSize: Integer; AHalf, ASmoothed: Boolean);
const
  CFlags: array[0..2] of Word = ($0000, $1004, $0003);
var
  LMode: TRoqCodebookMode;
  LGray, LInput: TBytes;
  LCodebook: TRoqModeCodebook;
  LState: Cardinal;
  LIndex, LChunk: Integer;
begin
  case APixelSize of
    4: LMode.PixelFormat := rpfRgba32;
    2: LMode.PixelFormat := rpfRgb565;
  else
    LMode.PixelFormat := rpfGray8;
  end;
  LMode.Half := AHalf;
  LMode.SmoothedDouble := ASmoothed;
  SetLength(LGray, 256);
  for LIndex := 0 to 255 do
    LGray[LIndex] := (LIndex * 37 + 11) and 255;
  SetLength(LInput, 4096);
  LState := 987654321;
  LCodebook := TCinematicFactory.CreateModeCodebook(LMode, ROQ_ALPHA_OPAQUE, LGray);
  try
    for LChunk := 0 to 2 do
    begin
      for LIndex := 0 to 4095 do
      begin
        LState := LState * Cardinal(1664525) + Cardinal(1013904223);
        LInput[LIndex] := Byte(LState shr 16);
      end;
      LCodebook.Decode(LInput, CFlags[LChunk]);
      FLines.Add(Format('mode size %d half %d smooth %d chunk %d flags %s vq2 %s vq4 %s vq8 %s',
        [APixelSize, Ord(AHalf), Ord(ASmoothed), LChunk, LowerCase(IntToHex(CFlags[LChunk], 4)),
        Digest(LCodebook.Vq2Bytes), Digest(LCodebook.Vq4Bytes), Digest(LCodebook.Vq8Bytes)]));
    end;
  finally
    LCodebook.Free;
  end;
end;

procedure TTestRoqModeParity.DovrebbeDareLeStesseImprontaDelCPerOgniModo;
const
  CSizes: array[0..2] of Integer = (4, 2, 1);
var
  LGolden: TStringList;
  LSize, LMode, LIndex: Integer;
begin
  LGolden := TRoqTestData.ReadLines('modes.golden.txt');
  try
    for LSize := 0 to 2 do
      for LMode := 0 to 2 do
        RunScenario(CSizes[LSize], LMode = 2, LMode = 1);
    // half wins over smootheddouble
    RunScenario(4, True, True);
    Assert.AreEqual(LGolden.Count - 1, FLines.Count, 'number of lines');
    for LIndex := 0 to FLines.Count - 1 do
      Assert.AreEqual(LGolden[LIndex + 1], FLines[LIndex], 'line ' + IntToStr(LIndex));
  finally
    LGolden.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestRoqModeParity);

end.
