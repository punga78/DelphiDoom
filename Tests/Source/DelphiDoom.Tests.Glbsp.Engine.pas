{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TGlbspEngine                                           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Glbsp.Engine;

{
  NOT covered here, on purpose: glbsp building the nodes of a real map. It
  needs a WAD (commercial or not) and takes time, which the tests must never
  depend on; it is proved by running the game, see "Build e prove" in
  CLAUDE.md.

  What is covered is everything the engine decides by itself: validation of
  the arguments, the errors for a missing input, and what happens when the
  process is started on a file that is not a WAD.

  What the code does with a missing WAD: BuildNodes checks the file before
  starting anything and returns GLBSP_ERR_WAD_NOT_FOUND. The historical code
  (gld_BuildNodes and I_ExecProgram) did not: I_ExecProgram only reports
  whether the process could be started and the pipe drained, it never reads
  the exit code, so a missing WAD would have been "successful" and the
  failure would have shown only as a missing GWA file at the next load. The
  engine reads the exit code and checks that the output file exists.
}

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, DUnitX.TestFramework,
  DelphiDoom.Glbsp.Intf;

type
  [TestFixture]
  [Category('glbsp')]
  TTestGlbspEngine = class(TObject)
  private
    // Always held as an interface: the engine is reference counted
    FGlbsp: IGlbsp;
    FTempFiles: TStringList;
    FWadPath: string;
    FGwaPath: string;
    function NewTempPath(const AExtension: string): string;
    function CreateTextFile(const AExtension: string): string;
    function BuildAnsi(const AWadPath, AGwaPath: AnsiString; AOptions,
      ATimeoutMs: Cardinal): Integer;
    function OutputText: string;
    function ErrorText: string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestExecutableSizeIsTheEmbeddedOne;
    [Test]
    procedure TestCreateWithoutExecutableRaises;
    [Test]
    procedure TestCreateWithEmptyExecutableRaises;

    [Test]
    procedure TestNilPathsAreRejected;
    [Test]
    procedure TestEmptyPathsAreRejected;
    [Test]
    procedure TestPathWithQuoteIsRejected;
    [Test]
    procedure TestPathWithControlCharacterIsRejected;
    [Test]
    procedure TestPathStartingWithDashIsRejected;
    [Test]
    procedure TestPathEndingWithBackslashIsRejected;
    [Test]
    procedure TestTooLongPathIsRejected;
    [Test]
    procedure TestUnknownOptionsAreRejected;
    [Test]
    [TestCase('Zero', '0')]
    [TestCase('Troppo alto', '3600001')]
    procedure TestTimeoutOutOfRangeIsRejected(ATimeoutMs: Integer);
    [Test]
    procedure TestOutputEqualToInputIsRejected;
    [Test]
    procedure TestRejectedCallLeavesAnErrorText;

    [Test]
    procedure TestMissingWadReturnsWadNotFound;
    [Test]
    procedure TestMissingWadDoesNotCreateTheOutput;
    [Test]
    procedure TestMissingWadErrorTextContainsThePath;

    [Test]
    procedure TestEngineWithNotAnExecutableReturnsLaunchError;
    [Test]
    procedure TestGlbspOnAFileThatIsNotAWadDoesNotSucceed;
    [Test]
    procedure TestVeryShortTimeoutNeverSucceeds;

    [Test]
    procedure TestTextsWithoutBufferReturnTheLength;
    [Test]
    procedure TestEmptyOutputTerminatesTheBuffer;
    [Test]
    procedure TestErrorTextTruncatesTheBuffer;
    [Test]
    procedure TestResultIsClearedByTheNextCall;
  end;

implementation

uses
  DelphiDoom.Glbsp.Engine;

const
  // Anything: the process is never run on a real map
  SOME_TIMEOUT_MS = 30000;

{ TTestGlbspEngine }

procedure TTestGlbspEngine.Setup;
begin
  FGlbsp := TGlbspEngine.Create;
  FTempFiles := TStringList.Create;
  FWadPath := NewTempPath('.wad');
  FGwaPath := NewTempPath('.gwa');
end;

procedure TTestGlbspEngine.TearDown;
var
  LIndex: Integer;
begin
  FGlbsp := nil;
  for LIndex := 0 to FTempFiles.Count - 1 do
    if FileExists(FTempFiles[LIndex]) then
      System.SysUtils.DeleteFile(FTempFiles[LIndex]);
  FreeAndNil(FTempFiles);
end;

function TTestGlbspEngine.NewTempPath(const AExtension: string): string;
begin
  Result := TPath.Combine(TPath.GetTempPath,
    'ddglbsp_test_' + Copy(GUIDToString(TGUID.NewGuid), 2, 36) + AExtension);
  FTempFiles.Add(Result);
end;

function TTestGlbspEngine.CreateTextFile(const AExtension: string): string;
begin
  Result := NewTempPath(AExtension);
  TFile.WriteAllText(Result, 'this is not a WAD file', TEncoding.ASCII);
end;

function TTestGlbspEngine.BuildAnsi(const AWadPath, AGwaPath: AnsiString;
  AOptions, ATimeoutMs: Cardinal): Integer;
begin
  Result := FGlbsp.BuildNodes(PAnsiChar(AWadPath), PAnsiChar(AGwaPath),
    AOptions, ATimeoutMs);
end;

function TTestGlbspEngine.OutputText: string;
var
  LText: AnsiString;
begin
  SetLength(LText, FGlbsp.GetOutput(nil, 0));
  if Length(LText) > 0 then
    FGlbsp.GetOutput(PAnsiChar(LText), Length(LText) + 1);
  Result := string(LText);
end;

function TTestGlbspEngine.ErrorText: string;
var
  LText: AnsiString;
begin
  SetLength(LText, FGlbsp.GetErrorText(nil, 0));
  if Length(LText) > 0 then
    FGlbsp.GetErrorText(PAnsiChar(LText), Length(LText) + 1);
  Result := string(LText);
end;

procedure TTestGlbspEngine.TestExecutableSizeIsTheEmbeddedOne;
begin
  Assert.AreEqual(57404, Integer(FGlbsp.GetExecutableSize));
end;

procedure TTestGlbspEngine.TestCreateWithoutExecutableRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      TGlbspEngine.Create(nil, 10);
    end, EArgumentNilException);
