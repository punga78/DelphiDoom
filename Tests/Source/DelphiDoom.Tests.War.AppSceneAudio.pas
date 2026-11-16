{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - the sound of the scenes              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.AppSceneAudio;

interface

uses
  System.SysUtils, System.Generics.Collections, DUnitX.TestFramework, DelphiDoom.War.Audio.Types,
  DelphiDoom.War.Audio.Intf, DelphiDoom.War.Music.Types, DelphiDoom.War.Music.Intf, DelphiDoom.War.Ui.Intf,
  DelphiDoom.War.App.SceneAudio;

type
  /// <summary>A library where the records 0 and 1 are songs, 10 and 11 are sounds, and 20 cannot be decoded</summary>
  TAppFakeLibrary = class(TInterfacedObject, IWarAudioLibrary)
  public
    function KindOf(AIndex: Integer): TWarAudioKind;
    function GetSound(AIndex: Integer): TWarPcmBuffer;
    function GetMusic(AIndex: Integer): TBytes;
  end;

  /// <summary>A mixer that writes down the calls (the volumes of the last one)</summary>
  TAppFakeMixer = class(TInterfacedObject, IWarSoundMixer)
  public
    Played: TList<Integer>;
    Loops: TList<Boolean>;
    Volume: Single;
    Enabled: Boolean;
    Silenced: Boolean;
    PlacedX: TList<Single>;
    ViewportWidth: Single;
    constructor Create;
    destructor Destroy; override;
    function Play(ASoundIndex: Integer; ALoop: Boolean): Integer;
    function PlayAt(ASoundIndex: Integer; AX, AY: Single; ALoop: Boolean): Integer;
    procedure Stop(AHandle: Integer);
    procedure StopAll;
    procedure SetViewport(AX, AY, AWidth, AHeight: Single);
    procedure SetVolume(AVolume: Single; AEnabled: Boolean);
    procedure SetSilenced(ASilenced: Boolean);
    procedure Mix(ABuffer: PSmallInt; ASampleCount: Integer);
    function ActiveVoices: Integer;
  end;

  /// <summary>A player of songs that writes down the calls</summary>
  TAppFakeMusic = class(TInterfacedObject, IWarMusicPlayer)
  public
    Songs: TList<Integer>;
    Loops: TList<Boolean>;
    Stops: Integer;
    Volume: Single;
    Enabled: Boolean;
    Silenced: Boolean;
    Accepts: Boolean;
    constructor Create;
    destructor Destroy; override;
    function Play(const AMidi: TBytes; ALoop: Boolean; AFadeInMs: Integer): Boolean;
    procedure Stop(AFadeOutMs: Integer);
    procedure SetVolume(AVolume: Single; AEnabled: Boolean);
    procedure SetSilenced(ASilenced: Boolean);
    procedure Mix(ABuffer: PSmallInt; ASampleCount: Integer);
    function GetState: TWarMusicState;
  end;

  /// <summary>An audio id is a record of DATA.WAR: a sound goes to the mixer, a song to the player</summary>
  [TestFixture]
  [Category('war')]
  TTestWarAppSceneAudio = class(TObject)
  strict private
    FMixer: TAppFakeMixer;
    FMixerRef: IWarSoundMixer;
    FMusic: TAppFakeMusic;
    FMusicRef: IWarMusicPlayer;
    FAudio: TWarSceneAudio;
    FAudioRef: IWarSceneAudio;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeMandareUnSuonoAlMixer;
    [Test]
    procedure DovrebbeMandareUnBranoAlPlayerConIlCiclo;
    [Test]
    procedure DovrebbeMandareAlMixerUnSuonoConPostoEIlViewport;
    [Test]
    procedure DovrebbeFermareLaMusica;
    [Test]
    procedure DovrebbeContareUnIdCheNonSiPuoSuonareESaltarlo;
    [Test]
    procedure DovrebbeContareUnBranoCheIlPlayerRifiuta;
    [Test]
    procedure DovrebbeTacereDaMutoESuonareDopo;
    [Test]
    procedure DovrebbeSuonareDopoIlRigiocoLUltimoBranoChiestoDaMuto;
    [Test]
    procedure DovrebbeFermareDopoIlRigiocoSeLUltimaRichiestaEraUnArresto;
    [Test]
    procedure DovrebbeDimenticareLeRichiesteDelRigiocoPrecedente;
    [Test]
    procedure DovrebbeDareAlMixerEAlPlayerVolumiEInterruttori;
    [Test]
    procedure DovrebbeTacereMentreLeScenaCambiano;
    [Test]
    procedure DovrebbeFunzionareSenzaPlayerDiMusica;
    [Test]
    procedure DovrebbeRifiutareLibreriaEMixerNil;
  end;

implementation

uses
  DelphiDoom.War.Types, DelphiDoom.War.Ui.GameSettings;

{ TAppFakeLibrary }

function TAppFakeLibrary.KindOf(AIndex: Integer): TWarAudioKind;
begin
  case AIndex of
    0, 1: Result := wakMidi;
    10, 11, 20: Result := wakWave;
  else
    raise EWarException.Create('not audio');
  end;
end;

function TAppFakeLibrary.GetSound(AIndex: Integer): TWarPcmBuffer;
begin
  Result := Default(TWarPcmBuffer);
end;

function TAppFakeLibrary.GetMusic(AIndex: Integer): TBytes;
begin
  Result := [Byte(AIndex)];
end;

{ TAppFakeMixer }

constructor TAppFakeMixer.Create;
begin
  inherited Create;
  Played := TList<Integer>.Create;
  Loops := TList<Boolean>.Create;
  PlacedX := TList<Single>.Create;
end;

destructor TAppFakeMixer.Destroy;
begin
  PlacedX.Free;
  Loops.Free;
  Played.Free;
  inherited Destroy;
end;

function TAppFakeMixer.Play(ASoundIndex: Integer; ALoop: Boolean): Integer;
begin
  Played.Add(ASoundIndex);
  Loops.Add(ALoop);
  Result := Played.Count;
end;

function TAppFakeMixer.PlayAt(ASoundIndex: Integer; AX, AY: Single; ALoop: Boolean): Integer;
begin
  PlacedX.Add(AX);
  Result := Play(ASoundIndex, ALoop);
end;

procedure TAppFakeMixer.Stop(AHandle: Integer);
begin
end;

procedure TAppFakeMixer.StopAll;
begin
end;

procedure TAppFakeMixer.SetViewport(AX, AY, AWidth, AHeight: Single);
begin
  ViewportWidth := AWidth;
end;

procedure TAppFakeMixer.SetVolume(AVolume: Single; AEnabled: Boolean);
begin
  Volume := AVolume;
  Enabled := AEnabled;
end;

procedure TAppFakeMixer.SetSilenced(ASilenced: Boolean);
begin
  Silenced := ASilenced;
end;

procedure TAppFakeMixer.Mix(ABuffer: PSmallInt; ASampleCount: Integer);
begin
end;

function TAppFakeMixer.ActiveVoices: Integer;
begin
  Result := Played.Count;
end;

{ TAppFakeMusic }

constructor TAppFakeMusic.Create;
begin
  inherited Create;
  Songs := TList<Integer>.Create;
  Loops := TList<Boolean>.Create;
  Accepts := True;
end;

destructor TAppFakeMusic.Destroy;
begin
  Loops.Free;
  Songs.Free;
  inherited Destroy;
end;

function TAppFakeMusic.Play(const AMidi: TBytes; ALoop: Boolean; AFadeInMs: Integer): Boolean;
begin
  Result := Accepts;
  if Accepts then
  begin
    Songs.Add(AMidi[0]);
    Loops.Add(ALoop);
  end;
end;

procedure TAppFakeMusic.Stop(AFadeOutMs: Integer);
begin
  Inc(Stops);
end;

procedure TAppFakeMusic.SetVolume(AVolume: Single; AEnabled: Boolean);
begin
  Volume := AVolume;
  Enabled := AEnabled;
end;

procedure TAppFakeMusic.SetSilenced(ASilenced: Boolean);
begin
  Silenced := ASilenced;
end;

procedure TAppFakeMusic.Mix(ABuffer: PSmallInt; ASampleCount: Integer);
begin
end;

function TAppFakeMusic.GetState: TWarMusicState;
begin
  Result := wmsStopped;
end;

{ TTestWarAppSceneAudio }

procedure TTestWarAppSceneAudio.Setup;
begin
  FMixer := TAppFakeMixer.Create;
  FMixerRef := FMixer;
  FMusic := TAppFakeMusic.Create;
  FMusicRef := FMusic;
  FAudio := TWarSceneAudio.Create(TAppFakeLibrary.Create, FMixerRef, FMusicRef);
  FAudioRef := FAudio;
end;

procedure TTestWarAppSceneAudio.TearDown;
begin
  FAudioRef := nil;
  FMusicRef := nil;
  FMixerRef := nil;
end;

procedure TTestWarAppSceneAudio.DovrebbeMandareUnSuonoAlMixer;
begin
  FAudio.Play(10, False);
  FAudio.Play(11, True);
  Assert.AreEqual<Integer>(2, FMixer.Played.Count);
  Assert.AreEqual(10, FMixer.Played[0]);
  Assert.IsFalse(FMixer.Loops[0]);
  Assert.IsTrue(FMixer.Loops[1]);
  Assert.AreEqual(2, FAudio.SoundsStarted);
  Assert.AreEqual<Integer>(0, FMusic.Songs.Count);
end;

procedure TTestWarAppSceneAudio.DovrebbeMandareAlMixerUnSuonoConPostoEIlViewport;
var
  LPositional: IWarPositionalAudio;
begin
  LPositional := FAudio;
  LPositional.SetViewport(10, 20, 240, 176);
  Assert.AreEqual<Single>(240, FMixer.ViewportWidth);
  LPositional.PlayAt(10, 300, 40);
  Assert.AreEqual<Integer>(1, FMixer.Played.Count);
  Assert.AreEqual<Single>(300, FMixer.PlacedX[0]);
  Assert.AreEqual(1, FAudio.SoundsStarted);
  // un brano non ha un posto: non suona qui
  LPositional.PlayAt(1, 300, 40);
  Assert.AreEqual<Integer>(1, FMixer.Played.Count);
  Assert.AreEqual<Integer>(0, FMusic.Songs.Count);
  // un id che non e'' un suono si conta e si salta
  LPositional.PlayAt(99, 0, 0);
  Assert.AreEqual(1, FAudio.Failures);
  FAudio.Muted := True;
  LPositional.PlayAt(10, 0, 0);
  Assert.AreEqual<Integer>(1, FMixer.Played.Count, 'muto non suona');
end;

procedure TTestWarAppSceneAudio.DovrebbeMandareUnBranoAlPlayerConIlCiclo;
begin
  FAudio.Play(1, True);
  Assert.AreEqual<Integer>(1, FMusic.Songs.Count);
  Assert.AreEqual(1, FMusic.Songs[0]);
  Assert.IsTrue(FMusic.Loops[0]);
  Assert.AreEqual(1, FAudio.SongsStarted);
  Assert.AreEqual<Integer>(0, FMixer.Played.Count);
end;

procedure TTestWarAppSceneAudio.DovrebbeFermareLaMusica;
begin
  FAudio.StopMusic;
  Assert.AreEqual(1, FMusic.Stops);
  Assert.AreEqual(1, FAudio.SongsStopped);
end;

procedure TTestWarAppSceneAudio.DovrebbeContareUnIdCheNonSiPuoSuonareESaltarlo;
begin
  FAudio.Play(999, False);
  Assert.AreEqual(1, FAudio.Failures);
  Assert.AreEqual<Integer>(0, FMixer.Played.Count);
  FAudio.Play(10, False);
  Assert.AreEqual(1, FAudio.SoundsStarted);
end;

procedure TTestWarAppSceneAudio.DovrebbeContareUnBranoCheIlPlayerRifiuta;
begin
  FMusic.Accepts := False;
  FAudio.Play(0, False);
  Assert.AreEqual(1, FAudio.Failures);
  Assert.AreEqual(0, FAudio.SongsStarted);
end;

procedure TTestWarAppSceneAudio.DovrebbeTacereDaMutoESuonareDopo;
begin
  FAudio.Muted := True;
  FAudio.Play(10, False);
  FAudio.Play(0, False);
  FAudio.StopMusic;
  Assert.AreEqual<Integer>(0, FMixer.Played.Count);
  Assert.AreEqual<Integer>(0, FMusic.Songs.Count);
  Assert.AreEqual(0, FMusic.Stops);
  FAudio.Muted := False;
  FAudio.Play(10, False);
  Assert.AreEqual<Integer>(1, FMixer.Played.Count);
end;

procedure TTestWarAppSceneAudio.DovrebbeSuonareDopoIlRigiocoLUltimoBranoChiestoDaMuto;
begin
  // the song of a map starts once, when the scene is entered: during the replay of a loaded game that is while muted
  FAudio.Muted := True;
  FAudio.Play(0, True);
  FAudio.Play(1, True);
  Assert.AreEqual<Integer>(0, FMusic.Songs.Count);
  FAudio.Muted := False;
  Assert.AreEqual<Integer>(1, FMusic.Songs.Count);
  Assert.AreEqual<Integer>(1, FMusic.Songs[0]);
  Assert.IsTrue(FMusic.Loops[0]);
  Assert.AreEqual(1, FAudio.SongsStarted);
end;

procedure TTestWarAppSceneAudio.DovrebbeFermareDopoIlRigiocoSeLUltimaRichiestaEraUnArresto;
begin
  FAudio.Muted := True;
  FAudio.Play(0, False);
  FAudio.StopMusic;
  FAudio.Muted := False;
  Assert.AreEqual<Integer>(0, FMusic.Songs.Count);
  Assert.AreEqual(1, FMusic.Stops);
end;

procedure TTestWarAppSceneAudio.DovrebbeDimenticareLeRichiesteDelRigiocoPrecedente;
begin
  FAudio.Muted := True;
  FAudio.Play(0, False);
  FAudio.Muted := False;
  FAudio.Muted := True;
  FAudio.Muted := False;
  Assert.AreEqual<Integer>(1, FMusic.Songs.Count);
end;

procedure TTestWarAppSceneAudio.DovrebbeDareAlMixerEAlPlayerVolumiEInterruttori;
var
  LSettings: IWarGameSettings;
begin
  LSettings := TWarGameSettings.Create;
  LSettings.SetMusicVolume(0.25);
  LSettings.SetSoundVolume(0.5);
  LSettings.MusicEnabled := False;
  FAudio.Synchronize(LSettings);
  Assert.AreEqual(Double(0.5), Double(FMixer.Volume), 0.0001);
  Assert.IsTrue(FMixer.Enabled);
  Assert.AreEqual(Double(0.25), Double(FMusic.Volume), 0.0001);
  Assert.IsFalse(FMusic.Enabled);
end;

procedure TTestWarAppSceneAudio.DovrebbeTacereMentreLeScenaCambiano;
var
  LSettings: IWarGameSettings;
begin
  LSettings := TWarGameSettings.Create;
  // the game turns the sound on when its first scene is entered
  LSettings.AudioEnabled := True;
  FAudio.Synchronize(LSettings);
  Assert.IsFalse(FMixer.Silenced);
  Assert.IsFalse(FMusic.Silenced);
  LSettings.AudioEnabled := False;
  FAudio.Synchronize(LSettings);
  Assert.IsTrue(FMixer.Silenced);
  Assert.IsTrue(FMusic.Silenced);
end;

procedure TTestWarAppSceneAudio.DovrebbeFunzionareSenzaPlayerDiMusica;
var
  LAudio: IWarSceneAudio;
  LObject: TWarSceneAudio;
begin
  LObject := TWarSceneAudio.Create(TAppFakeLibrary.Create, FMixerRef, nil);
  LAudio := LObject;
  LAudio.Play(1, True);
  LAudio.StopMusic;
  LObject.Synchronize(TWarGameSettings.Create);
  Assert.AreEqual(0, LObject.SongsStarted);
  Assert.AreEqual(0, LObject.Failures);
end;

procedure TTestWarAppSceneAudio.DovrebbeRifiutareLibreriaEMixerNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TWarSceneAudio.Create(nil, FMixerRef, nil);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TWarSceneAudio.Create(TAppFakeLibrary.Create, nil, nil);
    end, EArgumentNilException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestWarAppSceneAudio);

end.
