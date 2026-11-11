{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the xcom strategy library - the dogfight          }
{  (DogfightState: update, weapons, fire of the UFO, the end, the retaliation)  }
{  on the real saved games, against what the code of DogfightState did on the   }
{  real OpenXcom objects (simgen dogfight)                                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later)               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomStrategy.Dogfight;

interface

uses
  System.SysUtils, System.Classes, System.Math, System.Generics.Collections, DUnitX.TestFramework,
  DelphiDoom.XcomMod.Random, DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomMod.RuleAlienMission, DelphiDoom.XcomSave.SavedGame,
  DelphiDoom.XcomSave.AlienMission, DelphiDoom.XcomSave.Base, DelphiDoom.XcomSave.Craft, DelphiDoom.XcomSave.CraftWeapon,
  DelphiDoom.XcomSave.CraftWeaponProjectile, DelphiDoom.XcomSave.Ufo, DelphiDoom.XcomStrategy.LandMap.Intf,
  DelphiDoom.XcomStrategy.Dogfight.Listener.Intf, DelphiDoom.XcomStrategy.DogfightEngine, DelphiDoom.Tests.XcomSave.Sim;

type
  /// <summary>Records what the window would show, as the lines that the harness writes (ev|...)</summary>
  TDogfightRecorder = class(TInterfacedObject, IXcomDogfightListener, IXcomLandMap)
  strict private
    FLines: TStringList;
  public
    constructor Create(const ALines: TStringList);
    procedure StatusChanged(const AKey: string);
    procedure SoundPlayed(ASound: TXcomDogfightSound; AWeaponSound: Integer);
    procedure CraftDamaged;
    procedure AmmoChanged(AWeapon, AAmmo: Integer);
    procedure CannotEngage(const AReason: string);
    function InsideLand(ALongitude, ALatitude: Double): Boolean;
  end;

  [TestFixture]
  [Category('xcom-strategy')]
  [Category('xcom-strategy-sim')]
  TTestXcomDogfightScenario = class(TObject)
  strict private
    FSim: TXcomSim;
    FLines: TStringList;
    FRandom: IXcomRandom;
    FRecorder: IXcomDogfightListener;
    FLand: IXcomLandMap;
    function Pick(AValue: Integer): Integer;
    function AmmoText(const ACraft: TXcomCraft): string;
    function ProjectileText(const AEngine: TXcomDogfightEngine): string;
    procedure Run(const AGame: TXcomSavedGame; AVariant: Integer);
    procedure PlayDogfight(const AGame: TXcomSavedGame; const ABase: TXcomBase; const ACraft: TXcomCraft;
      AVariant, ABaseIndex, ACraftIndex, ARepetition: Integer);
  public
    [SetupFixture]
    procedure SetupFixture;
    [TearDownFixture]
    procedure TearDownFixture;
    [Test]
    procedure DovrebbeFareGliStessiCombattimentiDelVeroOpenXcom;
  end;

implementation

{ TDogfightRecorder }

constructor TDogfightRecorder.Create(const ALines: TStringList);
begin
  inherited Create;
  FLines := ALines;
end;

procedure TDogfightRecorder.StatusChanged(const AKey: string);
begin
  FLines.Add('ev|status|' + AKey);
end;

procedure TDogfightRecorder.SoundPlayed(ASound: TXcomDogfightSound; AWeaponSound: Integer);
begin
  case ASound of
    dsUfoFire: FLines.Add('ev|sound|ufofire');
    dsUfoHit: FLines.Add('ev|sound|ufohit');
    dsUfoCrash: FLines.Add('ev|sound|ufocrash');
    dsUfoExplode: FLines.Add('ev|sound|ufoexplode');
    dsInterceptorHit: FLines.Add('ev|sound|interceptorhit');
    dsInterceptorExplode: FLines.Add('ev|sound|interceptorexplode');
    dsWeapon: FLines.Add('ev|sound|weapon|' + IntToStr(AWeaponSound));
  end;
end;

procedure TDogfightRecorder.CraftDamaged;
begin
  FLines.Add('ev|craftdamage');
end;

