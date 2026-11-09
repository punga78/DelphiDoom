{******************************************************************************}
{                                                                              }
{  DelphiDoom: yaml library - how the emitter writes strings and names         }
{  Port of yaml-cpp 0.7.0 (MIT, Jesse Beder): see Libs\Yaml\README.md          }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Yaml.EmitterUtils;

interface

uses
  System.SysUtils,
  DelphiDoom.Yaml.Types,
  DelphiDoom.Yaml.RegEx,
  DelphiDoom.Yaml.Exp,
  DelphiDoom.Yaml.Convert,
  DelphiDoom.Yaml.OutputWriter,
  DelphiDoom.Yaml.EmitterState;

type
  /// <summary>StringFormat::value</summary>
  TYamlStringFormat = (sfPlain, sfSingleQuoted, sfDoubleQuoted, sfLiteral);
  /// <summary>StringEscaping::value</summary>
  TYamlStringEscaping = (seNone, seNonAscii, seJSON);

  /// <summary>YAML::Utils: the functions that write scalars, comments, anchors, aliases and tags</summary>
  TYamlEmitterUtils = class
  strict private
    class var FDisallowedFlow: TYamlRegEx;
    class var FDisallowedBlock: TYamlRegEx;
    class function NextCodePoint(const AText: TYamlText; var AIndex: Integer; out ACodePoint: Integer): Boolean; static;
    class procedure WriteCodePoint(AOut: TYamlOutputWriter; ACodePoint: Integer); static;
    class function IsAnchorChar(ACh: Integer): Boolean; static;
    class function IsValidPlainScalar(const AText: TYamlText; AFlowType: TYamlFlowType; AAllowOnlyAscii: Boolean): Boolean; static;
    class procedure WriteDoubleQuoteEscapeSequence(AOut: TYamlOutputWriter; ACodePoint: Integer;
      AEscaping: TYamlStringEscaping); static;
    class function WriteAliasName(AOut: TYamlOutputWriter; const AText: TYamlText): Boolean; static;
  public
    class constructor CreateClass;
    class function ComputeStringFormat(const AText: TYamlText; AFormat: TYamlManip; AFlowType: TYamlFlowType;
      AEscapeNonAscii: Boolean): TYamlStringFormat; static;
    class function WriteSingleQuotedString(AOut: TYamlOutputWriter; const AText: TYamlText): Boolean; static;
    class function WriteDoubleQuotedString(AOut: TYamlOutputWriter; const AText: TYamlText;
      AEscaping: TYamlStringEscaping): Boolean; static;
    class function WriteLiteralString(AOut: TYamlOutputWriter; const AText: TYamlText; AIndent: Integer): Boolean; static;
    class function WriteChar(AOut: TYamlOutputWriter; AChar: Byte; AEscaping: TYamlStringEscaping): Boolean; static;
    class function WriteComment(AOut: TYamlOutputWriter; const AText: TYamlText; APostCommentIndent: Integer): Boolean; static;
    class function WriteAlias(AOut: TYamlOutputWriter; const AText: TYamlText): Boolean; static;
    class function WriteAnchor(AOut: TYamlOutputWriter; const AText: TYamlText): Boolean; static;
    class function WriteTag(AOut: TYamlOutputWriter; const AText: TYamlText; AVerbatim: Boolean): Boolean; static;
    class function WriteTagWithPrefix(AOut: TYamlOutputWriter; const APrefix, ATag: TYamlText): Boolean; static;
    class function WriteBinary(AOut: TYamlOutputWriter; const AData: TBytes): Boolean; static;
  end;

implementation

const
  ReplacementCharacter = $FFFD;

// Arithmetic shift right (the shift of a signed int in C)
function Sar(AValue: Integer; ACount: Integer): Integer;
begin
  if AValue >= 0 then
    Result := AValue shr ACount
  else
    Result := not ((not AValue) shr ACount);
end;

