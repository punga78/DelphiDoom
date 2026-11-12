{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TSpeedDoomFontAliases                                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Speed.DoomFontAliases;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.GameData.Intf;

type
  [TestFixture]
  [Category('speed')]
  TTestSpeedDoomFontAliases = class(TObject)
  strict private
    FWad: IGameWadComposer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeCopiareIlCarattereSottoIlNomeDiDoom;
    [Test]
    procedure DovrebbeDareIlNumeroDeiLumpAggiunti;
    [Test]
    procedure DovrebbeLasciareIlLumpDiDoomCheEsisteGia;
    [Test]
    procedure DovrebbeIgnorareICaratteriFuoriDalFontDiDoom;
    [Test]
    procedure DovrebbeNonAggiungereNullaSeIlFontNonCe;
    [Test]
    procedure DovrebbeDareEccezioneSenzaWad;
  end;

implementation

uses
  DelphiDoom.GameData.Factory, DelphiDoom.Speed.DoomFontAliases;

{ TTestSpeedDoomFontAliases }

procedure TTestSpeedDoomFontAliases.Setup;
begin
  FWad := TGameDataFactory.CreateWadComposer;
end;

procedure TTestSpeedDoomFontAliases.TearDown;
begin
  FWad := nil;
end;

procedure TTestSpeedDoomFontAliases.DovrebbeCopiareIlCarattereSottoIlNomeDiDoom;
var
  LIndex: Integer;
begin
  FWad.AddLump('SFNTA065', TBytes.Create(1, 2, 3, 4, 5));

  TSpeedDoomFontAliases.Append(FWad);

  LIndex := FWad.IndexOf('STCFN065');
  Assert.IsTrue(LIndex >= 0);
  Assert.AreEqual(5, Integer(Length(FWad.LumpData[LIndex])));
  Assert.AreEqual(4, Integer(FWad.LumpData[LIndex][3]));
end;

procedure TTestSpeedDoomFontAliases.DovrebbeDareIlNumeroDeiLumpAggiunti;
begin
  FWad.AddLump('SFNTA033', TBytes.Create(1));
  FWad.AddLump('SFNTA095', TBytes.Create(2));
  FWad.AddLump('PLAYPAL', TBytes.Create(3));

  Assert.AreEqual(2, TSpeedDoomFontAliases.Append(FWad));
  Assert.AreEqual(5, FWad.Count);
end;

procedure TTestSpeedDoomFontAliases.DovrebbeLasciareIlLumpDiDoomCheEsisteGia;
var
  LIndex: Integer;
begin
  FWad.AddLump('STCFN066', TBytes.Create(9, 9));
  FWad.AddLump('SFNTA066', TBytes.Create(1));

  Assert.AreEqual(0, TSpeedDoomFontAliases.Append(FWad));

  LIndex := FWad.IndexOf('STCFN066');
  Assert.AreEqual(2, Integer(Length(FWad.LumpData[LIndex])));
  Assert.AreEqual(2, FWad.Count);
end;

procedure TTestSpeedDoomFontAliases.DovrebbeIgnorareICaratteriFuoriDalFontDiDoom;
begin
  FWad.AddLump('SFNTA032', TBytes.Create(1));
  FWad.AddLump('SFNTA096', TBytes.Create(1));
  FWad.AddLump('SFNTA127', TBytes.Create(1));

  Assert.AreEqual(0, TSpeedDoomFontAliases.Append(FWad));
  Assert.IsTrue(FWad.IndexOf('STCFN096') < 0);
end;

procedure TTestSpeedDoomFontAliases.DovrebbeNonAggiungereNullaSeIlFontNonCe;
begin
  FWad.AddLump('COLORMAP', TBytes.Create(1));

  Assert.AreEqual(0, TSpeedDoomFontAliases.Append(FWad));
  Assert.AreEqual(1, FWad.Count);
end;

procedure TTestSpeedDoomFontAliases.DovrebbeDareEccezioneSenzaWad;
begin
  Assert.WillRaise(
    procedure
    begin
      TSpeedDoomFontAliases.Append(nil);
    end, EArgumentNilException);
end;

end.
