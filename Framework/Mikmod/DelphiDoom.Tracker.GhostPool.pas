{******************************************************************************}
{                                                                              }
{  DelphiDoom: tracker - the voices of the notes that go on in the background  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tracker.GhostPool;

interface

uses
  DelphiDoom.Tracker.Ghost,
  DelphiDoom.Tracker.Mixer,
  DelphiDoom.Tracker.NoteEnvelopes,
  DelphiDoom.Tracker.Types,
  DelphiDoom.Tracker.Voice;

type
  /// <summary>What a duplicate of a note has to be tested on (the check of IT)</summary>
  TTrackerDuplicateCheck = (dcOff, dcNote, dcSample, dcInstrument);

  /// <summary>What happens to the note that is a duplicate</summary>
  TTrackerDuplicateAction = (daCut, daOff, daFade);

  /// <summary>
  ///   The ghosts of a module: the voices of the mixer from a given one on.
  ///   When all are in use the oldest ghost is cut to make room
  /// </summary>
  TTrackerGhostPool = class
  private
    FMixer: TTrackerMixer;
    FFirstVoice: Integer;
    FSlots: TArray<TTrackerGhost>;
    FGlobalVolume: Double;
    function FindFreeSlot: Integer;
    function GetCount: Integer;
  public
    /// <param name="AMixer">The mixer; the voices from AFirstVoice on belong to the pool</param>
    constructor Create(const AMixer: TTrackerMixer; const AFirstVoice: Integer);
    destructor Destroy; override;

    /// <summary>
    ///   Moves a note to a voice of the pool: the sound of AVoice goes on
    ///   from where it is. The pool takes the envelopes
    /// </summary>
    /// <returns>The ghost; nil when the pool has no voice at all (the envelopes stay with the caller)</returns>
    function Capture(const AVoice: TTrackerVoice; const AEnvelopes: TTrackerNoteEnvelopes;
      const AChannelIndex, ANote: Integer; const AInstrument: TTrackerInstrument;
      const ASample: TTrackerSample; const ABaseVolume, AFrequency, APanning: Double): TTrackerGhost;

    /// <summary>One tick for every ghost; the ones that have ended leave their voices</summary>
    procedure ProcessTick;

    /// <summary>
    ///   The check of the duplicates of IT: the ghosts of the channel that are
    ///   equal to the new note (as ADuplicateCheck says) get ADuplicateAction
    /// </summary>
    procedure ApplyDuplicateCheck(const AChannelIndex: Integer;
      const ADuplicateCheck: TTrackerDuplicateCheck; const ADuplicateAction: TTrackerDuplicateAction;
      const ANote: Integer; const ASample: TTrackerSample; const AInstrument: TTrackerInstrument);

    /// <summary>Ends every ghost</summary>
    procedure Clear;

    /// <summary>Whether the note 1 is equal to the note 2, in the way of ADuplicateCheck</summary>
    class function IsDuplicate(const ADuplicateCheck: TTrackerDuplicateCheck; const ANote1: Integer;
      const ASample1: TTrackerSample; const AInstrument1: TTrackerInstrument; const ANote2: Integer;
      const ASample2: TTrackerSample; const AInstrument2: TTrackerInstrument): Boolean; static;

    /// <summary>Scale 0..1 of the global volume of the module</summary>
    property GlobalVolume: Double read FGlobalVolume write FGlobalVolume;
    /// <summary>The number of ghosts that sound</summary>
    property Count: Integer read GetCount;
  end;

implementation

uses
  System.SysUtils;

{ TTrackerGhostPool }

constructor TTrackerGhostPool.Create(const AMixer: TTrackerMixer; const AFirstVoice: Integer);
begin
  inherited Create;
  FMixer := AMixer;
  FFirstVoice := AFirstVoice;
  FGlobalVolume := 1;
  SetLength(FSlots, AMixer.VoiceCount - AFirstVoice);
end;

destructor TTrackerGhostPool.Destroy;
begin
  Clear;
  inherited Destroy;
end;

function TTrackerGhostPool.GetCount: Integer;
var
  LSlot: Integer;
begin
  Result := 0;
  for LSlot := 0 to High(FSlots) do
  begin
    if Assigned(FSlots[LSlot]) then
      Inc(Result);
  end;
end;

function TTrackerGhostPool.FindFreeSlot: Integer;
var
  LSlot: Integer;
begin
  for LSlot := 0 to High(FSlots) do
  begin
    if not Assigned(FSlots[LSlot]) then
      Exit(LSlot);
  end;
  Result := -1;
end;

function TTrackerGhostPool.Capture(const AVoice: TTrackerVoice; const AEnvelopes: TTrackerNoteEnvelopes;
  const AChannelIndex, ANote: Integer; const AInstrument: TTrackerInstrument;
  const ASample: TTrackerSample; const ABaseVolume, AFrequency, APanning: Double): TTrackerGhost;
var
  LSlot: Integer;
begin
  Result := nil;
  if Length(FSlots) = 0 then
    Exit;

  LSlot := FindFreeSlot;
  if LSlot < 0 then
  begin
    // Every voice is in use: the first one is taken
    LSlot := 0;
    FSlots[LSlot].Cut;
    FreeAndNil(FSlots[LSlot]);
  end;

  FMixer.Voices[FFirstVoice + LSlot].CopyFrom(AVoice);
  Result := TTrackerGhost.Create(FMixer.Voices[FFirstVoice + LSlot], AEnvelopes, AChannelIndex, ANote,
    AInstrument, ASample, ABaseVolume, AFrequency, APanning);
  FSlots[LSlot] := Result;
end;

procedure TTrackerGhostPool.ProcessTick;
var
  LSlot: Integer;
begin
  for LSlot := 0 to High(FSlots) do
  begin
    if not Assigned(FSlots[LSlot]) then
      Continue;
    FSlots[LSlot].Update(FMixer.SampleRate, FGlobalVolume);
    if FSlots[LSlot].Dead then
      FreeAndNil(FSlots[LSlot]);
  end;
end;

class function TTrackerGhostPool.IsDuplicate(const ADuplicateCheck: TTrackerDuplicateCheck;
  const ANote1: Integer; const ASample1: TTrackerSample; const AInstrument1: TTrackerInstrument;
  const ANote2: Integer; const ASample2: TTrackerSample;
  const AInstrument2: TTrackerInstrument): Boolean;
begin
  case ADuplicateCheck of
    dcNote:
      Result := (ANote1 = ANote2) and (AInstrument1 = AInstrument2);
    dcSample:
      Result := ASample1 = ASample2;
    dcInstrument:
      Result := AInstrument1 = AInstrument2;
  else
    Result := False;
  end;
end;

procedure TTrackerGhostPool.ApplyDuplicateCheck(const AChannelIndex: Integer;
  const ADuplicateCheck: TTrackerDuplicateCheck; const ADuplicateAction: TTrackerDuplicateAction;
  const ANote: Integer; const ASample: TTrackerSample; const AInstrument: TTrackerInstrument);
var
  LSlot: Integer;
  LGhost: TTrackerGhost;
begin
  if ADuplicateCheck = dcOff then
    Exit;
  for LSlot := 0 to High(FSlots) do
  begin
    LGhost := FSlots[LSlot];
    if not Assigned(LGhost) or (LGhost.ChannelIndex <> AChannelIndex) then
      Continue;
    if not IsDuplicate(ADuplicateCheck, LGhost.Note, LGhost.Sample, LGhost.Instrument, ANote, ASample,
      AInstrument) then
      Continue;
    case ADuplicateAction of
      daCut:
        LGhost.Cut;
      daOff:
        LGhost.Envelopes.KeyOff;
      daFade:
        LGhost.Envelopes.StartFade;
    end;
  end;
end;

procedure TTrackerGhostPool.Clear;
var
  LSlot: Integer;
begin
  for LSlot := 0 to High(FSlots) do
  begin
    if Assigned(FSlots[LSlot]) then
    begin
      FSlots[LSlot].Cut;
      FreeAndNil(FSlots[LSlot]);
    end;
  end;
end;

end.
