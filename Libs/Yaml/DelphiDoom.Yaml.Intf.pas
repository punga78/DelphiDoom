{******************************************************************************}
{                                                                              }
{  DelphiDoom: yaml library - the interfaces                                   }
{  Port of yaml-cpp 0.7.0 (MIT, Jesse Beder): see Libs\Yaml\README.md          }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Yaml.Intf;

interface

uses
  System.SysUtils,
  DelphiDoom.Yaml.Types;

type
  IYamlNode = interface;

  /// <summary>A key and a value of a map (the value of the iterators over a map)</summary>
  TYamlPair = record
    Key: IYamlNode;
    Value: IYamlNode;
  end;

  /// <summary>EventHandler: what the parser tells while it reads a document</summary>
  IYamlEventHandler = interface
    ['{6F4B4E0C-3A52-4C4D-8E0B-2B6A5D1B9C01}']
    procedure OnDocumentStart(const AMark: TYamlMark);
    procedure OnDocumentEnd;
    procedure OnNull(const AMark: TYamlMark; AAnchor: TYamlAnchor);
    procedure OnAlias(const AMark: TYamlMark; AAnchor: TYamlAnchor);
    procedure OnScalar(const AMark: TYamlMark; const ATag: TYamlText; AAnchor: TYamlAnchor;
      const AValue: TYamlText);
    procedure OnSequenceStart(const AMark: TYamlMark; const ATag: TYamlText; AAnchor: TYamlAnchor;
      AStyle: TYamlEmitterStyle);
    procedure OnSequenceEnd;
    procedure OnMapStart(const AMark: TYamlMark; const ATag: TYamlText; AAnchor: TYamlAnchor;
      AStyle: TYamlEmitterStyle);
    procedure OnMapEnd;
    /// <summary>The name of an anchor (the default implementations do nothing)</summary>
    procedure OnAnchor(const AMark: TYamlMark; const AAnchorName: TYamlText);
  end;

  /// <summary>
  ///   YAML::Node. A handle with the reference semantics of yaml-cpp: two handles can be the same node (an
  ///   alias, or after Assign), and a node can contain itself through an anchor. The memory of a node tree is
  ///   shared by the handles that can reach it (and freed with the last one), so a document that contains itself
  ///   is fine as long as nobody walks it blindly. A handle made by Find on a missing key is "invalid": every
  ///   call except IsDefined raises EYamlInvalidNode. Text values are UTF-8 bytes (TYamlText)
  /// </summary>
  IYamlNode = interface
    ['{6F4B4E0C-3A52-4C4D-8E0B-2B6A5D1B9C02}']
    /// <summary>The node is defined (it is not a placeholder made by Child that nobody assigned yet)</summary>
    function IsDefined: Boolean;
    function NodeType: TYamlNodeType;
    function IsNull: Boolean;
    function IsScalar: Boolean;
    function IsSequence: Boolean;
    function IsMap: Boolean;
    /// <summary>Where the node was read (the null mark if it was not read from a text)</summary>
    function Mark: TYamlMark;
    /// <summary>The text of a scalar ('' for the others)</summary>
    function Scalar: TYamlText;
    /// <summary>The scalar as a Delphi string (UTF-8 decoded)</summary>
    function ScalarString: string;
    function Tag: TYamlText;
    procedure SetTag(const ATag: TYamlText);
    function Style: TYamlEmitterStyle;
    procedure SetStyle(AStyle: TYamlEmitterStyle);
    /// <summary>Number of defined elements of a sequence or defined pairs of a map; 0 for the other types</summary>
    function Size: Integer;
    /// <summary>The two handles are the same node</summary>
    function SameNode(const AOther: IYamlNode): Boolean;
    /// <summary>The elements of a sequence (including not yet defined ones, as the iterator does)</summary>
    function Items: TArray<IYamlNode>;
    /// <summary>The defined pairs of a map</summary>
    function Pairs: TArray<TYamlPair>;
    /// <summary>
    ///   node[key] on a node that can change: the entry is created undefined when it is not there (and defined
    ///   when something is assigned to it); a sequence indexed with a text becomes a map, and so on
    /// </summary>
    function Child(const AKey: TYamlText): IYamlNode; overload;
    function Child(AIndex: Integer): IYamlNode; overload;
    function Child(const AKey: IYamlNode): IYamlNode; overload;
    /// <summary>node[key] on a const node: an invalid handle when the key is not there</summary>
    function Find(const AKey: TYamlText): IYamlNode; overload;
    function Find(AIndex: Integer): IYamlNode; overload;
    function Find(const AKey: IYamlNode): IYamlNode; overload;
    /// <summary>push_back</summary>
    procedure Add(const AValue: IYamlNode); overload;
    procedure Add(const AValue: TYamlText); overload;
    function Remove(const AKey: TYamlText): Boolean; overload;
    function Remove(AIndex: Integer): Boolean; overload;
    function Remove(const AKey: IYamlNode): Boolean; overload;
    /// <summary>operator=(Node): this handle becomes the same node as AValue</summary>
    procedure Assign(const AValue: IYamlNode);
    /// <summary>operator=(string): the node becomes a scalar</summary>
    procedure AssignScalar(const AValue: TYamlText);
    /// <summary>operator=(Null)</summary>
    procedure AssignNull;
    /// <summary>The node takes the data (type, scalar, children) of AValue and stays another node</summary>
    procedure AssignData(const AValue: IYamlNode);
    /// <summary>reset(): the handle points to the node of AValue (no sharing of data with the old one)</summary>
    procedure Reset(const AValue: IYamlNode);
    /// <summary>force_insert(key, value): adds a pair without looking for the key</summary>
    procedure ForceInsert(const AKey, AValue: TYamlText);
    // as<T>(): bad conversions raise EYamlBadConversion
    function AsString: TYamlText; overload;
    function AsString(const ADefault: TYamlText): TYamlText; overload;
    function AsInteger: Integer; overload;
    function AsInteger(ADefault: Integer): Integer; overload;
    function AsCardinal: Cardinal; overload;
    function AsCardinal(ADefault: Cardinal): Cardinal; overload;
    function AsInt64: Int64; overload;
    function AsInt64(ADefault: Int64): Int64; overload;
    function AsUInt64: UInt64; overload;
    function AsUInt64(ADefault: UInt64): UInt64; overload;
    function AsSmallInt: SmallInt; overload;
    function AsSmallInt(ADefault: SmallInt): SmallInt; overload;
    function AsWord: Word; overload;
    function AsWord(ADefault: Word): Word; overload;
    function AsShortInt: ShortInt; overload;
    function AsShortInt(ADefault: ShortInt): ShortInt; overload;
    function AsByte: Byte; overload;
    function AsByte(ADefault: Byte): Byte; overload;
    /// <summary>as&lt;char&gt;: a one char scalar</summary>
    function AsChar: AnsiChar; overload;
    function AsChar(ADefault: AnsiChar): AnsiChar; overload;
    function AsDouble: Double; overload;
    function AsDouble(ADefault: Double): Double; overload;
    function AsSingle: Single; overload;
    function AsSingle(ADefault: Single): Single; overload;
    function AsBoolean: Boolean; overload;
    function AsBoolean(ADefault: Boolean): Boolean; overload;
    function TryAsInteger(out AValue: Integer): Boolean;
    function TryAsCardinal(out AValue: Cardinal): Boolean;
    function TryAsInt64(out AValue: Int64): Boolean;
    function TryAsUInt64(out AValue: UInt64): Boolean;
    function TryAsSmallInt(out AValue: SmallInt): Boolean;
    function TryAsWord(out AValue: Word): Boolean;
    function TryAsChar(out AValue: AnsiChar): Boolean;
    function TryAsDouble(out AValue: Double): Boolean;
    function TryAsSingle(out AValue: Single): Boolean;
    function TryAsBoolean(out AValue: Boolean): Boolean;
  end;

  /// <summary>Where the bytes of a file come from (so that the library does not touch the disk itself)</summary>
  IYamlFileSource = interface
    ['{6F4B4E0C-3A52-4C4D-8E0B-2B6A5D1B9C03}']
    /// <summary>False if the file cannot be read</summary>
    function TryReadAllBytes(const AFileName: string; out ABytes: TBytes): Boolean;
  end;

  /// <summary>YAML::Load, LoadAll, LoadFile and LoadAllFromFile</summary>
  IYamlParser = interface
    ['{6F4B4E0C-3A52-4C4D-8E0B-2B6A5D1B9C04}']
    /// <summary>The first document (an undefined null node for an empty text); EYamlParserException on errors</summary>
    function Load(const AText: TYamlText): IYamlNode; overload;
    function Load(const ABytes: TBytes): IYamlNode; overload;
    function LoadAll(const AText: TYamlText): TArray<IYamlNode>; overload;
    function LoadAll(const ABytes: TBytes): TArray<IYamlNode>; overload;
    /// <summary>EYamlBadFile when the file cannot be read</summary>
    function LoadFile(const AFileName: string): IYamlNode;
    function LoadAllFromFile(const AFileName: string): TArray<IYamlNode>;
  end;

  /// <summary>The kind of a tag written by the emitter (_Tag::Type)</summary>
  TYamlEmitterTagKind = (etVerbatim, etPrimaryHandle, etNamedHandle);

  /// <summary>YAML::Emitter: writes YAML text (UTF-8 bytes). The operations are the ones of the C++ class</summary>
  IYamlEmitter = interface
    ['{6F4B4E0C-3A52-4C4D-8E0B-2B6A5D1B9C05}']
    /// <summary>All the text written (c_str() cuts it at the first zero byte, this does not)</summary>
    function Text: TYamlText;
    function Size: Integer;
    function Good: Boolean;
    function LastError: TYamlText;
    function SetOutputCharset(AValue: TYamlManip): Boolean;
    function SetStringFormat(AValue: TYamlManip): Boolean;
    function SetBoolFormat(AValue: TYamlManip): Boolean;
    function SetNullFormat(AValue: TYamlManip): Boolean;
    function SetIntBase(AValue: TYamlManip): Boolean;
    function SetSeqFormat(AValue: TYamlManip): Boolean;
    function SetMapFormat(AValue: TYamlManip): Boolean;
    function SetIndent(AValue: NativeUInt): Boolean;
    function SetPreCommentIndent(AValue: NativeUInt): Boolean;
    function SetPostCommentIndent(AValue: NativeUInt): Boolean;
    function SetFloatPrecision(AValue: NativeUInt): Boolean;
    function SetDoublePrecision(AValue: NativeUInt): Boolean;
    procedure RestoreGlobalModifiedSettings;
    /// <summary>emitter &lt;&lt; manipulator (local effect; BeginSeq, EndMap, Newline... too)</summary>
    procedure Manip(AValue: TYamlManip);
    /// <summary>emitter &lt;&lt; Indent(n)</summary>
    procedure LocalIndent(AValue: Integer);
    /// <summary>emitter &lt;&lt; FloatPrecision(n), DoublePrecision(n) or Precision(n): a negative one is left alone</summary>
    procedure LocalPrecision(AFloatPrecision, ADoublePrecision: Integer);
    procedure WriteString(const AValue: TYamlText);
    procedure WriteBool(AValue: Boolean);
    procedure WriteChar(AValue: Byte);
    procedure WriteAlias(const AContent: TYamlText);
    procedure WriteAnchor(const AContent: TYamlText);
    procedure WriteTag(AKind: TYamlEmitterTagKind; const APrefix, AContent: TYamlText);
    procedure WriteComment(const AContent: TYamlText);
    procedure WriteNull;
    procedure WriteBinary(const AData: TBytes);
    procedure WriteInteger(AValue: Integer);
    procedure WriteCardinal(AValue: Cardinal);
    procedure WriteSmallInt(AValue: SmallInt);
    procedure WriteWord(AValue: Word);
    procedure WriteInt64(AValue: Int64);
    procedure WriteUInt64(AValue: UInt64);
    procedure WriteDouble(AValue: Double);
    procedure WriteSingle(AValue: Single);
    /// <summary>emitter &lt;&lt; node (anchors and aliases are made for the nodes shared in the tree)</summary>
    procedure WriteNode(const ANode: IYamlNode);
  end;

implementation

end.
