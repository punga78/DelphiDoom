{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - the catalog of the records           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.Catalog;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, DUnitX.TestFramework, DelphiDoom.War.Types,
  DelphiDoom.War.Intf, DelphiDoom.War.Catalog, DelphiDoom.War.Factory;

type
  [TestFixture]
  [Category('war')]
  TTestWarCatalog = class(TObject)
  private
    function Small: IWarCatalog;
  public
    [Test]
    procedure DovrebbeContareLeVociDellaTabella;
    [Test]
    procedure DovrebbeDareLeVociNellOrdineDiOrigine;
    [Test]
    procedure DovrebbeRifiutareUnaPosizioneFuoriDallaTabella;
    [Test]
    procedure DovrebbeTrovareUnaVocePerIndice;
    [Test]
    procedure DovrebbeNonTrovareUnIndiceCheNonCe;
    [Test]
    procedure DovrebbeDareTipoSconosciutoPerUnIndiceCheNonCe;
    [Test]
    procedure DovrebbeDareIlTipoDiUnaVoce;
    [Test]
    procedure DovrebbeSaltareSoloLeVociDiTipoSconosciuto;
    [Test]
    procedure DovrebbeTrovareUnLivelloPersonalizzatoSenzaDifferenzaTraMaiuscole;
    [Test]
    procedure DovrebbeIgnorareUnLivelloCheNonEPersonalizzabile;
    [Test]
    procedure DovrebbeNonTrovareUnNomeCheNonCe;
    [Test]
    procedure DovrebbeTenereLaPrimaVoceDiUnIndiceRipetuto;
    [Test]
    procedure DovrebbeDareLaTabellaDelRemake;
    [Test]
    procedure DovrebbeUguagliareIlGoldenDelCodiceOriginale;
  end;

implementation

{ TTestWarCatalog }

function TTestWarCatalog.Small: IWarCatalog;
  function Entry(AIndex: Integer; AType: TWarRecordType; const AName: string; AParam2: Word): TWarCatalogEntry;
  begin
    Result := Default(TWarCatalogEntry);
    Result.Index := AIndex;
    Result.RecordType := AType;
    Result.Name := AName;
    Result.Param2 := AParam2;
  end;
begin
  Result := TWarCatalog.Create([
    Entry(5, wrtImage, 'logo', 0),
    Entry(9, wrtUnknown, '', 0),
    Entry(12, wrtLevelInfo, 'Forest_1', 1),
    Entry(13, wrtLevelInfo, 'forest_2', 0),
    Entry(5, wrtSprite, 'again', 0)]);
end;

procedure TTestWarCatalog.DovrebbeContareLeVociDellaTabella;
begin
  Assert.AreEqual(5, Small.Count);
end;

procedure TTestWarCatalog.DovrebbeDareLeVociNellOrdineDiOrigine;
begin
  Assert.AreEqual('Forest_1', Small.GetEntry(2).Name);
  Assert.AreEqual('again', Small.GetEntry(4).Name);
end;

procedure TTestWarCatalog.DovrebbeRifiutareUnaPosizioneFuoriDallaTabella;
var
  LCatalog: IWarCatalog;
begin
  LCatalog := Small;
  Assert.WillRaise(
    procedure
    begin
      LCatalog.GetEntry(5);
    end, EWarException);
  Assert.WillRaise(
    procedure
    begin
      LCatalog.GetEntry(-1);
    end, EWarException);
end;

procedure TTestWarCatalog.DovrebbeTrovareUnaVocePerIndice;
var
  LEntry: TWarCatalogEntry;
begin
  Assert.IsTrue(Small.TryFind(12, LEntry));
  Assert.AreEqual('Forest_1', LEntry.Name);
end;

procedure TTestWarCatalog.DovrebbeNonTrovareUnIndiceCheNonCe;
var
  LEntry: TWarCatalogEntry;
begin
  Assert.IsFalse(Small.TryFind(77, LEntry));
  Assert.AreEqual('', LEntry.Name);
end;

procedure TTestWarCatalog.DovrebbeDareTipoSconosciutoPerUnIndiceCheNonCe;
begin
  Assert.AreEqual(Ord(wrtUnknown), Ord(Small.RecordTypeOf(77)));
end;

procedure TTestWarCatalog.DovrebbeDareIlTipoDiUnaVoce;
begin
  Assert.AreEqual(Ord(wrtLevelInfo), Ord(Small.RecordTypeOf(12)));
end;

procedure TTestWarCatalog.DovrebbeSaltareSoloLeVociDiTipoSconosciuto;
var
  LCatalog: IWarCatalog;
begin
  LCatalog := Small;
  Assert.IsTrue(LCatalog.IsSkipped(9));
  Assert.IsFalse(LCatalog.IsSkipped(5));
  // un indice che la tabella non elenca non si salta: come skipDecompress[]
  Assert.IsFalse(LCatalog.IsSkipped(77));
end;

procedure TTestWarCatalog.DovrebbeTrovareUnLivelloPersonalizzatoSenzaDifferenzaTraMaiuscole;
var
  LIndex: Integer;
begin
  Assert.IsTrue(Small.TryGetPredefinedCustomMapIndex('FOREST_1', LIndex));
  Assert.AreEqual(12, LIndex);
end;

procedure TTestWarCatalog.DovrebbeIgnorareUnLivelloCheNonEPersonalizzabile;
var
  LIndex: Integer;
begin
  Assert.IsFalse(Small.TryGetPredefinedCustomMapIndex('forest_2', LIndex));
end;

procedure TTestWarCatalog.DovrebbeNonTrovareUnNomeCheNonCe;
var
  LIndex: Integer;
begin
  Assert.IsFalse(Small.TryGetPredefinedCustomMapIndex('', LIndex));
  Assert.IsFalse(Small.TryGetPredefinedCustomMapIndex('forest_', LIndex));
end;

procedure TTestWarCatalog.DovrebbeTenereLaPrimaVoceDiUnIndiceRipetuto;
var
  LEntry: TWarCatalogEntry;
begin
  Assert.IsTrue(Small.TryFind(5, LEntry));
  Assert.AreEqual('logo', LEntry.Name);
end;

procedure TTestWarCatalog.DovrebbeDareLaTabellaDelRemake;
var
  LCatalog: IWarCatalog;
  LEntry: TWarCatalogEntry;
  LIndex: Integer;
begin
  LCatalog := TWarFactory.CreateCatalog;
  Assert.AreEqual(579, LCatalog.Count);
  Assert.AreEqual(Ord(wrtXmid), Ord(LCatalog.RecordTypeOf(0)));
  Assert.AreEqual(Ord(wrtPalette), Ord(LCatalog.RecordTypeOf(191)));
  Assert.IsTrue(LCatalog.TryFind(190, LEntry));
  Assert.AreEqual(Ord(wrtTiles), Ord(LEntry.RecordType));
  Assert.AreEqual(191, Integer(LEntry.Param1));
  Assert.AreEqual(217, Integer(LEntry.Param2));
  Assert.IsTrue(LCatalog.TryGetPredefinedCustomMapIndex('swamp_7_big_enemy', LIndex));
  Assert.AreEqual(176, LIndex);
  Assert.IsTrue(LCatalog.IsSkipped(214));
end;

procedure TTestWarCatalog.DovrebbeUguagliareIlGoldenDelCodiceOriginale;
var
  LLines: TStringList;
  LCatalog: IWarCatalog;
  LEntry: TWarCatalogEntry;
  LLine: string;
  LExpected: string;
  LPosition: Integer;
begin
  // il golden e' la tabella assets[] di war_database.h stampata dal C del remake compilato (war_ref.exe)
  LLines := TStringList.Create;
  try
    LLines.LoadFromFile(TPath.GetFullPath(ExtractFilePath(ParamStr(0)) + '..\..\..\..\Tests\Data\War\catalog.golden.txt'));
    LCatalog := TWarFactory.CreateCatalog;
    Assert.AreEqual(LLines.Count, LCatalog.Count);
    for LPosition := 0 to LLines.Count - 1 do
    begin
      LLine := LLines[LPosition];
      LEntry := LCatalog.GetEntry(LPosition);
      LExpected := Format('C %d %d %s %d %d %d', [LEntry.Index, Ord(LEntry.RecordType), LEntry.Name,
        LEntry.Param1, LEntry.Param2, LEntry.Param3]);
      Assert.AreEqual(LLine, LExpected, 'riga ' + IntToStr(LPosition));
    end;
  finally
    LLines.Free;
  end;
end;

end.
