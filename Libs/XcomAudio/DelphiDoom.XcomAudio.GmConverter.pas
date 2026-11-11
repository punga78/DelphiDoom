{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom audio library - the songs of GM.CAT as Standard MIDI files  }
{  (GMCatFile::loadMIDI of OpenXcom)                                            }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomAudio.GmConverter;

interface

uses
  System.SysUtils, System.Generics.Collections;

type
  /// <summary>
  ///   Turns an entry of GM.CAT (the music stream of the DOS game: a tempo, subsequences and tracks with a channel
  ///   each) into the bytes of a type 1 MIDI file with 24 ticks per quarter note, as GMCatFile::loadMIDI does:
  ///   the volume of the notes follows the patch, the reverb controller goes to 30 and a controller 0 changes the tempo
  /// </summary>
  TXcomGmConverter = class
  strict private
    type
      TSequence = record
        Start: Integer;
        Size: Integer;
      end;
      TTrack = record
        Channel: Integer;
        Sequence: TSequence;
      end;
      TStatus = record
        Delta: Cardinal;
        Patch: Integer;
      end;
    const
      MAX_SUBSEQUENCES = 256;
      NOTE_VOLUME: array[0..127] of Byte = (
        100,100,100,100,100, 90,100,100,100,100,100, 90,100,100,100,100,
        100,100, 85,100,100,100,100,100,100,100,100,100, 90,90, 110, 80,
        100,100,100, 90, 70,100,100,100,100,100,100,100,100,100,100,100,
        100,100, 90,100,100,100,100,100,100,120,100,100,100,120,100,127,
        100,100, 90,100,100,100,100,100,100, 95,100,100,100,100,100,100,
        100,100,100,100,100,100,100,115,100,100,100,100,100,100,100,100,
        100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,
        100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100);
    var
      FData: TBytes;
      FTempo: Integer;
      FSubsequences: array of TSequence;
      FTracks: array of TTrack;
      FMidi: TList<Byte>;
    function ReadLong(AOffset: Integer): Cardinal;
    function ReadStream: Boolean;
    procedure WriteWord(AValue: Cardinal);
    procedure WriteDelta(ADelta: Cardinal);
    procedure WriteTempo(ATempo: Cardinal);
    procedure WriteEnd;
    function WriteSequence(AChannel: Integer; const ASequence: TSequence; var AStatus: TStatus): Boolean;
    function WriteMidi: Boolean;
  public
    /// <summary>
    ///   The MIDI file of the entry (the bytes of CatFile::load without the name); nil when the stream is not valid
    ///   (the C++ then gives a music that does not play)
    /// </summary>
    class function Convert(const AEntry: TBytes): TBytes; static;
  end;

implementation

class function TXcomGmConverter.Convert(const AEntry: TBytes): TBytes;
var
  LConverter: TXcomGmConverter;
begin
  Result := nil;
  LConverter := TXcomGmConverter.Create;
  try
    LConverter.FData := AEntry;
    LConverter.FMidi := TList<Byte>.Create;
    try
      if LConverter.ReadStream and LConverter.WriteMidi then
        Result := LConverter.FMidi.ToArray;
    finally
      LConverter.FMidi.Free;
    end;
  finally
    LConverter.Free;
  end;
end;

function TXcomGmConverter.ReadLong(AOffset: Integer): Cardinal;
begin
  Result := Cardinal(FData[AOffset]) or (Cardinal(FData[AOffset + 1]) shl 8) or (Cardinal(FData[AOffset + 2]) shl 16) or
    (Cardinal(FData[AOffset + 3]) shl 24);
end;

function TXcomGmConverter.ReadStream: Boolean;
var
  LLeft: Int64;
  LPosition: Integer;
  LCount: Integer;
  LIndex: Integer;
  LSize: Cardinal;
