{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TGlbspEngine                                           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Glbsp.Engine;

{
  The engine builds the nodes in the process. The complete comparison with
  the output of the glbsp program is in DelphiDoom.Tests.Glbsp.Wad.Builder;
  here is what the engine decides by itself: validation of the arguments, the
  errors for a missing or bad input, the files it writes and the texts.
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
    function SamplePath: string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

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
    procedure TestFileThatIsNotAWadFails;
    [Test]
    procedure TestBuildsAGwaFile;
    [Test]
    procedure TestBuildsAWholeWadWhenTheOutputIsNotGwa;
    [Test]
    procedure TestOutputIsOverwritten;

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
  // Anything: the timeout is only checked, the build is not interrupted
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

procedure TTestGlbspEngine.TestFileThatIsNotAWadFails;
begin
  FWadPath := CreateTextFile('.wad');

  Assert.AreEqual(GLBSP_ERR_PROCESS_FAILED, BuildAnsi(AnsiString(FWadPath),
    AnsiString(FGwaPath), GLBSP_OPT_QUIET or GLBSP_OPT_NO_PROGRESS, SOME_TIMEOUT_MS));
  Assert.IsFalse(FileExists(FGwaPath));
  Assert.IsTrue(ErrorText <> '');
  Assert.IsTrue(FGlbsp.GetExitCode <> 0);
end;

function TTestGlbspEngine.SamplePath: string;
begin
  Result := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
    '..\..\Tests\Data\glbsp_map01.wad'));
end;

procedure TTestGlbspEngine.TestBuildsAGwaFile;
var
  LBytes: TBytes;
begin
  if not TFile.Exists(SamplePath) then
  begin
    Assert.Pass('Tests\Data\glbsp_map01.wad not found');
    Exit;
  end;

  Assert.AreEqual(GLBSP_OK, BuildAnsi(AnsiString(SamplePath), AnsiString(FGwaPath),
    GLBSP_OPT_QUIET or GLBSP_OPT_NO_PROGRESS, SOME_TIMEOUT_MS));

  LBytes := TFile.ReadAllBytes(FGwaPath);
  Assert.IsTrue(Length(LBytes) > 12);
  Assert.AreEqual(Ord('P'), Integer(LBytes[0]));
  // Only the six GL lumps: the original ones are not copied to a GWA
  Assert.AreEqual(6, PInteger(@LBytes[4])^);
  Assert.AreEqual(0, Integer(FGlbsp.GetExitCode));
end;

procedure TTestGlbspEngine.TestBuildsAWholeWadWhenTheOutputIsNotGwa;
var
  LBytes: TBytes;
begin
  if not TFile.Exists(SamplePath) then
  begin
    Assert.Pass('Tests\Data\glbsp_map01.wad not found');
    Exit;
  end;
  FGwaPath := NewTempPath('.wad');

  Assert.AreEqual(GLBSP_OK, BuildAnsi(AnsiString(SamplePath), AnsiString(FGwaPath),
    GLBSP_OPT_NONE, SOME_TIMEOUT_MS));

  // The 11 lumps of the level plus the GL marker and its 5 lumps
  LBytes := TFile.ReadAllBytes(FGwaPath);
  Assert.AreEqual(17, PInteger(@LBytes[4])^);
end;

procedure TTestGlbspEngine.TestOutputIsOverwritten;
begin
  if not TFile.Exists(SamplePath) then
  begin
    Assert.Pass('Tests\Data\glbsp_map01.wad not found');
    Exit;
  end;
  TFile.WriteAllText(FGwaPath, 'old', TEncoding.ASCII);

  Assert.AreEqual(GLBSP_OK, BuildAnsi(AnsiString(SamplePath), AnsiString(FGwaPath),
    GLBSP_OPT_NONE, SOME_TIMEOUT_MS));

  Assert.IsTrue(TFile.GetSize(FGwaPath) > 1000);
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
