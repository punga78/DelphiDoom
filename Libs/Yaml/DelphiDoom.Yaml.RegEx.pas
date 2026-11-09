{******************************************************************************}
{                                                                              }
{  DelphiDoom: yaml library - the small regular expressions of the scanner     }
{  Port of yaml-cpp 0.7.0 (MIT, Jesse Beder): see Libs\Yaml\README.md          }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Yaml.RegEx;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  DelphiDoom.Yaml.Types,
  DelphiDoom.Yaml.Stream;

type
  /// <summary>
  ///   The text a regular expression is matched against: the stream of the scanner (StreamCharSource; the
  ///   end of the input is the char $04) or a plain byte string (StringCharSource; reading past the end gives
  ///   zeros like the terminator of c_str())
  /// </summary>
  TYamlCharSource = record
  strict private
    FStream: TYamlStream;
    FText: TYamlText;
    FOffset: Integer;
  public
    class function FromStream(AStream: TYamlStream): TYamlCharSource; static;
    class function FromText(const AText: TYamlText): TYamlCharSource; static;
    /// <summary>operator bool</summary>
    function IsValid: Boolean;
    /// <summary>operator[]</summary>
    function At(AIndex: Integer): Byte;
    /// <summary>operator+: a source AOffset chars further (never before the start)</summary>
    function Plus(AOffset: Integer): TYamlCharSource;
    function IsStream: Boolean;
    /// <summary>operator++</summary>
    procedure Advance;
    property Offset: Integer read FOffset;
  end;

  /// <summary>
  ///   YAML::RegEx: an expression tree (empty, one char, a range, or, and, not, sequence). The nodes are shared
  ///   and never change; they are all owned by the class and freed with it
  /// </summary>
  TYamlRegEx = class
  strict private
    type
      TOp = (opEmpty, opMatch, opRange, opOr, opAnd, opNot, opSeq);
    class var FRegistry: TObjectList<TYamlRegEx>;
  strict private
    FOp: TOp;
    FA: Byte;
    FZ: Byte;
    FParams: TArray<TYamlRegEx>;
    constructor Create(AOp: TOp);
    function MatchUnchecked(const ASource: TYamlCharSource): Integer;
    function IsValidSource(const ASource: TYamlCharSource): Boolean;
    class function Track(AExpression: TYamlRegEx): TYamlRegEx; static;
  public
    class constructor CreateClass;
    class destructor DestroyClass;
    /// <summary>RegEx(): the empty expression</summary>
    class function Empty: TYamlRegEx; static;
    /// <summary>RegEx(ch)</summary>
    class function Ch(AChar: Byte): TYamlRegEx; static;
    /// <summary>RegEx(a, z)</summary>
    class function Range(AFirst, ALast: Byte): TYamlRegEx; static;
    /// <summary>RegEx("abc") (a sequence) or RegEx("abc", REGEX_OR) (any of the chars)</summary>
    class function Str(const AText: TYamlText; AAnyOf: Boolean = False): TYamlRegEx; static;
    class function NotOf(AExpression: TYamlRegEx): TYamlRegEx; static;
    class function OrOf(ALeft, ARight: TYamlRegEx): TYamlRegEx; static;
    class function AndOf(ALeft, ARight: TYamlRegEx): TYamlRegEx; static;
    class function SeqOf(ALeft, ARight: TYamlRegEx): TYamlRegEx; static;
    /// <summary>Match(): the length matched or -1</summary>
    function Match(const ASource: TYamlCharSource): Integer; overload;
    function Match(AStream: TYamlStream): Integer; overload;
    function Match(const AText: TYamlText): Integer; overload;
    function Matches(const ASource: TYamlCharSource): Boolean; overload;
    function Matches(AStream: TYamlStream): Boolean; overload;
    function Matches(const AText: TYamlText): Boolean; overload;
    function Matches(AChar: Byte): Boolean; overload;
  end;

implementation

{ TYamlCharSource }

class function TYamlCharSource.FromStream(AStream: TYamlStream): TYamlCharSource;
begin
  Result.FStream := AStream;
  Result.FText := '';
  Result.FOffset := 0;
end;

class function TYamlCharSource.FromText(const AText: TYamlText): TYamlCharSource;
begin
  Result.FStream := nil;
  Result.FText := AText;
  Result.FOffset := 0;
end;

function TYamlCharSource.IsStream: Boolean;
begin
  Result := Assigned(FStream);
end;

function TYamlCharSource.IsValid: Boolean;
begin
  if Assigned(FStream) then
    Result := FStream.ReadAheadTo(FOffset)
  else
    Result := FOffset < Length(FText);
end;

function TYamlCharSource.At(AIndex: Integer): Byte;
begin
  if Assigned(FStream) then
    Result := FStream.CharAt(FOffset + AIndex)
  else if FOffset + AIndex < Length(FText) then
    Result := Byte(FText[FOffset + AIndex + 1])
  else
    Result := 0;
end;

function TYamlCharSource.Plus(AOffset: Integer): TYamlCharSource;
begin
  Result := Self;
  if FOffset + AOffset >= 0 then
    Result.FOffset := FOffset + AOffset
  else
    Result.FOffset := 0;
end;

procedure TYamlCharSource.Advance;
begin
  Inc(FOffset);
end;

{ TYamlRegEx }

class constructor TYamlRegEx.CreateClass;
begin
  FRegistry := TObjectList<TYamlRegEx>.Create(True);
