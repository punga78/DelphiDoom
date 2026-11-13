{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the utility commands (dir, cd, cat, web pages)         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Console.UtilityCommands;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Console.Intf,
  DelphiDoom.Console.UtilityCommands, DelphiDoom.Tests.Console.Fakes;

type
  /// <summary>Files that exist only in the test: a mask gives two names, "nomatch" none</summary>
  TFakeFileLister = class(TInterfacedObject, IConsoleFileLister)
  public
    function FindFiles(const AMask: string): TArray<string>;
    function ReadTextLines(const AFileName: string): TArray<string>;
    function CurrentDirectory: string;
  end;

  /// <summary>Writes the addresses it is asked to open</summary>
  TFakeBrowser = class(TInterfacedObject, IConsoleBrowser)
  private
    FAddresses: TStringList;
  public
    constructor Create(AAddresses: TStringList);
    procedure OpenWebPage(const AAddress: string);
  end;

  [TestFixture]
  [Category('console')]
  TTestConsoleUtilityCommands = class(TObject)
  private
    FOutput: TFakeOutput;
    FOutputIntf: IConsoleOutput;
    FRegistry: ICommandRegistry;
    FInterpreter: IConsoleInterpreter;
    FAddresses: TStringList;
    FGroup: IConsoleCommandGroup;
    FFiles: IConsoleFileLister;
    function LegacyDirectory(const AParam1, AParam2: string): string;
    function LegacyConcatenate(const AParam1, AParam2: string): string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeRifiutareUnaDipendenzaNil;
    [Test]
    procedure DovrebbeRegistrareTuttiINomiCompresiGliAlias;
    [Test]
    procedure DovrebbeElencareITuttiIFileSenzaMaschera;
    [Test]
    procedure DovrebbeElencareLeMaschereDelSecondoParametro;
    [Test]
    procedure DovrebbeScrivereLaCartellaCorrente;
    [Test]
    procedure DovrebbeMostrareLeRigheDeiFile;
    [Test]
    procedure DovrebbeChiedereIFileSeNonCeLaMaschera;
    [Test]
    procedure DovrebbeAprireLaPaginaDataESuoiAlias;
    [Test]
    procedure DovrebbeEseguireVerEApriteLaPaginaDeiDownload;
    [Test]
    procedure DovrebbeDareLoStessoTestoDelVecchioCodiceSuScenariCasuali;
  end;

implementation

uses
  DelphiDoom.Console.Factory, DelphiDoom.Console.Text;

const
  EOL = #13#10;

{ TFakeFileLister }

function TFakeFileLister.FindFiles(const AMask: string): TArray<string>;
begin
  if AMask = 'nomatch' then
    Result := nil
  else
    Result := [AMask + '1', AMask + '2'];
end;

function TFakeFileLister.ReadTextLines(const AFileName: string): TArray<string>;
begin
  Result := ['first of ' + AFileName, '', 'last'];
end;

function TFakeFileLister.CurrentDirectory: string;
begin
  Result := 'C:\Games\Doom';
end;

{ TFakeBrowser }

constructor TFakeBrowser.Create(AAddresses: TStringList);
begin
  inherited Create;
  FAddresses := AAddresses;
end;

procedure TFakeBrowser.OpenWebPage(const AAddress: string);
begin
  FAddresses.Add(AAddress);
end;

{ TTestConsoleUtilityCommands }

procedure TTestConsoleUtilityCommands.Setup;
begin
  FOutput := TFakeOutput.Create;
  FOutputIntf := FOutput;
  FRegistry := TConsoleFactory.CreateRegistry;
  FInterpreter := TConsoleFactory.CreateInterpreter(FRegistry);
  FAddresses := TStringList.Create;
  FFiles := TFakeFileLister.Create;
  FGroup := TConsoleFactory.CreateUtilityCommands(FRegistry, FOutputIntf, FFiles,
    TFakeBrowser.Create(FAddresses), FInterpreter);
  FGroup.Register;
end;

procedure TTestConsoleUtilityCommands.TearDown;
begin
  FGroup := nil;
  FFiles := nil;
  FAddresses.Free;
  FInterpreter := nil;
  FRegistry := nil;
  FOutputIntf := nil;
end;

procedure TTestConsoleUtilityCommands.DovrebbeRifiutareUnaDipendenzaNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TConsoleUtilityCommands.Create(nil, FOutputIntf, FFiles, TFakeBrowser.Create(FAddresses), FInterpreter);
    end,
    EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TConsoleUtilityCommands.Create(FRegistry, nil, FFiles, TFakeBrowser.Create(FAddresses), FInterpreter);
    end,
    EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TConsoleUtilityCommands.Create(FRegistry, FOutputIntf, nil, TFakeBrowser.Create(FAddresses), FInterpreter);
    end,
    EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TConsoleUtilityCommands.Create(FRegistry, FOutputIntf, FFiles, nil, FInterpreter);
    end,
    EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TConsoleUtilityCommands.Create(FRegistry, FOutputIntf, FFiles, TFakeBrowser.Create(FAddresses), nil);
    end,
    EArgumentNilException);
end;

procedure TTestConsoleUtilityCommands.DovrebbeRegistrareTuttiINomiCompresiGliAlias;
var
  LName: string;
begin
  for LName in ['dir', 'ls', 'cd', 'pwd', 'type', 'cat', 'gotowebpage', 'homepage', 'help',
    'documentation', 'getlatestversion', 'downloadlatestversion', 'forum', 'forums'] do
    Assert.IsTrue(FRegistry.Contains(LName), LName);
end;

