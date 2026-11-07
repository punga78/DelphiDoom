{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the scanner library - the preprocessor as a service     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Scanner.TextPreprocessor;

interface

uses
  System.SysUtils, System.Generics.Collections, DUnitX.TestFramework,
  DelphiDoom.Logging.Intf, DelphiDoom.Scanner.Preprocessor.Intf;

type
  /// <summary>Include files kept in memory by name</summary>
  TFakeMemoryIncludeSource = class(TInterfacedObject, IScriptIncludeSource)
  public
    Files: TDictionary<string, string>;
    constructor Create;
    destructor Destroy; override;
    function ReadFile(const AName: string): string;
    function ReadAllFiles(const AName: string): string;
    function ReadLump(const AName: string): string;
  end;

  /// <summary>The defines of the game, with the number of times they were asked</summary>
  TFakeDefinesSource = class(TInterfacedObject, IScriptDefinesSource)
  public
    Names: TArray<string>;
    Calls: Integer;
    function Defines: TArray<string>;
  end;

  /// <summary>A directive that takes the lines that start with its word and writes them down</summary>
  TFakeRecordingDirective = class(TInterfacedObject, IScriptDirective)
  public
    Word: string;
    Lines: TList<string>;
    constructor Create(const AWord: string);
    destructor Destroy; override;
    function Execute(const AUpperLine: string): Boolean;
  end;

  /// <summary>A log that counts the warnings</summary>
  TFakeCountingLog = class(TInterfacedObject, ILog)
  public
    Warnings: Integer;
    procedure Info(const AText: string);
    procedure Warning(const AText: string);
    procedure DevWarning(const AText: string);
    procedure Error(const AText: string);
  end;

  [TestFixture]
  [Category('scanner')]
  TTestScannerTextPreprocessor = class(TObject)
  private
    FSource: TFakeMemoryIncludeSource;
    FSourceIntf: IScriptIncludeSource;
    FDefines: TFakeDefinesSource;
    FDefinesIntf: IScriptDefinesSource;
    FLog: TFakeCountingLog;
    FLogIntf: ILog;
    function CreatePreprocessor(const ADirectives: TArray<IScriptDirective>): IScriptTextPreprocessor;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeDareErroreSenzaSorgente;
    [Test]
    procedure DovrebbeDareErroreSenzaDefine;
    [Test]
    procedure DovrebbeLasciareUgualeUnTestoSenzaDirettive;
    [Test]
    procedure DovrebbeDareLoStessoTestoDelPreprocessore;
    [Test]
    procedure DovrebbeUsareIDefineDelGioco;
    [Test]
    procedure DovrebbeChiedereIDefineAOgniTesto;
    [Test]
    procedure DovrebbeNonTenereIDefineDiUnTestoPerIlSuccessivo;
    [Test]
    procedure DovrebbeIncludereIFile;
    [Test]
    procedure DovrebbeAggiungereICommentiAgliIncludeSeRichiesto;
    [Test]
    procedure DovrebbePassareLeRigheAlleDirettive;
    [Test]
    procedure DovrebbeAvvisareIlLogDiUnEndifSenzaIf;
    [Test]
    procedure DovrebbeFunzionareSenzaLog;
  end;

implementation

uses
  DelphiDoom.Scanner.Preprocessor, DelphiDoom.Scanner.TextPreprocessor;

{ TFakeMemoryIncludeSource }

constructor TFakeMemoryIncludeSource.Create;
begin
  inherited Create;
  Files := TDictionary<string, string>.Create;
end;

destructor TFakeMemoryIncludeSource.Destroy;
begin
  Files.Free;
  inherited Destroy;
end;

function TFakeMemoryIncludeSource.ReadFile(const AName: string): string;
begin
  if not Files.TryGetValue(UpperCase(AName), Result) then
    Result := '';
end;

function TFakeMemoryIncludeSource.ReadAllFiles(const AName: string): string;
begin
  Result := ReadFile(AName);
end;

function TFakeMemoryIncludeSource.ReadLump(const AName: string): string;
begin
  Result := ReadFile(AName);
end;

{ TFakeDefinesSource }

function TFakeDefinesSource.Defines: TArray<string>;
begin
  Inc(Calls);
  Result := Names;
end;

{ TFakeRecordingDirective }

constructor TFakeRecordingDirective.Create(const AWord: string);
begin
  inherited Create;
  Word := AWord;
  Lines := TList<string>.Create;
end;

destructor TFakeRecordingDirective.Destroy;
begin
  Lines.Free;
  inherited Destroy;
end;

function TFakeRecordingDirective.Execute(const AUpperLine: string): Boolean;
begin
  Result := AUpperLine.StartsWith(Word);
  if Result then
    Lines.Add(AUpperLine);
end;

{ TFakeCountingLog }

procedure TFakeCountingLog.Info(const AText: string);
begin
end;

procedure TFakeCountingLog.Warning(const AText: string);
begin
  Inc(Warnings);
end;

procedure TFakeCountingLog.DevWarning(const AText: string);
begin
end;

procedure TFakeCountingLog.Error(const AText: string);
begin
end;

{ TTestScannerTextPreprocessor }

procedure TTestScannerTextPreprocessor.Setup;
begin
  FSource := TFakeMemoryIncludeSource.Create;
  FSourceIntf := FSource;
  FDefines := TFakeDefinesSource.Create;
  FDefinesIntf := FDefines;
  FLog := TFakeCountingLog.Create;
  FLogIntf := FLog;
end;

procedure TTestScannerTextPreprocessor.TearDown;
begin
  FSourceIntf := nil;
  FDefinesIntf := nil;
  FLogIntf := nil;
end;

function TTestScannerTextPreprocessor.CreatePreprocessor(
  const ADirectives: TArray<IScriptDirective>): IScriptTextPreprocessor;
begin
  Result := TScriptTextPreprocessor.Create(FSourceIntf, ADirectives, FDefinesIntf, FLogIntf);
end;

procedure TTestScannerTextPreprocessor.DovrebbeDareErroreSenzaSorgente;
begin
  Assert.WillRaise(
    procedure
    begin
      TScriptTextPreprocessor.Create(nil, nil, FDefinesIntf, FLogIntf).Free;
    end, EArgumentNilException);
end;

procedure TTestScannerTextPreprocessor.DovrebbeDareErroreSenzaDefine;
begin
  Assert.WillRaise(
    procedure
    begin
      TScriptTextPreprocessor.Create(FSourceIntf, nil, nil, FLogIntf).Free;
    end, EArgumentNilException);
end;

procedure TTestScannerTextPreprocessor.DovrebbeLasciareUgualeUnTestoSenzaDirettive;
begin
  Assert.AreEqual('ACTOR Foo'#13#10'{'#13#10'}'#13#10,
    CreatePreprocessor(nil).Preprocess('ACTOR Foo'#13#10'{'#13#10'}'#13#10, False));
end;

procedure TTestScannerTextPreprocessor.DovrebbeDareLoStessoTestoDelPreprocessore;
const
  STEXT = '#include "a.txt"'#13#10'#ifdef HERETIC'#13#10'heretic'#13#10'#else'#13#10 +
    'other'#13#10'#endif'#13#10'#define X'#13#10'#ifdef X'#13#10'x'#13#10'#endif'#13#10;
var
  LDirect: TScriptPreprocessor;
  LExpected: string;
begin
  FSource.Files.Add('A.TXT', 'included'#13#10);
  FDefines.Names := TArray<string>.Create('HERETIC');
  LDirect := TScriptPreprocessor.Create(FSourceIntf, nil, nil);
  try
    LExpected := LDirect.Preprocess(STEXT, True, TArray<string>.Create('HERETIC'));
  finally
    LDirect.Free;
  end;
  Assert.AreEqual(LExpected, CreatePreprocessor(nil).Preprocess(STEXT, True));
end;

procedure TTestScannerTextPreprocessor.DovrebbeUsareIDefineDelGioco;
const
  STEXT = '#ifdef DOOM'#13#10'doom'#13#10'#endif'#13#10'#ifndef HEXEN'#13#10'nothexen'#13#10'#endif'#13#10;
var
  LResult: string;
begin
  FDefines.Names := TArray<string>.Create('DOOM');
  LResult := CreatePreprocessor(nil).Preprocess(STEXT, False);
  Assert.Contains(LResult, 'doom');
  Assert.Contains(LResult, 'nothexen');
end;

procedure TTestScannerTextPreprocessor.DovrebbeChiedereIDefineAOgniTesto;
const
  STEXT = '#ifdef STRIFE'#13#10'strife'#13#10'#endif'#13#10;
var
  LPreprocessor: IScriptTextPreprocessor;
begin
  LPreprocessor := CreatePreprocessor(nil);
  Assert.DoesNotContain(LPreprocessor.Preprocess(STEXT, False), 'strife');
  // the list of the game can grow while the game starts
  FDefines.Names := TArray<string>.Create('STRIFE');
  Assert.Contains(LPreprocessor.Preprocess(STEXT, False), 'strife');
  Assert.AreEqual(2, FDefines.Calls);
end;

procedure TTestScannerTextPreprocessor.DovrebbeNonTenereIDefineDiUnTestoPerIlSuccessivo;
var
  LPreprocessor: IScriptTextPreprocessor;
begin
  LPreprocessor := CreatePreprocessor(nil);
  Assert.Contains(LPreprocessor.Preprocess('#define LOCAL'#13#10'#ifdef LOCAL'#13#10'first'#13#10'#endif'#13#10, False),
    'first');
  Assert.DoesNotContain(LPreprocessor.Preprocess('#ifdef LOCAL'#13#10'second'#13#10'#endif'#13#10, False),
    'second');
end;

procedure TTestScannerTextPreprocessor.DovrebbeIncludereIFile;
var
  LResult: string;
begin
  FSource.Files.Add('PART.TXT', 'from the include'#13#10);
  LResult := CreatePreprocessor(nil).Preprocess('before'#13#10'#include "part.txt"'#13#10'after'#13#10, False);
  Assert.Contains(LResult, 'from the include');
  Assert.IsTrue(Pos('before', LResult) < Pos('from the include', LResult));
  Assert.IsTrue(Pos('from the include', LResult) < Pos('after', LResult));
end;

procedure TTestScannerTextPreprocessor.DovrebbeAggiungereICommentiAgliIncludeSeRichiesto;
var
  LPreprocessor: IScriptTextPreprocessor;
begin
  FSource.Files.Add('PART.TXT', 'body'#13#10);
  LPreprocessor := CreatePreprocessor(nil);
  Assert.Contains(LPreprocessor.Preprocess('#include "part.txt"'#13#10, True), '//');
  Assert.DoesNotContain(LPreprocessor.Preprocess('#include "part.txt"'#13#10, False), '//');
end;

procedure TTestScannerTextPreprocessor.DovrebbePassareLeRigheAlleDirettive;
var
  LDirective: TFakeRecordingDirective;
  LDirectiveIntf: IScriptDirective;
  LResult: string;
begin
  LDirective := TFakeRecordingDirective.Create('#MYDIRECTIVE');
  LDirectiveIntf := LDirective;
  LResult := CreatePreprocessor(TArray<IScriptDirective>.Create(LDirectiveIntf)).Preprocess(
    'kept'#13#10'#mydirective 1 2'#13#10'kept too'#13#10, False);
  Assert.AreEqual(1, LDirective.Lines.Count);
  Assert.AreEqual('#MYDIRECTIVE 1 2', LDirective.Lines[0]);
  Assert.DoesNotContain(LResult, 'mydirective');
  Assert.Contains(LResult, 'kept too');
end;

procedure TTestScannerTextPreprocessor.DovrebbeAvvisareIlLogDiUnEndifSenzaIf;
begin
  CreatePreprocessor(nil).Preprocess('text'#13#10'#endif'#13#10, False);
  Assert.IsTrue(FLog.Warnings > 0);
end;

procedure TTestScannerTextPreprocessor.DovrebbeFunzionareSenzaLog;
var
  LPreprocessor: IScriptTextPreprocessor;
begin
  LPreprocessor := TScriptTextPreprocessor.Create(FSourceIntf, nil, FDefinesIntf, nil);
  Assert.Contains(LPreprocessor.Preprocess('text'#13#10'#endif'#13#10, False), 'text');
end;

end.
