{******************************************************************************}
{                                                                              }
{  DelphiDoom: yaml library - the character stream of the scanner              }
{  Port of yaml-cpp 0.7.0 (MIT, Jesse Beder): see Libs\Yaml\README.md          }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Yaml.Stream;

interface

uses
  System.SysUtils,
  DelphiDoom.Yaml.Types;

type
  /// <summary>
  ///   YAML::Stream: reads UTF-8, UTF-16 (LE/BE) and UTF-32 (LE/BE) (with or without a BOM, same detection
  ///   table as yaml-cpp) and gives UTF-8 bytes one by one with the line and column of the next one.
  ///   The whole input is decoded to UTF-8 when the stream is created (yaml-cpp does it on demand: the bytes
  ///   and the end of stream behave the same). The end of the input is the byte $04 (Stream::eof()), also
  ///   when the text itself has a $04 byte, as in yaml-cpp
  /// </summary>
  TYamlStream = class
  public
    const
      /// <summary>The eof char of yaml-cpp</summary>
      EofChar = 4;
  strict private
    type
      TCharSet = (csUtf8, csUtf16le, csUtf16be, csUtf32le, csUtf32be);
  strict private
    FData: TBytes;       // the decoded UTF-8 bytes
    FMark: TYamlMark;
    FHead: Integer;      // absolute index in FData + eofs of the next char
    FLoaded: Integer;    // real bytes already "read ahead"
    FEofs: Integer;      // eof chars pushed after the data
    FEnded: Boolean;     // the input is exhausted (input.good() is false)
    FInputOk: Boolean;
    function ReadSize: Integer;
    class function IntroCharType(AChar: Integer): Integer; static;
    class procedure QueueCodepoint(var AOut: TBytes; var ALength: Integer; ACodepoint: Cardinal); static;
    class function DecodeInput(const AInput: TBytes; AStart: Integer; ACharSet: TCharSet): TBytes; static;
    function GetPeekRaw: Byte;
  public
    constructor Create(const AInput: TBytes);
    /// <summary>The next char without taking it (eof at the end)</summary>
    function Peek: Byte;
    /// <summary>Takes a char and moves the mark</summary>
    function Get: Byte; overload;
    /// <summary>Takes ACount chars</summary>
    function Get(ACount: Integer): TYamlText; overload;
    procedure Eat(ACount: Integer = 1);
    /// <summary>operator bool: the input is good or the next char is not eof</summary>
    function IsOpen: Boolean;
    /// <summary>StreamCharSource::operator bool: ReadAheadTo(AIndex)</summary>
    function ReadAheadTo(AIndex: Integer): Boolean;
    /// <summary>Unchecked access to the read ahead chars (after ReadAheadTo)</summary>
    function CharAt(AIndex: Integer): Byte;
    procedure ResetColumn;
    property Mark: TYamlMark read FMark;
    function Pos: Integer;
    function Line: Integer;
    function Column: Integer;
  end;

implementation