end;

class destructor TYamlRegEx.DestroyClass;
begin
  FRegistry.Free;
end;

constructor TYamlRegEx.Create(AOp: TOp);
begin
  inherited Create;
  FOp := AOp;
end;

class function TYamlRegEx.Track(AExpression: TYamlRegEx): TYamlRegEx;
begin
  FRegistry.Add(AExpression);
  Result := AExpression;
end;

class function TYamlRegEx.Empty: TYamlRegEx;
begin
  Result := Track(TYamlRegEx.Create(opEmpty));
end;

class function TYamlRegEx.Ch(AChar: Byte): TYamlRegEx;
begin
  Result := Track(TYamlRegEx.Create(opMatch));
  Result.FA := AChar;
end;

class function TYamlRegEx.Range(AFirst, ALast: Byte): TYamlRegEx;
begin
  Result := Track(TYamlRegEx.Create(opRange));
  Result.FA := AFirst;
  Result.FZ := ALast;
end;

class function TYamlRegEx.Str(const AText: TYamlText; AAnyOf: Boolean): TYamlRegEx;
var
  I: Integer;
begin
  if AAnyOf then
    Result := Track(TYamlRegEx.Create(opOr))
  else
    Result := Track(TYamlRegEx.Create(opSeq));
  SetLength(Result.FParams, Length(AText));
  for I := 1 to Length(AText) do
    Result.FParams[I - 1] := Ch(Byte(AText[I]));
end;

class function TYamlRegEx.NotOf(AExpression: TYamlRegEx): TYamlRegEx;
begin
  Result := Track(TYamlRegEx.Create(opNot));
  Result.FParams := [AExpression];
end;

class function TYamlRegEx.OrOf(ALeft, ARight: TYamlRegEx): TYamlRegEx;
begin
  Result := Track(TYamlRegEx.Create(opOr));
  Result.FParams := [ALeft, ARight];
end;

class function TYamlRegEx.AndOf(ALeft, ARight: TYamlRegEx): TYamlRegEx;
begin
  Result := Track(TYamlRegEx.Create(opAnd));
  Result.FParams := [ALeft, ARight];
end;

class function TYamlRegEx.SeqOf(ALeft, ARight: TYamlRegEx): TYamlRegEx;
begin
  Result := Track(TYamlRegEx.Create(opSeq));
  Result.FParams := [ALeft, ARight];
end;

function TYamlRegEx.IsValidSource(const ASource: TYamlCharSource): Boolean;
begin
  if ASource.IsStream then
    Exit(ASource.IsValid);
  case FOp of
    opMatch, opRange: Result := ASource.IsValid;
  else
    Result := True;
  end;
end;

function TYamlRegEx.Match(const ASource: TYamlCharSource): Integer;
begin
  if IsValidSource(ASource) then
    Result := MatchUnchecked(ASource)
  else
    Result := -1;
end;

function TYamlRegEx.MatchUnchecked(const ASource: TYamlCharSource): Integer;
var
  LParam: TYamlRegEx;
  I, N, LOffset, LFirst: Integer;
begin
  Result := -1;
  case FOp of
    opEmpty:
      if ASource.IsStream then
      begin
        if ASource.At(0) = TYamlStream.EofChar then
          Result := 0;
      end
      else if not ASource.IsValid then
        Result := 0;
    opMatch:
      if ASource.At(0) = FA then
        Result := 1;
    opRange:
      if not ((FA > ASource.At(0)) or (FZ < ASource.At(0))) then
        Result := 1;
    opOr:
      for LParam in FParams do
      begin
        N := LParam.MatchUnchecked(ASource);
        if N >= 0 then
          Exit(N);
      end;
    opAnd:
      begin
        LFirst := -1;
        for I := 0 to High(FParams) do
        begin
          N := FParams[I].MatchUnchecked(ASource);
          if N = -1 then
            Exit(-1);
          if I = 0 then
            LFirst := N;
        end;
        Result := LFirst;
      end;
    opNot:
      begin
        if Length(FParams) = 0 then
          Exit(-1);
        if FParams[0].MatchUnchecked(ASource) >= 0 then
          Exit(-1);
        Result := 1;
      end;
    opSeq:
      begin
        LOffset := 0;
        for LParam in FParams do
        begin
          N := LParam.Match(ASource.Plus(LOffset));
          if N = -1 then
            Exit(-1);
          Inc(LOffset, N);
        end;
        Result := LOffset;
      end;
  end;
end;

function TYamlRegEx.Match(AStream: TYamlStream): Integer;
begin
  Result := Match(TYamlCharSource.FromStream(AStream));
end;

function TYamlRegEx.Match(const AText: TYamlText): Integer;
begin
  Result := Match(TYamlCharSource.FromText(AText));
end;

function TYamlRegEx.Matches(const ASource: TYamlCharSource): Boolean;
begin
  Result := Match(ASource) >= 0;
end;

function TYamlRegEx.Matches(AStream: TYamlStream): Boolean;
begin
  Result := Match(AStream) >= 0;
end;

function TYamlRegEx.Matches(const AText: TYamlText): Boolean;
begin
  Result := Match(AText) >= 0;
end;

function TYamlRegEx.Matches(AChar: Byte): Boolean;
var
  LText: TYamlText;
begin
  SetLength(LText, 1);
  LText[1] := AnsiChar(AChar);
  Result := Matches(LText);
end;

end.
