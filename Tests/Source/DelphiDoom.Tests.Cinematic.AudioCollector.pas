{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TRoqAudioCollector and of the factory                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Cinematic.AudioCollector;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('cinematic')]
  TTestRoqAudioCollector = class(TObject)
  public
    [Test]
    procedure DovrebbeTenereIBlocchiNellOrdine;
    [Test]
    procedure DovrebbeUnireTuttiICampioni;
    [Test]
    procedure DovrebbeRicordareCanaliEFrequenzaDellUltimo;
    [Test]
    procedure DovrebbePartireVuoto;
    [Test]
    procedure DovrebbeRaccogliereLAudioDiUnFile;
  end;

  [TestFixture]
  [Category('cinematic')]
  TTestCinematicFactory = class(TObject)
  public
    [Test]
    procedure DovrebbeCreareSorgenteDecoderEGiocatore;
    [Test]
    procedure DovrebbeUsareLAlphaOpacoDiQuakeIII;
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.Cinematic.Types,
  DelphiDoom.Cinematic.Intf,
  DelphiDoom.Cinematic.AudioCollector,
  DelphiDoom.Cinematic.Factory,
  DelphiDoom.Tests.Cinematic.Support;

{ TTestRoqAudioCollector }

procedure TTestRoqAudioCollector.DovrebbeTenereIBlocchiNellOrdine;
var
  LCollector: TRoqAudioCollector;
  LHolder: IRoqAudioSink;
begin
  LCollector := TRoqAudioCollector.Create;
  LHolder := LCollector;
  LHolder.AudioReceived([1, 2], 2, 22050);
  LHolder.AudioReceived([3], 1, 11025);
  Assert.AreEqual(2, LCollector.ChunkCount);
  Assert.AreEqual(2, Integer(Length(LCollector.Chunks[0])));
  Assert.AreEqual(3, Integer(LCollector.Chunks[1][0]));
end;

procedure TTestRoqAudioCollector.DovrebbeUnireTuttiICampioni;
var
  LCollector: TRoqAudioCollector;
  LHolder: IRoqAudioSink;
  LAll: TArray<SmallInt>;
begin
  LCollector := TRoqAudioCollector.Create;
  LHolder := LCollector;
  LHolder.AudioReceived([1, 2], 2, 22050);
  LHolder.AudioReceived([], 2, 22050);
  LHolder.AudioReceived([3, -4], 2, 22050);
  LAll := LCollector.AllSamples;
  Assert.AreEqual(4, Integer(Length(LAll)));
  Assert.AreEqual(1, Integer(LAll[0]));
  Assert.AreEqual(3, Integer(LAll[2]));
  Assert.AreEqual(-4, Integer(LAll[3]));
end;

procedure TTestRoqAudioCollector.DovrebbeRicordareCanaliEFrequenzaDellUltimo;
var
  LCollector: TRoqAudioCollector;
  LHolder: IRoqAudioSink;
begin
  LCollector := TRoqAudioCollector.Create;
  LHolder := LCollector;
  LHolder.AudioReceived([1], 1, 11025);
  Assert.AreEqual(1, LCollector.Channels);
  Assert.AreEqual(11025, LCollector.SampleRate);
end;

procedure TTestRoqAudioCollector.DovrebbePartireVuoto;
var
  LCollector: TRoqAudioCollector;
  LHolder: IRoqAudioSink;
begin
  LCollector := TRoqAudioCollector.Create;
  LHolder := LCollector;
  Assert.AreEqual(0, LCollector.ChunkCount);
  Assert.AreEqual(0, Integer(Length(LCollector.AllSamples)));
  Assert.AreEqual(0, LCollector.Channels);
end;

procedure TTestRoqAudioCollector.DovrebbeRaccogliereLAudioDiUnFile;
var
  LCollector: TRoqAudioCollector;
  LHolder: IRoqAudioSink;
  LBuilder: TRoqTestBuilder;
  LDecoder: IRoqDecoder;
begin
  LCollector := TRoqAudioCollector.Create;
  LHolder := LCollector;
  LBuilder := TRoqTestBuilder.Create;
  try
    LBuilder.Chunk(ROQ_SOUND_STEREO, 0, TRoqTestBuilder.Bytes([1, 1, 1, 1]));
    LBuilder.Chunk(ROQ_SOUND_STEREO, 0, TRoqTestBuilder.Bytes([1, 1]));
    LDecoder := TCinematicFactory.CreateDecoder(
      TCinematicFactory.CreateMemorySource(LBuilder.ToBytes), LHolder);
  finally
    LBuilder.Free;
  end;
  Assert.IsFalse(LDecoder.NextFrame);
  Assert.AreEqual(2, LCollector.ChunkCount);
  Assert.AreEqual(6, Integer(Length(LCollector.AllSamples)));
end;

{ TTestCinematicFactory }

procedure TTestCinematicFactory.DovrebbeCreareSorgenteDecoderEGiocatore;
var
  LBuilder: TRoqTestBuilder;
  LSource: IRoqSource;
  LDecoder: IRoqDecoder;
  LPlayer: IRoqPlayer;
begin
  LBuilder := TRoqTestBuilder.Create;
  try
    LSource := TCinematicFactory.CreateMemorySource(LBuilder.ToBytes);
  finally
    LBuilder.Free;
  end;
  Assert.AreEqual(Int64(8), LSource.Size);
  LDecoder := TCinematicFactory.CreateDecoder(LSource, nil);
  Assert.IsTrue(Assigned(LDecoder));
  LPlayer := TCinematicFactory.CreatePlayer(LDecoder, True);
  Assert.IsTrue(Assigned(LPlayer));
end;

procedure TTestCinematicFactory.DovrebbeUsareLAlphaOpacoDiQuakeIII;
var
  LBuilder: TRoqTestBuilder;
  LDecoder: IRoqDecoder;
begin
  LBuilder := TRoqTestBuilder.Create;
  try
    LBuilder.Info(16, 16);
    LBuilder.Codebook(1, 1);
    LBuilder.FullFrame16(0);
    LDecoder := TCinematicFactory.CreateDecoder(
      TCinematicFactory.CreateMemorySource(LBuilder.ToBytes), nil);
  finally
    LBuilder.Free;
  end;
  LDecoder.NextFrame;
  Assert.AreEqual(ROQ_ALPHA_OPAQUE, Integer(LDecoder.Frame[0] shr 24));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestRoqAudioCollector);
  TDUnitX.RegisterTestFixture(TTestCinematicFactory);

end.