begin
  Result := False;
  LLeft := Length(FData);
  LPosition := 0;
  if LLeft < 1 then
    Exit;
  FTempo := FData[LPosition];
  Inc(LPosition);
  Dec(LLeft);
  if LLeft < 1 then
    Exit;
  LCount := FData[LPosition];
  Inc(LPosition);
  Dec(LLeft);
  SetLength(FSubsequences, LCount);
  for LIndex := 0 to LCount - 1 do
  begin
    if LLeft < 4 then
      Exit;
    LSize := ReadLong(LPosition);
    if (LSize < 4) or (Int64(LSize) > LLeft) then
      Exit;
    FSubsequences[LIndex].Start := LPosition + 4;
    FSubsequences[LIndex].Size := Integer(LSize) - 4;
    Dec(LLeft, LSize);
    Inc(LPosition, Integer(LSize));
  end;
  if LLeft < 1 then
    Exit;
  LCount := FData[LPosition];
  Inc(LPosition);
  Dec(LLeft);
  SetLength(FTracks, LCount);
  for LIndex := 0 to LCount - 1 do
  begin
    if LLeft < 5 then
      Exit;
    Dec(LLeft);
    FTracks[LIndex].Channel := FData[LPosition];
    Inc(LPosition);
    LSize := ReadLong(LPosition);
    if (LSize < 4) or (Int64(LSize) > LLeft) then
      Exit;
    FTracks[LIndex].Sequence.Start := LPosition + 4;
    FTracks[LIndex].Sequence.Size := Integer(LSize) - 4;
    Dec(LLeft, LSize);
    Inc(LPosition, Integer(LSize));
  end;
  Result := LLeft = 0;
end;

procedure TXcomGmConverter.WriteWord(AValue: Cardinal);
begin
  FMidi.Add(Byte(AValue shr 8));
  FMidi.Add(Byte(AValue));
end;

procedure TXcomGmConverter.WriteDelta(ADelta: Cardinal);
var
  LParts: array[0..3] of Byte;
  LCount: Integer;
begin
  ADelta := ADelta and ((1 shl 28) - 1);
  LCount := 0;
  repeat
    LParts[LCount] := ADelta and $7F;
    Inc(LCount);
    ADelta := ADelta shr 7;
  until (ADelta = 0) or (LCount > 3);
  while LCount > 1 do
  begin
    Dec(LCount);
    FMidi.Add(LParts[LCount] or $80);
  end;
  FMidi.Add(LParts[0]);
end;

procedure TXcomGmConverter.WriteTempo(ATempo: Cardinal);
begin
  FMidi.Add($FF);
  FMidi.Add($51);
  FMidi.Add(3);
  ATempo := 60000000 div ATempo;
  FMidi.Add(Byte(ATempo shr 16));
  FMidi.Add(Byte(ATempo shr 8));
  FMidi.Add(Byte(ATempo));
end;

procedure TXcomGmConverter.WriteEnd;
begin
  FMidi.Add($FF);
  FMidi.Add($2F);
  FMidi.Add(0);
end;

function TXcomGmConverter.WriteSequence(AChannel: Integer; const ASequence: TSequence; var AStatus: TStatus): Boolean;
var
  LPosition: Integer;
  LLeft: Integer;
  LCommand: Byte;
  LDelta: Cardinal;
  LIndex: Integer;
  LByte: Byte;
  LData1: Byte;
  LData2: Byte;

  function Next: Byte;
  begin
    Result := FData[LPosition];
    Inc(LPosition);
    Dec(LLeft);
  end;

