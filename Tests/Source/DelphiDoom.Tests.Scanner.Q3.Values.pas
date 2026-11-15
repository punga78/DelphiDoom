{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the scanner library - the script parser of Quake III   }
{  Arena with fake files and a fake log (what the golden of the real code      }
{  does not show: handles, global defines, the clock, the path of the files)   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Scanner.Q3.Values;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DUnitX.TestFramework,
  DelphiDoom.Scanner.Q3.Types, DelphiDoom.Scanner.Q3.Intf, DelphiDoom.Scanner.Q3.ScriptLoader.Intf,
  DelphiDoom.Scanner.Q3.GlobalDefines;

type
  /// <summary>Files in memory by path; the paths that were asked are kept</summary>
  TQ3MemoryFiles = class(TInterfacedObject, IQ3ScriptFiles)
  strict private
    FFiles: TDictionary<AnsiString, AnsiString>;
    FAsked: TStringList;
  public
    constructor Create(const AAsked: TStringList);
    destructor Destroy; override;
    procedure Add(const APath, AText: AnsiString);
    function TryRead(const APath: AnsiString; out AData: TBytes): Boolean;
  end;

  /// <summary>A log that keeps "level|text"</summary>
  TQ3ListLog = class(TInterfacedObject, IQ3ScriptLog)
  strict private
    FLines: TStringList;
  public
    constructor Create(const ALines: TStringList);
    procedure Print(const ALevel: Integer; const AMessage: AnsiString);
  end;

  [TestFixture]
  [Category('Q3Parser')]
  TTestQ3Values = class
  strict private
    FAsked: TStringList;
    FLines: TStringList;
    FFiles: TQ3MemoryFiles;
    FFilesIntf: IQ3ScriptFiles;
    FLog: IQ3ScriptLog;
    FLoader: IQ3ScriptLoader;
    FGlobals: TQ3GlobalDefines;
    function TokenTexts(const ASourceText: AnsiString; const ANow: TQ3NowProvider = nil;
      const ABuiltins: Boolean = False): string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeLeggereIFileDallaCartellaBase;
    [Test]
    procedure DovrebbeTroncareIlPercorsoACinquantaTreCaratteri;
    [Test]
    procedure DovrebbeDareNilPerUnFileCheNonCe;
    [Test]
    procedure DovrebbeCompattareIFileMaNonLeStringheInMemoria;
    [Test]
    procedure DovrebbeEspandereIDefineGlobali;
    [Test]
    procedure DovrebbeToglierDallaListaUnDefineGlobaleRimosso;
    [Test]
    procedure DovrebbeIgnorareUnDefineGlobaleNil;
    [Test]
    procedure DovrebbeEspandereDataEOraConUnOrologioIniettato;
    [Test]
    procedure DovrebbeDareFalsoPerUnDefineVuotoUsato;
    [Test]
    procedure DovrebbeTrattareComeSpazioIByteOltreIlCentoventisette;
    [Test]
    procedure DovrebbeUsareLaLetteraAComeUnicaMaiuscolaEsadecimale;
    [Test]
    procedure DovrebbeLeggereIlPuntoFinaleComeUnNumeroNegativo;
    [Test]
    procedure DovrebbeGestireLeManiglieDeiSorgenti;
    [Test]
    procedure DovrebbeSegnalareLeManiglieAncoraAperte;
    [Test]
    procedure DovrebbeEsaurireLeManiglieAlSessantaquattresimo;
    [Test]
    procedure DovrebbeSegnalareUnIncludeRicorsivoSenzaPerdereMemoria;
    [Test]
    procedure DovrebbeDareErroreSeDefinedNonHaUnNome;
    [Test]
    procedure DovrebbeDareDefineDaStringa;
  end;

implementation

uses
  DelphiDoom.Scanner.Q3.Script, DelphiDoom.Scanner.Q3.Source, DelphiDoom.Scanner.Q3.Define,
  DelphiDoom.Scanner.Q3.ScriptLoader, DelphiDoom.Scanner.Q3.SourceHandles, DelphiDoom.Scanner.Q3.Compressor;

{ TQ3MemoryFiles }

constructor TQ3MemoryFiles.Create(const AAsked: TStringList);
begin
  inherited Create;
  FFiles := TDictionary<AnsiString, AnsiString>.Create;
  FAsked := AAsked;
end;

destructor TQ3MemoryFiles.Destroy;
begin
  FFiles.Free;
  inherited;
end;

procedure TQ3MemoryFiles.Add(const APath, AText: AnsiString);
begin
  FFiles.AddOrSetValue(APath, AText);
end;

function TQ3MemoryFiles.TryRead(const APath: AnsiString; out AData: TBytes): Boolean;
var
  LText: AnsiString;
begin
  FAsked.Add(string(APath));
  Result := FFiles.TryGetValue(APath, LText);
  if Result then
  begin
    SetLength(AData, Length(LText));
    if Length(LText) > 0 then
      Move(LText[1], AData[0], Length(LText));
  end;
end;

{ TQ3ListLog }

constructor TQ3ListLog.Create(const ALines: TStringList);
begin
  inherited Create;
  FLines := ALines;
end;

procedure TQ3ListLog.Print(const ALevel: Integer; const AMessage: AnsiString);
begin
  FLines.Add(IntToStr(ALevel) + '|' + Trim(string(AMessage)));
end;

{ TTestQ3Values }

procedure TTestQ3Values.Setup;
begin
  FAsked := TStringList.Create;
  FLines := TStringList.Create;
  FFiles := TQ3MemoryFiles.Create(FAsked);
  FFilesIntf := FFiles;
  FLog := TQ3ListLog.Create(FLines);
  FLoader := TQ3ScriptLoader.Create(FFilesIntf, FLog);
  FGlobals := TQ3GlobalDefines.Create;
end;

procedure TTestQ3Values.TearDown;
begin
  FGlobals.Free;
  FLoader := nil;
  FLog := nil;
  FFilesIntf := nil;
  FFiles := nil;
  FLines.Free;
  FAsked.Free;
end;

function TTestQ3Values.TokenTexts(const ASourceText: AnsiString; const ANow: TQ3NowProvider;
  const ABuiltins: Boolean): string;
var
  LSource: TQ3Source;
  LBytes: TBytes;
  LToken: TQ3Token;
begin
  SetLength(LBytes, Length(ASourceText));
  if Length(ASourceText) > 0 then
    Move(ASourceText[1], LBytes[0], Length(ASourceText));
  LSource := TQ3Source.LoadMemory(LBytes, 'test', FLoader, FLog, FGlobals, ANow);
  try
    if ABuiltins then
      LSource.AddBuiltinDefines;
    Result := '';
    while LSource.ReadToken(LToken) do
      Result := Result + string(LToken.Text) + ' ';
    Result := Trim(Result);
  finally
    LSource.Free;
  end;
end;

procedure TTestQ3Values.DovrebbeLeggereIFileDallaCartellaBase;
var
  LScript: TQ3Script;
begin
  FFiles.Add('botfiles/a.c', 'x');
  FLoader.SetBaseFolder('botfiles');
  LScript := FLoader.LoadFile('a.c');
  try
    Assert.IsNotNull(LScript);
    Assert.AreEqual('a.c', string(LScript.FileName), 'the script keeps the name that was asked');
    Assert.AreEqual('botfiles/a.c', FAsked[0]);
  finally
    LScript.Free;
  end;
end;

procedure TTestQ3Values.DovrebbeTroncareIlPercorsoACinquantaTreCaratteri;
var
  LLong: AnsiString;
begin
  // Com_sprintf into a buffer of MAX_QPATH (64) characters keeps 63
  LLong := AnsiString(StringOfChar('d', 70));
  FLoader.SetBaseFolder('');
  Assert.IsNull(FLoader.LoadFile(LLong));
  Assert.AreEqual(63, Length(FAsked[0]));
end;

procedure TTestQ3Values.DovrebbeDareNilPerUnFileCheNonCe;
begin
  Assert.IsNull(TQ3Source.LoadFile('nothing.c', FLoader, FLog, FGlobals));
end;

procedure TTestQ3Values.DovrebbeCompattareIFileMaNonLeStringheInMemoria;
var
  LScript: TQ3Script;
  LToken: TQ3Token;
  LBytes: TBytes;
  LText: AnsiString;
begin
  FFiles.Add('c.c', 'a   // comment' + #10 + #10 + 'b');
  LScript := FLoader.LoadFile('c.c');
  try
    LScript.ReadToken(LToken);
    LScript.ReadToken(LToken);
    Assert.AreEqual('b', string(LToken.Text));
    // the comments and the empty lines are gone, so b is on line 2
    Assert.AreEqual(2, LToken.Line);
    Assert.IsFalse(LScript.EndOfScript, 'end_p is the length of the file before it is compressed');
  finally
    LScript.Free;
  end;
  LText := 'a   // comment' + #10 + #10 + 'b';
  SetLength(LBytes, Length(LText));
  Move(LText[1], LBytes[0], Length(LText));
  LScript := FLoader.LoadMemory(LBytes, 'mem');
  try
    LScript.ReadToken(LToken);
    LScript.ReadToken(LToken);
    Assert.AreEqual(3, LToken.Line, 'a script in memory is not compressed');
  finally
    LScript.Free;
  end;
  Assert.AreEqual('a b', string(TQ3ScriptCompressor.Compress('a  b')));
end;

procedure TTestQ3Values.DovrebbeEspandereIDefineGlobali;
begin
  FGlobals.Add(TQ3Source.DefineFromString('GLOBAL 12', FLoader, FLog));
  FGlobals.Add(TQ3Source.DefineFromString('TWICE(a) a + a', FLoader, FLog));
  Assert.AreEqual(2, FGlobals.Count);
  Assert.AreEqual('12 3 + 3', TokenTexts('GLOBAL TWICE(3)'));
end;

procedure TTestQ3Values.DovrebbeToglierDallaListaUnDefineGlobaleRimosso;
begin
  FGlobals.Add(TQ3Source.DefineFromString('ONE 1', FLoader, FLog));
  FGlobals.Add(TQ3Source.DefineFromString('TWO 2', FLoader, FLog));
  Assert.IsTrue(FGlobals.Remove('TWO'));
  Assert.IsFalse(FGlobals.Remove('TWO'));
  Assert.AreEqual(1, FGlobals.Count);
  // the C frees the define and leaves it linked: here the list is intact
  Assert.AreEqual('1 TWO', TokenTexts('ONE TWO'));
  FGlobals.Clear;
  Assert.AreEqual(0, FGlobals.Count);
end;

procedure TTestQ3Values.DovrebbeIgnorareUnDefineGlobaleNil;
begin
  FGlobals.Add(TQ3Source.DefineFromString('BAD(', FLoader, FLog));
  Assert.AreEqual(0, FGlobals.Count);
end;

procedure TTestQ3Values.DovrebbeEspandereDataEOraConUnOrologioIniettato;
var
  LNow: TQ3NowProvider;
begin
  LNow := function: TDateTime
    begin
      Result := EncodeDate(2026, 11, 5) + EncodeTime(8, 30, 5, 0);
    end;
  Assert.AreEqual('"Nov  5 2026" "08:30:05"', TokenTexts('__DATE__ __TIME__', LNow, True));
end;

procedure TTestQ3Values.DovrebbeDareFalsoPerUnDefineVuotoUsato;
begin
  // a define with no tokens "expands" to nothing and PC_ReadToken gives up there (as the C does)
  Assert.AreEqual('before', TokenTexts('#define EMPTY' + #10 + 'before' + #10 + 'EMPTY' + #10 + 'after'));
end;

procedure TTestQ3Values.DovrebbeTrattareComeSpazioIByteOltreIlCentoventisette;
begin
  // char is signed in the C: the bytes of UTF-8 are white space
  Assert.AreEqual('caf ab cd', TokenTexts('caf' + #$C3 + #$A9 + ' ab' + #$FF + 'cd'));
end;

procedure TTestQ3Values.DovrebbeUsareLaLetteraAComeUnicaMaiuscolaEsadecimale;
begin
  // (c >= 'A' && c <= 'A') in PS_ReadNumber: 0xFF is 0x then the name FF
  Assert.AreEqual('0x FF 0xa', TokenTexts('0xFF 0xa'));
end;

procedure TTestQ3Values.DovrebbeLeggereIlPuntoFinaleComeUnNumeroNegativo;
var
  LScript: TQ3Script;
  LBytes: TBytes;
  LToken: TQ3Token;
begin
  SetLength(LBytes, 2);
  LBytes[0] := Ord('1');
  LBytes[1] := Ord('.');
  LScript := FLoader.LoadMemory(LBytes, 'f');
  try
    Assert.IsTrue(LScript.ReadToken(LToken));
    // the zero that ends "1." is read as a digit: 1 + (0 - '0') / 10 = -3.8
    Assert.AreEqual(Cardinal($FFFFFFFD), LToken.IntValue);
    Assert.IsTrue(LToken.FloatValue.IsNegative);
  finally
    LScript.Free;
  end;
end;

procedure TTestQ3Values.DovrebbeGestireLeManiglieDeiSorgenti;
var
  LHandles: TQ3SourceHandles;
  LHandle: Integer;
  LToken: TQ3PcToken;
  LName: AnsiString;
  LLine: Integer;
begin
  FFiles.Add('h.c', 'name "text" 12 0.5');
  LHandles := TQ3SourceHandles.Create(FLoader, FLog, FGlobals);
  try
    LHandle := LHandles.Load('h.c');
    Assert.AreEqual(1, LHandle);
    Assert.IsTrue(LHandles.ReadToken(LHandle, LToken));
    Assert.AreEqual('name', string(LToken.Text));
    Assert.IsTrue(LHandles.ReadToken(LHandle, LToken));
    Assert.AreEqual('text', string(LToken.Text), 'the quotes of a string go');
    Assert.IsTrue(LHandles.ReadToken(LHandle, LToken));
    Assert.AreEqual(12, LToken.IntValue);
    Assert.IsTrue(LHandles.ReadToken(LHandle, LToken));
    Assert.AreEqual<Single>(0.5, LToken.FloatValue);
    Assert.IsTrue(LHandles.SourceFileAndLine(LHandle, LName, LLine));
    Assert.AreEqual('h.c', string(LName));
    Assert.AreEqual(1, LLine);
    Assert.IsTrue(LHandles.Release(LHandle));
    Assert.IsFalse(LHandles.Release(LHandle));
    Assert.IsFalse(LHandles.ReadToken(LHandle, LToken));
    Assert.IsFalse(LHandles.ReadToken(0, LToken));
    Assert.IsFalse(LHandles.SourceFileAndLine(99, LName, LLine));
    Assert.AreEqual(0, LHandles.Load('nope.c'));
  finally
    LHandles.Free;
  end;
end;

procedure TTestQ3Values.DovrebbeSegnalareLeManiglieAncoraAperte;
var
  LHandles: TQ3SourceHandles;
begin
  FFiles.Add('o.c', 'x');
  LHandles := TQ3SourceHandles.Create(FLoader, FLog, FGlobals);
  try
    LHandles.Load('o.c');
    LHandles.CheckOpen;
    Assert.AreEqual('3|file o.c still open in precompiler', FLines[0]);
  finally
    LHandles.Free;
  end;
end;

procedure TTestQ3Values.DovrebbeEsaurireLeManiglieAlSessantaquattresimo;
var
  LHandles: TQ3SourceHandles;
  LIndex: Integer;
begin
  FFiles.Add('m.c', 'x');
  LHandles := TQ3SourceHandles.Create(FLoader, FLog, FGlobals);
  try
    for LIndex := 1 to 63 do
      Assert.AreEqual(LIndex, LHandles.Load('m.c'));
    Assert.AreEqual(0, LHandles.Load('m.c'), 'the table has 63 usable handles');
    Assert.IsTrue(LHandles.Release(10));
    Assert.AreEqual(10, LHandles.Load('m.c'), 'the first free handle is used again');
  finally
    LHandles.Free;
  end;
end;

procedure TTestQ3Values.DovrebbeSegnalareUnIncludeRicorsivoSenzaPerdereMemoria;
var
  LSource: TQ3Source;
  LToken: TQ3Token;
begin
  FFiles.Add('r.c', 'a' + #10 + '#include "r.c"' + #10 + 'b');
  LSource := TQ3Source.LoadFile('r.c', FLoader, FLog, FGlobals);
  try
    while LSource.ReadToken(LToken) do
      ;
  finally
    LSource.Free;
  end;
  Assert.AreEqual('3|file r.c, line 2: r.c recursively included', FLines[0]);
end;

procedure TTestQ3Values.DovrebbeDareErroreSeDefinedNonHaUnNome;
begin
  // the C reads a null pointer here
  Assert.AreEqual('', TokenTexts('#if defined' + #10 + 'x' + #10 + '#endif'));
  Assert.IsTrue(FLines.Count > 0);
  Assert.IsTrue(FLines[0].Contains('defined without name'));
end;

procedure TTestQ3Values.DovrebbeDareDefineDaStringa;
var
  LDefine: TQ3Define;
begin
  LDefine := TQ3Source.DefineFromString('MAX(a, b) a > b', FLoader, FLog);
  try
    Assert.IsNotNull(LDefine);
    Assert.AreEqual('MAX', string(LDefine.Name));
    Assert.AreEqual(2, LDefine.NumParms);
    Assert.AreEqual(1, LDefine.FindParm('b'));
    Assert.AreEqual(-1, LDefine.FindParm('c'));
  finally
    LDefine.Free;
  end;
  Assert.IsNull(TQ3Source.DefineFromString('5 nope', FLoader, FLog));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestQ3Values);

end.