procedure TTestConsoleUtilityCommands.DovrebbeElencareITuttiIFileSenzaMaschera;
begin
  Assert.IsTrue(FInterpreter.Execute('dir'));
  Assert.AreEqual('*.*1' + EOL + '*.*2' + EOL, FOutput.Text);
end;

procedure TTestConsoleUtilityCommands.DovrebbeElencareLeMaschereDelSecondoParametro;
begin
  FInterpreter.Execute('ls', 'a', 'b nomatch  c');
  Assert.AreEqual('a1' + EOL + 'a2' + EOL + 'b1' + EOL + 'b2' + EOL + 'c1' + EOL + 'c2' + EOL, FOutput.Text);
end;

procedure TTestConsoleUtilityCommands.DovrebbeScrivereLaCartellaCorrente;
begin
  FInterpreter.Execute('pwd');
  Assert.AreEqual('C:\Games\Doom' + EOL, FOutput.Text);
end;

procedure TTestConsoleUtilityCommands.DovrebbeMostrareLeRigheDeiFile;
begin
  FInterpreter.Execute('cat', 'x', '');
  Assert.AreEqual('first of x1' + EOL + EOL + 'last' + EOL + 'first of x2' + EOL + EOL + 'last' + EOL,
    FOutput.Text);
end;

procedure TTestConsoleUtilityCommands.DovrebbeChiedereIFileSeNonCeLaMaschera;
begin
  FInterpreter.Execute('type');
  Assert.AreEqual('Please specify the files to display.' + EOL, FOutput.Text);
end;

procedure TTestConsoleUtilityCommands.DovrebbeAprireLaPaginaDataESuoiAlias;
begin
  FInterpreter.Execute('gotowebpage', 'http://example.org/');
  FInterpreter.Execute('homepage');
  FInterpreter.Execute('documentation');
  FInterpreter.Execute('help');
  FInterpreter.Execute('forums');
  Assert.AreEqual(
    'http://example.org/|http://sourceforge.net/projects/delphidoom/|' +
    'http://sourceforge.net/projects/delphidoom/|http://sourceforge.net/projects/delphidoom/|' +
    'http://delphidoom.forumotion.com/index.htm', StringReplace(Trim(FAddresses.Text), sLineBreak, '|', [rfReplaceAll]));
end;

procedure TTestConsoleUtilityCommands.DovrebbeEseguireVerEApriteLaPaginaDeiDownload;
var
  LVersion: string;
begin
  FRegistry.Add('ver',
    procedure(const AParam1, AParam2: string)
    begin
      LVersion := 'ver ran';
    end);
  FInterpreter.Execute('getlatestversion');
  Assert.AreEqual('ver ran', LVersion);
  Assert.AreEqual('http://sourceforge.net/projects/delphidoom/files/', Trim(FAddresses.Text));
end;

// The old C_CmdDir and C_CmdCat (c_utils.pas of master cb5a45e3), with the files and printf given
function TTestConsoleUtilityCommands.LegacyDirectory(const AParam1, AParam2: string): string;
var
  LMask: string;
  LMask1: string;
  LMask2: string;
  LFile: string;
begin
  Result := '';
  LMask := AParam1;
  if LMask = '' then
    LMask := '*.*';
  for LFile in FFiles.FindFiles(LMask) do
    Result := Result + LFile + EOL;
  LMask := AParam2;
  if LMask = '' then
    Exit;
  TConsoleText.Split(LMask, ' ', LMask1, LMask2);
  Result := Result + LegacyDirectory(LMask1, LMask2);
end;

function TTestConsoleUtilityCommands.LegacyConcatenate(const AParam1, AParam2: string): string;
var
  LMask: string;
  LMask1: string;
  LMask2: string;
  LFile: string;
  LLine: string;
begin
  Result := '';
  LMask := AParam1;
  if LMask = '' then
  begin
    Result := 'Please specify the files to display.' + EOL;
    Exit;
  end;
  for LFile in FFiles.FindFiles(LMask) do
    for LLine in FFiles.ReadTextLines(LFile) do
      Result := Result + LLine + EOL;
  LMask := AParam2;
  if LMask = '' then
    Exit;
  TConsoleText.Split(LMask, ' ', LMask1, LMask2);
  Result := Result + LegacyConcatenate(LMask1, LMask2);
end;

procedure TTestConsoleUtilityCommands.DovrebbeDareLoStessoTestoDelVecchioCodiceSuScenariCasuali;
const
  WORDS: array[0..5] of string = ('a', 'b*', 'nomatch', '*.txt', '', 'wad');
var
  LScenario: Integer;
  LParam1: string;
  LParam2: string;
  LCount: Integer;
  LIndex: Integer;
  LKind: Integer;
  LExpected: string;
begin
  RandSeed := 185;
  for LScenario := 1 to 300 do
  begin
    LParam1 := WORDS[Random(6)];
    LParam2 := '';
    LCount := Random(4);
    for LIndex := 1 to LCount do
      LParam2 := LParam2 + WORDS[Random(6)] + StringOfChar(' ', 1 + Random(2));
    LParam2 := Trim(LParam2);
    LKind := Random(2);
    FOutput.Clear;
    if LKind = 0 then
    begin
      LExpected := LegacyDirectory(LParam1, LParam2);
      FInterpreter.Execute('dir', LParam1, LParam2);
    end
    else
    begin
      LExpected := LegacyConcatenate(LParam1, LParam2);
      FInterpreter.Execute('cat', LParam1, LParam2);
    end;
    Assert.AreEqual(LExpected, FOutput.Text,
      Format('scenario %d (%d): "%s" "%s"', [LScenario, LKind, LParam1, LParam2]));
  end;
end;

end.
