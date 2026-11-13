{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the ide library - the tree panels (small tables)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Ide.Catalogs;

interface

uses
  DUnitX.TestFramework,
  DelphiDoom.Ide.Intf,
  DelphiDoom.Tests.Ide.FakeGameLibrary;

type
  [TestFixture]
  [Category('ide')]
  TTestIdeCatalogs = class(TObject)
  strict private
    FLibrary: TFakeIdeGameLibrary;
    FLibraryIntf: IIdeGameLibrary;
    procedure GiveStates;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeOrdinareLeDichiarazioniDiUnaClasse;
    [Test]
    procedure DovrebbeTogliereLeDichiarazioniRipetute;
    [Test]
    procedure DovrebbeFiltrareLeClassiPerNome;
    [Test]
    procedure DovrebbeOrdinareICampiDiUnActor;
    [Test]
    procedure DovrebbeScrivereIlNomeDelloStatoNeiCampiFrame;
    [Test]
    procedure DovrebbeEspandereLeUnitaFrazionarieNeiCampiDiUnActor;
    [Test]
    procedure DovrebbeDareICampiDelloStatoPuntatoDaUnCampoFrame;
    [Test]
    procedure DovrebbeNonDareRigheSeLaRigaNonEUnFrame;
    [Test]
    procedure DovrebbeScrivereNomeSpriteELetteraNeiCampiDiUnoStato;
    [Test]
    procedure DovrebbeDareICampiDelloStatoPerNomeOPerProssimoFotogramma;
    [Test]
    procedure DovrebbeLegareGliActorAiFotogrammiDegliSprite;
    [Test]
    procedure DovrebbeDareGliActorDiUnoSpriteSenzaRipetizioni;
    [Test]
    procedure DovrebbeDareSoloLActorSeLaRigaEUnActor;
    [Test]
    procedure DovrebbeNonFermarsiSuUnaCatenaDiStatiCheTornaIndietro;
  end;

implementation

uses
  DelphiDoom.Ide.Types,
  DelphiDoom.Ide.Outline,
  DelphiDoom.Ide.ClassCatalog,
  DelphiDoom.Ide.MobjinfoCatalog,
  DelphiDoom.Ide.StateCatalog,
  DelphiDoom.Ide.SpriteCatalog;

{ TTestIdeCatalogs }

procedure TTestIdeCatalogs.Setup;
begin
  FLibrary := TFakeIdeGameLibrary.Create;
  FLibraryIntf := FLibrary;
end;

procedure TTestIdeCatalogs.TearDown;
begin
  FLibraryIntf := nil;
end;

procedure TTestIdeCatalogs.GiveStates;
begin
  FLibrary.SetLines(ldSpritesCsv, 'doom', ['"Id";"Sprite"', '"0";"TROO"', '"1";"POSS"']);
  FLibrary.SetLines(ldStatesCsv, 'doom', [
    '"Name";"Sprite Number";"Sprite Subnumber";"Next Frame"',
    '"S_NULL";"0";"0";"1"',
    '"S_TROO1";"0";"32769";"2"',
    '"S_POSS1";"1";"2";"0"',
    '"S_END";"1";"3";"0"']);
end;

procedure TTestIdeCatalogs.DovrebbeOrdinareLeDichiarazioniDiUnaClasse;
var
  LCatalog: TIdeClassCatalog;
  LOutline: TIdeOutline;
  LLines: TArray<string>;
begin
  FLibrary.SetLines(ldClasses, 'doom', [
    'TThing=property Z: Integer|procedure Free|constructor Create|inherit TObject|function A: Integer|x unknown|destructor Destroy']);
  LCatalog := TIdeClassCatalog.Create;
  try
    Assert.IsTrue(LCatalog.Load(FLibraryIntf, 'doom'));
    LOutline := LCatalog.BuildOutline('');
    try
      LLines := LOutline.ToLines;
      Assert.AreEqual('TThing', LLines[0]);
      Assert.AreEqual('  inherit TObject', LLines[1]);
      Assert.AreEqual('  constructor Create', LLines[2]);
      Assert.AreEqual('  destructor Destroy', LLines[3]);
      Assert.AreEqual('  function A: Integer', LLines[4]);
      Assert.AreEqual('  procedure Free', LLines[5]);
      Assert.AreEqual('  property Z: Integer', LLines[6]);
      Assert.AreEqual('  x unknown', LLines[7]);
    finally
      LOutline.Free;
    end;
  finally
    LCatalog.Free;
  end;
end;

procedure TTestIdeCatalogs.DovrebbeTogliereLeDichiarazioniRipetute;
var
  LCatalog: TIdeClassCatalog;
  LOutline: TIdeOutline;
begin
  FLibrary.SetLines(ldClasses, 'doom', ['TThing=procedure Free|PROCEDURE FREE|procedure Free']);
  LCatalog := TIdeClassCatalog.Create;
  try
    LCatalog.Load(FLibraryIntf, 'doom');
    LOutline := LCatalog.BuildOutline('');
    try
      // the comparison does not look at the case, so the second line is the same as the first
      Assert.AreEqual<Integer>(2, Length(LOutline.ToLines));
    finally
      LOutline.Free;
    end;
  finally
    LCatalog.Free;
  end;
end;

procedure TTestIdeCatalogs.DovrebbeFiltrareLeClassiPerNome;
var
  LCatalog: TIdeClassCatalog;
  LOutline: TIdeOutline;
begin
  FLibrary.SetLines(ldClasses, 'doom', ['TActor=procedure A', 'TLine=procedure B', 'Other=procedure C']);
  LCatalog := TIdeClassCatalog.Create;
  try
    LCatalog.Load(FLibraryIntf, 'doom');
    LOutline := LCatalog.BuildOutline('  LINE ');
    try
      Assert.AreEqual(1, LOutline.Roots.Count);
      Assert.AreEqual('TLine', LOutline.Roots[0].Text);
    finally
      LOutline.Free;
    end;
  finally
    LCatalog.Free;
  end;
end;

procedure TTestIdeCatalogs.DovrebbeOrdinareICampiDiUnActor;
begin
  Assert.IsTrue(TIdeMobjinfoCatalog.CompareFields('InheritsFrom: x', 'Name: y') < 0);
  Assert.IsTrue(TIdeMobjinfoCatalog.CompareFields('Id #: 1', 'Id: 1') < 0);
  Assert.IsTrue(TIdeMobjinfoCatalog.CompareFields('Name: a', 'Spawn Frame: 1') < 0);
  Assert.IsTrue(TIdeMobjinfoCatalog.CompareFields('Spawn Frame: 1', 'Bits: 4') < 0);
  Assert.IsTrue(TIdeMobjinfoCatalog.CompareFields('Bits: 4', 'Bits2: 4') < 0);
  Assert.IsTrue(TIdeMobjinfoCatalog.CompareFields('Flags6_ex: 1', 'Seesound: 1') < 0);
  Assert.IsTrue(TIdeMobjinfoCatalog.CompareFields('Seesound: 1', 'Speed: 1') < 0);
  Assert.IsTrue(TIdeMobjinfoCatalog.CompareFields('Speed: 1', 'Radius: 1') > 0);
  Assert.AreEqual(0, TIdeMobjinfoCatalog.CompareFields('Speed: 1', 'SPEED: 1'));
end;

procedure TTestIdeCatalogs.DovrebbeScrivereIlNomeDelloStatoNeiCampiFrame;
var
  LCatalog: TIdeMobjinfoCatalog;
  LOutline: TIdeOutline;
  LLines: TArray<string>;
begin
  GiveStates;
  FLibrary.SetLines(ldMobjinfoCsv, 'doom', [
    '"Id";"Name";"Spawn Frame";"Speed"',
    '"1";"MT_IMP";"2";"8"']);
  LCatalog := TIdeMobjinfoCatalog.Create;
  try
    Assert.IsTrue(LCatalog.Load(FLibraryIntf, 'doom'));
    LOutline := LCatalog.BuildOutline('');
    try
      LLines := LOutline.ToLines;
      Assert.AreEqual('MT_IMP', LLines[0]);
      // the id comes first, then the name, then the frames, then the rest
      Assert.AreEqual('  Id: 1', LLines[1]);
      Assert.AreEqual('  Name: MT_IMP', LLines[2]);
      Assert.AreEqual('  Spawn Frame: S_POSS1', LLines[3]);
      Assert.AreEqual('  Speed: 8', LLines[4]);
    finally
      LOutline.Free;
    end;
  finally
    LCatalog.Free;
  end;
end;

procedure TTestIdeCatalogs.DovrebbeEspandereLeUnitaFrazionarieNeiCampiDiUnActor;
var
  LCatalog: TIdeMobjinfoCatalog;
  LOutline: TIdeOutline;
begin
  GiveStates;
  FLibrary.SetLines(ldMobjinfoCsv, 'doom', ['"Id";"Name";"Radius"', '"1";"MT_IMP";"1310720"']);
  LCatalog := TIdeMobjinfoCatalog.Create;
  try
    LCatalog.Load(FLibraryIntf, 'doom');
    LOutline := LCatalog.BuildOutline('');
    try
      Assert.AreEqual('  Radius: 20 * FRACUNIT', LOutline.ToLines[3]);
    finally
      LOutline.Free;
    end;
  finally
    LCatalog.Free;
  end;
end;

procedure TTestIdeCatalogs.DovrebbeDareICampiDelloStatoPuntatoDaUnCampoFrame;
var
  LCatalog: TIdeMobjinfoCatalog;
  LRows: TArray<TIdeRow>;
begin
  GiveStates;
  FLibrary.SetLines(ldMobjinfoCsv, 'doom', ['"Id";"Name";"Spawn Frame"', '"1";"MT_IMP";"2"']);
  LCatalog := TIdeMobjinfoCatalog.Create;
  try
    LCatalog.Load(FLibraryIntf, 'doom');
    LRows := LCatalog.RowsFor('Spawn Frame: S_POSS1');
    Assert.AreEqual<Integer>(4, Length(LRows));
    Assert.AreEqual('Name', LRows[0].Caption);
    Assert.AreEqual('S_POSS1', LRows[0].Values[0]);
    Assert.AreEqual('Sprite Number', LRows[1].Caption);
    Assert.AreEqual('POSS', LRows[1].Values[0]);
    Assert.AreEqual('C', LRows[2].Values[0]);
    // a number that is a place of the table works too
    Assert.AreEqual<Integer>(4, Length(LCatalog.RowsFor('Spawn Frame: 2')));
  finally
    LCatalog.Free;
  end;
end;

procedure TTestIdeCatalogs.DovrebbeNonDareRigheSeLaRigaNonEUnFrame;
var
  LCatalog: TIdeMobjinfoCatalog;
begin
  GiveStates;
  FLibrary.SetLines(ldMobjinfoCsv, 'doom', ['"Id";"Name";"Spawn Frame"', '"1";"MT_IMP";"2"']);
  LCatalog := TIdeMobjinfoCatalog.Create;
  try
    LCatalog.Load(FLibraryIntf, 'doom');
    Assert.AreEqual<Integer>(0, Length(LCatalog.RowsFor('MT_IMP')));
    Assert.AreEqual<Integer>(0, Length(LCatalog.RowsFor('Name: MT_IMP')));
    Assert.AreEqual<Integer>(0, Length(LCatalog.RowsFor('Spawn Frame: nothing')));
    Assert.AreEqual<Integer>(0, Length(LCatalog.RowsFor('')));
  finally
    LCatalog.Free;
  end;
end;

procedure TTestIdeCatalogs.DovrebbeScrivereNomeSpriteELetteraNeiCampiDiUnoStato;
var
  LCatalog: TIdeStateCatalog;
  LOutline: TIdeOutline;
  LLines: TArray<string>;
begin
  GiveStates;
  LCatalog := TIdeStateCatalog.Create;
  try
    Assert.IsTrue(LCatalog.Load(FLibraryIntf, 'doom'));
    LOutline := LCatalog.BuildOutline('troo');
    try
      LLines := LOutline.ToLines;
      Assert.AreEqual('S_TROO1', LLines[0]);
      Assert.AreEqual('  Name: S_TROO1', LLines[1]);
      Assert.AreEqual('  Sprite Number: TROO', LLines[2]);
      Assert.AreEqual('  Sprite Subnumber: B BRIGHT', LLines[3]);
      Assert.AreEqual('  Next Frame: S_POSS1', LLines[4]);
    finally
      LOutline.Free;
    end;
  finally
    LCatalog.Free;
  end;
end;

procedure TTestIdeCatalogs.DovrebbeDareICampiDelloStatoPerNomeOPerProssimoFotogramma;
var
  LCatalog: TIdeStateCatalog;
begin
  GiveStates;
  LCatalog := TIdeStateCatalog.Create;
  try
    LCatalog.Load(FLibraryIntf, 'doom');
    Assert.AreEqual<Integer>(4, Length(LCatalog.RowsFor('S_POSS1')));
    Assert.AreEqual<Integer>(4, Length(LCatalog.RowsFor('Next Frame: S_POSS1')));
    Assert.AreEqual<Integer>(0, Length(LCatalog.RowsFor('Duration: 3')));
    Assert.AreEqual<Integer>(0, Length(LCatalog.RowsFor('S_UNKNOWN')));
  finally
    LCatalog.Free;
  end;
end;

procedure TTestIdeCatalogs.DovrebbeLegareGliActorAiFotogrammiDegliSprite;
var
  LCatalog: TIdeSpriteCatalog;
  LOutline: TIdeOutline;
  LLines: TArray<string>;
begin
  GiveStates;
  FLibrary.SetLines(ldMobjinfoCsv, 'doom', [
    '"Id";"Name";"Spawn Frame";"Speed"',
    '"1";"MT_IMP";"1";"8"']);
  LCatalog := TIdeSpriteCatalog.Create;
  try
    Assert.IsTrue(LCatalog.Load(FLibraryIntf, 'doom'));
    LOutline := LCatalog.BuildOutline('');
    try
      LLines := LOutline.ToLines;
      // MT_IMP starts at state 1 (TROOB), whose next state is 2 (POSSC), which goes back to 0
      Assert.AreEqual('POSS', LLines[0]);
      Assert.AreEqual('  POSSC', LLines[1]);
      Assert.AreEqual('    MT_IMP', LLines[2]);
      Assert.AreEqual('  POSSD', LLines[3]);
      Assert.AreEqual('TROO', LLines[4]);
      Assert.AreEqual('  TROOA', LLines[5]);
      Assert.AreEqual('  TROOB', LLines[6]);
      Assert.AreEqual('    MT_IMP', LLines[7]);
    finally
      LOutline.Free;
    end;
  finally
    LCatalog.Free;
  end;
end;

procedure TTestIdeCatalogs.DovrebbeDareGliActorDiUnoSpriteSenzaRipetizioni;
var
  LCatalog: TIdeSpriteCatalog;
  LRows: TArray<TIdeRow>;
begin
  GiveStates;
  FLibrary.SetLines(ldMobjinfoCsv, 'doom', [
    '"Id";"Name";"Spawn Frame";"See Frame"',
    '"1";"MT_IMP";"1";"1"',
    '"2";"MT_BOSS";"2";"1"']);
  LCatalog := TIdeSpriteCatalog.Create;
  try
    LCatalog.Load(FLibraryIntf, 'doom');
    LRows := LCatalog.RowsFor('TROO', 0);
    Assert.AreEqual<Integer>(2, Length(LRows));
    Assert.AreEqual('MT_BOSS', LRows[0].Caption);
    Assert.AreEqual('MT_IMP', LRows[1].Caption);
    LRows := LCatalog.RowsFor('TROOB', 1);
    Assert.AreEqual<Integer>(2, Length(LRows));
    Assert.AreEqual<Integer>(0, Length(LCatalog.RowsFor('NONE', 0)));
  finally
    LCatalog.Free;
  end;
end;

procedure TTestIdeCatalogs.DovrebbeDareSoloLActorSeLaRigaEUnActor;
var
  LCatalog: TIdeSpriteCatalog;
  LRows: TArray<TIdeRow>;
begin
  GiveStates;
  LCatalog := TIdeSpriteCatalog.Create;
  try
    LCatalog.Load(FLibraryIntf, 'doom');
    LRows := LCatalog.RowsFor('MT_IMP', 2);
    Assert.AreEqual<Integer>(1, Length(LRows));
    Assert.AreEqual('MT_IMP', LRows[0].Caption);
  finally
    LCatalog.Free;
  end;
end;

procedure TTestIdeCatalogs.DovrebbeNonFermarsiSuUnaCatenaDiStatiCheTornaIndietro;
var
  LCatalog: TIdeSpriteCatalog;
  LOutline: TIdeOutline;
begin
  FLibrary.SetLines(ldSpritesCsv, 'doom', ['"Id";"Sprite"', '"0";"AAAA"']);
  // state 1 -> 2 -> 1 -> ...: the walk must stop
  FLibrary.SetLines(ldStatesCsv, 'doom', [
    '"Name";"Sprite Number";"Sprite Subnumber";"Next Frame"',
    '"S_0";"0";"0";"0"',
    '"S_1";"0";"1";"2"',
    '"S_2";"0";"2";"1"']);
  FLibrary.SetLines(ldMobjinfoCsv, 'doom', ['"Id";"Name";"Spawn Frame"', '"1";"MT_LOOP";"1"']);
  LCatalog := TIdeSpriteCatalog.Create;
  try
    LCatalog.Load(FLibraryIntf, 'doom');
    LOutline := LCatalog.BuildOutline('');
    try
      // AAAA, its three frames, and the actor under the two frames the walk touched
      Assert.AreEqual<Integer>(6, Length(LOutline.ToLines));
    finally
      LOutline.Free;
    end;
  finally
    LCatalog.Free;
  end;
end;

end.
