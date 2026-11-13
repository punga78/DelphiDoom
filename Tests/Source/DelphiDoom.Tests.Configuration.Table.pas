{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the configuration library - rows, table and store      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Configuration.Table;

interface

uses
  System.SysUtils,
  System.Classes,
  DUnitX.TestFramework,
  DelphiDoom.Configuration.Types,
  DelphiDoom.Configuration.Intf;

type
  [TestFixture]
  [Category('configuration')]
  TTestConfigurationTable = class(TObject)
  strict private
    FInteger: Integer;
    FBoolean: Boolean;
    FString: string;
    FFormat: IConfigurationFormat;
    FCommands: TStringList;
    FLog: TStringList;
    function Defaults(const AText: string; AInteger: Integer; ABoolean: Boolean): TConfigurationDefaults;
    function NewItem(const AName: string; AKind: TConfigurationItemKind;
      ASetable: Byte = CONFIGURATION_SET_ALWAYS): IConfigurationItem;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeLeggereEScrivereLaVariabile;
    [Test]
    procedure DovrebbeTornareAlValoreDiPartenza;
    [Test]
    procedure DovrebbeChiudereLaRigaForzataETenereIlValoreDiPrima;
    [Test]
    procedure DovrebbeScrivereSoloLaVariabileDallaSecondaForzatura;
    [Test]
    procedure DovrebbeForzareTestiEBooleani;
    [Test]
    procedure DovrebbeRifiutareUnTipoDiverso;
    [Test]
    procedure DovrebbeRifiutareUnGruppoComeValore;
    [Test]
    procedure DovrebbeRifiutareUnaRigaSenzaVariabile;
    [Test]
    procedure DovrebbeAccettareUnGruppoSenzaVariabile;
    [Test]
    procedure DovrebbeTrovareLaPrimaRigaConIlNome;
    [Test]
    procedure DovrebbeSaltareIGruppiCercandoUnValore;
    [Test]
    procedure DovrebbeRifiutareUnaPosizioneSbagliata;
    [Test]
    procedure DovrebbeRifiutareUnaRigaNil;
    [Test]
    procedure DovrebbeRifiutareDipendenzeNil;
    [Test]
    procedure DovrebbeScrivereGruppiEValoriInOrdine;
    [Test]
    procedure DovrebbeIgnorareLeChiaviSconosciute;
    [Test]
    procedure DovrebbeRimettereIlValoreDiPartenzaSoloSeSiPuoCambiare;
    [Test]
    procedure DovrebbeChiamareIlComandoSeLaRigaNonSiPuoCambiare;
    [Test]
    procedure DovrebbeFermarsiSuUnGruppoConLoStessoNome;
    [Test]
    procedure DovrebbeRifiutareUnDestinatarioNil;
    [Test]
    procedure DovrebbeDareFalsoForzandoUnNomeSconosciuto;
  end;

implementation

uses
  DelphiDoom.Configuration.Factory,
  DelphiDoom.Tests.Configuration.Fakes;

{ TTestConfigurationTable }

procedure TTestConfigurationTable.Setup;
begin
  FInteger := 7;
  FBoolean := False;
  FString := 'start';
  FFormat := TConfigurationFactory.CreateFormat;
  FCommands := TStringList.Create;
  FLog := TStringList.Create;
end;

procedure TTestConfigurationTable.TearDown;
begin
  FCommands.Free;
  FLog.Free;
end;

function TTestConfigurationTable.Defaults(const AText: string; AInteger: Integer;
  ABoolean: Boolean): TConfigurationDefaults;
begin
  Result.StringValue := AText;
  Result.IntegerValue := AInteger;
  Result.BooleanValue := ABoolean;
end;

function TTestConfigurationTable.NewItem(const AName: string; AKind: TConfigurationItemKind;
  ASetable: Byte): IConfigurationItem;
begin
  Result := TConfigurationFactory.CreateItem(AName, AKind, ASetable, Defaults('def', 42, True),
    TFakeConfigurationValue.Create(@FInteger, @FBoolean, @FString));
end;

procedure TTestConfigurationTable.DovrebbeLeggereEScrivereLaVariabile;
var
  LItem: IConfigurationItem;
begin
  LItem := NewItem('screenblocks', cikInteger);
  Assert.AreEqual('screenblocks', LItem.Name);
  Assert.AreEqual(7, LItem.GetInteger);
  LItem.SetInteger(11);
  Assert.AreEqual(11, FInteger);
  Assert.AreEqual(11, LItem.ActualInteger);
  Assert.IsFalse(LItem.IsForced);
end;

procedure TTestConfigurationTable.DovrebbeTornareAlValoreDiPartenza;
var
  LItem: IConfigurationItem;
begin
  LItem := NewItem('a', cikString);
  LItem.ResetToDefault;
  Assert.AreEqual('def', FString);
  LItem := NewItem('b', cikBoolean);
  LItem.ResetToDefault;
  Assert.IsTrue(FBoolean);
  LItem := TConfigurationFactory.CreateGroup('Display');
  LItem.ResetToDefault;
  Assert.AreEqual(cikGroup, LItem.Kind);
end;

procedure TTestConfigurationTable.DovrebbeChiudereLaRigaForzataETenereIlValoreDiPrima;
var
  LItem: IConfigurationItem;
begin
  LItem := NewItem('a', cikInteger);
  LItem.ForceInteger(99);
  Assert.IsTrue(LItem.IsForced);
  Assert.AreEqual(99, FInteger);
  Assert.AreEqual(99, LItem.ActualInteger);
  // the file and the console see the value of before, and change only it
  Assert.AreEqual(7, LItem.GetInteger);
  Assert.AreEqual(7, LItem.Defaults.IntegerValue);
  Assert.AreEqual(Integer(CONFIGURATION_SET_NEVER), Integer(LItem.Setable));
  LItem.SetInteger(5);
  Assert.AreEqual(99, FInteger);
  Assert.AreEqual(5, LItem.GetInteger);
  LItem.ResetToDefault;
  Assert.AreEqual(99, FInteger);
end;

procedure TTestConfigurationTable.DovrebbeScrivereSoloLaVariabileDallaSecondaForzatura;
var
  LItem: IConfigurationItem;
begin
  LItem := NewItem('a', cikInteger);
  LItem.ForceInteger(99);
  LItem.ForceInteger(100);
  Assert.AreEqual(100, FInteger);
  Assert.AreEqual(7, LItem.GetInteger);
end;

procedure TTestConfigurationTable.DovrebbeForzareTestiEBooleani;
var
  LText, LBool: IConfigurationItem;
begin
  LText := NewItem('t', cikString);
  LBool := NewItem('b', cikBoolean);
  LText.ForceString('forced');
  LBool.ForceBoolean(True);
  Assert.AreEqual('forced', FString);
  Assert.AreEqual('forced', LText.ActualString);
  Assert.AreEqual('start', LText.GetString);
  Assert.IsTrue(FBoolean);
  Assert.IsTrue(LBool.ActualBoolean);
  Assert.IsFalse(LBool.GetBoolean);
  LText.SetString('x');
  LBool.SetBoolean(True);
  Assert.AreEqual('x', LText.GetString);
  Assert.IsTrue(LBool.GetBoolean);
  LText.ForceString('again');
  LBool.ForceBoolean(False);
  Assert.AreEqual('again', FString);
  Assert.IsFalse(FBoolean);
end;

procedure TTestConfigurationTable.DovrebbeRifiutareUnTipoDiverso;
var
  LItem: IConfigurationItem;
begin
  LItem := NewItem('a', cikInteger);
  Assert.WillRaise(procedure begin LItem.GetString; end, EConfigurationException);
  Assert.WillRaise(procedure begin LItem.SetBoolean(True); end, EConfigurationException);
  Assert.WillRaise(procedure begin LItem.ForceString('x'); end, EConfigurationException);
  Assert.WillRaise(procedure begin LItem.ActualBoolean; end, EConfigurationException);
  Assert.WillRaise(procedure begin LItem.ForceBoolean(True); end, EConfigurationException);
  LItem := NewItem('b', cikBoolean);
  Assert.WillRaise(procedure begin LItem.GetInteger; end, EConfigurationException);
  Assert.WillRaise(procedure begin LItem.SetString('x'); end, EConfigurationException);
  Assert.WillRaise(procedure begin LItem.ForceInteger(1); end, EConfigurationException);
  Assert.WillRaise(procedure begin LItem.ActualString; end, EConfigurationException);
  Assert.WillRaise(procedure begin LItem.ActualInteger; end, EConfigurationException);
  Assert.WillRaise(procedure begin LItem.SetInteger(1); end, EConfigurationException);
end;

procedure TTestConfigurationTable.DovrebbeRifiutareUnGruppoComeValore;
var
  LItem: IConfigurationItem;
begin
  LItem := TConfigurationFactory.CreateGroup('Display');
  Assert.WillRaise(procedure begin LItem.GetInteger; end, EConfigurationException);
  Assert.WillRaise(procedure begin LItem.GetBoolean; end, EConfigurationException);
end;

procedure TTestConfigurationTable.DovrebbeRifiutareUnaRigaSenzaVariabile;
begin
  Assert.WillRaise(
    procedure
    begin
      TConfigurationFactory.CreateItem('a', cikInteger, 0, Defaults('', 0, False), nil);
    end, EArgumentNilException);
end;

procedure TTestConfigurationTable.DovrebbeAccettareUnGruppoSenzaVariabile;
var
  LItem: IConfigurationItem;
begin
  LItem := TConfigurationFactory.CreateItem('Sound', cikGroup, 0, Defaults('', 0, False), nil);
  Assert.AreEqual('Sound', LItem.Name);
  Assert.IsFalse(LItem.IsForced);
end;

procedure TTestConfigurationTable.DovrebbeTrovareLaPrimaRigaConIlNome;
var
  LTable: IConfigurationTable;
begin
  LTable := TConfigurationFactory.CreateTable(TArray<IConfigurationItem>.Create(
    TConfigurationFactory.CreateGroup('Display'), NewItem('a', cikInteger), NewItem('a', cikString)));
  Assert.AreEqual(3, LTable.Count);
  Assert.AreEqual(1, LTable.IndexOf('a'));
  Assert.AreEqual(0, LTable.IndexOf('Display'));
  Assert.AreEqual(-1, LTable.IndexOf('display'));
  Assert.AreEqual(-1, LTable.IndexOf('b'));
end;

procedure TTestConfigurationTable.DovrebbeSaltareIGruppiCercandoUnValore;
var
  LTable: IConfigurationTable;
begin
  LTable := TConfigurationFactory.CreateTable(TArray<IConfigurationItem>.Create(
    TConfigurationFactory.CreateGroup('a'), NewItem('a', cikBoolean)));
  Assert.AreEqual(cikBoolean, LTable.FindValue('a').Kind);
  Assert.IsNull(LTable.FindValue('b'));
end;

procedure TTestConfigurationTable.DovrebbeRifiutareUnaPosizioneSbagliata;
var
  LTable: IConfigurationTable;
begin
  LTable := TConfigurationFactory.CreateTable(TArray<IConfigurationItem>.Create(NewItem('a', cikInteger)));
  Assert.WillRaise(procedure begin LTable.Item(1); end, EConfigurationException);
  Assert.WillRaise(procedure begin LTable.Item(-1); end, EConfigurationException);
end;

procedure TTestConfigurationTable.DovrebbeRifiutareUnaRigaNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TConfigurationFactory.CreateTable(TArray<IConfigurationItem>.Create(nil));
    end, EArgumentNilException);
