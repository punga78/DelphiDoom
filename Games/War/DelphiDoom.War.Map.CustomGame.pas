{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the setup of a custom game                         }
{                                                                              }
{  Port of war1 (acoto87/war1), war_map.c (wmap_createCustomMap and its          }
{  helpers) and war_launch.h (WarCustomGameOptions), (c) 2019 Alejandro Coto     }
{  Gutierrez, zlib License (see Games\War\LICENSE-war1.txt). This is an altered  }
{  version, not the original.                                                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Map.CustomGame;

{$R-}
{$Q-}

interface

uses
  System.SysUtils, DelphiDoom.War.Level.Types, DelphiDoom.War.Level.Intf, DelphiDoom.War.Map.Intf,
  DelphiDoom.War.Sound.Intf;

type
  /// <summary>
  ///   WarCustomGameOptions: what the player asks of a custom game. A race that is neutral is drawn. The gold and the
  ///   lumber replace those of the level for the two players. The seed (the command line of the original) is not ported
  /// </summary>
  TWarCustomGameOptions = record
    Enabled: Boolean;
    PlayerRace: TWarRace;
    EnemyRace: TWarRace;
    HasGold: Boolean;
    Gold: Integer;
    HasWood: Boolean;
    Wood: Integer;
    HasSeed: Boolean;
    Seed: UInt64;
    StartConfigurationIndex: Integer;
  end;

  /// <summary>
  ///   What wmap_createCustomMap leaves on the level and on the map: the options with the races and the position that were
  ///   drawn, the level info with the units the two players start with (the gold mines first, then the units of the
  ///   position, with the types of their races), and where the camera starts
  /// </summary>
  TWarCustomGame = record
    Options: TWarCustomGameOptions;
    Info: TWarLevelInfo;
    HasCameraStart: Boolean;
    CameraCenterX: Integer;
    CameraCenterY: Integer;
  end;

  /// <summary>
  ///   wmap_createCustomMap: the draws of the generator of the game, in the order of the original (the race of the player and
  ///   the one of the enemy if they are not chosen, the gold of every mine, the position of the start), and the units of the
  ///   level that follow. The level is not changed (the original changed the record of the archive: the same game started
  ///   again found it as it was left, and here the setup is kept by whoever starts it again)
  /// </summary>
  TWarCustomGameMaker = class sealed
  public
    /// <summary>
    ///   EWarException if the level is not a custom map or has no position (the original stops on an assert), or if the
    ///   options have a seed
    /// </summary>
    class function Make(const ALevel: IWarLevel; const AOptions: TWarCustomGameOptions; const AUnits: IWarUnitCatalog;
      const ARandom: IWarRandom): TWarCustomGame; static;
  end;

implementation

uses
  DelphiDoom.War.Types, DelphiDoom.War.Model.Types, DelphiDoom.War.Model.UnitClassifier, DelphiDoom.War.Map.Types;

resourcestring
  SWarCustomNotCustom = 'The level %d is not a custom map: it cannot start a custom game';
  SWarCustomNoPositions = 'The custom map %d has no position for the players';
  SWarCustomSeed = 'A custom game with a seed is not ported: it needs the generator of SDL, which is not the one of the game';
  SWarCustomNoUnit = 'The unit type %d of a start position is not in the tables';

{ TWarCustomGameMaker }

class function TWarCustomGameMaker.Make(const ALevel: IWarLevel; const AOptions: TWarCustomGameOptions;
  const AUnits: IWarUnitCatalog; const ARandom: IWarRandom): TWarCustomGame;
var
  LInfo: TWarLevelInfo;
  LEntities: TArray<TWarLevelUnit>;
  LMine: TWarLevelUnit;
  LSource: TWarLevelUnit;
  LUnit: TWarLevelUnit;
  LData: TWarUnitData;
  LPlayerRace: TWarRace;
  LEnemyRace: TWarRace;
  LTownHall: Integer;
  LIndex: Integer;
  LFound: Boolean;
begin
  LInfo := ALevel.Info;
  if AOptions.HasSeed then
    raise EWarException.Create(SWarCustomSeed);
  if not LInfo.CustomMap then
    raise EWarException.CreateFmt(SWarCustomNotCustom, [LInfo.Index]);
  if Length(LInfo.StartConfigurations) = 0 then
    raise EWarException.CreateFmt(SWarCustomNoPositions, [LInfo.Index]);
  Result := Default(TWarCustomGame);
  Result.Options := AOptions;
  Result.Options.Enabled := True;
  // resolveCustomGameRace: the player first, then the enemy; a neutral race is a draw of two
  LPlayerRace := AOptions.PlayerRace;
  if LPlayerRace = wraNeutral then
  begin
    if ARandom.Below(2) = 0 then
      LPlayerRace := wraHumans
    else
      LPlayerRace := wraOrcs;
  end;
  LEnemyRace := AOptions.EnemyRace;
  if LEnemyRace = wraNeutral then
  begin
    if ARandom.Below(2) = 0 then
      LEnemyRace := wraHumans
    else
      LEnemyRace := wraOrcs;
  end;
  Result.Options.PlayerRace := LPlayerRace;
  Result.Options.EnemyRace := LEnemyRace;
  LInfo.Races[0] := LPlayerRace;
  LInfo.Races[1] := LEnemyRace;
  if AOptions.HasGold then
  begin
    LInfo.Gold[0] := Cardinal(AOptions.Gold);
    LInfo.Gold[1] := Cardinal(AOptions.Gold);
  end;
  if AOptions.HasWood then
  begin
    LInfo.Lumber[0] := Cardinal(AOptions.Wood);
    LInfo.Lumber[1] := Cardinal(AOptions.Wood);
  end;
  // the gold mines of the map, each with its gold (20000 to 29999) drawn in order
  LEntities := nil;
  for LMine in LInfo.StartGoldmines do
  begin
    LUnit := Default(TWarLevelUnit);
    LUnit.X := LMine.X;
    LUnit.Y := LMine.Y;
    LUnit.UnitType := LMine.UnitType;
    LUnit.Player := LMine.Player;
    LUnit.ResourceKind := wrkGold;
    LUnit.Amount := Word(20000 + ARandom.Below(10000));
    LEntities := LEntities + [LUnit];
  end;
  // the position of the start: one of the configurations
  Result.Options.StartConfigurationIndex := ARandom.Below(Length(LInfo.StartConfigurations));
  LTownHall := TWarUnitClassifier.TypeForRace(WAR_UNIT_TOWNHALL_HUMANS, LPlayerRace);
  LFound := False;
  for LIndex := 0 to High(LInfo.StartConfigurations[Result.Options.StartConfigurationIndex].StartEntities) do
  begin
    LSource := LInfo.StartConfigurations[Result.Options.StartConfigurationIndex].StartEntities[LIndex];
    LUnit := Default(TWarLevelUnit);
    LUnit.X := LSource.X;
    LUnit.Y := LSource.Y;
    LUnit.Player := LSource.Player;
    if LSource.Player = 0 then
      LUnit.UnitType := Byte(TWarUnitClassifier.TypeForRace(LSource.UnitType, LPlayerRace))
    else
      LUnit.UnitType := Byte(TWarUnitClassifier.TypeForRace(LSource.UnitType, LEnemyRace));
    // the camera starts on the first unit of the player, or on its town hall if there is one
    if (LUnit.Player = 0) and ((not LFound) or (LUnit.UnitType = LTownHall)) then
    begin
      if not AUnits.TryGetData(LUnit.UnitType, LData) then
        raise EWarException.CreateFmt(SWarCustomNoUnit, [LUnit.UnitType]);
      Result.CameraCenterX := LUnit.X * WAR_MEGA_TILE_SIZE + LData.SizeX * WAR_MEGA_TILE_SIZE div 2;
      Result.CameraCenterY := LUnit.Y * WAR_MEGA_TILE_SIZE + LData.SizeY * WAR_MEGA_TILE_SIZE div 2;
      LFound := True;
    end;
    LEntities := LEntities + [LUnit];
  end;
  Result.HasCameraStart := LFound;
  LInfo.StartEntities := LEntities;
  Result.Info := LInfo;
end;

end.
