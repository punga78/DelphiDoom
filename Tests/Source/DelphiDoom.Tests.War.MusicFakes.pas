{******************************************************************************}
{                                                                              }
{  DelphiDoom: fakes for the tests of the music and of the sounds of Libs\War  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.MusicFakes;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.War.Music.Types, DelphiDoom.War.Music.Intf, DelphiDoom.War.Sound.Intf,
  DelphiDoom.War.Audio.Types, DelphiDoom.War.Audio.Intf;

type
  /// <summary>A synth that writes down its calls as text (the same format as war_music_ref.c) and adds a constant to the samples</summary>
  TFakeMusicSynth = class(TInterfacedObject, IWarMusicSynth)
  strict private
    FCalls: TStringList;
    FRendered: Integer;
    FLevel: SmallInt;
  public
    constructor Create(ALevel: SmallInt = 0);
    destructor Destroy; override;
    procedure ProgramChange(AChannel, AProgram: Integer; AIsDrums: Boolean);
    procedure NoteOn(AChannel, AKey: Integer; AVelocity: Single);
    procedure NoteOff(AChannel, AKey: Integer);
    procedure PitchBend(AChannel, AValue: Integer);
    procedure ControlChange(AChannel, AController, AValue: Integer);
    procedure AllNotesOff;
    procedure Render(ABuffer: PSmallInt; ASampleCount: Integer);
    /// <summary>One line for each call, with the number of samples rendered until then: "pos ON ch key bits"</summary>
    property Calls: TStringList read FCalls;
    property Rendered: Integer read FRendered;
  end;

  /// <summary>A timeline that gives the events it is given (and refuses what it is told to)</summary>
  TFakeMusicTimeline = class(TInterfacedObject, IWarMusicTimeline)
  strict private
    FEvents: TArray<TWarMusicEvent>;
    FNext: Integer;
    FAccepts: Boolean;
  public
    LoadCount: Integer;
    RewindCount: Integer;
    constructor Create(const AEvents: TArray<TWarMusicEvent>; AAccepts: Boolean = True);
    function Load(const AMidi: TBytes): Boolean;
    function TryNext(out AEvent: TWarMusicEvent): Boolean;
    procedure Rewind;
  end;

  /// <summary>A generator that gives the numbers it is given in order, and writes down the limits it was asked for</summary>
  TScriptedRandom = class(TInterfacedObject, IWarRandom)
  strict private
    FValues: TArray<Integer>;
    FIndex: Integer;
  public
    Limits: TArray<Integer>;
    constructor Create(const AValues: array of Integer);
    function Below(ALimit: Integer): Integer;
  end;

  /// <summary>A mixer that only writes down what it is asked to play</summary>
  TFakeSoundMixer = class(TInterfacedObject, IWarSoundMixer)
  strict private
    FPlayed: TArray<Integer>;
    FStopped: TArray<Integer>;
    FNextHandle: Integer;
  public
    /// <summary>What Mix adds to every sample</summary>
    Level: SmallInt;
    function Play(ASoundIndex: Integer; ALoop: Boolean): Integer;
    function PlayAt(ASoundIndex: Integer; AX, AY: Single; ALoop: Boolean): Integer;
    procedure Stop(AHandle: Integer);
    procedure StopAll;
    procedure SetViewport(AX, AY, AWidth, AHeight: Single);
    procedure SetVolume(AVolume: Single; AEnabled: Boolean);
    procedure SetSilenced(ASilenced: Boolean);
    procedure Mix(ABuffer: PSmallInt; ASampleCount: Integer);
    function ActiveVoices: Integer;
    property Played: TArray<Integer> read FPlayed;
    property Stopped: TArray<Integer> read FStopped;
  end;

implementation

{ TFakeMusicSynth }

constructor TFakeMusicSynth.Create(ALevel: SmallInt);
begin
  inherited Create;
  FCalls := TStringList.Create;
  FLevel := ALevel;
end;

destructor TFakeMusicSynth.Destroy;
begin
  FCalls.Free;
  inherited;
end;

procedure TFakeMusicSynth.ProgramChange(AChannel, AProgram: Integer; AIsDrums: Boolean);
begin
  FCalls.Add(Format('%d PC %d %d %d', [FRendered, AChannel, AProgram, Ord(AIsDrums)]));
end;

procedure TFakeMusicSynth.NoteOn(AChannel, AKey: Integer; AVelocity: Single);
var
  LBits: Cardinal;
begin
  Move(AVelocity, LBits, SizeOf(LBits));
  FCalls.Add(Format('%d ON %d %d %s', [FRendered, AChannel, AKey, LowerCase(IntToHex(LBits, 8))]));
end;

procedure TFakeMusicSynth.NoteOff(AChannel, AKey: Integer);
begin
  FCalls.Add(Format('%d OF %d %d', [FRendered, AChannel, AKey]));
end;

procedure TFakeMusicSynth.PitchBend(AChannel, AValue: Integer);
begin
  FCalls.Add(Format('%d PB %d %d', [FRendered, AChannel, AValue]));
end;

procedure TFakeMusicSynth.ControlChange(AChannel, AController, AValue: Integer);
begin
  FCalls.Add(Format('%d CC %d %d %d', [FRendered, AChannel, AController, AValue]));
end;

procedure TFakeMusicSynth.AllNotesOff;
begin
  FCalls.Add(Format('%d AO', [FRendered]));
end;

procedure TFakeMusicSynth.Render(ABuffer: PSmallInt; ASampleCount: Integer);
var
  LIndex: Integer;
begin
  for LIndex := 0 to ASampleCount - 1 do
  begin
    ABuffer^ := ABuffer^ + FLevel;
    Inc(ABuffer);
  end;
  Inc(FRendered, ASampleCount);
end;

{ TFakeMusicTimeline }

constructor TFakeMusicTimeline.Create(const AEvents: TArray<TWarMusicEvent>; AAccepts: Boolean);
begin
  inherited Create;
  FEvents := AEvents;
  FAccepts := AAccepts;
end;

function TFakeMusicTimeline.Load(const AMidi: TBytes): Boolean;
begin
  Inc(LoadCount);
  FNext := 0;
  Result := FAccepts;
end;

function TFakeMusicTimeline.TryNext(out AEvent: TWarMusicEvent): Boolean;
begin
  Result := FNext <= High(FEvents);
  if Result then
  begin
    AEvent := FEvents[FNext];
    Inc(FNext);
  end
  else
    AEvent := Default(TWarMusicEvent);
end;

procedure TFakeMusicTimeline.Rewind;
begin
  Inc(RewindCount);
  FNext := 0;
end;

{ TScriptedRandom }

constructor TScriptedRandom.Create(const AValues: array of Integer);
var
  LIndex: Integer;
begin
  inherited Create;
  SetLength(FValues, Length(AValues));
  for LIndex := 0 to High(AValues) do
    FValues[LIndex] := AValues[LIndex];
end;

function TScriptedRandom.Below(ALimit: Integer): Integer;
begin
  SetLength(Limits, Length(Limits) + 1);
  Limits[High(Limits)] := ALimit;
  if FIndex < Length(FValues) then
    Result := FValues[FIndex]
  else
    Result := 0;
  Inc(FIndex);
end;

{ TFakeSoundMixer }

function TFakeSoundMixer.Play(ASoundIndex: Integer; ALoop: Boolean): Integer;
begin
  Inc(FNextHandle);
  SetLength(FPlayed, Length(FPlayed) + 1);
  FPlayed[High(FPlayed)] := ASoundIndex;
  Result := FNextHandle;
end;

function TFakeSoundMixer.PlayAt(ASoundIndex: Integer; AX, AY: Single; ALoop: Boolean): Integer;
begin
  Result := Play(ASoundIndex, ALoop);
end;

procedure TFakeSoundMixer.Stop(AHandle: Integer);
begin
  SetLength(FStopped, Length(FStopped) + 1);
  FStopped[High(FStopped)] := AHandle;
end;

procedure TFakeSoundMixer.StopAll;
begin
end;

procedure TFakeSoundMixer.SetViewport(AX, AY, AWidth, AHeight: Single);
begin
end;

procedure TFakeSoundMixer.SetVolume(AVolume: Single; AEnabled: Boolean);
begin
end;

procedure TFakeSoundMixer.SetSilenced(ASilenced: Boolean);
begin
end;

procedure TFakeSoundMixer.Mix(ABuffer: PSmallInt; ASampleCount: Integer);
var
  LIndex: Integer;
begin
  for LIndex := 0 to ASampleCount - 1 do
  begin
    ABuffer^ := ABuffer^ + Level;
    Inc(ABuffer);
  end;
end;

function TFakeSoundMixer.ActiveVoices: Integer;
begin
  Result := Length(FPlayed) - Length(FStopped);
end;

end.
