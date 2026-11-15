{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the lump commands (lumpsize, lumpnum, savelumptodisk)  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Console.LumpCommands;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Console.Intf,
  DelphiDoom.Console.LumpCommands, DelphiDoom.Tests.Console.Fakes;

type
  /// <summary>Three lumps: PLAYPAL (0, 3000 bytes), E1M1 (1, 0 bytes) and DEMO1 (2, 10 bytes)</summary>
  TFakeLumpSource = class(TInterfacedObject, IConsoleLumpSource)
  public
    function Count: Integer;
    function CheckNumForName(const AName: string): Integer;
    function LengthOf(ALump: Integer): Integer;
    function ReadBytes(ALump: Integer): TBytes;
  end;

  /// <summary>Writes nothing to the disk: it keeps the last file it was given</summary>
  TFakeLumpFiles = class(TInterfacedObject, IConsoleLumpFiles)
  public
    FileName: string;
    Data: TBytes;
    Succeeds: Boolean;
    constructor Create;
    function SaveFileName(const AFileName: string): string;
    function WriteFile(const AFileName: string; const AData: TBytes): Boolean;
  end;

  [TestFixture]
  [Category('console')]
  TTestConsoleLumpCommands = class(TObject)
  private
    FOutput: TFakeOutput;
    FOutputIntf: IConsoleOutput;
    FRegistry: ICommandRegistry;
    FInterpreter: IConsoleInterpreter;
    FFiles: TFakeLumpFiles;
    FFilesIntf: IConsoleLumpFiles;
    FGroup: IConsoleCommandGroup;
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
    procedure DovrebbeChiedereIlNomeSeLumpsizeNonLoHa;
    [Test]
    procedure DovrebbeDareLaDimensioneDiUnLumpPerNome;
    [Test]
    procedure DovrebbeDareLaDimensioneDiUnLumpPerNumero;
    [Test]
    procedure DovrebbeDireCheIlLumpNonEsisteConIlSuoNome;
    [Test]
    procedure DovrebbeDareIlNumeroDelLumpConIlSuoNome;
    [Test]
    procedure DovrebbeDireCheIlLumpDiLumpnumNonEsiste;
    [Test]
    procedure DovrebbeDareIlNumeroDeiLump;
    [Test]
    procedure DovrebbeMostrareLUsoSeMancaUnParametroDiSavelumptodisk;
    [Test]
    procedure DovrebbeAggiungereLEstensioneLmpSeIlNomeNonHaIlPunto;
    [Test]
    procedure DovrebbeConservareIlNomeSeHaIlPunto;
    [Test]
    procedure DovrebbeScrivereIByteDelLump;
    [Test]
    procedure DovrebbeDireCheIlLumpDaSalvareNonCe;
    [Test]
    procedure DovrebbeAvvisareSeLaScritturaFallisce;
  end;

implementation

uses
  DelphiDoom.Console.Factory;

const
  EOL = #13#10;

{ TFakeLumpSource }

function TFakeLumpSource.Count: Integer;
begin
  Result := 3;
end;

function TFakeLumpSource.CheckNumForName(const AName: string): Integer;
begin
  if SameText(AName, 'PLAYPAL') then
    Result := 0
  else if SameText(AName, 'E1M1') then
    Result := 1
  else if SameText(AName, 'DEMO1') then
    Result := 2
  else
    Result := -1;
end;

function TFakeLumpSource.LengthOf(ALump: Integer): Integer;
begin
  case ALump of
    0: Result := 3000;
    1: Result := 0;
    2: Result := 10;
  else
    Result := 0;
  end;
end;

function TFakeLumpSource.ReadBytes(ALump: Integer): TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, LengthOf(ALump));
  for LIndex := 0 to High(Result) do
    Result[LIndex] := Byte(LIndex + ALump);
end;

{ TFakeLumpFiles }

constructor TFakeLumpFiles.Create;
begin
  inherited Create;
  Succeeds := True;
end;

function TFakeLumpFiles.SaveFileName(const AFileName: string): string;
begin
  Result := 'saves\' + AFileName;
end;

function TFakeLumpFiles.WriteFile(const AFileName: string; const AData: TBytes): Boolean;
begin
  FileName := AFileName;
  Data := AData;
  Result := Succeeds;
end;

{ TTestConsoleLumpCommands }

procedure TTestConsoleLumpCommands.Setup;
begin
  FOutput := TFakeOutput.Create;
  FOutputIntf := FOutput;
  FRegistry := TConsoleFactory.CreateRegistry;
  FInterpreter := TConsoleFactory.CreateInterpreter(FRegistry);
  FFiles := TFakeLumpFiles.Create;
  FFilesIntf := FFiles;
  FGroup := TConsoleFactory.CreateLumpCommands(FRegistry, FOutputIntf, TFakeLumpSource.Create,
    FFilesIntf, TFakeLog.Create(FOutput));
  FGroup.Register;
end;

procedure TTestConsoleLumpCommands.TearDown;
begin
  FGroup := nil;
  FFilesIntf := nil;
  FFiles := nil;
  FInterpreter := nil;
  FRegistry := nil;
  FOutputIntf := nil;
end;

procedure TTestConsoleLumpCommands.DovrebbeRifiutareUnaDipendenzaNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TConsoleLumpCommands.Create(nil, FOutputIntf, TFakeLumpSource.Create, FFilesIntf,
        TFakeLog.Create(FOutput));
    end,
    EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TConsoleLumpCommands.Create(FRegistry, nil, TFakeLumpSource.Create, FFilesIntf,
        TFakeLog.Create(FOutput));
    end,
    EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TConsoleLumpCommands.Create(FRegistry, FOutputIntf, nil, FFilesIntf, TFakeLog.Create(FOutput));
    end,
    EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TConsoleLumpCommands.Create(FRegistry, FOutputIntf, TFakeLumpSource.Create, nil,
        TFakeLog.Create(FOutput));
    end,
    EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TConsoleLumpCommands.Create(FRegistry, FOutputIntf, TFakeLumpSource.Create, FFilesIntf, nil);
    end,
    EArgumentNilException);
