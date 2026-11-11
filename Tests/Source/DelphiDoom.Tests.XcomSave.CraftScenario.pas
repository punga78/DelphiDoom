{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the xcom saved game library - the craft           }
{  (rearm, radar, reuse of items, unload) on the real saved games, against     }
{  what the real OpenXcom objects did (simgen craft)                           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later)               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomSave.CraftScenario;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, DUnitX.TestFramework, DelphiDoom.Tests.Xcom.Skip, DelphiDoom.XcomMod.Random,
  DelphiDoom.XcomMod.RuleCraftWeapon, DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomSave.Base,
  DelphiDoom.XcomSave.Craft, DelphiDoom.XcomSave.CraftWeapon, DelphiDoom.XcomSave.Ufo, DelphiDoom.XcomSave.Soldier,
  DelphiDoom.Tests.XcomSave.Sim;

type
  [TestFixture]
  [Category('xcom-save')]
  [Category('xcom-save-sim')]
  TTestXcomCraftScenario = class(TObject)
  strict private
    FSim: TXcomSim;
    FLines: TStringList;
    FRandom: IXcomRandom;
    function Pick(AValue: Integer): Integer;
    function AmmoText(const ACraft: TXcomCraft): string;
    procedure Run(const AGame: TXcomSavedGame; AVariant: Integer);
    procedure RunBase(const AGame: TXcomSavedGame; const ABase: TXcomBase; AVariant, ABaseIndex: Integer);
    procedure Out(const ALine: string);
  public
    [SetupFixture]
    procedure SetupFixture;
    [TearDownFixture]
    procedure TearDownFixture;
    [Test]
    procedure DovrebbeFareLeStesseOperazioniSuiVelivoliDelVeroOpenXcom;
  end;

implementation

const
  STEP: Double = 0.004;

{ TTestXcomCraftScenario }

procedure TTestXcomCraftScenario.SetupFixture;
begin
  FSim := TXcomSim.Create;
end;

procedure TTestXcomCraftScenario.TearDownFixture;
begin
  FSim.Free;
end;

function TTestXcomCraftScenario.Pick(AValue: Integer): Integer;
begin
  if AValue <= 0 then
    Result := 0
  else
    Result := FRandom.Generate(0, AValue - 1);
end;

procedure TTestXcomCraftScenario.Out(const ALine: string);
begin
  FLines.Add(ALine);
end;

function TTestXcomCraftScenario.AmmoText(const ACraft: TXcomCraft): string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 0 to ACraft.Weapons.Count - 1 do
  begin
    if LIndex > 0 then
      Result := Result + ',';
    if Assigned(ACraft.Weapons[LIndex]) then
    begin
      Result := Result + IntToStr(ACraft.Weapons[LIndex].Ammo);
      if ACraft.Weapons[LIndex].Rearming then
        Result := Result + 'r';
    end
    else
      Result := Result + '-';
  end;
end;

procedure TTestXcomCraftScenario.RunBase(const AGame: TXcomSavedGame; const ABase: TXcomBase; AVariant,
  ABaseIndex: Integer);
var
  LCraft: TXcomCraft;
  LIndex, LWeapon, LStep, LStill, LWhich, LUfo, LK: Integer;
  LRearm, LPrefix: string;
  LUfoTarget: TXcomUfo;
  LValue, LOffset: Double;
  LDetected: Boolean;
  LRule: TXcomRuleCraftWeapon;
