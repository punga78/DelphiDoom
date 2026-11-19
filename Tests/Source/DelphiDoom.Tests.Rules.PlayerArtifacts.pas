{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the inventory routines of Heretic and Hexen            }
{                                                                              }
{  PlayerArtifacts is the same unit for the two games. What a game decides     }
{  (when a slot counts as empty, whether the freed slot is cleared) is the     }
{  two rules of the shim of TUserGameRules, with the meaning of the game of    }
{  the project; the cursors of the inventory bar are the shim of sb_bar. The   }
{  oracles are written from the meaning of the rule: the inventory is a        }
{  compact list of (type, count), the console player has a cursor on it.       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Rules.PlayerArtifacts;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  d_player,
  p_mobj_h;

type
  [TestFixture]
  [Category('rules')]
  TTestRulesPlayerArtifacts = class
  strict private
    FPlayer: player_t;
    FMobj: mobj_t;
    procedure FillInventory(const ATypes: array of Integer; const ACounts: array of Integer);
    function SlotType(ASlot: Integer): Integer;
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure DovrebbeDareIlNumeroDelGiocatore;
    [Test]
    procedure DovrebbeDareZeroPerUnGiocatoreSconosciuto;
    [Test]
    procedure DovrebbeSpostareIlCursoreIndietroPerIlGiocatoreDellaConsole;
    [Test]
    procedure DovrebbeTornareAllUltimoSlotDopoIlPrimo;
    [Test]
    procedure DovrebbeFermareLaPosizioneDelCursoreASeiNelGiroCompleto;
    [Test]
    procedure DovrebbeNonMuovereIlCursoreDiUnGiocatoreDiversoDallaConsole;
    [Test]
    procedure DovrebbeTogliereUnaSolaCopiaSenzaCompattare;
    [Test]
    procedure DovrebbeCompattareLaListaAllUltimaCopia;
    [Test]
    procedure DovrebbeAzzerareLaSceltaDelGiocatoreCheNonELaConsole;
    [Test]
    procedure DovrebbeSceglierePerLaConsoleLArtefattoSottoIlCursore;
    [Test]
    procedure DovrebbeRiportareIlCursoreAZeroSeSiTogliePrimoSlot;
    [Test]
    procedure DovrebbeUsareLeFialeAlLivelloPiuFacileESalvareLaSalute;
    [Test]
    procedure DovrebbeUsareLeUrneSeBastanoPerLaSaluteRichiesta;
    [Test]
    procedure DovrebbeNonUsareLeFialeSeNonESkillBaby;
    [Test]
    procedure DovrebbeNonUsareNullaSeGliArtefattiNonBastano;
    [Test]
    procedure DovrebbeAllinearLaSaluteDelMostroAQuellaDelGiocatore;
    {$IFDEF HEXEN}
    [Test]
    procedure DovrebbeIgnorareUnoSlotVuoto;
    [Test]
    procedure DovrebbePulireLoSlotLiberatoDallaCompattazione;
    {$ENDIF}
  end;

implementation

uses
  doomdef,
  g_game,
  sb_bar,
  DelphiDoom.Engine.World.PlayerArtifacts;

{ TTestRulesPlayerArtifacts }

procedure TTestRulesPlayerArtifacts.Setup;
begin
  FillChar(FPlayer, SizeOf(FPlayer), 0);
  FillChar(FMobj, SizeOf(FMobj), 0);
  FPlayer.mo := @FMobj;
  FillChar(TGameSession.Players, SizeOf(TGameSession.Players), 0);
  TGameSession.ConsolePlayer := 0;
  TGameSession.GameSkill := sk_medium;
  inv_ptr := 0;
  curpos := 0;
end;

procedure TTestRulesPlayerArtifacts.FillInventory(const ATypes: array of Integer; const ACounts: array of Integer);
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(ATypes) do
  begin
    FPlayer.inventory[LIndex]._type := ATypes[LIndex];
    FPlayer.inventory[LIndex].count := ACounts[LIndex];
    inc(FPlayer.artifactCount, ACounts[LIndex]);
  end;
  FPlayer.inventorySlotNum := Length(ATypes);
end;

function TTestRulesPlayerArtifacts.SlotType(ASlot: Integer): Integer;
begin
  result := FPlayer.inventory[ASlot]._type;
end;

procedure TTestRulesPlayerArtifacts.DovrebbeDareIlNumeroDelGiocatore;
begin
  Assert.AreEqual(0, P_GetPlayerNum(@TGameSession.Players[0]));
  Assert.AreEqual(2, P_GetPlayerNum(@TGameSession.Players[2]));
  Assert.AreEqual(MAXPLAYERS - 1, P_GetPlayerNum(@TGameSession.Players[MAXPLAYERS - 1]));
end;

procedure TTestRulesPlayerArtifacts.DovrebbeDareZeroPerUnGiocatoreSconosciuto;
begin
  Assert.AreEqual(0, P_GetPlayerNum(@FPlayer));
end;

procedure TTestRulesPlayerArtifacts.DovrebbeSpostareIlCursoreIndietroPerIlGiocatoreDellaConsole;
begin
  TGameSession.Players[0].inventorySlotNum := 4;
  TGameSession.Players[0].inventory[2]._type := 5;
  inv_ptr := 3;
  curpos := 3;
  P_PlayerNextArtifact(@TGameSession.Players[0]);
  Assert.AreEqual(2, inv_ptr);
  Assert.AreEqual(2, curpos);
  Assert.AreEqual<Integer>(5, Ord(TGameSession.Players[0].readyArtifact));
end;

procedure TTestRulesPlayerArtifacts.DovrebbeTornareAllUltimoSlotDopoIlPrimo;
begin
  TGameSession.Players[0].inventorySlotNum := 4;
  TGameSession.Players[0].inventory[3]._type := 7;
  inv_ptr := 0;
  curpos := 0;
  P_PlayerNextArtifact(@TGameSession.Players[0]);
  Assert.AreEqual(3, inv_ptr);
  Assert.AreEqual(3, curpos);
  Assert.AreEqual<Integer>(7, Ord(TGameSession.Players[0].readyArtifact));
end;

procedure TTestRulesPlayerArtifacts.DovrebbeFermareLaPosizioneDelCursoreASeiNelGiroCompleto;
begin
  // with more than 7 slots the cursor of the bar stays at the sixth position, the pointer goes on
  TGameSession.Players[0].inventorySlotNum := 9;
  inv_ptr := 0;
  curpos := 0;
  P_PlayerNextArtifact(@TGameSession.Players[0]);
  Assert.AreEqual(8, inv_ptr);
  Assert.AreEqual(6, curpos);
end;

procedure TTestRulesPlayerArtifacts.DovrebbeNonMuovereIlCursoreDiUnGiocatoreDiversoDallaConsole;
begin
  FPlayer.inventorySlotNum := 4;
  FPlayer.readyArtifact := artitype_t(1);
  inv_ptr := 3;
  curpos := 3;
  P_PlayerNextArtifact(@FPlayer);
  Assert.AreEqual(3, inv_ptr);
  Assert.AreEqual(3, curpos);
  Assert.AreEqual<Integer>(1, Ord(FPlayer.readyArtifact));
end;

procedure TTestRulesPlayerArtifacts.DovrebbeTogliereUnaSolaCopiaSenzaCompattare;
begin
  FillInventory([1, 2, 3], [1, 2, 1]);
  P_PlayerRemoveArtifact(@FPlayer, 1);
  Assert.AreEqual(1, FPlayer.inventory[1].count);
  Assert.AreEqual(3, FPlayer.artifactCount);
  Assert.AreEqual(3, FPlayer.inventorySlotNum);
  Assert.AreEqual(2, SlotType(1));
end;

procedure TTestRulesPlayerArtifacts.DovrebbeCompattareLaListaAllUltimaCopia;
begin
  FillInventory([1, 2, 3], [1, 1, 1]);
  P_PlayerRemoveArtifact(@FPlayer, 1);
  Assert.AreEqual(2, FPlayer.inventorySlotNum);
  Assert.AreEqual(2, FPlayer.artifactCount);
  Assert.AreEqual(1, SlotType(0));
  Assert.AreEqual(3, SlotType(1));
  Assert.AreEqual(1, FPlayer.inventory[1].count);
end;

procedure TTestRulesPlayerArtifacts.DovrebbeAzzerareLaSceltaDelGiocatoreCheNonELaConsole;
begin
  FillInventory([1, 2, 3], [1, 1, 1]);
  FPlayer.readyArtifact := artitype_t(2);
  P_PlayerRemoveArtifact(@FPlayer, 1);
  Assert.AreEqual<Integer>(Ord(arti_none), Ord(FPlayer.readyArtifact));
end;

procedure TTestRulesPlayerArtifacts.DovrebbeSceglierePerLaConsoleLArtefattoSottoIlCursore;
var
  LConsole: Pplayer_t;
begin
  LConsole := @TGameSession.Players[0];
  LConsole.inventory[0]._type := 1;
  LConsole.inventory[0].count := 1;
  LConsole.inventory[1]._type := 2;
  LConsole.inventory[1].count := 1;
  LConsole.inventory[2]._type := 3;
  LConsole.inventory[2].count := 1;
  LConsole.inventorySlotNum := 3;
  LConsole.artifactCount := 3;
  inv_ptr := 1;
  curpos := 1;
  P_PlayerRemoveArtifact(LConsole, 1);
  // the cursor goes back by one and shows the artifact that is now in that position
  Assert.AreEqual(0, inv_ptr);
  Assert.AreEqual(0, curpos);
  Assert.AreEqual<Integer>(1, Ord(LConsole.readyArtifact));
end;

procedure TTestRulesPlayerArtifacts.DovrebbeRiportareIlCursoreAZeroSeSiTogliePrimoSlot;
var
  LConsole: Pplayer_t;
begin
  LConsole := @TGameSession.Players[0];
  LConsole.inventory[0]._type := 1;
  LConsole.inventory[0].count := 1;
  LConsole.inventory[1]._type := 2;
  LConsole.inventory[1].count := 1;
  LConsole.inventorySlotNum := 2;
  LConsole.artifactCount := 2;
  inv_ptr := 0;
  curpos := 0;
  P_PlayerRemoveArtifact(LConsole, 0);
  Assert.AreEqual(0, inv_ptr);
  Assert.AreEqual(0, curpos);
  Assert.AreEqual<Integer>(2, Ord(LConsole.readyArtifact));
end;

procedure TTestRulesPlayerArtifacts.DovrebbeUsareLeFialeAlLivelloPiuFacileESalvareLaSalute;
begin
  // two flasks give 50, the 30 asked for need two of them ((30 + 24) div 25)
  TGameSession.GameSkill := sk_baby;
  FPlayer.health := 10;
  FillInventory([Ord(arti_health)], [2]);
  P_AutoUseHealth(@FPlayer, 30);
  Assert.AreEqual(60, FPlayer.health);
  Assert.AreEqual(0, FPlayer.inventorySlotNum);
  Assert.AreEqual(0, FPlayer.artifactCount);
end;

procedure TTestRulesPlayerArtifacts.DovrebbeUsareLeUrneSeBastanoPerLaSaluteRichiesta;
begin
  FPlayer.health := 10;
  FillInventory([Ord(arti_superhealth)], [2]);
  P_AutoUseHealth(@FPlayer, 30);
  Assert.AreEqual(110, FPlayer.health);
  Assert.AreEqual(1, FPlayer.inventory[0].count);
  Assert.AreEqual(1, FPlayer.artifactCount);
end;

procedure TTestRulesPlayerArtifacts.DovrebbeNonUsareLeFialeSeNonESkillBaby;
begin
  FPlayer.health := 10;
  FillInventory([Ord(arti_health)], [4]);
  P_AutoUseHealth(@FPlayer, 30);
  Assert.AreEqual(10, FPlayer.health);
  Assert.AreEqual(4, FPlayer.inventory[0].count);
end;

procedure TTestRulesPlayerArtifacts.DovrebbeNonUsareNullaSeGliArtefattiNonBastano;
begin
  TGameSession.GameSkill := sk_baby;
  FPlayer.health := 10;
  FillInventory([Ord(arti_health)], [1]);
  P_AutoUseHealth(@FPlayer, 80);
  Assert.AreEqual(10, FPlayer.health);
  Assert.AreEqual(1, FPlayer.inventory[0].count);
end;

procedure TTestRulesPlayerArtifacts.DovrebbeAllinearLaSaluteDelMostroAQuellaDelGiocatore;
begin
  FPlayer.health := 33;
  FMobj.health := 1;
  P_AutoUseHealth(@FPlayer, 30);
  Assert.AreEqual(33, FMobj.health);
end;

{$IFDEF HEXEN}
procedure TTestRulesPlayerArtifacts.DovrebbeIgnorareUnoSlotVuoto;
begin
  FillInventory([1, 0], [1, 0]);
  FPlayer.artifactCount := 1;
  P_PlayerRemoveArtifact(@FPlayer, 1);
  Assert.AreEqual(1, FPlayer.artifactCount);
  Assert.AreEqual(2, FPlayer.inventorySlotNum);
end;

procedure TTestRulesPlayerArtifacts.DovrebbePulireLoSlotLiberatoDallaCompattazione;
begin
  FillInventory([1, 2, 3], [1, 1, 1]);
  P_PlayerRemoveArtifact(@FPlayer, 0);
  Assert.AreEqual(2, FPlayer.inventorySlotNum);
  Assert.AreEqual(0, SlotType(2));
  Assert.AreEqual(0, FPlayer.inventory[2].count);
end;
{$ENDIF}

end.
