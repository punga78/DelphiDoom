{******************************************************************************}
{                                                                              }
{  DelphiDoom: parity of the RoQ decoder with the code of Quake III Arena      }
{                                                                              }
{  The golden files (Tests\Data\Cinematic\*.golden.txt) are the output of      }
{  the decoder of Quake III Arena (cl_cin.c: RoQInterrupt, decodeCodeBook,     }
{  blitVQQuad32fs, RllDecode*...) compiled with gcc of w64devkit, on the       }
{  small files *.roq made by Tools\Verifica\114\roqgen.c (random content,      }
{  fixed seeds, no commercial material), and on the real file idlogo.RoQ of    }
{  OpenArena, which is read where it is (the pk3 of Reference\openarena) and   }
{  skipped if it is missing. A line is a CRC-32 of the 32 bit pixels of a      }
{  frame, or of the 16 bit samples of an audio chunk (see README.md of the     }
{  library, "Parity").                                                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Cinematic.Parity;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('cinematic')]
  [Category('parity')]
  TTestRoqParity = class(TObject)
  strict private
    procedure CompareWithGolden(const ARoq: TBytes; const AGoldenName: string;
      AAllowStaleRepeats: Boolean = False);
    function FindOpenArenaPak: string;
  public
    [Test]
    procedure DovrebbeDareLeStesseImprontaDelCPerIlFileBasic;
    [Test]
    procedure DovrebbeDareLeStesseImprontaDelCPerIlFileWide;
    [Test]
    procedure DovrebbeDareLeStesseImprontaDelCPerIlFileStereo;
    [Test]
    procedure DovrebbeDareLeStesseImprontaDelCPerIlFileVeroDiOpenArena;
  end;

implementation

uses
  System.Classes, System.IOUtils, System.Zip,
  DelphiDoom.Cinematic.Types,
  DelphiDoom.Cinematic.Intf,
  DelphiDoom.Cinematic.Factory,
  DelphiDoom.Tests.Cinematic.Support;

type
  /// <summary>Writes a line for every block of audio, as the golden file does</summary>
  TLineSink = class(TInterfacedObject, IRoqAudioSink)
  strict private
    FLines: TStringList;
    FCount: Integer;
  public
    constructor Create(const ALines: TStringList);
    procedure AudioReceived(const ASamples: TArray<SmallInt>; AChannels, ASampleRate: Integer);
  end;

{ TLineSink }

constructor TLineSink.Create(const ALines: TStringList);
begin
  inherited Create;
  FLines := ALines;
end;

procedure TLineSink.AudioReceived(const ASamples: TArray<SmallInt>; AChannels, ASampleRate: Integer);
begin
  // the golden line has the number of sample pairs and the CRC of all the bytes of the block
  FLines.Add(Format('audio %d samples %d full %s',
    [FCount, Length(ASamples) div 2, LowerCase(IntToHex(SamplesCrc(ASamples), 8))]));
  Inc(FCount);
end;

{ TTestRoqParity }

procedure TTestRoqParity.CompareWithGolden(const ARoq: TBytes; const AGoldenName: string;
  AAllowStaleRepeats: Boolean);
var
  LGolden, LMine, LExpected: TStringList;
  LDecoder: IRoqDecoder;
  LSink: IRoqAudioSink;
  LKind: TRoqChunkKind;
  LFrames, LAudio, LIndex, LStale: Integer;
  LParts: TArray<string>;
  LLine: string;
