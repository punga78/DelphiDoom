{******************************************************************************}
{                                                                              }
{  DelphiDoom: yaml library - reading the documents of a text one by one       }
{  Port of yaml-cpp 0.7.0 (MIT, Jesse Beder): see Libs\Yaml\README.md          }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Yaml.DocumentParser;

interface

uses
  System.SysUtils,
  DelphiDoom.Yaml.Types,
  DelphiDoom.Yaml.Intf,
  DelphiDoom.Yaml.Stream,
  DelphiDoom.Yaml.Token,
  DelphiDoom.Yaml.Scanner,
  DelphiDoom.Yaml.Directives,
  DelphiDoom.Yaml.SingleDocParser;

type
  /// <summary>YAML::Parser: the directives and the documents of a text</summary>
  TYamlDocumentParser = class
  strict private
    FScanner: TYamlScanner;
    FDirectives: TYamlDirectives;
    FStuck: Boolean;
    procedure ParseDirectives;
    procedure HandleDirective(AToken: TYamlToken);
    procedure HandleYamlDirective(AToken: TYamlToken);
    procedure HandleTagDirective(AToken: TYamlToken);
  public
    /// <summary>The parser reads the UTF-8, UTF-16 or UTF-32 bytes of AInput</summary>
    constructor Create(const AInput: TBytes);
    destructor Destroy; override;
    /// <summary>False when there are no more documents</summary>
    function HandleNextDocument(const AHandler: IYamlEventHandler): Boolean;
    /// <summary>
    ///   The last document ended on the token it started with: the next one would be the same (yaml-cpp reads
    ///   them for ever, see EYamlEndlessDocumentsException)
    /// </summary>
    property Stuck: Boolean read FStuck;
  end;

implementation

type
  // The std::stringstream reading of "%d.%d" of the version
  TVersionReader = record
    Text: TYamlText;
    Pos: Integer;
    Failed: Boolean;
    function ReadInt(out AValue: Integer): Boolean;
  end;

function TVersionReader.ReadInt(out AValue: Integer): Boolean;
var
  LNegative: Boolean;
  LStart: Integer;
  LValue: Int64;
begin
  AValue := 0;
  Result := False;
  // operator>> skips the leading white space
  while (Pos <= Length(Text)) and ((Text[Pos] = ' ') or ((Text[Pos] >= #9) and (Text[Pos] <= #13))) do
    Inc(Pos);
  LNegative := False;
  if (Pos <= Length(Text)) and ((Text[Pos] = '-') or (Text[Pos] = '+')) then
  begin
    LNegative := Text[Pos] = '-';
    Inc(Pos);
  end;
  LStart := Pos;
  LValue := 0;
  while (Pos <= Length(Text)) and (Text[Pos] >= '0') and (Text[Pos] <= '9') do
  begin
    if LValue <= $7FFFFFFFFF then
      LValue := LValue * 10 + (Ord(Text[Pos]) - Ord('0'));
    Inc(Pos);
  end;
  if Pos = LStart then
  begin
    Failed := True;
    Exit;
  end;
  if LNegative then
    LValue := -LValue;
  if (LValue > High(Integer)) or (LValue < Low(Integer)) then
  begin
    Failed := True;
    Exit;
  end;
  AValue := Integer(LValue);
  Result := True;
end;

{ TYamlDocumentParser }

constructor TYamlDocumentParser.Create(const AInput: TBytes);
begin
  inherited Create;
  FScanner := TYamlScanner.Create(TYamlStream.Create(AInput));
  FDirectives := TYamlDirectives.Create;
end;

destructor TYamlDocumentParser.Destroy;
begin
  FDirectives.Free;
  FScanner.Free;
  inherited Destroy;
end;

function TYamlDocumentParser.HandleNextDocument(const AHandler: IYamlEventHandler): Boolean;
var
  LParser: TYamlSingleDocParser;
  LFront: TYamlToken;
begin
  ParseDirectives;
  if FScanner.Empty then
    Exit(False);
  LFront := FScanner.Peek;
  LParser := TYamlSingleDocParser.Create(FScanner, FDirectives);
  try
    LParser.HandleDocument(AHandler);
  finally
    LParser.Free;
  end;
  FStuck := (not FScanner.Empty) and (FScanner.Peek = LFront);
  Result := True;
end;

procedure TYamlDocumentParser.ParseDirectives;
var
  LReadDirective: Boolean;
  LToken: TYamlToken;
begin
  LReadDirective := False;
  while not FScanner.Empty do
  begin
    LToken := FScanner.Peek;
    if LToken.TokenType <> ttDirective then
      Break;
    // we keep the directives from the last document if none are specified; but if any directives are specific to
    // this document, then reset them
    if not LReadDirective then
    begin
      FDirectives.Free;
      FDirectives := TYamlDirectives.Create;
    end;
    LReadDirective := True;
    HandleDirective(LToken);
    FScanner.Pop;
  end;
end;

procedure TYamlDocumentParser.HandleDirective(AToken: TYamlToken);
begin
  if AToken.Value = 'YAML' then
    HandleYamlDirective(AToken)
  else if AToken.Value = 'TAG' then
    HandleTagDirective(AToken);
end;

procedure TYamlDocumentParser.HandleYamlDirective(AToken: TYamlToken);
var
  LReader: TVersionReader;
  LMajor, LMinor: Integer;
begin
  if Length(AToken.Params) <> 1 then
    raise EYamlParserException.Create(AToken.Mark, SYamlDirectiveArgs);
  if not FDirectives.VersionIsDefault then
    raise EYamlParserException.Create(AToken.Mark, SYamlRepeatedDirective);
  // str >> major; str.get(); str >> minor; if (!str || str.peek() != EOF) error
  LReader.Text := AToken.Params[0];
  LReader.Pos := 1;
  LReader.Failed := False;
  LMajor := 0;
  LMinor := 0;
  LReader.ReadInt(LMajor);
  if (not LReader.Failed) then
  begin
    // str.get(): one char of any kind
    if LReader.Pos <= Length(LReader.Text) then
      Inc(LReader.Pos)
    else
      LReader.Failed := True;
  end;
  if not LReader.Failed then
    LReader.ReadInt(LMinor);
  if LReader.Failed or (LReader.Pos <= Length(LReader.Text)) then
    raise EYamlParserException.Create(AToken.Mark, SYamlVersion + AToken.Params[0]);
  FDirectives.VersionMajor := LMajor;
  FDirectives.VersionMinor := LMinor;
  if FDirectives.VersionMajor > 1 then
    raise EYamlParserException.Create(AToken.Mark, SYamlMajorVersion);
  FDirectives.VersionIsDefault := False;
end;

procedure TYamlDocumentParser.HandleTagDirective(AToken: TYamlToken);
begin
  if Length(AToken.Params) <> 2 then
    raise EYamlParserException.Create(AToken.Mark, SYamlTagDirectiveArgs);
  if FDirectives.HasTag(AToken.Params[0]) then
    raise EYamlParserException.Create(AToken.Mark, SYamlRepeatedTagDirective);
  FDirectives.SetTag(AToken.Params[0], AToken.Params[1]);
end;

end.
