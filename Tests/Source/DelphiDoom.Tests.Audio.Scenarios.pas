{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the audio library - the scenarios of the golden files  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Audio.Scenarios;

{$Q-}
{$R-}
// The random numbers and the fingerprints wrap around on purpose

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   The inputs of the golden files of Tests\Data\Audio: WAV files and lumps, DMX lumps and MUS
  ///   songs, the same at every call. The harness that ran the old code of i_sound and i_music
  ///   (outside the repository) built its inputs with this unit too
  /// </summary>
  TAudioScenarios = class
  public
    /// <summary>RIFF WAVE buffers as they can be found in a WAD: valid, malformed, odd chunks</summary>
    class function WaveLumps: TArray<TBytes>; static;
    /// <summary>RIFF WAVE files as they can be found out of the WAD</summary>
    class function WaveFiles: TArray<TBytes>; static;
    /// <summary>MUS songs: valid, without the end, with wrong controls, with a long header</summary>
    class function MusSongs: TArray<TBytes>; static;
    /// <summary>The tempo of every song of MusSongs</summary>
    class function MusTempo(AIndex: Integer): Byte; static;
    /// <summary>FNV-1a at 32 bits of a block of memory, in hexadecimal</summary>
    class function Fingerprint(AData: Pointer; ASize: Integer): string; static;
  end;

implementation

const
  RIFF_ID = $46464952;
  WAVE_ID = $45564157;
  FMT_ID = $20746D66;
  DATA_ID = $61746164;
  LIST_ID = $5453494C;
  MUS_ID = $1A53554D;

type
  TScenarioRandom = record
    State: Cardinal;
    function Next: Cardinal;
    function Below(AValue: Integer): Integer;
  end;

  TScenarioBuffer = record
    Bytes: TBytes;
    Size: Integer;
    procedure Clear;
    procedure AddByte(AValue: Byte);
    procedure AddWord(AValue: Word);
    procedure AddLong(AValue: Cardinal);
    procedure AddRandom(var ARandom: TScenarioRandom; ACount: Integer);
    procedure PatchLong(APosition: Integer; AValue: Cardinal);
    function ToBytes: TBytes;
  end;

{ TScenarioRandom }

function TScenarioRandom.Next: Cardinal;
begin
  State := State * 1664525 + 1013904223;
  Result := State shr 8;
end;

function TScenarioRandom.Below(AValue: Integer): Integer;
begin
  if AValue <= 0 then
    Result := 0
  else
    Result := Integer(Next mod Cardinal(AValue));
end;

{ TScenarioBuffer }

procedure TScenarioBuffer.Clear;
begin
  Bytes := nil;
  Size := 0;
end;

procedure TScenarioBuffer.AddByte(AValue: Byte);
begin
  if Size >= Length(Bytes) then
    SetLength(Bytes, Size * 2 + 64);
  Bytes[Size] := AValue;
  Inc(Size);
end;

procedure TScenarioBuffer.AddWord(AValue: Word);
begin
  AddByte(AValue and $FF);
  AddByte(AValue shr 8);
end;

procedure TScenarioBuffer.AddLong(AValue: Cardinal);
begin
  AddWord(AValue and $FFFF);
  AddWord(AValue shr 16);
end;

procedure TScenarioBuffer.AddRandom(var ARandom: TScenarioRandom; ACount: Integer);
var
  LIndex: Integer;
begin
  for LIndex := 1 to ACount do
    AddByte(ARandom.Next and $FF);
end;

procedure TScenarioBuffer.PatchLong(APosition: Integer; AValue: Cardinal);
begin
  Bytes[APosition] := AValue and $FF;
  Bytes[APosition + 1] := (AValue shr 8) and $FF;
  Bytes[APosition + 2] := (AValue shr 16) and $FF;
  Bytes[APosition + 3] := AValue shr 24;
end;

function TScenarioBuffer.ToBytes: TBytes;
begin
  Result := Copy(Bytes, 0, Size);
end;

{ The WAV files }

procedure AddFormat(var ABuffer: TScenarioBuffer; var ARandom: TScenarioRandom; ALength: Integer;
  ATag: Word);
var
  LChannels: Word;
  LBits: Word;
  LRate: Cardinal;
  LIndex: Integer;
begin
  LChannels := 1 + ARandom.Below(2);
  if ARandom.Below(2) = 0 then
    LBits := 8
  else
    LBits := 16;
  LRate := 8000 + Cardinal(ARandom.Below(40000));
  ABuffer.AddLong(FMT_ID);
  ABuffer.AddLong(ALength);
  // the bytes of the chunk: as many as it says, whatever the length
  for LIndex := 0 to ALength - 1 do
    case LIndex of
      0: ABuffer.AddByte(ATag and $FF);
      1: ABuffer.AddByte(ATag shr 8);
      2: ABuffer.AddByte(LChannels);
      3: ABuffer.AddByte(0);
      4..7: ABuffer.AddByte((LRate shr ((LIndex - 4) * 8)) and $FF);
      8..11: ABuffer.AddByte(((LRate * LChannels * LBits div 8) shr ((LIndex - 8) * 8)) and $FF);
      12: ABuffer.AddByte(LChannels * LBits div 8);
      13: ABuffer.AddByte(0);
      14: ABuffer.AddByte(LBits);
      15: ABuffer.AddByte(0);
    else
      ABuffer.AddByte(ARandom.Next and $FF);
    end;
end;

procedure AddData(var ABuffer: TScenarioBuffer; var ARandom: TScenarioRandom; ALength: Integer;
  ADeclared: Integer);
begin
  ABuffer.AddLong(DATA_ID);
  ABuffer.AddLong(Cardinal(ADeclared));
  ABuffer.AddRandom(ARandom, ALength);
end;

procedure AddOther(var ABuffer: TScenarioBuffer; var ARandom: TScenarioRandom; AId: Cardinal;
  ALength: Integer);
begin
  ABuffer.AddLong(AId);
  ABuffer.AddLong(ALength);
  ABuffer.AddRandom(ARandom, ALength);
end;

function MakeWave(AKind: Integer; var ARandom: TScenarioRandom): TBytes;
var
  LBuffer: TScenarioBuffer;
  LDataLength: Integer;
  LFormatLength: Integer;
  LIndex: Integer;
  LCount: Integer;
begin
  LBuffer.Clear;
  LDataLength := ARandom.Below(300);
  if ARandom.Below(3) = 0 then
    LFormatLength := 18
  else
    LFormatLength := 16;
  LBuffer.AddLong(RIFF_ID);
  LBuffer.AddLong(0);
  LBuffer.AddLong(WAVE_ID);
  case AKind of
    0:
      begin
        AddFormat(LBuffer, ARandom, LFormatLength, 1);
        AddData(LBuffer, ARandom, LDataLength, LDataLength);
      end;
    1:
      begin
        AddOther(LBuffer, ARandom, LIST_ID, ARandom.Below(40));
        AddFormat(LBuffer, ARandom, LFormatLength, 1);
        AddOther(LBuffer, ARandom, $6B6E756A, ARandom.Below(13));
        AddData(LBuffer, ARandom, LDataLength, LDataLength);
      end;
    2:
      begin
        AddData(LBuffer, ARandom, LDataLength, LDataLength);
        AddFormat(LBuffer, ARandom, LFormatLength, 1);
      end;
    3:
      begin
        AddFormat(LBuffer, ARandom, 14, 1);
        AddData(LBuffer, ARandom, LDataLength, LDataLength);
      end;
    4:
      begin
        AddFormat(LBuffer, ARandom, 12, 1);
        AddData(LBuffer, ARandom, LDataLength, LDataLength);
      end;
    5:
      begin
        AddFormat(LBuffer, ARandom, LFormatLength, 3);
        AddData(LBuffer, ARandom, LDataLength, LDataLength);
      end;
    6:
      begin
        AddFormat(LBuffer, ARandom, LFormatLength, 1);
        AddData(LBuffer, ARandom, LDataLength, LDataLength + 1 + ARandom.Below(500));
      end;
    7:
      begin
        LBuffer.PatchLong(8, $45564158);
        AddFormat(LBuffer, ARandom, LFormatLength, 1);
        AddData(LBuffer, ARandom, LDataLength, LDataLength);
      end;
    8:
      begin
        LBuffer.PatchLong(0, $46464953);
        AddFormat(LBuffer, ARandom, LFormatLength, 1);
        AddData(LBuffer, ARandom, LDataLength, LDataLength);
      end;
    9:
      LBuffer.AddRandom(ARandom, ARandom.Below(14));
    10:
      begin
        AddFormat(LBuffer, ARandom, LFormatLength, 1);
        AddFormat(LBuffer, ARandom, 16 + ARandom.Below(3), 1);
        AddData(LBuffer, ARandom, LDataLength, LDataLength);
      end;
    11:
      begin
        AddFormat(LBuffer, ARandom, LFormatLength, 1);
        AddData(LBuffer, ARandom, LDataLength, LDataLength);
        AddData(LBuffer, ARandom, 20, 20);
      end;
    12:
      begin
        AddOther(LBuffer, ARandom, $6B6E756A, 1 + 2 * ARandom.Below(10));
        AddFormat(LBuffer, ARandom, LFormatLength, 1);
        AddOther(LBuffer, ARandom, $6B6E756A, 1 + ARandom.Below(10));
        AddData(LBuffer, ARandom, LDataLength, LDataLength);
      end;
    13:
      begin
        LCount := 1 + ARandom.Below(6);
        for LIndex := 1 to LCount do
          case ARandom.Below(5) of
            0: AddFormat(LBuffer, ARandom, 10 + ARandom.Below(30), ARandom.Below(3));
            1:
              begin
                LDataLength := ARandom.Below(100);
                AddData(LBuffer, ARandom, LDataLength, LDataLength + ARandom.Below(3) * ARandom.Below(60));
              end;
            2: AddOther(LBuffer, ARandom, LIST_ID, ARandom.Below(30));
          else
            LBuffer.AddRandom(ARandom, ARandom.Below(20));
          end;
      end;
    14:
      begin
        AddFormat(LBuffer, ARandom, 20 + ARandom.Below(40), 1);
        AddData(LBuffer, ARandom, LDataLength, LDataLength);
      end;
  else
    // only the format
    AddFormat(LBuffer, ARandom, LFormatLength, 1);
    LBuffer.AddRandom(ARandom, ARandom.Below(9));
  end;
  if LBuffer.Size >= 8 then
    LBuffer.PatchLong(4, LBuffer.Size - 8);
  Result := LBuffer.ToBytes;
end;

const
  WAVE_KINDS = 16;

class function TAudioScenarios.WaveLumps: TArray<TBytes>;
var
  LRandom: TScenarioRandom;
  LIndex: Integer;
begin
  LRandom.State := 20260107;
  SetLength(Result, 240);
  for LIndex := 0 to High(Result) do
    Result[LIndex] := MakeWave(LIndex mod WAVE_KINDS, LRandom);
end;

class function TAudioScenarios.WaveFiles: TArray<TBytes>;
var
  LRandom: TScenarioRandom;
  LIndex: Integer;
begin
  LRandom.State := 19931210;
  SetLength(Result, 192);
  for LIndex := 0 to High(Result) do
    Result[LIndex] := MakeWave(LIndex mod WAVE_KINDS, LRandom);
end;

{ The MUS songs }

const
  MUS_KINDS = 8;

function MakeMus(AKind: Integer; var ARandom: TScenarioRandom): TBytes;
var
  LBuffer: TScenarioBuffer;
  LEvents: Integer;
  LIndex: Integer;
  LType: Integer;
  LLast: Boolean;
  LDelay: Cardinal;
  LStart: Word;
  LInstruments: Word;
begin
  LBuffer.Clear;
  if AKind = 5 then
    LInstruments := 1 + ARandom.Below(8)
  else
    LInstruments := 0;
  LStart := 16 + LInstruments * 2;
  LBuffer.AddLong(MUS_ID);
  LBuffer.AddWord(0);
  LBuffer.AddWord(LStart);
  LBuffer.AddWord(1 + ARandom.Below(9));
  LBuffer.AddWord(0);
  LBuffer.AddWord(LInstruments);
  LBuffer.AddWord(0);
  for LIndex := 1 to LInstruments do
    LBuffer.AddWord(ARandom.Below(175));

  if AKind = 6 then
  begin
    // only the header: the old code read the bytes after the song
    Result := LBuffer.ToBytes;
    Exit;
  end;

  LEvents := ARandom.Below(220);
  for LIndex := 1 to LEvents do
  begin
    LType := ARandom.Below(5);
    LLast := ARandom.Below(3) = 0;
    LBuffer.AddByte((Ord(LLast) shl 7) or (LType shl 4) or ARandom.Below(16));
    case LType of
      0: LBuffer.AddByte(ARandom.Below(128));
      1:
        if ARandom.Below(2) = 0 then
          LBuffer.AddByte(ARandom.Below(128))
        else
        begin
          LBuffer.AddByte($80 or ARandom.Below(128));
          LBuffer.AddByte(ARandom.Below(128));
        end;
      2: LBuffer.AddByte(ARandom.Below(256));
      3:
        if (AKind = 3) and (ARandom.Below(20) = 0) then
          LBuffer.AddByte(ARandom.Below(10))
        else
          LBuffer.AddByte(10 + ARandom.Below(5));
      4:
        begin
          LBuffer.AddByte(ARandom.Below(10));
          LBuffer.AddByte(ARandom.Below(128));
        end;
    end;
    if LLast then
    begin
      LDelay := ARandom.Below(1 shl (7 * (1 + ARandom.Below(3))));
      if LDelay >= 1 shl 14 then
        LBuffer.AddByte($80 or ((LDelay shr 14) and $7F));
      if LDelay >= 1 shl 7 then
        LBuffer.AddByte($80 or ((LDelay shr 7) and $7F));
      LBuffer.AddByte(LDelay and $7F);
    end;
  end;

  case AKind of
    // without the end: the old code went on reading after the song
    2: ;
    // an unknown event (5) ends the song like the end (6)
    4: LBuffer.AddByte($50 or ARandom.Below(16));
    // bytes after the end
    7:
      begin
        LBuffer.AddByte($60);
        LBuffer.AddRandom(ARandom, ARandom.Below(30));
      end;
  else
    LBuffer.AddByte($60);
  end;
  Result := LBuffer.ToBytes;
  // the length of the score in the header
  if Length(Result) >= 6 then
  begin
    Result[4] := (Length(Result) - LStart) and $FF;
    Result[5] := ((Length(Result) - LStart) shr 8) and $FF;
  end;
end;

class function TAudioScenarios.MusSongs: TArray<TBytes>;
var
  LRandom: TScenarioRandom;
  LIndex: Integer;
begin
  LRandom.State := 4242;
  SetLength(Result, 160);
  for LIndex := 0 to High(Result) do
    Result[LIndex] := MakeMus(LIndex mod MUS_KINDS, LRandom);
  // a MIDI file and something that is not a song
  Result[10][0] := Ord('M');
  Result[10][1] := Ord('T');
  Result[10][2] := Ord('h');
  Result[10][3] := Ord('d');
  Result[11][0] := Ord('X');
end;

class function TAudioScenarios.MusTempo(AIndex: Integer): Byte;
begin
  case AIndex mod 4 of
    0: Result := 160;
    1: Result := 1;
    2: Result := 255;
  else
    Result := 100 + AIndex mod 50;
  end;
end;

class function TAudioScenarios.Fingerprint(AData: Pointer; ASize: Integer): string;
var
  LHash: Cardinal;
  LIndex: Integer;
  LByte: PByte;
begin
  LHash := $811C9DC5;
  LByte := AData;
  for LIndex := 0 to ASize - 1 do
  begin
    LHash := (LHash xor LByte^) * $01000193;
    Inc(LByte);
  end;
  Result := IntToHex(LHash, 8);
end;

end.
