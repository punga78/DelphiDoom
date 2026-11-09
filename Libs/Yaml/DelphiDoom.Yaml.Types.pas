{******************************************************************************}
{                                                                              }
{  DelphiDoom: yaml library - shared types, error messages and exceptions      }
{  Port of yaml-cpp 0.7.0 (MIT, Jesse Beder): see Libs\Yaml\README.md          }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Yaml.Types;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   The text of yaml-cpp is a byte string (std::string holding UTF-8 or any other bytes): one Delphi
  ///   byte per C++ char, no code page conversions
  /// </summary>
  TYamlText = RawByteString;

  /// <summary>A position in the input (YAML::Mark): zero based line and column, pos in bytes</summary>
  TYamlMark = record
    Pos: Integer;
    Line: Integer;
    Column: Integer;
    /// <summary>Mark::null_mark(): all fields -1</summary>
    class function NullMark: TYamlMark; static;
    /// <summary>The default Mark(): all fields 0</summary>
    class function Zero: TYamlMark; static;
    function IsNull: Boolean;
  end;

  /// <summary>NodeType::value</summary>
  TYamlNodeType = (ntUndefined, ntNull, ntScalar, ntSequence, ntMap);

  /// <summary>EmitterStyle::value</summary>
  TYamlEmitterStyle = (esDefault, esBlock, esFlow);

  /// <summary>EMITTER_MANIP: the manipulators of the emitter (in the same order as yaml-cpp)</summary>
  TYamlManip = (
    ymAuto, ymTagByKind, ymNewline, ymEmitNonAscii, ymEscapeNonAscii, ymEscapeAsJson,
    ymSingleQuoted, ymDoubleQuoted, ymLiteral, ymLowerNull, ymUpperNull, ymCamelNull, ymTildeNull,
    ymYesNoBool, ymTrueFalseBool, ymOnOffBool, ymUpperCase, ymLowerCase, ymCamelCase, ymLongBool,
    ymShortBool, ymDec, ymHex, ymOct, ymBeginDoc, ymEndDoc, ymBeginSeq, ymEndSeq, ymFlow, ymBlock,
    ymBeginMap, ymEndMap, ymKey, ymValue, ymLongKey);

  /// <summary>The identity of an anchor in the events (anchor_t); 0 is "no anchor"</summary>
  TYamlAnchor = NativeUInt;

