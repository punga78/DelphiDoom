{******************************************************************************}
{                                                                              }
{  DelphiDoom: tracker - plays a module: rows, ticks and song flow             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tracker.Player;

interface

uses
  System.Generics.Collections,
  DelphiDoom.Tracker.Channel,
  DelphiDoom.Tracker.Mixer,
  DelphiDoom.Tracker.Types;

type
  /// <summary>
  ///   The sequencer: it reads the rows of the patterns tick by tick, gives
  ///   each cell to its channel and follows the flow of the song (speed,
  ///   tempo, global volume, position jump, pattern break, loop and delay of
  ///   the pattern)
  /// </summary>
  /// <remarks>
  ///   Not done yet: the envelopes, the fade out and the new note actions of
  ///   XM and IT, and the waveforms of the vibrato other than the sine
  /// </remarks>
  TTrackerPlayer = class
  private
    FModule: TTrackerModule;
    FMixer: TTrackerMixer;
    FChannels: TObjectList<TTrackerChannel>;
    FVisited: TDictionary<Integer, Boolean>;
    FLooping: Boolean;
    FFinished: Boolean;
    FOrderIndex: Integer;
    FRow: Integer;
    FTick: Integer;
    FSpeed: Integer;
    FTempo: Integer;
    FGlobalVolume: Integer;
    FTickStarted: Boolean;
    FSamplesLeft: Integer;
    FPendingOrder: Integer;
    FPendingRow: Integer;
    FLoopRow: Integer;
    FLoopCount: Integer;
    FLoopJump: Boolean;
    FPatternDelay: Integer;
    function GetChannel(const AIndex: Integer): TTrackerChannel;
    function CurrentPattern: TTrackerPattern;
    function TickLength: Integer;
    function RowTicks: Integer;
    function NormalizeOrder(var AOrder: Integer): Boolean;
    procedure ProcessRow;
    procedure ApplyFlowEffect(const ACell: TTrackerCell);
    procedure SetGlobalVolume(const AValue: Integer);
    procedure EndTick;
    procedure AdvanceRow;
    procedure FinishSong;
    procedure GoToOrder(const AOrder, ARow: Integer);
  public
    /// <param name="AModule">The module to play; it must stay alive</param>
    /// <param name="ASampleRate">Frames per second of the output</param>
    /// <param name="ALooping">At the end the song starts again; otherwise it finishes</param>
    constructor Create(const AModule: TTrackerModule; const ASampleRate: Integer;
      const ALooping: Boolean);
    destructor Destroy; override;

    /// <summary>
    ///   Writes AFrames frames of 16 bit stereo (interleaved) to AOutput; when
    ///   the song has finished it writes silence
    /// </summary>
    procedure Render(const AOutput: TArray<SmallInt>; const AFrames: Integer);

    property Mixer: TTrackerMixer read FMixer;
    property Channels[const AIndex: Integer]: TTrackerChannel read GetChannel;
    property Finished: Boolean read FFinished;
    property Looping: Boolean read FLooping write FLooping;
    property OrderIndex: Integer read FOrderIndex;
    property Row: Integer read FRow;
    property Speed: Integer read FSpeed;
    property Tempo: Integer read FTempo;
    /// <summary>0..128</summary>
    property GlobalVolume: Integer read FGlobalVolume;
  end;

implementation

uses
  System.Math,
  System.SysUtils,
  DelphiDoom.Tracker.Effects;

const
  ORDER_SKIP = 254;
  ORDER_END = 255;
  MAX_GLOBAL_VOLUME = 128;
  MIN_TEMPO = 32;
  NOT_SET = -1;
  ROW_KEY_SIZE = 512;

{ TTrackerPlayer }

constructor TTrackerPlayer.Create(const AModule: TTrackerModule; const ASampleRate: Integer;
  const ALooping: Boolean);
var
  LIndex: Integer;
begin
  inherited Create;
  FModule := AModule;
  FLooping := ALooping;
  FMixer := TTrackerMixer.Create(ASampleRate, AModule.Channels);
  FChannels := TObjectList<TTrackerChannel>.Create(True);
  FVisited := TDictionary<Integer, Boolean>.Create;
  for LIndex := 0 to AModule.Channels - 1 do
    FChannels.Add(TTrackerChannel.Create(AModule, FMixer.Voices[LIndex], ASampleRate, LIndex));

  FSpeed := Max(1, AModule.InitialSpeed);
  FTempo := Max(MIN_TEMPO, AModule.InitialTempo);
  FPendingOrder := NOT_SET;
  FPendingRow := NOT_SET;
  SetGlobalVolume(AModule.GlobalVolume);

  FOrderIndex := 0;
  if not NormalizeOrder(FOrderIndex) then
    FinishSong;
end;

destructor TTrackerPlayer.Destroy;
begin
  FVisited.Free;
  FChannels.Free;
  FMixer.Free;
  inherited Destroy;
end;

function TTrackerPlayer.GetChannel(const AIndex: Integer): TTrackerChannel;
begin
  Result := FChannels[AIndex];
end;

function TTrackerPlayer.CurrentPattern: TTrackerPattern;
begin
  Result := FModule.Patterns[FModule.Orders[FOrderIndex]];
end;

function TTrackerPlayer.TickLength: Integer;
begin
  // A tick lasts 2.5 / tempo seconds
  Result := Max(1, Integer(Round(FMixer.SampleRate * 2.5 / FTempo)));
end;

// The delay of the pattern repeats the row without playing its notes again
function TTrackerPlayer.RowTicks: Integer;
begin
  Result := FSpeed * (1 + FPatternDelay);
end;

procedure TTrackerPlayer.SetGlobalVolume(const AValue: Integer);
var
  LChannel: TTrackerChannel;
begin
  FGlobalVolume := Max(0, Min(MAX_GLOBAL_VOLUME, AValue));
  for LChannel in FChannels do
    LChannel.GlobalVolume := FGlobalVolume / MAX_GLOBAL_VOLUME;
end;

// Moves AOrder to the first order that holds a pattern; False at the end of the song
function TTrackerPlayer.NormalizeOrder(var AOrder: Integer): Boolean;
begin
  while AOrder < Length(FModule.Orders) do
  begin
    if FModule.Orders[AOrder] = ORDER_END then
      Exit(False);
    if (FModule.Orders[AOrder] <> ORDER_SKIP) and
      (FModule.Orders[AOrder] < FModule.Patterns.Count) then
      Exit(True);
    Inc(AOrder);
  end;
  Result := False;
end;

procedure TTrackerPlayer.FinishSong;
var
  LIndex: Integer;
begin
  FFinished := True;
  for LIndex := 0 to FMixer.VoiceCount - 1 do
    FMixer.Voices[LIndex].Stop;
end;

procedure TTrackerPlayer.GoToOrder(const AOrder, ARow: Integer);
var
  LOrder: Integer;
begin
  LOrder := AOrder;
  if not NormalizeOrder(LOrder) then
  begin
    // The end of the song: it starts again or it finishes
    if not FLooping then
    begin
      FinishSong;
      Exit;
    end;
    LOrder := Min(FModule.RestartPosition, Max(0, Length(FModule.Orders) - 1));
    if not NormalizeOrder(LOrder) then
      LOrder := 0;
    if not NormalizeOrder(LOrder) then
    begin
      FinishSong;
      Exit;
    end;
    FVisited.Clear;
    FOrderIndex := LOrder;
    FRow := 0;
    FLoopRow := 0;
    FLoopCount := 0;
    Exit;
  end;

  if LOrder <> FOrderIndex then
  begin
    FLoopRow := 0;
    FLoopCount := 0;
  end;
  FOrderIndex := LOrder;
  FRow := ARow;
  if FRow >= CurrentPattern.Rows then
    FRow := 0;
end;

procedure TTrackerPlayer.ApplyFlowEffect(const ACell: TTrackerCell);
var
  LEffect: TTrackerEffect;
begin
  LEffect := TTrackerEffectMapper.Map(FModule.Format, ACell.Effect, ACell.Param);
  case LEffect.Kind of
    ekPositionJump:
      FPendingOrder := LEffect.Param;
    ekPatternBreak:
      FPendingRow := LEffect.Param;
    ekSetSpeed:
      FSpeed := Max(1, LEffect.Param);
    ekSetTempo:
      FTempo := Max(MIN_TEMPO, LEffect.Param);
    ekSetGlobalVolume:
      // XM and S3M count to 64, IT to 128
      if FModule.Format in [tfXm, tfS3m] then
        SetGlobalVolume(LEffect.Param * 2)
      else
        SetGlobalVolume(LEffect.Param);
    ekPatternLoop:
      if LEffect.Param = 0 then
        FLoopRow := FRow
      else
      begin
        if FLoopCount = 0 then
          FLoopCount := LEffect.Param
        else
          Dec(FLoopCount);
        if FLoopCount > 0 then
          FLoopJump := True;
      end;
    ekPatternDelay:
      if FPatternDelay = 0 then
        FPatternDelay := LEffect.Param;
  end;
end;

procedure TTrackerPlayer.ProcessRow;
var
  LChannel, LKey: Integer;
  LPattern: TTrackerPattern;
  LCell: TTrackerCell;
begin
  LKey := FOrderIndex * ROW_KEY_SIZE + FRow;
  if FVisited.ContainsKey(LKey) and not FLooping then
  begin
    // A row that is played twice: the song would never end
    FinishSong;
    Exit;
  end;
  FVisited.AddOrSetValue(LKey, True);

  LPattern := CurrentPattern;
  FPatternDelay := 0;
  for LChannel := 0 to Min(FModule.Channels, LPattern.Channels) - 1 do
  begin
    LCell := LPattern.Cells[FRow, LChannel];
    FChannels[LChannel].StartRow(LCell);
    ApplyFlowEffect(LCell);
  end;

  // The flow effects can change the global volume
  for LChannel := 0 to FChannels.Count - 1 do
    FChannels[LChannel].UpdateVoice;
end;

procedure TTrackerPlayer.AdvanceRow;
var
  LRow: Integer;
begin
  if FLoopJump then
  begin
    // The rows of the loop will be played again: they are not "seen twice"
    for LRow := FLoopRow to FRow do
      FVisited.Remove(FOrderIndex * ROW_KEY_SIZE + LRow);
    FRow := FLoopRow;
  end
  else if FPendingOrder <> NOT_SET then
    GoToOrder(FPendingOrder, Max(0, FPendingRow))
  else if FPendingRow <> NOT_SET then
    GoToOrder(FOrderIndex + 1, FPendingRow)
  else if FRow + 1 >= CurrentPattern.Rows then
    GoToOrder(FOrderIndex + 1, 0)
  else
    Inc(FRow);
  FLoopJump := False;
  FPendingOrder := NOT_SET;
  FPendingRow := NOT_SET;
end;

procedure TTrackerPlayer.EndTick;
begin
  Inc(FTick);
  if FTick >= RowTicks then
  begin
    FTick := 0;
    AdvanceRow;
  end;
end;

procedure TTrackerPlayer.Render(const AOutput: TArray<SmallInt>; const AFrames: Integer);
var
  LDone, LChunk, LChannel: Integer;
begin
  LDone := 0;
  while LDone < AFrames do
  begin
    if FFinished then
    begin
      FillChar(AOutput[2 * LDone], 2 * (AFrames - LDone) * SizeOf(SmallInt), 0);
      Break;
    end;

    if not FTickStarted then
    begin
      if FTick = 0 then
        ProcessRow
      else
      begin
        for LChannel := 0 to FChannels.Count - 1 do
          FChannels[LChannel].ProcessTick(FTick);
      end;
      if FFinished then
        Continue;
      FSamplesLeft := TickLength;
      FTickStarted := True;
    end;

    LChunk := Min(AFrames - LDone, FSamplesLeft);
    FMixer.Mix(AOutput, LDone, LChunk);
    Inc(LDone, LChunk);
    Dec(FSamplesLeft, LChunk);

    if FSamplesLeft = 0 then
    begin
      FTickStarted := False;
      EndTick;
    end;
  end;
end;

end.