begin
  LGolden := TRoqTestData.ReadLines(AGoldenName);
  LMine := TStringList.Create;
  LExpected := TStringList.Create;
  try
    LSink := TLineSink.Create(LMine);
    LDecoder := TCinematicFactory.CreateDecoder(TCinematicFactory.CreateMemorySource(ARoq), LSink);
    LFrames := 0;
    while LDecoder.ReadChunk(LKind) do
      if LKind = rckFrame then
      begin
        LMine.Add(Format('frame %d crc %s', [LFrames, LowerCase(IntToHex(PixelsCrc(LDecoder.Frame), 8))]));
        Inc(LFrames);
      end;
    // the lines of the golden file that the decoder can reproduce, with the fields in common
    LAudio := 0;
    LStale := 0;
    for LLine in LGolden do
    begin
      LParts := LLine.Split([' ']);
      if LParts[0] = 'fps' then
        Assert.AreEqual(StrToInt(LParts[1]), LDecoder.FramesPerSecond, 'fps')
      else if LParts[0] = 'size' then
      begin
        Assert.AreEqual(StrToInt(LParts[1]), LDecoder.Width, 'width');
        Assert.AreEqual(StrToInt(LParts[2]), LDecoder.Height, 'height');
      end
      else if LParts[0] = 'frame' then
      begin
        // Quake III keeps redecoding the last chunk of a file after its end (see README.md,
        // "Difetti del C"): those repeated frames are not in the file
        if AAllowStaleRepeats and (StrToInt(LParts[1]) >= LFrames) then
        begin
          Assert.AreEqual(LowerCase(IntToHex(PixelsCrc(LDecoder.Frame), 8)), LParts[3],
            'stale frame ' + LParts[1]);
          Inc(LStale);
        end
        else
          LExpected.Add(LLine);
      end
      else if LParts[0] = 'audio' then
      begin
        // audio N channels C rate R samples S consumed X full Y
        LExpected.Add(Format('audio %s samples %s full %s', [LParts[1], LParts[7], LParts[11]]));
        Inc(LAudio);
      end
      else if LParts[0] = 'frames' then
      begin
        Assert.AreEqual(StrToInt(LParts[1]), LFrames + LStale, 'number of frames');
        Assert.AreEqual(StrToInt(LParts[3]), LAudio, 'number of audio chunks');
      end;
    end;
    Assert.IsTrue(LFrames > 0);
    Assert.AreEqual(LExpected.Count, LMine.Count, 'number of fingerprints');
    for LIndex := 0 to LExpected.Count - 1 do
      Assert.AreEqual(LExpected[LIndex], LMine[LIndex], 'fingerprint ' + IntToStr(LIndex));
  finally
    LExpected.Free;
    LMine.Free;
    LGolden.Free;
  end;
end;

function TTestRoqParity.FindOpenArenaPak: string;
const
  RELATIVE = 'Reference\openarena\openarena-0.8.8\baseoa\pak6-misc.pk3';
var
  LBase: string;
  LCandidates: array[0..3] of string;
  LIndex: Integer;
begin
  LBase := ExtractFilePath(ParamStr(0));
  // beside the test executable or in the main checkout above a worktree (.claude\worktrees\name)
  LCandidates[0] := LBase + '..\..\' + RELATIVE;
  LCandidates[1] := LBase + '..\..\..\..\..\' + RELATIVE;
  LCandidates[2] := LBase + '..\..\..\..\..\..\' + RELATIVE;
  LCandidates[3] := GetEnvironmentVariable('DELPHIDOOM_OPENARENA_PAK');
  Result := '';
  for LIndex := 0 to High(LCandidates) do
    if (LCandidates[LIndex] <> '') and TFile.Exists(TPath.GetFullPath(LCandidates[LIndex])) then
      Exit(TPath.GetFullPath(LCandidates[LIndex]));
end;

procedure TTestRoqParity.DovrebbeDareLeStesseImprontaDelCPerIlFileBasic;
begin
  CompareWithGolden(TRoqTestData.ReadBytes('basic.roq'), 'basic.golden.txt');
end;

procedure TTestRoqParity.DovrebbeDareLeStesseImprontaDelCPerIlFileWide;
begin
  CompareWithGolden(TRoqTestData.ReadBytes('wide.roq'), 'wide.golden.txt');
end;

procedure TTestRoqParity.DovrebbeDareLeStesseImprontaDelCPerIlFileStereo;
begin
  CompareWithGolden(TRoqTestData.ReadBytes('stereo.roq'), 'stereo.golden.txt');
end;

procedure TTestRoqParity.DovrebbeDareLeStesseImprontaDelCPerIlFileVeroDiOpenArena;
var
  LPak: string;
  LZip: TZipFile;
  LBytes: TBytes;
  LIndex: Integer;
begin
  LPak := FindOpenArenaPak;
  if LPak = '' then
  begin
    Assert.Pass('pak6-misc.pk3 of OpenArena not found: skipped');
    Exit;
  end;
  LZip := TZipFile.Create;
  try
    LZip.Open(LPak, zmRead);
    LIndex := LZip.IndexOf('video/idlogo.RoQ');
    if LIndex < 0 then
    begin
      Assert.Pass('video/idlogo.RoQ not in the pk3: skipped');
      Exit;
    end;
    LZip.Read(LIndex, LBytes);
  finally
    LZip.Free;
  end;
  CompareWithGolden(LBytes, 'idlogo.golden.txt', True);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestRoqParity);

end.
