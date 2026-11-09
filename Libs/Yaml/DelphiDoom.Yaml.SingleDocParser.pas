{******************************************************************************}
{                                                                              }
{  DelphiDoom: yaml library - the parser of one document (tokens to events)    }
{  Port of yaml-cpp 0.7.0 (MIT, Jesse Beder): see Libs\Yaml\README.md          }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Yaml.SingleDocParser;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  DelphiDoom.Yaml.Types,
  DelphiDoom.Yaml.Intf,
  DelphiDoom.Yaml.Convert,
  DelphiDoom.Yaml.Token,
  DelphiDoom.Yaml.Scanner,
  DelphiDoom.Yaml.Directives;

type
  /// <summary>SingleDocParser: reads the tokens of one document and tells the events to a handler</summary>
  TYamlSingleDocParser = class
  strict private
    type
      TCollectionType = (ctNoCollection, ctBlockMap, ctBlockSeq, ctFlowMap, ctFlowSeq, ctCompactMap);
  strict private
    FDepth: Integer;
    FScanner: TYamlScanner;
    FDirectives: TYamlDirectives;
    FCollections: TStack<TCollectionType>;
    FAnchorNames: TList<TYamlText>;
    FAnchorIds: TList<TYamlAnchor>;
    FCurAnchor: TYamlAnchor;
    function CurCollectionType: TCollectionType;
    procedure HandleNode(const AHandler: IYamlEventHandler);
    procedure HandleSequence(const AHandler: IYamlEventHandler);
    procedure HandleBlockSequence(const AHandler: IYamlEventHandler);
    procedure HandleFlowSequence(const AHandler: IYamlEventHandler);
    procedure HandleMap(const AHandler: IYamlEventHandler);
    procedure HandleBlockMap(const AHandler: IYamlEventHandler);
    procedure HandleFlowMap(const AHandler: IYamlEventHandler);
    procedure HandleCompactMap(const AHandler: IYamlEventHandler);
    procedure HandleCompactMapWithNoKey(const AHandler: IYamlEventHandler);
    procedure ParseProperties(var ATag: TYamlText; var AAnchor: TYamlAnchor; var AAnchorName: TYamlText);
    procedure ParseTag(var ATag: TYamlText);
    procedure ParseAnchor(var AAnchor: TYamlAnchor; var AAnchorName: TYamlText);
    function RegisterAnchor(const AName: TYamlText): TYamlAnchor;
    function LookupAnchor(const AMark: TYamlMark; const AName: TYamlText): TYamlAnchor;
  public
    /// <summary>The scanner and the directives are not owned</summary>
    constructor Create(AScanner: TYamlScanner; ADirectives: TYamlDirectives);
    destructor Destroy; override;
    procedure HandleDocument(const AHandler: IYamlEventHandler);
  end;

implementation

const
  MaxDepth = 500;

constructor TYamlSingleDocParser.Create(AScanner: TYamlScanner; ADirectives: TYamlDirectives);
begin
  inherited Create;
  FScanner := AScanner;
  FDirectives := ADirectives;
  FCollections := TStack<TCollectionType>.Create;
  FAnchorNames := TList<TYamlText>.Create;
  FAnchorIds := TList<TYamlAnchor>.Create;
end;

destructor TYamlSingleDocParser.Destroy;
begin
  FAnchorIds.Free;
  FAnchorNames.Free;
  FCollections.Free;
  inherited Destroy;
end;

function TYamlSingleDocParser.CurCollectionType: TCollectionType;
begin
  if FCollections.Count = 0 then
    Result := ctNoCollection
  else
    Result := FCollections.Peek;
end;

procedure TYamlSingleDocParser.HandleDocument(const AHandler: IYamlEventHandler);
begin
  AHandler.OnDocumentStart(FScanner.Peek.Mark);
  if FScanner.Peek.TokenType = ttDocStart then
    FScanner.Pop;
  HandleNode(AHandler);
  AHandler.OnDocumentEnd;
  // and finally eat any doc ends we see
  while (not FScanner.Empty) and (FScanner.Peek.TokenType = ttDocEnd) do
    FScanner.Pop;
end;

procedure TYamlSingleDocParser.HandleNode(const AHandler: IYamlEventHandler);
var
  LMark: TYamlMark;
  LTag, LAnchorName: TYamlText;
  LAnchor: TYamlAnchor;
  LToken: TYamlToken;