const
  // UtfIntroState
  uis_start = 0; uis_utfbe_b1 = 1; uis_utf32be_b2 = 2; uis_utf32be_bom3 = 3; uis_utf32be = 4;
  uis_utf16be = 5; uis_utf16be_bom1 = 6; uis_utfle_bom1 = 7; uis_utf16le_bom2 = 8;
  uis_utf32le_bom3 = 9; uis_utf16le = 10; uis_utf32le = 11; uis_utf8_imp = 12; uis_utf16le_imp = 13;
  uis_utf32le_imp3 = 14; uis_utf8_bom1 = 15; uis_utf8_bom2 = 16; uis_utf8 = 17; uis_error = 18;

  // UtfIntroCharType: 00, BB, BF, EF, FE, FF, Ascii, Other
  IntroFinalState: array[0..18] of Boolean = (
    False, False, False, False, True, True, False, False, False, False, True, True, False, False,
    False, False, False, True, True);

  IntroTransitions: array[0..17, 0..7] of Byte = (
    (uis_utfbe_b1, uis_utf8, uis_utf8, uis_utf8_bom1, uis_utf16be_bom1, uis_utfle_bom1, uis_utf8_imp, uis_utf8),
    (uis_utf32be_b2, uis_utf8, uis_utf8, uis_utf8, uis_utf8, uis_utf8, uis_utf16be, uis_utf8),
    (uis_utf32be, uis_utf8, uis_utf8, uis_utf8, uis_utf32be_bom3, uis_utf8, uis_utf8, uis_utf8),
    (uis_utf8, uis_utf8, uis_utf8, uis_utf8, uis_utf8, uis_utf32be, uis_utf8, uis_utf8),
    (uis_utf32be, uis_utf32be, uis_utf32be, uis_utf32be, uis_utf32be, uis_utf32be, uis_utf32be, uis_utf32be),
    (uis_utf16be, uis_utf16be, uis_utf16be, uis_utf16be, uis_utf16be, uis_utf16be, uis_utf16be, uis_utf16be),
    (uis_utf8, uis_utf8, uis_utf8, uis_utf8, uis_utf8, uis_utf16be, uis_utf8, uis_utf8),
    (uis_utf8, uis_utf8, uis_utf8, uis_utf8, uis_utf16le_bom2, uis_utf8, uis_utf8, uis_utf8),
    (uis_utf32le_bom3, uis_utf16le, uis_utf16le, uis_utf16le, uis_utf16le, uis_utf16le, uis_utf16le, uis_utf16le),
    (uis_utf32le, uis_utf16le, uis_utf16le, uis_utf16le, uis_utf16le, uis_utf16le, uis_utf16le, uis_utf16le),
    (uis_utf16le, uis_utf16le, uis_utf16le, uis_utf16le, uis_utf16le, uis_utf16le, uis_utf16le, uis_utf16le),
    (uis_utf32le, uis_utf32le, uis_utf32le, uis_utf32le, uis_utf32le, uis_utf32le, uis_utf32le, uis_utf32le),
    (uis_utf16le_imp, uis_utf8, uis_utf8, uis_utf8, uis_utf8, uis_utf8, uis_utf8, uis_utf8),
    (uis_utf32le_imp3, uis_utf16le, uis_utf16le, uis_utf16le, uis_utf16le, uis_utf16le, uis_utf16le, uis_utf16le),
    (uis_utf32le, uis_utf16le, uis_utf16le, uis_utf16le, uis_utf16le, uis_utf16le, uis_utf16le, uis_utf16le),
    (uis_utf8, uis_utf8_bom2, uis_utf8, uis_utf8, uis_utf8, uis_utf8, uis_utf8, uis_utf8),
    (uis_utf8, uis_utf8, uis_utf8, uis_utf8, uis_utf8, uis_utf8, uis_utf8, uis_utf8),
    (uis_utf8, uis_utf8, uis_utf8, uis_utf8, uis_utf8, uis_utf8, uis_utf8, uis_utf8));

  IntroUngetCount: array[0..17, 0..7] of Byte = (
    (0, 1, 1, 0, 0, 0, 0, 1), (0, 2, 2, 2, 2, 2, 2, 2),
    (3, 3, 3, 3, 0, 3, 3, 3), (4, 4, 4, 4, 4, 0, 4, 4),
    (1, 1, 1, 1, 1, 1, 1, 1), (1, 1, 1, 1, 1, 1, 1, 1),
    (2, 2, 2, 2, 2, 0, 2, 2), (2, 2, 2, 2, 0, 2, 2, 2),
    (0, 1, 1, 1, 1, 1, 1, 1), (0, 2, 2, 2, 2, 2, 2, 2),
    (1, 1, 1, 1, 1, 1, 1, 1), (1, 1, 1, 1, 1, 1, 1, 1),
    (0, 2, 2, 2, 2, 2, 2, 2), (0, 3, 3, 3, 3, 3, 3, 3),
    (4, 4, 4, 4, 4, 4, 4, 4), (2, 0, 2, 2, 2, 2, 2, 2),
    (3, 3, 0, 3, 3, 3, 3, 3), (1, 1, 1, 1, 1, 1, 1, 1));

  CpReplacementCharacter = $FFFD;

{ TYamlStream }

class function TYamlStream.IntroCharType(AChar: Integer): Integer;
begin
  case AChar of
    -1: Result := 7;
    0: Result := 0;
    $BB: Result := 1;
    $BF: Result := 2;
    $EF: Result := 3;
    $FE: Result := 4;
    $FF: Result := 5;
  else
    if (AChar > 0) and (AChar < $FF) then
      Result := 6
    else
      Result := 7;
  end;