end;

procedure TTestConfigurationTable.DovrebbeRifiutareDipendenzeNil;
var
  LTable: IConfigurationTable;
begin
  LTable := TConfigurationFactory.CreateTable(nil);
  Assert.WillRaise(procedure begin TConfigurationFactory.CreateTableStore(nil, FFormat); end,
    EArgumentNilException);
  Assert.WillRaise(procedure begin TConfigurationFactory.CreateTableStore(LTable, nil); end,
    EArgumentNilException);
end;

procedure TTestConfigurationTable.DovrebbeScrivereGruppiEValoriInOrdine;
var
  LTable: IConfigurationTable;
  LWriter: IConfigurationWriter;
  LLines: TArray<string>;
begin
  LTable := TConfigurationFactory.CreateTable(TArray<IConfigurationItem>.Create(
    TConfigurationFactory.CreateGroup('Display'), NewItem('n', cikInteger), NewItem('b', cikBoolean),
    NewItem('s', cikString)));
  LWriter := FFormat.CreateWriter('[x]');
  TConfigurationFactory.CreateTableStore(LTable, FFormat).Write(LWriter);
  LLines := LWriter.Lines;
  Assert.AreEqual('[x]', LLines[0]);
  Assert.AreEqual('[Display]', LLines[2]);
  Assert.AreEqual('n=7', LLines[3]);
  Assert.AreEqual('b=' + FFormat.FormatBoolean(False), LLines[4]);
  Assert.AreEqual('s=start', LLines[5]);
