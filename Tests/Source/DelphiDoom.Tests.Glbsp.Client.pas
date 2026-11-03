{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TGlbspClient                                           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Glbsp.Client;

{
  The client is tested against a fake IGlbsp that records the calls it
  receives: no process is ever started. What is NOT covered here is glbsp
  building real nodes: it needs a WAD, see "Build e prove" in CLAUDE.md.
}

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework,
  DelphiDoom.Glbsp.Intf, DelphiDoom.Glbsp.Client;

type
  /// <summary>
  ///   IGlbsp that writes the calls it receives into a log and answers with
  ///   the results it has been told to give
  /// </summary>
  TFakeGlbsp = class(TInterfacedObject, IGlbsp)
  private
    FLog: TStrings;
    FReturnCode: Integer;
    FExitCode: Cardinal;
    FOutput: AnsiString;
    FErrorText: AnsiString;
    class function CopyText(const AText: AnsiString; ABuffer: PAnsiChar;
      ABufferSize: Cardinal): Cardinal; static;
  public
    constructor Create(ALog: TStrings);
    function GetExecutableSize: Cardinal; stdcall;
    function BuildNodes(AWadPath, AGwaPath: PAnsiChar; AOptions,
      ATimeoutMs: Cardinal): Integer; stdcall;
    function GetExitCode: Cardinal; stdcall;
    function GetOutput(ABuffer: PAnsiChar; ABufferSize: Cardinal): Cardinal; stdcall;
    function GetErrorText(ABuffer: PAnsiChar; ABufferSize: Cardinal): Cardinal; stdcall;
    property ReturnCode: Integer read FReturnCode write FReturnCode;
    property ExitCode: Cardinal read FExitCode write FExitCode;
    property Output: AnsiString read FOutput write FOutput;
    property ErrorText: AnsiString read FErrorText write FErrorText;
  end;

  [TestFixture]
  [Category('glbsp')]
  TTestGlbspClient = class(TObject)
  private
    FLog: TStringList;
    FFake: TFakeGlbsp;
    FGlbsp: IGlbsp;
    FClient: TGlbspClient;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestCreateWithoutGlbspRaises;
    [Test]
    procedure TestExecutableSizeIsForwarded;
    [Test]
    procedure TestDefaultOptionsAreQuietAndNoProgress;
    [Test]
    procedure TestOptionsAreConvertedToFlags;
    [Test]
    procedure TestNoOptionsPassNoFlags;
    [Test]
    procedure TestTimeoutIsForwarded;
    [Test]
    procedure TestDefaultTimeoutIsFiveMinutes;
    [Test]
    procedure TestPathsAreForwardedAsAnsi;
    [Test]
    procedure TestSuccessKeepsOutputAndExitCode;
    [Test]
    procedure TestFailureRaisesWithCodeAndDetail;
    [Test]
    procedure TestFailureKeepsOutputAndExitCode;
    [Test]
    procedure TestPathNotInAnsiCodePageRaisesWithoutCalling;
  end;

implementation

{ TFakeGlbsp }

constructor TFakeGlbsp.Create(ALog: TStrings);
begin
  inherited Create;
  FLog := ALog;
  FReturnCode := GLBSP_OK;
end;

class function TFakeGlbsp.CopyText(const AText: AnsiString; ABuffer: PAnsiChar;
  ABufferSize: Cardinal): Cardinal;
var
  LCount: Cardinal;
begin
  Result := Length(AText);
  if not Assigned(ABuffer) or (ABufferSize = 0) then
    Exit;

  LCount := Result;
  if LCount > ABufferSize - 1 then
    LCount := ABufferSize - 1;
  if LCount > 0 then
    Move(PAnsiChar(AText)^, ABuffer^, LCount);
  ABuffer[LCount] := #0;
end;

function TFakeGlbsp.GetExecutableSize: Cardinal;
begin
  Result := 1234;
end;

function TFakeGlbsp.BuildNodes(AWadPath, AGwaPath: PAnsiChar; AOptions,
  ATimeoutMs: Cardinal): Integer;
begin
  FLog.Add(Format('BuildNodes %s|%s|%d|%d',
    [string(AnsiString(AWadPath)), string(AnsiString(AGwaPath)), AOptions,
    ATimeoutMs]));
  Result := FReturnCode;
end;

function TFakeGlbsp.GetExitCode: Cardinal;
begin
  Result := FExitCode;
end;

function TFakeGlbsp.GetOutput(ABuffer: PAnsiChar; ABufferSize: Cardinal): Cardinal;
begin
  Result := CopyText(FOutput, ABuffer, ABufferSize);
end;

function TFakeGlbsp.GetErrorText(ABuffer: PAnsiChar; ABufferSize: Cardinal): Cardinal;
begin
  Result := CopyText(FErrorText, ABuffer, ABufferSize);
end;

{ TTestGlbspClient }

procedure TTestGlbspClient.Setup;
begin
  FLog := TStringList.Create;
  FFake := TFakeGlbsp.Create(FLog);
  // The interface keeps the fake alive; FFake is only for configuring it
  FGlbsp := FFake;
  FClient := TGlbspClient.Create(FGlbsp);
end;

procedure TTestGlbspClient.TearDown;
begin
  FreeAndNil(FClient);
  FFake := nil;
  FGlbsp := nil;
  FreeAndNil(FLog);
end;

procedure TTestGlbspClient.TestCreateWithoutGlbspRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      TGlbspClient.Create(nil).Free;
    end, EArgumentNilException);
