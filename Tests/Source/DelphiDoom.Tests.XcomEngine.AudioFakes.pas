{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the audio of the xcom game - the fakes (an Adlib        }
{  player, a music track, the songs, a music player) and a maker of WAV files   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomEngine.AudioFakes;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.XcomEngine.Resources.Intf, DelphiDoom.XcomEngine.Music.Intf,
  DelphiDoom.XcomEngine.State, DelphiDoom.XcomAdlib.Intf, DelphiDoom.XcomAudio.Intf, DelphiDoom.XcomAudio.Factory;

type
  /// <summary>Makes PCM WAV files for the tests</summary>
  TWaveMaker = class
  public
    class function Make(ARate, AChannels, ABits: Integer; const AData: TBytes): TBytes; static;
    /// <summary>A 22050 Hz mono 8 bit file of AFrames samples that all have the value AValue</summary>
    class function Constant(AValue: Byte; AFrames: Integer): TBytes; static;
  end;

  /// <summary>The real decoders of the libraries, for the tests of what is built on them</summary>
  TTestDecoders = class
  public
    class function Sound: IXcomSampleDecoder; static;
    class function Mp3: IXcomSampleDecoder; static;
  end;

  /// <summary>An IXcomSampleDecoder that counts the decodes and gives them to another one</summary>
  TCountingDecoder = class(TInterfacedObject, IXcomSampleDecoder)
  strict private
    FInner: IXcomSampleDecoder;
  public
    Decodes: Integer;
    constructor Create(const AInner: IXcomSampleDecoder);
    function Accepts(const AData: TBytes): Boolean;
    function TryDecode(const AData: TBytes; ARate: Integer; out ASamples: TArray<SmallInt>): Boolean;
  end;

  /// <summary>IXcomMusicSettings with fields</summary>
  TFakeSettings = class(TInterfacedObject, IXcomMusicSettings)
  public
    MuteOn: Boolean;
    LoopOn: Boolean;
    Preferred: Integer;
    function Mute: Boolean;
    function AlwaysLoop: Boolean;
    function PreferredFormat: Integer;
  end;

  /// <summary>IXcomAdlibPlayer that records what it is asked and renders a constant</summary>
  TFakeAdlibPlayer = class(TInterfacedObject, IXcomAdlibPlayer)
  public
    Loaded: TBytes;
    PlayVolume: Single;
    Plays: Integer;
    Stops: Integer;
    Renders: Integer;
    Playing: Boolean;
    RenderValue: SmallInt;
    LastVolume: Single;
    procedure Load(const ASong: TBytes);
    procedure Play(AVolume: Single);
    procedure Stop;
    procedure Fade;
    function IsPlaying: Boolean;
    procedure SetTempo(AValue: Integer);
    procedure SetVolume(AValue: Integer);
    function Polyphony: Integer;
    procedure SaveState(AIndex: Integer);
    procedure LoadState(AIndex: Integer);
    function PendingBytes: Integer;
    procedure Render(const ABuffer: TArray<SmallInt>; ABytes: Integer; AVolume: Single);
  end;

  /// <summary>IXcomMusicTrack that records its calls and adds a constant</summary>
  TFakeTrack = class(TInterfacedObject, IXcomMusicTrack)
  public
    Value: SmallInt;
    Started: Integer;
    Stopped: Integer;
    LastLoop: Integer;
    LastVolume: Single;
    Active: Boolean;
    FormatName: string;
    function Format: string;
    procedure Start(ALoop: Integer);
    procedure Stop;
    function IsPlaying: Boolean;
    procedure Render(ABuffer: PSmallInt; ABytes: Integer; AVolume: Single);
  end;

  TFakeSongs = class(TInterfacedObject, IXcomAdlibSongs)
  public
    Songs: TArray<TBytes>;
    Intro: TArray<TBytes>;
    function Count: Integer;
    function Song(AIndex: Integer): TBytes;
    function IntroCount: Integer;
    function IntroSong(AIndex: Integer): TBytes;
  end;

  /// <summary>IXcomMusicPlayer that records what the game asks</summary>
  TFakeMusicPlayer = class(TInterfacedObject, IXcomMusicPlayer)
  public
    Names: TStringList;
    Reloads: Integer;
    Stops: Integer;
    constructor Create;
    destructor Destroy; override;
    procedure Reload(const AResources: IXcomResources);
    procedure PlayMusic(const AName: string; AId: Integer = 0);
    procedure Stop;
    procedure Pause;
    procedure Resume;
    function IsPlaying: Boolean;
    function CurrentFormat: string;
    function LoadedCount: Integer;
  end;

  /// <summary>A state whose interface (musicMenu of the fake resources) has a music</summary>
  TMusicState = class(TXcomState)
  public
    constructor Create(AHost: TXcomStateHost);
  end;

implementation

class function TWaveMaker.Make(ARate, AChannels, ABits: Integer; const AData: TBytes): TBytes;
var
  LStream: TBytesStream;

  procedure PutLong(AValue: Cardinal);
  begin
    LStream.WriteBuffer(AValue, 4);
  end;

  procedure PutWord(AValue: Word);
  begin
    LStream.WriteBuffer(AValue, 2);
  end;

begin
  LStream := TBytesStream.Create;
  try
    LStream.WriteBuffer(TEncoding.ASCII.GetBytes('RIFF')[0], 4);
    PutLong(36 + Length(AData));
    LStream.WriteBuffer(TEncoding.ASCII.GetBytes('WAVEfmt ')[0], 8);
    PutLong(16);
    PutWord(1);
    PutWord(AChannels);
    PutLong(ARate);
    PutLong(ARate * AChannels * (ABits div 8));
    PutWord(AChannels * (ABits div 8));
    PutWord(ABits);
    LStream.WriteBuffer(TEncoding.ASCII.GetBytes('data')[0], 4);
    PutLong(Length(AData));
    if Length(AData) > 0 then
      LStream.WriteBuffer(AData[0], Length(AData));
    Result := Copy(LStream.Bytes, 0, LStream.Size);
  finally
    LStream.Free;
  end;
end;

class function TWaveMaker.Constant(AValue: Byte; AFrames: Integer): TBytes;
var
  LData: TBytes;
  LIndex: Integer;
begin
  SetLength(LData, AFrames);
  for LIndex := 0 to AFrames - 1 do
    LData[LIndex] := AValue;
  Result := Make(22050, 1, 8, LData);
end;

function TFakeSettings.Mute: Boolean;
begin
  Result := MuteOn;
end;

function TFakeSettings.AlwaysLoop: Boolean;
begin
  Result := LoopOn;
end;

function TFakeSettings.PreferredFormat: Integer;
begin
  Result := Preferred;
end;

class function TTestDecoders.Sound: IXcomSampleDecoder;
begin
  Result := TXcomAudioFactory.CreateSoundDecoder;
end;

class function TTestDecoders.Mp3: IXcomSampleDecoder;
begin
  Result := TXcomAudioFactory.CreateMp3Decoder;
end;

constructor TCountingDecoder.Create(const AInner: IXcomSampleDecoder);
begin
  inherited Create;
  FInner := AInner;
end;

function TCountingDecoder.Accepts(const AData: TBytes): Boolean;
begin
  Result := FInner.Accepts(AData);
end;

function TCountingDecoder.TryDecode(const AData: TBytes; ARate: Integer; out ASamples: TArray<SmallInt>): Boolean;
begin
  Inc(Decodes);
  Result := FInner.TryDecode(AData, ARate, ASamples);
end;

procedure TFakeAdlibPlayer.Load(const ASong: TBytes);
begin
  Loaded := ASong;
end;

procedure TFakeAdlibPlayer.Play(AVolume: Single);
begin
  PlayVolume := AVolume;
  Inc(Plays);
  Playing := True;
end;

procedure TFakeAdlibPlayer.Stop;
begin
  Inc(Stops);
  Playing := False;
end;

procedure TFakeAdlibPlayer.Fade;
begin
end;

function TFakeAdlibPlayer.IsPlaying: Boolean;
begin
  Result := Playing;
end;

procedure TFakeAdlibPlayer.SetTempo(AValue: Integer);
begin
end;

procedure TFakeAdlibPlayer.SetVolume(AValue: Integer);
begin
end;

function TFakeAdlibPlayer.Polyphony: Integer;
begin
  Result := 0;
end;

procedure TFakeAdlibPlayer.SaveState(AIndex: Integer);
begin
end;

procedure TFakeAdlibPlayer.LoadState(AIndex: Integer);
begin
end;

function TFakeAdlibPlayer.PendingBytes: Integer;
begin
  Result := 0;
end;

procedure TFakeAdlibPlayer.Render(const ABuffer: TArray<SmallInt>; ABytes: Integer; AVolume: Single);
var
  LIndex: Integer;
begin
  Inc(Renders);
  LastVolume := AVolume;
  for LIndex := 0 to ABytes div 2 - 1 do
    ABuffer[LIndex] := RenderValue;
end;

function TFakeTrack.Format: string;
begin
  Result := FormatName;
end;

procedure TFakeTrack.Start(ALoop: Integer);
begin
  Inc(Started);
  LastLoop := ALoop;
  Active := True;
end;

procedure TFakeTrack.Stop;
begin
  Inc(Stopped);
  Active := False;
end;

function TFakeTrack.IsPlaying: Boolean;
begin
  Result := Active;
end;

procedure TFakeTrack.Render(ABuffer: PSmallInt; ABytes: Integer; AVolume: Single);
var
  LIndex: Integer;
begin
  LastVolume := AVolume;
  for LIndex := 0 to ABytes div 2 - 1 do
  begin
    ABuffer^ := ABuffer^ + Trunc(Value * AVolume);
    Inc(ABuffer);
  end;
end;

function TFakeSongs.Count: Integer;
begin
  Result := Length(Songs);
end;

function TFakeSongs.Song(AIndex: Integer): TBytes;
begin
  Result := Songs[AIndex];
end;

function TFakeSongs.IntroCount: Integer;
begin
  Result := Length(Intro);
end;

function TFakeSongs.IntroSong(AIndex: Integer): TBytes;
begin
  Result := Intro[AIndex];
end;

constructor TFakeMusicPlayer.Create;
begin
  inherited Create;
  Names := TStringList.Create;
end;

destructor TFakeMusicPlayer.Destroy;
begin
  Names.Free;
  inherited Destroy;
end;

procedure TFakeMusicPlayer.Reload(const AResources: IXcomResources);
begin
  Inc(Reloads);
end;

procedure TFakeMusicPlayer.PlayMusic(const AName: string; AId: Integer);
begin
  Names.Add(AName + ':' + IntToStr(AId));
end;

procedure TFakeMusicPlayer.Stop;
begin
  Inc(Stops);
end;

procedure TFakeMusicPlayer.Pause;
begin
end;

procedure TFakeMusicPlayer.Resume;
begin
end;

function TFakeMusicPlayer.IsPlaying: Boolean;
begin
  Result := False;
end;

function TFakeMusicPlayer.CurrentFormat: string;
begin
  Result := 'Wav';
end;

function TFakeMusicPlayer.LoadedCount: Integer;
begin
  Result := 0;
end;

constructor TMusicState.Create(AHost: TXcomStateHost);
begin
  inherited Create(AHost);
  SetInterface('musicMenu');
end;

end.