procedure TDogfightRecorder.AmmoChanged(AWeapon, AAmmo: Integer);
begin
  // the text of the ammunition: the harness has it in the line of the step
end;

procedure TDogfightRecorder.CannotEngage(const AReason: string);
begin
  FLines.Add('ev|cannotengage|' + AReason);
end;

function TDogfightRecorder.InsideLand(ALongitude, ALatitude: Double): Boolean;
var
  LFirst, LSecond: Double;
begin
  // the fixed function of the harness (DogLand)
  LFirst := ALongitude * 1000.0;
  LSecond := ALatitude * 1000.0;
  Result := ((Floor(LFirst) + Floor(LSecond)) and 1) <> 0;
end;

{ TTestXcomDogfightScenario }

procedure TTestXcomDogfightScenario.SetupFixture;
begin
  FSim := TXcomSim.Create;
end;

procedure TTestXcomDogfightScenario.TearDownFixture;
begin
  FSim.Free;
end;

function TTestXcomDogfightScenario.Pick(AValue: Integer): Integer;
begin
  if AValue <= 0 then
    Result := 0
  else
    Result := FRandom.Generate(0, AValue - 1);
end;

function TTestXcomDogfightScenario.AmmoText(const ACraft: TXcomCraft): string;
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

function TTestXcomDogfightScenario.ProjectileText(const AEngine: TXcomDogfightEngine): string;
var
  LIndex: Integer;
  LProjectile: TXcomCraftWeaponProjectile;
begin
  Result := '';
  for LIndex := 0 to AEngine.Projectiles.Count - 1 do
  begin
    LProjectile := AEngine.Projectiles[LIndex];
    if LIndex > 0 then
      Result := Result + ';';
    Result := Result + Format('%d:%d:%d:%d:%d', [Ord(LProjectile.ProjectileType), LProjectile.Position,
      LProjectile.Direction, LProjectile.State, Ord(LProjectile.Missed)]);
  end;
end;

procedure TTestXcomDogfightScenario.PlayDogfight(const AGame: TXcomSavedGame; const ABase: TXcomBase;
  const ACraft: TXcomCraft; AVariant, ABaseIndex, ACraftIndex, ARepetition: Integer);
const
  POSITION_OFFSET: Double = 0.1;
  POSITION_STEP: Double = 0.001;
var
  LIndex, LStep, LMax: Integer;
  LRuleset: TXcomRuleset;
  LRule: TXcomRuleAlienMission;
  LMission: TXcomAlienMission;
  LUfo: TXcomUfo;
  LEngine: TXcomDogfightEngine;
  LLongitude, LLatitude: Double;
  LBefore, LMissions: Integer;
  LMode: Integer;
  LNew: TXcomAlienMission;
  LUfoMax: Integer;
  LRegionName: string;
