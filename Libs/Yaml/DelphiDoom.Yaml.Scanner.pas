{******************************************************************************}
{                                                                              }
{  DelphiDoom: yaml library - the scanner: characters to tokens               }
{  Port of yaml-cpp 0.7.0 (MIT, Jesse Beder): see Libs\Yaml\README.md          }
{  (scanner.cpp, scantoken.cpp and simplekey.cpp)                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Yaml.Scanner;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  DelphiDoom.Yaml.Types,
  DelphiDoom.Yaml.Stream,
  DelphiDoom.Yaml.RegEx,
  DelphiDoom.Yaml.Exp,
  DelphiDoom.Yaml.Token,
  DelphiDoom.Yaml.ScanScalar,
  DelphiDoom.Yaml.ScanTag,
  DelphiDoom.Yaml.Directives;

type
  /// <summary>
  ///   YAML::Scanner: turns the characters of a stream into tokens. Tokens and indent markers are owned by the
  ///   scanner until it is freed (the queue and the possible simple keys keep references to them)
  /// </summary>
  TYamlScanner = class
  strict private
    type
      TIndentType = (itMap, itSeq, itNone);
      TIndentStatus = (isValid, isInvalid, isUnknown);
      TFlowMarker = (fmMap, fmSeq);

      TIndentMarker = class
      public
        Column: Integer;
        IndentType: TIndentType;
        Status: TIndentStatus;
        StartToken: TYamlToken;
        constructor Create(AColumn: Integer; AType: TIndentType);
      end;

      TSimpleKey = record
        Mark: TYamlMark;
        FlowLevel: Integer;
        Indent: TIndentMarker;
        MapStart: TYamlToken;
        Key: TYamlToken;
        procedure Validate;
        procedure Invalidate;
      end;
  strict private
    FInput: TYamlStream;
    FTokens: TQueue<TYamlToken>;
    FAllTokens: TObjectList<TYamlToken>;
    FIndentRefs: TObjectList<TIndentMarker>;
    FStartedStream: Boolean;
    FEndedStream: Boolean;
    FSimpleKeyAllowed: Boolean;
    FCanBeJSONFlow: Boolean;
    FSimpleKeys: TStack<TSimpleKey>;
    FIndents: TStack<TIndentMarker>;
    FFlows: TStack<TFlowMarker>;
    function NewToken(AType: TYamlTokenType; const AMark: TYamlMark): TYamlToken;
    procedure Enqueue(AToken: TYamlToken);
    procedure EnsureTokensInQueue;
    procedure ScanNextToken;
    procedure ScanToNextToken;
    procedure StartStream;
    procedure EndStream;
    function PushToken(AType: TYamlTokenType): TYamlToken;
    function InFlowContext: Boolean;
    function InBlockContext: Boolean;
    function GetFlowLevel: Integer;
    function PushIndentTo(AColumn: Integer; AType: TIndentType): TIndentMarker;
    procedure PopIndentToHere;
    procedure PopAllIndents;
    procedure PopIndent;
    function GetTopIndent: Integer;
    function CanInsertPotentialSimpleKey: Boolean;
    function ExistsActiveSimpleKey: Boolean;
    procedure InsertPotentialSimpleKey;
    procedure InvalidateSimpleKey;
    function VerifySimpleKey: Boolean;
    procedure PopAllSimpleKeys;
    function GetValueRegex: TYamlRegEx;
    procedure ScanDirective;
    procedure ScanDocStart;
    procedure ScanDocEnd;
    procedure ScanBlockEntry;
    procedure ScanFlowStart;
    procedure ScanFlowEnd;
    procedure ScanFlowEntry;
    procedure ScanKey;
    procedure ScanValue;
    procedure ScanAnchorOrAlias;
    procedure ScanTag;
    procedure ScanPlainScalar;
    procedure ScanQuotedScalar;
    procedure ScanBlockScalar;
  public
    /// <summary>The scanner owns AInput</summary>
    constructor Create(AInput: TYamlStream);
    destructor Destroy; override;
    /// <summary>True if there are no more tokens</summary>
    function Empty: Boolean;
    /// <summary>Removes the next token</summary>
    procedure Pop;
    /// <summary>The next token (the scanner must not be Empty)</summary>
    function Peek: TYamlToken;
    /// <summary>The current mark of the input</summary>
    function Mark: TYamlMark;
  end;

implementation

{ TYamlScanner.TIndentMarker }

constructor TYamlScanner.TIndentMarker.Create(AColumn: Integer; AType: TIndentType);
begin
  inherited Create;
  Column := AColumn;
  IndentType := AType;
  Status := isValid;
end;

{ TYamlScanner.TSimpleKey }

procedure TYamlScanner.TSimpleKey.Validate;
begin
  if Assigned(Indent) then
    Indent.Status := isValid;
  if Assigned(MapStart) then
    MapStart.Status := tsValid;
  if Assigned(Key) then
    Key.Status := tsValid;
end;

procedure TYamlScanner.TSimpleKey.Invalidate;
begin
  if Assigned(Indent) then
    Indent.Status := isInvalid;
  if Assigned(MapStart) then
    MapStart.Status := tsInvalid;
  if Assigned(Key) then
    Key.Status := tsInvalid;
end;

{ TYamlScanner }

constructor TYamlScanner.Create(AInput: TYamlStream);
begin
  inherited Create;
  FInput := AInput;
  FTokens := TQueue<TYamlToken>.Create;
  FAllTokens := TObjectList<TYamlToken>.Create(True);
  FIndentRefs := TObjectList<TIndentMarker>.Create(True);
  FSimpleKeys := TStack<TSimpleKey>.Create;
  FIndents := TStack<TIndentMarker>.Create;
  FFlows := TStack<TFlowMarker>.Create;
end;

destructor TYamlScanner.Destroy;
begin
  FFlows.Free;
  FIndents.Free;
  FSimpleKeys.Free;
  FIndentRefs.Free;
  FAllTokens.Free;
  FTokens.Free;
  FInput.Free;
  inherited Destroy;
end;

function TYamlScanner.NewToken(AType: TYamlTokenType; const AMark: TYamlMark): TYamlToken;
begin
  Result := TYamlToken.Create(AType, AMark);
  FAllTokens.Add(Result);
end;

procedure TYamlScanner.Enqueue(AToken: TYamlToken);
begin
  FTokens.Enqueue(AToken);
end;

function TYamlScanner.PushToken(AType: TYamlTokenType): TYamlToken;
begin
  Result := NewToken(AType, FInput.Mark);
  Enqueue(Result);
end;

function TYamlScanner.Empty: Boolean;
begin
  EnsureTokensInQueue;
  Result := FTokens.Count = 0;
end;

procedure TYamlScanner.Pop;
begin
  EnsureTokensInQueue;
  if FTokens.Count > 0 then
    FTokens.Dequeue;
end;

function TYamlScanner.Peek: TYamlToken;
begin
  EnsureTokensInQueue;
  Result := FTokens.Peek;
end;

function TYamlScanner.Mark: TYamlMark;
begin
  Result := FInput.Mark;
end;

procedure TYamlScanner.EnsureTokensInQueue;
var
  LToken: TYamlToken;
begin
  while True do
  begin
    if FTokens.Count > 0 then
    begin
      LToken := FTokens.Peek;
      if LToken.Status = tsValid then
        Exit;
      if LToken.Status = tsInvalid then
      begin
        FTokens.Dequeue;
        Continue;
      end;
      // tsUnverified: wait for more tokens
    end;
    if FEndedStream then
      Exit;
    ScanNextToken;
  end;
end;

function TYamlScanner.InFlowContext: Boolean;
begin
  Result := FFlows.Count > 0;
end;

function TYamlScanner.InBlockContext: Boolean;
begin
  Result := FFlows.Count = 0;
end;

function TYamlScanner.GetFlowLevel: Integer;
begin
  Result := FFlows.Count;
end;

function TYamlScanner.GetValueRegex: TYamlRegEx;
begin
  if InBlockContext then
    Exit(TYamlExp.Value);
  if FCanBeJSONFlow then
    Result := TYamlExp.ValueInJSONFlow
  else
    Result := TYamlExp.ValueInFlow;
end;

procedure TYamlScanner.ScanNextToken;
begin
  if FEndedStream then
    Exit;
  if not FStartedStream then
  begin
    StartStream;
    Exit;
  end;

  // get rid of whitespace, etc. (in between tokens it should be irrelevant)
  ScanToNextToken;

  // maybe need to end some blocks
  PopIndentToHere;

  // end of stream
  if not FInput.IsOpen then
  begin
    EndStream;
    Exit;
  end;

  if (FInput.Column = 0) and (FInput.Peek = YAML_KEY_DIRECTIVE) then
    begin ScanDirective; Exit; end;
  if (FInput.Column = 0) and TYamlExp.DocStart.Matches(FInput) then
    begin ScanDocStart; Exit; end;
  if (FInput.Column = 0) and TYamlExp.DocEnd.Matches(FInput) then
    begin ScanDocEnd; Exit; end;
  if (FInput.Peek = YAML_KEY_FLOW_SEQ_START) or (FInput.Peek = YAML_KEY_FLOW_MAP_START) then
    begin ScanFlowStart; Exit; end;
  if (FInput.Peek = YAML_KEY_FLOW_SEQ_END) or (FInput.Peek = YAML_KEY_FLOW_MAP_END) then
    begin ScanFlowEnd; Exit; end;
  if FInput.Peek = YAML_KEY_FLOW_ENTRY then
    begin ScanFlowEntry; Exit; end;
  if TYamlExp.BlockEntry.Matches(FInput) then
    begin ScanBlockEntry; Exit; end;
  if InBlockContext then
  begin
    if TYamlExp.Key.Matches(FInput) then
      begin ScanKey; Exit; end;
  end
  else if TYamlExp.KeyInFlow.Matches(FInput) then
    begin ScanKey; Exit; end;
  if GetValueRegex.Matches(FInput) then
    begin ScanValue; Exit; end;
  if (FInput.Peek = YAML_KEY_ALIAS) or (FInput.Peek = YAML_KEY_ANCHOR) then
    begin ScanAnchorOrAlias; Exit; end;
  if FInput.Peek = YAML_KEY_TAG then
    begin ScanTag; Exit; end;
  if InBlockContext and ((FInput.Peek = YAML_KEY_LITERAL_SCALAR) or (FInput.Peek = YAML_KEY_FOLDED_SCALAR)) then
    begin ScanBlockScalar; Exit; end;
  if (FInput.Peek = Ord('''')) or (FInput.Peek = Ord('"')) then
    begin ScanQuotedScalar; Exit; end;
  if InBlockContext then
  begin
    if TYamlExp.PlainScalar.Matches(FInput) then
      begin ScanPlainScalar; Exit; end;
  end
  else if TYamlExp.PlainScalarInFlow.Matches(FInput) then
    begin ScanPlainScalar; Exit; end;

  // don't know what it is!
  raise EYamlParserException.Create(FInput.Mark, SYamlUnknownToken);
end;

procedure TYamlScanner.ScanToNextToken;
var
  N: Integer;
begin
  while True do
  begin
    // first eat whitespace
    while FInput.IsOpen and ((FInput.Peek = Ord(' ')) or (FInput.Peek = 9)) do
    begin
      if InBlockContext and TYamlExp.Tab.Matches(FInput) then
        FSimpleKeyAllowed := False;
      FInput.Eat(1);
    end;
    // then eat a comment
    if TYamlExp.Comment.Matches(FInput) then
    begin
      // eat until line break
      while FInput.IsOpen and (not TYamlExp.Break.Matches(FInput)) do
        FInput.Eat(1);
    end;
    // if it's NOT a line break, then we're done!
    if not TYamlExp.Break.Matches(FInput) then
      Break;
    // otherwise, let's eat the line break and keep going
    N := TYamlExp.Break.Match(FInput);
    FInput.Eat(N);
    // oh yeah, and let's get rid of that simple key
    InvalidateSimpleKey;
    // new line - we may be able to accept a simple key now
    if InBlockContext then
      FSimpleKeyAllowed := True;
  end;
end;

procedure TYamlScanner.StartStream;
var
  LIndent: TIndentMarker;
begin
  FStartedStream := True;
  FSimpleKeyAllowed := True;
  LIndent := TIndentMarker.Create(-1, itNone);
  FIndentRefs.Add(LIndent);
  FIndents.Push(LIndent);
end;

procedure TYamlScanner.EndStream;
begin
  // force an ending newline
  if FInput.Column > 0 then
    FInput.ResetColumn;
  PopAllIndents;
  PopAllSimpleKeys;
  FSimpleKeyAllowed := False;
  FEndedStream := True;
end;

function TYamlScanner.PushIndentTo(AColumn: Integer; AType: TIndentType): TIndentMarker;
var
  LIndent, LLast: TIndentMarker;
begin
  Result := nil;
  // are we in flow?
  if InFlowContext then
    Exit;
  LIndent := TIndentMarker.Create(AColumn, AType);
  LLast := FIndents.Peek;
  // is this actually an indentation?
  if LIndent.Column < LLast.Column then
  begin
    LIndent.Free;
    Exit;
  end;
  if (LIndent.Column = LLast.Column) and not ((LIndent.IndentType = itSeq) and (LLast.IndentType = itMap)) then
  begin
    LIndent.Free;
    Exit;
  end;
  // push a start token
  if AType = itSeq then
    LIndent.StartToken := PushToken(ttBlockSeqStart)
  else
    LIndent.StartToken := PushToken(ttBlockMapStart);
  // and then the indent
  FIndents.Push(LIndent);
  FIndentRefs.Add(LIndent);
  Result := LIndent;
end;

procedure TYamlScanner.PopIndentToHere;
var
  LIndent: TIndentMarker;
begin
  // are we in flow?
  if InFlowContext then
    Exit;
  // now pop away
  while FIndents.Count > 0 do
  begin
    LIndent := FIndents.Peek;
    if LIndent.Column < FInput.Column then
      Break;
    if (LIndent.Column = FInput.Column) and
      not ((LIndent.IndentType = itSeq) and (not TYamlExp.BlockEntry.Matches(FInput))) then
      Break;
    PopIndent;
  end;
  while (FIndents.Count > 0) and (FIndents.Peek.Status = isInvalid) do
    PopIndent;
end;

procedure TYamlScanner.PopAllIndents;
begin
  // are we in flow?
  if InFlowContext then
    Exit;
  // now pop away
  while FIndents.Count > 0 do
  begin
    if FIndents.Peek.IndentType = itNone then
      Break;
    PopIndent;
  end;
end;

procedure TYamlScanner.PopIndent;
var
  LIndent: TIndentMarker;
begin
  LIndent := FIndents.Pop;
  if LIndent.Status <> isValid then
  begin
    InvalidateSimpleKey;
    Exit;
  end;
  if LIndent.IndentType = itSeq then
    Enqueue(NewToken(ttBlockSeqEnd, FInput.Mark))
  else if LIndent.IndentType = itMap then
    Enqueue(NewToken(ttBlockMapEnd, FInput.Mark));
end;

function TYamlScanner.GetTopIndent: Integer;
begin
  if FIndents.Count = 0 then
    Exit(0);
  Result := FIndents.Peek.Column;
end;

function TYamlScanner.CanInsertPotentialSimpleKey: Boolean;
begin
  if not FSimpleKeyAllowed then
    Exit(False);
  Result := not ExistsActiveSimpleKey;
end;

function TYamlScanner.ExistsActiveSimpleKey: Boolean;
begin
  if FSimpleKeys.Count = 0 then
    Exit(False);
  Result := FSimpleKeys.Peek.FlowLevel = GetFlowLevel;
end;

procedure TYamlScanner.InsertPotentialSimpleKey;
var
  LKey: TSimpleKey;
begin
  if not CanInsertPotentialSimpleKey then
    Exit;
  LKey.Mark := FInput.Mark;
  LKey.FlowLevel := GetFlowLevel;
  LKey.Indent := nil;
  LKey.MapStart := nil;
  LKey.Key := nil;
  // first add a map start, if necessary
  if InBlockContext then
  begin
    LKey.Indent := PushIndentTo(FInput.Column, itMap);
    if Assigned(LKey.Indent) then
    begin
      LKey.Indent.Status := isUnknown;
      LKey.MapStart := LKey.Indent.StartToken;
      LKey.MapStart.Status := tsUnverified;
    end;
  end;
  // then add the (now unverified) key
  LKey.Key := NewToken(ttKey, FInput.Mark);
  Enqueue(LKey.Key);
  LKey.Key.Status := tsUnverified;
  FSimpleKeys.Push(LKey);
end;

procedure TYamlScanner.InvalidateSimpleKey;
var
  LKey: TSimpleKey;
begin
  if FSimpleKeys.Count = 0 then
    Exit;
  // grab top key
  LKey := FSimpleKeys.Peek;
  if LKey.FlowLevel <> GetFlowLevel then
    Exit;
  LKey.Invalidate;
  FSimpleKeys.Pop;
end;

function TYamlScanner.VerifySimpleKey: Boolean;
var
  LKey: TSimpleKey;
begin
  if FSimpleKeys.Count = 0 then
    Exit(False);
  // grab top key
  LKey := FSimpleKeys.Peek;
  if LKey.FlowLevel <> GetFlowLevel then
    Exit(False);
  FSimpleKeys.Pop;
  Result := True;
  // only a key if it is on the same line and no longer than 1024 chars
  if (FInput.Line <> LKey.Mark.Line) or (FInput.Pos - LKey.Mark.Pos > 1024) then
    Result := False;
  if Result then
    LKey.Validate
  else
    LKey.Invalidate;
end;

procedure TYamlScanner.PopAllSimpleKeys;
begin
  FSimpleKeys.Clear;
end;

{ scantoken.cpp }

procedure TYamlScanner.ScanDirective;
var
  LToken: TYamlToken;
  LParam: TYamlText;
  LParams: TArray<TYamlText>;
begin
  // pop indents and simple keys
  PopAllIndents;
  PopAllSimpleKeys;
  FSimpleKeyAllowed := False;
  FCanBeJSONFlow := False;
  // store pos and eat indicator
  LToken := NewToken(ttDirective, FInput.Mark);
  FInput.Eat(1);
  // read name
  while FInput.IsOpen and (not TYamlExp.BlankOrBreak.Matches(FInput)) do
    LToken.Value := LToken.Value + AnsiChar(FInput.Get);
  // read parameters
  LParams := nil;
  while True do
  begin
    // first eat whitespace
    while TYamlExp.Blank.Matches(FInput) do
      FInput.Eat(1);
    // break on newline or comment
    if (not FInput.IsOpen) or TYamlExp.Break.Matches(FInput) or TYamlExp.Comment.Matches(FInput) then
      Break;
    // read parameter
    LParam := '';
    while FInput.IsOpen and (not TYamlExp.BlankOrBreak.Matches(FInput)) do
      LParam := LParam + AnsiChar(FInput.Get);
    SetLength(LParams, Length(LParams) + 1);
    LParams[High(LParams)] := LParam;
  end;
  LToken.Params := LParams;
  Enqueue(LToken);
end;

procedure TYamlScanner.ScanDocStart;
var
  LMark: TYamlMark;
begin
  PopAllIndents;
  PopAllSimpleKeys;
  FSimpleKeyAllowed := False;
  FCanBeJSONFlow := False;
  LMark := FInput.Mark;
  FInput.Eat(3);
  Enqueue(NewToken(ttDocStart, LMark));
end;

procedure TYamlScanner.ScanDocEnd;
var
  LMark: TYamlMark;
begin
  PopAllIndents;
  PopAllSimpleKeys;
  FSimpleKeyAllowed := False;
  FCanBeJSONFlow := False;
  LMark := FInput.Mark;
  FInput.Eat(3);
  Enqueue(NewToken(ttDocEnd, LMark));
end;

procedure TYamlScanner.ScanFlowStart;
var
  LMark: TYamlMark;
  LChar: Byte;
  LFlowType: TFlowMarker;
begin
  // flow start is a simple key
  InsertPotentialSimpleKey;
  FSimpleKeyAllowed := True;
  FCanBeJSONFlow := False;
  LMark := FInput.Mark;
  LChar := FInput.Get;
  if LChar = YAML_KEY_FLOW_SEQ_START then
    LFlowType := fmSeq
  else
    LFlowType := fmMap;
  FFlows.Push(LFlowType);
  if LFlowType = fmSeq then
    Enqueue(NewToken(ttFlowSeqStart, LMark))
  else
    Enqueue(NewToken(ttFlowMapStart, LMark));
end;

procedure TYamlScanner.ScanFlowEnd;
var
  LMark: TYamlMark;
  LChar: Byte;
  LFlowType: TFlowMarker;
begin
  if InBlockContext then
    raise EYamlParserException.Create(FInput.Mark, SYamlFlowEnd);
  // we might have a solo entry in the flow context
  if InFlowContext then
  begin
    if (FFlows.Peek = fmMap) and VerifySimpleKey then
      Enqueue(NewToken(ttValue, FInput.Mark))
    else if FFlows.Peek = fmSeq then
      InvalidateSimpleKey;
  end;
  FSimpleKeyAllowed := False;
  FCanBeJSONFlow := True;
  LMark := FInput.Mark;
  LChar := FInput.Get;
  if LChar = YAML_KEY_FLOW_SEQ_END then
    LFlowType := fmSeq
  else
    LFlowType := fmMap;
  if FFlows.Peek <> LFlowType then
    raise EYamlParserException.Create(LMark, SYamlFlowEnd);
  FFlows.Pop;
  if LFlowType = fmSeq then
    Enqueue(NewToken(ttFlowSeqEnd, LMark))
  else
    Enqueue(NewToken(ttFlowMapEnd, LMark));
end;

procedure TYamlScanner.ScanFlowEntry;
var
  LMark: TYamlMark;
begin
  // we might have a solo entry in the flow context
  if InFlowContext then
  begin
    if (FFlows.Peek = fmMap) and VerifySimpleKey then
      Enqueue(NewToken(ttValue, FInput.Mark))
    else if FFlows.Peek = fmSeq then
      InvalidateSimpleKey;
  end;
  FSimpleKeyAllowed := True;
  FCanBeJSONFlow := False;
  LMark := FInput.Mark;
  FInput.Eat(1);
  Enqueue(NewToken(ttFlowEntry, LMark));
end;

procedure TYamlScanner.ScanBlockEntry;
var
  LMark: TYamlMark;
begin
  // we better be in the block context!
  if InFlowContext then
    raise EYamlParserException.Create(FInput.Mark, SYamlBlockEntry);
  // can we put it here?
  if not FSimpleKeyAllowed then
    raise EYamlParserException.Create(FInput.Mark, SYamlBlockEntry);
  PushIndentTo(FInput.Column, itSeq);
  FSimpleKeyAllowed := True;
  FCanBeJSONFlow := False;
  LMark := FInput.Mark;
  FInput.Eat(1);
  Enqueue(NewToken(ttBlockEntry, LMark));
end;

procedure TYamlScanner.ScanKey;
var
  LMark: TYamlMark;
begin
  // handle keys differently in the block context (and manage indents)
  if InBlockContext then
  begin
    if not FSimpleKeyAllowed then
      raise EYamlParserException.Create(FInput.Mark, SYamlMapKey);
    PushIndentTo(FInput.Column, itMap);
  end;
  // can only put a simple key here if we're in block context
  FSimpleKeyAllowed := InBlockContext;
  LMark := FInput.Mark;
  FInput.Eat(1);
  Enqueue(NewToken(ttKey, LMark));
end;

procedure TYamlScanner.ScanValue;
var
  LIsSimpleKey: Boolean;
  LMark: TYamlMark;
begin
  // does this follow a simple key?
  LIsSimpleKey := VerifySimpleKey;
  FCanBeJSONFlow := False;
  if LIsSimpleKey then
    // can't follow a simple key with another simple key (dunno why, though - it seems fine)
    FSimpleKeyAllowed := False
  else
  begin
    // handle values diffently in the block context (and manage indents)
    if InBlockContext then
    begin
      if not FSimpleKeyAllowed then
        raise EYamlParserException.Create(FInput.Mark, SYamlMapValue);
      PushIndentTo(FInput.Column, itMap);
    end;
    // can only put a simple key here if we're in block context
    FSimpleKeyAllowed := InBlockContext;
  end;
  LMark := FInput.Mark;
  FInput.Eat(1);
  Enqueue(NewToken(ttValue, LMark));
end;

procedure TYamlScanner.ScanAnchorOrAlias;
var
  LAlias: Boolean;
  LName: TYamlText;
  LMark: TYamlMark;
  LIndicator: Byte;
  LToken: TYamlToken;
begin
  LName := '';
  // insert a potential simple key
  InsertPotentialSimpleKey;
  FSimpleKeyAllowed := False;
  FCanBeJSONFlow := False;
  // eat the indicator
  LMark := FInput.Mark;
  LIndicator := FInput.Get;
  LAlias := LIndicator = YAML_KEY_ALIAS;
  // now eat the content
  while FInput.IsOpen and TYamlExp.Anchor.Matches(FInput) do
    LName := LName + AnsiChar(FInput.Get);
  // we need to have read SOMETHING!
  if LName = '' then
  begin
    if LAlias then
      raise EYamlParserException.Create(FInput.Mark, SYamlAliasNotFound)
    else
      raise EYamlParserException.Create(FInput.Mark, SYamlAnchorNotFound);
  end;
  // and needs to end correctly
  if FInput.IsOpen and (not TYamlExp.AnchorEnd.Matches(FInput)) then
  begin
    if LAlias then
      raise EYamlParserException.Create(FInput.Mark, SYamlCharInAlias)
    else
      raise EYamlParserException.Create(FInput.Mark, SYamlCharInAnchor);
  end;
  // and we're done
  if LAlias then
    LToken := NewToken(ttAlias, LMark)
  else
    LToken := NewToken(ttAnchor, LMark);
  LToken.Value := LName;
  Enqueue(LToken);
end;

procedure TYamlScanner.ScanTag;
var
  LToken: TYamlToken;
  LCanBeHandle: Boolean;
begin
  // insert a potential simple key
  InsertPotentialSimpleKey;
  FSimpleKeyAllowed := False;
  FCanBeJSONFlow := False;
  LToken := NewToken(ttTag, FInput.Mark);
  // eat the indicator
  FInput.Get;
  if FInput.IsOpen and (FInput.Peek = YAML_KEY_VERBATIM_TAG_START) then
  begin
    LToken.Value := TYamlTagScanner.ScanVerbatimTag(FInput);
    LToken.Data := Ord(tkVerbatim);
  end
  else
  begin
    LToken.Value := TYamlTagScanner.ScanTagHandle(FInput, LCanBeHandle);
    if (not LCanBeHandle) and (LToken.Value = '') then
      LToken.Data := Ord(tkNonSpecific)
    else if LToken.Value = '' then
      LToken.Data := Ord(tkSecondaryHandle)
    else
      LToken.Data := Ord(tkPrimaryHandle);
    // is there a suffix?
    if LCanBeHandle and (FInput.Peek = YAML_KEY_TAG) then
    begin
      // eat the indicator
      FInput.Get;
      LToken.Params := [TYamlTagScanner.ScanTagSuffix(FInput)];
      LToken.Data := Ord(tkNamedHandle);
    end;
  end;
  Enqueue(LToken);
end;

procedure TYamlScanner.ScanPlainScalar;
var
  LParams: TYamlScanScalarParams;
  LScalar: TYamlText;
  LMark: TYamlMark;
  LToken: TYamlToken;
begin
  // set up the scanning parameters
  LParams := TYamlScanScalarParams.Default;
  if InFlowContext then
    LParams.EndExpression := TYamlExp.ScanScalarEndInFlow
  else
    LParams.EndExpression := TYamlExp.ScanScalarEnd;
  LParams.EatEnd := False;
  if InFlowContext then
    LParams.Indent := 0
  else
    LParams.Indent := GetTopIndent + 1;
  LParams.Fold := foFoldFlow;
  LParams.EatLeadingWhitespace := True;
  LParams.TrimTrailingSpaces := True;
  LParams.Chomp := chStrip;
  LParams.OnDocIndicator := saBreak;
  LParams.OnTabInIndentation := saThrow;
  // insert a potential simple key
  InsertPotentialSimpleKey;
  LMark := FInput.Mark;
  LScalar := TYamlScalarScanner.Scan(FInput, LParams);
  // can have a simple key only if we ended the scalar by starting a new line
  FSimpleKeyAllowed := LParams.LeadingSpaces;
  FCanBeJSONFlow := False;
  // finally, check and see if we ended on an illegal character
  LToken := NewToken(ttPlainScalar, LMark);
  LToken.Value := LScalar;
  Enqueue(LToken);
end;

procedure TYamlScanner.ScanQuotedScalar;
var
  LParams: TYamlScanScalarParams;
  LScalar: TYamlText;
  LQuote: Byte;
  LSingle: Boolean;
  LMark: TYamlMark;
  LToken: TYamlToken;
begin
  // peek at single or double quote (don't eat because we need to preserve (for the time being) the input position)
  LQuote := FInput.Peek;
  LSingle := LQuote = Ord('''');
  // setup the scanning parameters
  LParams := TYamlScanScalarParams.Default;
  if LSingle then
  begin
    LParams.EndExpression := TYamlExp.SingleQuoteEnd;
    LParams.Escape := Ord('''');
  end
  else
  begin
    LParams.EndExpression := TYamlExp.DoubleQuoteEnd;
    LParams.Escape := Ord('\');
  end;
  LParams.EatEnd := True;
  LParams.Indent := 0;
  LParams.Fold := foFoldFlow;
  LParams.EatLeadingWhitespace := True;
  LParams.TrimTrailingSpaces := False;
  LParams.Chomp := chClip;
  LParams.OnDocIndicator := saThrow;
  // insert a potential simple key
  InsertPotentialSimpleKey;
  LMark := FInput.Mark;
  // now eat that opening quote
  FInput.Get;
  // and scan
  LScalar := TYamlScalarScanner.Scan(FInput, LParams);
  FSimpleKeyAllowed := False;
  FCanBeJSONFlow := True;
  LToken := NewToken(ttNonPlainScalar, LMark);
  LToken.Value := LScalar;
  Enqueue(LToken);
end;

procedure TYamlScanner.ScanBlockScalar;
var
  LParams: TYamlScanScalarParams;
  LScalar: TYamlText;
  LMark: TYamlMark;
  LIndicator, LChar: Byte;
  N, I: Integer;
  LToken: TYamlToken;
begin
  LParams := TYamlScanScalarParams.Default;
  LParams.Indent := 1;
  LParams.DetectIndent := True;
  // eat block indicator ('|' or '>')
  LMark := FInput.Mark;
  LIndicator := FInput.Get;
  if LIndicator = YAML_KEY_FOLDED_SCALAR then
    LParams.Fold := foFoldBlock
  else
    LParams.Fold := foDontFold;
  // eat chomping/indentation indicators
  LParams.Chomp := chClip;
  N := TYamlExp.Chomp.Match(FInput);
  for I := 0 to N - 1 do
  begin
    LChar := FInput.Get;
    if LChar = Ord('+') then
      LParams.Chomp := chKeep
    else if LChar = Ord('-') then
      LParams.Chomp := chStrip
    else if TYamlExp.Digit.Matches(LChar) then
    begin
      if LChar = Ord('0') then
        raise EYamlParserException.Create(FInput.Mark, SYamlZeroIndentInBlock);
      LParams.Indent := LChar - Ord('0');
      LParams.DetectIndent := False;
    end;
  end;
  // eat whitespace
  while TYamlExp.Blank.Matches(FInput) do
    FInput.Eat(1);
  // and comments to the end of the line
  if TYamlExp.Comment.Matches(FInput) then
    while FInput.IsOpen and (not TYamlExp.Break.Matches(FInput)) do
      FInput.Eat(1);
  // if it's not a line break, then we ran into a bad character inline
  if FInput.IsOpen and (not TYamlExp.Break.Matches(FInput)) then
    raise EYamlParserException.Create(FInput.Mark, SYamlCharInBlock);
  // set the initial indentation
  if GetTopIndent >= 0 then
    LParams.Indent := LParams.Indent + GetTopIndent;
  LParams.EatLeadingWhitespace := False;
  LParams.TrimTrailingSpaces := False;
  LParams.OnTabInIndentation := saThrow;
  LScalar := TYamlScalarScanner.Scan(FInput, LParams);
  // simple keys always ok after block scalars (since we're gonna start a new line anyways)
  FSimpleKeyAllowed := True;
  FCanBeJSONFlow := False;
  LToken := NewToken(ttNonPlainScalar, LMark);
  LToken.Value := LScalar;
  Enqueue(LToken);
end;

end.
