{******************************************************************************}
{                                                                              }
{  DelphiDoom: yaml library - the named expressions (YAML::Exp) and escapes    }
{  Port of yaml-cpp 0.7.0 (MIT, Jesse Beder): see Libs\Yaml\README.md          }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Yaml.Exp;

interface

uses
  System.SysUtils,
  DelphiDoom.Yaml.Types,
  DelphiDoom.Yaml.Stream,
  DelphiDoom.Yaml.RegEx;

type
  /// <summary>The expressions of YAML::Exp (built once) and the escape sequences of quoted scalars</summary>
  TYamlExp = class
  strict private
    class var FEmpty, FSpace, FTab, FBlank, FBreak, FBlankOrBreak, FDigit, FAlpha, FAlphaNumeric, FWord,
      FHex, FNotPrintable, FUtf8ByteOrderMark, FDocStart, FDocEnd, FDocIndicator, FBlockEntry, FKey,
      FKeyInFlow, FValue, FValueInFlow, FValueInJSONFlow, FComment, FAnchor, FAnchorEnd, FURI, FTag,
      FPlainScalar, FPlainScalarInFlow, FEndScalar, FEndScalarInFlow, FScanScalarEndInFlow,
      FScanScalarEnd, FEscSingleQuote, FEscBreak, FChompIndicator, FChomp, FSingleQuoteEnd,
      FDoubleQuoteEnd: TYamlRegEx;
    class function ParseHex(const AText: TYamlText; const AMark: TYamlMark): Cardinal; static;
    class function EscapeCode(AStream: TYamlStream; ACodeLength: Integer): TYamlText; static;
  public
    class constructor CreateClass;
    class property Empty: TYamlRegEx read FEmpty;
    class property Space: TYamlRegEx read FSpace;
    class property Tab: TYamlRegEx read FTab;
    class property Blank: TYamlRegEx read FBlank;
    class property Break: TYamlRegEx read FBreak;
    class property BlankOrBreak: TYamlRegEx read FBlankOrBreak;
    class property Digit: TYamlRegEx read FDigit;
    class property Alpha: TYamlRegEx read FAlpha;
    class property AlphaNumeric: TYamlRegEx read FAlphaNumeric;
    class property Word: TYamlRegEx read FWord;
    class property Hex: TYamlRegEx read FHex;
    class property NotPrintable: TYamlRegEx read FNotPrintable;
    class property Utf8ByteOrderMark: TYamlRegEx read FUtf8ByteOrderMark;
    class property DocStart: TYamlRegEx read FDocStart;
    class property DocEnd: TYamlRegEx read FDocEnd;
    class property DocIndicator: TYamlRegEx read FDocIndicator;
    class property BlockEntry: TYamlRegEx read FBlockEntry;
    class property Key: TYamlRegEx read FKey;
    class property KeyInFlow: TYamlRegEx read FKeyInFlow;
    class property Value: TYamlRegEx read FValue;
    class property ValueInFlow: TYamlRegEx read FValueInFlow;
    class property ValueInJSONFlow: TYamlRegEx read FValueInJSONFlow;
    class property Comment: TYamlRegEx read FComment;
    class property Anchor: TYamlRegEx read FAnchor;
    class property AnchorEnd: TYamlRegEx read FAnchorEnd;
    class property URI: TYamlRegEx read FURI;
    class property Tag: TYamlRegEx read FTag;
    class property PlainScalar: TYamlRegEx read FPlainScalar;
    class property PlainScalarInFlow: TYamlRegEx read FPlainScalarInFlow;
    class property EndScalar: TYamlRegEx read FEndScalar;
    class property EndScalarInFlow: TYamlRegEx read FEndScalarInFlow;
    class property ScanScalarEndInFlow: TYamlRegEx read FScanScalarEndInFlow;
    class property ScanScalarEnd: TYamlRegEx read FScanScalarEnd;
    class property EscSingleQuote: TYamlRegEx read FEscSingleQuote;
    class property EscBreak: TYamlRegEx read FEscBreak;
    class property ChompIndicator: TYamlRegEx read FChompIndicator;
    class property Chomp: TYamlRegEx read FChomp;
    /// <summary>The end of a single quoted scalar: a quote that is not a doubled quote</summary>
    class property SingleQuoteEnd: TYamlRegEx read FSingleQuoteEnd;
    /// <summary>The end of a double quoted scalar</summary>
    class property DoubleQuoteEnd: TYamlRegEx read FDoubleQuoteEnd;
    /// <summary>Exp::Escape(Stream&amp;): the escape sequence at the stream as the UTF-8 (or single) bytes it means</summary>
    class function Escape(AStream: TYamlStream): TYamlText; static;
  end;

