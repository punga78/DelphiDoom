{******************************************************************************}
{                                                                              }
{  DelphiDoom: tracker - the model of a module (MOD, S3M, XM, IT)              }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tracker.Types;

interface

uses
  System.Generics.Collections,
  System.SysUtils;

const
  /// <summary>Notes are numbered from C-0 = 1, so C-4 is 49</summary>
  TRACKER_NOTE_NONE = 0;
  TRACKER_NOTE_FIRST = 1;
  TRACKER_NOTE_LAST = 120;
  /// <summary>Key off (XM, IT) and note cut (S3M, IT)</summary>
  TRACKER_NOTE_OFF = 254;
  TRACKER_NOTE_CUT = 255;

  /// <summary>
  ///   The note that a sample plays at its CenterFrequency: C-4, as the
  ///   relative note zero of a FastTracker 2 sample
  /// </summary>
  TRACKER_CENTER_NOTE = 49;

  /// <summary>Frequency of the Amiga C-2 sample (period 428), also the default of XM</summary>
  TRACKER_DEFAULT_CENTER_FREQUENCY = 8363;

  TRACKER_MAX_CHANNELS = 64;
  TRACKER_NO_PANNING = -1;

type
  TTrackerFormat = (tfMod, tfS3m, tfXm, tfIt);

  TTrackerLoopType = (tlNone, tlForward, tlPingPong);

  /// <summary>Raised when a module is bad, truncated or of an unknown format</summary>
  ETrackerException = class(Exception);

  /// <summary>One position of a pattern: a note, an instrument, a volume and an effect</summary>
  TTrackerCell = record
    /// <summary>0 for none, 1..120, TRACKER_NOTE_OFF or TRACKER_NOTE_CUT</summary>
    Note: Byte;
    /// <summary>1 based; 0 for none</summary>
    Instrument: Byte;
    /// <summary>
    ///   The volume column: -1 for none, otherwise the code of the format
    ///   (S3M: the volume 0..64; XM: $10..$FF; IT: 0..212)
    /// </summary>
    Volume: SmallInt;
    /// <summary>
    ///   The effect, as the code of the format (the letter number of
    ///   S3M and IT: A = 1; the number of MOD and XM)
    /// </summary>
    Effect: Byte;
    Param: Byte;
  end;

  /// <summary>A point of an envelope</summary>
  TTrackerEnvelopePoint = record
    Tick: Word;
    Value: Byte;
  end;

  /// <summary>Volume or panning envelope of an XM or IT instrument</summary>
  TTrackerEnvelope = record
    Enabled: Boolean;
    Loop: Boolean;
    Sustain: Boolean;
    LoopStart: Byte;
    LoopEnd: Byte;
    SustainStart: Byte;
    SustainEnd: Byte;
    Points: TArray<TTrackerEnvelopePoint>;
  end;

  /// <summary>
  ///   A sample, always held as 16 bit signed mono, whatever it was in the file
  /// </summary>
  TTrackerSample = class
  public
    Name: string;
    Data: TArray<SmallInt>;
    LoopType: TTrackerLoopType;
    /// <summary>In samples</summary>
    LoopStart: Integer;
    /// <summary>In samples, exclusive</summary>
    LoopEnd: Integer;
    /// <summary>0..64</summary>
    Volume: Byte;
    /// <summary>Frequency, in Hz, at which the note TRACKER_CENTER_NOTE is played</summary>
    CenterFrequency: Integer;
    /// <summary>-1 for none, otherwise 0 (left) to 255 (right)</summary>
    Panning: SmallInt;
    constructor Create;
    function Length: Integer;
  end;

  /// <summary>What an IT instrument does to the note that is playing when a new one starts</summary>
  TTrackerNewNoteAction = (nnaCut, nnaContinue, nnaOff, nnaFade);

  /// <summary>
  ///   An instrument: the samples it uses and, for XM and IT, the envelopes.
  ///   In MOD and S3M an instrument is a sample
  /// </summary>
  /// <remarks>
  ///   The samples belong to the module, because in IT several instruments
  ///   can use the same sample
  /// </remarks>
  TTrackerInstrument = class
  public
    Name: string;
    Samples: TList<TTrackerSample>;
    /// <summary>For each note (0..119), the index in Samples</summary>
    SampleMap: array[0..119] of Byte;
    /// <summary>For each note (0..119), the note that is played (IT; the note + 1 elsewhere)</summary>
    NoteMap: array[0..119] of Byte;
    VolumeEnvelope: TTrackerEnvelope;
    PanningEnvelope: TTrackerEnvelope;
    PitchEnvelope: TTrackerEnvelope;
    FadeOut: Word;
    /// <summary>0..128</summary>
    GlobalVolume: Byte;
    /// <summary>-1 for none, otherwise 0..255</summary>
    DefaultPanning: SmallInt;
    NewNoteAction: TTrackerNewNoteAction;
    /// <summary>IT: 0 off, 1 note, 2 sample, 3 instrument</summary>
    DuplicateCheckType: Byte;
    /// <summary>IT: 0 cut, 1 off, 2 fade</summary>
    DuplicateCheckAction: Byte;
    /// <summary>IT: panning change per note away from PitchPanCenter, -32..32</summary>
    PitchPanSeparation: ShortInt;
    PitchPanCenter: Byte;
    constructor Create;
    destructor Destroy; override;
  end;

  /// <summary>The rows of a pattern, with one cell per channel in each</summary>
  TTrackerPattern = class
  private
    FRows: Integer;
    FChannels: Integer;
    FCells: TArray<TTrackerCell>;
    function GetCell(const ARow, AChannel: Integer): TTrackerCell;
    procedure SetCell(const ARow, AChannel: Integer; const AValue: TTrackerCell);
  public
    constructor Create(const ARows, AChannels: Integer);
    property Rows: Integer read FRows;
    property Channels: Integer read FChannels;
    property Cells[const ARow, AChannel: Integer]: TTrackerCell read GetCell write SetCell;
  end;

  TTrackerModule = class
  public
    Title: string;
    Format: TTrackerFormat;
    Channels: Integer;
    /// <summary>Ticks per row at the start</summary>
    InitialSpeed: Integer;
    /// <summary>Beats per minute at the start</summary>
    InitialTempo: Integer;
    /// <summary>0..128</summary>
    GlobalVolume: Integer;
    /// <summary>Order of the patterns; 254 and 255 mark a gap and the end in S3M and IT</summary>
    Orders: TArray<Byte>;
    RestartPosition: Integer;
    Patterns: TObjectList<TTrackerPattern>;
    /// <summary>All the samples of the module; the instruments refer to them</summary>
    Samples: TObjectList<TTrackerSample>;
    Instruments: TObjectList<TTrackerInstrument>;
    /// <summary>XM and IT: the slides are linear in frequency (otherwise as the Amiga)</summary>
    LinearSlides: Boolean;
    /// <summary>Panning of each channel, -1 for none</summary>
    ChannelPanning: TArray<SmallInt>;
    constructor Create;
    destructor Destroy; override;
  end;

