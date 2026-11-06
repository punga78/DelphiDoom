{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the audio library - the fake device                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Audio.Fakes;

interface

uses
  System.Generics.Collections, DelphiDoom.Audio.Types, DelphiDoom.Audio.Intf;

type
  TFakeVoice = class(TInterfacedObject, IAudioVoice)
  public
    Playing: Boolean;
    PlayCount: Integer;
    StopCount: Integer;
    RewindCount: Integer;
    Pan: Integer;
    Volume: Integer;
    LoadCode: Integer;
    Loaded: Boolean;
    function Load(const ASample: TSfxSample): Integer;
    procedure Play;
    procedure Stop;
    procedure Rewind;
    procedure SetPan(APan: Integer);
    procedure SetVolume(AVolume: Integer);
    function IsPlaying: Boolean;
  end;

  TFakeDevice = class(TInterfacedObject, ISoundDevice)
  public
    Voices: TList<TFakeVoice>;
    VoiceRefs: TList<IAudioVoice>;
    /// <summary>The next calls to CreateVoice fail, this many</summary>
    FailuresLeft: Integer;
    Calls: Integer;
    AverageBytesSeen: TList<Cardinal>;
    NextLoadCode: Integer;
    ShutdownCount: Integer;
    constructor Create;
    destructor Destroy; override;
    function Initialize: Boolean;
    procedure Shutdown;
    function CreateVoice(const ASample: TSfxSample; out AVoice: IAudioVoice): Integer;
  end;

  TFakeSource = class(TInterfacedObject, ISfxSampleSource)
  public
    Lengths: TDictionary<Integer, Integer>;
    External: Boolean;
    DiscardCount: Integer;
    LoadCount: Integer;
    StoredAverage: Cardinal;
    constructor Create;
    destructor Destroy; override;
    function Load(ASoundId: Integer): TSfxSample;
    procedure DiscardExternal(ASoundId: Integer);
    procedure StoreAverageBytes(ASoundId: Integer; AAverageBytes: Cardinal);
    function NameOf(ASoundId: Integer): string;
  end;

implementation

{ TFakeVoice }

function TFakeVoice.Load(const ASample: TSfxSample): Integer;
begin
  Result := LoadCode;
  Loaded := Result = 0;
end;

procedure TFakeVoice.Play;
begin
  Playing := True;
  Inc(PlayCount);
end;

procedure TFakeVoice.Stop;
begin
  Playing := False;
  Inc(StopCount);
end;

procedure TFakeVoice.Rewind;
begin
  Inc(RewindCount);
end;

procedure TFakeVoice.SetPan(APan: Integer);
begin
  Pan := APan;
end;

procedure TFakeVoice.SetVolume(AVolume: Integer);
begin
  Volume := AVolume;
end;

function TFakeVoice.IsPlaying: Boolean;
begin
  Result := Playing;
end;

{ TFakeDevice }

constructor TFakeDevice.Create;
begin
  inherited Create;
  Voices := TList<TFakeVoice>.Create;
  VoiceRefs := TList<IAudioVoice>.Create;
  AverageBytesSeen := TList<Cardinal>.Create;
end;

destructor TFakeDevice.Destroy;
begin
  AverageBytesSeen.Free;
  VoiceRefs.Free;
  Voices.Free;
  inherited Destroy;
end;

function TFakeDevice.Initialize: Boolean;
begin
  Result := True;
end;

procedure TFakeDevice.Shutdown;
begin
  Inc(ShutdownCount);
end;

function TFakeDevice.CreateVoice(const ASample: TSfxSample; out AVoice: IAudioVoice): Integer;
var
  LVoice: TFakeVoice;
begin
  Inc(Calls);
  AverageBytesSeen.Add(ASample.Format.AverageBytesPerSecond);
  AVoice := nil;
  if FailuresLeft > 0 then
  begin
    Dec(FailuresLeft);
    Result := 1;
    Exit;
  end;
  LVoice := TFakeVoice.Create;
  LVoice.LoadCode := NextLoadCode;
  Voices.Add(LVoice);
  AVoice := LVoice;
  VoiceRefs.Add(AVoice);
  Result := 0;
end;

{ TFakeSource }

constructor TFakeSource.Create;
begin
  inherited Create;
  Lengths := TDictionary<Integer, Integer>.Create;
end;

destructor TFakeSource.Destroy;
begin
  Lengths.Free;
  inherited Destroy;
end;

function TFakeSource.Load(ASoundId: Integer): TSfxSample;
begin
  Inc(LoadCount);
  FillChar(Result, SizeOf(Result), 0);
  Result.Format.Tag := 1;
  Result.Format.Channels := 1;
  Result.Format.SamplesPerSecond := 11025;
  Result.Format.AverageBytesPerSecond := 99;
  Result.Format.BitsPerSample := 8;
  if not Lengths.TryGetValue(ASoundId, Result.Length) then
    Result.Length := 100;
  Result.IsExternal := External;
end;

procedure TFakeSource.DiscardExternal(ASoundId: Integer);
begin
  Inc(DiscardCount);
  External := False;
end;

procedure TFakeSource.StoreAverageBytes(ASoundId: Integer; AAverageBytes: Cardinal);
begin
  StoredAverage := AAverageBytes;
end;

function TFakeSource.NameOf(ASoundId: Integer): string;
begin
  Result := 'DSPISTOL';
end;

end.
