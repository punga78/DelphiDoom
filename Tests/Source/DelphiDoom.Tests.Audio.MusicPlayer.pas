{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the audio library - the music player                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Audio.MusicPlayer;

interface

uses
  System.SysUtils, System.Generics.Collections, DUnitX.TestFramework, DelphiDoom.Audio.Types,
  DelphiDoom.Audio.Intf;

type
  /// <summary>Recognizes the songs whose first byte is its marker; every call is written in a shared list</summary>
  TFakeMusicBackend = class(TInterfacedObject, IMusicBackend)
  private
    FName: string;
    FCalls: TList<string>;
    FMarker: Byte;
    FResult: TMusicRegisterResult;
    FNextContext: NativeInt;
  public
    constructor Create(const AName: string; const ACalls: TList<string>; AMarker: Byte;
      AResult: TMusicRegisterResult = TMusicRegisterResult.Registered);
    procedure Initialize;
    procedure Shutdown;
    function Register(AData: Pointer; ASize: Integer; out AContext: NativeInt): TMusicRegisterResult;
    procedure Play(AContext: NativeInt; ALooping: Boolean);
    procedure Stop(AContext: NativeInt);
    procedure Pause(AContext: NativeInt);
    procedure Resume(AContext: NativeInt);
    procedure Unregister(AContext: NativeInt);
    procedure SetVolume(AVolume: Integer);
    procedure Process;
    procedure PrepareForNewSong;
  end;

  [TestFixture]
  [Category('audio')]
  TTestAudioMusicPlayer = class(TObject)
  private
    FCalls: TList<string>;
    FSong: array[0..3] of Byte;
    function MakePlayer(const ABackends: array of IMusicBackend): IMusicPlayer;
    function Register(const APlayer: IMusicPlayer; AMarker: Byte): Integer;
    function CallsText: string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestFirstBackendThatRecognizesTheSongPlaysIt;
    [Test]
    procedure TestBackendsAreAskedInOrderAndStopAtTheFirst;
    [Test]
    procedure TestUnknownSongGetsAHandleAndIsSilent;
    [Test]
    procedure TestFailedSongGivesZeroAndStopsTheSearch;
    [Test]
    procedure TestFailedSongClearsTheActiveBackend;
    [Test]
    procedure TestHandlesAreNeverZeroNorReused;
    [Test]
    procedure TestPlayGoesToTheBackendOfTheSong;
    [Test]
    procedure TestPauseAndResumeGoToTheActiveBackend;
    [Test]
    procedure TestPauseWithAnUnknownHandleUsesContextZero;
    [Test]
    procedure TestNewSongTellsTheActiveBackendToPrepare;
    [Test]
    procedure TestVolumeAndProcessGoToTheActiveBackendOnly;
    [Test]
    procedure TestNothingActiveNothingHappens;
    [Test]
    procedure TestUnregisterStopsThenUnregisters;
    [Test]
    procedure TestUnregisterOfAnUnknownHandleDoesNothing;
    [Test]
    procedure TestInitializeAndShutdownReachEveryBackendInOrder;
  end;

implementation

uses
  DelphiDoom.Audio.Factory;

{ TFakeMusicBackend }

constructor TFakeMusicBackend.Create(const AName: string; const ACalls: TList<string>;
  AMarker: Byte; AResult: TMusicRegisterResult);
begin
  inherited Create;
  FName := AName;
  FCalls := ACalls;
  FMarker := AMarker;
  FResult := AResult;
  FNextContext := 100;
end;

procedure TFakeMusicBackend.Initialize;
begin
  FCalls.Add(FName + '.initialize');
end;

procedure TFakeMusicBackend.Shutdown;
begin
  FCalls.Add(FName + '.shutdown');
end;

function TFakeMusicBackend.Register(AData: Pointer; ASize: Integer;
  out AContext: NativeInt): TMusicRegisterResult;
begin
  FCalls.Add(FName + '.register');
  AContext := 0;
  if PByte(AData)^ <> FMarker then
  begin
    Result := TMusicRegisterResult.NotRecognized;
    Exit;
  end;
  Result := FResult;
  if Result = TMusicRegisterResult.Registered then
  begin
    AContext := FNextContext;
    Inc(FNextContext);
  end;
end;

procedure TFakeMusicBackend.Play(AContext: NativeInt; ALooping: Boolean);
begin
  FCalls.Add(Format('%s.play(%d,%s)', [FName, AContext, BoolToStr(ALooping, True)]));
end;

procedure TFakeMusicBackend.Stop(AContext: NativeInt);
begin
  FCalls.Add(Format('%s.stop(%d)', [FName, AContext]));
end;

procedure TFakeMusicBackend.Pause(AContext: NativeInt);
begin
  FCalls.Add(Format('%s.pause(%d)', [FName, AContext]));
end;

procedure TFakeMusicBackend.Resume(AContext: NativeInt);
begin
  FCalls.Add(Format('%s.resume(%d)', [FName, AContext]));
end;

procedure TFakeMusicBackend.Unregister(AContext: NativeInt);
begin
  FCalls.Add(Format('%s.unregister(%d)', [FName, AContext]));
end;

procedure TFakeMusicBackend.SetVolume(AVolume: Integer);
begin
  FCalls.Add(Format('%s.volume(%d)', [FName, AVolume]));
end;

procedure TFakeMusicBackend.Process;
begin
  FCalls.Add(FName + '.process');
end;

procedure TFakeMusicBackend.PrepareForNewSong;
begin
  FCalls.Add(FName + '.prepare');
end;

{ TTestAudioMusicPlayer }

procedure TTestAudioMusicPlayer.Setup;
begin
  FCalls := TList<string>.Create;
  FillChar(FSong, SizeOf(FSong), 0);
end;

procedure TTestAudioMusicPlayer.TearDown;
begin
  FreeAndNil(FCalls);
end;

function TTestAudioMusicPlayer.MakePlayer(const ABackends: array of IMusicBackend): IMusicPlayer;
var
  LBackends: TArray<IMusicBackend>;
  LIndex: Integer;
begin
  SetLength(LBackends, Length(ABackends));
  for LIndex := 0 to High(ABackends) do
    LBackends[LIndex] := ABackends[LIndex];
  Result := TAudioFactory.CreateMusicPlayer(LBackends);
end;

function TTestAudioMusicPlayer.Register(const APlayer: IMusicPlayer; AMarker: Byte): Integer;
begin
  FSong[0] := AMarker;
  Result := APlayer.Register(@FSong[0], SizeOf(FSong));
end;

function TTestAudioMusicPlayer.CallsText: string;
begin
  Result := string.Join(' ', FCalls.ToArray);
end;

procedure TTestAudioMusicPlayer.TestFirstBackendThatRecognizesTheSongPlaysIt;
var
  LPlayer: IMusicPlayer;
  LHandle: Integer;
begin
  LPlayer := MakePlayer([TFakeMusicBackend.Create('a', FCalls, 1), TFakeMusicBackend.Create('b', FCalls, 2)]);
  LHandle := Register(LPlayer, 2);
  LPlayer.Play(LHandle, True);
  Assert.AreEqual('a.register b.register b.play(100,True)', CallsText);
end;

procedure TTestAudioMusicPlayer.TestBackendsAreAskedInOrderAndStopAtTheFirst;
var
  LPlayer: IMusicPlayer;
begin
  LPlayer := MakePlayer([TFakeMusicBackend.Create('a', FCalls, 1), TFakeMusicBackend.Create('b', FCalls, 1)]);
  Register(LPlayer, 1);
  Assert.AreEqual('a.register', CallsText);
end;

procedure TTestAudioMusicPlayer.TestUnknownSongGetsAHandleAndIsSilent;
var
  LPlayer: IMusicPlayer;
  LHandle: Integer;
begin
  LPlayer := MakePlayer([TFakeMusicBackend.Create('a', FCalls, 1)]);
  LHandle := Register(LPlayer, 9);
  Assert.IsTrue(LHandle > 0);
  FCalls.Clear;
  LPlayer.Play(LHandle, False);
  LPlayer.Pause(LHandle);
  LPlayer.Unregister(LHandle);
  Assert.AreEqual('', CallsText);
end;

procedure TTestAudioMusicPlayer.TestFailedSongGivesZeroAndStopsTheSearch;
var
  LPlayer: IMusicPlayer;
begin
  LPlayer := MakePlayer([
    TFakeMusicBackend.Create('a', FCalls, 1, TMusicRegisterResult.Failed),
    TFakeMusicBackend.Create('b', FCalls, 1)]);
  Assert.AreEqual(0, Register(LPlayer, 1));
  Assert.AreEqual('a.register', CallsText);
end;

procedure TTestAudioMusicPlayer.TestFailedSongClearsTheActiveBackend;
var
  LPlayer: IMusicPlayer;
begin
  LPlayer := MakePlayer([
    TFakeMusicBackend.Create('a', FCalls, 1),
    TFakeMusicBackend.Create('b', FCalls, 2, TMusicRegisterResult.Failed)]);
  Register(LPlayer, 1);
  Register(LPlayer, 2);
  FCalls.Clear;
  LPlayer.Process;
  LPlayer.SetVolume(5);
  Assert.AreEqual('', CallsText);
end;

procedure TTestAudioMusicPlayer.TestHandlesAreNeverZeroNorReused;
var
  LPlayer: IMusicPlayer;
  LFirst: Integer;
  LSecond: Integer;
begin
  LPlayer := MakePlayer([TFakeMusicBackend.Create('a', FCalls, 1)]);
  LFirst := Register(LPlayer, 1);
  LPlayer.Unregister(LFirst);
  LSecond := Register(LPlayer, 1);
  Assert.IsTrue(LFirst > 0);
  Assert.IsTrue(LSecond > LFirst);
end;

procedure TTestAudioMusicPlayer.TestPlayGoesToTheBackendOfTheSong;
var
  LPlayer: IMusicPlayer;
  LFirst: Integer;
  LSecond: Integer;
begin
  LPlayer := MakePlayer([TFakeMusicBackend.Create('a', FCalls, 1), TFakeMusicBackend.Create('b', FCalls, 2)]);
  LFirst := Register(LPlayer, 1);
  LSecond := Register(LPlayer, 2);
  FCalls.Clear;
  LPlayer.Play(LFirst, False);
  LPlayer.Play(LSecond, True);
  Assert.AreEqual('a.play(100,False) b.play(100,True)', CallsText);
end;

procedure TTestAudioMusicPlayer.TestPauseAndResumeGoToTheActiveBackend;
var
  LPlayer: IMusicPlayer;
  LHandle: Integer;
begin
  LPlayer := MakePlayer([TFakeMusicBackend.Create('a', FCalls, 1), TFakeMusicBackend.Create('b', FCalls, 2)]);
  Register(LPlayer, 1);
  LHandle := Register(LPlayer, 2);
  FCalls.Clear;
  LPlayer.Pause(LHandle);
  LPlayer.Resume(LHandle);
  Assert.AreEqual('b.pause(100) b.resume(100)', CallsText);
end;

procedure TTestAudioMusicPlayer.TestPauseWithAnUnknownHandleUsesContextZero;
var
  LPlayer: IMusicPlayer;
begin
  LPlayer := MakePlayer([TFakeMusicBackend.Create('a', FCalls, 1)]);
  Register(LPlayer, 1);
  FCalls.Clear;
  LPlayer.Pause(999);
  Assert.AreEqual('a.pause(0)', CallsText);
end;

procedure TTestAudioMusicPlayer.TestNewSongTellsTheActiveBackendToPrepare;
var
  LPlayer: IMusicPlayer;
begin
  LPlayer := MakePlayer([TFakeMusicBackend.Create('a', FCalls, 1), TFakeMusicBackend.Create('b', FCalls, 2)]);
  Register(LPlayer, 1);
  FCalls.Clear;
  Register(LPlayer, 2);
  Assert.AreEqual('a.prepare a.register b.register', CallsText);
end;

procedure TTestAudioMusicPlayer.TestVolumeAndProcessGoToTheActiveBackendOnly;
var
  LPlayer: IMusicPlayer;
begin
  LPlayer := MakePlayer([TFakeMusicBackend.Create('a', FCalls, 1), TFakeMusicBackend.Create('b', FCalls, 2)]);
  Register(LPlayer, 1);
  FCalls.Clear;
  LPlayer.SetVolume(7);
  LPlayer.Process;
  Assert.AreEqual('a.volume(7) a.process', CallsText);
end;

procedure TTestAudioMusicPlayer.TestNothingActiveNothingHappens;
var
  LPlayer: IMusicPlayer;
begin
  LPlayer := MakePlayer([TFakeMusicBackend.Create('a', FCalls, 1)]);
  LPlayer.SetVolume(3);
  LPlayer.Process;
  LPlayer.Pause(1);
  LPlayer.Resume(1);
  LPlayer.Play(1, True);
  Assert.AreEqual('', CallsText);
end;

procedure TTestAudioMusicPlayer.TestUnregisterStopsThenUnregisters;
var
  LPlayer: IMusicPlayer;
  LHandle: Integer;
begin
  LPlayer := MakePlayer([TFakeMusicBackend.Create('a', FCalls, 1)]);
  LHandle := Register(LPlayer, 1);
  FCalls.Clear;
  LPlayer.Unregister(LHandle);
  Assert.AreEqual('a.stop(100) a.unregister(100)', CallsText);
  FCalls.Clear;
  LPlayer.Unregister(LHandle);
  LPlayer.Play(LHandle, False);
  Assert.AreEqual('', CallsText);
end;

procedure TTestAudioMusicPlayer.TestUnregisterOfAnUnknownHandleDoesNothing;
var
  LPlayer: IMusicPlayer;
begin
  LPlayer := MakePlayer([TFakeMusicBackend.Create('a', FCalls, 1)]);
  LPlayer.Unregister(0);
  LPlayer.Unregister(55);
  Assert.AreEqual('', CallsText);
end;

procedure TTestAudioMusicPlayer.TestInitializeAndShutdownReachEveryBackendInOrder;
var
  LPlayer: IMusicPlayer;
begin
  LPlayer := MakePlayer([TFakeMusicBackend.Create('a', FCalls, 1), TFakeMusicBackend.Create('b', FCalls, 2)]);
  LPlayer.Initialize;
  Register(LPlayer, 1);
  FCalls.Clear;
  LPlayer.Shutdown;
  Assert.AreEqual('a.shutdown b.shutdown', CallsText);
  FCalls.Clear;
  LPlayer.Process;
  Assert.AreEqual('', CallsText);
end;

end.