end;

procedure TTestConfigurationTable.DovrebbeIgnorareLeChiaviSconosciute;
var
  LStore: IConfigurationTableStore;
begin
  LStore := TConfigurationFactory.CreateTableStore(TConfigurationFactory.CreateTable(
    TArray<IConfigurationItem>.Create(TConfigurationFactory.CreateGroup('g'), NewItem('n', cikInteger),
    NewItem('s', cikString), NewItem('b', cikBoolean))), FFormat);
  LStore.Apply(FFormat.Parse(TArray<string>.Create('[Delphi Doom ver 2.07]', 'nope=3', 'g=1',
    'N=0x10', 's=hello', 'b=' + FFormat.FormatBoolean(True))));
  Assert.AreEqual(16, FInteger);
  Assert.AreEqual('hello', FString);
  Assert.IsTrue(FBoolean);
  Assert.AreEqual(3, Length(LStore.Names));
end;

procedure TTestConfigurationTable.DovrebbeRimettereIlValoreDiPartenzaSoloSeSiPuoCambiare;
var
  LStore: IConfigurationTableStore;
begin
  LStore := TConfigurationFactory.CreateTableStore(TConfigurationFactory.CreateTable(
    TArray<IConfigurationItem>.Create(NewItem('n', cikInteger, CONFIGURATION_SET_NETWORK))), FFormat);
  LStore.Reset('N', CONFIGURATION_SET_SINGLEPLAYER, TFakeResetSink.Create(FCommands, FLog));
  Assert.AreEqual(7, FInteger);
  Assert.AreEqual(0, FLog.Count);
  LStore.Reset('N', CONFIGURATION_SET_NETWORK, TFakeResetSink.Create(FCommands, FLog));
  Assert.AreEqual(42, FInteger);
  Assert.AreEqual('Setting default value for N', FLog[0]);
  Assert.AreEqual('execute get n', FLog[1]);
