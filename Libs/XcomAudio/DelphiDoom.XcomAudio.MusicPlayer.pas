{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom audio library - the music of the game (the music part of    }
{  Mod: loadExtraResources, getMusic, getRandomMusic and playMusic)             }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomAudio.MusicPlayer;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.XcomEngine.Resources.Intf,
  DelphiDoom.XcomEngine.Music.Intf, DelphiDoom.XcomAdlib.Intf, DelphiDoom.XcomAudio.Intf;

type
  /// <summary>Makes the player of the Adlib (two chips) the Adlib tracks share</summary>
  TXcomAdlibPlayerFactory = reference to function: IXcomAdlibPlayer;

  /// <summary>The songs of the Adlib containers of the game data in use</summary>
  TXcomAdlibSongsFactory = reference to function(const AResources: IXcomResources): IXcomAdlibSongs;

  /// <summary>A number from 0 to AMaximum (RNG::seedless)</summary>
  TXcomMusicRandom = reference to function(AMaximum: Integer): Integer;

  /// <summary>
  ///   The musics of the rulesets and which one plays. Mod::loadExtraResources tries, for each music, the preferred
  ///   format and then FLAC, OGG, MP3, MOD, WAV, Adlib, GM and MIDI, and keeps the first that loads. Here the Adlib
  ///   (ADLIB.CAT with the intro songs of AINTRO.CAT) and the WAV files of the SOUND folder load; the other formats
  ///   give nothing, so the next one is tried
  /// </summary>
  TXcomMusicPlayer = class(TInterfacedObject, IXcomMusicPlayer)
  strict private
    type
      TEntry = record
        MusicType: string;
        Track: IXcomMusicTrack;
      end;
    var
      FSink: IXcomMusicSink;
      FSettings: IXcomMusicSettings;
      FAdlibPlayerFactory: TXcomAdlibPlayerFactory;
      FSongsFactory: TXcomAdlibSongsFactory;
      FRandom: TXcomMusicRandom;
      FRate: Integer;
      FEntries: TList<TEntry>;
      FPlayingMusic: string;
      FAdlibPlayer: IXcomAdlibPlayer;
    function LoadMusic(AFormat: Integer; const ARule: TXcomMusicRule; const AResources: IXcomResources;
      const ASongs: IXcomAdlibSongs): IXcomMusicTrack;
    function LoadAdlib(const ARule: TXcomMusicRule; const ASongs: IXcomAdlibSongs): IXcomMusicTrack;
    function LoadWave(const ARule: TXcomMusicRule; const AResources: IXcomResources): IXcomMusicTrack;
    function Find(const AType: string): IXcomMusicTrack;
  public
    constructor Create(const ASink: IXcomMusicSink; const ASettings: IXcomMusicSettings; ARate: Integer;
      const AAdlibPlayerFactory: TXcomAdlibPlayerFactory; const ASongsFactory: TXcomAdlibSongsFactory;
      const ARandom: TXcomMusicRandom = nil);
    destructor Destroy; override;
    procedure Reload(const AResources: IXcomResources);
    procedure PlayMusic(const AName: string; AId: Integer = 0);
    procedure Stop;
    procedure Pause;
    procedure Resume;
    function IsPlaying: Boolean;
    function CurrentFormat: string;
    function LoadedCount: Integer;
    /// <summary>The types of the musics that loaded, in order</summary>
    function Types: TArray<string>;
  end;

implementation

uses
  DelphiDoom.XcomAudio.Types, DelphiDoom.XcomAudio.AdlibTrack, DelphiDoom.XcomAudio.WavTrack;

{ TXcomMusicPlayer }

constructor TXcomMusicPlayer.Create(const ASink: IXcomMusicSink; const ASettings: IXcomMusicSettings; ARate: Integer;
  const AAdlibPlayerFactory: TXcomAdlibPlayerFactory; const ASongsFactory: TXcomAdlibSongsFactory;
  const ARandom: TXcomMusicRandom);
begin
  inherited Create;
  FSink := ASink;
  FSettings := ASettings;
  FRate := ARate;
  FAdlibPlayerFactory := AAdlibPlayerFactory;
  FSongsFactory := ASongsFactory;
  FRandom := ARandom;
  if not Assigned(FRandom) then
    FRandom := function(AMaximum: Integer): Integer
      begin
        Result := Random(AMaximum + 1);
      end;
  FEntries := TList<TEntry>.Create;
end;

destructor TXcomMusicPlayer.Destroy;
begin
  Stop;
  FEntries.Free;
  inherited Destroy;
end;

function TXcomMusicPlayer.LoadAdlib(const ARule: TXcomMusicRule; const ASongs: IXcomAdlibSongs): IXcomMusicTrack;
var
  LTrack: Integer;
  LSong: TBytes;
begin
  Result := nil;
  if (ASongs = nil) or (ASongs.Count = 0) or (ARule.CatPos < 0) then
    Exit;
  LTrack := ARule.CatPos;
  if LTrack < ASongs.Count then
    LSong := ASongs.Song(LTrack)
  else
  begin
    Dec(LTrack, ASongs.Count);
    if LTrack >= ASongs.IntroCount then
      Exit;
    LSong := ASongs.IntroSong(LTrack);
  end;
  if Length(LSong) = 0 then
    Exit;
  if FAdlibPlayer = nil then
    FAdlibPlayer := FAdlibPlayerFactory();
  Result := TXcomAdlibTrack.Create(FAdlibPlayer, FSettings, LSong, ARule.Normalization);
