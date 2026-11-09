{******************************************************************************}
{                                                                              }
{  DelphiDoom: yaml library - scanning the text of a scalar                    }
{  Port of yaml-cpp 0.7.0 (MIT, Jesse Beder): see Libs\Yaml\README.md          }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Yaml.ScanScalar;

interface

uses
  System.SysUtils,
  DelphiDoom.Yaml.Types,
  DelphiDoom.Yaml.Stream,
  DelphiDoom.Yaml.RegEx,
  DelphiDoom.Yaml.Exp;

type
  /// <summary>CHOMP: what to do with the newlines at the end of a block scalar</summary>
  TYamlChomp = (chStrip, chClip, chKeep);
  /// <summary>ACTION</summary>
  TYamlScanAction = (saNone, saBreak, saThrow);
  /// <summary>FOLD</summary>
  TYamlFold = (foDontFold, foFoldBlock, foFoldFlow);

  /// <summary>ScanScalarParams (the end expression is not owned)</summary>
  TYamlScanScalarParams = record
    EndExpression: TYamlRegEx;
    EatEnd: Boolean;
    Indent: Integer;
    DetectIndent: Boolean;
    EatLeadingWhitespace: Boolean;
    Escape: Byte;
    Fold: TYamlFold;
    TrimTrailingSpaces: Boolean;
    Chomp: TYamlChomp;
    OnDocIndicator: TYamlScanAction;
    OnTabInIndentation: TYamlScanAction;
    LeadingSpaces: Boolean;
    /// <summary>ScanScalarParams(): the defaults of yaml-cpp</summary>
    class function Default: TYamlScanScalarParams; static;
  end;

  /// <summary>ScanScalar(): reads the text of plain, quoted and block scalars</summary>
  TYamlScalarScanner = class
  public
    class function Scan(AStream: TYamlStream; var AParams: TYamlScanScalarParams): TYamlText; static;
  end;

implementation

{ TYamlScanScalarParams }

class function TYamlScanScalarParams.Default: TYamlScanScalarParams;
begin
  Result.EndExpression := nil;
  Result.EatEnd := False;
  Result.Indent := 0;
  Result.DetectIndent := False;
  Result.EatLeadingWhitespace := False;
  Result.Escape := 0;
  Result.Fold := foDontFold;
  Result.TrimTrailingSpaces := False;
  Result.Chomp := chClip;
  Result.OnDocIndicator := saNone;
  Result.OnTabInIndentation := saNone;
  Result.LeadingSpaces := False;
end;

{ TYamlScalarScanner }

// find_last_not_of: the 0 based index or -1 (npos)
function FindLastNotOf(const AText: TYamlText; const AChars: TYamlText): Integer;
var
  I, J: Integer;
  LFound: Boolean;
begin
  for I := Length(AText) downto 1 do
  begin
    LFound := False;
    for J := 1 to Length(AChars) do
      if AChars[J] = AText[I] then
      begin
        LFound := True;
        Break;
      end;
    if not LFound then
      Exit(I - 1);
  end;
  Result := -1;
end;

// pos < lastEscapedChar with npos as the biggest value
function LessThan(APos, AOther: Integer): Boolean;
begin
  Result := (APos <> -1) and ((AOther = -1) or (APos < AOther));
end;

class function TYamlScalarScanner.Scan(AStream: TYamlStream; var AParams: TYamlScanScalarParams): TYamlText;
var
  LFoundNonEmptyLine, LPastOpeningBreak, LEmptyLine, LMoreIndented: Boolean;
  LFoldedNewlineCount: Integer;
  LFoldedNewlineStartedMoreIndented: Boolean;
  LLastEscapedChar: Integer;
  LScalar: TYamlText;
  LLastNonWhitespaceChar: Integer;
  LEscapedNewline: Boolean;
  LNextEmptyLine, LNextMoreIndented: Boolean;
  LChar: Byte;
  N: Integer;
  LPos: Integer;
