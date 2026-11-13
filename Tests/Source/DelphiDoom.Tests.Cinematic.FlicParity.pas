{******************************************************************************}
{                                                                              }
{  DelphiDoom: parity of the FLIC decoder with the code of OpenXcom            }
{                                                                              }
{  The golden files (Tests\Data\Cinematic\flic-*.golden.txt) are the output    }
{  of the decoder of FlcPlayer.cpp of OpenXcom (the very lines of the file,    }
{  see Tools\Verifica\199\build.sh) compiled with the gcc of w64devkit, on     }
{  the files flic-*.flc made by Tools\Verifica\199\flcgen.c (random content,   }
{  fixed seeds) and on the 13 animations of Warcraft: Orcs and Humans, which   }
{  are read where they are (DELPHIDOOM_WAR_DATA or Reference\_dati\warcraft)   }
{  and ignored if missing. A line is "frame N pix <CRC-32 of the picture>      }
{  pal <CRC-32 of the 768 bytes of the palette> delay <ms>".                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Cinematic.FlicParity;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('cinematic')]
  [Category('parity')]
  TTestFlicParity = class(TObject)
  strict private
    procedure CompareWithGolden(const ABytes: TBytes; const AGoldenName: string);
  public
    [Test]
    [TestCase('basic', 'basic')]
    [TestCase('fli', 'fli')]
    [TestCase('wide', 'wide')]
    [TestCase('tall', 'tall')]
    procedure DovrebbeDareLeStesseImprontaDelCperIFileDiProva(const AName: string);
    [Test]
    [TestCase('CAVE1', 'CAVE1')]
    [TestCase('CAVE2', 'CAVE2')]
    [TestCase('CAVE3', 'CAVE3')]
    [TestCase('HFINALE', 'HFINALE')]
    [TestCase('HINTRO1', 'HINTRO1')]
    [TestCase('HINTRO2', 'HINTRO2')]
    [TestCase('LOSE2', 'LOSE2')]
    [TestCase('OFINALE', 'OFINALE')]
    [TestCase('OINTRO1', 'OINTRO1')]
    [TestCase('OINTRO2', 'OINTRO2')]
    [TestCase('OINTRO3', 'OINTRO3')]
    [TestCase('TITLE', 'TITLE')]
    [TestCase('WIN2', 'WIN2')]
    procedure DovrebbeDareLeStesseImprontaDelCperIFilmatiVeriDiWarcraft(const AName: string);
    [Test]
    procedure DovrebbeEscludereLUltimoFotogrammaDelCicloNeiFilmatiVeri;
  end;

implementation

uses
  System.IOUtils,
  DelphiDoom.Cinematic.Flic.Intf,
  DelphiDoom.Cinematic.Flic.Factory,
  DelphiDoom.Tests.Cinematic.FlicSupport;

{ TTestFlicParity }

procedure TTestFlicParity.CompareWithGolden(const ABytes: TBytes; const AGoldenName: string);
var
  LLines: TArray<string>;
  LDecoder: IFlicDecoder;
  LLine: string;
  LParts: TArray<string>;
  LFrames: Integer;
begin
  LLines := TFlicTestData.ReadLines(AGoldenName);
  // with the ring frame: the C++ plays every frame of the file
  LDecoder := TFlicFactory.CreateDecoder(ABytes, True);
  LFrames := 0;
  for LLine in LLines do
  begin
    LParts := LLine.Split([' ']);
    if (Length(LParts) < 8) or (LParts[0] <> 'frame') then
      Continue;
    Assert.IsTrue(LDecoder.NextFrame, 'missing frame ' + LParts[1]);
    Assert.AreEqual(StrToInt(LParts[1]), LDecoder.FrameIndex);
    Assert.AreEqual(LParts[3], LowerCase(IntToHex(IndicesCrc(LDecoder.Indices), 8)),
      'picture of frame ' + LParts[1]);
    Assert.AreEqual(LParts[5], LowerCase(IntToHex(PaletteCrc(LDecoder.Palette), 8)),
      'palette of frame ' + LParts[1]);
    Assert.AreEqual(StrToInt(LParts[7]), LDecoder.FrameDelay, 'delay of frame ' + LParts[1]);
    Inc(LFrames);
  end;
  Assert.IsTrue(LFrames > 0);
  Assert.IsFalse(LDecoder.NextFrame, 'more frames than the C++');
  Assert.AreEqual(LFrames, LDecoder.FrameCount);
end;

procedure TTestFlicParity.DovrebbeDareLeStesseImprontaDelCperIFileDiProva(const AName: string);
begin
  CompareWithGolden(TFlicTestData.ReadBytes('flic-' + AName + '.flc'),
    'flic-' + AName + '.golden.txt');
end;

procedure TTestFlicParity.DovrebbeDareLeStesseImprontaDelCperIFilmatiVeriDiWarcraft(const AName: string);
var
  LFile: string;
begin
  LFile := TFlicTestData.WarcraftFolder;
  if LFile = '' then
  begin
    Assert.Pass('the data of Warcraft are not here');
    Exit;
  end;
  LFile := TPath.Combine(LFile, AName + '.WAR');
  if not TFile.Exists(LFile) then
  begin
    Assert.Pass(AName + '.WAR is not here');
    Exit;
  end;
  CompareWithGolden(TFile.ReadAllBytes(LFile), 'flic-war-' + AName + '.golden.txt');
end;

procedure TTestFlicParity.DovrebbeEscludereLUltimoFotogrammaDelCicloNeiFilmatiVeri;
var
  LFolder: string;
  LDecoder: IFlicDecoder;
begin
  LFolder := TFlicTestData.WarcraftFolder;
  if (LFolder = '') or not TFile.Exists(TPath.Combine(LFolder, 'TITLE.WAR')) then
  begin
    Assert.Pass('the data of Warcraft are not here');
    Exit;
  end;
  LDecoder := TFlicFactory.CreateDecoder(TFile.ReadAllBytes(TPath.Combine(LFolder, 'TITLE.WAR')));
  // the header of TITLE.WAR says 21 frames, the file has 22: the last one is the ring
  Assert.AreEqual(21, LDecoder.HeaderFrames);
  Assert.AreEqual(21, LDecoder.FrameCount);
  Assert.AreEqual(320, LDecoder.Width);
  Assert.AreEqual(200, LDecoder.Height);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestFlicParity);

end.
