{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the pool of the notes in the background                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Tracker.GhostPool;

interface

uses
  DUnitX.TestFramework,
  DelphiDoom.Tracker.Ghost,
  DelphiDoom.Tracker.GhostPool,
  DelphiDoom.Tracker.Mixer,
  DelphiDoom.Tracker.NoteEnvelopes,
  DelphiDoom.Tracker.Types,
  DelphiDoom.Tracker.Voice;

type
  [TestFixture]
  [Category('tracker')]
  TTestTrackerGhostPool = class(TObject)
  private
    FMixer: TTrackerMixer;
    FPool: TTrackerGhostPool;
    FSample: TTrackerSample;
    FOtherSample: TTrackerSample;
    FInstrument: TTrackerInstrument;
    FOtherInstrument: TTrackerInstrument;
    FSource: TTrackerVoice;
    function Capture(const AChannel, ANote: Integer): TTrackerGhost;
    procedure CreatePool(const AVoices: Integer);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestLaCatturaPortaIlSuonoSuUnaVoceDelPool;
    [Test]
    procedure TestSenzaVociNonCattura;
    [Test]
    procedure TestQuandoEPienoPrendeLaPrimaVoce;
    [Test]
    procedure TestFinisceConLaSfumatura;
    [Test]
    procedure TestDuplicatoDiNota;
    [Test]
    procedure TestDuplicatoDiCampione;
    [Test]
    procedure TestDuplicatoDiStrumento;
    [Test]
    procedure TestSenzaControlloNonCiSonoDuplicati;
    [Test]
    procedure TestIlControlloTagliaSoloIFantasmiDelCanale;
    [Test]
    procedure TestIlControlloConKeyOffEFadeNonTaglia;
  end;

implementation

uses
  System.SysUtils;

const
  SAMPLE_RATE = 22050;

{ TTestTrackerGhostPool }

procedure TTestTrackerGhostPool.Setup;
begin
  FSample := TTrackerSample.Create;
  SetLength(FSample.Data, 16);
  FSample.LoopType := tlForward;
  FSample.LoopStart := 0;
  FSample.LoopEnd := 16;
  FOtherSample := TTrackerSample.Create;
  FInstrument := TTrackerInstrument.Create;
  FOtherInstrument := TTrackerInstrument.Create;
  FSource := TTrackerVoice.Create;
  FSource.Start(FSample);
  FMixer := nil;
  FPool := nil;
end;

procedure TTestTrackerGhostPool.TearDown;
begin
  FreeAndNil(FPool);
  FreeAndNil(FMixer);
  FreeAndNil(FSource);
  FreeAndNil(FOtherInstrument);
  FreeAndNil(FInstrument);
  FreeAndNil(FOtherSample);
  FreeAndNil(FSample);
end;

// One voice for the channel and AVoices - 1 for the pool
procedure TTestTrackerGhostPool.CreatePool(const AVoices: Integer);
begin
  FMixer := TTrackerMixer.Create(SAMPLE_RATE, AVoices);
  FPool := TTrackerGhostPool.Create(FMixer, 1);
end;

function TTestTrackerGhostPool.Capture(const AChannel, ANote: Integer): TTrackerGhost;
begin
  Result := FPool.Capture(FSource, TTrackerNoteEnvelopes.Create(tfIt), AChannel, ANote, FInstrument,
    FSample, 1, 8363, 127.5);
end;

procedure TTestTrackerGhostPool.TestLaCatturaPortaIlSuonoSuUnaVoceDelPool;
var
  LGhost: TTrackerGhost;
begin
  CreatePool(3);
  FSource.Position := 5;

  LGhost := Capture(0, 49);

  Assert.IsNotNull(LGhost);
  Assert.AreEqual(1, FPool.Count);
  Assert.IsTrue(FMixer.Voices[1].Active);
  Assert.AreEqual(5.0, FMixer.Voices[1].Position, 0.0001);
  Assert.AreSame(FSample, FMixer.Voices[1].Sample);
end;

procedure TTestTrackerGhostPool.TestSenzaVociNonCattura;
var
  LEnvelopes: TTrackerNoteEnvelopes;
begin
  CreatePool(1);
  LEnvelopes := TTrackerNoteEnvelopes.Create(tfIt);
  try
    Assert.IsNull(FPool.Capture(FSource, LEnvelopes, 0, 49, FInstrument, FSample, 1, 8363, 127.5));
    Assert.AreEqual(0, FPool.Count);
  finally
    LEnvelopes.Free;
  end;
end;

procedure TTestTrackerGhostPool.TestQuandoEPienoPrendeLaPrimaVoce;
var
  LGhost: TTrackerGhost;
begin
  CreatePool(3);
  Capture(0, 49);
  Capture(0, 50);

  LGhost := Capture(0, 51);

  Assert.AreEqual(2, FPool.Count);
  Assert.AreSame(FMixer.Voices[1], LGhost.Voice);
  Assert.AreEqual(51, LGhost.Note);
end;

procedure TTestTrackerGhostPool.TestFinisceConLaSfumatura;
var
  LGhost: TTrackerGhost;
  LTick: Integer;
begin
  CreatePool(2);
  // 128 * 64 of 65536 in each tick: eight ticks
  FInstrument.FadeOut := 128;
  LGhost := FPool.Capture(FSource, TTrackerNoteEnvelopes.Create(tfIt), 0, 49, FInstrument, FSample, 1,
    8363, 127.5);
  LGhost.Envelopes.Start(FInstrument);
  LGhost.Envelopes.StartFade;

  for LTick := 1 to 7 do
    FPool.ProcessTick;
  Assert.AreEqual(1, FPool.Count);
  FPool.ProcessTick;

  Assert.AreEqual(0, FPool.Count);
  Assert.IsFalse(FMixer.Voices[1].Active);
end;

procedure TTestTrackerGhostPool.TestDuplicatoDiNota;
begin
  Assert.IsTrue(TTrackerGhostPool.IsDuplicate(dcNote, 49, FSample, FInstrument, 49, FOtherSample, FInstrument));
  Assert.IsFalse(TTrackerGhostPool.IsDuplicate(dcNote, 49, FSample, FInstrument, 50, FSample, FInstrument));
  Assert.IsFalse(TTrackerGhostPool.IsDuplicate(dcNote, 49, FSample, FInstrument, 49, FSample,
    FOtherInstrument));
end;

procedure TTestTrackerGhostPool.TestDuplicatoDiCampione;
begin
  Assert.IsTrue(TTrackerGhostPool.IsDuplicate(dcSample, 49, FSample, FInstrument, 60, FSample,
    FOtherInstrument));
  Assert.IsFalse(TTrackerGhostPool.IsDuplicate(dcSample, 49, FSample, FInstrument, 49, FOtherSample,
    FInstrument));
end;

procedure TTestTrackerGhostPool.TestDuplicatoDiStrumento;
begin
  Assert.IsTrue(TTrackerGhostPool.IsDuplicate(dcInstrument, 49, FSample, FInstrument, 60, FOtherSample,
    FInstrument));
  Assert.IsFalse(TTrackerGhostPool.IsDuplicate(dcInstrument, 49, FSample, FInstrument, 49, FSample,
    FOtherInstrument));
end;

procedure TTestTrackerGhostPool.TestSenzaControlloNonCiSonoDuplicati;
begin
  Assert.IsFalse(TTrackerGhostPool.IsDuplicate(dcOff, 49, FSample, FInstrument, 49, FSample, FInstrument));
end;

procedure TTestTrackerGhostPool.TestIlControlloTagliaSoloIFantasmiDelCanale;
begin
  CreatePool(4);
  Capture(0, 49);
  Capture(1, 49);
  Capture(0, 60);

  FPool.ApplyDuplicateCheck(0, dcNote, daCut, 49, FSample, FInstrument);
  FPool.ProcessTick;

  // Left: the note 49 of the channel 1 and the note 60 of the channel 0
  Assert.AreEqual(2, FPool.Count);
end;

procedure TTestTrackerGhostPool.TestIlControlloConKeyOffEFadeNonTaglia;
begin
  CreatePool(3);
  Capture(0, 49);

  FPool.ApplyDuplicateCheck(0, dcNote, daOff, 49, FSample, FInstrument);
  FPool.ApplyDuplicateCheck(0, dcNote, daFade, 49, FSample, FInstrument);
  FPool.ProcessTick;

  // Without a fade out in the instrument the note goes on
  Assert.AreEqual(1, FPool.Count);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestTrackerGhostPool);

end.
