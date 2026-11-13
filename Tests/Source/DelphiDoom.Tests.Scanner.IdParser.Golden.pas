{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the scanner library - parity of TIdParser, TIdDict and }
{  TIdLangDict with the real idLib of Doom 3                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Scanner.IdParser.Golden;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Generics.Collections, DUnitX.TestFramework,
  DelphiDoom.IdLib.Text.Token;

type
  /// <summary>
  ///   Runs the cases of Tests\Data\IdParser\parser.input.txt as the harness of the real idLib did (the
  ///   golden file is its output, see the README of Libs\Scanner) and writes the same lines
  /// </summary>
  TIdParserGoldenRunner = class
  strict private
    FOutput: TStrings;
    procedure Add(const ALine: string);
    function FormatToken(const ATag: string; var AToken: TIdToken): string;
    procedure RunOperations(const AOperations: TStrings; const AFlags: Integer; const AText, AName: AnsiString;
      const AGlobalDefines: TStrings; const AFiles: TDictionary<AnsiString, AnsiString>);
  public
    constructor Create(const AOutput: TStrings);
    procedure Run(const AInput: TStrings);
  end;

  [TestFixture]
  [Category('IdParser')]
  TTestIdParserGolden = class
  strict private
    function DataFolder: string;
    function LoadLines(const AName: string): TStringList;
  public
    [Test]
    procedure DovrebbeDareLeStesseRisposteDelVeroIdLib;
  end;

implementation

uses
  DelphiDoom.IdLib.Core.Intf, DelphiDoom.IdLib.Text.Types, DelphiDoom.IdLib.Text.Strings,
  DelphiDoom.IdLib.Math.Vec3, DelphiDoom.Scanner.IdParser, DelphiDoom.Scanner.IdParser.GlobalDefines,
  DelphiDoom.Scanner.IdDict, DelphiDoom.Scanner.IdLangDict, DelphiDoom.Scanner.IdCNumbers,
  DelphiDoom.Tests.Scanner.IdFakes;

{ TIdParserGoldenRunner }

constructor TIdParserGoldenRunner.Create(const AOutput: TStrings);
begin
  inherited Create;
  FOutput := AOutput;
end;

procedure TIdParserGoldenRunner.Add(const ALine: string);
begin
  FOutput.Add(ALine);
end;

function TIdParserGoldenRunner.FormatToken(const ATag: string; var AToken: TIdToken): string;
var
  LFloat: Single;
  LBits: Cardinal;
  LInt: Cardinal;
begin
  LFloat := 0;
  LInt := 0;
  if AToken.TokenType = TT_NUMBER then
  begin
    LFloat := AToken.GetFloatValue;
    LInt := AToken.GetUnsignedLongValue;
  end;
  LBits := PCardinal(@LFloat)^;
  Result := Format('%s %d %d L%d X%d F%d i=%u f=#%s |%s|', [ATag, AToken.TokenType, AToken.SubType, AToken.Line,
    AToken.LinesCrossed, AToken.Flags, LInt, LowerCase(IntToHex(LBits, 8)), TFakeIdLibLog.Escape(AToken.Text)]);
end;

procedure TIdParserGoldenRunner.RunOperations(const AOperations: TStrings; const AFlags: Integer;
  const AText, AName: AnsiString; const AGlobalDefines: TStrings; const AFiles: TDictionary<AnsiString, AnsiString>);
var
  LLog: TFakeIdLibLog;
  LLogIntf: IIdLibLog;
  LFileSystem: TFakeIdLibFileSystem;
  LFileSystemIntf: IIdLibFileSystem;
  LGlobals: TIdParserGlobalDefines;
  LParser, LAdmin: TIdParser;
  LLoaded: Boolean;
  LIndex: Integer;
  LOperation, LCommand, LArgument: string;
  LSpace, LCount: Integer;
  LToken: TIdToken;
  LText: AnsiString;
  LPair: TPair<AnsiString, AnsiString>;
  LBool: Boolean;
  LFloat: Single;
  LBits: Cardinal;

  procedure RunDictionary;
  var
    LDict: TIdDict;
    LIdx: Integer;
    LKeyValue: TIdKeyValue;
    LOk: Boolean;
  begin
    LDict := TIdDict.Create(LLogIntf);
    try
      LOk := LDict.Parse(LParser);
      Add(Format('dict ok=%d n=%d crc=%d', [Ord(LOk), LDict.GetNumKeyVals, LDict.Checksum]));
      for LIdx := 0 to LDict.GetNumKeyVals - 1 do
      begin
        LDict.TryGetKeyVal(LIdx, LKeyValue);
        Add('  ' + TFakeIdLibLog.Escape(LKeyValue.Key) + ' = ' + TFakeIdLibLog.Escape(LKeyValue.Value));
      end;
    finally
      LDict.Free;
    end;
  end;

  procedure RunDictionaryOperations;
  var
    LDict, LOther: TIdDict;
    LVector, LVector2: TIdVec3;
    LKeyValue: TIdKeyValue;
    LMatch: Integer;
  begin
    LDict := TIdDict.Create(LLogIntf);
    LOther := TIdDict.Create(LLogIntf);
    try
      LDict.SetValue('Alpha', '1');
      LDict.SetValue('beta', '2.5');
      LDict.SetValue('ALPHA', '3');
      LDict.SetValue('', 'x');
      LDict.SetInt('n', -7);
      LDict.SetBool('b', True);
      LDict.SetFloat('f', 1.5);
      LDict.SetValue('vec', '1 2 3');
      LDict.SetValue('monster_a', 'a');
      LDict.SetValue('monster_b', 'b');
      LDict.SetValue('Monster_c', 'c');
      Add(Format('n=%d alpha=%s beta=%s int=%d bool=%d f=%s', [LDict.GetNumKeyVals, string(LDict.GetString('alpha')),
        string(TIdStrings.FormatFixed(LDict.GetFloat('beta'), 6)), LDict.GetInt('n'), Ord(LDict.GetBool('b')),
        string(TIdStrings.FormatFixed(LDict.GetFloat('f'), 6))]));
      LVector := LDict.GetVector('vec');
      Add(Format('vec=%s %s %s', [string(TIdStrings.FormatFixed(LVector.X, 6)),
        string(TIdStrings.FormatFixed(LVector.Y, 6)), string(TIdStrings.FormatFixed(LVector.Z, 6))]));
      LVector2 := LDict.GetVector('none');
      Add(Format('vecdef=%s %s %s', [string(TIdStrings.FormatFixed(LVector2.X, 6)),
        string(TIdStrings.FormatFixed(LVector2.Y, 6)), string(TIdStrings.FormatFixed(LVector2.Z, 6))]));
      Add(Format('find=%d missing=%d', [LDict.FindKeyIndex('BETA'), LDict.FindKeyIndex('zzz')]));
      LMatch := LDict.MatchPrefix('monster_');
      while LMatch <> -1 do
      begin
        LDict.TryGetKeyVal(LMatch, LKeyValue);
        Add('m ' + string(LKeyValue.Key));
        LMatch := LDict.MatchPrefix('monster_', LMatch);
      end;
      LDict.Delete('beta');
      LDict.TryGetKeyVal(0, LKeyValue);
      Add(Format('after delete n=%d first=%s crc=%d', [LDict.GetNumKeyVals, string(LKeyValue.Key), LDict.Checksum]));
      LOther.SetValue('alpha', 'zzz');
      LOther.SetValue('extra', 'e');
      LOther.SetDefaults(LDict);
      Add(Format('defaults n=%d alpha=%s', [LOther.GetNumKeyVals, string(LOther.GetString('alpha'))]));
      LOther.Copy(LDict);
      Add(Format('copy n=%d alpha=%s', [LOther.GetNumKeyVals, string(LOther.GetString('alpha'))]));
    finally
      LOther.Free;
      LDict.Free;
    end;
  end;

  procedure RunLanguage(const AFileName: AnsiString);
  var
    LLang: TIdLangDict;
    LIdx: Integer;
    LKeyValue: TIdKeyValue;
    LLoadedOk: Boolean;
  begin
    LLang := TIdLangDict.Create(LLogIntf, LFileSystemIntf);
    try
      LLoadedOk := LLang.Load(AFileName, True);
      Add(Format('r=%d n=%d', [Ord(LLoadedOk), LLang.GetNumKeyVals]));
      for LIdx := 0 to LLang.GetNumKeyVals - 1 do
      begin
        LLang.TryGetKeyVal(LIdx, LKeyValue);
        Add('  ' + TFakeIdLibLog.Escape(LKeyValue.Key) + ' = ' + TFakeIdLibLog.Escape(LKeyValue.Value));
      end;
      Add('get1=' + TFakeIdLibLog.Escape(LLang.GetString('#str_00001')));
      Add('getx=' + TFakeIdLibLog.Escape(LLang.GetString('#str_99999')));
      Add('getp=' + TFakeIdLibLog.Escape(LLang.GetString('plain')));
      Add('add=' + string(LLang.AddString('Hello world')));
      Add('add2=' + string(LLang.AddString('Hello world')));
      Add('add3=' + string(LLang.AddString('12345')));
      Add('add4=' + string(LLang.AddString('gui::x')));
      Add('add5=' + string(LLang.AddString('Other text')));
      LLang.Save('saved.lang');
    finally
      LLang.Free;
    end;
  end;

begin
  LLog := TFakeIdLibLog.Create(FOutput);
  LLogIntf := LLog;
  LFileSystem := TFakeIdLibFileSystem.Create;
  LFileSystemIntf := LFileSystem;
  for LPair in AFiles do
    LFileSystem.Add(LPair.Key, LPair.Value);
  LFileSystem.OnWritten := procedure(const AFileName: AnsiString; const AData: TBytes)
    begin
      Add('SAVED ' + string(AFileName) + ': ' + TFakeIdLibLog.Escape(LFileSystem.Content(AFileName)));
    end;
  LGlobals := TIdParserGlobalDefines.Create;
  try
    LAdmin := TIdParser.Create(0, LLogIntf, LFileSystemIntf, LGlobals);
    try
      for LIndex := 0 to AGlobalDefines.Count - 1 do
      begin
        try
          Add(Format('gdef %s -> %d', [AGlobalDefines[LIndex], Ord(LAdmin.AddGlobalDefine(AnsiString(AGlobalDefines[LIndex])))]));
        except
          on E: Exception do
            Add('ERR ' + TFakeIdLibLog.Escape(AnsiString(E.Message)));
        end;
      end;
      LParser := TIdParser.Create(AFlags, LLogIntf, LFileSystemIntf, LGlobals);
      try
        LLoaded := False;
        try
          LLoaded := LParser.LoadMemory(AText, Length(AText), AName);
        except
          on E: Exception do
            Add('ERR ' + TFakeIdLibLog.Escape(AnsiString(E.Message)));
        end;
        Add(Format('loaded %d', [Ord(LLoaded)]));
        for LIndex := 0 to AOperations.Count - 1 do
        begin
          LOperation := AOperations[LIndex];
          LSpace := Pos(' ', LOperation);
          if LSpace > 0 then
          begin
            LCommand := Copy(LOperation, 1, LSpace - 1);
            LArgument := Copy(LOperation, LSpace + 1, MaxInt);
          end
          else
          begin
            LCommand := LOperation;
            LArgument := '';
          end;
          Add('> ' + LOperation);
          try
            LToken := TIdToken.Create;
            if LCommand = 'tokens' then
            begin
              LCount := 0;
              while LParser.ReadToken(LToken) do
              begin
                Add(FormatToken('T', LToken));
                Inc(LCount);
                if LCount > 2000 then
                  Break;
              end;
              Add(Format('end n=%d', [LCount]));
            end
            else if LCommand = 'expect' then
              Add(Format('r=%d', [Ord(LParser.ExpectTokenString(AnsiString(LArgument)))]))
            else if LCommand = 'check' then
              Add(Format('r=%d', [Ord(LParser.CheckTokenString(AnsiString(LArgument)))]))
            else if LCommand = 'peek' then
              Add(Format('r=%d', [Ord(LParser.PeekTokenString(AnsiString(LArgument)))]))
            else if LCommand = 'skipuntil' then
              Add(Format('r=%d', [Ord(LParser.SkipUntilString(AnsiString(LArgument)))]))
            else if LCommand = 'skiprest' then
              Add(Format('r=%d', [Ord(LParser.SkipRestOfLine)]))
            else if LCommand = 'skipbraced' then
              Add(Format('r=%d', [Ord(LParser.SkipBracedSection(True))]))
            else if LCommand = 'parseint' then
              Add(Format('v=%d', [LParser.ParseInt]))
            else if LCommand = 'parsebool' then
            begin
              LBool := LParser.ParseBool;
              Add(Format('v=%d', [Ord(LBool)]));
            end
            else if LCommand = 'parsefloat' then
            begin
              LFloat := LParser.ParseFloat;
              LBits := PCardinal(@LFloat)^;
              Add('v=#' + LowerCase(IntToHex(LBits, 8)));
            end
            else if LCommand = 'braced' then
            begin
              LParser.ParseBracedSection(LText, StrToIntDef(LArgument, 0));
              Add('s=' + TFakeIdLibLog.Escape(LText));
            end
            else if LCommand = 'restofline' then
            begin
              LParser.ParseRestOfLine(LText);
              Add('s=' + TFakeIdLibLog.Escape(LText));
            end
            else if LCommand = 'readonline' then
            begin
              LBool := LParser.ReadTokenOnLine(LToken);
              Add(Format('r=%d', [Ord(LBool)]));
              if LBool then
                Add(FormatToken('T', LToken));
            end
            else if LCommand = 'adddef' then
              Add(Format('r=%d', [Ord(LParser.AddDefine(AnsiString(LArgument)))]))
            else if LCommand = 'gdef' then
              Add(Format('r=%d', [Ord(LParser.AddGlobalDefine(AnsiString(LArgument)))]))
            else if LCommand = 'rmgdef' then
              Add(Format('r=%d', [Ord(LGlobals.Remove(AnsiString(LArgument)))]))
            else if LCommand = 'rmallgdef' then
              LGlobals.Clear
            else if LCommand = 'builtins' then
              LParser.AddBuiltinDefines
            else if LCommand = 'incpath' then
              LParser.SetIncludePath(AnsiString(LArgument))
            else if LCommand = 'setflags' then
              LParser.SetFlags(StrToIntDef(LArgument, 0))
            else if LCommand = 'marker' then
              LParser.SetMarker
            else if LCommand = 'frommarker' then
            begin
              LText := '';
              LParser.GetStringFromMarker(LText, False);
              Add('s=' + TFakeIdLibLog.Escape(LText));
            end
            else if LCommand = 'frommarkerclean' then
            begin
              LText := '';
              LParser.GetStringFromMarker(LText, True);
              Add('s=' + TFakeIdLibLog.Escape(LText));
            end
            else if LCommand = 'whitespace' then
            begin
              LParser.GetLastWhiteSpace(LText);
              Add('s=' + TFakeIdLibLog.Escape(LText));
            end
            else if LCommand = 'pos' then
              Add(Format('file=%s line=%d', [string(LParser.FileName), LParser.LineNum]))
            else if LCommand = 'free' then
              LParser.FreeSource
            else if LCommand = 'freekeep' then
              LParser.FreeSource(True)
            else if LCommand = 'dict' then
              RunDictionary
            else if LCommand = 'dictops' then
              RunDictionaryOperations
            else if LCommand = 'langload' then
              RunLanguage(AnsiString(LArgument))
            else
              Add('unknown op');
          except
            on E: Exception do
              Add('ERR ' + TFakeIdLibLog.Escape(AnsiString(E.Message)));
          end;
        end;
      finally
        LParser.Free;
      end;
    finally
      LAdmin.Free;
    end;
  finally
    LGlobals.Free;
  end;
end;

procedure TIdParserGoldenRunner.Run(const AInput: TStrings);
var
  LIndex: Integer;
  LLine, LName, LSourceName, LCurrentFile: string;
  LFlags: Integer;
  LText: AnsiString;
  LOperations, LGlobalDefines: TStringList;
  LFiles: TDictionary<AnsiString, AnsiString>;
  LTarget: Integer; // 0: none, 1: text, 2: file
begin
  LIndex := 0;
  while LIndex < AInput.Count do
  begin
    if Copy(AInput[LIndex], 1, 6) <> '@case ' then
    begin
      Inc(LIndex);
      Continue;
    end;
    LName := Copy(AInput[LIndex], 7, MaxInt);
    Inc(LIndex);
    LFlags := 0;
    LText := '';
    LSourceName := 'test';
    LTarget := 0;
    LCurrentFile := '';
    LOperations := TStringList.Create;
    LGlobalDefines := TStringList.Create;
    LFiles := TDictionary<AnsiString, AnsiString>.Create;
    try
      while (LIndex < AInput.Count) and (AInput[LIndex] <> '@end') do
      begin
        LLine := AInput[LIndex];
        if Copy(LLine, 1, 7) = '@flags ' then
        begin
          LFlags := StrToIntDef(Copy(LLine, 8, MaxInt), 0);
          LTarget := 0;
        end
        else if Copy(LLine, 1, 6) = '@name ' then
        begin
          LSourceName := Copy(LLine, 7, MaxInt);
          LTarget := 0;
        end
        else if Copy(LLine, 1, 4) = '@op ' then
        begin
          LOperations.Add(Copy(LLine, 5, MaxInt));
          LTarget := 0;
        end
        else if Copy(LLine, 1, 6) = '@gdef ' then
        begin
          LGlobalDefines.Add(Copy(LLine, 7, MaxInt));
          LTarget := 0;
        end
        else if Copy(LLine, 1, 6) = '@file ' then
        begin
          LCurrentFile := Copy(LLine, 7, MaxInt);
          LFiles.AddOrSetValue(AnsiString(LCurrentFile), '');
          LTarget := 2;
        end
        else if LLine = '@text' then
        begin
          LText := '';
          LTarget := 1;
        end
        else if LTarget = 1 then
          LText := LText + AnsiString(LLine) + #10
        else if LTarget = 2 then
          LFiles.AddOrSetValue(AnsiString(LCurrentFile), LFiles[AnsiString(LCurrentFile)] + AnsiString(LLine) + #10);
        Inc(LIndex);
      end;
      Inc(LIndex);
      if LOperations.Count = 0 then
        LOperations.Add('tokens');
      Add('## ' + LName);
      RunOperations(LOperations, LFlags, LText, AnsiString(LSourceName), LGlobalDefines, LFiles);
    finally
      LFiles.Free;
      LGlobalDefines.Free;
      LOperations.Free;
    end;
  end;
end;

{ TTestIdParserGolden }

function TTestIdParserGolden.DataFolder: string;
begin
  Result := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\..\Tests\Data\IdParser\');
end;

function ActualLine(const ALines: TStrings; const AIndex: Integer): string;
begin
  if AIndex < ALines.Count then
    Result := ALines[AIndex]
  else
    Result := '<missing>';
end;

function TTestIdParserGolden.LoadLines(const AName: string): TStringList;
var
  LBytes: TBytes;
  LText: AnsiString;
begin
  Result := TStringList.Create;
  LBytes := TFile.ReadAllBytes(DataFolder + AName);
  SetString(LText, PAnsiChar(@LBytes[0]), Length(LBytes));
  // the lines as they are, whatever the line end of the checkout (a CR before the LF is dropped)
  Result.LineBreak := #10;
  Result.Text := string(StringReplace(LText, #13#10, #10, [rfReplaceAll]));
end;

procedure TTestIdParserGolden.DovrebbeDareLeStesseRisposteDelVeroIdLib;
var
  LInput, LExpected, LActual: TStringList;
  LRunner: TIdParserGoldenRunner;
  LIndex, LDifferences: Integer;
  LCase, LFirst: string;
begin
  LInput := LoadLines('parser.input.txt');
  LExpected := LoadLines('parser.golden.txt');
  LActual := TStringList.Create;
  try
    LRunner := TIdParserGoldenRunner.Create(LActual);
    try
      LRunner.Run(LInput);
    finally
      LRunner.Free;
    end;
    LCase := '';
    LFirst := '';
    LDifferences := 0;
    for LIndex := 0 to LExpected.Count - 1 do
    begin
      if Copy(LExpected[LIndex], 1, 3) = '## ' then
        LCase := LExpected[LIndex];
      if (LIndex >= LActual.Count) or (LExpected[LIndex] <> LActual[LIndex]) then
      begin
        Inc(LDifferences);
        if LFirst = '' then
        begin
          LFirst := Format('line %d (%s): expected [%s] but got [%s]', [LIndex + 1, LCase, LExpected[LIndex],
            ActualLine(LActual, LIndex)]);
        end;
      end;
    end;
    if LDifferences > 0 then
      // for the comparison with the golden file by hand
      LActual.SaveToFile(ChangeFileExt(ParamStr(0), '.idparser.actual.txt'));
    Assert.AreEqual('', LFirst, Format('%d differences; the first: %s', [LDifferences, LFirst]));
    Assert.AreEqual(LExpected.Count, LActual.Count, 'number of lines');
  finally
    LActual.Free;
    LExpected.Free;
    LInput.Free;
  end;
end;


end.