end;

procedure TTestConsoleLumpCommands.DovrebbeRegistrareTuttiINomiCompresiGliAlias;
var
  LName: string;
begin
  for LName in ['lumpsize', 'lumplength', 'lumplen', 'lumpnum', 'checknumforname', 'numlumps',
    'savelumptodisk'] do
    Assert.IsTrue(FRegistry.Contains(LName), 'dovrebbe registrare ' + LName);
end;

procedure TTestConsoleLumpCommands.DovrebbeChiedereIlNomeSeLumpsizeNonLoHa;
begin
  Assert.IsTrue(FInterpreter.Execute('lumpsize'));
  Assert.AreEqual('Please specify the lump name' + EOL, FOutput.Text);
end;

procedure TTestConsoleLumpCommands.DovrebbeDareLaDimensioneDiUnLumpPerNome;
begin
  FInterpreter.Execute('lumplen PLAYPAL');
  Assert.AreEqual('Lump PLAYPAL size = 2KB (3000 bytes)' + EOL, FOutput.Text);
end;

procedure TTestConsoleLumpCommands.DovrebbeDareLaDimensioneDiUnLumpPerNumero;
begin
  FInterpreter.Execute('lumpsize #2');
  Assert.AreEqual('Lump #2 size = 0KB (10 bytes)' + EOL, FOutput.Text);
end;

// regressione: il vecchio codice scriveva "Lump %s does not exist" con il %s letterale
procedure TTestConsoleLumpCommands.DovrebbeDireCheIlLumpNonEsisteConIlSuoNome;
begin
  FInterpreter.Execute('lumpsize NOSUCH');
  Assert.AreEqual('Lump NOSUCH does not exist' + EOL, FOutput.Text);
end;

// regressione: il vecchio codice dava a "%s" il numero del lump (EConvertError)
procedure TTestConsoleLumpCommands.DovrebbeDareIlNumeroDelLumpConIlSuoNome;
begin
  FInterpreter.Execute('lumpnum DEMO1');
  Assert.AreEqual('Lump DEMO1 num = 2' + EOL, FOutput.Text);
end;

procedure TTestConsoleLumpCommands.DovrebbeDireCheIlLumpDiLumpnumNonEsiste;
begin
  FInterpreter.Execute('checknumforname NOSUCH');
  Assert.AreEqual('Lump NOSUCH does not exist' + EOL, FOutput.Text);
  FOutput.Clear;
  FInterpreter.Execute('lumpnum');
  Assert.AreEqual('Please specify the lump name' + EOL, FOutput.Text);
end;

procedure TTestConsoleLumpCommands.DovrebbeDareIlNumeroDeiLump;
begin
  FInterpreter.Execute('numlumps');
  Assert.AreEqual('3 total lumps' + EOL, FOutput.Text);
end;

procedure TTestConsoleLumpCommands.DovrebbeMostrareLUsoSeMancaUnParametroDiSavelumptodisk;
const
  USAGE = 'Usage is:' + EOL + '  savelumptodisk [lumpname] [filename]' + EOL;
begin
  FInterpreter.Execute('savelumptodisk');
  Assert.AreEqual(USAGE, FOutput.Text);
  FOutput.Clear;
  FInterpreter.Execute('savelumptodisk PLAYPAL');
  Assert.AreEqual(USAGE, FOutput.Text);
  Assert.AreEqual('', FFiles.FileName, 'non dovrebbe scrivere niente');
end;

procedure TTestConsoleLumpCommands.DovrebbeAggiungereLEstensioneLmpSeIlNomeNonHaIlPunto;
begin
  FInterpreter.Execute('savelumptodisk DEMO1 mydemo');
  Assert.AreEqual('saves\mydemo.lmp', FFiles.FileName);
end;

procedure TTestConsoleLumpCommands.DovrebbeConservareIlNomeSeHaIlPunto;
begin
  FInterpreter.Execute('savelumptodisk DEMO1 mydemo.bin');
  Assert.AreEqual('saves\mydemo.bin', FFiles.FileName);
end;

procedure TTestConsoleLumpCommands.DovrebbeScrivereIByteDelLump;
begin
  FInterpreter.Execute('savelumptodisk DEMO1 d.lmp');
  Assert.AreEqual<Integer>(10, Length(FFiles.Data));
  Assert.AreEqual<Integer>(2, FFiles.Data[0]);
  Assert.AreEqual<Integer>(11, FFiles.Data[9]);
  Assert.AreEqual('Lump DEMO1 saved to file saves\d.lmp (10 bytes).' + EOL, FOutput.Text);
end;

procedure TTestConsoleLumpCommands.DovrebbeDireCheIlLumpDaSalvareNonCe;
begin
  FInterpreter.Execute('savelumptodisk NOSUCH d.lmp');
  Assert.AreEqual('Lump NOSUCH not found.' + EOL, FOutput.Text);
  Assert.AreEqual('', FFiles.FileName);
end;

procedure TTestConsoleLumpCommands.DovrebbeAvvisareSeLaScritturaFallisce;
begin
  FFiles.Succeeds := False;
  FInterpreter.Execute('savelumptodisk DEMO1 d.lmp');
  Assert.AreEqual('[warn] Can not save lump DEMO1 to file saves\d.lmp.' + EOL, FOutput.Text);
end;

end.
