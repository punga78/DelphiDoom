{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TRoqSoundDecoder                                       }
{                                                                              }
{  The golden lines (Tests\Data\Cinematic\tables.golden.txt, "rll ...") are    }
{  made by the RllDecode* functions of Quake III Arena (cl_cin.c) compiled     }
{  with gcc: Tools\Verifica\114. The input is a buffer of 4096 bytes made by   }
{  a linear congruential generator (seed 12345) that the test repeats.         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Cinematic.SoundDecoder;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('cinematic')]
  TTestRoqSoundDecoder = class(TObject)
  public
    [Test]
    procedure DovrebbeSommareIQuadratiConSegno;
    [Test]
    procedure DovrebbeRaddoppiareIlMonoInStereo;
    [Test]
    procedure DovrebbeSeparareIDueCanaliDelloStereo;
    [Test]
    procedure DovrebbeFareLaMediaDelloStereoInMono;
    [Test]
    procedure DovrebbeFareGiroSuSedicibit;
    [Test]
    procedure DovrebbeSollevareSeIDatiSonoPochi;
    [Test]
    procedure DovrebbeScartareLUltimoByteDiUnaDimensioneDispari;
    [Test]
    procedure DovrebbeDareLeStesseImprontedelC;
  end;

implementation

uses
  System.SysUtils, System.Classes,
  DelphiDoom.Cinematic.Types,
  DelphiDoom.Cinematic.SoundDecoder,
  DelphiDoom.Tests.Cinematic.Support;

function Generated: TBytes;
var
  LSeed: Cardinal;
  LIndex: Integer;
begin
  SetLength(Result, 4096);
  LSeed := 12345;
  for LIndex := 0 to 4095 do
  begin
    LSeed := LSeed * 1664525 + 1013904223;
    Result[LIndex] := Byte(LSeed shr 16);
  end;
end;

{ TTestRoqSoundDecoder }

procedure TTestRoqSoundDecoder.DovrebbeSommareIQuadratiConSegno;
var
  LDecoder: TRoqSoundDecoder;
  LSamples: TArray<SmallInt>;
begin
  LDecoder := TRoqSoundDecoder.Create;
  try
    // 0 -> 0, 1 -> 1, 3 -> 9, 129 -> -1, 130 -> -4
    LSamples := LDecoder.DecodeMonoToMono(TBytes.Create(0, 1, 3, 129, 130), 5, 100);
    Assert.AreEqual(5, Integer(Length(LSamples)));
    Assert.AreEqual(100, Integer(LSamples[0]));
    Assert.AreEqual(101, Integer(LSamples[1]));
    Assert.AreEqual(110, Integer(LSamples[2]));
    Assert.AreEqual(109, Integer(LSamples[3]));
    Assert.AreEqual(105, Integer(LSamples[4]));
  finally
    LDecoder.Free;
  end;
end;

procedure TTestRoqSoundDecoder.DovrebbeRaddoppiareIlMonoInStereo;
var
  LDecoder: TRoqSoundDecoder;
  LSamples: TArray<SmallInt>;
begin
  LDecoder := TRoqSoundDecoder.Create;
  try
    LSamples := LDecoder.DecodeMonoToStereo(TBytes.Create(2, 2), 2, 0);
    Assert.AreEqual(4, Integer(Length(LSamples)));
    Assert.AreEqual(4, Integer(LSamples[0]));
    Assert.AreEqual(4, Integer(LSamples[1]));
    Assert.AreEqual(8, Integer(LSamples[2]));
    Assert.AreEqual(8, Integer(LSamples[3]));
  finally
    LDecoder.Free;
  end;
end;

procedure TTestRoqSoundDecoder.DovrebbeSeparareIDueCanaliDelloStereo;
var
  LDecoder: TRoqSoundDecoder;
  LSamples: TArray<SmallInt>;
begin
  LDecoder := TRoqSoundDecoder.Create;
  try
    // the high byte of the flags starts the left channel, the low one the right channel
    LSamples := LDecoder.DecodeStereoToStereo(TBytes.Create(1, 2, 1, 2), 4, $0A05);
    Assert.AreEqual(4, Integer(Length(LSamples)));
    Assert.AreEqual($0A00 + 1, Integer(LSamples[0]));
    Assert.AreEqual($0500 + 4, Integer(LSamples[1]));
    Assert.AreEqual($0A00 + 2, Integer(LSamples[2]));
    Assert.AreEqual($0500 + 8, Integer(LSamples[3]));
  finally
    LDecoder.Free;
  end;