end;

function TXcomMusicPlayer.LoadWave(const ARule: TXcomMusicRule; const AResources: IXcomResources): IXcomMusicTrack;
var
  LBytes: TBytes;
begin
  Result := nil;
  LBytes := AResources.SoundFile(LowerCase(ARule.Name) + '.wav');
  if Length(LBytes) = 0 then
    Exit;
  try
    Result := TXcomWavTrack.Create(LBytes, FRate);
  except
    on EXcomAudioException do
      Result := nil;
  end;
end;

function TXcomMusicPlayer.LoadMusic(AFormat: Integer; const ARule: TXcomMusicRule;
  const AResources: IXcomResources; const ASongs: IXcomAdlibSongs): IXcomMusicTrack;
begin
  case TXcomMusicFormat(AFormat) of
    mfAdlib:
      Result := LoadAdlib(ARule, ASongs);
    mfWav:
      Result := LoadWave(ARule, AResources);
  else
    // FLAC, OGG, MP3, MOD (digital decoders), GM and MIDI (the GM.CAT songs) are not played here
    Result := nil;
  end;
end;

procedure TXcomMusicPlayer.Reload(const AResources: IXcomResources);
var
  LRule: TXcomMusicRule;
  LSongs: IXcomAdlibSongs;
  LPriority: array[0..8] of Integer;
  LIndex: Integer;
  LTrack: IXcomMusicTrack;
  LEntry: TEntry;
begin
  Stop;
  FEntries.Clear;
  FPlayingMusic := '';
  if FSettings.Mute then
    Exit;
  LSongs := nil;
  if Assigned(FSongsFactory) then
    LSongs := FSongsFactory(AResources);
  // the preferred format first, then the default order
  LPriority[0] := FSettings.PreferredFormat;
  LPriority[1] := Ord(mfFlac);
  LPriority[2] := Ord(mfOgg);
  LPriority[3] := Ord(mfMp3);
  LPriority[4] := Ord(mfMod);
  LPriority[5] := Ord(mfWav);
  LPriority[6] := Ord(mfAdlib);
  LPriority[7] := Ord(mfGm);
  LPriority[8] := Ord(mfMidi);
  for LRule in AResources.MusicRules do
  begin
    LTrack := nil;
    LIndex := 0;
    while (LTrack = nil) and (LIndex <= High(LPriority)) do
    begin
      LTrack := LoadMusic(LPriority[LIndex], LRule, AResources, LSongs);
      Inc(LIndex);
    end;
    if LTrack <> nil then
    begin
      LEntry.MusicType := LRule.MusicType;
      LEntry.Track := LTrack;
      FEntries.Add(LEntry);
    end;
  end;
end;

function TXcomMusicPlayer.Find(const AType: string): IXcomMusicTrack;
var
  LEntry: TEntry;
begin
  for LEntry in FEntries do
    if LEntry.MusicType = AType then
      Exit(LEntry.Track);
  Result := nil;
end;

procedure TXcomMusicPlayer.PlayMusic(const AName: string; AId: Integer);
var
  LLoop: Integer;
  LTrack: IXcomMusicTrack;
  LMatches: TList<IXcomMusicTrack>;
  LEntry: TEntry;
begin
  if FSettings.Mute or (FPlayingMusic = AName) then
    Exit;
  LLoop := -1;
  // hacks
  if (not FSettings.AlwaysLoop) and ((AName = 'GMSTORY') or (AName = 'GMWIN') or (AName = 'GMLOSE')) then
    LLoop := 0;
  LTrack := nil;
  if AId = 0 then
  begin
    // getRandomMusic: the tracks whose type contains the name
    LMatches := TList<IXcomMusicTrack>.Create;
    try
      for LEntry in FEntries do
        if Pos(AName, LEntry.MusicType) > 0 then
          LMatches.Add(LEntry.Track);
      if LMatches.Count > 0 then
        LTrack := LMatches[FRandom(LMatches.Count - 1)];
    finally
      LMatches.Free;
    end;
  end
  else
    // getMusic(name + id): the C++ throws when there is none; here nothing plays
    LTrack := Find(AName + IntToStr(AId));
  if LTrack = nil then
    Exit;
  FSink.PlayTrack(LTrack, LLoop);
  FPlayingMusic := AName;
end;

procedure TXcomMusicPlayer.Stop;
begin
  if FSink <> nil then
    FSink.StopTrack;
end;

procedure TXcomMusicPlayer.Pause;
begin
  FSink.PauseTrack(True);
end;

procedure TXcomMusicPlayer.Resume;
begin
  FSink.PauseTrack(False);
end;

function TXcomMusicPlayer.IsPlaying: Boolean;
var
  LTrack: IXcomMusicTrack;
begin
  LTrack := FSink.CurrentTrack;
  Result := (LTrack <> nil) and LTrack.IsPlaying;
end;

function TXcomMusicPlayer.CurrentFormat: string;
var
  LTrack: IXcomMusicTrack;
begin
  LTrack := FSink.CurrentTrack;
  if LTrack = nil then
    Result := 'Adlib'
  else
    Result := LTrack.Format;
end;

function TXcomMusicPlayer.LoadedCount: Integer;
begin
  Result := FEntries.Count;
end;

function TXcomMusicPlayer.Types: TArray<string>;
var
  LIndex: Integer;
begin
  SetLength(Result, FEntries.Count);
  for LIndex := 0 to FEntries.Count - 1 do
    Result[LIndex] := FEntries[LIndex].MusicType;
end;

end.
