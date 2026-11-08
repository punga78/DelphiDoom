{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the doors - the profiles of the games                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Thinkers.DoorProfiles;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Thinkers.Door.Types;

type
  [TestFixture]
  [Category('thinkers')]
  TTestThinkersDoorProfiles = class(TObject)
  public
    [Test]
    procedure DovrebbeDareIlNomeDiOgniGioco;
    [Test]
    procedure DovrebbeTrovareIlGiocoDalNomeSenzaDistinguereLeMaiuscole;
    [Test]
    procedure DovrebbeRifiutareUnNomeSconosciuto;
    [Test]
    procedure DovrebbeNonAvereLePorteClassicheInHexen;
    [Test]
    procedure DovrebbeFarTornareSuUnaPortaSchiacciataPerImpostazione;
    [Test]
    procedure DovrebbeNonFarTornareSuLePorteCheChiudono;
    [Test]
    procedure DovrebbeCollegareLeLuciSoloInDoomEStrife;
    [Test]
    procedure DovrebbeAvereLePorteDiviseSoloInStrife;
    [Test]
    procedure DovrebbeFermareIlSuonoSoloNellePortePerScript;
    [Test]
    procedure DovrebbeAvereLeStesseRegoleDellePortePerScriptInOgniGioco;
    [Test]
    procedure DovrebbeAvereLeLineeDelleAperturaAManoDiOgniGioco;
    [Test]
    procedure DovrebbeAvereLeLineeCheRichiamanoLePorteDiOgniGioco;
  end;

implementation

uses
  DelphiDoom.Thinkers.Door.Profiles;

function Contains(const ASpecials: TArray<Integer>; ASpecial: Integer): Boolean;
var
  LIndex: Integer;
begin
  Result := False;
  for LIndex := 0 to High(ASpecials) do
    if ASpecials[LIndex] = ASpecial then
      Result := True;
end;

{ TTestThinkersDoorProfiles }

procedure TTestThinkersDoorProfiles.DovrebbeDareIlNomeDiOgniGioco;
begin
  Assert.AreEqual('DOOM', TDoorProfiles.NameOf(TDoorGame.Doom));
  Assert.AreEqual('HERETIC', TDoorProfiles.NameOf(TDoorGame.Heretic));
  Assert.AreEqual('HEXEN', TDoorProfiles.NameOf(TDoorGame.Hexen));
  Assert.AreEqual('STRIFE', TDoorProfiles.NameOf(TDoorGame.Strife));
end;

procedure TTestThinkersDoorProfiles.DovrebbeTrovareIlGiocoDalNomeSenzaDistinguereLeMaiuscole;
var
  LGame: TDoorGame;
begin
  Assert.IsTrue(TDoorProfiles.TryGameFromName('Strife', LGame));
  Assert.AreEqual(Ord(TDoorGame.Strife), Ord(LGame));
  Assert.IsTrue(TDoorProfiles.TryGameFromName('hexen', LGame));
  Assert.AreEqual(Ord(TDoorGame.Hexen), Ord(LGame));
end;

procedure TTestThinkersDoorProfiles.DovrebbeRifiutareUnNomeSconosciuto;
var
  LGame: TDoorGame;
begin
  Assert.IsFalse(TDoorProfiles.TryGameFromName('QUAKE', LGame));
  Assert.IsFalse(TDoorProfiles.TryGameFromName('', LGame));
end;

procedure TTestThinkersDoorProfiles.DovrebbeNonAvereLePorteClassicheInHexen;
begin
  Assert.WillRaise(
    procedure
    begin
      TDoorProfiles.ForGame(TDoorGame.Hexen, TDoorFlavor.Classic);
    end, EDoorException);
end;

procedure TTestThinkersDoorProfiles.DovrebbeFarTornareSuUnaPortaSchiacciataPerImpostazione;
var
  LProfile: TDoorProfile;
begin
  LProfile := TDoorProfiles.ForGame(TDoorGame.Doom, TDoorFlavor.Classic);
  Assert.AreEqual(Ord(TDoorCrushed.GoUp), Ord(LProfile.Rules[TDoorKind.Normal].Crushed));
  Assert.AreEqual(Ord(TDoorSound.Open), Ord(LProfile.Rules[TDoorKind.Normal].CrushedSound));
  // the doors of the scripted specials go up without a sound
  LProfile := TDoorProfiles.ForGame(TDoorGame.Doom, TDoorFlavor.Udmf);
  Assert.AreEqual(Ord(TDoorCrushed.GoUp), Ord(LProfile.Rules[TDoorKind.UdmfNormal].Crushed));
  Assert.AreEqual(Ord(TDoorSound.None), Ord(LProfile.Rules[TDoorKind.UdmfNormal].CrushedSound));
end;

procedure TTestThinkersDoorProfiles.DovrebbeNonFarTornareSuLePorteCheChiudono;
var
  LProfile: TDoorProfile;
begin
  LProfile := TDoorProfiles.ForGame(TDoorGame.Doom, TDoorFlavor.Classic);
  Assert.AreEqual(Ord(TDoorCrushed.Nothing), Ord(LProfile.Rules[TDoorKind.Close].Crushed));
  Assert.AreEqual(Ord(TDoorCrushed.Nothing), Ord(LProfile.Rules[TDoorKind.BlazeClose].Crushed));
  LProfile := TDoorProfiles.ForGame(TDoorGame.Strife, TDoorFlavor.Classic);
  Assert.AreEqual(Ord(TDoorCrushed.Nothing), Ord(LProfile.Rules[TDoorKind.ShopClose].Crushed));
  LProfile := TDoorProfiles.ForGame(TDoorGame.Hexen, TDoorFlavor.Udmf);
  Assert.AreEqual(Ord(TDoorCrushed.Nothing), Ord(LProfile.Rules[TDoorKind.UdmfClose].Crushed));
end;

procedure TTestThinkersDoorProfiles.DovrebbeCollegareLeLuciSoloInDoomEStrife;
begin
  Assert.IsTrue(TDoorProfiles.ForGame(TDoorGame.Doom, TDoorFlavor.Classic).LinkLights);
  Assert.IsTrue(TDoorProfiles.ForGame(TDoorGame.Strife, TDoorFlavor.Classic).LinkLights);
  Assert.IsFalse(TDoorProfiles.ForGame(TDoorGame.Heretic, TDoorFlavor.Classic).LinkLights);
  Assert.IsFalse(TDoorProfiles.ForGame(TDoorGame.Doom, TDoorFlavor.Udmf).LinkLights);
end;

procedure TTestThinkersDoorProfiles.DovrebbeAvereLePorteDiviseSoloInStrife;
begin
  Assert.IsTrue(TDoorProfiles.ForGame(TDoorGame.Strife, TDoorFlavor.Classic).SplitDoors);
  Assert.IsFalse(TDoorProfiles.ForGame(TDoorGame.Doom, TDoorFlavor.Classic).SplitDoors);
  Assert.IsFalse(TDoorProfiles.ForGame(TDoorGame.Heretic, TDoorFlavor.Classic).SplitDoors);
end;

procedure TTestThinkersDoorProfiles.DovrebbeFermareIlSuonoSoloNellePortePerScript;
begin
  Assert.IsTrue(TDoorProfiles.ForGame(TDoorGame.Hexen, TDoorFlavor.Udmf).StopSoundOnPastDest);
  Assert.IsFalse(TDoorProfiles.ForGame(TDoorGame.Doom, TDoorFlavor.Classic).StopSoundOnPastDest);
end;

procedure TTestThinkersDoorProfiles.DovrebbeAvereLeStesseRegoleDellePortePerScriptInOgniGioco;
var
  LGame: TDoorGame;
  LKind: TDoorKind;
  LFirst, LOther: TDoorProfile;
begin
  LFirst := TDoorProfiles.ForGame(TDoorGame.Doom, TDoorFlavor.Udmf);
  for LGame := Low(TDoorGame) to High(TDoorGame) do
  begin
    LOther := TDoorProfiles.ForGame(LGame, TDoorFlavor.Udmf);
    for LKind := Low(TDoorKind) to High(TDoorKind) do
    begin
      Assert.AreEqual(Ord(LFirst.Rules[LKind].WaitEnd), Ord(LOther.Rules[LKind].WaitEnd));
      Assert.AreEqual(Ord(LFirst.Rules[LKind].DownDone), Ord(LOther.Rules[LKind].DownDone));
      Assert.AreEqual(Ord(LFirst.Rules[LKind].UpDone), Ord(LOther.Rules[LKind].UpDone));
      Assert.AreEqual(Ord(LFirst.Rules[LKind].Spawn.TopMode), Ord(LOther.Rules[LKind].Spawn.TopMode));
    end;
  end;
end;

procedure TTestThinkersDoorProfiles.DovrebbeAvereLeLineeDelleAperturaAManoDiOgniGioco;
var
  LProfile: TDoorProfile;
begin
  LProfile := TDoorProfiles.ForGame(TDoorGame.Doom, TDoorFlavor.Classic);
  Assert.IsTrue(Contains(LProfile.ManualSpecials[TDoorManualKind.BlazeRaising], 117));
  Assert.IsTrue(Contains(LProfile.ManualSpecials[TDoorManualKind.Opening], 31));
  Assert.IsFalse(Contains(LProfile.ManualSpecials[TDoorManualKind.Opening], 156));

  LProfile := TDoorProfiles.ForGame(TDoorGame.Strife, TDoorFlavor.Classic);
  Assert.IsTrue(Contains(LProfile.ManualSpecials[TDoorManualKind.Opening], 156));
  Assert.IsTrue(Contains(LProfile.ManualSpecials[TDoorManualKind.Opening], 158));

  LProfile := TDoorProfiles.ForGame(TDoorGame.Heretic, TDoorFlavor.Classic);
  Assert.AreEqual(0, Integer(Length(LProfile.ManualSpecials[TDoorManualKind.BlazeRaising])),
    'Heretic has no blazing doors');

  LProfile := TDoorProfiles.ForGame(TDoorGame.Hexen, TDoorFlavor.Udmf);
  Assert.IsTrue(Contains(LProfile.ManualSpecials[TDoorManualKind.Opening], 11));
  Assert.IsTrue(LProfile.ManualConsumesSpecial[TDoorManualKind.Opening]);
  Assert.IsFalse(LProfile.ManualConsumesSpecial[TDoorManualKind.Raising]);
end;

procedure TTestThinkersDoorProfiles.DovrebbeAvereLeLineeCheRichiamanoLePorteDiOgniGioco;
begin
  Assert.AreEqual(5, Integer(Length(TDoorProfiles.ForGame(TDoorGame.Doom,
    TDoorFlavor.Classic).RetriggerSpecials)));
  Assert.AreEqual(4, Integer(Length(TDoorProfiles.ForGame(TDoorGame.Heretic,
    TDoorFlavor.Classic).RetriggerSpecials)));
  Assert.AreEqual(15, Integer(Length(TDoorProfiles.ForGame(TDoorGame.Strife,
    TDoorFlavor.Classic).RetriggerSpecials)));
  Assert.AreEqual(0, Integer(Length(TDoorProfiles.ForGame(TDoorGame.Doom,
    TDoorFlavor.Udmf).RetriggerSpecials)));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestThinkersDoorProfiles);

end.
