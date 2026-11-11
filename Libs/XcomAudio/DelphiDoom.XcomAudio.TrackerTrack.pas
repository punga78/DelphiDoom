{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom audio library - a music made of a module (MOD, S3M, XM,     }
{  IT) played by the tracker of Libs\Mikmod                                     }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomAudio.TrackerTrack;

interface

uses
  System.SysUtils, DelphiDoom.Tracker.Types, DelphiDoom.Tracker.Player, DelphiDoom.XcomAudio.Intf;

type
  /// <summary>
  ///   A module music. The tracker makes the samples when the mixer asks for them (no thread and no device of its
  ///   own: Libs\Mikmod gives the sequencer and the mixer of the channels, the output is the mixer of the game)
  /// </summary>
  TXcomTrackerTrack = class(TInterfacedObject, IXcomMusicTrack, IXcomMusicPreparation)
  strict private
    FData: TBytes;
    FRate: Integer;
    FModule: TTrackerModule;
    FPlayer: TTrackerPlayer;
    FPrepared: Boolean;
    FRemaining: Integer;
    FActive: Boolean;
    FLoopForever: Boolean;
    FFrames: TArray<SmallInt>;
    procedure StartPlayer;
  public
    /// <param name="AData">The bytes of the module</param>
    /// <param name="ARate">The rate of the mixer</param>
    constructor Create(const AData: TBytes; ARate: Integer);
    destructor Destroy; override;
    /// <summary>True when the bytes are a module that one of the loaders reads</summary>
    class function Accepts(const AData: TBytes): Boolean; static;
    function Format: string;
    /// <summary>Reads the module; one that cannot be read is a silent track</summary>
    procedure Prepare;
    procedure Start(ALoop: Integer);
    procedure Stop;
    function IsPlaying: Boolean;
    procedure Render(ABuffer: PSmallInt; ABytes: Integer; AVolume: Single);
  end;

implementation

uses
  DelphiDoom.Tracker.Loader.It, DelphiDoom.Tracker.Loader.ProTracker, DelphiDoom.Tracker.Loader.S3m,
  DelphiDoom.Tracker.Loader.Xm, DelphiDoom.XcomAudio.Types;

constructor TXcomTrackerTrack.Create(const AData: TBytes; ARate: Integer);
begin
  inherited Create;
  FData := AData;
  FRate := ARate;
end;

destructor TXcomTrackerTrack.Destroy;
begin
  FPlayer.Free;
  FModule.Free;
  inherited Destroy;
end;

class function TXcomTrackerTrack.Accepts(const AData: TBytes): Boolean;
begin
  Result := TTrackerXmLoader.Detect(AData) or TTrackerItLoader.Detect(AData) or TTrackerS3mLoader.Detect(AData) or
    TTrackerModLoader.Detect(AData);
end;

function TXcomTrackerTrack.Format: string;
begin
  Result := 'MOD';
end;

procedure TXcomTrackerTrack.Prepare;
begin
  if FPrepared then
    Exit;
  FPrepared := True;
  try
    if TTrackerXmLoader.Detect(FData) then
      FModule := TTrackerXmLoader.Load(FData)
    else if TTrackerItLoader.Detect(FData) then
      FModule := TTrackerItLoader.Load(FData)
    else if TTrackerS3mLoader.Detect(FData) then
      FModule := TTrackerS3mLoader.Load(FData)
    else if TTrackerModLoader.Detect(FData) then
      FModule := TTrackerModLoader.Load(FData);
  except
    on ETrackerException do
      FreeAndNil(FModule);
  end;
end;

procedure TXcomTrackerTrack.StartPlayer;
begin
  FreeAndNil(FPlayer);
  FPlayer := TTrackerPlayer.Create(FModule, FRate, FLoopForever);
end;

procedure TXcomTrackerTrack.Start(ALoop: Integer);
begin
  Prepare;
  FLoopForever := ALoop < 0;
  if ALoop <= 1 then
    FRemaining := 1
  else
    FRemaining := ALoop;
  FActive := FModule <> nil;
  if FActive then
    StartPlayer;
end;

procedure TXcomTrackerTrack.Stop;
begin
  FActive := False;
  FreeAndNil(FPlayer);
  FreeAndNil(FModule);
  FPrepared := False;
end;

function TXcomTrackerTrack.IsPlaying: Boolean;
begin
  Result := FActive;
end;

procedure TXcomTrackerTrack.Render(ABuffer: PSmallInt; ABytes: Integer; AVolume: Single);
var
  LFrames: Integer;
  LIndex: Integer;
  LSum: Integer;
begin
  if (ABytes <= 0) or ((ABytes and 3) <> 0) then
    raise EXcomAudioException.Create(SXcomBufferNotWhole);
  if not FActive then
    Exit;
  LFrames := ABytes div 4;
  if Length(FFrames) < LFrames * 2 then
    SetLength(FFrames, LFrames * 2);
  FPlayer.Render(FFrames, LFrames);
  for LIndex := 0 to LFrames * 2 - 1 do
  begin
    LSum := Integer(ABuffer^) + Trunc(FFrames[LIndex] * AVolume);
    if LSum > 32767 then
      LSum := 32767
    else if LSum < -32768 then
      LSum := -32768;
    ABuffer^ := SmallInt(LSum);
    Inc(ABuffer);
  end;
  if FPlayer.Finished then
  begin
    Dec(FRemaining);
    if FRemaining > 0 then
      StartPlayer
    else
      FActive := False;
  end;
end;

end.
