{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - builders and fakes of the audio      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.AudioSupport;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DelphiDoom.War.Types, DelphiDoom.War.Intf,
  DelphiDoom.War.Audio.Intf;

type
  /// <summary>
  ///   The inputs of the synthetic cases of audio.synth.golden.txt: buildVoc and buildWav of
  ///   Tools\Verifica\198\war_audio_ref.c, byte for byte. The kind, a, b, c and len are in the golden line
  /// </summary>
  TWarSyntheticAudio = class
  public
    class function Voc(AKind: Integer; AA, AB, AC, ALen: Cardinal): TBytes; static;
    class function Wav(AKind: Integer; AA, AB, AC, ALen: Cardinal): TBytes; static;
  end;

  /// <summary>CRC-32 as the golden files print it: 8 lower case hex digits</summary>
  TWarAudioHash = class
  public
    class function Of_(const ABytes: TBytes; ALength: Integer): string; static;
    class function OfBuffer(const ABuffer; ALength: Integer): string; static;
  end;

  /// <summary>
  ///   What a MIDI file contains, whatever the way it is written (the same as midiSummary of the harness): the
  ///   channel events that are not a Note Off as a sorted multiset (CRC-32), the number of Note On and Note Off,
  ///   and the microseconds of the last Note On with the tempo map of the file
  /// </summary>
  TWarMidiSummary = record
    NoteOn: Integer;
    NoteOff: Integer;
    Other: Integer;
    EventsCrc: string;
    LastNoteOnMicroseconds: Double;
    class function Of_(const AMidi: TBytes): TWarMidiSummary; static;
  end;

  /// <summary>An archive in memory: record index to bytes</summary>
  TWarFakeArchive = class(TInterfacedObject, IWarArchive)
  strict private
    FRecords: TDictionary<Integer, TBytes>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Put(AIndex: Integer; const ABytes: TBytes);
    function GetFileType: TWarFileType;
    function GetArchiveId: Cardinal;
    function GetEntryCount: Integer;
    function GetRecordInfo(AIndex: Integer): TWarRecordInfo;
    function IsAvailable(AIndex: Integer): Boolean;
    function ReadRecord(AIndex: Integer): TBytes;
  end;

  /// <summary>A catalog that says what the records of the test are</summary>
  TWarFakeCatalog = class(TInterfacedObject, IWarCatalog)
  strict private
    FTypes: TDictionary<Integer, TWarRecordType>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Put(AIndex: Integer; AType: TWarRecordType);
    function GetCount: Integer;
    function GetEntry(APosition: Integer): TWarCatalogEntry;
    function TryFind(AIndex: Integer; out AEntry: TWarCatalogEntry): Boolean;
    function RecordTypeOf(AIndex: Integer): TWarRecordType;
    function IsSkipped(AIndex: Integer): Boolean;
    function TryGetPredefinedCustomMapIndex(const AName: string; out AIndex: Integer): Boolean;
  end;

  /// <summary>A converter that gives what it was told, and counts</summary>
  TWarFakeMusicConverter = class(TInterfacedObject, IWarMusicConverter)
  public
    Calls: Integer;
    Output: TBytes;
    Succeeds: Boolean;
    constructor Create;
    function TryConvert(const AXmi: TBytes; out AMidi: TBytes): Boolean;
  end;

implementation

uses
  System.Generics.Defaults, DelphiDoom.MathCore.Crc32;

{ TWarSyntheticAudio }

procedure Put16(var ABytes: TBytes; var APosition: Integer; AValue: Cardinal);
begin
  ABytes[APosition] := Byte(AValue);
  ABytes[APosition + 1] := Byte(AValue shr 8);
  Inc(APosition, 2);
end;

procedure Put24(var ABytes: TBytes; var APosition: Integer; AValue: Cardinal);
begin
  Put16(ABytes, APosition, AValue);
  ABytes[APosition] := Byte(AValue shr 16);
  Inc(APosition);
end;

procedure Put32(var ABytes: TBytes; var APosition: Integer; AValue: Cardinal);
begin
  Put16(ABytes, APosition, AValue);
  Put16(ABytes, APosition, AValue shr 16);
end;

procedure PutByte(var ABytes: TBytes; var APosition: Integer; AValue: Cardinal);
begin
  ABytes[APosition] := Byte(AValue);
  Inc(APosition);
end;

procedure PutText(var ABytes: TBytes; var APosition: Integer; const AText: AnsiString);
var
  LIndex: Integer;
begin
  for LIndex := 1 to Length(AText) do
    PutByte(ABytes, APosition, Ord(AText[LIndex]));
end;

procedure PutData(var ABytes: TBytes; var APosition: Integer; ALength: Cardinal);
var
  LIndex: Cardinal;
begin
  LIndex := 0;
  while LIndex < ALength do
  begin
    PutByte(ABytes, APosition, LIndex * 13 + 7);
    Inc(LIndex);
  end;
end;

class function TWarSyntheticAudio.Voc(AKind: Integer; AA, AB, AC, ALen: Cardinal): TBytes;
var
  LP: Integer;
  LVersion: Cardinal;
begin
  SetLength(Result, 64 + Integer(ALen) * 2 + 64);
  LP := 0;
  PutText(Result, LP, 'Creative Voice File'#$1A);
  Put16(Result, LP, 26);
  LVersion := $010A;
  Put16(Result, LP, LVersion);
  Put16(Result, LP, Word(not LVersion) + $1234);
  case AKind of
    1:
      begin
        PutByte(Result, LP, 1); Put24(Result, LP, ALen + 2); PutByte(Result, LP, AA); PutByte(Result, LP, 0);
        PutData(Result, LP, ALen); PutByte(Result, LP, 0);
      end;
    8:
      begin
        PutByte(Result, LP, 8); Put24(Result, LP, 4); Put16(Result, LP, AA); PutByte(Result, LP, 0);
        PutByte(Result, LP, AB);
        PutByte(Result, LP, 1); Put24(Result, LP, ALen + 2); PutByte(Result, LP, 0); PutByte(Result, LP, 0);
        PutData(Result, LP, ALen); PutByte(Result, LP, 0);
      end;
    9, 16, 17:
      begin
        PutByte(Result, LP, 9); Put24(Result, LP, ALen + 12); Put32(Result, LP, AA); PutByte(Result, LP, AB);
        PutByte(Result, LP, AC);
        case AKind of
          16: Put16(Result, LP, 2);
          17: Put16(Result, LP, 4);
        else
          Put16(Result, LP, 0);
        end;
        Put32(Result, LP, 0); PutData(Result, LP, ALen); PutByte(Result, LP, 0);
      end;
    10:
      begin
        PutByte(Result, LP, 1); Put24(Result, LP, ALen + 2); PutByte(Result, LP, AA); PutByte(Result, LP, 0);
        PutData(Result, LP, ALen);
        PutByte(Result, LP, 6); Put24(Result, LP, 2); PutByte(Result, LP, 1); PutByte(Result, LP, 2);
        PutByte(Result, LP, 1); Put24(Result, LP, ALen div 2 + 2); PutByte(Result, LP, AB); PutByte(Result, LP, 0);
        PutData(Result, LP, ALen div 2); PutByte(Result, LP, 0);
      end;
    11:
      begin
        Result[LP - 1] := Result[LP - 1] xor $55;
        PutByte(Result, LP, 1); Put24(Result, LP, ALen + 2); PutByte(Result, LP, AA); PutByte(Result, LP, 0);
        PutData(Result, LP, ALen); PutByte(Result, LP, 0);
      end;
    12:
      begin
        PutByte(Result, LP, 1); Put24(Result, LP, ALen + 2); PutByte(Result, LP, AA); PutByte(Result, LP, 1);
        PutData(Result, LP, ALen); PutByte(Result, LP, 0);
      end;
    13:
      begin
        PutByte(Result, LP, 1); Put24(Result, LP, ALen + 2 + 50); PutByte(Result, LP, AA); PutByte(Result, LP, 0);
        PutData(Result, LP, ALen);
      end;
    14: PutByte(Result, LP, 0);
    15: LP := 10;
    18:
      begin
        Result[20] := Byte(5000);
        Result[21] := Byte(5000 shr 8);
        PutByte(Result, LP, 0);
      end;
  end;
  SetLength(Result, LP);
end;

class function TWarSyntheticAudio.Wav(AKind: Integer; AA, AB, AC, ALen: Cardinal): TBytes;
var
  LP: Integer;
  LAlign: Cardinal;
  LIndex: Integer;
  LFmtLength: Cardinal;
begin
  SetLength(Result, 128 + Integer(ALen) + 64);
  LP := 0;
  LAlign := (AB div 8) * AC;
  PutText(Result, LP, 'RIFF'); Put32(Result, LP, 36 + ALen);
  PutText(Result, LP, 'WAVE');
  PutText(Result, LP, 'fmt ');
  if AKind = 3 then
    LFmtLength := 18
  else
    LFmtLength := 16;
  Put32(Result, LP, LFmtLength);
  Put16(Result, LP, 1); Put16(Result, LP, AC); Put32(Result, LP, AA); Put32(Result, LP, AA * LAlign);
  Put16(Result, LP, LAlign); Put16(Result, LP, AB);
  if AKind = 3 then
    Put16(Result, LP, 0);
  if AKind = 2 then
  begin
    PutText(Result, LP, 'LIST'); Put32(Result, LP, 6);
    for LIndex := 0 to 5 do
      PutByte(Result, LP, $30 + LIndex);
  end;
  if AKind <> 6 then
  begin
    PutText(Result, LP, 'data');
    if AKind = 5 then
      Put32(Result, LP, ALen + 40)
    else
      Put32(Result, LP, ALen);
  end;
  PutData(Result, LP, ALen);
  if AKind = 4 then
    Result[3] := Ord('X');
  if AKind = 7 then
    LP := 30;
  SetLength(Result, LP);
end;

{ TWarAudioHash }

class function TWarAudioHash.OfBuffer(const ABuffer; ALength: Integer): string;
var
  LCrc: TCrc32;
begin
  LCrc := TCrc32.Create;
  try
    if ALength > 0 then
      LCrc.Update(ABuffer, ALength);
    Result := LowerCase(TCrc32.ToHex(LCrc.Value));
  finally
    LCrc.Free;
  end;
end;

class function TWarAudioHash.Of_(const ABytes: TBytes; ALength: Integer): string;
begin
  if ALength <= 0 then
    Result := OfBuffer(Result, 0)
  else
    Result := OfBuffer(ABytes[0], ALength);
end;

{ TWarMidiSummary }

class function TWarMidiSummary.Of_(const AMidi: TBytes): TWarMidiSummary;
var
  LKeys: TList<Cardinal>;
  LPosition, LEnd, LLength: Integer;
  LDivision, LDelta, LTempo, LRunning, LStatus, LData1, LData2, LKind: Cardinal;
  LTime: Double;
  LType: Byte;
  LArray: TArray<Cardinal>;

  function ReadVar: Cardinal;
  var
    LByte: Byte;
  begin
    Result := 0;
    repeat
      LByte := AMidi[LPosition];
      Inc(LPosition);
      Result := (Result shl 7) or (LByte and $7F);
    until LByte and $80 = 0;
  end;

begin
  Result := Default(TWarMidiSummary);
  LKeys := TList<Cardinal>.Create;
  try
    LDivision := (Cardinal(AMidi[12]) shl 8) or AMidi[13];
    LPosition := 14;
    while LPosition + 8 <= Length(AMidi) do
    begin
      LLength := (Integer(AMidi[LPosition + 4]) shl 24) or (Integer(AMidi[LPosition + 5]) shl 16) or
        (Integer(AMidi[LPosition + 6]) shl 8) or AMidi[LPosition + 7];
      Inc(LPosition, 8);
      LEnd := LPosition + LLength;
      LTempo := 500000;
      LTime := 0;
      LRunning := 0;
      while LPosition < LEnd do
      begin
        LDelta := ReadVar;
        LTime := LTime + Double(LDelta) * LTempo / LDivision;
        LStatus := AMidi[LPosition];
        if LStatus >= $80 then
          Inc(LPosition)
        else
          LStatus := LRunning;
        if LStatus = $FF then
        begin
          LType := AMidi[LPosition];
          Inc(LPosition);
          LLength := Integer(ReadVar);
          if (LType = $51) and (LLength >= 3) then
            LTempo := (Cardinal(AMidi[LPosition]) shl 16) or (Cardinal(AMidi[LPosition + 1]) shl 8) or
              AMidi[LPosition + 2];
          Inc(LPosition, LLength);
          Continue;
        end;
        if (LStatus = $F0) or (LStatus = $F7) then
        begin
          LLength := Integer(ReadVar);
          Inc(LPosition, LLength);
          Continue;
        end;
        LRunning := LStatus;
        LData1 := AMidi[LPosition];
        Inc(LPosition);
        LData2 := 0;
        if ((LStatus and $F0) <> $C0) and ((LStatus and $F0) <> $D0) then
        begin
          LData2 := AMidi[LPosition];
          Inc(LPosition);
        end;
        LKind := LStatus and $F0;
        if (LKind = $80) or ((LKind = $90) and (LData2 = 0)) then
        begin
          Inc(Result.NoteOff);
          Continue;
        end;
        if LKind = $90 then
        begin
          Inc(Result.NoteOn);
          if LTime > Result.LastNoteOnMicroseconds then
            Result.LastNoteOnMicroseconds := LTime;
        end
        else
          Inc(Result.Other);
        LKeys.Add((LStatus shl 16) or (LData1 shl 8) or LData2);
      end;
    end;
    LKeys.Sort;
    LArray := LKeys.ToArray;
    if Length(LArray) > 0 then
      Result.EventsCrc := TWarAudioHash.OfBuffer(LArray[0], Length(LArray) * SizeOf(Cardinal))
    else
      Result.EventsCrc := TWarAudioHash.OfBuffer(Result, 0);
  finally
    LKeys.Free;
  end;
end;

{ TWarFakeArchive }

constructor TWarFakeArchive.Create;
begin
  inherited Create;
  FRecords := TDictionary<Integer, TBytes>.Create;
end;

destructor TWarFakeArchive.Destroy;
begin
  FRecords.Free;
  inherited;
end;

procedure TWarFakeArchive.Put(AIndex: Integer; const ABytes: TBytes);
begin
  FRecords.AddOrSetValue(AIndex, ABytes);
end;

function TWarFakeArchive.GetFileType: TWarFileType;
begin
  Result := wftRetail;
end;

function TWarFakeArchive.GetArchiveId: Cardinal;
begin
  Result := WAR_ARCHIVE_ID_RETAIL_DOS;
end;

function TWarFakeArchive.GetEntryCount: Integer;
begin
  Result := 600;
end;

function TWarFakeArchive.GetRecordInfo(AIndex: Integer): TWarRecordInfo;
begin
  Result := Default(TWarRecordInfo);
  Result.Index := AIndex;
end;

function TWarFakeArchive.IsAvailable(AIndex: Integer): Boolean;
begin
  Result := FRecords.ContainsKey(AIndex);
end;

function TWarFakeArchive.ReadRecord(AIndex: Integer): TBytes;
begin
  if not FRecords.TryGetValue(AIndex, Result) then
    raise EWarException.CreateFmt(SWarRecordNotAvailable, [AIndex, 'fake']);
end;

{ TWarFakeCatalog }

constructor TWarFakeCatalog.Create;
begin
  inherited Create;
  FTypes := TDictionary<Integer, TWarRecordType>.Create;
end;

destructor TWarFakeCatalog.Destroy;
begin
  FTypes.Free;
  inherited;
end;

procedure TWarFakeCatalog.Put(AIndex: Integer; AType: TWarRecordType);
begin
  FTypes.AddOrSetValue(AIndex, AType);
end;

function TWarFakeCatalog.GetCount: Integer;
begin
  Result := FTypes.Count;
end;

function TWarFakeCatalog.GetEntry(APosition: Integer): TWarCatalogEntry;
begin
  Result := Default(TWarCatalogEntry);
end;

function TWarFakeCatalog.TryFind(AIndex: Integer; out AEntry: TWarCatalogEntry): Boolean;
begin
  AEntry := Default(TWarCatalogEntry);
  Result := FTypes.ContainsKey(AIndex);
end;

function TWarFakeCatalog.RecordTypeOf(AIndex: Integer): TWarRecordType;
begin
  if not FTypes.TryGetValue(AIndex, Result) then
    Result := wrtUnknown;
end;

function TWarFakeCatalog.IsSkipped(AIndex: Integer): Boolean;
begin
  Result := False;
end;

function TWarFakeCatalog.TryGetPredefinedCustomMapIndex(const AName: string; out AIndex: Integer): Boolean;
begin
  AIndex := 0;
  Result := False;
end;

{ TWarFakeMusicConverter }

constructor TWarFakeMusicConverter.Create;
begin
  inherited Create;
  Succeeds := True;
end;

function TWarFakeMusicConverter.TryConvert(const AXmi: TBytes; out AMidi: TBytes): Boolean;
begin
  Inc(Calls);
  AMidi := Output;
  Result := Succeeds;
end;

end.