end;

procedure TTestGlbspClient.TestExecutableSizeIsForwarded;
begin
  Assert.AreEqual(1234, Integer(FClient.ExecutableSize));
end;

procedure TTestGlbspClient.TestDefaultOptionsAreQuietAndNoProgress;
begin
  // Same as the command line of gld_BuildNodes: -q -xp
  FClient.BuildNodes('a.wad', 'a.gwa');

  Assert.AreEqual(1, FLog.Count);
  Assert.AreEqual('BuildNodes a.wad|a.gwa|3|300000', FLog[0]);
end;

procedure TTestGlbspClient.TestOptionsAreConvertedToFlags;
begin
  FClient.BuildNodes('a.wad', 'a.gwa', [goQuiet, goNoProgress, goHexen]);

  Assert.AreEqual('BuildNodes a.wad|a.gwa|7|300000', FLog[0]);
end;

procedure TTestGlbspClient.TestNoOptionsPassNoFlags;
begin
  // Same as the command line of ND_NodesCheck: no -q, no -xp
  FClient.BuildNodes('a.wad', 'a.gwa', []);

  Assert.AreEqual('BuildNodes a.wad|a.gwa|0|300000', FLog[0]);
end;

procedure TTestGlbspClient.TestTimeoutIsForwarded;
begin
  FClient.BuildNodes('a.wad', 'a.gwa', [goHexen], 4500);

  Assert.AreEqual('BuildNodes a.wad|a.gwa|4|4500', FLog[0]);
end;

procedure TTestGlbspClient.TestDefaultTimeoutIsFiveMinutes;
begin
  Assert.AreEqual(300000, GLBSP_DEFAULT_TIMEOUT_MS);
end;

procedure TTestGlbspClient.TestPathsAreForwardedAsAnsi;
begin
  FClient.BuildNodes('C:\Mappe di prova\e1m1.wad', 'C:\Mappe di prova\e1m1.gwa');

  Assert.AreEqual('BuildNodes C:\Mappe di prova\e1m1.wad|C:\Mappe di prova\e1m1.gwa|3|300000',
    FLog[0]);
end;

procedure TTestGlbspClient.TestSuccessKeepsOutputAndExitCode;
begin
  FFake.Output := 'Built 3 nodes'#13#10;
  FFake.ExitCode := 0;

  FClient.BuildNodes('a.wad', 'a.gwa');

  Assert.AreEqual('Built 3 nodes'#13#10, FClient.Output);
  Assert.AreEqual(0, Integer(FClient.ExitCode));
end;

procedure TTestGlbspClient.TestFailureRaisesWithCodeAndDetail;
begin
  FFake.ReturnCode := GLBSP_ERR_PROCESS_FAILED;
  FFake.ErrorText := 'glbsp exited with code 5';

  try
    FClient.BuildNodes('a.wad', 'a.gwa');
    Assert.Fail('EGlbspException expected');
  except
    on E: EGlbspException do
    begin
      Assert.AreEqual(GLBSP_ERR_PROCESS_FAILED, E.Code);
      Assert.IsTrue(Pos('glbsp exited with code 5', E.Message) > 0);
    end;
  end;
end;

procedure TTestGlbspClient.TestFailureKeepsOutputAndExitCode;
begin
  FFake.ReturnCode := GLBSP_ERR_PROCESS_FAILED;
  FFake.ExitCode := 5;
  FFake.Output := 'Error: bad wad';

  try
    FClient.BuildNodes('a.wad', 'a.gwa');
  except
    on EGlbspException do
      ; // expected: what matters is what the client kept
  end;

  Assert.AreEqual('Error: bad wad', FClient.Output);
  Assert.AreEqual(5, Integer(FClient.ExitCode));
end;

procedure TTestGlbspClient.TestPathNotInAnsiCodePageRaisesWithoutCalling;
var
  LNotAnsi: string;
begin
  // U+1F600 (a surrogate pair) is in no ANSI code page
  LNotAnsi := 'a' + #$D83D#$DE00 + '.wad';

  try
    FClient.BuildNodes(LNotAnsi, 'a.gwa');
    Assert.Fail('EGlbspException expected');
  except
    on E: EGlbspException do
      Assert.AreEqual(GLBSP_ERR_INVALID_ARGUMENT, E.Code);
  end;
  Assert.AreEqual(0, FLog.Count);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGlbspClient);

end.