class constructor TYamlEmitterUtils.CreateClass;
begin
  FDisallowedFlow := TYamlRegEx.OrOf(TYamlRegEx.OrOf(TYamlRegEx.OrOf(TYamlRegEx.OrOf(TYamlRegEx.OrOf(
    TYamlExp.EndScalarInFlow, TYamlRegEx.SeqOf(TYamlExp.BlankOrBreak, TYamlExp.Comment)),
    TYamlExp.NotPrintable), TYamlExp.Utf8ByteOrderMark), TYamlExp.Break), TYamlExp.Tab);
  FDisallowedBlock := TYamlRegEx.OrOf(TYamlRegEx.OrOf(TYamlRegEx.OrOf(TYamlRegEx.OrOf(TYamlRegEx.OrOf(
    TYamlExp.EndScalar, TYamlRegEx.SeqOf(TYamlExp.BlankOrBreak, TYamlExp.Comment)),
    TYamlExp.NotPrintable), TYamlExp.Utf8ByteOrderMark), TYamlExp.Break), TYamlExp.Tab);
end;

class function TYamlEmitterUtils.IsAnchorChar(ACh: Integer): Boolean;
begin
  case ACh of
    Ord(','), Ord('['), Ord(']'), Ord('{'), Ord('}'), Ord(' '), 9, $FEFF, $A, $D:
      Exit(False);
    $85:
      Exit(True);
  end;
  if ACh < $20 then
    Exit(False);
  if ACh < $7E then
    Exit(True);
  if ACh < $A0 then
    Exit(False);
  if (ACh >= $D800) and (ACh <= $DFFF) then
    Exit(False);
  if (ACh and $FFFE) = $FFFE then
    Exit(False);
  if (ACh >= $FDD0) and (ACh <= $FDEF) then
    Exit(False);
  if ACh > $10FFFF then
    Exit(False);
  Result := True;
end;

class function TYamlEmitterUtils.NextCodePoint(const AText: TYamlText; var AIndex: Integer;
  out ACodePoint: Integer): Boolean;
var
  LByte, LBytes: Integer;
begin
  ACodePoint := 0;
  if AIndex > Length(AText) then
    Exit(False);
  LByte := Byte(AText[AIndex]);
  case LByte shr 4 of
    0..7: LBytes := 1;
    12, 13: LBytes := 2;
    14: LBytes := 3;
    15: LBytes := 4;
  else
    LBytes := -1;
  end;
  if LBytes < 1 then
  begin
    Inc(AIndex);
    ACodePoint := ReplacementCharacter;
    Exit(True);
  end;
  if LBytes = 1 then
  begin
    ACodePoint := LByte;
    Inc(AIndex);
    Exit(True);
  end;
  ACodePoint := LByte and ((1 shl (7 - LBytes)) - 1);
  Inc(AIndex);
  Dec(LBytes);
  while LBytes > 0 do
  begin
    if (AIndex > Length(AText)) or ((Byte(AText[AIndex]) and $C0) <> $80) then
    begin
      ACodePoint := ReplacementCharacter;
      Break;
    end;
    ACodePoint := (ACodePoint shl 6) or (Byte(AText[AIndex]) and $3F);
    Inc(AIndex);
    Dec(LBytes);
  end;
  if ACodePoint > $10FFFF then
    ACodePoint := ReplacementCharacter
  else if (ACodePoint >= $D800) and (ACodePoint <= $DFFF) then
    ACodePoint := ReplacementCharacter
  else if (ACodePoint and $FFFE) = $FFFE then
    ACodePoint := ReplacementCharacter
  else if (ACodePoint >= $FDD0) and (ACodePoint <= $FDEF) then
    ACodePoint := ReplacementCharacter;
  Result := True;
end;

class procedure TYamlEmitterUtils.WriteCodePoint(AOut: TYamlOutputWriter; ACodePoint: Integer);
begin
  if (ACodePoint < 0) or (ACodePoint > $10FFFF) then
    ACodePoint := ReplacementCharacter;
  if ACodePoint <= $7F then
    AOut.Write(Byte(ACodePoint))
  else if ACodePoint <= $7FF then
  begin
    AOut.Write(Byte($C0 or (ACodePoint shr 6)));
    AOut.Write(Byte($80 or (ACodePoint and $3F)));
  end
  else if ACodePoint <= $FFFF then
  begin
    AOut.Write(Byte($E0 or (ACodePoint shr 12)));
    AOut.Write(Byte($80 or ((ACodePoint shr 6) and $3F)));
    AOut.Write(Byte($80 or (ACodePoint and $3F)));
  end
  else
  begin
    AOut.Write(Byte($F0 or (ACodePoint shr 18)));
    AOut.Write(Byte($80 or ((ACodePoint shr 12) and $3F)));
    AOut.Write(Byte($80 or ((ACodePoint shr 6) and $3F)));
    AOut.Write(Byte($80 or (ACodePoint and $3F)));
  end;
