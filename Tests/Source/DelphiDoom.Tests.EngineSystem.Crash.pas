{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the engine system library - the crash report           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.EngineSystem.Crash;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DUnitX.TestFramework,
  DelphiDoom.EngineSystem.Types, DelphiDoom.EngineSystem.Intf;

type
  /// <summary>The report as text</summary>
  TFakeCrashSink = class(TInterfacedObject, ICrashSink)
  public
    Text: AnsiString;
    procedure Write(AText: PAnsiChar);
  end;

  /// <summary>A memory made of the dwords that the test puts in it</summary>
  TFakeCrashMemory = class(TInterfacedObject, ICrashMemory)
  public
    Words: TDictionary<Cardinal, Cardinal>;
    constructor Create;
    destructor Destroy; override;
    function IsReadable(AAddress: Cardinal; ASize: Cardinal): Boolean;
    function ReadDWord(AAddress: Cardinal): Cardinal;
  end;

  /// <summary>A 64 bit memory made of the qwords that the test puts in it</summary>
  TFakeCrashMemory64 = class(TInterfacedObject, ICrashMemory64)
  public
    Words: TDictionary<UInt64, UInt64>;
    constructor Create;
    destructor Destroy; override;
    function IsReadable(AAddress: UInt64; ASize: Cardinal): Boolean;
    function ReadQWord(AAddress: UInt64): UInt64;
  end;

  [TestFixture]
  [Category('enginesystem')]
  TTestCrashReportWriter = class(TObject)
  private
    FSink: TFakeCrashSink;
    FSinkRef: ICrashSink;
    FMemory: TFakeCrashMemory;
    FMemoryRef: ICrashMemory;
    function Snapshot: TCrashSnapshot;
    function Report(const ASnapshot: TCrashSnapshot): string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeScrivereLIntestazioneEIRegistri;
    [Test]
    procedure DovrebbeScrivereLaViolazioneDiAccessoSoloSeLoE;
    [Test]
    procedure DovrebbeDireSeLIndirizzoEFuoriDallImmagine;
    [Test]
    procedure DovrebbeSeguireLaCatenaDiEbp;
    [Test]
    procedure DovrebbeFermarsiSeUnFrameNonELeggibile;
    [Test]
    procedure DovrebbeFermarsiSeLaCatenaNonSale;
    [Test]
    procedure DovrebbeFermarsiATrentaduePassi;
    [Test]
    procedure DovrebbeScrivereGliIndirizziFuoriDallImmagine;
    [Test]
    procedure DovrebbeCercareNelloStackSoloIndirizziDiCodice;
    [Test]
    procedure DovrebbeLeggereAlPiuCinquecentododiciParole;
  end;

  [TestFixture]
  [Category('enginesystem')]
  TTestCrashReportWriter64 = class(TObject)
  private
    FSink: TFakeCrashSink;
    FSinkRef: ICrashSink;
    FMemory: TFakeCrashMemory64;
    FMemoryRef: ICrashMemory64;
    function Snapshot: TCrashSnapshot64;
    function Report(const ASnapshot: TCrashSnapshot64): string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeScrivereLIntestazioneEIRegistri;
    [Test]
    procedure DovrebbeScrivereLaViolazioneDiAccessoSoloSeLoE;
    [Test]
    procedure DovrebbeDireSeLIndirizzoEFuoriDallImmagine;
    [Test]
    procedure DovrebbeScrivereGliIndirizziDellaCatenaDiUnwind;
    [Test]
    procedure DovrebbeScrivereAlPiuTrentaduePassi;
    [Test]
    procedure DovrebbeCercareNelloStackSoloIndirizziDiCodice;
    [Test]
    procedure DovrebbeLeggereAlPiuCinquecentododiciParole;
    [Test]
    procedure DovrebbeDareErroreSeMancaUnaDipendenza;
  end;

  [TestFixture]
  [Category('enginesystem')]
  TTestWindowsCrashLogger = class(TObject)
  public
{$IFDEF CPUX86}
    [Test]
    procedure DovrebbeScrivereIlFileDelRapporto;
    [Test]
    procedure DovrebbeScrivereLoStessoRapportoDelVecchioFiltro;
    [Test]
    procedure DovrebbeDireFalsoSeIlFileNonSiCrea;
{$ENDIF}
    [Test]
    procedure DovrebbeScrivereIlRapportoDiUnCrashVero;
    [Test]
    procedure DovrebbeDireFalsoSeIlFileNonSiCreaConUnContestoVuoto;
  end;

/// <summary>
///   When the program was started as a crash probe (CRASH_PROBE_SWITCH and a file name) installs the
///   crash logger, crashes with an access violation in a thread of the system and never returns;
///   otherwise it does nothing. The project of the tests calls it before it runs the fixtures
/// </summary>
procedure RunCrashProbeIfRequested;

const
  CRASH_PROBE_SWITCH = '-crashprobe';

implementation

uses
  System.IOUtils, DelphiDoom.EngineSystem.CrashReportWriter, DelphiDoom.EngineSystem.CrashReportWriter64,
  Winapi.Windows, DelphiDoom.EngineSystem.WindowsCrashLogger
{$IFDEF CPUX86}
  , DelphiDoom.Tests.EngineSystem.LegacyCrash
{$ENDIF}
  ;

function Hex8(AValue: Cardinal): string;
begin
  Result := IntToHex(AValue, 8) + ' ';
end;

{ TFakeCrashSink }

procedure TFakeCrashSink.Write(AText: PAnsiChar);
begin
  Text := Text + AnsiString(AText);
end;

{ TFakeCrashMemory }

constructor TFakeCrashMemory.Create;
begin
  inherited Create;
  Words := TDictionary<Cardinal, Cardinal>.Create;
end;

destructor TFakeCrashMemory.Destroy;
begin
  Words.Free;
  inherited Destroy;
end;

function TFakeCrashMemory.IsReadable(AAddress: Cardinal; ASize: Cardinal): Boolean;
var
  LOffset: Cardinal;
begin
  Result := True;
  LOffset := 0;
  while LOffset < ASize do
  begin
    if not Words.ContainsKey(AAddress + LOffset) then
      Result := False;
    Inc(LOffset, 4);
  end;
end;

function TFakeCrashMemory.ReadDWord(AAddress: Cardinal): Cardinal;
begin
  Result := Words[AAddress];
end;

{ TTestCrashReportWriter }

procedure TTestCrashReportWriter.Setup;
begin
  FSink := TFakeCrashSink.Create;
  FSinkRef := FSink;
  FMemory := TFakeCrashMemory.Create;
  FMemoryRef := FMemory;
end;

procedure TTestCrashReportWriter.TearDown;
begin
  FMemoryRef := nil;
  FSinkRef := nil;
end;

function TTestCrashReportWriter.Snapshot: TCrashSnapshot;
begin
  Result := Default(TCrashSnapshot);
  Result.ImageBase := $00400000;
  Result.ImageSize := $00100000;
  Result.ExceptionCode := $C0000094;
  Result.ExceptionAddress := $00412345;
  Result.ThreadId := 77;
  Result.Eip := $00412345;
  Result.Esp := $0019F000;
  Result.Ebp := 0;
end;

function TTestCrashReportWriter.Report(const ASnapshot: TCrashSnapshot): string;
var
  LWriter: TCrashReportWriter;
begin
  LWriter := TCrashReportWriter.Create(FSinkRef, FMemoryRef);
  try
    LWriter.Write(ASnapshot);
  finally
    LWriter.Free;
  end;
  Result := string(FSink.Text);
end;

procedure TTestCrashReportWriter.DovrebbeScrivereLIntestazioneEIRegistri;
var
  LSnapshot: TCrashSnapshot;
  LExpected: string;
begin
  LSnapshot := Snapshot;
  LSnapshot.Eax := $11111111;
  LSnapshot.Edi := $99999999;
  LExpected := 'DelphiDoom crash report'#13#10 +
    'ExceptionCode   ' + Hex8($C0000094) + #13#10 +
    'ExceptionAddr   ' + Hex8($00412345) + #13#10 +
    'ImageBase       ' + Hex8($00400000) + #13#10 +
    'ImageSize       ' + Hex8($00100000) + #13#10 +
    'ThreadId        ' + Hex8(77) + #13#10 +
    'Addr-ImageBase  ' + Hex8($00012345) + #13#10 +
    'EIP ' + Hex8($00412345) + #13#10 +
    'ESP ' + Hex8($0019F000) + #13#10 +
    'EBP ' + Hex8(0) + #13#10 +
    'EAX ' + Hex8($11111111) + #13#10 +
    'EBX ' + Hex8(0) + #13#10 +
    'ECX ' + Hex8(0) + #13#10 +
    'EDX ' + Hex8(0) + #13#10 +
    'ESI ' + Hex8(0) + #13#10 +
    'EDI ' + Hex8($99999999) + #13#10 +
    #13#10'EBP chain (return address - ImageBase):'#13#10 +
    #13#10'Stack scan (code addresses - ImageBase):'#13#10;
  Assert.AreEqual(LExpected, Report(LSnapshot));
end;

procedure TTestCrashReportWriter.DovrebbeScrivereLaViolazioneDiAccessoSoloSeLoE;
var
  LSnapshot: TCrashSnapshot;
begin
  LSnapshot := Snapshot;
  LSnapshot.ExceptionCode := CRASH_EXCEPTION_ACCESS_VIOLATION;
  LSnapshot.ParameterCount := 2;
  LSnapshot.Parameter0 := 1;
  LSnapshot.Parameter1 := $DEAD0000;
  Assert.IsTrue(Pos('AV operation    ' + Hex8(1) + #13#10'AV address      ' + Hex8($DEAD0000), Report(LSnapshot)) > 0);
end;

procedure TTestCrashReportWriter.DovrebbeDireSeLIndirizzoEFuoriDallImmagine;
var
  LSnapshot: TCrashSnapshot;
begin
  LSnapshot := Snapshot;
  LSnapshot.ExceptionAddress := $77000000;
  Assert.IsTrue(Pos('Addr is outside the executable image'#13#10, Report(LSnapshot)) > 0);
  Assert.AreEqual(0, Pos('Addr-ImageBase', string(FSink.Text)));
end;

procedure TTestCrashReportWriter.DovrebbeSeguireLaCatenaDiEbp;
var
  LSnapshot: TCrashSnapshot;
  LText: string;
begin
  LSnapshot := Snapshot;
  LSnapshot.Ebp := $1000;
  FMemory.Words.Add($1000, $2000);
  FMemory.Words.Add($1004, $00401234);
  FMemory.Words.Add($2000, $3000);
  FMemory.Words.Add($2004, $00402222);
  FMemory.Words.Add($3000, $0);
  FMemory.Words.Add($3004, $00403333);
  LText := Report(LSnapshot);
  Assert.IsTrue(Pos(#13#10'EBP chain (return address - ImageBase):'#13#10'  ' + Hex8($1234) + #13#10'  ' +
    Hex8($2222) + #13#10'  ' + Hex8($3333) + #13#10, LText) > 0);
end;

procedure TTestCrashReportWriter.DovrebbeFermarsiSeUnFrameNonELeggibile;
var
  LSnapshot: TCrashSnapshot;
begin
  LSnapshot := Snapshot;
  LSnapshot.Ebp := $1000;
  // the second word of the frame is missing
  FMemory.Words.Add($1000, $2000);
  Assert.IsTrue(Pos(#13#10'EBP chain (return address - ImageBase):'#13#10#13#10'Stack scan', Report(LSnapshot)) > 0);
end;

procedure TTestCrashReportWriter.DovrebbeFermarsiSeLaCatenaNonSale;
var
  LSnapshot: TCrashSnapshot;
  LText: string;
begin
  LSnapshot := Snapshot;
  LSnapshot.Ebp := $1000;
  FMemory.Words.Add($1000, $0800);
  FMemory.Words.Add($1004, $00401234);
  LText := Report(LSnapshot);
  // the frame is written, the next one is lower: the walk ends
  Assert.IsTrue(Pos('  ' + Hex8($1234) + #13#10, LText) > 0);
end;

procedure TTestCrashReportWriter.DovrebbeFermarsiATrentaduePassi;
var
  LSnapshot: TCrashSnapshot;
  LIndex: Integer;
  LAddress: Cardinal;
  LText: string;
  LCount: Integer;
  LPosition: Integer;
begin
  LSnapshot := Snapshot;
  LSnapshot.Ebp := $1000;
  for LIndex := 0 to 49 do
  begin
    LAddress := $1000 + Cardinal(LIndex) * 16;
    FMemory.Words.Add(LAddress, LAddress + 16);
    FMemory.Words.Add(LAddress + 4, $00401000);
  end;
  LText := Report(LSnapshot);
  LCount := 0;
  LPosition := Pos('  ' + Hex8($1000) + #13#10, LText);
  while LPosition > 0 do
  begin
    Inc(LCount);
    LPosition := Pos('  ' + Hex8($1000) + #13#10, LText, LPosition + 1);
  end;
  Assert.AreEqual(CRASH_MAX_FRAMES, LCount);
end;

procedure TTestCrashReportWriter.DovrebbeScrivereGliIndirizziFuoriDallImmagine;
var
  LSnapshot: TCrashSnapshot;
begin
  LSnapshot := Snapshot;
  LSnapshot.Ebp := $1000;
  FMemory.Words.Add($1000, $0);
  FMemory.Words.Add($1004, $77001234);
  Assert.IsTrue(Pos('  (outside) ' + Hex8($77001234) + #13#10, Report(LSnapshot)) > 0);
end;

procedure TTestCrashReportWriter.DovrebbeCercareNelloStackSoloIndirizziDiCodice;
var
  LSnapshot: TCrashSnapshot;
  LText: string;
begin
  LSnapshot := Snapshot;
  LSnapshot.Esp := $5000;
  FMemory.Words.Add($5000, $00400FFF);
  FMemory.Words.Add($5004, $00401000);
  FMemory.Words.Add($5008, $004FFFFF);
  FMemory.Words.Add($500C, $00500000);
  FMemory.Words.Add($5010, 5);
  LText := Report(LSnapshot);
  // below the first page of the image and after the end: no; the edges inside: yes
  Assert.IsTrue(Pos(#13#10'Stack scan (code addresses - ImageBase):'#13#10'  ' + Hex8($1000) + #13#10'  ' +
    Hex8($FFFFF) + #13#10, LText) > 0);
  Assert.AreEqual(0, Pos(Hex8($FFF) + #13#10, Copy(LText, Pos('Stack scan', LText), MaxInt)));
end;

procedure TTestCrashReportWriter.DovrebbeLeggereAlPiuCinquecentododiciParole;
var
  LSnapshot: TCrashSnapshot;
  LIndex: Integer;
  LText: string;
  LCount: Integer;
  LPosition: Integer;
begin
  LSnapshot := Snapshot;
  LSnapshot.Esp := $5000;
  for LIndex := 0 to 599 do
    FMemory.Words.Add($5000 + Cardinal(LIndex) * 4, $00401000);
  LText := Report(LSnapshot);
  LCount := 0;
  LPosition := Pos('  ' + Hex8($1000) + #13#10, LText);
  while LPosition > 0 do
  begin
    Inc(LCount);
    LPosition := Pos('  ' + Hex8($1000) + #13#10, LText, LPosition + 1);
  end;
  Assert.AreEqual(CRASH_STACK_DWORDS, LCount);
end;

function Hex16(AValue: UInt64): string;
begin
  Result := IntToHex(AValue, 16) + ' ';
end;

{ TFakeCrashMemory64 }

constructor TFakeCrashMemory64.Create;
begin
  inherited Create;
  Words := TDictionary<UInt64, UInt64>.Create;
end;

destructor TFakeCrashMemory64.Destroy;
begin
  Words.Free;
  inherited Destroy;
end;

function TFakeCrashMemory64.IsReadable(AAddress: UInt64; ASize: Cardinal): Boolean;
var
  LOffset: Cardinal;
begin
  Result := True;
  LOffset := 0;
  while LOffset < ASize do
  begin
    if not Words.ContainsKey(AAddress + LOffset) then
      Result := False;
    Inc(LOffset, 8);
  end;
end;

function TFakeCrashMemory64.ReadQWord(AAddress: UInt64): UInt64;
begin
  Result := Words[AAddress];
end;

{ TTestCrashReportWriter64 }

procedure TTestCrashReportWriter64.Setup;
begin
  FSink := TFakeCrashSink.Create;
  FSinkRef := FSink;
  FMemory := TFakeCrashMemory64.Create;
  FMemoryRef := FMemory;
end;

procedure TTestCrashReportWriter64.TearDown;
begin
  FMemoryRef := nil;
  FSinkRef := nil;
end;

function TTestCrashReportWriter64.Snapshot: TCrashSnapshot64;
begin
  Result := Default(TCrashSnapshot64);
  Result.ImageBase := $0000000140000000;
  Result.ImageSize := $00100000;
  Result.ExceptionCode := $C0000094;
  Result.ExceptionAddress := $0000000140012345;
  Result.ThreadId := 77;
  Result.Rip := $0000000140012345;
  Result.Rsp := $000000000019F000;
end;

function TTestCrashReportWriter64.Report(const ASnapshot: TCrashSnapshot64): string;
var
  LWriter: TCrashReportWriter64;
begin
  LWriter := TCrashReportWriter64.Create(FSinkRef, FMemoryRef);
  try
    LWriter.Write(ASnapshot);
  finally
    LWriter.Free;
  end;
  Result := string(FSink.Text);
end;

procedure TTestCrashReportWriter64.DovrebbeScrivereLIntestazioneEIRegistri;
var
  LSnapshot: TCrashSnapshot64;
  LExpected: string;
begin
  LSnapshot := Snapshot;
  LSnapshot.Rax := $1111111111111111;
  LSnapshot.R8 := $8888888888888888;
  LSnapshot.R15 := $FFFFFFFFFFFFFFFF;
  LExpected := 'DelphiDoom crash report (64 bit)'#13#10 +
    'ExceptionCode   ' + Hex16($C0000094) + #13#10 +
    'ExceptionAddr   ' + Hex16($0000000140012345) + #13#10 +
    'ImageBase       ' + Hex16($0000000140000000) + #13#10 +
    'ImageSize       ' + Hex16($00100000) + #13#10 +
    'ThreadId        ' + Hex16(77) + #13#10 +
    'Addr-ImageBase  ' + Hex16($00012345) + #13#10 +
    'RIP ' + Hex16($0000000140012345) + #13#10 +
    'RSP ' + Hex16($000000000019F000) + #13#10 +
    'RBP ' + Hex16(0) + #13#10 +
    'RAX ' + Hex16($1111111111111111) + #13#10 +
    'RBX ' + Hex16(0) + #13#10 +
    'RCX ' + Hex16(0) + #13#10 +
    'RDX ' + Hex16(0) + #13#10 +
    'RSI ' + Hex16(0) + #13#10 +
    'RDI ' + Hex16(0) + #13#10 +
    'R8  ' + Hex16($8888888888888888) + #13#10 +
    'R9  ' + Hex16(0) + #13#10 +
    'R10 ' + Hex16(0) + #13#10 +
    'R11 ' + Hex16(0) + #13#10 +
    'R12 ' + Hex16(0) + #13#10 +
    'R13 ' + Hex16(0) + #13#10 +
    'R14 ' + Hex16(0) + #13#10 +
    'R15 ' + Hex16($FFFFFFFFFFFFFFFF) + #13#10 +
    #13#10'Unwind chain (return address - ImageBase):'#13#10 +
    #13#10'Stack scan (code addresses - ImageBase):'#13#10;
  Assert.AreEqual(LExpected, Report(LSnapshot));
end;

procedure TTestCrashReportWriter64.DovrebbeScrivereLaViolazioneDiAccessoSoloSeLoE;
var
  LSnapshot: TCrashSnapshot64;
begin
  LSnapshot := Snapshot;
  Assert.AreEqual(0, Pos('AV operation', Report(LSnapshot)));
  FSink.Text := '';
  LSnapshot.ExceptionCode := CRASH_EXCEPTION_ACCESS_VIOLATION;
  LSnapshot.ParameterCount := 2;
  LSnapshot.Parameter0 := 1;
  LSnapshot.Parameter1 := $00007FF700001000;
  Assert.IsTrue(Pos('AV operation    ' + Hex16(1) + #13#10'AV address      ' + Hex16($00007FF700001000),
    Report(LSnapshot)) > 0);
end;

procedure TTestCrashReportWriter64.DovrebbeDireSeLIndirizzoEFuoriDallImmagine;
var
  LSnapshot: TCrashSnapshot64;
begin
  LSnapshot := Snapshot;
  LSnapshot.ExceptionAddress := $00007FFA77000000;
  Assert.IsTrue(Pos('Addr is outside the executable image'#13#10, Report(LSnapshot)) > 0);
  Assert.AreEqual(0, Pos('Addr-ImageBase', string(FSink.Text)));
end;

procedure TTestCrashReportWriter64.DovrebbeScrivereGliIndirizziDellaCatenaDiUnwind;
var
  LSnapshot: TCrashSnapshot64;
begin
  LSnapshot := Snapshot;
  LSnapshot.FrameCount := 3;
  LSnapshot.Frames[0] := $0000000140001234;
  LSnapshot.Frames[1] := $00007FFA77001234;
  LSnapshot.Frames[2] := $00000001400FFFFF;
  Assert.IsTrue(Pos(#13#10'Unwind chain (return address - ImageBase):'#13#10'  ' + Hex16($1234) + #13#10 +
    '  (outside) ' + Hex16($00007FFA77001234) + #13#10'  ' + Hex16($FFFFF) + #13#10, Report(LSnapshot)) > 0);
end;

procedure TTestCrashReportWriter64.DovrebbeScrivereAlPiuTrentaduePassi;
var
  LSnapshot: TCrashSnapshot64;
  LText: string;
  LCount: Integer;
  LPosition: Integer;
begin
  LSnapshot := Snapshot;
  LSnapshot.FrameCount := 1000;
  for LCount := 0 to CRASH_MAX_FRAMES_64 - 1 do
    LSnapshot.Frames[LCount] := $0000000140001000;
  LText := Report(LSnapshot);
  LCount := 0;
  LPosition := Pos('  ' + Hex16($1000) + #13#10, LText);
  while LPosition > 0 do
  begin
    Inc(LCount);
    LPosition := Pos('  ' + Hex16($1000) + #13#10, LText, LPosition + 1);
  end;
  Assert.AreEqual<Integer>(CRASH_MAX_FRAMES_64, LCount);
end;

procedure TTestCrashReportWriter64.DovrebbeCercareNelloStackSoloIndirizziDiCodice;
var
  LSnapshot: TCrashSnapshot64;
  LText: string;
begin
  LSnapshot := Snapshot;
  LSnapshot.Rsp := $5000;
  FMemory.Words.Add($5000, $0000000140000FFF);
  FMemory.Words.Add($5008, $0000000140001000);
  FMemory.Words.Add($5010, $00000001400FFFFF);
  FMemory.Words.Add($5018, $0000000140100000);
  FMemory.Words.Add($5020, 5);
  // a value that looks like a 32 bit address of the image must not count: the image is above 4 GB
  FMemory.Words.Add($5028, $0000000000401000);
  LText := Report(LSnapshot);
  Assert.IsTrue(Pos(#13#10'Stack scan (code addresses - ImageBase):'#13#10'  ' + Hex16($1000) + #13#10'  ' +
    Hex16($FFFFF) + #13#10, LText) > 0);
  Assert.AreEqual(0, Pos(Hex16($FFF) + #13#10, Copy(LText, Pos('Stack scan', LText), MaxInt)));
end;

procedure TTestCrashReportWriter64.DovrebbeLeggereAlPiuCinquecentododiciParole;
var
  LSnapshot: TCrashSnapshot64;
  LIndex: Integer;
  LText: string;
  LCount: Integer;
  LPosition: Integer;
begin
  LSnapshot := Snapshot;
  LSnapshot.Rsp := $5000;
  for LIndex := 0 to 599 do
    FMemory.Words.Add($5000 + UInt64(LIndex) * 8, $0000000140001000);
  LText := Report(LSnapshot);
  LCount := 0;
  LPosition := Pos('  ' + Hex16($1000) + #13#10, LText);
  while LPosition > 0 do
  begin
    Inc(LCount);
    LPosition := Pos('  ' + Hex16($1000) + #13#10, LText, LPosition + 1);
  end;
  Assert.AreEqual<Integer>(CRASH_STACK_QWORDS, LCount);
end;

procedure TTestCrashReportWriter64.DovrebbeDareErroreSeMancaUnaDipendenza;
begin
  Assert.WillRaise(
    procedure
    begin
      TCrashReportWriter64.Create(nil, FMemoryRef).Free;
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TCrashReportWriter64.Create(FSinkRef, nil).Free;
    end, EArgumentNilException);
end;
{ TTestWindowsCrashLogger }

{$IFDEF CPUX86}
type
  /// <summary>A made-up exception: the registers point at memory of the test</summary>
  TMadeUpCrash = record
    Frames: array[0..15] of Cardinal;
    Stack: array[0..599] of Cardinal;
    ExceptionRecord: TExceptionRecord;
    Context: TContext;
    Pointers: TExceptionPointers;
  end;
  PMadeUpCrash = ^TMadeUpCrash;

procedure MakeCrash(var ACrash: TMadeUpCrash; ACode: Cardinal);
var
  LIndex: Integer;
  LBase: Cardinal;
begin
  FillChar(ACrash, SizeOf(ACrash), 0);
  LBase := Cardinal(GetModuleHandle(nil));
  // three frames: each points to the next one, which is higher in memory
  ACrash.Frames[0] := Cardinal(@ACrash.Frames[4]);
  ACrash.Frames[1] := LBase + $1234;
  ACrash.Frames[4] := Cardinal(@ACrash.Frames[8]);
  ACrash.Frames[5] := LBase + $2345;
  ACrash.Frames[8] := 0;
  ACrash.Frames[9] := $77001111;
  for LIndex := 0 to 599 do
    if LIndex mod 7 = 0 then
      ACrash.Stack[LIndex] := LBase + $1000 + Cardinal(LIndex);
  ACrash.ExceptionRecord.ExceptionCode := ACode;
  ACrash.ExceptionRecord.ExceptionAddress := Pointer(LBase + $4321);
  ACrash.ExceptionRecord.NumberParameters := 2;
  ACrash.ExceptionRecord.ExceptionInformation[0] := 1;
  ACrash.ExceptionRecord.ExceptionInformation[1] := $DEAD0000;
  ACrash.Context.Eip := LBase + $4321;
  ACrash.Context.Esp := Cardinal(@ACrash.Stack[0]);
  ACrash.Context.Ebp := Cardinal(@ACrash.Frames[0]);
  ACrash.Context.Eax := $A1;
  ACrash.Context.Edi := $D1;
  ACrash.Pointers.ExceptionRecord := @ACrash.ExceptionRecord;
  ACrash.Pointers.ContextRecord := @ACrash.Context;
end;

procedure TTestWindowsCrashLogger.DovrebbeScrivereIlFileDelRapporto;
var
  LCrash: TMadeUpCrash;
  LFileName: string;
  LText: string;
begin
  MakeCrash(LCrash, CRASH_EXCEPTION_ACCESS_VIOLATION);
  LFileName := TPath.Combine(TPath.GetTempPath, 'enginesystem_crash_a.txt');
  TWindowsCrashLogger.Install(LFileName);
  try
    Assert.IsTrue(TWindowsCrashLogger.Report(@LCrash.Pointers));
    LText := TFile.ReadAllText(LFileName, TEncoding.ANSI);
    Assert.IsTrue(Pos('DelphiDoom crash report'#13#10, LText) = 1);
    Assert.IsTrue(Pos('AV address      DEAD0000', LText) > 0);
  finally
    TWindowsCrashLogger.Uninstall;
    System.SysUtils.DeleteFile(LFileName);
  end;
end;

procedure TTestWindowsCrashLogger.DovrebbeScrivereLoStessoRapportoDelVecchioFiltro;
var
  LCrash: TMadeUpCrash;
  LNewFile: string;
  LOldFile: string;
  LCode: Cardinal;
begin
  LNewFile := TPath.Combine(TPath.GetTempPath, 'enginesystem_crash_new.txt');
  LOldFile := TPath.Combine(TPath.GetTempPath, 'enginesystem_crash_old.txt');
  TWindowsCrashLogger.Install(LNewFile);
  try
    for LCode in [CRASH_EXCEPTION_ACCESS_VIOLATION, $C0000094, $80000003] do
    begin
      MakeCrash(LCrash, LCode);
      Assert.IsTrue(TWindowsCrashLogger.Report(@LCrash.Pointers));
      LegacyCrashFilter(@LCrash.Pointers, AnsiString(LOldFile));
      Assert.AreEqual(TFile.ReadAllText(LOldFile, TEncoding.ANSI), TFile.ReadAllText(LNewFile, TEncoding.ANSI));
    end;
  finally
    TWindowsCrashLogger.Uninstall;
    System.SysUtils.DeleteFile(LNewFile);
    System.SysUtils.DeleteFile(LOldFile);
  end;
end;

procedure TTestWindowsCrashLogger.DovrebbeDireFalsoSeIlFileNonSiCrea;
var
  LCrash: TMadeUpCrash;
begin
  MakeCrash(LCrash, 1);
  TWindowsCrashLogger.Install(TPath.Combine(TPath.GetTempPath, 'enginesystem_missing\x\crash.txt'));
  try
    Assert.IsFalse(TWindowsCrashLogger.Report(@LCrash.Pointers));
  finally
    TWindowsCrashLogger.Uninstall;
  end;
end;

{$ENDIF}

var
  // a variable, so that the compiler cannot see that the address is a bad one
  GProbeTarget: NativeUInt = $DEAD0000;

procedure CrashProbeLevel;
begin
  PInteger(GProbeTarget)^ := 1;
end;

function CrashProbeThread(AParameter: Pointer): DWORD; stdcall;
begin
  CrashProbeLevel;
  Result := 0;
end;

procedure RunCrashProbeIfRequested;
var
  LThread: THandle;
  LThreadId: DWORD;
begin
  if (ParamCount <> 2) or (ParamStr(1) <> CRASH_PROBE_SWITCH) then
    Exit;
  TWindowsCrashLogger.Install(ParamStr(2));
  // a thread of the system, not of the RTL: nothing of Delphi catches the access violation and
  // it reaches the unhandled exception filter, as a crash of the game does
  LThread := CreateThread(nil, 0, @CrashProbeThread, nil, 0, LThreadId);
  WaitForSingleObject(LThread, INFINITE);
  ExitProcess(0);
end;

procedure TTestWindowsCrashLogger.DovrebbeScrivereIlRapportoDiUnCrashVero;
var
  LFileName: string;
  LCommand: string;
  LStartup: TStartupInfo;
  LProcess: TProcessInformation;
  LExitCode: DWORD;
  LText: string;
{$IFDEF CPUX64}
  LLine: string;
  LInChain: Boolean;
  LFoundInImage: Boolean;
{$ENDIF}
begin
  LFileName := TPath.Combine(TPath.GetTempPath, 'enginesystem_crash_real_' + IntToStr(SizeOf(Pointer) * 8) + '.txt');
  System.SysUtils.DeleteFile(LFileName);
  LCommand := '"' + ParamStr(0) + '" ' + CRASH_PROBE_SWITCH + ' "' + LFileName + '"';
  UniqueString(LCommand);
  FillChar(LStartup, SizeOf(LStartup), 0);
  LStartup.cb := SizeOf(LStartup);
  Assert.IsTrue(CreateProcess(nil, PChar(LCommand), nil, nil, False, CREATE_NO_WINDOW, nil, nil, LStartup,
    LProcess), 'the probe starts');
  try
    Assert.AreEqual<Cardinal>(WAIT_OBJECT_0, WaitForSingleObject(LProcess.hProcess, 30000), 'the probe ends');
    GetExitCodeProcess(LProcess.hProcess, LExitCode);
    Assert.AreEqual<Cardinal>(CRASH_EXCEPTION_ACCESS_VIOLATION, LExitCode, 'exit code of the crash');
  finally
    CloseHandle(LProcess.hThread);
    CloseHandle(LProcess.hProcess);
  end;
  try
    Assert.IsTrue(FileExists(LFileName), 'crash.txt of the probe');
    LText := TFile.ReadAllText(LFileName, TEncoding.ANSI);
    Assert.IsTrue(Pos('DelphiDoom crash report', LText) = 1);
    Assert.IsTrue(Pos('AV address      ' + IntToHex(NativeUInt($DEAD0000), SizeOf(NativeUInt) * 2), LText) > 0,
      'address of the access violation');
    Assert.IsTrue(Pos('Addr-ImageBase  ', LText) > 0, 'the crash is in the image');
{$IFDEF CPUX64}
    // the return addresses of the unwinder: the caller of the faulting function is in the image too
    LInChain := False;
    LFoundInImage := False;
    for LLine in LText.Split([#13#10]) do
    begin
      if LLine.StartsWith('Unwind chain') then
        LInChain := True
      else if LLine.StartsWith('Stack scan') then
        LInChain := False
      else if LInChain and LLine.StartsWith('  ') and not LLine.StartsWith('  (outside)') then
        LFoundInImage := True;
    end;
    Assert.IsTrue(LFoundInImage, 'a return address inside the image in the unwind chain');
{$ELSE}
    Assert.IsTrue(Pos('EBP chain', LText) > 0);
{$ENDIF}
  finally
    System.SysUtils.DeleteFile(LFileName);
  end;
end;

procedure TTestWindowsCrashLogger.DovrebbeDireFalsoSeIlFileNonSiCreaConUnContestoVuoto;
var
  LPointers: TExceptionPointers;
  LRecord: TExceptionRecord;
  LContext: TContext;
begin
  FillChar(LRecord, SizeOf(LRecord), 0);
  FillChar(LContext, SizeOf(LContext), 0);
  LPointers.ExceptionRecord := @LRecord;
  LPointers.ContextRecord := @LContext;
  TWindowsCrashLogger.Install(TPath.Combine(TPath.GetTempPath, 'enginesystem_missing\x\crash.txt'));
  try
    Assert.IsFalse(TWindowsCrashLogger.Report(@LPointers));
  finally
    TWindowsCrashLogger.Uninstall;
  end;
end;

end.
