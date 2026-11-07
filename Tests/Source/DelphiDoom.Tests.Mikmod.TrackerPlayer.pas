{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TTrackerModPlayer, on a fake audio output              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Mikmod.TrackerPlayer;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Mikmod.Intf,
  DelphiDoom.Tests.Tracker.FakeOutput,
  DelphiDoom.Tracker.Output.Intf;

type
  [TestFixture]
  [Category('mikmod')]
  TTestTrackerModPlayer = class(TObject)
  private
    FOutputs: TFakeTrackerOutputFactory;
    FOutputsIntf: ITrackerOutputFactory;
    FPlayer: IMikModPlayer;
    FReleased: Integer;
    function Load(const AData: TBytes): Integer;
    class function MinimalMod: TBytes; static;
    class function MinimalS3m(AChannel: Byte): TBytes; static;
    class function MinimalXm: TBytes; static;
    class function MinimalIt: TBytes; static;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeRifiutareUnUscitaMancante;
    [Test]
    procedure DovrebbeAvvisareChiLoHaCreatoQuandoELiberato;
    [Test]
    procedure DovrebbeCaricareOgniFormato;
    [Test]
    procedure DovrebbeRifiutareUnModuloRiconosciutoMaRotto;
    [Test]
    procedure DovrebbeSuonareSulDispositivo;
    [Test]
    procedure DovrebbeMettereInPausaERiprendere;
    [Test]
    procedure DovrebbeDareIlVolumeAlBranoCaricato;
    [Test]
    procedure DovrebbeDareErroreInternoSeLaRiproduzioneFallisce;
    [Test]
    procedure DovrebbeDareErroreInternoSeLArrestoFallisce;
    [Test]
    procedure DovrebbeDareErroreDiFileSeIlFileNonSiLegge;
  end;

implementation

uses
  System.Classes,
  System.IOUtils,
  DelphiDoom.Mikmod.TrackerPlayer;

const
  SOME_RATE = 22050;

{ TTestTrackerModPlayer }

procedure TTestTrackerModPlayer.Setup;
begin
  FOutputs := TFakeTrackerOutputFactory.Create;
  FOutputsIntf := FOutputs;
  FReleased := 0;
  FPlayer := TTrackerModPlayer.Create(SOME_RATE,
    procedure
    begin
      Inc(FReleased);
    end, FOutputsIntf);
end;

procedure TTestTrackerModPlayer.TearDown;
begin
  FOutputs.Worker.WaitForRaises := False;
  FPlayer := nil;
  FOutputsIntf := nil;
  FOutputs := nil;
end;

function TTestTrackerModPlayer.Load(const AData: TBytes): Integer;
begin
  Result := FPlayer.LoadFromMemory(Pointer(AData), Length(AData));
end;

// A MOD of four channels with one empty pattern and no samples
class function TTestTrackerModPlayer.MinimalMod: TBytes;
begin
  SetLength(Result, 1084 + 1024);
  FillChar(Result[0], Length(Result), 0);
  Result[950] := 1;
  Result[1080] := Ord('M');
  Result[1081] := Ord('.');
  Result[1082] := Ord('K');
  Result[1083] := Ord('.');
end;

// SCRM at $2C, the channel settings at $40 (255 = not used), no orders, instruments or patterns
class function TTestTrackerModPlayer.MinimalS3m(AChannel: Byte): TBytes;
begin
  SetLength(Result, $60);
  FillChar(Result[0], Length(Result), 0);
  Result[$2C] := Ord('S');
  Result[$2D] := Ord('C');
  Result[$2E] := Ord('R');
  Result[$2F] := Ord('M');
  FillChar(Result[$40], 32, 255);
  Result[$40] := AChannel;
end;

// "Extended Module: ", version 1.04 at 58, a header of 276 bytes from 60: one order, one channel
class function TTestTrackerModPlayer.MinimalXm: TBytes;
const
  SIGNATURE: AnsiString = 'Extended Module: ';
begin
  SetLength(Result, 60 + 276);
  FillChar(Result[0], Length(Result), 0);
  Move(PAnsiChar(SIGNATURE)^, Result[0], Length(SIGNATURE));
  Result[37] := $1A;
  Result[58] := $04;
  Result[59] := $01;
  Result[60] := 20;
  Result[64] := 1;   // song length
  Result[68] := 1;   // channels
  Result[76] := 6;   // speed
  Result[78] := 125; // tempo
end;

// IMPM, the compatible version 2.00 at 42, no orders, instruments, samples or patterns
class function TTestTrackerModPlayer.MinimalIt: TBytes;
begin
  SetLength(Result, 192);
  FillChar(Result[0], Length(Result), 0);
  Result[0] := Ord('I');
  Result[1] := Ord('M');
  Result[2] := Ord('P');
  Result[3] := Ord('M');
  Result[42] := $00;
  Result[43] := $02;
end;

procedure TTestTrackerModPlayer.DovrebbeRifiutareUnUscitaMancante;
begin
  Assert.WillRaise(
    procedure
    begin
      TTrackerModPlayer.Create(SOME_RATE, nil, nil).Free;
    end, EArgumentNilException);
end;

procedure TTestTrackerModPlayer.DovrebbeAvvisareChiLoHaCreatoQuandoELiberato;
begin
  Assert.AreEqual(MIKMOD_OK, Load(MinimalMod));
  FPlayer := nil;
  Assert.AreEqual(1, FReleased);
end;

procedure TTestTrackerModPlayer.DovrebbeCaricareOgniFormato;
begin
  Assert.AreEqual(MIKMOD_OK, Load(MinimalMod), 'MOD');
  Assert.AreEqual(MIKMOD_OK, Load(MinimalS3m(0)), 'S3M');
  Assert.AreEqual(MIKMOD_OK, Load(MinimalXm), 'XM');
  Assert.AreEqual(MIKMOD_OK, Load(MinimalIt), 'IT');
end;

procedure TTestTrackerModPlayer.DovrebbeRifiutareUnModuloRiconosciutoMaRotto;
begin
  // An S3M without channels: the loader raises, the player says it cannot load it
  Assert.AreEqual(MIKMOD_ERR_LOAD_MODULE, Load(MinimalS3m(255)));
  Assert.AreEqual(MIKMOD_ERR_NO_MODULE, FPlayer.Play(False));
end;

procedure TTestTrackerModPlayer.DovrebbeSuonareSulDispositivo;
begin
  Load(MinimalMod);

  Assert.AreEqual(MIKMOD_OK, FPlayer.Play(False));

  Assert.AreEqual(1, FOutputs.Device.OpenCalls);
  Assert.AreEqual(SOME_RATE, FOutputs.Device.OpenedRate);
  Assert.AreEqual(1, FOutputs.Device.CloseCalls);
  // The fake worker has done all the work: the song is over
  Assert.IsFalse(FPlayer.IsPlaying);
  Assert.AreEqual(MIKMOD_OK, FPlayer.Stop);
end;

procedure TTestTrackerModPlayer.DovrebbeMettereInPausaERiprendere;
begin
  Load(MinimalMod);
  Assert.IsFalse(FPlayer.IsPaused);

  Assert.AreEqual(MIKMOD_OK, FPlayer.SetPaused(True));
  Assert.IsTrue(FPlayer.IsPaused);
  Assert.AreEqual(MIKMOD_OK, FPlayer.SetPaused(False));
  Assert.IsFalse(FPlayer.IsPaused);
end;

procedure TTestTrackerModPlayer.DovrebbeDareIlVolumeAlBranoCaricato;
var
  LSilent: Boolean;
  LIndex: Integer;
begin
  Load(MinimalMod);
  Assert.AreEqual(MIKMOD_OK, FPlayer.SetVolume(0));
  FPlayer.Play(False);

  // The module has no samples: silence at any volume, but every buffer went to the device
  LSilent := True;
  for LIndex := 0 to High(FOutputs.Device.Written[0]) do
    if FOutputs.Device.Written[0][LIndex] <> 0 then
      LSilent := False;
  Assert.IsTrue(LSilent);
  Assert.IsTrue(Length(FOutputs.Device.Written) >= 4);
end;

procedure TTestTrackerModPlayer.DovrebbeDareErroreInternoSeLaRiproduzioneFallisce;
begin
  Load(MinimalMod);
  FOutputs.Device.OpenRaises := True;

  Assert.AreEqual(MIKMOD_ERR_INTERNAL, FPlayer.Play(False));
end;

procedure TTestTrackerModPlayer.DovrebbeDareErroreInternoSeLArrestoFallisce;
begin
  Load(MinimalMod);
  FOutputs.Worker.WaitForRaises := True;

  Assert.AreEqual(MIKMOD_ERR_INTERNAL, FPlayer.Stop);
end;

// A file that exists and cannot be opened (another handle holds it alone):
// TFile turns the error of the stream into EInOutError
procedure TTestTrackerModPlayer.DovrebbeDareErroreDiFileSeIlFileNonSiLegge;
var
  LPath: string;
  LLock: TFileStream;
begin
  LPath := TPath.Combine(TPath.GetTempPath, 'ddmikmod_locked_' + IntToStr(Random(MaxInt)) + '.mod');
  LLock := TFileStream.Create(LPath, fmCreate or fmShareExclusive);
  try
    Assert.AreEqual(MIKMOD_ERR_IO, FPlayer.LoadFromFile(PAnsiChar(AnsiString(LPath))));
  finally
    LLock.Free;
    TFile.Delete(LPath);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestTrackerModPlayer);

end.
