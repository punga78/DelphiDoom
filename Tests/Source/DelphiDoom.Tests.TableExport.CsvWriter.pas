{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the TableExport library - the CSV writer               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.TableExport.CsvWriter;

interface

uses
  DUnitX.TestFramework, DelphiDoom.TableExport.Intf, DelphiDoom.Tests.TableExport.Fakes;

type
  [TestFixture]
  [Category('tableexport')]
  TTestTableExportCsvWriter = class(TObject)
  private
    FStates: TFakeStates;
    FStatesIntf: IExportStateSource;
    FNames: IInterface;
    FWriter: IExportCsvWriter;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure TestDovrebbeScrivereLeColonneEUnaRigaPerCosa;
    [Test]
    procedure TestDovrebbeScrivereUnTrattinoPerUnValoreVuoto;
    [Test]
    procedure TestDovrebbeSaltareICommentiELeRigheVuote;
    [Test]
    procedure TestDovrebbeScrivereLeColonneEUnaRigaPerStato;
    [Test]
    procedure TestDovrebbeTogliereLeVirgoletteDaiValoriDegliStati;
    [Test]
    procedure TestDovrebbeDareINomiGenericiOltreLEnumerazione;
    [Test]
    procedure TestDovrebbeScrivereGliSprite;
    [Test]
    procedure TestDovrebbeRifiutareUnaSorgenteMancante;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.TableExport.Factory;

{ TTestTableExportCsvWriter }

procedure TTestTableExportCsvWriter.Setup;
begin
  FStates := TFakeStates.Create;
  FStatesIntf := FStates;
  FNames := TFakeNames.Create;
  FWriter := TTableExportFactory.CreateCsvWriter(FStatesIntf, FNames as IExportEnumNames);
end;

procedure TTestTableExportCsvWriter.TearDown;
begin
  FWriter := nil;
  FNames := nil;
  FStatesIntf := nil;
end;

procedure TTestTableExportCsvWriter.TestDovrebbeScrivereLeColonneEUnaRigaPerCosa;
var
  LRows: TArray<string>;
begin
  LRows := FWriter.MobjInfo(['# Things', '', 'Thing 1', 'Name = Player', 'Id # = 1', '', 'Thing 2', 'Name = Imp',
    'Id # = 3001', '# States']);
  Assert.AreEqual<Integer>(3, Length(LRows));
  Assert.AreEqual('"id";"Name";"Id #"', LRows[0]);
  Assert.AreEqual('"0";"Player";"1"', LRows[1]);
  Assert.AreEqual('"1";"Imp";"3001"', LRows[2]);
end;

procedure TTestTableExportCsvWriter.TestDovrebbeScrivereUnTrattinoPerUnValoreVuoto;
var
  LRows: TArray<string>;
begin
  LRows := FWriter.MobjInfo(['# Things', 'Thing 1', 'Name = Player', 'Obituary =', '# States']);
  Assert.AreEqual('"0";"Player";"-"', LRows[1]);
end;

procedure TTestTableExportCsvWriter.TestDovrebbeSaltareICommentiELeRigheVuote;
var
  LRows: TArray<string>;
begin
  LRows := FWriter.MobjInfo(['# Things', '# a comment', 'Thing 1', '// another', 'Name = Player', '   ',
    '# States']);
  Assert.AreEqual<Integer>(2, Length(LRows));
  Assert.AreEqual('"id";"Name"', LRows[0]);
end;

procedure TTestTableExportCsvWriter.TestDovrebbeScrivereLeColonneEUnaRigaPerStato;
var
  LRows: TArray<string>;
begin
  LRows := FWriter.States(['# States', '# S_FIRST', 'Frame 1', 'Sprite Number = 5', 'Duration = 4', '',
    'Frame 2', 'Sprite Number = 6', 'Duration = 8', '# Weapons']);
  Assert.AreEqual<Integer>(4, Length(LRows));
  Assert.AreEqual('"Name";"id";"Sprite Number";"Duration"', LRows[0]);
  Assert.AreEqual('"S_NULL";"0";"0";"0";"0";"-1";"0";"NULL";"0";"0";"0";"0"', LRows[1]);
  Assert.AreEqual('"S_FIRST";"1";"5";"4"', LRows[2]);
  Assert.AreEqual('"S_SECOND";"2";"6";"8"', LRows[3]);
end;

procedure TTestTableExportCsvWriter.TestDovrebbeTogliereLeVirgoletteDaiValoriDegliStati;
var
  LRows: TArray<string>;
begin
  LRows := FWriter.States(['# States', 'Frame 1', 'Action pointer = "CHASE"', '# Weapons']);
  Assert.AreEqual('"S_FIRST";"1";"CHASE"', LRows[2]);
end;

procedure TTestTableExportCsvWriter.TestDovrebbeDareINomiGenericiOltreLEnumerazione;
var
  LRows: TArray<string>;
begin
  LRows := FWriter.States(['# States', 'Frame 1', 'Duration = 1', 'Frame 2', 'Duration = 1', 'Frame 3',
    'Duration = 1', '# Weapons']);
  Assert.AreEqual('"S_STATE_3";"3";"1"', LRows[4]);
end;

procedure TTestTableExportCsvWriter.TestDovrebbeScrivereGliSprite;
var
  LRows: TArray<string>;
begin
  FStates.Sprites.AddRange(['NULL', 'TROO']);
  LRows := FWriter.Sprites;
  Assert.AreEqual<Integer>(3, Length(LRows));
  Assert.AreEqual('"id";"Sprite"', LRows[0]);
  Assert.AreEqual('1;"NULL"', LRows[1]);
  Assert.AreEqual('2;"TROO"', LRows[2]);
end;

procedure TTestTableExportCsvWriter.TestDovrebbeRifiutareUnaSorgenteMancante;
begin
  Assert.WillRaise(
    procedure
    begin
      TTableExportFactory.CreateCsvWriter(nil, FNames as IExportEnumNames);
    end, EArgumentNilException);
end;

end.