begin
  for LIndex := 0 to ABase.Crafts.Count - 1 do
    for LWeapon := 0 to ABase.Crafts[LIndex].Weapons.Count - 1 do
      if Assigned(ABase.Crafts[LIndex].Weapons[LWeapon]) then
      begin
        LRule := FSim.Ruleset.CraftWeapons.Find(ABase.Crafts[LIndex].Weapons[LWeapon].Rules.WeaponType);
        ABase.StorageItems.AddItem(LRule.ClipItem, Pick(20));
      end;
  for LIndex := 0 to ABase.Crafts.Count - 1 do
  begin
    LCraft := ABase.Crafts[LIndex];
    LPrefix := Format('|%d|%d|%d|', [AVariant, ABaseIndex, LIndex]);
    Out('craft' + LPrefix + 'soldiers=' + IntToStr(LCraft.NumSoldiers(ABase.Soldiers)));
    for LWeapon := 0 to LCraft.Weapons.Count - 1 do
    begin
      if not Assigned(LCraft.Weapons[LWeapon]) then
        Continue;
      LCraft.Weapons[LWeapon].SetAmmo(Pick(LCraft.Weapons[LWeapon].Rules.AmmoMax + 1));
      LCraft.Weapons[LWeapon].Rearming := True;
    end;
    LCraft.Status := 'STR_REARMING';
    Out('craft' + LPrefix + 'before|' + AmmoText(LCraft) + '|' + TXcomSim.StorageText(ABase.StorageItems));
    for LStep := 0 to 13 do
    begin
      LRearm := LCraft.Rearm(ABase.StorageItems, FSim.Ruleset);
      Out(Format('rearm|%d|%d|%d|%d|%s|%s|%s', [AVariant, ABaseIndex, LIndex, LStep, LRearm, LCraft.Status,
        AmmoText(LCraft)]));
      if LCraft.Status = 'STR_REFUELLING' then
        Break;
    end;
    Out('craft' + LPrefix + 'after|' + TXcomSim.StorageText(ABase.StorageItems));
    LCraft.Status := 'STR_READY';
    for LWeapon := 0 to LCraft.Weapons.Count - 1 do
    begin
      if not Assigned(LCraft.Weapons[LWeapon]) then
        Continue;
      LCraft.Weapons[LWeapon].SetAmmo(Pick(LCraft.Weapons[LWeapon].Rules.AmmoMax));
      LRule := FSim.Ruleset.CraftWeapons.Find(LCraft.Weapons[LWeapon].Rules.WeaponType);
      LCraft.ReuseItem(LRule.ClipItem, FSim.Ruleset);
    end;
    LCraft.ReuseItem(LCraft.Rules.RefuelItem, FSim.Ruleset);
    Out('reuse' + LPrefix + LCraft.Status + '|' + AmmoText(LCraft));
    for LUfo := 0 to AGame.Ufos.Count - 1 do
    begin
      LUfoTarget := AGame.Ufos[LUfo];
      // every step rounded to a double, as the volatile variables of the harness do
      LOffset := (Pick(100) - 50) * STEP;
      LValue := LUfoTarget.Longitude + LOffset;
      LCraft.SetLongitude(LValue);
      LOffset := (Pick(100) - 50) * STEP;
      LValue := LUfoTarget.Latitude + LOffset;
      LCraft.SetLatitude(LValue);
      LDetected := LCraft.Detect(LUfoTarget, LUfoTarget.Visibility, FRandom);
      Out(Format('detect|%d|%d|%d|%d|%d|vis=%d', [AVariant, ABaseIndex, LIndex, LUfo, Ord(LDetected),
        LUfoTarget.Visibility]));
    end;
  end;
  for LWhich := 0 to 1 do
  begin
    if ABase.Crafts.Count = 0 then
      Break;
    if LWhich = 0 then
      LCraft := ABase.Crafts.First
    else
      LCraft := ABase.Crafts.Last;
    if (LWhich = 1) and (LCraft = ABase.Crafts.First) then
      Break;
    LCraft.Unload(ABase.StorageItems, ABase.Soldiers, FSim.Ruleset);
    Out(Format('unload|%d|%d|%d|%s|%s', [AVariant, ABaseIndex, LWhich, TXcomSim.StorageText(ABase.StorageItems),
      AmmoText(LCraft)]));
    LStill := 0;
    for LK := 0 to ABase.Soldiers.Count - 1 do
      if ABase.Soldiers[LK].Craft = LCraft then
        Inc(LStill);
    Out(Format('unload|%d|%d|%d|soldiers=%d|vehicles=%d', [AVariant, ABaseIndex, LWhich, LStill,
      LCraft.Vehicles.Count]));
  end;
end;

procedure TTestXcomCraftScenario.Run(const AGame: TXcomSavedGame; AVariant: Integer);
var
  LBase: Integer;
begin
  for LBase := 0 to AGame.Bases.Count - 1 do
    RunBase(AGame, AGame.Bases[LBase], AVariant, LBase);
end;

procedure TTestXcomCraftScenario.DovrebbeFareLeStesseOperazioniSuiVelivoliDelVeroOpenXcom;
var
  LFolder, LExpected: string;
  LVariant: Integer;
  LGame: TXcomSavedGame;
  LText: string;
begin
  LFolder := TXcomSim.GoldenFolder('XcomSave\sim');
  if not FSim.Available or (LFolder = '') then
  begin
    TXcomTestSkip.Ignore('senza i dati di TFTD o i golden il confronto non si fa');
    Exit;
  end;
  FLines := TStringList.Create;
  try
    for LVariant := 0 to 15 do
    begin
      FLines.Clear;
      FRandom := TXcomRandom.Create(1);
      LGame := FSim.LoadSave(LVariant, FRandom);
      try
        FRandom.SetSeed(5000 + LVariant);
        Run(LGame, LVariant);
        Out(Format('rng|%d|%s', [LVariant, UIntToStr(FRandom.Seed)]));
        LExpected := string(TXcomSim.GoldenText(LFolder + Format('sim%.2d.craft.txt', [LVariant])));
        LText := FLines.Text;
        Assert.AreEqual('', TXcomSim.FirstDifference(LExpected, LText), Format('risposte del salvataggio %d', [LVariant]));
        Assert.AreEqual('', TXcomSim.SaveDifference(TXcomSim.GoldenText(LFolder + Format('sim%.2d.craft.sav',
          [LVariant])), FSim.SaveText(LGame, FRandom)), Format('stato finale del salvataggio %d', [LVariant]));
      finally
        LGame.Free;
      end;
    end;
  finally
    FLines.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomCraftScenario);

end.