end;

class function TYamlEmitterUtils.IsValidPlainScalar(const AText: TYamlText; AFlowType: TYamlFlowType;
  AAllowOnlyAscii: Boolean): Boolean;
var
  LStart, LDisallowed: TYamlRegEx;
  LBuffer: TYamlCharSource;
begin
  if TYamlConvert.IsNullString(AText) then
    Exit(False);
  if AFlowType = ftFlow then
    LStart := TYamlExp.PlainScalarInFlow
  else
    LStart := TYamlExp.PlainScalar;
  if not LStart.Matches(AText) then
    Exit(False);
  if (AText <> '') and (AText[Length(AText)] = ' ') then
    Exit(False);
  if AFlowType = ftFlow then
    LDisallowed := FDisallowedFlow
  else
    LDisallowed := FDisallowedBlock;
  LBuffer := TYamlCharSource.FromText(AText);
  while LBuffer.IsValid do
  begin
    if LDisallowed.Matches(LBuffer) then
      Exit(False);
    if AAllowOnlyAscii and ($80 <= LBuffer.At(0)) then
      Exit(False);
    LBuffer.Advance;
  end;
  Result := True;
end;

class function TYamlEmitterUtils.ComputeStringFormat(const AText: TYamlText; AFormat: TYamlManip;
  AFlowType: TYamlFlowType; AEscapeNonAscii: Boolean): TYamlStringFormat;
var
  I: Integer;
