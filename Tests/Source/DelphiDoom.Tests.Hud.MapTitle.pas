{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the heads-up display library - the title of the map  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Hud.MapTitle;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('hud')]
  TTestHudMapTitle = class(TObject)
  public
    [Test]
    procedure DovrebbeLeggereIlNomeDaUnEpisodio;
    [Test]
    procedure DovrebbeInventareIlNomeFuoriDallaTabellaDegliEpisodi;
    [Test]
    procedure DovrebbeLeggereIlNomeDaUnaLista;
    [Test]
    procedure DovrebbeInventareIlNomeFuoriDallaLista;
    [Test]
    procedure DovrebbeScrivereLEtichettaDellaMappa;
    [Test]
    procedure DovrebbeUsareIlNomeDellaMappaSeManca;
    [Test]
    procedure DovrebbeTogliereLEtichettaMenoUnoSeNonEIlNomeDellaMappa;
    [Test]
    procedure DovrebbeTenereIlNomeDellaMappaSeLEtichettaEMenoUno;
  end;

implementation

uses
  DelphiDoom.Hud.MapTitle;

{ TTestHudMapTitle }

procedure TTestHudMapTitle.DovrebbeLeggereIlNomeDaUnEpisodio;
const
  NAMES: array[0..17] of string = ('E1M1', 'E1M2', 'E1M3', 'E1M4', 'E1M5', 'E1M6', 'E1M7', 'E1M8',
    'E1M9', 'E2M1', 'E2M2', 'E2M3', 'E2M4', 'E2M5', 'E2M6', 'E2M7', 'E2M8', 'E2M9');
begin
  Assert.AreEqual('E1M1', THudMapTitle.ForEpisode(NAMES, 1, 1));
  Assert.AreEqual('E2M3', THudMapTitle.ForEpisode(NAMES, 2, 3));
  Assert.AreEqual('E2M9', THudMapTitle.ForEpisode(NAMES, 2, 9));
end;

procedure TTestHudMapTitle.DovrebbeInventareIlNomeFuoriDallaTabellaDegliEpisodi;
const
  NAMES: array[0..8] of string = ('a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i');
begin
  Assert.AreEqual('Episode 2 - Map 1', THudMapTitle.ForEpisode(NAMES, 2, 1));
  Assert.AreEqual('Episode 1 - Map 0', THudMapTitle.ForEpisode(NAMES, 1, 0));
  Assert.AreEqual('Episode 0 - Map 1', THudMapTitle.ForEpisode(NAMES, 0, 1));
end;

procedure TTestHudMapTitle.DovrebbeLeggereIlNomeDaUnaLista;
const
  NAMES: array[0..2] of string = ('one', 'two', 'three');
begin
  Assert.AreEqual('one', THudMapTitle.ForMap(NAMES, 1));
  Assert.AreEqual('three', THudMapTitle.ForMap(NAMES, 3));
end;

procedure TTestHudMapTitle.DovrebbeInventareIlNomeFuoriDallaLista;
const
  NAMES: array[0..2] of string = ('one', 'two', 'three');
begin
  Assert.AreEqual('Map 0', THudMapTitle.ForMap(NAMES, 0));
  Assert.AreEqual('Map 4', THudMapTitle.ForMap(NAMES, 4));
end;

procedure TTestHudMapTitle.DovrebbeScrivereLEtichettaDellaMappa;
begin
  Assert.AreEqual('E1M8: Phobos Anomaly', THudMapTitle.FromMapInfo('MAP01', 'E1M8', 'Phobos Anomaly'));
end;

procedure TTestHudMapTitle.DovrebbeUsareIlNomeDellaMappaSeManca;
begin
  Assert.AreEqual('MAP07: Dead Simple', THudMapTitle.FromMapInfo('MAP07', '', 'Dead Simple'));
end;

procedure TTestHudMapTitle.DovrebbeTogliereLEtichettaMenoUnoSeNonEIlNomeDellaMappa;
begin
  Assert.AreEqual('Dead Simple', THudMapTitle.FromMapInfo('MAP07', '-', 'Dead Simple'));
end;

procedure TTestHudMapTitle.DovrebbeTenereIlNomeDellaMappaSeLEtichettaEMenoUno;
begin
  // the label "-" is also the name of the map: then it is written, as the old code did
  Assert.AreEqual('-: Dead Simple', THudMapTitle.FromMapInfo('-', '-', 'Dead Simple'));
end;


end.