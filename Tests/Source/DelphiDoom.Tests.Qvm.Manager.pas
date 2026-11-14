{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the QVM library - the table of the machines            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Qvm.Manager;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Logging.Intf, DelphiDoom.BotAi.Import.Intf,
  DelphiDoom.Qvm.Types, DelphiDoom.Qvm.Intf, DelphiDoom.Tests.Qvm.Support;

type
  /// <summary>A log that keeps what it is told</summary>
  TQvmFakeLog = class(TInterfacedObject, ILog)
  strict private
    FText: string;
  public
    procedure Info(const AText: string);
    procedure Warning(const AText: string);
    procedure DevWarning(const AText: string);
    procedure Error(const AText: string);
    property Text: string read FText;
  end;

  [TestFixture]
  [Category('Qvm')]
  TTestQvmManager = class
  strict private
    FFiles: TQvmMemoryFiles;
    FFilesKeeper: IBotFileSource;
    FLog: TQvmFakeLog;
    FLogKeeper: ILog;
    FHost: IQvmHost;
    FManager: IQvmManager;
    procedure PutModule(const AName: AnsiString; AOpcode: Integer);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeCaricareUnModuloDalSuoFile;
    [Test]
    procedure LoStessoNomeDovrebbeDareLaStessaMacchinaSenzaMaiuscole;
    [Test]
    procedure UnFileCheNonCEDovrebbeDareNilComeLOriginale;
    [Test]
    procedure UnFileSbagliatoNonDovrebbeEntrareNellaTabella;
    [Test]
    procedure SenzaNomeOSenzaHostDovrebbeRifiutare;
    [Test]
    procedure LaTabellaDovrebbeTenereTreMacchine;
    [Test]
    procedure ScaricareUnaMacchinaDovrebbeLiberareIlPosto;
    [Test]
    procedure SvuotareDovrebbeToglierleTutte;
    [Test]
    procedure IlRiavvioDovrebbeRileggereIlFile;
    [Test]
    procedure IlRiavvioSenzaFileOdiUnaMacchinaEstraneaDovrebbeFallire;
    [Test]
    procedure DovrebbeElencareLeMacchineNellOrdineInCuiSonoNate;
    [Test]
    procedure DovrebbeCaricareISimboliSoloSeRichiesto;
    [Test]
    procedure SenzaIlFileDeiSimboliDovrebbeDirloENonFallire;
    [Test]
    procedure SenzaLogDovrebbeFunzionareLoStesso;
    [Test]
    procedure IlNomeDovrebbeEssereTagliatoComeNellOriginale;
  end;

implementation

uses
  DelphiDoom.Qvm.Opcodes, DelphiDoom.Qvm.Factory, DelphiDoom.Tests.Qvm.Programs;

{ TQvmFakeLog }

procedure TQvmFakeLog.Info(const AText: string);
begin
  FText := FText + AText;
end;

procedure TQvmFakeLog.Warning(const AText: string);
begin
  FText := FText + 'W:' + AText;
end;

procedure TQvmFakeLog.DevWarning(const AText: string);
begin
  FText := FText + 'D:' + AText;
end;

procedure TQvmFakeLog.Error(const AText: string);
begin
  FText := FText + 'E:' + AText;
end;

{ TTestQvmManager }

procedure TTestQvmManager.Setup;
begin
  FFiles := TQvmMemoryFiles.Create;
  FFilesKeeper := FFiles;
  FLog := TQvmFakeLog.Create;
  FLogKeeper := FLog;
  FHost := TQvmNullHost.Create;
  FManager := TQvmFactory.CreateManager(FFilesKeeper, FLogKeeper, TQvmLimits.Default, False);
end;

procedure TTestQvmManager.TearDown;
begin
  FManager := nil;
  FHost := nil;
  FLogKeeper := nil;
  FFilesKeeper := nil;
end;

procedure TTestQvmManager.PutModule(const AName: AnsiString; AOpcode: Integer);
begin
  FFiles.Put('vm/' + AName + '.qvm', TQvmPrograms.Binary(AOpcode));
end;

procedure TTestQvmManager.DovrebbeCaricareUnModuloDalSuoFile;
var
  LMachine: IQvmMachine;
begin
  PutModule('qagame', OP_ADD);
  LMachine := FManager.Load('qagame', FHost);
  Assert.IsNotNull(LMachine);
  Assert.AreEqual<AnsiString>('qagame', LMachine.Name);
  Assert.AreEqual(7, LMachine.Call(0, [3, 4]));
  Assert.AreEqual(1, FManager.Count);
  Assert.Contains(FLog.Text, 'Loading vm file vm/qagame.qvm.');
end;

procedure TTestQvmManager.LoStessoNomeDovrebbeDareLaStessaMacchinaSenzaMaiuscole;
var
  LFirst, LSecond: IQvmMachine;
begin
  PutModule('ui', OP_ADD);
  LFirst := FManager.Load('ui', FHost);
  // the file is not read again
  FFiles.Remove('vm/ui.qvm');
  LSecond := FManager.Load('UI', FHost);
  Assert.IsTrue(LFirst = LSecond);
  Assert.IsTrue(FManager.Find('Ui') = LFirst);
  Assert.IsNull(FManager.Find('cgame'));
  Assert.AreEqual(1, FManager.Count);
end;

procedure TTestQvmManager.UnFileCheNonCEDovrebbeDareNilComeLOriginale;
begin
  Assert.IsNull(FManager.Load('nothing', FHost));
  Assert.AreEqual(0, FManager.Count);
  Assert.Contains(FLog.Text, 'Failed.');
end;

procedure TTestQvmManager.UnFileSbagliatoNonDovrebbeEntrareNellaTabella;
begin
  FFiles.Put('vm/bad.qvm', [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24,
    25, 26, 27, 28, 29, 30, 31, 32]);
  try
    FManager.Load('bad', FHost);
    Assert.Fail('nessun errore');
  except
    on E: EQvmFormatException do
      Assert.AreEqual('bad has bad header', E.Message);
  end;
  Assert.AreEqual(0, FManager.Count);
  Assert.IsNull(FManager.Find('bad'));
end;

procedure TTestQvmManager.SenzaNomeOSenzaHostDovrebbeRifiutare;
begin
  PutModule('ui', OP_ADD);
  Assert.WillRaise(
    procedure
    begin
      FManager.Load('', FHost);
    end, EQvmException);
  Assert.WillRaise(
    procedure
    begin
      FManager.Load('ui', nil);
    end, EQvmException);
end;

procedure TTestQvmManager.LaTabellaDovrebbeTenereTreMacchine;
begin
  PutModule('qagame', OP_ADD);
  PutModule('cgame', OP_SUB);
  PutModule('ui', OP_MULI);
  PutModule('fourth', OP_BXOR);
  FManager.Load('qagame', FHost);
  FManager.Load('cgame', FHost);
  FManager.Load('ui', FHost);
  Assert.AreEqual(QVM_MAX_MACHINES, FManager.Count);
  try
    FManager.Load('fourth', FHost);
    Assert.Fail('nessun errore');
  except
    on E: EQvmException do
      Assert.AreEqual('VM_Create: no free vm_t', E.Message);
  end;
  // one that is there is still given
  Assert.AreEqual(12, FManager.Load('ui', FHost).Call(0, [3, 4]));
  Assert.AreEqual(-1, FManager.Load('cgame', FHost).Call(0, [3, 4]));
end;

procedure TTestQvmManager.ScaricareUnaMacchinaDovrebbeLiberareIlPosto;
var
  LMachine: IQvmMachine;
begin
  PutModule('qagame', OP_ADD);
  PutModule('cgame', OP_SUB);
  PutModule('ui', OP_MULI);
  PutModule('fourth', OP_BXOR);
  FManager.Load('qagame', FHost);
  LMachine := FManager.Load('cgame', FHost);
  FManager.Load('ui', FHost);
  FManager.Unload(LMachine);
  Assert.AreEqual(2, FManager.Count);
  Assert.IsNull(FManager.Find('cgame'));
  // who still holds it can use it; unloading it twice does nothing
  Assert.AreEqual(-1, LMachine.Call(0, [3, 4]));
  FManager.Unload(LMachine);
  Assert.AreEqual(2, FManager.Count);
  Assert.AreEqual(7, FManager.Load('fourth', FHost).Call(0, [3, 4]));
  Assert.AreEqual(3, FManager.Count);
end;

procedure TTestQvmManager.SvuotareDovrebbeToglierleTutte;
begin
  PutModule('qagame', OP_ADD);
  PutModule('ui', OP_MULI);
  FManager.Load('qagame', FHost);
  FManager.Load('ui', FHost);
  FManager.Clear;
  Assert.AreEqual(0, FManager.Count);
  Assert.AreEqual<Integer>(0, Length(FManager.Info));
  Assert.IsNull(FManager.Find('ui'));
end;

procedure TTestQvmManager.IlRiavvioDovrebbeRileggereIlFile;
var
  LMachine: IQvmMachine;
begin
  PutModule('qagame', OP_ADD);
  LMachine := FManager.Load('qagame', FHost);
  LMachine.Memory.WriteInt32(1000, 99);
  FManager.Restart(LMachine);
  Assert.AreEqual(0, LMachine.Memory.ReadInt32(1000));
  // only the data come from the file: the code stays the one that was loaded
  PutModule('qagame', OP_SUB);
  FManager.Restart(LMachine);
  Assert.AreEqual(7, LMachine.Call(0, [3, 4]));
end;

procedure TTestQvmManager.IlRiavvioSenzaFileOdiUnaMacchinaEstraneaDovrebbeFallire;
var
  LMachine, LForeign: IQvmMachine;
begin
  PutModule('qagame', OP_ADD);
  LMachine := FManager.Load('qagame', FHost);
  FFiles.Remove('vm/qagame.qvm');
  try
    FManager.Restart(LMachine);
    Assert.Fail('nessun errore');
  except
    on E: EQvmException do
      Assert.AreEqual('VM_Restart failed.', E.Message);
  end;
  LForeign := TQvmFactory.CreateMachine('other', TQvmPrograms.Binary(OP_ADD), FHost);
  Assert.WillRaise(
    procedure
    begin
      FManager.Restart(LForeign);
    end, EQvmException);
end;

procedure TTestQvmManager.DovrebbeElencareLeMacchineNellOrdineInCuiSonoNate;
var
  LInfo: TArray<TQvmInfo>;
begin
  PutModule('qagame', OP_ADD);
  FFiles.Put('vm/cgame.qvm', TQvmPrograms.Sieve(1 shl 16));
  FManager.Load('qagame', FHost);
  FManager.Load('cgame', FHost);
  LInfo := FManager.Info;
  Assert.AreEqual<Integer>(2, Length(LInfo));
  Assert.AreEqual<AnsiString>('qagame', LInfo[0].Name);
  Assert.AreEqual(24, LInfo[0].CodeLength);
  Assert.AreEqual(28, LInfo[0].TableLength);
  Assert.AreEqual(8192, LInfo[0].DataLength);
  Assert.AreEqual<AnsiString>('cgame', LInfo[1].Name);
  Assert.AreEqual(1 shl 16, LInfo[1].DataLength);
end;

procedure TTestQvmManager.DovrebbeCaricareISimboliSoloSeRichiesto;
var
  LMachine: IQvmMachine;
begin
  PutModule('qagame', OP_ADD);
  FFiles.Put('vm/qagame.map', BytesOf('0 0 vmMain' + #10 + '0 5 tail' + #10 + '1 0 data'));
  // com_developer off: the .map is not read
  LMachine := FManager.Load('qagame', FHost);
  Assert.AreEqual(0, LMachine.Symbols.Count);
  FManager := TQvmFactory.CreateManager(FFilesKeeper, FLogKeeper, TQvmLimits.Default, True);
  LMachine := FManager.Load('qagame', FHost);
  Assert.AreEqual(2, LMachine.Symbols.Count);
  Assert.AreEqual<AnsiString>('tail+1', LMachine.Symbols.ValueToSymbol(18));
  Assert.Contains(FLog.Text, '2 symbols parsed from vm/qagame.map');
end;

procedure TTestQvmManager.SenzaIlFileDeiSimboliDovrebbeDirloENonFallire;
var
  LMachine: IQvmMachine;
begin
  PutModule('ui', OP_ADD);
  FManager := TQvmFactory.CreateManager(FFilesKeeper, FLogKeeper, TQvmLimits.Default, True);
  LMachine := FManager.Load('ui', FHost);
  Assert.IsNotNull(LMachine);
  Assert.AreEqual(0, LMachine.Symbols.Count);
  Assert.Contains(FLog.Text, 'Couldn''t load symbol file: vm/ui.map');
end;

procedure TTestQvmManager.SenzaLogDovrebbeFunzionareLoStesso;
begin
  PutModule('ui', OP_ADD);
  FManager := TQvmFactory.CreateManager(FFilesKeeper, nil, TQvmLimits.Default, True);
  Assert.AreEqual(7, FManager.Load('ui', FHost).Call(0, [3, 4]));
  Assert.IsNull(FManager.Load('nothing', FHost));
end;

procedure TTestQvmManager.IlNomeDovrebbeEssereTagliatoComeNellOriginale;
var
  LLong: AnsiString;
  LMachine: IQvmMachine;
begin
  LLong := AnsiString(StringOfChar('m', 80));
  FFiles.Put('vm/' + Copy(LLong, 1, 63) + '.qvm', TQvmPrograms.Binary(OP_ADD));
  LMachine := FManager.Load(LLong, FHost);
  Assert.IsNotNull(LMachine);
  Assert.AreEqual<Integer>(63, Length(LMachine.Name));
  Assert.IsTrue(FManager.Load(LLong, FHost) = LMachine);
end;

end.
