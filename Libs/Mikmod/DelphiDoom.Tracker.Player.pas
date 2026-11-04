{******************************************************************************}
{                                                                              }
{  DelphiDoom: tracker - plays a module: rows, ticks, notes and song flow      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tracker.Player;

interface

uses
  System.Generics.Collections,
  DelphiDoom.Tracker.Mixer,
  DelphiDoom.Tracker.Types;

type
  /// <summary>
  ///   The sequencer: it reads the rows of the patterns tick by tick, starts
  ///   the notes on the voices of a mixer and follows the flow of the song
  ///   (speed, tempo, position jump and pattern break)
  /// </summary>
  /// <remarks>
  ///   The effects that change a note while it plays (slides, vibrato,
  ///   arpeggio, envelopes) are not done yet
  /// </remarks>
  TTrackerPlayer = class
  private
    type
      TChannelState = class
      public
        Instrument: TTrackerInstrument;
        Sample: TTrackerSample;
        /// <summary>0..64</summary>
        Volume: Integer;
        /// <summary>0 (left) to 255 (right); 127.5 is the middle</summary>
        Panning: Double;
      end;
  private
    FModule: TTrackerModule;
    FMixer: TTrackerMixer;
    FChannels: TObjectList<TChannelState>;
    FVisited: TDictionary<Integer, Boolean>;
    FLooping: Boolean;
    FFinished: Boolean;
    FOrderIndex: Integer;
    FRow: Integer;
    FTick: Integer;
    FSpeed: Integer;
    FTempo: Integer;
    FTickStarted: Boolean;
    FSamplesLeft: Integer;
    FPendingOrder: Integer;
    FPendingRow: Integer;
    function CurrentPattern: TTrackerPattern;
    function TickLength: Integer;
    function NormalizeOrder(var AOrder: Integer): Boolean;
    procedure ProcessRow;
    procedure TriggerCell(const AChannel: Integer; const ACell: TTrackerCell);
    procedure ApplyFlowEffect(const ACell: TTrackerCell);
    procedure ApplyVolumeColumn(const AState: TChannelState; const ACell: TTrackerCell);
    procedure UpdateVoice(const AChannel: Integer);
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
    property Finished: Boolean read FFinished;
    property Looping: Boolean read FLooping write FLooping;
    property OrderIndex: Integer read FOrderIndex;
    property Row: Integer read FRow;
    property Speed: Integer read FSpeed;
    property Tempo: Integer read FTempo;
  end;

implementation

uses
  System.Math,
  System.SysUtils,
  DelphiDoom.Tracker.Voice;

const
  ORDER_SKIP = 254;
  ORDER_END = 255;
  MAX_VOLUME = 64;
  CENTER_PANNING = 127.5;
  // Effects of MOD and XM
  EFFECT_JUMP = $0B;
  EFFECT_SET_VOLUME = $0C;
  EFFECT_BREAK = $0D;
  EFFECT_SPEED_TEMPO = $0F;
  // Effects of S3M and IT (the letter, A = 1)
  EFFECT_LETTER_SPEED = 1;
  EFFECT_LETTER_JUMP = 2;
  EFFECT_LETTER_BREAK = 3;
  EFFECT_LETTER_TEMPO = 20;
  MIN_TEMPO = 32;
  NOT_SET = -1;

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
  FChannels := TObjectList<TChannelState>.Create(True);
  FVisited := TDictionary<Integer, Boolean>.Create;
  for LIndex := 0 to AModule.Channels - 1 do
    FChannels.Add(TChannelState.Create);

  FSpeed := Max(1, AModule.InitialSpeed);
  FTempo := Max(MIN_TEMPO, AModule.InitialTempo);
  FPendingOrder := NOT_SET;
  FPendingRow := NOT_SET;

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

function TTrackerPlayer.CurrentPattern: TTrackerPattern;
begin
  Result := FModule.Patterns[FModule.Orders[FOrderIndex]];
end;

function TTrackerPlayer.TickLength: Integer;
begin
  // A tick lasts 2.5 / tempo seconds
  Result := Max(1, Integer(Round(FMixer.SampleRate * 2.5 / FTempo)));
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
    if FLooping then
    begin
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
    end
    else
      FinishSong;
    Exit;
  end;

  FOrderIndex := LOrder;
  FRow := ARow;
  if FRow >= CurrentPattern.Rows then
    FRow := 0;
end;

procedure TTrackerPlayer.UpdateVoice(const AChannel: Integer);
var
  LState: TChannelState;
  LVoice: TTrackerVoice;
begin
  LState := FChannels[AChannel];
  LVoice := FMixer.Voices[AChannel];
  LVoice.Volume := LState.Volume / MAX_VOLUME * FModule.GlobalVolume / 128;
  LVoice.Panning := LState.Panning / 255;
end;

procedure TTrackerPlayer.ApplyVolumeColumn(const AState: TChannelState; const ACell: TTrackerCell);
begin
  if ACell.Volume < 0 then
    Exit;
  case FModule.Format of
    tfS3m, tfIt:
      if ACell.Volume <= MAX_VOLUME then
        AState.Volume := ACell.Volume;
    tfXm:
      // $10..$50 sets the volume 0..64
      if (ACell.Volume >= $10) and (ACell.Volume <= $50) then
        AState.Volume := ACell.Volume - $10;
  end;
end;

procedure TTrackerPlayer.TriggerCell(const AChannel: Integer; const ACell: TTrackerCell);
var
  LState: TChannelState;
  LVoice: TTrackerVoice;
  LSampleIndex, LPlayedNote: Integer;
  LFrequency: Double;
begin
  LState := FChannels[AChannel];
  LVoice := FMixer.Voices[AChannel];

  if (ACell.Instrument > 0) and (ACell.Instrument <= FModule.Instruments.Count) then
    LState.Instrument := FModule.Instruments[ACell.Instrument - 1];

  if (ACell.Note >= TRACKER_NOTE_FIRST) and (ACell.Note <= TRACKER_NOTE_LAST) then
  begin
    if Assigned(LState.Instrument) then
    begin
      LSampleIndex := LState.Instrument.SampleMap[ACell.Note - 1];
      LPlayedNote := LState.Instrument.NoteMap[ACell.Note - 1];
      if LSampleIndex < LState.Instrument.Samples.Count then
      begin
        LState.Sample := LState.Instrument.Samples[LSampleIndex];
        LFrequency := LState.Sample.CenterFrequency *
          Power(2, (LPlayedNote - TRACKER_CENTER_NOTE) / 12);
        LVoice.Increment := LFrequency / FMixer.SampleRate;
        LState.Volume := LState.Sample.Volume;
        if LState.Sample.Panning >= 0 then
          LState.Panning := LState.Sample.Panning
        else if (AChannel < Length(FModule.ChannelPanning)) and
          (FModule.ChannelPanning[AChannel] >= 0) then
          LState.Panning := FModule.ChannelPanning[AChannel]
        else
          LState.Panning := CENTER_PANNING;
        LVoice.Start(LState.Sample);
      end;
    end;
  end
  else if (ACell.Note = TRACKER_NOTE_OFF) or (ACell.Note = TRACKER_NOTE_CUT) then
    LVoice.Stop
  else if (ACell.Instrument > 0) and Assigned(LState.Sample) then
    // An instrument without a note sets its volume again
    LState.Volume := LState.Sample.Volume;

  ApplyVolumeColumn(LState, ACell);
  if (FModule.Format in [tfMod, tfXm]) and (ACell.Effect = EFFECT_SET_VOLUME) then
    LState.Volume := Min(ACell.Param, MAX_VOLUME);

  UpdateVoice(AChannel);
end;

procedure TTrackerPlayer.ApplyFlowEffect(const ACell: TTrackerCell);
var
  LRow: Integer;
begin
  case FModule.Format of
    tfMod, tfXm:
      case ACell.Effect of
        EFFECT_JUMP:
          FPendingOrder := ACell.Param;
        EFFECT_BREAK:
          FPendingRow := (ACell.Param shr 4) * 10 + (ACell.Param and $0F);
        EFFECT_SPEED_TEMPO:
          if ACell.Param = 0 then
            Exit
          else if ACell.Param < MIN_TEMPO then
            FSpeed := ACell.Param
          else
            FTempo := ACell.Param;
      end;
    tfS3m, tfIt:
      case ACell.Effect of
        EFFECT_LETTER_SPEED:
          if ACell.Param > 0 then
            FSpeed := ACell.Param;
        EFFECT_LETTER_TEMPO:
          if ACell.Param >= MIN_TEMPO then
            FTempo := ACell.Param;
        EFFECT_LETTER_JUMP:
          FPendingOrder := ACell.Param;
        EFFECT_LETTER_BREAK:
          begin
            // S3M writes the row in decimal digits; IT in binary
            if FModule.Format = tfS3m then
              LRow := (ACell.Param shr 4) * 10 + (ACell.Param and $0F)
            else
              LRow := ACell.Param;
            FPendingRow := LRow;
          end;
      end;
  end;
end;

procedure TTrackerPlayer.ProcessRow;
var
  LChannel, LKey: Integer;
  LPattern: TTrackerPattern;
  LCell: TTrackerCell;
begin
  LKey := FOrderIndex * 512 + FRow;
  if FVisited.ContainsKey(LKey) and not FLooping then
  begin
    // A row that is played twice: the song would never end
    FinishSong;
    Exit;
  end;
  FVisited.AddOrSetValue(LKey, True);

  LPattern := CurrentPattern;
  for LChannel := 0 to Min(FModule.Channels, LPattern.Channels) - 1 do
  begin
    LCell := LPattern.Cells[FRow, LChannel];
    TriggerCell(LChannel, LCell);
    ApplyFlowEffect(LCell);
  end;
end;

procedure TTrackerPlayer.AdvanceRow;
begin
  if FPendingOrder <> NOT_SET then
    GoToOrder(FPendingOrder, Max(0, FPendingRow))
  else if FPendingRow <> NOT_SET then
    GoToOrder(FOrderIndex + 1, FPendingRow)
  else if FRow + 1 >= CurrentPattern.Rows then
    GoToOrder(FOrderIndex + 1, 0)
  else
    Inc(FRow);
  FPendingOrder := NOT_SET;
  FPendingRow := NOT_SET;
end;

procedure TTrackerPlayer.EndTick;
begin
  Inc(FTick);
  if FTick >= FSpeed then
  begin
    FTick := 0;
    AdvanceRow;
  end;
end;

procedure TTrackerPlayer.Render(const AOutput: TArray<SmallInt>; const AFrames: Integer);
var
  LDone, LChunk: Integer;
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
        ProcessRow;
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