begin
  // depth guard (DepthGuard<500>)
  Inc(FDepth);
  try
    if MaxDepth <= FDepth then
      raise EYamlDeepRecursion.Create(FDepth, FScanner.Mark, SYamlBadFile);

    // an empty node *is* a possibility
    if FScanner.Empty then
    begin
      AHandler.OnNull(FScanner.Mark, YAML_NULL_ANCHOR);
      Exit;
    end;

    // save location
    LMark := FScanner.Peek.Mark;

    // special case: a value node by itself must be a map, with no header
    if FScanner.Peek.TokenType = ttValue then
    begin
      AHandler.OnMapStart(LMark, '?', YAML_NULL_ANCHOR, esDefault);
      HandleMap(AHandler);
      AHandler.OnMapEnd;
      Exit;
    end;

    // special case: an alias node
    if FScanner.Peek.TokenType = ttAlias then
    begin
      AHandler.OnAlias(LMark, LookupAnchor(LMark, FScanner.Peek.Value));
      FScanner.Pop;
      Exit;
    end;

    LTag := '';
    LAnchorName := '';
    ParseProperties(LTag, LAnchor, LAnchorName);

    if LAnchorName <> '' then
      AHandler.OnAnchor(LMark, LAnchorName);

    // after parsing properties, an empty node is again a possibility
    if FScanner.Empty then
    begin
      AHandler.OnNull(LMark, LAnchor);
      Exit;
    end;

    LToken := FScanner.Peek;

    // add non-specific tags
    if LTag = '' then
    begin
      if LToken.TokenType = ttNonPlainScalar then
        LTag := '!'
      else
        LTag := '?';
    end;

    if (LToken.TokenType = ttPlainScalar) and (LTag = '?') and TYamlConvert.IsNullString(LToken.Value) then
    begin
      AHandler.OnNull(LMark, LAnchor);
      FScanner.Pop;
      Exit;
    end;

    // now split based on what kind of node we should be
    case LToken.TokenType of
      ttPlainScalar, ttNonPlainScalar:
        begin
          AHandler.OnScalar(LMark, LTag, LAnchor, LToken.Value);
          FScanner.Pop;
          Exit;
        end;
      ttFlowSeqStart:
        begin
          AHandler.OnSequenceStart(LMark, LTag, LAnchor, esFlow);
          HandleSequence(AHandler);
          AHandler.OnSequenceEnd;
          Exit;
        end;
      ttBlockSeqStart:
        begin
          AHandler.OnSequenceStart(LMark, LTag, LAnchor, esBlock);
          HandleSequence(AHandler);
          AHandler.OnSequenceEnd;
          Exit;
        end;
      ttFlowMapStart:
        begin
          AHandler.OnMapStart(LMark, LTag, LAnchor, esFlow);
          HandleMap(AHandler);
          AHandler.OnMapEnd;
          Exit;
        end;
      ttBlockMapStart:
        begin
          AHandler.OnMapStart(LMark, LTag, LAnchor, esBlock);
          HandleMap(AHandler);
          AHandler.OnMapEnd;
          Exit;
        end;
      ttKey:
        // compact maps can only go in a flow sequence
        if CurCollectionType = ctFlowSeq then
        begin
          AHandler.OnMapStart(LMark, LTag, LAnchor, esFlow);
          HandleMap(AHandler);
          AHandler.OnMapEnd;
          Exit;
        end;
    end;

    if LTag = '?' then
      AHandler.OnNull(LMark, LAnchor)
    else
      AHandler.OnScalar(LMark, LTag, LAnchor, '');
  finally
    Dec(FDepth);
  end;
end;

procedure TYamlSingleDocParser.HandleSequence(const AHandler: IYamlEventHandler);
begin
  // split based on start token
  case FScanner.Peek.TokenType of
    ttBlockSeqStart: HandleBlockSequence(AHandler);
    ttFlowSeqStart: HandleFlowSequence(AHandler);
  end;
end;

procedure TYamlSingleDocParser.HandleBlockSequence(const AHandler: IYamlEventHandler);
var
  LToken, LNext: TYamlToken;