end;

class procedure TYamlStream.QueueCodepoint(var AOut: TBytes; var ALength: Integer; ACodepoint: Cardinal);

  procedure Push(AValue: Cardinal);
  begin
    if ALength >= Length(AOut) then
      SetLength(AOut, (Length(AOut) + 16) * 2);
    AOut[ALength] := Byte(AValue);
    Inc(ALength);
  end;

begin
  // The eof codepoint cannot be queued
  if ACodepoint = EofChar then
    ACodepoint := CpReplacementCharacter;
  if ACodepoint < $80 then
    Push(ACodepoint)
  else if ACodepoint < $800 then
  begin
    Push($C0 or ((ACodepoint shr 6) and $1F));
    Push($80 or (ACodepoint and $3F));
  end
  else if ACodepoint < $10000 then
  begin
    Push($E0 or ((ACodepoint shr 12) and $F));
    Push($80 or ((ACodepoint shr 6) and $3F));
    Push($80 or (ACodepoint and $3F));
  end
  else
  begin
    Push($F0 or ((ACodepoint shr 18) and $7));
    Push($80 or ((ACodepoint shr 12) and $3F));
    Push($80 or ((ACodepoint shr 6) and $3F));
    Push($80 or (ACodepoint and $3F));
  end;
end;

class function TYamlStream.DecodeInput(const AInput: TBytes; AStart: Integer; ACharSet: TCharSet): TBytes;
var
  LPos: Integer;
  LLength: Integer;
  LEnded: Boolean;

  function NextByte: Byte;
  begin
    if LPos < Length(AInput) then
    begin
      Result := AInput[LPos];
      Inc(LPos);
    end
    else
    begin
      LEnded := True;
      Result := 0;
    end;
  end;

var
  LBytes: array[0..3] of Byte;
  LBigEnd: Integer;
  LCh, LChLow: Cardinal;
  I: Integer;
begin
  Result := nil;
  LLength := 0;
  LPos := AStart;
  LEnded := False;
  if ACharSet = csUtf8 then
  begin
    SetLength(Result, Length(AInput) - AStart);
    if Length(Result) > 0 then
      Move(AInput[AStart], Result[0], Length(Result));
    Exit;
  end;
  while not LEnded do
  begin
    if (ACharSet = csUtf16le) or (ACharSet = csUtf16be) then
    begin
      if ACharSet = csUtf16be then
        LBigEnd := 0
      else
        LBigEnd := 1;
      LBytes[0] := NextByte;
      LBytes[1] := NextByte;
      if LEnded then
        Break;
      LCh := (Cardinal(LBytes[LBigEnd]) shl 8) or Cardinal(LBytes[1 xor LBigEnd]);
      if (LCh >= $DC00) and (LCh < $E000) then
      begin
        QueueCodepoint(Result, LLength, CpReplacementCharacter);
        Continue;
      end;
      if (LCh >= $D800) and (LCh < $DC00) then
      begin
        while True do
        begin
          LBytes[0] := NextByte;
          LBytes[1] := NextByte;
          if LEnded then
          begin
            QueueCodepoint(Result, LLength, CpReplacementCharacter);
            Break;
          end;
          LChLow := (Cardinal(LBytes[LBigEnd]) shl 8) or Cardinal(LBytes[1 xor LBigEnd]);
          if (LChLow < $DC00) or (LChLow >= $E000) then
          begin
            QueueCodepoint(Result, LLength, CpReplacementCharacter);
            if (LChLow < $D800) or (LChLow >= $E000) then
            begin
              QueueCodepoint(Result, LLength, LCh);
              Break;
            end;
            LCh := LChLow;
            Continue;
          end;
          LCh := LCh and $3FF;
          LCh := LCh shl 10;
          LCh := LCh or (LChLow and $3FF);
          LCh := LCh + $10000;
          QueueCodepoint(Result, LLength, LCh);
          Break;
        end;
        Continue;
      end;
      QueueCodepoint(Result, LLength, LCh);
    end
    else
    begin
      for I := 0 to 3 do
        LBytes[I] := NextByte;
      if LEnded then
        Break;
      LCh := 0;
      for I := 0 to 3 do
      begin
        LCh := LCh shl 8;
        if ACharSet = csUtf32be then
          LCh := LCh or LBytes[I]
        else
          LCh := LCh or LBytes[3 - I];
      end;
      QueueCodepoint(Result, LLength, LCh);
    end;
  end;
  SetLength(Result, LLength);