begin
  LRuleset := FSim.Ruleset;
  for LIndex := 0 to ACraft.Weapons.Count - 1 do
    if Assigned(ACraft.Weapons[LIndex]) then
      ACraft.Weapons[LIndex].SetAmmo(1 + Pick(LRuleset.CraftWeapons.Find(
        ACraft.Weapons[LIndex].Rules.WeaponType).AmmoMax));
  if Pick(3) = 0 then
    ACraft.SetDamage(Pick(ACraft.Rules.MaxDamage div 2))
  else
    ACraft.SetDamage(0);
  LRule := LRuleset.AlienMissions.Find(LRuleset.AlienMissions.Index[Pick(Length(LRuleset.AlienMissions.Index))]);
  LMission := TXcomAlienMission.Create(LRule);
  LMission.SetId(AGame.GetId('ALIEN_MISSIONS'));
  LRegionName := LRuleset.Regions.Index[Pick(Length(LRuleset.Regions.Index))];
  LMission.SetRegion(LRegionName, LRuleset.Regions.Find(LRegionName));
  LMission.Race := LRuleset.AlienRaces.Index[Pick(Length(LRuleset.AlienRaces.Index))];
  AGame.ActiveMissions.Add(LMission);
  LUfo := TXcomUfo.Create(LRuleset.Ufos.Find(LRuleset.Ufos.Index[Pick(Length(LRuleset.Ufos.Index))]));
  LUfo.Id := AGame.GetId('STR_UFO');
  LUfo.SetMissionInfo(LMission, LRuleset.UfoTrajectories.Find(LRule.Waves[0].Trajectory));
  LLongitude := ABase.Longitude + POSITION_OFFSET + Pick(100) * POSITION_STEP;
  LLatitude := ABase.Latitude + Pick(100) * POSITION_STEP;
  LUfo.SetLongitude(LLongitude);
  LUfo.SetLatitude(LLatitude);
  ACraft.SetLongitude(LLongitude);
  ACraft.SetLatitude(LLatitude);
  if Pick(2) = 0 then
    LUfo.SetAltitude('STR_VERY_LOW')
  else
    LUfo.SetAltitude('STR_HIGH_UC');
  LUfo.Detected := True;
  LUfoMax := LUfo.Rules.MaxDamage;
  if Pick(2) = 0 then
    LUfo.SetDamage(Max(0, LUfoMax div 2 - Pick(40)))
  else if Pick(3) = 0 then
    LUfo.SetDamage(Pick(LUfoMax div 2))
  else
    LUfo.SetDamage(0);
  LMax := ACraft.Rules.MaxSpeed;
  if Pick(4) = 0 then
    LUfo.SetSpeed(LMax + 100)
  else
    LUfo.SetSpeed(LMax div 2 + Pick(LMax div 2));
  AGame.Ufos.Add(LUfo);
  ACraft.Status := 'STR_OUT';
  ACraft.SetDestination(LUfo);
  LEngine := TXcomDogfightEngine.Create(AGame, LRuleset, FRandom, FLand, FRecorder, ACraft, LUfo);
  try
    // the geoscape gives the first free slot
    LEngine.SetInterceptionNumber(1);
    FLines.Add(Format('dog|%d|%d|%d|%d|ufo=%s|size=%d|esc=%d|w=%d,%d|ammo=%s|cdmg=%d|udmg=%d|uspeed=%d|cspeed=%d',
      [AVariant, ABaseIndex, ACraftIndex, ARepetition, LUfo.Rules.UfoType, LEngine.UfoSize, LUfo.EscapeCountdown,
      LEngine.WeaponInterval(0), LEngine.WeaponInterval(1), AmmoText(ACraft), ACraft.Damage, LUfo.Damage, LUfo.Speed,
      ACraft.Rules.MaxSpeed]));
    LStep := 0;
    while (not LEngine.Ended) and (LStep < 900) do
    begin
      if (LStep mod 40 = 0) and (Pick(3) <> 0) then
      begin
        if Pick(6) = 0 then
          LMode := 4
        else
          LMode := 1 + Pick(3);
        LEngine.PressMode(TXcomDogfightMode(LMode));
      end;
      if (LStep mod 97 = 0) and (Pick(4) = 0) then
        LEngine.ToggleWeapon(0);
      LUfo.InterceptionProcessed := False;
      LBefore := FLines.Count;
      LMissions := AGame.ActiveMissions.Count;
      LEngine.Think;
      if AGame.ActiveMissions.Count > LMissions then
      begin
        LNew := AGame.ActiveMissions.Last;
        FLines.Add(Format('ev|retaliation|%s|%s', [LNew.Region, LNew.Rule.MissionType]));
      end;
      if (FLines.Count <> LBefore) or (LStep mod 10 = 0) or LEngine.Ended then
        FLines.Add(Format('df|%d|%d|%d|%d|%d|dist=%d|tgt=%d|mode=%d|udmg=%d|ust=%d|usp=%d|hit=%d|fire=%d|esc=%d|shoot=%d|' +
          'cdmg=%d|ammo=%s|cd=%d,%d|proj=%s|to=%d|end=%d|ended=%d|size=%d|alt=%s|dest=%d|indf=%d',
          [AVariant, ABaseIndex, ACraftIndex, ARepetition, LStep, LEngine.CurrentDistance, LEngine.TargetDistance,
          Ord(LEngine.Mode), LUfo.Damage, LUfo.Status, LUfo.Speed, LUfo.HitFrame, LUfo.FireCountdown,
          LUfo.EscapeCountdown, LUfo.ShootingAt, ACraft.Damage, AmmoText(ACraft), LEngine.WeaponCountdown(0),
          LEngine.WeaponCountdown(1), ProjectileText(LEngine), LEngine.Timeout, Ord(LEngine.Finishing),
          Ord(LEngine.Ended), LEngine.UfoSize, LUfo.Altitude, Ord(ACraft.Destination <> nil), Ord(ACraft.InDogfight)]));
      Inc(LStep);
    end;
  finally
    LEngine.Free;
  end;
  if LUfo.Status = TXcomUfo.STATUS_DESTROYED then
  begin
    ACraft.SetDestination(nil);
    AGame.Ufos.Remove(LUfo);
  end
  else
  begin
    ACraft.SetDestination(nil);
    LUfo.SetDestination(nil);
  end;
  ACraft.Status := 'STR_READY';
  FLines.Add(Format('dogend|%d|%d|%d|%d|steps=%d|rng=%s', [AVariant, ABaseIndex, ACraftIndex, ARepetition, LStep,
    UIntToStr(FRandom.Seed)]));