begin
  Result := False;
  LPosition := ASequence.Start;
  LLeft := ASequence.Size;
  LCommand := $FF;
  while LLeft > 0 do
  begin
    // the delta
    LDelta := 0;
    LIndex := 0;
    while True do
    begin
      LByte := Next;
      LDelta := LDelta + (LByte and $7F);
      if (LByte and $80) = 0 then
        Break;
      Inc(LIndex);
      if (LIndex = 4) or (LLeft = 0) then
        Exit;
      LDelta := LDelta shl 7;
    end;
    AStatus.Delta := AStatus.Delta + LDelta;
    if LLeft = 0 then
      Exit;
    if (FData[LPosition] and $80) <> 0 then
    begin
      LCommand := Next;
      case LCommand of
        $FF, $FD:
          Exit(True);
        $FE:
          begin
            if LLeft = 0 then
              Exit;
            if FData[LPosition] >= Length(FSubsequences) then
              Exit;
            LByte := Next;
            if not WriteSequence(AChannel, FSubsequences[LByte], AStatus) then
              Exit;
            LCommand := 0;
            Continue;
          end;
      else
        LCommand := LCommand and $F0;
      end;
    end
    else if LCommand = 0 then
      Exit;
    if LLeft = 0 then
      Exit;
    LData1 := Next;
    case LCommand of
      $80, $90:
        begin
          if LLeft = 0 then
            Exit;
          LData2 := Next;
          if LData2 <> 0 then
          begin
            if AChannel = 9 then
              LData2 := Byte((Cardinal(LData2) * 80) shr 7)
            else
              LData2 := Byte((Cardinal(LData2) * NOTE_VOLUME[AStatus.Patch and $7F]) shr 7);
          end;
          WriteDelta(AStatus.Delta);
          FMidi.Add(Byte(LCommand or AChannel));
          FMidi.Add(LData1);
          FMidi.Add(LData2);
        end;
      $C0:
        begin
          if LData1 = $7E then
            Exit(True);
          AStatus.Patch := LData1;
          if (LData1 = $57) or (LData1 = $3F) then
            LData1 := $3E;
          WriteDelta(AStatus.Delta);
          FMidi.Add(Byte(LCommand or AChannel));
          FMidi.Add(LData1);
        end;
      $B0:
        begin
          if LLeft = 0 then
            Exit;
          LData2 := Next;
          if LData1 = $7E then
            Continue;
          if LData1 = 0 then
          begin
            if LData2 = 0 then
              Continue;
            WriteDelta(AStatus.Delta);
            WriteTempo(2 * Cardinal(LData2));
          end
          else
          begin
            if LData1 = $5B then
              LData2 := $1E;
            WriteDelta(AStatus.Delta);
            FMidi.Add(Byte(LCommand or AChannel));
            FMidi.Add(LData1);
            FMidi.Add(LData2);
          end;
        end;
      $E0:
        begin
          if LLeft = 0 then
            Exit;
          LData2 := Next;
          WriteDelta(AStatus.Delta);
          FMidi.Add(Byte(LCommand or AChannel));
          FMidi.Add(LData1);
          FMidi.Add(LData2);
        end;
    else
      Exit;
    end;
    AStatus.Delta := 0;
  end;
  Result := True;
end;

function TXcomGmConverter.WriteMidi: Boolean;
const
  TRACK_INIT: array[0..7] of Byte = ($78, 0, 0, $79, 0, 0, $7B, 0);
  // MThd, 6; MTrk, 11
  FILE_HEADER: array[0..7] of Byte = ($4D, $54, $68, $64, 0, 0, 0, 6);
  TEMPO_TRACK_HEADER: array[0..7] of Byte = ($4D, $54, $72, $6B, 0, 0, 0, 11);
  TRACK_TAG: array[0..3] of Byte = ($4D, $54, $72, $6B);
var
  LTrack: Integer;
  LIndex: Integer;
  LLengthOffset: Integer;
  LLength: Integer;
  LStatus: TStatus;
begin
  Result := False;
  if FTempo = 0 then
    Exit;
  for LIndex := 0 to 7 do
    FMidi.Add(FILE_HEADER[LIndex]);
  WriteWord(1);
  WriteWord(Length(FTracks) + 1);
  WriteWord(24);
  // the global tempo track
  for LIndex := 0 to 7 do
    FMidi.Add(TEMPO_TRACK_HEADER[LIndex]);
  WriteDelta(0);
  WriteTempo(FTempo);
  WriteDelta(0);
  WriteEnd;
  for LTrack := 0 to High(FTracks) do
  begin
    for LIndex := 0 to 3 do
      FMidi.Add(TRACK_TAG[LIndex]);
    LLengthOffset := FMidi.Count;
    for LIndex := 0 to 3 do
      FMidi.Add(0);
    FMidi.Add(0);
    FMidi.Add(Byte($B0 or FTracks[LTrack].Channel));
    for LIndex := 0 to 7 do
      FMidi.Add(TRACK_INIT[LIndex]);
    LStatus.Delta := 0;
    LStatus.Patch := 0;
    if not WriteSequence(FTracks[LTrack].Channel, FTracks[LTrack].Sequence, LStatus) then
      Exit;
    WriteDelta(LStatus.Delta);
    WriteEnd;
    LLength := FMidi.Count - LLengthOffset - 4;
    FMidi[LLengthOffset] := Byte(LLength shr 24);
    FMidi[LLengthOffset + 1] := Byte(LLength shr 16);
    FMidi[LLengthOffset + 2] := Byte(LLength shr 8);
    FMidi[LLengthOffset + 3] := Byte(LLength);
  end;
  Result := True;
end;

end.