const
  YAML_NULL_ANCHOR: TYamlAnchor = 0;

  // ErrorMsg:: of yaml-cpp, the same texts
  SYamlDirectiveArgs: TYamlText = 'YAML directives must have exactly one argument';
  SYamlVersion: TYamlText = 'bad YAML version: ';
  SYamlMajorVersion: TYamlText = 'YAML major version too large';
  SYamlRepeatedDirective: TYamlText = 'repeated YAML directive';
  SYamlTagDirectiveArgs: TYamlText = 'TAG directives must have exactly two arguments';
  SYamlRepeatedTagDirective: TYamlText = 'repeated TAG directive';
  SYamlCharInTagHandle: TYamlText = 'illegal character found while scanning tag handle';
  SYamlTagWithNoSuffix: TYamlText = 'tag handle with no suffix';
  SYamlEndOfVerbatimTag: TYamlText = 'end of verbatim tag not found';
  SYamlEndOfMap: TYamlText = 'end of map not found';
  SYamlEndOfMapFlow: TYamlText = 'end of map flow not found';
  SYamlEndOfSeq: TYamlText = 'end of sequence not found';
  SYamlEndOfSeqFlow: TYamlText = 'end of sequence flow not found';
  SYamlMultipleTags: TYamlText = 'cannot assign multiple tags to the same node';
  SYamlMultipleAnchors: TYamlText = 'cannot assign multiple anchors to the same node';
  SYamlInvalidHex: TYamlText = 'bad character found while scanning hex number';
  SYamlInvalidUnicode: TYamlText = 'invalid unicode: ';
  SYamlInvalidEscape: TYamlText = 'unknown escape character: ';
  SYamlUnknownToken: TYamlText = 'unknown token';
  SYamlDocInScalar: TYamlText = 'illegal document indicator in scalar';
  SYamlEofInScalar: TYamlText = 'illegal EOF in scalar';
  SYamlTabInIndentation: TYamlText = 'illegal tab when looking for indentation';
  SYamlFlowEnd: TYamlText = 'illegal flow end';
  SYamlBlockEntry: TYamlText = 'illegal block entry';
  SYamlMapKey: TYamlText = 'illegal map key';
  SYamlMapValue: TYamlText = 'illegal map value';
  SYamlAliasNotFound: TYamlText = 'alias not found after *';
  SYamlAnchorNotFound: TYamlText = 'anchor not found after &';
  SYamlCharInAlias: TYamlText = 'illegal character found while scanning alias';
  SYamlCharInAnchor: TYamlText = 'illegal character found while scanning anchor';
  SYamlZeroIndentInBlock: TYamlText = 'cannot set zero indentation for a block scalar';
  SYamlCharInBlock: TYamlText = 'unexpected character in block scalar';
  SYamlUnknownAnchor: TYamlText = 'the referenced anchor is not defined';
  SYamlInvalidNode: TYamlText =
    'invalid node; this may result from using a map iterator as a sequence iterator, or vice-versa';
  SYamlInvalidScalar: TYamlText = 'invalid scalar';
  SYamlKeyNotFound: TYamlText = 'key not found';
  SYamlBadConversion: TYamlText = 'bad conversion';
  SYamlBadDereference: TYamlText = 'bad dereference';
  SYamlBadSubscript: TYamlText = 'operator[] call on a scalar';
  SYamlBadPushback: TYamlText = 'appending to a non-sequence';
  SYamlBadInsert: TYamlText = 'inserting in a non-convertible-to-map';
  SYamlUnmatchedGroupTag: TYamlText = 'unmatched group tag';
  SYamlUnexpectedEndSeq: TYamlText = 'unexpected end sequence token';
  SYamlUnexpectedEndMap: TYamlText = 'unexpected end map token';
  SYamlInvalidAnchor: TYamlText = 'invalid anchor';
  SYamlInvalidAlias: TYamlText = 'invalid alias';
  SYamlInvalidTag: TYamlText = 'invalid tag';
  SYamlBadFile: TYamlText = 'bad file';

type
  /// <summary>YAML::Exception: a message and the position it refers to</summary>
  EYamlException = class(Exception)
  strict private
    FMark: TYamlMark;
    FMsg: TYamlText;
  public
    constructor Create(const AMark: TYamlMark; const AMsg: TYamlText);
    /// <summary>Where (Exception::mark; the null mark when there is no position)</summary>
    property Mark: TYamlMark read FMark;
    /// <summary>The bare message in bytes (Exception::msg), without "yaml-cpp: error at ..."</summary>
    property Msg: TYamlText read FMsg;
  end;

  /// <summary>ParserException: bad input text</summary>
  EYamlParserException = class(EYamlException);

  /// <summary>DeepRecursion: a document nested more than 500 levels</summary>
  EYamlDeepRecursion = class(EYamlParserException)
  strict private
    FDepth: Integer;
  public
    constructor Create(ADepth: Integer; const AMark: TYamlMark; const AMsg: TYamlText);
    property Depth: Integer read FDepth;
  end;

  /// <summary>RepresentationException: a node used in a way it does not support</summary>
  EYamlRepresentationException = class(EYamlException);

  EYamlInvalidScalar = class(EYamlRepresentationException);
  EYamlKeyNotFound = class(EYamlRepresentationException);
  EYamlInvalidNode = class(EYamlRepresentationException);
  EYamlBadConversion = class(EYamlRepresentationException);
  EYamlBadDereference = class(EYamlRepresentationException);
  EYamlBadSubscript = class(EYamlRepresentationException);
  EYamlBadPushback = class(EYamlRepresentationException);
  EYamlBadInsert = class(EYamlRepresentationException);
  /// <summary>EmitterException</summary>
  EYamlEmitterException = class(EYamlException);
  /// <summary>BadFile: the file could not be read</summary>
  EYamlBadFile = class(EYamlException);

  /// <summary>
  ///   LoadAll on a text where a document ends without taking the token it stopped at (for example a text
  ///   that starts with a comma): yaml-cpp then reads empty documents for ever until std::bad_alloc is thrown
  ///   (an error that is not a YAML::Exception). The library stops at the first of them with this exception,
  ///   which is not an EYamlException either
  /// </summary>
  EYamlEndlessDocumentsException = class(Exception);