end;

procedure TTestConfigurationTable.DovrebbeChiamareIlComandoSeLaRigaNonSiPuoCambiare;
var
  LStore: IConfigurationTableStore;
begin
  FCommands.Add('n');
  FCommands.Add('b');
  FCommands.Add('s');
  LStore := TConfigurationFactory.CreateTableStore(TConfigurationFactory.CreateTable(
    TArray<IConfigurationItem>.Create(NewItem('n', cikInteger, CONFIGURATION_SET_NEVER),
    NewItem('b', cikBoolean, CONFIGURATION_SET_NEVER), NewItem('s', cikString, CONFIGURATION_SET_NEVER))),
    FFormat);
  LStore.Reset('n', CONFIGURATION_SET_SINGLEPLAYER, TFakeResetSink.Create(FCommands, FLog));
  LStore.Reset('b', CONFIGURATION_SET_SINGLEPLAYER, TFakeResetSink.Create(FCommands, FLog));
  LStore.Reset('s', CONFIGURATION_SET_SINGLEPLAYER, TFakeResetSink.Create(FCommands, FLog));
  Assert.AreEqual(7, FInteger);
  Assert.AreEqual('execute n 42', FLog[1]);
  Assert.AreEqual('execute b YES', FLog[3]);
  Assert.AreEqual('execute s def', FLog[5]);
end;

procedure TTestConfigurationTable.DovrebbeFermarsiSuUnGruppoConLoStessoNome;
var
  LStore: IConfigurationTableStore;
begin
  FCommands.Add('g');
  LStore := TConfigurationFactory.CreateTableStore(TConfigurationFactory.CreateTable(
    TArray<IConfigurationItem>.Create(TConfigurationFactory.CreateItem('g', cikGroup,
    CONFIGURATION_SET_ALWAYS, Defaults('', 0, False), nil), NewItem('g', cikInteger))), FFormat);
  LStore.Reset('g', CONFIGURATION_SET_SINGLEPLAYER, TFakeResetSink.Create(FCommands, FLog));
  Assert.AreEqual(7, FInteger);
  LStore := TConfigurationFactory.CreateTableStore(TConfigurationFactory.CreateTable(
    TArray<IConfigurationItem>.Create(TConfigurationFactory.CreateGroup('g'), NewItem('g', cikInteger))),
    FFormat);
  LStore.Reset('g', CONFIGURATION_SET_SINGLEPLAYER, TFakeResetSink.Create(FCommands, FLog));
  Assert.AreEqual(7, FInteger);
  Assert.AreEqual(0, FLog.Count);
end;

procedure TTestConfigurationTable.DovrebbeRifiutareUnDestinatarioNil;
var
  LStore: IConfigurationTableStore;
begin
  LStore := TConfigurationFactory.CreateTableStore(TConfigurationFactory.CreateTable(nil), FFormat);
  Assert.WillRaise(procedure begin LStore.Reset('a', 1, nil); end, EArgumentNilException);
end;

procedure TTestConfigurationTable.DovrebbeDareFalsoForzandoUnNomeSconosciuto;
var
  LStore: IConfigurationTableStore;
begin
  LStore := TConfigurationFactory.CreateTableStore(TConfigurationFactory.CreateTable(
    TArray<IConfigurationItem>.Create(NewItem('n', cikInteger))), FFormat);
  Assert.IsFalse(LStore.ForceInteger('x', 1));
  Assert.IsFalse(LStore.ForceBoolean('n', True));
  Assert.IsFalse(LStore.ForceString('n', 'a'));
  Assert.IsTrue(LStore.ForceInteger('N', 3));
  Assert.AreEqual(3, FInteger);
end;

end.
