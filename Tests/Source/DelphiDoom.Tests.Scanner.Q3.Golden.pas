{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the scanner library - parity of the script parser of   }
{  Quake III Arena (TQ3Script, TQ3Source) with the real l_script.c and         }
{  l_precomp.c                                                                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Scanner.Q3.Golden;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, DUnitX.TestFramework, DelphiDoom.MathCore.SoftExtended,
  DelphiDoom.Scanner.Q3.Types, DelphiDoom.Scanner.Q3.Intf, DelphiDoom.Scanner.Q3.Script,
  DelphiDoom.Scanner.Q3.Source, DelphiDoom.Scanner.Q3.GlobalDefines;

type
  /// <summary>The files of the cases: a folder on the disk, with the backslashes of the paths turned into slashes</summary>
  TQ3FolderFiles = class(TInterfacedObject, IQ3ScriptFiles)
  strict private
    FFolder: string;
  public
    constructor Create(const AFolder: string);
    function TryRead(const APath: AnsiString; out AData: TBytes): Boolean;
  end;

  /// <summary>The log: every message is a line "P(level)|text" of the output</summary>
  TQ3LineLog = class(TInterfacedObject, IQ3ScriptLog)
  strict private
    FOutput: TStrings;
  public
    constructor Create(const AOutput: TStrings);
    procedure Print(const ALevel: Integer; const AMessage: AnsiString);
  end;

  /// <summary>
  ///   Runs the cases of Tests\Data\Scanner\Q3\cases.txt as Tools\Verifica\236a\q3scan.c does with the real
  ///   code of Quake III Arena and writes the same lines
  /// </summary>
  TQ3GoldenRunner = class
  strict private
    FFolder: string;
    FOutput: TStrings;
    FHideValues: Integer;
    procedure Add(const ALine: string);
    function FormatToken(const AToken: TQ3Token): string;
    function ReadAllLines(const AName: string): TStringList;
    function ReadBytes(const AName: string; out AFound: Boolean): TBytes;
    procedure RunScriptOperations(const AScript: TQ3Script; const AOperations: TStrings);
    procedure RunSourceOperations(const ASource: TQ3Source; const AOperations: TStrings);
    procedure RunCase(const AMode, AInput: string; const AOptions: TStrings);
  public
    class function Escape(const AText: AnsiString): string; static;
    class function LongDoubleText(const AValue: TSoftExtended): string; static;
    constructor Create(const AFolder: string; const AOutput: TStrings);
    procedure Run;
  end;

  [TestFixture]
  [Category('Q3Parser')]
  TTestQ3Golden = class
  strict private
    function DataFolder: string;
  public
    [Test]
    procedure DovrebbeDareLeStesseRisposteDelVeroCodiceDiQuake3;
  end;

implementation

uses
  System.StrUtils, DelphiDoom.Scanner.Q3.Define, DelphiDoom.Scanner.Q3.ScriptLoader,
  DelphiDoom.Scanner.Q3.ScriptLoader.Intf;

{ TQ3FolderFiles }

constructor TQ3FolderFiles.Create(const AFolder: string);
begin
  inherited Create;
  FFolder := AFolder;
end;

function TQ3FolderFiles.TryRead(const APath: AnsiString; out AData: TBytes): Boolean;
var
  LPath: string;
begin
  LPath := FFolder + StringReplace(string(APath), '\', '/', [rfReplaceAll]);
  Result := TFile.Exists(LPath);
  if Result then
    AData := TFile.ReadAllBytes(LPath);
end;

{ TQ3LineLog }

constructor TQ3LineLog.Create(const AOutput: TStrings);
begin
  inherited Create;
  FOutput := AOutput;
end;

procedure TQ3LineLog.Print(const ALevel: Integer; const AMessage: AnsiString);
begin
  FOutput.Add('P' + IntToStr(ALevel) + '|' + TQ3GoldenRunner.Escape(AMessage));
end;

{ TQ3GoldenRunner }

constructor TQ3GoldenRunner.Create(const AFolder: string; const AOutput: TStrings);
begin
  inherited Create;
  FFolder := AFolder;
  FOutput := AOutput;
end;

procedure TQ3GoldenRunner.Add(const ALine: string);
begin
  FOutput.Add(ALine);
end;

class function TQ3GoldenRunner.Escape(const AText: AnsiString): string;
var
  LIndex: Integer;
  LByte: Byte;
begin
  Result := '';
  for LIndex := 1 to Length(AText) do
  begin
    LByte := Byte(AText[LIndex]);
    if LByte = 0 then
      Break;
    if (LByte < 32) or (LByte > 126) or (LByte = Ord('\')) then
      Result := Result + '\x' + IntToHex(LByte, 2)
    else
      Result := Result + Char(LByte);
  end;
end;

class function TQ3GoldenRunner.LongDoubleText(const AValue: TSoftExtended): string;
var
  LExponent: Integer;
begin
  if AValue.IsZero then
    Exit('00000000000000000000');
  LExponent := AValue.BinaryExponent + 63 + 16383;
  if AValue.IsNegative then
    LExponent := LExponent or $8000;
  Result := IntToHex(AValue.Mantissa, 16) + IntToHex(LExponent, 4);
end;

function TQ3GoldenRunner.FormatToken(const AToken: TQ3Token): string;
begin
  if FHideValues = 2 then
    Exit(Format('T|%d|-|-|-|-|-|%d|%s', [AToken.TokenType, AToken.EndWhitespaceOffset - AToken.WhitespaceOffset,
      Escape(AToken.Text)]));
  Result := Format('T|%d|%d|', [AToken.TokenType, AToken.Subtype]);
  if FHideValues <> 0 then
    Result := Result + '-|-'
  else if AToken.TokenType = TT_PUNCTUATION then
    // the values of a punctuation are never set (the stack garbage of the tokens the directives make is not compared)
    Result := Result + '0|00000000000000000000'
  else
    Result := Result + Format('%u|%s', [AToken.IntValue, LongDoubleText(AToken.FloatValue)]);
  Result := Result + Format('|%d|%d|%d|%s', [AToken.Line, AToken.LinesCrossed,
    AToken.EndWhitespaceOffset - AToken.WhitespaceOffset, Escape(AToken.Text)]);
end;

function TQ3GoldenRunner.ReadBytes(const AName: string; out AFound: Boolean): TBytes;
begin
  AFound := TFile.Exists(FFolder + AName);
  if AFound then
    Result := TFile.ReadAllBytes(FFolder + AName)
  else
    Result := nil;
end;

function TQ3GoldenRunner.ReadAllLines(const AName: string): TStringList;
var
  LBytes: TBytes;
  LText: AnsiString;
  LFound: Boolean;
begin
  Result := TStringList.Create;
  Result.LineBreak := #10;
  LBytes := ReadBytes(AName, LFound);
  if Length(LBytes) = 0 then
    Exit;
  SetString(LText, PAnsiChar(@LBytes[0]), Length(LBytes));
  Result.Text := StringReplace(string(LText), #13#10, #10, [rfReplaceAll]);
end;

procedure TQ3GoldenRunner.RunScriptOperations(const AScript: TQ3Script; const AOperations: TStrings);
var
  LIndex: Integer;
  LParts: TArray<string>;
  LToken: TQ3Token;
  LLast: TQ3Token;
  LText: AnsiString;
  LResult: Boolean;
  LOp: string;
begin
  LLast := Default(TQ3Token);
  for LIndex := 0 to AOperations.Count - 1 do
  begin
    if AOperations[LIndex] = '' then
      Continue;
    LParts := AOperations[LIndex].Split(['|']);
    LOp := LParts[0];
    Add('>' + LOp);
    if LOp = 'read' then
    begin
      LResult := AScript.ReadToken(LToken);
      LLast := LToken;
      Add('R|' + IntToStr(Ord(LResult)));
      if LResult then
        Add(FormatToken(LToken));
    end
    else if LOp = 'expstr' then
      Add('R|' + IntToStr(Ord(AScript.ExpectTokenString(AnsiString(LParts[1])))))
    else if LOp = 'exptype' then
    begin
      LResult := AScript.ExpectTokenType(StrToInt(LParts[1]), StrToInt(LParts[2]), LToken);
      Add('R|' + IntToStr(Ord(LResult)));
      if LResult then
        Add(FormatToken(LToken));
    end
    else if LOp = 'expany' then
    begin
      LResult := AScript.ExpectAnyToken(LToken);
      Add('R|' + IntToStr(Ord(LResult)));
      if LResult then
        Add(FormatToken(LToken));
    end
    else if LOp = 'chkstr' then
      Add('R|' + IntToStr(Ord(AScript.CheckTokenString(AnsiString(LParts[1])))))
    else if LOp = 'chktype' then
    begin
      LResult := AScript.CheckTokenType(StrToInt(LParts[1]), StrToInt(LParts[2]), LToken);
      Add('R|' + IntToStr(Ord(LResult)));
      if LResult then
        Add(FormatToken(LToken));
    end
    else if LOp = 'skip' then
      Add('R|' + IntToStr(Ord(AScript.SkipUntilString(AnsiString(LParts[1])))))
    else if LOp = 'unread' then
      AScript.UnreadLastToken
    else if LOp = 'unreadtok' then
      AScript.UnreadToken(LLast)
    else if LOp = 'sint' then
      Add('R|' + IntToStr(AScript.ReadSignedInt))
    else if LOp = 'sfloat' then
      Add('R|' + LongDoubleText(AScript.ReadSignedFloat))
    else if LOp = 'eos' then
      Add('R|' + IntToStr(Ord(AScript.EndOfScript)))
    else if LOp = 'ws' then
      Add('R|' + IntToStr(AScript.NextWhiteSpaceChar))
    else if LOp = 'reset' then
      AScript.Reset
    else if LOp = 'flags' then
      AScript.Flags := StrToInt(LParts[1])
    else if LOp = 'getflags' then
      Add('R|' + IntToStr(AScript.Flags))
    else if LOp = 'punct' then
      Add('R|' + string(AScript.PunctuationFromNumber(StrToInt(LParts[1]))))
    else if LOp = 'strip2' then
    begin
      LText := LLast.Text;
      TQ3Script.StripDoubleQuotes(LText);
      LLast.Text := LText;
      Add(FormatToken(LLast));
    end
    else if LOp = 'strip1' then
    begin
      LText := LLast.Text;
      TQ3Script.StripSingleQuotes(LText);
      LLast.Text := LText;
      Add(FormatToken(LLast));
    end
    else if LOp = 'line' then
      Add('R|' + IntToStr(AScript.Line) + '|' + IntToStr(AScript.LastLine))
    else
      Add('?unknown op');
  end;
end;

procedure TQ3GoldenRunner.RunSourceOperations(const ASource: TQ3Source; const AOperations: TStrings);
var
  LIndex: Integer;
  LParts: TArray<string>;
  LToken: TQ3Token;
  LLast: TQ3Token;
  LResult: Boolean;
  LOp: string;
begin
  LLast := Default(TQ3Token);
  for LIndex := 0 to AOperations.Count - 1 do
  begin
    if AOperations[LIndex] = '' then
      Continue;
    LParts := AOperations[LIndex].Split(['|']);
    LOp := LParts[0];
    Add('>' + LOp);
    if LOp = 'read' then
    begin
      LResult := ASource.ReadToken(LToken);
      LLast := LToken;
      Add('R|' + IntToStr(Ord(LResult)));
      if LResult then
        Add(FormatToken(LToken));
    end
    else if LOp = 'expstr' then
      Add('R|' + IntToStr(Ord(ASource.ExpectTokenString(AnsiString(LParts[1])))))
    else if LOp = 'exptype' then
    begin
      LResult := ASource.ExpectTokenType(StrToInt(LParts[1]), StrToInt(LParts[2]), LToken);
      Add('R|' + IntToStr(Ord(LResult)));
      if LResult then
        Add(FormatToken(LToken));
    end
    else if LOp = 'expany' then
    begin
      LResult := ASource.ExpectAnyToken(LToken);
      Add('R|' + IntToStr(Ord(LResult)));
      if LResult then
        Add(FormatToken(LToken));
    end
    else if LOp = 'chkstr' then
      Add('R|' + IntToStr(Ord(ASource.CheckTokenString(AnsiString(LParts[1])))))
    else if LOp = 'chktype' then
    begin
      LResult := ASource.CheckTokenType(StrToInt(LParts[1]), StrToInt(LParts[2]), LToken);
      Add('R|' + IntToStr(Ord(LResult)));
      if LResult then
        Add(FormatToken(LToken));
    end
    else if LOp = 'skip' then
      Add('R|' + IntToStr(Ord(ASource.SkipUntilString(AnsiString(LParts[1])))))
    else if LOp = 'unread' then
      ASource.UnreadLastToken
    else if LOp = 'unreadtok' then
      ASource.UnreadToken(LLast)
    else if LOp = 'readline' then
    begin
      LResult := ASource.ReadLine(LToken);
      LLast := LToken;
      Add('R|' + IntToStr(Ord(LResult)));
      if LResult then
        Add(FormatToken(LToken));
    end
    else if LOp = 'wsbefore' then
      Add('R|' + IntToStr(Ord(TQ3Source.WhiteSpaceBeforeToken(LLast))))
    else if LOp = 'adddef' then
      Add('R|' + IntToStr(Ord(ASource.AddDefine(AnsiString(LParts[1])))))
    else if LOp = 'line' then
    begin
      if ASource.CurrentScript <> nil then
        Add('R|' + IntToStr(ASource.CurrentScript.Line))
      else
        Add('R|-1');
    end
    else
      Add('?unknown op');
  end;
end;

procedure TQ3GoldenRunner.RunCase(const AMode, AInput: string; const AOptions: TStrings);
var
  LIndex: Integer;
  LFlags: Integer;
  LMemory: Boolean;
  LOps: string;
  LBase: AnsiString;
  LOption: string;
  LGlobals: TQ3GlobalDefines;
  LLoader: IQ3ScriptLoader;
  LLog: IQ3ScriptLog;
  LFiles: IQ3ScriptFiles;
  LOperations: TStringList;
  LScript: TQ3Script;
  LSource: TQ3Source;
  LBytes: TBytes;
  LFound: Boolean;
  LDefine: TQ3Define;
  LToken: TQ3Token;
begin
  FHideValues := 0;
  LFlags := 0;
  LMemory := False;
  LOps := '';
  LBase := '';
  LGlobals := TQ3GlobalDefines.Create;
  LFiles := TQ3FolderFiles.Create(FFolder);
  LLog := TQ3LineLog.Create(FOutput);
  LLoader := TQ3ScriptLoader.Create(LFiles, LLog);
  try
    LLoader.SetBaseFolder('');
    for LIndex := 0 to AOptions.Count - 1 do
    begin
      LOption := AOptions[LIndex];
      if LOption.StartsWith('flags=') then
        LFlags := StrToInt(Copy(LOption, 7, MaxInt))
      else if LOption.StartsWith('mem=') then
        LMemory := StrToInt(Copy(LOption, 5, MaxInt)) <> 0
      else if LOption.StartsWith('ops=') then
        LOps := Copy(LOption, 5, MaxInt)
      else if LOption.StartsWith('nv=') then
        FHideValues := StrToInt(Copy(LOption, 4, MaxInt))
      else if LOption.StartsWith('base=') then
      begin
        LBase := AnsiString(Copy(LOption, 6, MaxInt));
        LLoader.SetBaseFolder(LBase);
      end
      else if LOption.StartsWith('gdef=') then
      begin
        LDefine := TQ3Source.DefineFromString(AnsiString(Copy(LOption, 6, MaxInt)), LLoader, LLog);
        Add('G|' + IntToStr(Ord(LDefine <> nil)));
        LGlobals.Add(LDefine);
      end;
    end;
    if LOps <> '' then
      LOperations := ReadAllLines(LOps)
    else
      LOperations := TStringList.Create;
    try
      if AMode = 'ps' then
      begin
        LBytes := ReadBytes(AInput, LFound);
        if LMemory then
        begin
          if LFound then
            LScript := LLoader.LoadMemory(LBytes, AnsiString(AInput))
          else
            LScript := nil;
        end
        else
          LScript := LLoader.LoadFile(AnsiString(AInput));
        if LScript = nil then
        begin
          Add('NOFILE');
          Exit;
        end;
        try
          LScript.Flags := LFlags;
          if LOps = '' then
          begin
            LToken := Default(TQ3Token);
            while LScript.ReadToken(LToken) do
              Add(FormatToken(LToken));
            Add('END|' + IntToStr(LScript.Line) + '|' + IntToStr(Ord(LScript.EndOfScript)));
          end
          else
            RunScriptOperations(LScript, LOperations);
        finally
          LScript.Free;
        end;
      end
      else
      begin
        if LMemory then
        begin
          LBytes := ReadBytes(AInput, LFound);
          if LFound then
            LSource := TQ3Source.LoadMemory(LBytes, AnsiString(AInput), LLoader, LLog, LGlobals)
          else
            LSource := nil;
        end
        else
          LSource := TQ3Source.LoadFile(AnsiString(AInput), LLoader, LLog, LGlobals);
        if LSource = nil then
        begin
          Add('NOFILE');
          Exit;
        end;
        try
          LSource.CurrentScript.Flags := LFlags;
          for LIndex := 0 to AOptions.Count - 1 do
          begin
            LOption := AOptions[LIndex];
            if LOption.StartsWith('def=') then
              Add('D|' + IntToStr(Ord(LSource.AddDefine(AnsiString(Copy(LOption, 5, MaxInt))))))
            else if LOption.StartsWith('inc=') then
              LSource.SetIncludePath(AnsiString(Copy(LOption, 5, MaxInt)))
            else if LOption.StartsWith('builtin=') then
              LSource.AddBuiltinDefines;
          end;
          if LOps = '' then
          begin
            LToken := Default(TQ3Token);
            while LSource.ReadToken(LToken) do
              Add(FormatToken(LToken));
            if LSource.CurrentScript <> nil then
              Add('END|' + IntToStr(LSource.CurrentScript.Line))
            else
              Add('END|-1');
          end
          else
            RunSourceOperations(LSource, LOperations);
        finally
          LSource.Free;
        end;
      end;
    finally
      LOperations.Free;
    end;
  finally
    LGlobals.Free;
  end;
end;

procedure TQ3GoldenRunner.Run;
var
  LCases: TStringList;
  LIndex: Integer;
  LParts: TArray<string>;
  LOptions: TStringList;
  LPart: Integer;
begin
  LCases := ReadAllLines('cases.txt');
  try
    for LIndex := 0 to LCases.Count - 1 do
    begin
      if (LCases[LIndex] = '') or (LCases[LIndex][1] = '#') then
        Continue;
      LParts := LCases[LIndex].Split(['|']);
      Add('CASE|' + LParts[1] + '|' + LParts[0]);
      LOptions := TStringList.Create;
      try
        for LPart := 3 to High(LParts) do
          LOptions.Add(LParts[LPart]);
        RunCase(LParts[0], LParts[2], LOptions);
      finally
        LOptions.Free;
      end;
    end;
  finally
    LCases.Free;
  end;
end;

{ TTestQ3Golden }

function TTestQ3Golden.DataFolder: string;
begin
  Result := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\..\..\..\Tests\Data\Scanner\Q3\');
end;

procedure TTestQ3Golden.DovrebbeDareLeStesseRisposteDelVeroCodiceDiQuake3;
var
  LExpected: TStringList;
  LActual: TStringList;
  LRunner: TQ3GoldenRunner;
  LBytes: TBytes;
  LText: AnsiString;
  LIndex: Integer;
  LDifferences: Integer;
  LFirst: string;
  LCase: string;
begin
  LExpected := TStringList.Create;
  LActual := TStringList.Create;
  try
    LExpected.LineBreak := #10;
    LActual.LineBreak := #10;
    LBytes := TFile.ReadAllBytes(DataFolder + 'q3.golden.txt');
    SetString(LText, PAnsiChar(@LBytes[0]), Length(LBytes));
    LExpected.Text := StringReplace(string(LText), #13#10, #10, [rfReplaceAll]);
    LRunner := TQ3GoldenRunner.Create(DataFolder, LActual);
    try
      LRunner.Run;
    finally
      LRunner.Free;
    end;
    LDifferences := 0;
    LFirst := '';
    LCase := '';
    for LIndex := 0 to LExpected.Count - 1 do
    begin
      if (LExpected[LIndex].StartsWith('CASE|')) then
        LCase := LExpected[LIndex];
      if (LIndex >= LActual.Count) or (LExpected[LIndex] <> LActual[LIndex]) then
      begin
        Inc(LDifferences);
        if LFirst = '' then
          LFirst := Format('line %d of %s: expected "%s", got "%s"', [LIndex + 1, LCase, LExpected[LIndex],
            IfThen(LIndex < LActual.Count, LActual[LIndex], '<missing>')]);
      end;
    end;
    Assert.AreEqual(0, LDifferences, IntToStr(LDifferences) + ' lines differ; the first: ' + LFirst);
    Assert.AreEqual<Integer>(LExpected.Count, LActual.Count, 'number of lines');
  finally
    LActual.Free;
    LExpected.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestQ3Golden);

end.