end;

procedure TTestGlbspEngine.TestCreateWithEmptyExecutableRaises;
var
  LByte: Byte;
begin
  LByte := 0;
  Assert.WillRaise(
    procedure
    begin
      TGlbspEngine.Create(@LByte, 0);
    end, EArgumentException);
end;

procedure TTestGlbspEngine.TestNilPathsAreRejected;
begin
  Assert.AreEqual(GLBSP_ERR_INVALID_ARGUMENT,
    FGlbsp.BuildNodes(nil, PAnsiChar('x.gwa'), GLBSP_OPT_NONE, SOME_TIMEOUT_MS));
  Assert.AreEqual(GLBSP_ERR_INVALID_ARGUMENT,
    FGlbsp.BuildNodes(PAnsiChar('x.wad'), nil, GLBSP_OPT_NONE, SOME_TIMEOUT_MS));
end;

procedure TTestGlbspEngine.TestEmptyPathsAreRejected;
begin
  Assert.AreEqual(GLBSP_ERR_INVALID_ARGUMENT,
    BuildAnsi('', 'x.gwa', GLBSP_OPT_NONE, SOME_TIMEOUT_MS));
  Assert.AreEqual(GLBSP_ERR_INVALID_ARGUMENT,
    BuildAnsi('x.wad', '', GLBSP_OPT_NONE, SOME_TIMEOUT_MS));
end;

procedure TTestGlbspEngine.TestPathWithQuoteIsRejected;
begin
  // A quote would end the quoted path and let the rest become other arguments
  Assert.AreEqual(GLBSP_ERR_INVALID_ARGUMENT,
    BuildAnsi('a".wad -o "b', 'x.gwa', GLBSP_OPT_NONE, SOME_TIMEOUT_MS));
  Assert.AreEqual(GLBSP_ERR_INVALID_ARGUMENT,
    BuildAnsi('x.wad', 'a".gwa', GLBSP_OPT_NONE, SOME_TIMEOUT_MS));
end;