implementation

{ TTrackerSample }

constructor TTrackerSample.Create;
begin
  inherited Create;
  Volume := 64;
  CenterFrequency := TRACKER_DEFAULT_CENTER_FREQUENCY;
  Panning := TRACKER_NO_PANNING;
end;

function TTrackerSample.Length: Integer;
begin
  Result := System.Length(Data);
end;

{ TTrackerInstrument }

constructor TTrackerInstrument.Create;
var
  LNote: Integer;
begin
  inherited Create;
  Samples := TList<TTrackerSample>.Create;
  GlobalVolume := 128;
  DefaultPanning := TRACKER_NO_PANNING;
  for LNote := 0 to 119 do
    NoteMap[LNote] := LNote + 1;
end;

destructor TTrackerInstrument.Destroy;
begin
  Samples.Free;
  inherited Destroy;
end;

{ TTrackerPattern }

constructor TTrackerPattern.Create(const ARows, AChannels: Integer);
var
  LIndex: Integer;
begin
  inherited Create;
  FRows := ARows;
  FChannels := AChannels;
  SetLength(FCells, ARows * AChannels);
  for LIndex := 0 to High(FCells) do
    FCells[LIndex].Volume := -1;
end;

function TTrackerPattern.GetCell(const ARow, AChannel: Integer): TTrackerCell;
begin
  Result := FCells[ARow * FChannels + AChannel];
end;

procedure TTrackerPattern.SetCell(const ARow, AChannel: Integer; const AValue: TTrackerCell);
begin
  FCells[ARow * FChannels + AChannel] := AValue;
end;

{ TTrackerModule }

constructor TTrackerModule.Create;
begin
  inherited Create;
  Patterns := TObjectList<TTrackerPattern>.Create(True);
  Samples := TObjectList<TTrackerSample>.Create(True);
  Instruments := TObjectList<TTrackerInstrument>.Create(True);
  InitialSpeed := 6;
  InitialTempo := 125;
  GlobalVolume := 128;
end;

destructor TTrackerModule.Destroy;
begin
  Instruments.Free;
  Samples.Free;
  Patterns.Free;
  inherited Destroy;
end;

end.