begin
  case AFormat of
    ymAuto:
      if IsValidPlainScalar(AText, AFlowType, AEscapeNonAscii) then
        Exit(sfPlain)
      else
        Exit(sfDoubleQuoted);
    ymSingleQuoted:
      begin
        // IsValidSingleQuotedScalar
        for I := 1 to Length(AText) do
          if (AEscapeNonAscii and (Byte(AText[I]) >= $80)) or (AText[I] = #10) then
            Exit(sfDoubleQuoted);
        Exit(sfSingleQuoted);
      end;
    ymDoubleQuoted:
      Exit(sfDoubleQuoted);
    ymLiteral:
      begin
        // IsValidLiteralScalar
        if AFlowType = ftFlow then
          Exit(sfDoubleQuoted);
        for I := 1 to Length(AText) do
          if AEscapeNonAscii and (Byte(AText[I]) >= $80) then
            Exit(sfDoubleQuoted);
        Exit(sfLiteral);
      end;
  end;
  Result := sfDoubleQuoted;
end;

class function TYamlEmitterUtils.WriteSingleQuotedString(AOut: TYamlOutputWriter; const AText: TYamlText): Boolean;
var
  I, LCodePoint: Integer;
begin
  AOut.Write('''');
  I := 1;
  while NextCodePoint(AText, I, LCodePoint) do
  begin
    if LCodePoint = 10 then
      Exit(False); // we can't handle a new line and the attendant indentation
    if LCodePoint = Ord('''') then
      AOut.Write('''''')
    else
      WriteCodePoint(AOut, LCodePoint);
  end;
  AOut.Write('''');
  Result := True;
end;

class procedure TYamlEmitterUtils.WriteDoubleQuoteEscapeSequence(AOut: TYamlOutputWriter; ACodePoint: Integer;
  AEscaping: TYamlStringEscaping);
const
  HexDigits: array[0..15] of AnsiChar = '0123456789abcdef';
var
  LDigits: Integer;
  LFirst, LSecond: Integer;
begin
  AOut.Write('\');
  if (ACodePoint < $FF) and (AEscaping <> seJSON) then
  begin
    AOut.Write('x');
    LDigits := 2;
  end
  else if ACodePoint < $FFFF then
  begin
    AOut.Write('u');
    LDigits := 4;
  end
  else if AEscaping <> seJSON then
  begin
    AOut.Write('U');
    LDigits := 8;
  end
  else
  begin
    LFirst := ($D800 - ($10000 shr 10)) or (ACodePoint shr 10);
    LSecond := $DC00 or (ACodePoint and $3FF);
    WriteDoubleQuoteEscapeSequence(AOut, LFirst and $FFFF, AEscaping);
    WriteDoubleQuoteEscapeSequence(AOut, LSecond and $FFFF, AEscaping);
    Exit;
  end;
  while LDigits > 0 do
  begin
    AOut.Write(Byte(HexDigits[Sar(ACodePoint, 4 * (LDigits - 1)) and $F]));
    Dec(LDigits);
  end;
end;

class function TYamlEmitterUtils.WriteDoubleQuotedString(AOut: TYamlOutputWriter; const AText: TYamlText;
  AEscaping: TYamlStringEscaping): Boolean;
var
  I, LCodePoint: Integer;
begin
  AOut.Write('"');
  I := 1;
  while NextCodePoint(AText, I, LCodePoint) do
  begin
    case LCodePoint of
      Ord('"'): AOut.Write('\"');
      Ord('\'): AOut.Write('\\');
      10: AOut.Write('\n');
      9: AOut.Write('\t');
      13: AOut.Write('\r');
      8: AOut.Write('\b');
      12: AOut.Write('\f');
    else
      if (LCodePoint < $20) or ((LCodePoint >= $80) and (LCodePoint <= $A0)) then
        // control characters and non-breaking space
        WriteDoubleQuoteEscapeSequence(AOut, LCodePoint, AEscaping)
      else if LCodePoint = $FEFF then
        // byte order marks (ZWNS) should be escaped (YAML 1.2, sec. 5.2)
        WriteDoubleQuoteEscapeSequence(AOut, LCodePoint, AEscaping)
      else if (AEscaping = seNonAscii) and (LCodePoint > $7E) then
        WriteDoubleQuoteEscapeSequence(AOut, LCodePoint, AEscaping)
      else
        WriteCodePoint(AOut, LCodePoint);
    end;
  end;
  AOut.Write('"');
  Result := True;
end;

class function TYamlEmitterUtils.WriteLiteralString(AOut: TYamlOutputWriter; const AText: TYamlText;
  AIndent: Integer): Boolean;
var
  I, LCodePoint: Integer;
begin
  AOut.Write('|'#10);
  I := 1;
  while NextCodePoint(AText, I, LCodePoint) do
  begin
    if LCodePoint = 10 then
      AOut.Write(#10)
    else
    begin
      AOut.IndentTo(AIndent);
      WriteCodePoint(AOut, LCodePoint);
    end;
  end;
  Result := True;
end;

class function TYamlEmitterUtils.WriteChar(AOut: TYamlOutputWriter; AChar: Byte;
  AEscaping: TYamlStringEscaping): Boolean;
var
  LSigned: Integer;
begin
  // ch is a (signed) char in C++
  if AChar >= $80 then
    LSigned := Integer(AChar) - 256
  else
    LSigned := AChar;
  if ((LSigned >= Ord('a')) and (LSigned <= Ord('z'))) or ((LSigned >= Ord('A')) and (LSigned <= Ord('Z'))) then
    AOut.Write(AChar)
  else if LSigned = Ord('"') then
    AOut.Write('"\""')
  else if LSigned = 9 then
    AOut.Write('"\t"')
  else if LSigned = 10 then
    AOut.Write('"\n"')
  else if LSigned = 8 then
    AOut.Write('"\b"')
  else if LSigned = 13 then
    AOut.Write('"\r"')
  else if LSigned = 12 then
    AOut.Write('"\f"')
  else if LSigned = Ord('\') then
    AOut.Write('"\\"')
  else if (LSigned >= $20) and (LSigned <= $7E) then
  begin
    AOut.Write('"');
    AOut.Write(AChar);
    AOut.Write('"');
  end
  else
  begin
    AOut.Write('"');
    WriteDoubleQuoteEscapeSequence(AOut, LSigned, AEscaping);
    AOut.Write('"');
  end;
  Result := True;
end;

class function TYamlEmitterUtils.WriteComment(AOut: TYamlOutputWriter; const AText: TYamlText;
  APostCommentIndent: Integer): Boolean;
var
  LCurIndent, I, LCodePoint: Integer;
begin
  LCurIndent := AOut.Col;
  AOut.Write('#');
  AOut.WriteSpaces(APostCommentIndent);
  AOut.SetComment;
  I := 1;
  while NextCodePoint(AText, I, LCodePoint) do
  begin
    if LCodePoint = 10 then
    begin
      AOut.Write(#10);
      AOut.IndentTo(LCurIndent);
      AOut.Write('#');
      AOut.WriteSpaces(APostCommentIndent);
      AOut.SetComment;
    end
    else
      WriteCodePoint(AOut, LCodePoint);
  end;
  Result := True;
end;

class function TYamlEmitterUtils.WriteAliasName(AOut: TYamlOutputWriter; const AText: TYamlText): Boolean;
var
  I, LCodePoint: Integer;
begin
  I := 1;
  while NextCodePoint(AText, I, LCodePoint) do
  begin
    if not IsAnchorChar(LCodePoint) then
      Exit(False);
    WriteCodePoint(AOut, LCodePoint);
  end;
  Result := True;
end;

class function TYamlEmitterUtils.WriteAlias(AOut: TYamlOutputWriter; const AText: TYamlText): Boolean;
begin
  AOut.Write('*');
  Result := WriteAliasName(AOut, AText);
end;

class function TYamlEmitterUtils.WriteAnchor(AOut: TYamlOutputWriter; const AText: TYamlText): Boolean;
begin
  AOut.Write('&');
  Result := WriteAliasName(AOut, AText);
end;

class function TYamlEmitterUtils.WriteTag(AOut: TYamlOutputWriter; const AText: TYamlText;
  AVerbatim: Boolean): Boolean;
var
  LBuffer: TYamlCharSource;
  LValid: TYamlRegEx;
  N: Integer;
begin
  if AVerbatim then
    AOut.Write('!<')
  else
    AOut.Write('!');
  LBuffer := TYamlCharSource.FromText(AText);
  if AVerbatim then
    LValid := TYamlExp.URI
  else
    LValid := TYamlExp.Tag;
  while LBuffer.IsValid do
  begin
    N := LValid.Match(LBuffer);
    if N <= 0 then
      Exit(False);
    Dec(N);
    while N >= 0 do
    begin
      AOut.Write(LBuffer.At(0));
      LBuffer.Advance;
      Dec(N);
    end;
  end;
  if AVerbatim then
    AOut.Write('>');
  Result := True;
end;

class function TYamlEmitterUtils.WriteTagWithPrefix(AOut: TYamlOutputWriter; const APrefix, ATag: TYamlText): Boolean;
var
  LBuffer: TYamlCharSource;
  N: Integer;
begin
  AOut.Write('!');
  LBuffer := TYamlCharSource.FromText(APrefix);
  while LBuffer.IsValid do
  begin
    N := TYamlExp.URI.Match(LBuffer);
    if N <= 0 then
      Exit(False);
    Dec(N);
    while N >= 0 do
    begin
      AOut.Write(LBuffer.At(0));
      LBuffer.Advance;
      Dec(N);
    end;
  end;
  AOut.Write('!');
  LBuffer := TYamlCharSource.FromText(ATag);
  while LBuffer.IsValid do
  begin
    N := TYamlExp.Tag.Match(LBuffer);
    if N <= 0 then
      Exit(False);
    Dec(N);
    while N >= 0 do
    begin
      AOut.Write(LBuffer.At(0));
      LBuffer.Advance;
      Dec(N);
    end;
  end;
  Result := True;
end;

class function TYamlEmitterUtils.WriteBinary(AOut: TYamlOutputWriter; const AData: TBytes): Boolean;
begin
  WriteDoubleQuotedString(AOut, TYamlConvert.EncodeBase64(AData), seNone);
  Result := True;
end;

end.