begin
  // eat start token
  FScanner.Pop;
  FCollections.Push(ctBlockSeq);
  while True do
  begin
    if FScanner.Empty then
      raise EYamlParserException.Create(FScanner.Mark, SYamlEndOfSeq);
    LToken := FScanner.Peek;
    if (LToken.TokenType <> ttBlockEntry) and (LToken.TokenType <> ttBlockSeqEnd) then
      raise EYamlParserException.Create(LToken.Mark, SYamlEndOfSeq);
    FScanner.Pop;
    if LToken.TokenType = ttBlockSeqEnd then
      Break;
    // check for null
    if not FScanner.Empty then
    begin
      LNext := FScanner.Peek;
      if (LNext.TokenType = ttBlockEntry) or (LNext.TokenType = ttBlockSeqEnd) then
      begin
        AHandler.OnNull(LNext.Mark, YAML_NULL_ANCHOR);
        Continue;
      end;
    end;
    HandleNode(AHandler);
  end;
  FCollections.Pop;
end;

procedure TYamlSingleDocParser.HandleFlowSequence(const AHandler: IYamlEventHandler);
var
  LToken: TYamlToken;
begin
  // eat start token
  FScanner.Pop;
  FCollections.Push(ctFlowSeq);
  while True do
  begin
    if FScanner.Empty then
      raise EYamlParserException.Create(FScanner.Mark, SYamlEndOfSeqFlow);
    // first check for end
    if FScanner.Peek.TokenType = ttFlowSeqEnd then
    begin
      FScanner.Pop;
      Break;
    end;
    // then read the node
    HandleNode(AHandler);
    if FScanner.Empty then
      raise EYamlParserException.Create(FScanner.Mark, SYamlEndOfSeqFlow);
    // now eat the separator (or could be a sequence end, which we ignore - but if it's neither, then it's a bad node)
    LToken := FScanner.Peek;
    if LToken.TokenType = ttFlowEntry then
      FScanner.Pop
    else if LToken.TokenType <> ttFlowSeqEnd then
      raise EYamlParserException.Create(LToken.Mark, SYamlEndOfSeqFlow);
  end;
  FCollections.Pop;
end;

procedure TYamlSingleDocParser.HandleMap(const AHandler: IYamlEventHandler);
begin
  // split based on start token
  case FScanner.Peek.TokenType of
    ttBlockMapStart: HandleBlockMap(AHandler);
    ttFlowMapStart: HandleFlowMap(AHandler);
    ttKey: HandleCompactMap(AHandler);
    ttValue: HandleCompactMapWithNoKey(AHandler);
  end;
end;

procedure TYamlSingleDocParser.HandleBlockMap(const AHandler: IYamlEventHandler);
var
  LToken: TYamlToken;
begin
  // eat start token
  FScanner.Pop;
  FCollections.Push(ctBlockMap);
  while True do
  begin
    if FScanner.Empty then
      raise EYamlParserException.Create(FScanner.Mark, SYamlEndOfMap);
    LToken := FScanner.Peek;
    if (LToken.TokenType <> ttKey) and (LToken.TokenType <> ttValue) and (LToken.TokenType <> ttBlockMapEnd) then
      raise EYamlParserException.Create(LToken.Mark, SYamlEndOfMap);
    if LToken.TokenType = ttBlockMapEnd then
    begin
      FScanner.Pop;
      Break;
    end;
    // grab key (if non-null)
    if LToken.TokenType = ttKey then
    begin
      FScanner.Pop;
      HandleNode(AHandler);
    end
    else
      AHandler.OnNull(LToken.Mark, YAML_NULL_ANCHOR);
    // now grab value (optional)
    if (not FScanner.Empty) and (FScanner.Peek.TokenType = ttValue) then
    begin
      FScanner.Pop;
      HandleNode(AHandler);
    end
    else
      AHandler.OnNull(LToken.Mark, YAML_NULL_ANCHOR);
  end;
  FCollections.Pop;
end;

procedure TYamlSingleDocParser.HandleFlowMap(const AHandler: IYamlEventHandler);
var
  LToken, LNext: TYamlToken;
  LMark: TYamlMark;
