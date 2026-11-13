{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the engine, the client and the provider of m2m         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.M2m.Engine;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.M2m.Intf;

type
  [TestFixture]
  [Category('m2m')]
  TTestM2mEngine = class(TObject)
  private
    FEngine: IM2m;
    function SmallSong: TBytes;
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure TestConvertePiuTracceInUna;
    [Test]
    procedure TestScriveUnMusValido;
    [Test]
    procedure TestSenzaDatiNonVa;
    [Test]
    procedure TestUnFileCheNonEMidi;
    [Test]
    procedure TestUnFileDiTipo2NonSiConverte;
    [Test]
    procedure TestIlBufferTroppoPiccoloDiceQuantoServe;
    [Test]
    procedure TestSenzaBufferDiUscita;
  end;

  [TestFixture]
  [Category('m2m')]
  TTestM2mClient = class(TObject)
  public
    [Test]
    procedure TestConvertePerValore;
    [Test]
    procedure TestRichiedeUnaRealizzazione;
    [Test]
    procedure TestRiprovalConUnBufferPiuGrandeSeServe;
    [Test]
    procedure TestLeErroriDiventanoEccezioni;
    [Test]
    procedure TestDatiVuoti;
  end;

  [TestFixture]
  [Category('m2m')]
  TTestM2mProvider = class(TObject)
  public
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestDaUnClientCondiviso;
    [Test]
    procedure TestUseSostituisceLaRealizzazione;
  end;

implementation

uses
  DelphiDoom.M2m.Client,
  DelphiDoom.M2m.Engine,
  DelphiDoom.M2m.Provider,
  DelphiDoom.Tests.M2m.MidiBuilder;

type
  B = TTestMidiBuilder;

  // An implementation that answers with what the test says
  TFakeM2m = class(TInterfacedObject, IM2m)
  public
    Answer: Integer;
    NeededSize: Cardinal;
    Calls: Integer;
    function ConvertMidiToMus(AMidi: Pointer; AMidiSize: Cardinal; AMus: Pointer;
      AMusCapacity: Cardinal; out AMusSize: Cardinal): Integer; stdcall;
  end;

{ TFakeM2m }

function TFakeM2m.ConvertMidiToMus(AMidi: Pointer; AMidiSize: Cardinal; AMus: Pointer;
  AMusCapacity: Cardinal; out AMusSize: Cardinal): Integer;
begin
  Inc(Calls);
  AMusSize := NeededSize;
  if (NeededSize > AMusCapacity) then
    Exit(M2M_ERROR_BUFFER);
  FillChar(AMus^, NeededSize, $5A);
  Result := Answer;
end;

{ TTestM2mEngine }

procedure TTestM2mEngine.Setup;
begin
  FEngine := TM2mEngine.Create;
end;

function TTestM2mEngine.SmallSong: TBytes;
begin
  Result := B.Join([B.Header(0, 1, 70), B.Track(B.Join([B.NoteOn(0, 0, 60, 100), B.NoteOff(10, 0, 60, 0),
    B.EndOfTrack(0)]))]);
end;

procedure TTestM2mEngine.TestConvertePiuTracceInUna;
var
  LMidi: TBytes;
  LMus: array[0..1023] of Byte;
  LSize: Cardinal;
begin
  LMidi := B.Join([B.Header(1, 2, 70),
    B.Track(B.Join([B.NoteOn(0, 0, 60, 100), B.EndOfTrack(10)])),
    B.Track(B.Join([B.NoteOn(5, 1, 61, 100), B.EndOfTrack(0)]))]);

  Assert.AreEqual(M2M_OK, FEngine.ConvertMidiToMus(@LMidi[0], Length(LMidi), @LMus[0], SizeOf(LMus), LSize));

  Assert.AreEqual(Integer(Ord('M')), Integer(LMus[0]));
  Assert.IsTrue(LSize > 16);
end;

procedure TTestM2mEngine.TestScriveUnMusValido;
var
  LMidi: TBytes;
  LMus: array[0..1023] of Byte;
  LSize: Cardinal;
begin
  LMidi := SmallSong;

  Assert.AreEqual(M2M_OK, FEngine.ConvertMidiToMus(@LMidi[0], Length(LMidi), @LMus[0], SizeOf(LMus), LSize));

  Assert.AreEqual(16 + 7, Integer(LSize));
  Assert.AreEqual(Integer(Ord('M')), Integer(LMus[0]));
  Assert.AreEqual(Integer(Ord('U')), Integer(LMus[1]));
  Assert.AreEqual(Integer(Ord('S')), Integer(LMus[2]));
  Assert.AreEqual($1A, Integer(LMus[3]));
end;

procedure TTestM2mEngine.TestSenzaDatiNonVa;
var
  LMus: array[0..15] of Byte;
  LSize: Cardinal;
  LMidi: TBytes;
begin
  LMidi := SmallSong;

  Assert.AreEqual(M2M_ERROR_ARGUMENT, FEngine.ConvertMidiToMus(nil, 10, @LMus[0], SizeOf(LMus), LSize));
  Assert.AreEqual(M2M_ERROR_ARGUMENT, FEngine.ConvertMidiToMus(@LMidi[0], 0, @LMus[0], SizeOf(LMus), LSize));
end;

procedure TTestM2mEngine.TestUnFileCheNonEMidi;
var
  LData: TBytes;
  LMus: array[0..15] of Byte;
  LSize: Cardinal;
begin
  LData := TEncoding.ASCII.GetBytes('this is not a midi file at all');

  Assert.AreEqual(M2M_ERROR_MIDI, FEngine.ConvertMidiToMus(@LData[0], Length(LData), @LMus[0], SizeOf(LMus), LSize));
end;

procedure TTestM2mEngine.TestUnFileDiTipo2NonSiConverte;
var
  LMidi: TBytes;
  LMus: array[0..255] of Byte;
  LSize: Cardinal;
begin
  LMidi := B.Join([B.Header(2, 1, 70), B.Track(B.Join([B.NoteOn(0, 0, 60, 100), B.EndOfTrack(0)]))]);

  Assert.AreEqual(M2M_ERROR_CONVERT, FEngine.ConvertMidiToMus(@LMidi[0], Length(LMidi), @LMus[0], SizeOf(LMus), LSize));
end;

procedure TTestM2mEngine.TestIlBufferTroppoPiccoloDiceQuantoServe;
var
  LMidi: TBytes;
  LMus: array[0..7] of Byte;
  LSize: Cardinal;
begin
  LMidi := SmallSong;

  Assert.AreEqual(M2M_ERROR_BUFFER, FEngine.ConvertMidiToMus(@LMidi[0], Length(LMidi), @LMus[0], SizeOf(LMus), LSize));
  Assert.AreEqual(16 + 7, Integer(LSize));
end;

procedure TTestM2mEngine.TestSenzaBufferDiUscita;
var
  LMidi: TBytes;
  LSize: Cardinal;
begin
  LMidi := SmallSong;

  Assert.AreEqual(M2M_ERROR_ARGUMENT, FEngine.ConvertMidiToMus(@LMidi[0], Length(LMidi), nil, 100, LSize));
end;

{ TTestM2mClient }

procedure TTestM2mClient.TestConvertePerValore;
var
  LClient: TM2mClient;
  LMus: TBytes;
begin
  LClient := TM2mClient.Create(TM2mEngine.Create);
  try
    LMus := LClient.ConvertMidiToMus(B.Join([B.Header(0, 1, 70), B.Track(B.Join([B.NoteOn(0, 0, 60, 100),
      B.NoteOff(10, 0, 60, 0), B.EndOfTrack(0)]))]));

    Assert.AreEqual<Integer>(16 + 7, Length(LMus));
  finally
    LClient.Free;
  end;
end;

procedure TTestM2mClient.TestRichiedeUnaRealizzazione;
begin
  Assert.WillRaise(
    procedure
    begin
      TM2mClient.Create(nil);
    end, EM2mException);
end;

procedure TTestM2mClient.TestRiprovalConUnBufferPiuGrandeSeServe;
var
  LFake: TFakeM2m;
  LClient: TM2mClient;
  LMus: TBytes;
  LMidi: TBytes;
begin
  // The fake needs more room than the client offers the first time
  LFake := TFakeM2m.Create;
  LFake.Answer := M2M_OK;
  LFake.NeededSize := 100000;
  LClient := TM2mClient.Create(LFake);
  try
    LMidi := B.Bytes([1, 2, 3]);

    LMus := LClient.ConvertMidiToMus(LMidi);

    Assert.AreEqual<Integer>(100000, Length(LMus));
    Assert.AreEqual(2, LFake.Calls);
  finally
    LClient.Free;
  end;
end;

procedure TTestM2mClient.TestLeErroriDiventanoEccezioni;
var
  LFake: TFakeM2m;
  LClient: TM2mClient;
  LMidi: TBytes;
begin
  LFake := TFakeM2m.Create;
  LFake.Answer := M2M_ERROR_MIDI;
  LFake.NeededSize := 10;
  LClient := TM2mClient.Create(LFake);
  try
    LMidi := B.Bytes([1, 2, 3]);

    Assert.WillRaise(
      procedure
      begin
        LClient.ConvertMidiToMus(LMidi);
      end, EM2mException);
  finally
    LClient.Free;
  end;
end;

procedure TTestM2mClient.TestDatiVuoti;
var
  LClient: TM2mClient;
begin
  LClient := TM2mClient.Create(TM2mEngine.Create);
  try
    Assert.WillRaise(
      procedure
      begin
        LClient.ConvertMidiToMus(nil, 0);
      end, EM2mException);
  finally
    LClient.Free;
  end;
end;

{ TTestM2mProvider }

procedure TTestM2mProvider.TearDown;
begin
  TM2mProvider.Release;
end;

procedure TTestM2mProvider.TestDaUnClientCondiviso;
begin
  Assert.AreSame(TM2mProvider.Client, TM2mProvider.Client);
end;

procedure TTestM2mProvider.TestUseSostituisceLaRealizzazione;
var
  LFake: TFakeM2m;
  LMus: TBytes;
begin
  LFake := TFakeM2m.Create;
  LFake.Answer := M2M_OK;
  LFake.NeededSize := 20;
  TM2mProvider.Use(LFake);

  LMus := TM2mProvider.Client.ConvertMidiToMus(B.Bytes([1, 2, 3]));

  Assert.AreEqual<Integer>(20, Length(LMus));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestM2mEngine);
  TDUnitX.RegisterTestFixture(TTestM2mClient);
  TDUnitX.RegisterTestFixture(TTestM2mProvider);

end.