end;

procedure TTestXcomDogfightScenario.Run(const AGame: TXcomSavedGame; AVariant: Integer);
var
  LBaseIndex, LCraftIndex, LRepetition, LCount, LIndex: Integer;
  LBase: TXcomBase;
  LCraft: TXcomCraft;
  LAny: Boolean;
begin
  LCount := 0;
  for LBaseIndex := 0 to AGame.Bases.Count - 1 do
  begin
    LBase := AGame.Bases[LBaseIndex];
    LCraftIndex := 0;
    while (LCraftIndex < LBase.Crafts.Count) and (LCount < 5) do
    begin
      LCraft := LBase.Crafts[LCraftIndex];
      LAny := False;
      for LIndex := 0 to LCraft.Weapons.Count - 1 do
        if Assigned(LCraft.Weapons[LIndex]) then
          LAny := True;
      if (LCraft.Rules.Weapons > 0) and LAny then
        for LRepetition := 0 to 3 do
        begin
          PlayDogfight(AGame, LBase, LCraft, AVariant, LBaseIndex, LCraftIndex, LRepetition);
          Inc(LCount);
        end;
      Inc(LCraftIndex);
    end;
  end;
end;

procedure TTestXcomDogfightScenario.DovrebbeFareGliStessiCombattimentiDelVeroOpenXcom;
var
  LFolder: string;
  LVariant: Integer;
  LGame: TXcomSavedGame;
begin
  LFolder := TXcomSim.GoldenFolder('XcomSave\sim');
  if not FSim.Available or (LFolder = '') then
  begin
    Assert.Pass('senza i dati di TFTD o i golden il confronto non si fa');
    Exit;
  end;
  FLines := TStringList.Create;
  try
    for LVariant := 0 to 15 do
    begin
      FLines.Clear;
      FRandom := TXcomRandom.Create(1);
      LGame := FSim.LoadSave(LVariant, FRandom);
      FRecorder := TDogfightRecorder.Create(FLines);
      Supports(FRecorder, IXcomLandMap, FLand);
      try
        FRandom.SetSeed(5000 + LVariant);
        try
          Run(LGame, LVariant);
        except
          on E: Exception do
            raise Exception.CreateFmt('%s (variant %d, after: %s)', [E.Message, LVariant, FLines[FLines.Count - 1]]);
        end;
        FLines.Add(Format('rng|%d|%s', [LVariant, UIntToStr(FRandom.Seed)]));
        Assert.AreEqual('', TXcomSim.FirstDifference(string(TXcomSim.GoldenText(LFolder +
          Format('sim%.2d.dogfight.txt', [LVariant]))), FLines.Text), Format('risposte del salvataggio %d', [LVariant]));
        Assert.AreEqual('', TXcomSim.CompareSaveTolerant(LFolder + Format('sim%.2d.dogfight.sav', [LVariant]),
          FSim.SaveText(LGame, FRandom), 1E-9), Format('stato finale del salvataggio %d', [LVariant]));
      finally
        LGame.Free;
        FLand := nil;
        FRecorder := nil;
      end;
    end;
  finally
    FLines.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomDogfightScenario);

end.
