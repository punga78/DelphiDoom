{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the scanner library - the preprocessor                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Scanner.Preprocessor;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Generics.Collections, DUnitX.TestFramework,
  DelphiDoom.Logging.Intf, DelphiDoom.Logging.Recorder, DelphiDoom.Scanner.Preprocessor.Intf;

type
  /// <summary>
  ///   Fakes for the engine: files and lumps are the files of Tests\Data\Scanner\Preprocess,
  ///   the variables are the ones of the old test program (a name that starts with B, I or S
  ///   is a boolean, an integer or a text variable)
  /// </summary>
  TFakeIncludeSource = class(TInterfacedObject, IScriptIncludeSource)
  private
    FDirectory: string;
    function Load(const AFileName: string): string;
  public
    constructor Create(const ADirectory: string);
    function ReadFile(const AName: string): string;
    function ReadAllFiles(const AName: string): string;
    function ReadLump(const AName: string): string;
  end;

  TFakeCvarSetter = class(TInterfacedObject, ICvarSetter)
  public
    Calls: string;
    function EvaluateBoolean(const AText: string; ADefault: Boolean): Boolean;
    function TrySetBoolean(const AName: string; AValue: Boolean): Boolean;
    function TrySetInteger(const AName: string; AValue: Integer): Boolean;
    function TrySetString(const AName: string; const AValue: string): Boolean;
  end;

  TFakePaletteGenerator = class(TInterfacedObject, IPaletteGenerator)
  private
    FSetter: TFakeCvarSetter;
  public
    constructor Create(ASetter: TFakeCvarSetter);
    procedure Generate(const AArgument: string);
  end;

  /// <summary>
  ///   The files *.golden.txt in Tests\Data\Scanner\Preprocess were made by SC_Preprocess and
  ///   TDefinesPreprocessor of the old sc_utils.pas and sc_defines.pas, on the texts of the
  ///   same folder (the game define GAMEDEF is set): the text, the warnings, the calls to
  ///   the engine and the flag of the vanilla demo
  /// </summary>
  [TestFixture]
  [Category('scanner')]
  TTestScannerPreprocessor = class(TObject)
  private
    FRecorder: TLogRecorder;
    FSink: ILogSink;
    function DataPath(const AFileName: string): string;
    function Quote(const AText: string): string;
    function ReadAnsi(const AFileName: string): string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    [TestCase('blank_lines', 'blank_lines')]
    [TestCase('comments_include', 'comments_include')]
    [TestCase('defines', 'defines')]
    [TestCase('defines_errors', 'defines_errors')]
    [TestCase('depth', 'depth')]
    [TestCase('depth_twice', 'depth_twice')]
    [TestCase('directives', 'directives')]
    [TestCase('highchars', 'highchars')]
    [TestCase('include', 'include')]
    [TestCase('plain', 'plain')]
    procedure TestSameResultAsTheOldPreprocessor(const ASample: string);
  end;

implementation

uses
  DelphiDoom.Logging.Types, DelphiDoom.Logging.Factory, DelphiDoom.Scanner.Preprocessor,
  DelphiDoom.Scanner.Directive.Flag, DelphiDoom.Scanner.Directive.CvarForce,
  DelphiDoom.Scanner.Directive.CreatePalette;

{ TFakeIncludeSource }

constructor TFakeIncludeSource.Create(const ADirectory: string);
begin
  inherited Create;
  FDirectory := ADirectory;
end;

function TFakeIncludeSource.Load(const AFileName: string): string;
var
  LBytes: TBytes;
  LAnsi: AnsiString;
begin
  if not TFile.Exists(AFileName) then
    Exit('');
  LBytes := TFile.ReadAllBytes(AFileName);
  SetLength(LAnsi, Length(LBytes));
  if Length(LBytes) > 0 then
    Move(LBytes[0], LAnsi[1], Length(LBytes));
  Result := string(LAnsi);
end;

function TFakeIncludeSource.ReadFile(const AName: string): string;
begin
  Result := Load(TPath.Combine(FDirectory, 'files\' + AName));
end;

function TFakeIncludeSource.ReadAllFiles(const AName: string): string;
var
  LFiles: TArray<string>;
  LFile: string;
begin
  Result := '';
  if not TDirectory.Exists(TPath.Combine(FDirectory, 'files\' + AName)) then
    Exit;
  LFiles := TDirectory.GetFiles(TPath.Combine(FDirectory, 'files\' + AName));
  TArray.Sort<string>(LFiles);
  for LFile in LFiles do
    Result := Result + Load(LFile) + #13#10;
end;

function TFakeIncludeSource.ReadLump(const AName: string): string;
begin
  Result := Load(TPath.Combine(FDirectory, 'lumps\' + AName));
end;

{ TFakeCvarSetter }

function TFakeCvarSetter.EvaluateBoolean(const AText: string; ADefault: Boolean): Boolean;
begin
  if (AText = 'TRUE') or (AText = 'ON') or (AText = '1') then
    Result := True
  else if (AText = 'FALSE') or (AText = 'OFF') or (AText = '0') then
    Result := False
  else
    Result := ADefault;
end;

function TFakeCvarSetter.TrySetBoolean(const AName: string; AValue: Boolean): Boolean;
begin
  Result := Copy(AName, 1, 1) = 'B';
  if Result then
    Calls := Calls + 'BOOL ' + AName + ' ' + BoolToStr(AValue, True) + #13#10;
end;

function TFakeCvarSetter.TrySetInteger(const AName: string; AValue: Integer): Boolean;
begin
  Result := Copy(AName, 1, 1) = 'I';
  if Result then
    Calls := Calls + 'INT ' + AName + ' ' + IntToStr(AValue) + #13#10;
end;

function TFakeCvarSetter.TrySetString(const AName: string; const AValue: string): Boolean;
begin
  Result := Copy(AName, 1, 1) = 'S';
  if Result then
    Calls := Calls + 'STR ' + AName + ' ' + AValue + #13#10;
end;

{ TFakePaletteGenerator }

constructor TFakePaletteGenerator.Create(ASetter: TFakeCvarSetter);
begin
  inherited Create;
  FSetter := ASetter;
end;

procedure TFakePaletteGenerator.Generate(const AArgument: string);
begin
  FSetter.Calls := FSetter.Calls + 'PAL ' + AArgument + #13#10;
end;

{ TTestScannerPreprocessor }

procedure TTestScannerPreprocessor.Setup;
begin
  FRecorder := TLogRecorder.Create;
  FSink := FRecorder;
end;

procedure TTestScannerPreprocessor.TearDown;
begin
  FSink := nil;
  FRecorder := nil;
end;

function TTestScannerPreprocessor.DataPath(const AFileName: string): string;
begin
  Result := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
    '..\..\Tests\Data\Scanner\Preprocess\' + AFileName));
end;

function TTestScannerPreprocessor.Quote(const AText: string): string;
var
  LChar: Char;
begin
  Result := '';
  for LChar in AText do
    if LChar = '\' then
      Result := Result + '\\'
    else if (Ord(LChar) < 32) or (Ord(LChar) > 126) then
      Result := Result + '\x' + IntToHex(Ord(LChar), 2)
    else
      Result := Result + LChar;
end;

function TTestScannerPreprocessor.ReadAnsi(const AFileName: string): string;
var
  LBytes: TBytes;
  LAnsi: AnsiString;
begin
  LBytes := TFile.ReadAllBytes(AFileName);
  SetLength(LAnsi, Length(LBytes));
  if Length(LBytes) > 0 then
    Move(LBytes[0], LAnsi[1], Length(LBytes));
  Result := string(LAnsi);
end;

procedure TTestScannerPreprocessor.TestSameResultAsTheOldPreprocessor(const ASample: string);
var
  LLog: ILog;
  LSetter: TFakeCvarSetter;
  LSetterIntf: ICvarSetter;
  LVanilla: Boolean;
  LPreprocessor: TScriptPreprocessor;
  LText: string;
  LOut: TStringList;
  LExpected: TArray<string>;
  LMode: Integer;
  LIndex: Integer;
begin
  LText := ReadAnsi(DataPath(ASample + '.txt'));
  LOut := TStringList.Create;
  try
    for LMode := 0 to 1 do
    begin
      FRecorder.Clear;
      LLog := TLogFactory.CreateLog(TArray<ILogSink>.Create(FSink), nil);
      LSetter := TFakeCvarSetter.Create;
      LSetterIntf := LSetter;
      LVanilla := False;
      LPreprocessor := TScriptPreprocessor.Create(TFakeIncludeSource.Create(DataPath('')),
        TArray<IScriptDirective>.Create(
          TFlagDirective.Create(TArray<string>.Create('VANILLA_DEMO_OFF', '#VANILLA_DEMO_OFF',
            '{$VANILLA_DEMO_OFF}'),
            procedure
            begin
              LVanilla := True;
            end),
          TCvarForceDirective.Create(LSetterIntf, LLog),
          TCreatePaletteDirective.Create(TFakePaletteGenerator.Create(LSetter), LLog)),
        LLog);
      try
        LOut.Add('R' + IntToStr(LMode) + '|' +
          Quote(LPreprocessor.Preprocess(LText, LMode = 1, TArray<string>.Create('GAMEDEF'))));
      finally
        LPreprocessor.Free;
      end;
      LOut.Add('W' + IntToStr(LMode) + '|' + Quote(FRecorder.TextOf(TLogChannel.ErrorFile)));
      LOut.Add('C' + IntToStr(LMode) + '|' + Quote(LSetter.Calls));
      if LVanilla then
        LOut.Add('V' + IntToStr(LMode) + '|1')
      else
        LOut.Add('V' + IntToStr(LMode) + '|0');
    end;

    LExpected := TFile.ReadAllText(DataPath(ASample + '.golden.txt'), TEncoding.ASCII)
      .Split([#13#10], TStringSplitOptions.None);
    if (Length(LExpected) > 0) and (LExpected[High(LExpected)] = '') then
      SetLength(LExpected, Length(LExpected) - 1);
    Assert.AreEqual<Integer>(Length(LExpected), LOut.Count, 'the number of lines of ' + ASample);
    for LIndex := 0 to High(LExpected) do
      Assert.AreEqual(LExpected[LIndex], LOut[LIndex], 'line ' + IntToStr(LIndex + 1) + ' of ' + ASample);
  finally
    LOut.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestScannerPreprocessor);

end.
