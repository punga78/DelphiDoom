{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - TRadixPilotRules                                }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of the rules of the custom pickups of P_TouchSpecialThing and of the   }
{  P_Give* functions (p_inter.pas of Rad-X) and of the regeneration of         }
{  RX_PlayerThink (radix_player.pas of Rad-X)                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.Pilot.Rules;

interface

uses
  DelphiDoom.Radix.ActorProperties;

{$SCOPEDENUMS ON}

type
  /// <summary>The power ups of the craft, in the order of radixpowers of Rad-X</summary>
  TRadixPowerUp = (RapidShield, RapidEnergy, ManeuverJets, NightVision, Alds);

  /// <summary>What the craft carries: the part of the player that a pickup or the time changes</summary>
  TRadixInventory = record
    /// <summary>The shield (the health of the player of Doom)</summary>
    Shield: Integer;
    Armor: Integer;
    Energy: Integer;
    /// <summary>The energy kept aside while an energy weapon is fired with the rapid energy</summary>
    EnergyReserve: Integer;
    Ammo: array[0..RADIX_AMMO_TYPES - 1] of Integer;
    MaxAmmo: array[0..RADIX_AMMO_TYPES - 1] of Integer;
    WeaponOwned: array[0..RADIX_WEAPONS - 1] of Boolean;
    /// <summary>The weapon to bring up; -1 for none</summary>
    PendingWeapon: Integer;
    /// <summary>The tics left of each power up</summary>
    Powers: array[TRadixPowerUp] of Integer;
    PlasmaBombs: Integer;
    NeutronCannonLevel: Integer;
    NeutronSpreaderLevel: Integer;
  end;

  /// <summary>The numbers of the game that the rules need (GAMEDEF can change them)</summary>
  TRadixPilotLimits = record
    /// <summary>The shield of a new craft: what a pickup or the time gives back at most</summary>
    SpawnShield: Integer;
    SpawnEnergy: Integer;
    MaxEnergy: Integer;
    MaxArmor: Integer;
    MaxPlasmaBombs: Integer;
    ReserveEnergy: Integer;
    class function Default: TRadixPilotLimits; static;
  end;

  /// <summary>Which message a pickup shows</summary>
  TRadixPickupMessage = (
    /// <summary>The one of the pickup</summary>
    Pickup,
    /// <summary>The one of the new level of the neutron cannons</summary>
    NeutronCannons,
    /// <summary>The one of the new level of the plasma spreader</summary>
    NeutronSpreader,
    EnhancedEpc,
    SuperEpc);

  TRadixPickupResult = record
    /// <summary>False: the craft needs nothing of the pickup, which stays where it is</summary>
    Taken: Boolean;
    Message: TRadixPickupMessage;
  end;

  /// <summary>The rules of the craft that do not need the engine</summary>
  TRadixPilotRules = class
  public const
    WEAPON_STANDARD_EPC = 1;
    WEAPON_PLASMA_SPREADER = 2;
    WEAPON_ENHANCED_EPC = 7;
    WEAPON_SUPER_EPC = 8;
    AMMO_TORPEDOES = 2;
    AMMO_NUKES = 3;
    /// <summary>The levels of the neutron cannons and of the spreader are 0..6</summary>
    MAX_NEUTRON_LEVEL = 6;
    /// <summary>The numbers in the editor of the two pickups that raise a level</summary>
    DOOMEDNUM_NEUTRON_CANNONS = 1011;
    DOOMEDNUM_PLASMA_SPREADER = 1013;
    /// <summary>The shield and the energy come back every 32 tics</summary>
    REGENERATION_MASK = 31;
  public
    /// <summary>
    ///   Gives to the craft what a pickup has. Each thing is given only if the craft can take it
    ///   (the armour of a pickup is not below the one it has, the ammo is not full ...); the
    ///   pickup is taken when at least one was
    /// </summary>
    /// <param name="ADoomedNum">The number of the pickup in the editor (two of them raise a level)</param>
    /// <param name="AEpisode">In the first episode torpedoes and nukes are not given, and the EPC stops at the enhanced one</param>
    /// <param name="ADoubleAmmo">The hardest skill gives twice the ammo</param>
    class function Pickup(const AInfo: TRadixActorInfo; ADoomedNum, AEpisode: Integer; ADoubleAmmo: Boolean;
      const ALimits: TRadixPilotLimits; var AInventory: TRadixInventory): TRadixPickupResult; static;
    /// <summary>
    ///   The shield and the energy that come back with the time: call it at every tic of a craft
    ///   that is alive. Nothing happens while the screen is red of a damage (ADamaged) or in
    ///   the sector that kills at the end of an episode
    /// </summary>
    /// <param name="AEnergyWeaponFired">An energy weapon was fired a moment ago</param>
    class procedure Regenerate(ALevelTime: Integer; ADamaged, AEnergyWeaponFired: Boolean;
      const ALimits: TRadixPilotLimits; var AInventory: TRadixInventory); static;
    /// <summary>One tic less for every power up that is on</summary>
    class procedure TickPowers(var AInventory: TRadixInventory); static;
    /// <summary>The craft is under threat: less than a quarter of the shield is left</summary>
    class function Threat(AShield: Integer; const ALimits: TRadixPilotLimits): Boolean; static;
  end;

implementation

uses
  System.Math;

{ TRadixPilotLimits }

class function TRadixPilotLimits.Default: TRadixPilotLimits;
begin
  Result.SpawnShield := 100;
  Result.SpawnEnergy := 100;
  Result.MaxEnergy := 100;
  Result.MaxArmor := 200;
  Result.MaxPlasmaBombs := 99;
  Result.ReserveEnergy := 3;
end;

{ TRadixPilotRules }

class function TRadixPilotRules.Pickup(const AInfo: TRadixActorInfo; ADoomedNum, AEpisode: Integer;
  ADoubleAmmo: Boolean; const ALimits: TRadixPilotLimits; var AInventory: TRadixInventory): TRadixPickupResult;
var
  LGave: Boolean;

  procedure GiveArmor(AAmount: Integer);
  begin
    if (AAmount <= 0) or (AInventory.Armor >= ALimits.MaxArmor) then
      Exit;
    AInventory.Armor := Min(AInventory.Armor + AAmount, ALimits.MaxArmor);
    LGave := True;
  end;

  procedure GiveEnergy(AAmount: Integer);
  begin
    if (AAmount <= 0) or (AInventory.Energy >= ALimits.MaxEnergy) then
      Exit;
    AInventory.Energy := Min(AInventory.Energy + AAmount, ALimits.MaxEnergy);
    LGave := True;
  end;

  procedure GiveShield(AAmount: Integer);
  begin
    if (AAmount <= 0) or (AInventory.Shield >= ALimits.SpawnShield) then
      Exit;
    AInventory.Shield := Min(AInventory.Shield + AAmount, ALimits.SpawnShield);
    LGave := True;
  end;

  procedure GiveAmmo(AType, AAmount: Integer);
  begin
    if AAmount <= 0 then
      Exit;
    if (AEpisode = 1) and ((AType = AMMO_TORPEDOES) or (AType = AMMO_NUKES)) then
      Exit;
    if AInventory.Ammo[AType] >= AInventory.MaxAmmo[AType] then
      Exit;
    if ADoubleAmmo then
      AAmount := AAmount * 2;
    AInventory.Ammo[AType] := Min(AInventory.Ammo[AType] + AAmount, AInventory.MaxAmmo[AType]);
    LGave := True;
  end;

  procedure GivePower(APower: TRadixPowerUp; ATics: Integer);
  begin
    if AInventory.Powers[APower] < ATics then
    begin
      AInventory.Powers[APower] := ATics;
      LGave := True;
    end;
  end;

var
  LIndex: Integer;
  LWeapon: Integer;
  LHadSpreader: Boolean;
begin
  LGave := False;
  Result.Message := TRadixPickupMessage.Pickup;

  GiveArmor(AInfo.ArmorInc);
  GiveEnergy(AInfo.EnergyInc);
  GiveShield(AInfo.ShieldInc);
  // the old code gave "set - what there is" to a function that took an armour class: the
  // armour could become thousands. Here a "set" brings the value up to it
  if AInfo.ArmorSet > AInventory.Armor then
    GiveArmor(AInfo.ArmorSet - AInventory.Armor);
  if AInfo.EnergySet > AInventory.Energy then
    GiveEnergy(AInfo.EnergySet - AInventory.Energy);
  if AInfo.ShieldSet > AInventory.Shield then
    GiveShield(AInfo.ShieldSet - AInventory.Shield);

  for LIndex := 0 to RADIX_AMMO_TYPES - 1 do
    GiveAmmo(LIndex, AInfo.AmmoInc[LIndex]);

  LHadSpreader := AInventory.WeaponOwned[WEAPON_PLASMA_SPREADER];
  for LIndex := 0 to RADIX_WEAPONS - 1 do
    if AInfo.WeaponInc[LIndex] then
    begin
      LWeapon := LIndex;
      // a standard EPC found again is the enhanced one, and after it (not in the first episode)
      // the super one
      if LWeapon = WEAPON_STANDARD_EPC then
      begin
        if AInventory.WeaponOwned[WEAPON_ENHANCED_EPC] and (AEpisode <> 1) then
          LWeapon := WEAPON_SUPER_EPC
        else if AInventory.WeaponOwned[WEAPON_STANDARD_EPC] then
          LWeapon := WEAPON_ENHANCED_EPC;
      end;
      if not AInventory.WeaponOwned[LWeapon] then
      begin
        AInventory.WeaponOwned[LWeapon] := True;
        AInventory.PendingWeapon := LWeapon;
        LGave := True;
        if LWeapon = WEAPON_SUPER_EPC then
          Result.Message := TRadixPickupMessage.SuperEpc
        else if LWeapon = WEAPON_ENHANCED_EPC then
          Result.Message := TRadixPickupMessage.EnhancedEpc;
      end;
    end;

  GivePower(TRadixPowerUp.RapidShield, AInfo.RapidShield);
  GivePower(TRadixPowerUp.RapidEnergy, AInfo.RapidEnergy);
  GivePower(TRadixPowerUp.ManeuverJets, AInfo.ManeuverJets);
  GivePower(TRadixPowerUp.NightVision, AInfo.NightVision);
  GivePower(TRadixPowerUp.Alds, AInfo.Alds);

  if (AInfo.PlasmaBomb > 0) and (AInventory.PlasmaBombs < ALimits.MaxPlasmaBombs) then
  begin
    AInventory.PlasmaBombs := Min(AInventory.PlasmaBombs + AInfo.PlasmaBomb, ALimits.MaxPlasmaBombs);
    LGave := True;
  end;

  // the level messages win over the one of the pickup and over the one of the EPC
  if (ADoomedNum = DOOMEDNUM_PLASMA_SPREADER) and LHadSpreader and
    (AInventory.NeutronSpreaderLevel < MAX_NEUTRON_LEVEL) then
  begin
    Inc(AInventory.NeutronSpreaderLevel);
    LGave := True;
    Result.Message := TRadixPickupMessage.NeutronSpreader;
  end;
  if (ADoomedNum = DOOMEDNUM_NEUTRON_CANNONS) and (AInventory.NeutronCannonLevel < MAX_NEUTRON_LEVEL) then
  begin
    Inc(AInventory.NeutronCannonLevel);
    LGave := True;
    Result.Message := TRadixPickupMessage.NeutronCannons;
  end;

  Result.Taken := LGave;
end;

class procedure TRadixPilotRules.Regenerate(ALevelTime: Integer; ADamaged, AEnergyWeaponFired: Boolean;
  const ALimits: TRadixPilotLimits; var AInventory: TRadixInventory);
var
  LShield: Integer;
  LEnergy: Integer;
begin
  if (ALevelTime and REGENERATION_MASK <> 0) or ADamaged then
    Exit;

  if AInventory.Powers[TRadixPowerUp.RapidShield] > 0 then
    LShield := AInventory.Shield + 2
  else
    LShield := AInventory.Shield + 1;
  if LShield <= ALimits.SpawnShield then
    AInventory.Shield := LShield;

  LEnergy := AInventory.Energy;
  if not AEnergyWeaponFired then
  begin
    if AInventory.Powers[TRadixPowerUp.RapidEnergy] > 0 then
      LEnergy := AInventory.Energy + 2
    else
      LEnergy := AInventory.Energy + 1;
  end
  else if AInventory.Powers[TRadixPowerUp.RapidEnergy] > 0 then
  begin
    // while an energy weapon fires only the rapid energy gives something: to the reserve
    if AInventory.EnergyReserve < ALimits.ReserveEnergy then
      Inc(AInventory.EnergyReserve);
  end;
  if LEnergy <= ALimits.SpawnEnergy then
    AInventory.Energy := LEnergy;
end;

class procedure TRadixPilotRules.TickPowers(var AInventory: TRadixInventory);
var
  LPower: TRadixPowerUp;
begin
  for LPower := Low(TRadixPowerUp) to High(TRadixPowerUp) do
    if AInventory.Powers[LPower] > 0 then
      Dec(AInventory.Powers[LPower]);
end;

class function TRadixPilotRules.Threat(AShield: Integer; const ALimits: TRadixPilotLimits): Boolean;
begin
  Result := AShield < ALimits.SpawnShield div 4;
end;

end.