procedure TTestGlbspEngine.TestPathWithControlCharacterIsRejected;
begin
  Assert.AreEqual(GLBSP_ERR_INVALID_ARGUMENT,
    BuildAnsi('a'#13#10'b.wad', 'x.gwa', GLBSP_OPT_NONE, SOME_TIMEOUT_MS));
end;

procedure TTestGlbspEngine.TestPathStartingWithDashIsRejected;
begin
  Assert.AreEqual(GLBSP_ERR_INVALID_ARGUMENT,
    BuildAnsi('-h', 'x.gwa', GLBSP_OPT_NONE, SOME_TIMEOUT_MS));
  Assert.AreEqual(GLBSP_ERR_INVALID_ARGUMENT,
    BuildAnsi('x.wad', '-o', GLBSP_OPT_NONE, SOME_TIMEOUT_MS));
end;

procedure TTestGlbspEngine.TestPathEndingWithBackslashIsRejected;
begin
  // A trailing backslash would escape the closing quote
  Assert.AreEqual(GLBSP_ERR_INVALID_ARGUMENT,
    BuildAnsi('C:\maps\', 'x.gwa', GLBSP_OPT_NONE, SOME_TIMEOUT_MS));
end;

procedure TTestGlbspEngine.TestTooLongPathIsRejected;
var
  LLong: AnsiString;
begin
  LLong := AnsiString(StringOfChar('a', GLBSP_MAX_PATH_LENGTH + 1));
  Assert.AreEqual(GLBSP_ERR_INVALID_ARGUMENT,
    BuildAnsi(LLong, 'x.gwa', GLBSP_OPT_NONE, SOME_TIMEOUT_MS));
end;

procedure TTestGlbspEngine.TestUnknownOptionsAreRejected;
begin
  Assert.AreEqual(GLBSP_ERR_INVALID_ARGUMENT,
    BuildAnsi('x.wad', 'x.gwa', GLBSP_OPT_ALL + 1, SOME_TIMEOUT_MS));
  Assert.AreEqual(GLBSP_ERR_INVALID_ARGUMENT,
    BuildAnsi('x.wad', 'x.gwa', $80000000, SOME_TIMEOUT_MS));
end;

procedure TTestGlbspEngine.TestTimeoutOutOfRangeIsRejected(ATimeoutMs: Integer);
begin
  Assert.AreEqual(GLBSP_ERR_INVALID_ARGUMENT,
    BuildAnsi('x.wad', 'x.gwa', GLBSP_OPT_NONE, Cardinal(ATimeoutMs)));
end;

procedure TTestGlbspEngine.TestOutputEqualToInputIsRejected;
begin
  // glbsp would overwrite the WAD it is reading
  FWadPath := CreateTextFile('.wad');
  Assert.AreEqual(GLBSP_ERR_INVALID_ARGUMENT,
    BuildAnsi(AnsiString(FWadPath), AnsiString(UpperCase(FWadPath)),
    GLBSP_OPT_NONE, SOME_TIMEOUT_MS));
  Assert.IsTrue(FileExists(FWadPath));
end;

procedure TTestGlbspEngine.TestRejectedCallLeavesAnErrorText;
begin
  BuildAnsi('', 'x.gwa', GLBSP_OPT_NONE, SOME_TIMEOUT_MS);

  Assert.IsTrue(ErrorText <> '');
  Assert.AreEqual(0, Integer(FGlbsp.GetExitCode));
  Assert.AreEqual('', OutputText);
end;

procedure TTestGlbspEngine.TestMissingWadReturnsWadNotFound;
begin
  Assert.AreEqual(GLBSP_ERR_WAD_NOT_FOUND,
    BuildAnsi(AnsiString(FWadPath), AnsiString(FGwaPath), GLBSP_OPT_QUIET,
    SOME_TIMEOUT_MS));
end;

procedure TTestGlbspEngine.TestMissingWadDoesNotCreateTheOutput;
begin
  BuildAnsi(AnsiString(FWadPath), AnsiString(FGwaPath), GLBSP_OPT_QUIET,
    SOME_TIMEOUT_MS);

  Assert.IsFalse(FileExists(FGwaPath));
end;

procedure TTestGlbspEngine.TestMissingWadErrorTextContainsThePath;
begin
  BuildAnsi(AnsiString(FWadPath), AnsiString(FGwaPath), GLBSP_OPT_QUIET,
    SOME_TIMEOUT_MS);

  Assert.IsTrue(Pos(FWadPath, ErrorText) > 0);
end;

procedure TTestGlbspEngine.TestEngineWithNotAnExecutableReturnsLaunchError;
var
  LGarbage: TBytes;
  LGlbsp: IGlbsp;
begin
  // The wad exists, so the engine gets to start the process; the bytes are
  // not a program, so Windows refuses to run them
  LGarbage := TEncoding.ASCII.GetBytes('this is not a Win32 program');
  LGlbsp := TGlbspEngine.Create(Pointer(LGarbage), Length(LGarbage));
  FWadPath := CreateTextFile('.wad');

  Assert.AreEqual(GLBSP_ERR_LAUNCH,
    LGlbsp.BuildNodes(PAnsiChar(AnsiString(FWadPath)),
    PAnsiChar(AnsiString(FGwaPath)), GLBSP_OPT_NONE, SOME_TIMEOUT_MS));
  Assert.IsFalse(FileExists(FGwaPath));
end;

procedure TTestGlbspEngine.TestGlbspOnAFileThatIsNotAWadDoesNotSucceed;
var
  LCode: Integer;
begin
  // Runs the real glbsp on a text file. What is expected from glbsp is a
  // non zero exit code (GLBSP_ERR_PROCESS_FAILED); a glbsp that exited with
  // zero without writing the output would give GLBSP_ERR_NO_OUTPUT. Both are
  // failures and either is accepted: the test pins down that the engine never
  // reports success, never leaves an output behind and never hangs
  FWadPath := CreateTextFile('.wad');

  LCode := BuildAnsi(AnsiString(FWadPath), AnsiString(FGwaPath),
    GLBSP_OPT_QUIET or GLBSP_OPT_NO_PROGRESS, SOME_TIMEOUT_MS);

  Assert.IsTrue((LCode = GLBSP_ERR_PROCESS_FAILED) or
    (LCode = GLBSP_ERR_NO_OUTPUT), 'Unexpected result ' + IntToStr(LCode));
  Assert.IsFalse(FileExists(FGwaPath));
  Assert.IsTrue(ErrorText <> '');
end;

procedure TTestGlbspEngine.TestVeryShortTimeoutNeverSucceeds;
var
  LCode: Integer;
begin
  // One millisecond: the process is normally killed (GLBSP_ERR_TIMEOUT), or
  // it is so quick to reject the file that it ends first
  // (GLBSP_ERR_PROCESS_FAILED). The outcome depends on the speed of the
  // machine, so only the impossible one is excluded. The deterministic test
  // of the timeout is the one of TGlbspProcess
  FWadPath := CreateTextFile('.wad');

  LCode := BuildAnsi(AnsiString(FWadPath), AnsiString(FGwaPath), GLBSP_OPT_QUIET,
    GLBSP_MIN_TIMEOUT_MS);

  Assert.IsTrue(LCode <> GLBSP_OK, 'Unexpected result ' + IntToStr(LCode));
  Assert.IsTrue((LCode = GLBSP_ERR_TIMEOUT) or (LCode = GLBSP_ERR_PROCESS_FAILED) or
    (LCode = GLBSP_ERR_NO_OUTPUT), 'Unexpected result ' + IntToStr(LCode));
  Assert.IsFalse(FileExists(FGwaPath));
end;

procedure TTestGlbspEngine.TestTextsWithoutBufferReturnTheLength;
begin
  BuildAnsi('', 'x.gwa', GLBSP_OPT_NONE, SOME_TIMEOUT_MS);

  // The error text is set, the output of the (never started) process is not
  Assert.AreEqual(0, Integer(FGlbsp.GetOutput(nil, 0)));
  Assert.IsTrue(FGlbsp.GetErrorText(nil, 0) > 0);
end;

procedure TTestGlbspEngine.TestEmptyOutputTerminatesTheBuffer;
var
  LBuffer: array[0..7] of AnsiChar;
begin
  BuildAnsi('', 'x.gwa', GLBSP_OPT_NONE, SOME_TIMEOUT_MS);
  FillChar(LBuffer, SizeOf(LBuffer), Ord('z'));

  Assert.AreEqual(0, Integer(FGlbsp.GetOutput(@LBuffer[0], SizeOf(LBuffer))));
  Assert.AreEqual(0, Integer(Ord(LBuffer[0])));
end;

procedure TTestGlbspEngine.TestErrorTextTruncatesTheBuffer;
var
  LBuffer: array[0..4] of AnsiChar;
  LFullLength: Cardinal;
begin
  BuildAnsi(AnsiString(FWadPath), AnsiString(FGwaPath), GLBSP_OPT_QUIET,
    SOME_TIMEOUT_MS);
  FillChar(LBuffer, SizeOf(LBuffer), Ord('z'));
  LFullLength := Cardinal(Length(ErrorText));

  // The whole length is returned, the buffer gets 4 characters and a terminator
  Assert.AreEqual(Integer(LFullLength),
    Integer(FGlbsp.GetErrorText(@LBuffer[0], SizeOf(LBuffer))));
  Assert.IsTrue(LFullLength > 4);
  Assert.AreEqual('WAD ', string(AnsiString(PAnsiChar(@LBuffer[0]))));
  Assert.AreEqual(0, Integer(Ord(LBuffer[4])));
end;

procedure TTestGlbspEngine.TestResultIsClearedByTheNextCall;
begin
  BuildAnsi(AnsiString(FWadPath), AnsiString(FGwaPath), GLBSP_OPT_QUIET,
    SOME_TIMEOUT_MS);
  Assert.IsTrue(ErrorText <> '');

  // A rejected call replaces the previous text, it does not append to it
  BuildAnsi('', 'x.gwa', GLBSP_OPT_NONE, SOME_TIMEOUT_MS);

  Assert.IsFalse(Pos('WAD file not found', ErrorText) > 0);
  Assert.IsTrue(ErrorText <> '');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGlbspEngine);

end.