begin
  // eat start token
  FScanner.Pop;
  FCollections.Push(ctFlowMap);
  while True do
  begin
    if FScanner.Empty then
      raise EYamlParserException.Create(FScanner.Mark, SYamlEndOfMapFlow);
    LToken := FScanner.Peek;
    LMark := LToken.Mark;
    // first check for end
    if LToken.TokenType = ttFlowMapEnd then
    begin
      FScanner.Pop;
      Break;
    end;
    // grab key (if non-null)
    if LToken.TokenType = ttKey then
    begin
      FScanner.Pop;
      HandleNode(AHandler);
    end
    else
      AHandler.OnNull(LMark, YAML_NULL_ANCHOR);
    // now grab value (optional)
    if (not FScanner.Empty) and (FScanner.Peek.TokenType = ttValue) then
    begin
      FScanner.Pop;
      HandleNode(AHandler);
    end
    else
      AHandler.OnNull(LMark, YAML_NULL_ANCHOR);
    if FScanner.Empty then
      raise EYamlParserException.Create(FScanner.Mark, SYamlEndOfMapFlow);
    // now eat the separator (or could be a map end, which we ignore - but if it's neither, then it's a bad node)
    LNext := FScanner.Peek;
    if LNext.TokenType = ttFlowEntry then
      FScanner.Pop
    else if LNext.TokenType <> ttFlowMapEnd then
      raise EYamlParserException.Create(LNext.Mark, SYamlEndOfMapFlow);
  end;
  FCollections.Pop;
end;

procedure TYamlSingleDocParser.HandleCompactMap(const AHandler: IYamlEventHandler);
var
  LMark: TYamlMark;
begin
  // single key/value pair
  FCollections.Push(ctCompactMap);
  LMark := FScanner.Peek.Mark;
  FScanner.Pop;
  HandleNode(AHandler);
  if (not FScanner.Empty) and (FScanner.Peek.TokenType = ttValue) then
  begin
    FScanner.Pop;
    HandleNode(AHandler);
  end
  else
    AHandler.OnNull(LMark, YAML_NULL_ANCHOR);
  FCollections.Pop;
end;

procedure TYamlSingleDocParser.HandleCompactMapWithNoKey(const AHandler: IYamlEventHandler);
begin
  FCollections.Push(ctCompactMap);
  // null key
  AHandler.OnNull(FScanner.Peek.Mark, YAML_NULL_ANCHOR);
  // grab value
  FScanner.Pop;
  HandleNode(AHandler);
  FCollections.Pop;
end;

procedure TYamlSingleDocParser.ParseProperties(var ATag: TYamlText; var AAnchor: TYamlAnchor;
  var AAnchorName: TYamlText);
begin
  ATag := '';
  AAnchorName := '';
  AAnchor := YAML_NULL_ANCHOR;
  while True do
  begin
    if FScanner.Empty then
      Exit;
    case FScanner.Peek.TokenType of
      ttTag: ParseTag(ATag);
      ttAnchor: ParseAnchor(AAnchor, AAnchorName);
    else
      Exit;
    end;
  end;
end;

procedure TYamlSingleDocParser.ParseTag(var ATag: TYamlText);
var
  LToken: TYamlToken;
  LInfo: TYamlTag;
begin
  LToken := FScanner.Peek;
  if ATag <> '' then
    raise EYamlParserException.Create(LToken.Mark, SYamlMultipleTags);
  LInfo := TYamlTag.FromToken(LToken);
  ATag := LInfo.Translate(FDirectives);
  FScanner.Pop;
end;

procedure TYamlSingleDocParser.ParseAnchor(var AAnchor: TYamlAnchor; var AAnchorName: TYamlText);
var
  LToken: TYamlToken;
begin
  LToken := FScanner.Peek;
  if AAnchor <> 0 then
    raise EYamlParserException.Create(LToken.Mark, SYamlMultipleAnchors);
  AAnchorName := LToken.Value;
  AAnchor := RegisterAnchor(LToken.Value);
  FScanner.Pop;
end;

function TYamlSingleDocParser.RegisterAnchor(const AName: TYamlText): TYamlAnchor;
var
  I: Integer;
begin
  if AName = '' then
    Exit(YAML_NULL_ANCHOR);
  Inc(FCurAnchor);
  Result := FCurAnchor;
  for I := 0 to FAnchorNames.Count - 1 do
    if FAnchorNames[I] = AName then
    begin
      FAnchorIds[I] := Result;
      Exit;
    end;
  FAnchorNames.Add(AName);
  FAnchorIds.Add(Result);
end;

function TYamlSingleDocParser.LookupAnchor(const AMark: TYamlMark; const AName: TYamlText): TYamlAnchor;
var
  I: Integer;
begin
  for I := 0 to FAnchorNames.Count - 1 do
    if FAnchorNames[I] = AName then
      Exit(FAnchorIds[I]);
  raise EYamlParserException.Create(AMark, SYamlUnknownAnchor);
end;

end.