end;

constructor TYamlStream.Create(const AInput: TBytes);
var
  LReads: array[0..3] of Integer;
  LUsed: Integer;
  LState, LType, LNewState, LUngets: Integer;
  LPos: Integer;
  LCharSet: TCharSet;
  LCh: Integer;
begin
  inherited Create;
  FMark := TYamlMark.Zero;
  FInputOk := True;
  LPos := 0;
  LUsed := 0;
  LState := uis_start;
  while not IntroFinalState[LState] do
  begin
    if LPos < Length(AInput) then
    begin
      LCh := AInput[LPos];
      Inc(LPos);
    end
    else
      LCh := -1;
    LReads[LUsed] := LCh;
    Inc(LUsed);
    LType := IntroCharType(LCh);
    LNewState := IntroTransitions[LState, LType];
    LUngets := IntroUngetCount[LState, LType];
    while LUngets > 0 do
    begin
      Dec(LUsed);
      if LReads[LUsed] <> -1 then
        Dec(LPos);
      Dec(LUngets);
    end;
    LState := LNewState;
  end;
  case LState of
    uis_utf16le: LCharSet := csUtf16le;
    uis_utf16be: LCharSet := csUtf16be;
    uis_utf32le: LCharSet := csUtf32le;
    uis_utf32be: LCharSet := csUtf32be;
  else
    LCharSet := csUtf8;
  end;
  FData := DecodeInput(AInput, LPos, LCharSet);
  ReadAheadTo(0);
end;

function TYamlStream.ReadSize: Integer;
begin
  Result := FLoaded + FEofs - FHead;
end;

function TYamlStream.ReadAheadTo(AIndex: Integer): Boolean;
begin
  if ReadSize > AIndex then
    Exit(True);
  while (not FEnded) and (ReadSize <= AIndex) do
  begin
    if FLoaded < Length(FData) then
      Inc(FLoaded)
    else
      FEnded := True;
  end;
  if FEnded then
    Inc(FEofs);
  Result := ReadSize > AIndex;
end;

function TYamlStream.CharAt(AIndex: Integer): Byte;
var
  LAbs: Integer;
begin
  LAbs := FHead + AIndex;
  if LAbs < Length(FData) then
    Result := FData[LAbs]
  else
    Result := EofChar;
end;

function TYamlStream.GetPeekRaw: Byte;
begin
  if ReadSize = 0 then
    Result := EofChar
  else
    Result := CharAt(0);
end;

function TYamlStream.Peek: Byte;
begin
  Result := GetPeekRaw;
end;

function TYamlStream.IsOpen: Boolean;
begin
  Result := (not FEnded) or ((ReadSize > 0) and (CharAt(0) <> EofChar));
end;

function TYamlStream.Get: Byte;
begin
  Result := Peek;
  // AdvanceCurrent
  if ReadSize > 0 then
  begin
    Inc(FHead);
    Inc(FMark.Pos);
  end;
  ReadAheadTo(0);
  Inc(FMark.Column);
  if Result = 10 then
  begin
    FMark.Column := 0;
    Inc(FMark.Line);
  end;
end;

function TYamlStream.Get(ACount: Integer): TYamlText;
var
  I: Integer;
begin
  Result := '';
  if ACount > 0 then
  begin
    SetLength(Result, ACount);
    for I := 1 to ACount do
      Result[I] := AnsiChar(Get);
  end;
end;

procedure TYamlStream.Eat(ACount: Integer);
var
  I: Integer;
begin
  for I := 1 to ACount do
    Get;
end;

procedure TYamlStream.ResetColumn;
begin
  FMark.Column := 0;
end;

function TYamlStream.Pos: Integer;
begin
  Result := FMark.Pos;
end;

function TYamlStream.Line: Integer;
begin
  Result := FMark.Line;
end;

function TYamlStream.Column: Integer;
begin
  Result := FMark.Column;
end;

end.