/// <summary>The message of an InvalidNode: with the key it was reached by when there is one</summary>
function YamlInvalidNodeMessage(const AKey: TYamlText): TYamlText;
/// <summary>KEY_NOT_FOUND_WITH_KEY for a string or numeric key</summary>
function YamlKeyNotFoundMessage(const AKey: TYamlText): TYamlText;
/// <summary>BAD_SUBSCRIPT_WITH_KEY for a string or numeric key</summary>
function YamlBadSubscriptMessage(const AKey: TYamlText): TYamlText;
/// <summary>A byte string made of exactly these bytes (a Delphi literal above #127 would be converted)</summary>
function YamlBytes(const ABytes: array of Byte): TYamlText;
/// <summary>Bytes to a Delphi string, reading them as UTF-8 (invalid bytes become U+FFFD)</summary>
function YamlTextToString(const AText: TYamlText): string;
/// <summary>A Delphi string to the UTF-8 bytes</summary>
function YamlStringToText(const AText: string): TYamlText;

implementation

{ TYamlMark }

class function TYamlMark.NullMark: TYamlMark;
begin
  Result.Pos := -1;
  Result.Line := -1;
  Result.Column := -1;
end;

class function TYamlMark.Zero: TYamlMark;
begin
  Result.Pos := 0;
  Result.Line := 0;
  Result.Column := 0;
end;

function TYamlMark.IsNull: Boolean;
begin
  Result := (Pos = -1) and (Line = -1) and (Column = -1);
end;

function YamlBytes(const ABytes: array of Byte): TYamlText;
begin
  SetLength(Result, Length(ABytes));
  if Length(ABytes) > 0 then
    Move(ABytes[0], Result[1], Length(ABytes));
end;

function YamlTextToString(const AText: TYamlText): string;
var
  LBytes: TBytes;
begin
  SetLength(LBytes, Length(AText));
  if Length(AText) > 0 then
    Move(AText[1], LBytes[0], Length(AText));
  Result := TEncoding.UTF8.GetString(LBytes);
end;

function YamlStringToText(const AText: string): TYamlText;
var
  LBytes: TBytes;
begin
  LBytes := TEncoding.UTF8.GetBytes(AText);
  SetLength(Result, Length(LBytes));
  if Length(LBytes) > 0 then
    Move(LBytes[0], Result[1], Length(LBytes));
end;

function BuildWhat(const AMark: TYamlMark; const AMsg: TYamlText): string;
begin
  if AMark.IsNull then
    Exit(YamlTextToString(AMsg));
  Result := Format('yaml-cpp: error at line %d, column %d: %s',
    [AMark.Line + 1, AMark.Column + 1, YamlTextToString(AMsg)]);
end;

function YamlInvalidNodeMessage(const AKey: TYamlText): TYamlText;
begin
  if AKey = '' then
    Exit(SYamlInvalidNode);
  Result := 'invalid node; first invalid key: "' + AKey + '"';
end;

function YamlKeyNotFoundMessage(const AKey: TYamlText): TYamlText;
begin
  Result := SYamlKeyNotFound + ': ' + AKey;
end;

function YamlBadSubscriptMessage(const AKey: TYamlText): TYamlText;
begin
  Result := SYamlBadSubscript + ' (key: "' + AKey + '")';
end;

{ EYamlException }

constructor EYamlException.Create(const AMark: TYamlMark; const AMsg: TYamlText);
begin
  inherited Create(BuildWhat(AMark, AMsg));
  FMark := AMark;
  FMsg := AMsg;
end;

{ EYamlDeepRecursion }

constructor EYamlDeepRecursion.Create(ADepth: Integer; const AMark: TYamlMark; const AMsg: TYamlText);
begin
  inherited Create(AMark, AMsg);
  FDepth := ADepth;
end;

end.