end;

procedure TTestRoqSoundDecoder.DovrebbeFareLaMediaDelloStereoInMono;
var
  LDecoder: TRoqSoundDecoder;
  LSamples: TArray<SmallInt>;
begin
  LDecoder := TRoqSoundDecoder.Create;
  try
    LSamples := LDecoder.DecodeStereoToMono(TBytes.Create(4, 2), 1, $0000);
    Assert.AreEqual(1, Integer(Length(LSamples)));
    Assert.AreEqual((16 + 4) div 2, Integer(LSamples[0]));
  finally
    LDecoder.Free;
  end;
end;

procedure TTestRoqSoundDecoder.DovrebbeFareGiroSuSedicibit;
var
  LDecoder: TRoqSoundDecoder;
  LSamples: TArray<SmallInt>;
begin
  LDecoder := TRoqSoundDecoder.Create;
  try
    // 32767 plus 127 * 127 = 16129 wraps to a negative number, as the short of C does
    LSamples := LDecoder.DecodeMonoToMono(TBytes.Create(127), 1, $7FFF);
    Assert.AreEqual($7FFF + 16129 - 65536, Integer(LSamples[0]));
    Assert.IsTrue(LSamples[0] < 0);
  finally
    LDecoder.Free;
  end;
end;

procedure TTestRoqSoundDecoder.DovrebbeSollevareSeIDatiSonoPochi;
var
  LDecoder: TRoqSoundDecoder;
begin
  LDecoder := TRoqSoundDecoder.Create;
  try
    Assert.WillRaise(
      procedure
      begin
        LDecoder.DecodeMonoToMono(TBytes.Create(1, 2), 3, 0);
      end, ERoqTruncatedException);
    Assert.WillRaise(
      procedure
      begin
        LDecoder.DecodeStereoToMono(TBytes.Create(1, 2, 3), 2, 0);
      end, ERoqTruncatedException);
  finally
    LDecoder.Free;
  end;
end;

procedure TTestRoqSoundDecoder.DovrebbeScartareLUltimoByteDiUnaDimensioneDispari;
var
  LDecoder: TRoqSoundDecoder;
  LSamples: TArray<SmallInt>;
begin
  // the original would write one short past the end of its buffer for an odd size
  LDecoder := TRoqSoundDecoder.Create;
  try
    LSamples := LDecoder.DecodeStereoToStereo(TBytes.Create(1, 1, 1), 3, 0);
    Assert.AreEqual(3, Integer(Length(LSamples)));
    Assert.AreEqual(0, Integer(LSamples[2]));
  finally
    LDecoder.Free;
  end;
end;

procedure TTestRoqSoundDecoder.DovrebbeDareLeStesseImprontedelC;
const
  FLAGS: array[0..3] of Word = ($0000, $1234, $FFFF, $8000);
var
  LDecoder: TRoqSoundDecoder;
  LData: TBytes;
  LGolden: TStringList;
  LLine, LIndex: Integer;
  LText, LKind: string;
  LSamples: TArray<SmallInt>;
begin
  LData := Generated;
  LGolden := TRoqTestData.ReadLines('tables.golden.txt');
  LDecoder := TRoqSoundDecoder.Create;
  try
    LLine := 1;
    for LIndex := 0 to 3 do
      for LKind in ['monomono', 'monostereo', 'stereostereo', 'stereomono'] do
      begin
        if LKind = 'monomono' then
          LSamples := LDecoder.DecodeMonoToMono(LData, 1000, FLAGS[LIndex])
        else if LKind = 'monostereo' then
          LSamples := LDecoder.DecodeMonoToStereo(LData, 1000, FLAGS[LIndex])
        else if LKind = 'stereostereo' then
          LSamples := LDecoder.DecodeStereoToStereo(LData, 1000, FLAGS[LIndex])
        else
          LSamples := LDecoder.DecodeStereoToMono(LData, 1000, FLAGS[LIndex]);
        LText := LGolden[LLine];
        Assert.IsTrue(LText.EndsWith('crc ' + LowerCase(IntToHex(SamplesCrc(LSamples), 8))),
          Format('%s flags %.4x: %s', [LKind, FLAGS[LIndex], LText]));
        Assert.IsTrue(LText.StartsWith('rll ' + LKind + ' flags ' + LowerCase(IntToHex(FLAGS[LIndex], 4))),
          LText);
        Inc(LLine);
      end;
  finally
    LDecoder.Free;
    LGolden.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestRoqSoundDecoder);

end.