const
  // YAML::Keys
  YAML_KEY_DIRECTIVE = Ord('%');
  YAML_KEY_FLOW_SEQ_START = Ord('[');
  YAML_KEY_FLOW_SEQ_END = Ord(']');
  YAML_KEY_FLOW_MAP_START = Ord('{');
  YAML_KEY_FLOW_MAP_END = Ord('}');
  YAML_KEY_FLOW_ENTRY = Ord(',');
  YAML_KEY_ALIAS = Ord('*');
  YAML_KEY_ANCHOR = Ord('&');
  YAML_KEY_TAG = Ord('!');
  YAML_KEY_LITERAL_SCALAR = Ord('|');
  YAML_KEY_FOLDED_SCALAR = Ord('>');
  YAML_KEY_VERBATIM_TAG_START = Ord('<');
  YAML_KEY_VERBATIM_TAG_END = Ord('>');

implementation

class constructor TYamlExp.CreateClass;
begin
  FEmpty := TYamlRegEx.Empty;
  FSpace := TYamlRegEx.Ch(Ord(' '));
  FTab := TYamlRegEx.Ch(9);
  FBlank := TYamlRegEx.OrOf(FSpace, FTab);
  FBreak := TYamlRegEx.OrOf(TYamlRegEx.Ch(10), TYamlRegEx.Str(#13#10));
  FBlankOrBreak := TYamlRegEx.OrOf(FBlank, FBreak);
  FDigit := TYamlRegEx.Range(Ord('0'), Ord('9'));
  FAlpha := TYamlRegEx.OrOf(TYamlRegEx.Range(Ord('a'), Ord('z')), TYamlRegEx.Range(Ord('A'), Ord('Z')));
  FAlphaNumeric := TYamlRegEx.OrOf(FAlpha, FDigit);
  FWord := TYamlRegEx.OrOf(FAlphaNumeric, TYamlRegEx.Ch(Ord('-')));
  FHex := TYamlRegEx.OrOf(TYamlRegEx.OrOf(FDigit, TYamlRegEx.Range(Ord('A'), Ord('F'))),
    TYamlRegEx.Range(Ord('a'), Ord('f')));
  // RegEx(0) | RegEx("\x01..\x7F", OR) | RegEx(0x0E, 0x1F) | (RegEx('\xC2') + (RegEx('\x80','\x84') | RegEx('\x86','\x9F')))
  FNotPrintable := TYamlRegEx.OrOf(
    TYamlRegEx.OrOf(
      TYamlRegEx.OrOf(TYamlRegEx.Ch(0), TYamlRegEx.Str(#1#2#3#4#5#6#7#8#11#12#127, True)),
      TYamlRegEx.Range($0E, $1F)),
    TYamlRegEx.SeqOf(TYamlRegEx.Ch($C2),
      TYamlRegEx.OrOf(TYamlRegEx.Range($80, $84), TYamlRegEx.Range($86, $9F))));
  FUtf8ByteOrderMark := TYamlRegEx.Str(YamlBytes([$EF, $BB, $BF]));
  FDocStart := TYamlRegEx.SeqOf(TYamlRegEx.Str('---'), TYamlRegEx.OrOf(FBlankOrBreak, TYamlRegEx.Empty));
  FDocEnd := TYamlRegEx.SeqOf(TYamlRegEx.Str('...'), TYamlRegEx.OrOf(FBlankOrBreak, TYamlRegEx.Empty));
  FDocIndicator := TYamlRegEx.OrOf(FDocStart, FDocEnd);
  FBlockEntry := TYamlRegEx.SeqOf(TYamlRegEx.Ch(Ord('-')), TYamlRegEx.OrOf(FBlankOrBreak, TYamlRegEx.Empty));
  FKey := TYamlRegEx.SeqOf(TYamlRegEx.Ch(Ord('?')), FBlankOrBreak);
  FKeyInFlow := TYamlRegEx.SeqOf(TYamlRegEx.Ch(Ord('?')), FBlankOrBreak);
  FValue := TYamlRegEx.SeqOf(TYamlRegEx.Ch(Ord(':')), TYamlRegEx.OrOf(FBlankOrBreak, TYamlRegEx.Empty));
  FValueInFlow := TYamlRegEx.SeqOf(TYamlRegEx.Ch(Ord(':')),
    TYamlRegEx.OrOf(FBlankOrBreak, TYamlRegEx.Str(',]}', True)));
  FValueInJSONFlow := TYamlRegEx.Ch(Ord(':'));
  FComment := TYamlRegEx.Ch(Ord('#'));
  FAnchor := TYamlRegEx.NotOf(TYamlRegEx.OrOf(TYamlRegEx.Str('[]{},', True), FBlankOrBreak));
  FAnchorEnd := TYamlRegEx.OrOf(TYamlRegEx.Str('?:,]}%@`', True), FBlankOrBreak);
  FURI := TYamlRegEx.OrOf(TYamlRegEx.OrOf(FWord, TYamlRegEx.Str('#;/?:@&=+$,_.!~*''()[]', True)),
    TYamlRegEx.SeqOf(TYamlRegEx.SeqOf(TYamlRegEx.Ch(Ord('%')), FHex), FHex));
  FTag := TYamlRegEx.OrOf(TYamlRegEx.OrOf(FWord, TYamlRegEx.Str('#;/?:@&=+$_.~*''()', True)),
    TYamlRegEx.SeqOf(TYamlRegEx.SeqOf(TYamlRegEx.Ch(Ord('%')), FHex), FHex));
  // !(BlankOrBreak() | RegEx(",[]{}#&*!|>'\"%@`", OR) | (RegEx("-?:", OR) + (BlankOrBreak() | RegEx())))
  FPlainScalar := TYamlRegEx.NotOf(TYamlRegEx.OrOf(TYamlRegEx.OrOf(FBlankOrBreak,
    TYamlRegEx.Str(',[]{}#&*!|>''"%@`', True)),
    TYamlRegEx.SeqOf(TYamlRegEx.Str('-?:', True), TYamlRegEx.OrOf(FBlankOrBreak, TYamlRegEx.Empty))));
  FPlainScalarInFlow := TYamlRegEx.NotOf(TYamlRegEx.OrOf(TYamlRegEx.OrOf(FBlankOrBreak,
    TYamlRegEx.Str('?,[]{}#&*!|>''"%@`', True)),
    TYamlRegEx.SeqOf(TYamlRegEx.Str('-:', True), TYamlRegEx.OrOf(FBlank, TYamlRegEx.Empty))));
  FEndScalar := TYamlRegEx.SeqOf(TYamlRegEx.Ch(Ord(':')), TYamlRegEx.OrOf(FBlankOrBreak, TYamlRegEx.Empty));
  FEndScalarInFlow := TYamlRegEx.OrOf(
    TYamlRegEx.SeqOf(TYamlRegEx.Ch(Ord(':')),
      TYamlRegEx.OrOf(TYamlRegEx.OrOf(FBlankOrBreak, TYamlRegEx.Empty), TYamlRegEx.Str(',]}', True))),
    TYamlRegEx.Str(',?[]{}', True));
  FScanScalarEndInFlow := TYamlRegEx.OrOf(FEndScalarInFlow, TYamlRegEx.SeqOf(FBlankOrBreak, FComment));
  FScanScalarEnd := TYamlRegEx.OrOf(FEndScalar, TYamlRegEx.SeqOf(FBlankOrBreak, FComment));
  FEscSingleQuote := TYamlRegEx.Str('''''');
  FEscBreak := TYamlRegEx.SeqOf(TYamlRegEx.Ch(Ord('\')), FBreak);
  FChompIndicator := TYamlRegEx.Str('+-', True);
  FChomp := TYamlRegEx.OrOf(TYamlRegEx.OrOf(TYamlRegEx.OrOf(
    TYamlRegEx.SeqOf(FChompIndicator, FDigit), TYamlRegEx.SeqOf(FDigit, FChompIndicator)),
    FChompIndicator), FDigit);
  FSingleQuoteEnd := TYamlRegEx.AndOf(TYamlRegEx.Ch(Ord('''')), TYamlRegEx.NotOf(FEscSingleQuote));
  FDoubleQuoteEnd := TYamlRegEx.Ch(Ord('"'));
end;

class function TYamlExp.ParseHex(const AText: TYamlText; const AMark: TYamlMark): Cardinal;
var
  I, LDigit: Integer;
  C: Byte;
begin
  Result := 0;
  for I := 1 to Length(AText) do
  begin
    C := Byte(AText[I]);
    if (C >= Ord('a')) and (C <= Ord('f')) then
      LDigit := C - Ord('a') + 10
    else if (C >= Ord('A')) and (C <= Ord('F')) then
      LDigit := C - Ord('A') + 10
    else if (C >= Ord('0')) and (C <= Ord('9')) then
      LDigit := C - Ord('0')
    else
      raise EYamlParserException.Create(AMark, SYamlInvalidHex);
    Result := (Result shl 4) + Cardinal(LDigit);
  end;
end;

class function TYamlExp.EscapeCode(AStream: TYamlStream; ACodeLength: Integer): TYamlText;

  function Str(AValue: Cardinal): TYamlText;
  begin
    SetLength(Result, 1);
    Result[1] := AnsiChar(Byte(AValue));
  end;

var
  LText: TYamlText;
  LValue: Cardinal;
  I: Integer;
begin
  LText := '';
  for I := 1 to ACodeLength do
    LText := LText + AnsiChar(AStream.Get);
  LValue := ParseHex(LText, AStream.Mark);
  if ((LValue >= $D800) and (LValue <= $DFFF)) or (LValue > $10FFFF) then
    raise EYamlParserException.Create(AStream.Mark, SYamlInvalidUnicode + TYamlText(UIntToStr(LValue)));
  if LValue <= $7F then
    Exit(Str(LValue));
  if LValue <= $7FF then
    Exit(Str($C0 + (LValue shr 6)) + Str($80 + (LValue and $3F)));
  if LValue <= $FFFF then
    Exit(Str($E0 + (LValue shr 12)) + Str($80 + ((LValue shr 6) and $3F)) + Str($80 + (LValue and $3F)));
  Result := Str($F0 + (LValue shr 18)) + Str($80 + ((LValue shr 12) and $3F)) +
    Str($80 + ((LValue shr 6) and $3F)) + Str($80 + (LValue and $3F));
end;

class function TYamlExp.Escape(AStream: TYamlStream): TYamlText;
var
  LEscape, LChar: Byte;
begin
  LEscape := AStream.Get;
  LChar := AStream.Get;
  if (LEscape = Ord('''')) and (LChar = Ord('''')) then
    Exit('''');
  case LChar of
    Ord('0'): Result := #0;
    Ord('a'): Result := #7;
    Ord('b'): Result := #8;
    Ord('t'), 9: Result := #9;
    Ord('n'): Result := #10;
    Ord('v'): Result := #11;
    Ord('f'): Result := #12;
    Ord('r'): Result := #13;
    Ord('e'): Result := #27;
    Ord(' '): Result := ' ';
    Ord('"'): Result := '"';
    Ord(''''): Result := '''';
    Ord('\'): Result := '\';
    Ord('/'): Result := '/';
    Ord('N'): Result := YamlBytes([$85]);
    Ord('_'): Result := YamlBytes([$A0]);
    Ord('L'): Result := YamlBytes([$E2, $80, $A8]);
    Ord('P'): Result := YamlBytes([$E2, $80, $A9]);
    Ord('x'): Result := EscapeCode(AStream, 2);
    Ord('u'): Result := EscapeCode(AStream, 4);
    Ord('U'): Result := EscapeCode(AStream, 8);
  else
    raise EYamlParserException.Create(AStream.Mark, SYamlInvalidEscape + AnsiChar(LChar));
  end;
end;

end.