begin
  LFoundNonEmptyLine := False;
  LPastOpeningBreak := AParams.Fold = foFoldFlow;
  LEmptyLine := False;
  LMoreIndented := False;
  LFoldedNewlineCount := 0;
  LFoldedNewlineStartedMoreIndented := False;
  LLastEscapedChar := -1;
  LScalar := '';
  AParams.LeadingSpaces := False;
  if not Assigned(AParams.EndExpression) then
    AParams.EndExpression := TYamlExp.Empty;

  while AStream.IsOpen do
  begin
    LLastNonWhitespaceChar := Length(LScalar);
    LEscapedNewline := False;
    while (not AParams.EndExpression.Matches(AStream)) and (not TYamlExp.Break.Matches(AStream)) do
    begin
      if not AStream.IsOpen then
        Break;
      if (AStream.Column = 0) and TYamlExp.DocIndicator.Matches(AStream) then
      begin
        if AParams.OnDocIndicator = saBreak then
          Break
        else if AParams.OnDocIndicator = saThrow then
          raise EYamlParserException.Create(AStream.Mark, SYamlDocInScalar);
      end;
      LFoundNonEmptyLine := True;
      LPastOpeningBreak := True;
      // escaped newline? (only if we're escaping on slash)
      if (AParams.Escape = Ord('\')) and TYamlExp.EscBreak.Matches(AStream) then
      begin
        AStream.Get;
        LLastNonWhitespaceChar := Length(LScalar);
        LLastEscapedChar := Length(LScalar);
        LEscapedNewline := True;
        Break;
      end;
      // escape this?
      if AStream.Peek = AParams.Escape then
      begin
        LScalar := LScalar + TYamlExp.Escape(AStream);
        LLastNonWhitespaceChar := Length(LScalar);
        LLastEscapedChar := Length(LScalar);
        Continue;
      end;
      LChar := AStream.Get;
      LScalar := LScalar + AnsiChar(LChar);
      if (LChar <> Ord(' ')) and (LChar <> 9) then
        LLastNonWhitespaceChar := Length(LScalar);
    end;

    if not AStream.IsOpen then
    begin
      if AParams.EatEnd then
        raise EYamlParserException.Create(AStream.Mark, SYamlEofInScalar);
      Break;
    end;
    if (AParams.OnDocIndicator = saBreak) and (AStream.Column = 0) and TYamlExp.DocIndicator.Matches(AStream) then
      Break;
    N := AParams.EndExpression.Match(AStream);
    if N >= 0 then
    begin
      if AParams.EatEnd then
        AStream.Eat(N);
      Break;
    end;

    // doc indicator?
    // are we done via character match?
    if AParams.Fold = foFoldFlow then
      SetLength(LScalar, LLastNonWhitespaceChar);

    // eat newline
    N := TYamlExp.Break.Match(AStream);
    AStream.Eat(N);

    // eat leading indentation (only for block scalars with detectIndent: do it whenever the column is small)
    while (AStream.Peek = Ord(' ')) and
      ((AStream.Column < AParams.Indent) or (AParams.DetectIndent and (not LFoundNonEmptyLine))) and
      (not AParams.EndExpression.Matches(AStream)) do
      AStream.Eat(1);

    if AParams.DetectIndent and (not LFoundNonEmptyLine) then
      if AStream.Column > AParams.Indent then
        AParams.Indent := AStream.Column;

    while TYamlExp.Blank.Matches(AStream) do
    begin
      if (AStream.Peek = 9) and (AStream.Column < AParams.Indent) and (AParams.OnTabInIndentation = saThrow) then
        raise EYamlParserException.Create(AStream.Mark, SYamlTabInIndentation);
      if not AParams.EatLeadingWhitespace then
        Break;
      if AParams.EndExpression.Matches(AStream) then
        Break;
      AStream.Eat(1);
    end;

    LNextEmptyLine := TYamlExp.Break.Matches(AStream);
    LNextMoreIndented := TYamlExp.Blank.Matches(AStream);
    if (AParams.Fold = foFoldBlock) and (LFoldedNewlineCount = 0) and LNextEmptyLine then
      LFoldedNewlineStartedMoreIndented := LMoreIndented;

    // for block scalars, we always start with a newline, so we should ignore it (not fold or keep)
    if LPastOpeningBreak then
    begin
      case AParams.Fold of
        foDontFold:
          LScalar := LScalar + #10;
        foFoldBlock:
          begin
            if (not LEmptyLine) and (not LNextEmptyLine) and (not LMoreIndented) and
              (not LNextMoreIndented) and (AStream.Column >= AParams.Indent) then
              LScalar := LScalar + ' '
            else if LNextEmptyLine then
              Inc(LFoldedNewlineCount)
            else
              LScalar := LScalar + #10;
            if (not LNextEmptyLine) and (LFoldedNewlineCount > 0) then
            begin
              LScalar := LScalar + TYamlText(StringOfChar(#10, LFoldedNewlineCount - 1));
              if LFoldedNewlineStartedMoreIndented or LNextMoreIndented or (not LFoundNonEmptyLine) then
                LScalar := LScalar + #10;
              LFoldedNewlineCount := 0;
            end;
          end;
        foFoldFlow:
          begin
            if LNextEmptyLine then
              LScalar := LScalar + #10
            else if (not LEmptyLine) and (not LEscapedNewline) then
              LScalar := LScalar + ' ';
          end;
      end;
    end;

    LEmptyLine := LNextEmptyLine;
    LMoreIndented := LNextMoreIndented;
    LPastOpeningBreak := True;

    // are we done via indentation?
    if (not LEmptyLine) and (AStream.Column < AParams.Indent) then
    begin
      AParams.LeadingSpaces := True;
      Break;
    end;
  end;

  // post-processing
  if AParams.TrimTrailingSpaces then
  begin
    LPos := FindLastNotOf(LScalar, ' '#9);
    if LLastEscapedChar <> -1 then
      if LessThan(LPos, LLastEscapedChar) or (LPos = -1) then
        LPos := LLastEscapedChar;
    if (LPos <> -1) and (LPos < Length(LScalar)) then
      SetLength(LScalar, LPos + 1);
  end;

  case AParams.Chomp of
    chClip:
      begin
        LPos := FindLastNotOf(LScalar, #10);
        if LLastEscapedChar <> -1 then
          if LessThan(LPos, LLastEscapedChar) or (LPos = -1) then
            LPos := LLastEscapedChar;
        if LPos = -1 then
          LScalar := ''
        else if LPos + 1 < Length(LScalar) then
          SetLength(LScalar, LPos + 2);
      end;
    chStrip:
      begin
        LPos := FindLastNotOf(LScalar, #10);
        if LLastEscapedChar <> -1 then
          if LessThan(LPos, LLastEscapedChar) or (LPos = -1) then
            LPos := LLastEscapedChar;
        if LPos = -1 then
          LScalar := ''
        else if LPos < Length(LScalar) then
          SetLength(LScalar, LPos + 1);
      end;
  end;

  Result := LScalar;
end;

end.
