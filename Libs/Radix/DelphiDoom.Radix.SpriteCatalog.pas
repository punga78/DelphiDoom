{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - TRadixSpriteCatalog                             }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  The calls to MakeNonRotatingSprite, MakeRotatingSprite8/16 and MakeOneSprite  }
{  of GenerateSprites (radix_xlat_wad.pas), in the same order. The translation }
{  table argument is gone: every call passed nil                               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.SpriteCatalog;

interface

uses
  DelphiDoom.Radix.SpriteList;

type
  /// <summary>The sprites of Radix: which bitmap of ObjectBitmaps is which sprite of the WAD</summary>
  TRadixSpriteCatalog = class
  public
    /// <summary>Adds the sprites in the order of the old translator</summary>
    class procedure Fill(const AList: TRadixSpriteList); static;
  end;

implementation

uses
  DelphiDoom.Radix.Things;

{ TRadixSpriteCatalog }

class procedure TRadixSpriteCatalog.Fill(const AList: TRadixSpriteList);
var
  LFrame: Char;
begin

    // MT_FULLARMOR
    AList.AddNonRotating('FullArmour', MTRX_FULLARMOR, 3);

    // MT_FULLSHIED
    AList.AddNonRotating('FullShield', MTRX_FULLSHIED, 3);

    // MT_FULLENERGY
    AList.AddNonRotating('FullEnergy', MTRX_FULLENERGY, 3);

    // MT_SUPERCHARGE
    AList.AddNonRotating('SuperCharge', MTRX_SUPERCHARGE, 3);

    // MT_RAPIDSHIELD
    AList.AddNonRotating('RapidShld.Recharger', MTRX_RAPIDSHIELD, 3);

    // MT_RAPIDENERGY
    AList.AddNonRotating('RapidEngy.Energizer', MTRX_RAPIDENERGY, 3);

    // MT_MANEUVERJETS
    AList.AddNonRotating('ManeuveringJets', MTRX_MANEUVERJETS, 3);

    // MT_NIGHTVISION
    AList.AddNonRotating('NightVisionSys', MTRX_NIGHTVISION, 3);

    // MT_PLASMABOMB
    AList.AddNonRotating('PlasmaBomb', MTRX_PLASMABOMB, 3);

    // MT_ALDS
    AList.AddNonRotating('A.L.D.S', MTRX_ALDS, 3);

    // MT_ULTRASHIELDS
    AList.AddNonRotating('GodMode', MTRX_ULTRASHIELDS, 3);

    // MT_LEVEL2NEUTRONCANNONS
    AList.AddNonRotating('LaserCannons', MTRX_LEVEL2NEUTRONCANNONS, 3);

    // MT_STANDARDEPC
    AList.AddNonRotating('ExplosiveCannon', MTRX_STANDARDEPC, 3);

    // MT_LEVEL1PLASMASPREADER
    AList.AddNonRotating('PlasmaCannon', MTRX_LEVEL1PLASMASPREADER, 3);

    // MT_NUCLEARCAPABILITY
    AList.AddNonRotating('NuclearWeaponSystem', MTRX_NUCLEARCAPABILITY, 3);

    // MT_MISSILECAPABILITY
    AList.AddNonRotating('SeekingMissileSystem', MTRX_MISSILECAPABILITY, 3);

    // MT_TORPEDOCAPABILITY
    AList.AddNonRotating('PhaseTorpedoSystem', MTRX_TORPEDOCAPABILITY, 3);

    // MT_GRAVITYDEVICE
    AList.AddNonRotating('GravityWaveDevice', MTRX_GRAVITYDEVICE, 3);

    // MT_250SHELLS
    AList.AddNonRotating('250ShellPack', MTRX_250SHELLS, 3);

    // MT_500SHELLS
    AList.AddNonRotating('500ShellPack', MTRX_500SHELLS, 3);

    // MT_1000SHELLS
    AList.AddNonRotating('1000ShellPack', MTRX_1000SHELLS, 3);

    // MT_4NUKES
    AList.AddNonRotating('5Nukes', MTRX_4NUKES, 3);

    // MT_10NUKES
    AList.AddNonRotating('25Nukes', MTRX_10NUKES, 3);

    // MT_15TORPEDOES
    AList.AddNonRotating('10Torps', MTRX_15TORPEDOES, 3);

    // MT_75TORPEDOES
    AList.AddNonRotating('50Torps', MTRX_75TORPEDOES, 3);

    // MT_20MISSILES
    AList.AddNonRotating('20Missiles', MTRX_20MISSILES, 3);

    // MT_50MISSILES
    AList.AddNonRotating('50Missiles', MTRX_50MISSILES, 3);

    // MT_BOOMPACK
    AList.AddNonRotating('BoomPack', MTRX_BOOMPACK, 3);

    // MT_BIOMINE1
    AList.AddNonRotating('WeakBiomine', MTRX_BIOMINE1, 3);
    AList.AddOne('WeakBio-MineFall', MTRX_BIOMINE1, 31, 37, False, False, 'D');
    AList.AddOne('WeakBio-MineDead1', MTRX_BIOMINE1, 8, 9, False, False, 'E');
    AList.AddOne('WeakBio-MineDead2', MTRX_BIOMINE1, 18, 20, False, False, 'F');
    AList.AddOne('WeakBio-MineDead3', MTRX_BIOMINE1, 14, 22, False, False, 'G');
    AList.AddOne('WeakBioChunk1', MTRX_BIOMINE1, 29, 46, False, False, 'H');
    AList.AddOne('WeakBioChunk2', MTRX_BIOMINE1, 41, 46, False, False, 'I');
    AList.AddOne('WeakBioChunk3', MTRX_BIOMINE1, 50, 38, False, False, 'J');
    AList.AddOne('WeakBioChunk4', MTRX_BIOMINE1, 49, 25, False, False, 'K');
    AList.AddOne('WeakBioChunk5', MTRX_BIOMINE1, 39, 18, False, False, 'L');
    AList.AddOne('WeakBioChunk6', MTRX_BIOMINE1, 25, 17, False, False, 'M');
    AList.AddOne('WeakBioChunk7', MTRX_BIOMINE1, 18, 26, False, False, 'N');
    AList.AddOne('WeakBioChunk8', MTRX_BIOMINE1, 20, 34, False, False, 'O');

    // MT_BIOMINE2
    AList.AddNonRotating('PowerBiomine', MTRX_BIOMINE2, 3);
    AList.AddOne('BlackBioBottom', MTRX_BIOMINE2, 32, 32, False, False, 'D');
    AList.AddOne('BlackBioChunk', MTRX_BIOMINE2, 7, 14, False, False, 'E');
    AList.AddOne('BlackBioTop', MTRX_BIOMINE2, 31, 22, False, False, 'F');

    // MT_ALIENFODDER
    AList.AddRotating8('AlienFodder', MTRX_ALIENFODDER, 3, 68, 101, False, False);
    AList.AddOne('FodderFire1', MTRX_ALIENFODDER, 68, 101, False, False, 'D', '1');
    AList.AddOne('FodderFire2', MTRX_ALIENFODDER, 68, 101, False, False, 'D', '2');
    AList.AddOne('FodderFire3', MTRX_ALIENFODDER, 75, 101, False, False, 'D', '3');
    AList.AddOne('FodderFire4', MTRX_ALIENFODDER, 75, 101, False, False, 'D', '4');
    AList.AddOne('FodderFire5', MTRX_ALIENFODDER, 75, 101, False, False, 'D', '5');
    AList.AddOne('FodderFire6', MTRX_ALIENFODDER, 75, 101, False, False, 'D', '6');
    AList.AddOne('FodderFire7', MTRX_ALIENFODDER, 75, 101, False, False, 'D', '7');
    AList.AddOne('FodderFire8', MTRX_ALIENFODDER, 75, 101, False, False, 'D', '8');
    AList.AddOne('FodderBust1', MTRX_ALIENFODDER, 71, 102, False, False, 'E');
    AList.AddOne('FodderBust2', MTRX_ALIENFODDER, 71, 102, False, False, 'F');
    AList.AddOne('FodderBust3', MTRX_ALIENFODDER, 71, 108, False, False, 'G');
    AList.AddOne('FodderBust4', MTRX_ALIENFODDER, 86, 123, False, False, 'H');
    AList.AddOne('FodderBust5', MTRX_ALIENFODDER, 71, 108, False, False, 'I');
    AList.AddOne('FodderDEAD', MTRX_ALIENFODDER, 71, 108, False, False, 'J');
    AList.AddOne('FodderHead1', MTRX_ALIENFODDER, 51, 58, False, False, 'K');
    AList.AddOne('FodderHead2', MTRX_ALIENFODDER, 46, 68, False, False, 'L');
    AList.AddOne('FodderHead3', MTRX_ALIENFODDER, 53, 93, False, False, 'M');
    AList.AddOne('FodderHead4', MTRX_ALIENFODDER, 68, 85, False, False, 'N');
    AList.AddOne('FodderHead5', MTRX_ALIENFODDER, 79, 85, False, False, 'O');
    AList.AddOne('FodderHead6', MTRX_ALIENFODDER, 62, 74, False, False, 'P');
    AList.AddOne('FodderHead7', MTRX_ALIENFODDER, 68, 84, False, False, 'Q');
    AList.AddOne('FodderHead8', MTRX_ALIENFODDER, 66, 71, False, False, 'R');
    AList.AddOne('FodderShot', MTRX_ALIENFODDER, 8, 8, False, False, 'S');

    // MT_DEFENCEDRONE_STUB1
    AList.AddRotating8('DroneB', MTRX_DEFENCEDRONE_STUB1, 1, 63, 67, False, False);

    // MT_DEFENCEDRONE_STUB2
    AList.AddRotating8('DroneB', MTRX_DEFENCEDRONE_STUB2, 1, 63, 67, False, False);

    // MT_BATTLEDRONE1
    AList.AddRotating8('DroneA', MTRX_BATTLEDRONE1, 1, 91, 50, False, False);
    AList.AddOne('DroneA1Chunk1', MTRX_BATTLEDRONE1, 27, 35, False, False, 'B');
    AList.AddOne('DroneA1Chunk2', MTRX_BATTLEDRONE1, 31, 34, False, False, 'C');
    AList.AddOne('DroneA1Chunk3', MTRX_BATTLEDRONE1, 35, 25, False, False, 'D');
    AList.AddOne('DroneA1Chunk4', MTRX_BATTLEDRONE1, 30, 19, False, False, 'E');
    AList.AddOne('DroneA1Chunk5', MTRX_BATTLEDRONE1, 25, 15, False, False, 'F');
    AList.AddOne('DroneA1Chunk6', MTRX_BATTLEDRONE1, 19, 18, False, False, 'G');
    AList.AddOne('DroneA1Chunk7', MTRX_BATTLEDRONE1, 14, 25, False, False, 'H');
    AList.AddOne('DroneA1Chunk8', MTRX_BATTLEDRONE1, 17, 31, False, False, 'I');
    AList.AddOne('DroneA3Chunk', MTRX_BATTLEDRONE1, 7, 11, False, False, 'J');

    // MT_MISSILEBOAT1
    AList.AddRotating8('DroneC', MTRX_MISSILEBOAT1, 1, 83, 68, False, False);
    AList.AddOne('DroneCLeftChunk1', MTRX_MISSILEBOAT1, 46, 46, False, False, 'B');
    AList.AddOne('DroneCLeftChunk2', MTRX_MISSILEBOAT1, 44, 50, False, False, 'C');
    AList.AddOne('DroneCLeftChunk3', MTRX_MISSILEBOAT1, 38, 45, False, False, 'D');
    AList.AddOne('DroneCLeftChunk4', MTRX_MISSILEBOAT1, 35, 39, False, False, 'E');
    AList.AddOne('DroneCLeftChunk5', MTRX_MISSILEBOAT1, 37, 34, False, False, 'F');
    AList.AddOne('DroneCLeftChunk6', MTRX_MISSILEBOAT1, 41, 36, False, False, 'G');
    AList.AddOne('DroneCLeftChunk7', MTRX_MISSILEBOAT1, 42, 35, False, False, 'H');
    AList.AddOne('DroneCLeftChunk8', MTRX_MISSILEBOAT1, 44, 35, False, False, 'I');
    AList.AddRotating8('MissileBoatBody', MTRX_MISSILEBOAT1, 1, 85, 42, False, False, 'J');
    AList.AddOne('DroneCSingleChunk1', MTRX_MISSILEBOAT1, 11, 17, False, False, 'K');
    AList.AddOne('DroneCSingleChunk2', MTRX_MISSILEBOAT1, 17, 16, False, False, 'L');

    // MT_SKYFIREASSULTFIGHTER1
    AList.AddRotating8('LightAssault', MTRX_SKYFIREASSULTFIGHTER1, 1, 62, 51, False, False);
    AList.AddOne('StormBirdChunk5', MTRX_SKYFIREASSULTFIGHTER1, 50, 45, False, False, 'B');
    AList.AddRotating8('SkyFireBodyBusted', MTRX_SKYFIREASSULTFIGHTER1, 1, 72, 31, False, False, 'C');

    // MT_STORMBIRDHEAVYBOMBER
    AList.AddRotating8('HeavyFighter', MTRX_STORMBIRDHEAVYBOMBER, 1, 86, 54, False, False);
    AList.AddOne('SkyFireChunk1', MTRX_STORMBIRDHEAVYBOMBER, 51, 53, False, False, 'B');
    AList.AddRotating8('StormBirdBodyBust', MTRX_STORMBIRDHEAVYBOMBER, 1, 82, 48, False, False, 'C');

    // MT_SPAWNER
    AList.AddRotating8('Spawner', MTRX_SPAWNER, 1, 146, 154, False, False);

    // MT_EXODROID
    AList.AddRotating8('ExoDroid', MTRX_EXODROID, 3, 113, 188, False, False);
    AList.AddOne('ExoDroidFire1', MTRX_EXODROID, 56, 192, False, False, 'D', '1', 'E1');
    AList.AddOne('ExoDroidFire2', MTRX_EXODROID, 100, 192, False, False, 'D', '2', 'E8');
    AList.AddOne('ExoDroidFire3', MTRX_EXODROID, 126, 188, False, False, 'D', '3', 'E7');
    AList.AddOne('ExoDroidFire4', MTRX_EXODROID, 94, 190, False, False, 'D', '4', 'E6');
    AList.AddOne('ExoDroidFire5', MTRX_EXODROID, 48, 188, False, False, 'D', '5', 'E5');
    AList.AddOne('ExoDroidFire6', MTRX_EXODROID, 98, 188, False, False, 'D', '6', 'E4');
    AList.AddOne('ExoDroidFire7', MTRX_EXODROID, 121, 188, False, False, 'D', '7', 'E3');
    AList.AddOne('ExoDroidFire8', MTRX_EXODROID, 117, 191, False, False, 'D', '8', 'E2');
    AList.AddOne('Exo-DroidArm1', MTRX_EXODROID, 58, 63, False, False, 'F');
    AList.AddOne('Exo-DroidArm2', MTRX_EXODROID, 64, 56, False, False, 'G');
    AList.AddOne('Exo-DroidArm3', MTRX_EXODROID, 64, 46, False, False, 'H');
    AList.AddOne('Exo-DroidArm4', MTRX_EXODROID, 55, 35, False, False, 'I');
    AList.AddOne('Exo-DroidArm5', MTRX_EXODROID, 46, 33, False, False, 'J');
    AList.AddOne('Exo-DroidArm6', MTRX_EXODROID, 42, 38, False, False, 'K');
    AList.AddOne('Exo-DroidArm7', MTRX_EXODROID, 40, 48, False, False, 'L');
    AList.AddOne('Exo-DroidArm8', MTRX_EXODROID, 45, 55, False, False, 'M');
    AList.AddOne('Exo-DroidDeadBitmap', MTRX_EXODROID, 65, 24, False, False, 'N');

    // MT_SNAKEDEAMON
    AList.AddNonRotating('SnakeDemonBadassHead', MTRX_SNAKEDEAMON, 3, 57, 109, False, False);
    AList.AddOne('SnakeDemonBadassBody', MTRX_SNAKEDEAMON, 41, 34, False, False, 'D');
    AList.AddOne('SnakeDemonBadassBody', MTRX_SNAKEDEAMON, 41, 65, False, False, 'E');

    // MT_MINE
    AList.AddNonRotating('Airmine', MTRX_MINE, 3, 51, 93, False, False);

    // MT_ROTATINGRADAR1
    AList.AddRotating8('RadarDish', MTRX_ROTATINGRADAR1, 1, 53, 91, False, False);

    // MT_SHIELDGENERATOR1
    AList.AddNonRotating('ShieldGen', MTRX_SHIELDGENERATOR1, 3, 34, 135, False, False);

    // MT_SECONDCOOLAND1
    AList.AddNonRotating('SecondCoolant', MTRX_SECONDCOOLAND1, 3, 64, 183, False, False);

    // MT_BIOMECHUP
    AList.AddOne('BioMech9', MTRX_BIOMECHUP, 45, 89, False, False);
    AList.AddOne('BioMechBodyBust1', MTRX_BIOMECHUP, 75, 47, False, False, 'B', '1', 'C1');
    AList.AddOne('BioMechBodyBust2', MTRX_BIOMECHUP, 75, 47, False, False, 'B', '2', 'C8');
    AList.AddOne('BioMechBodyBust3', MTRX_BIOMECHUP, 75, 47, False, False, 'B', '3', 'C7');
    AList.AddOne('BioMechBodyBust4', MTRX_BIOMECHUP, 75, 47, False, False, 'B', '4', 'C6');
    AList.AddOne('BioMechBodyBust5', MTRX_BIOMECHUP, 75, 47, False, False, 'B', '5', 'C5');
    AList.AddOne('BioMechBodyBust6', MTRX_BIOMECHUP, 75, 47, False, False, 'B', '6', 'C4');
    AList.AddOne('BioMechBodyBust7', MTRX_BIOMECHUP, 75, 47, False, False, 'B', '7', 'C3');
    AList.AddOne('BioMechBodyBust8', MTRX_BIOMECHUP, 75, 47, False, False, 'B', '8', 'C2');
    AList.AddOne('BioMechChunk', MTRX_BIOMECHUP, 14, 14, False, False, 'D');
    AList.AddOne('BioXplode1', MTRX_BIOMECHUP, 35, 29, False, False, 'E');
    AList.AddOne('BioXplode2', MTRX_BIOMECHUP, 57, 44, False, False, 'F');
    AList.AddOne('BioXplode3', MTRX_BIOMECHUP, 58, 48, False, False, 'G');
    AList.AddOne('BioXplode4', MTRX_BIOMECHUP, 62, 60, False, False, 'H');
    AList.AddOne('BioXplode5', MTRX_BIOMECHUP, 63, 56, False, False, 'I');
    AList.AddOne('BioChunk1', MTRX_BIOMECHUP, 24, 20, False, False, 'J');
    AList.AddOne('BioChunk2', MTRX_BIOMECHUP, 7, 18, False, False, 'K');
    AList.AddOne('BioChunk3', MTRX_BIOMECHUP, 9, 11, False, False, 'L');
    AList.AddOne('BioChunk4', MTRX_BIOMECHUP, 6, 13, False, False, 'M');

    // MT_ENGINECORE
    AList.AddNonRotating('EngineCore', MTRX_ENGINECORE, 3, 59, 184, False, False);

    // MT_DEFENCEDRONE1
    AList.AddRotating8('DroneB', MTRX_DEFENCEDRONE1, 1, 63, 67, False, False);

    // MT_BATTLEDRONE2
    AList.AddRotating8('DroneA', MTRX_BATTLEDRONE2, 1, 91, 50, False, False);

    // MT_MISSILEBOAT2
    AList.AddRotating8('DroneC', MTRX_MISSILEBOAT2, 1, 83, 68, False, False);

    // MT_SKYFIREASSULTFIGHTER2
    AList.AddRotating8('LightAssault', MTRX_SKYFIREASSULTFIGHTER2, 1, 62, 51, False, False);

    // MT_SKYFIREASSULTFIGHTER4
    AList.AddRotating8('LightAssault', MTRX_SKYFIREASSULTFIGHTER4, 1, 62, 51, False, False);

    // MT_BIOMECH
    AList.AddRotating8('BioMech', MTRX_BIOMECH, 1, 73, 60, False, False);

    // MT_DEFENCEDRONE2
    AList.AddRotating8('DroneB', MTRX_DEFENCEDRONE2, 1, 63, 67, False, False);

    // MT_RUI
    AList.AddOne('Rui_1', MTRX_RUI, 16, 58, False, False, 'A');
    AList.AddOne('Rui_2', MTRX_RUI, 25, 58, False, False, 'B');
    AList.AddOne('Rui_3', MTRX_RUI, 31, 64, False, False, 'C');
    AList.AddOne('RuiBust_1', MTRX_RUI, 32, 58, False, False, 'D');
    AList.AddOne('RuiBust_2', MTRX_RUI, 32, 58, False, False, 'E');
    AList.AddOne('RuiBust_3', MTRX_RUI, 32, 58, False, False, 'F');
    AList.AddOne('RuiFall', MTRX_RUI, 42, 52, False, False, 'G');
    AList.AddOne('RuiDead', MTRX_RUI, 54, 19, False, False, 'H');

    // MT_SHIELDGENERATOR2
    AList.AddNonRotating('ShldGenerator', MTRX_SHIELDGENERATOR2, 3, 44, 176, False, False);

    // MT_COOLANDGENERATOR
    AList.AddNonRotating('CoolantGener', MTRX_COOLANDGENERATOR, 3, 55, 190, False, False);

    // MT_ROTATINGRADAR2
    AList.AddRotating8('RadarDish', MTRX_ROTATINGRADAR2, 1, 53, 91, False, False);

    // MT_MISSILEBOAT_STUB
    AList.AddRotating8('DroneC', MTRX_MISSILEBOAT_STUB, 1, 83, 68, False, False);

    // MT_BATTLEDRONE3
    AList.AddRotating8('DroneA', MTRX_BATTLEDRONE3, 1, 91, 50, False, False);

    // MT_ROTATINGLIGHT
    AList.AddOne('RotatingLight2', MTRX_ROTATINGLIGHT, 10, 61, True, True, 'A');
    AList.AddOne('RotatingLight3', MTRX_ROTATINGLIGHT, 10, 61, True, True, 'B');
    AList.AddOne('RotatingLight4', MTRX_ROTATINGLIGHT, 10, 61, True, True, 'C');
    AList.AddOne('RotatingLight5', MTRX_ROTATINGLIGHT, 10, 61, True, True, 'D');
    AList.AddOne('RotatingLight6', MTRX_ROTATINGLIGHT, 10, 61, True, True, 'E');
    AList.AddOne('RotatingLight7', MTRX_ROTATINGLIGHT, 10, 61, True, True, 'F');
    AList.AddOne('RotatingLight8', MTRX_ROTATINGLIGHT, 10, 61, True, True, 'G');
    AList.AddOne('RotatingLight9', MTRX_ROTATINGLIGHT, 10, 61, True, True, 'H');
    AList.AddOne('RotatingLightBUST', MTRX_ROTATINGLIGHT, 10, 37, True, True, 'I');

    // MT_EGG
    AList.AddOne('Egg', MTRX_EGG, 62, 82, False, False, 'A');
    AList.AddOne('Eggbust', MTRX_EGG, 62, 82, False, False, 'B');

    // MT_RADIXBARREL
    AList.AddOne('Barrel', MTRX_RADIXBARREL, 25, 57, False, False, 'A');
    AList.AddOne('BarrelDUDbust', MTRX_RADIXBARREL, 22, 23, False, False, 'B');

    AList.AddOne('BarrelRotate1', MTRX_RADIXBARREL, 41, 77, False, False, 'C');
    AList.AddOne('BarrelRotate2', MTRX_RADIXBARREL, 41, 77, False, False, 'D');
    AList.AddOne('BarrelRotate3(end)', MTRX_RADIXBARREL, 41, 77, False, False, 'E');
    AList.AddOne('BarrelRotate4', MTRX_RADIXBARREL, 41, 77, False, False, 'F');
    AList.AddOne('BarrelRotate5(end)', MTRX_RADIXBARREL, 41, 77, False, False, 'G');
    AList.AddOne('BarrelRotate6', MTRX_RADIXBARREL, 41, 77, False, False, 'H');
    AList.AddOne('BarrelRotate7(end)', MTRX_RADIXBARREL, 41, 77, False, False, 'I');
    AList.AddOne('BarrelRotate8', MTRX_RADIXBARREL, 41, 77, False, False, 'J');
    AList.AddOne('BarrelRotate3(end)', MTRX_RADIXBARREL, 41, 60, False, False, 'K');
    AList.AddOne('BarrelRotate5(end)', MTRX_RADIXBARREL, 41, 60, False, False, 'L');
    AList.AddOne('BarrelRotate7(end)', MTRX_RADIXBARREL, 41, 60, False, False, 'M');

    // MT_DOZZER
    AList.AddOne('Dozer1', MTRX_DOZZER, 98, 70, False, False, 'A', '1');
    AList.AddOne('Dozer2', MTRX_DOZZER, 98, 70, False, False, 'A', '2', 'A8');
    AList.AddOne('Dozer3', MTRX_DOZZER, 98, 70, False, False, 'A', '3', 'A7');
    AList.AddOne('Dozer4', MTRX_DOZZER, 98, 78, False, False, 'A', '4', 'A6');
    AList.AddOne('Dozer5', MTRX_DOZZER, 98, 70, False, False, 'A', '5');

    // MT_LIFT
    AList.AddRotating8('Lift', MTRX_LIFT, 1, 110, 88, False, False);

    // MT_SECONDCOOLAND2
    AList.AddNonRotating('SecondCoolant', MTRX_SECONDCOOLAND2, 1, 64, 183, False, False);

    // MT_SECONDCOOLAND3
    AList.AddNonRotating('SecondCoolant', MTRX_SECONDCOOLAND3, 1, 64, 183, False, False);

    // Radix things without doom editor number (runtime)
    // MT_RADIXPLASMA
    AList.AddNonRotating('Plasma', MTTX_RADIXPLASMA, 3, 21, 24, False, False);
    AList.AddOne('NeutronCannonPuff1', MTTX_RADIXPLASMA, 13, 12, False, False, 'D');
    AList.AddOne('PlasmaPuf1', MTTX_RADIXPLASMA, 16, 16, False, False, 'E');
    AList.AddOne('PlasmaPuf2', MTTX_RADIXPLASMA, 12, 12, False, False, 'F');
    AList.AddOne('PlasmaPuf3', MTTX_RADIXPLASMA, 9, 11, False, False, 'G');

    // MT_RADIXEPCSHELL
    AList.AddOne('FireSmoke1', MTTX_RADIXEPCSHELL, 8, 7, False, False, 'A');
    AList.AddOne('FireSmoke2', MTTX_RADIXEPCSHELL, 8, 7, False, False, 'B');
    AList.AddOne('FireSmoke3', MTTX_RADIXEPCSHELL, 7, 7, False, False, 'C');

    // MT_RADIXSEEKINGMISSILE
    AList.AddRotating16('Seeker', MTTX_RADIXSEEKINGMISSILE, 1, 49, 17, False, False);

    // Radix sprites shared between objects
    AList.AddNonRotating('10FrameExplosion', DOOM_THING_2_RADIX + 0, 10, 49, 46, False, False);
    AList.AddNonRotating('SmallXplode', DOOM_THING_2_RADIX + 1, 5, 26, 21, False, False);
    AList.AddNonRotating('RisingSmoke', DOOM_THING_2_RADIX + 2, 10, 75, 62, False, False);
    AList.AddOne('BurnerSmoke1', DOOM_THING_2_RADIX + 3, 8, 7, False, False, 'A');
    AList.AddOne('BurnerSmoke2', DOOM_THING_2_RADIX + 3, 8, 7, False, False, 'B');
    AList.AddOne('BurnerSmoke3', DOOM_THING_2_RADIX + 3, 7, 7, False, False, 'C');
    AList.AddOne('FireballPuff1', DOOM_THING_2_RADIX + 4, 12, 11, False, False, 'A');
    AList.AddOne('FireballPuff2', DOOM_THING_2_RADIX + 4, 12, 11, False, False, 'B');
    AList.AddOne('FireballPuff3', DOOM_THING_2_RADIX + 4, 12, 11, False, False, 'C');

    // MT_RADIXNUKE
    AList.AddRotating16('Nuke', MTTX_RADIXNUKE, 1, 42, 16, False, False);

    // MT_RADIXPHASETORPEDO
    AList.AddOne('PhaseTorpedo1', MTTX_RADIXPHASETORPEDO, 16, 17, False, False, 'A');
    AList.AddOne('PhaseTorpedo2', MTTX_RADIXPHASETORPEDO, 15, 17, False, False, 'B');
    AList.AddOne('PhaseTorpedo3', MTTX_RADIXPHASETORPEDO, 18, 17, False, False, 'C');

    // MT_RADIXGRAVITYWAVE
    AList.AddOne('GravityWave1', MTTX_RADIXGRAVITYWAVE, 99, 28, False, False, 'A');
    AList.AddOne('GravityWave2', MTTX_RADIXGRAVITYWAVE, 99, 28, False, False, 'B');
    AList.AddOne('GravityWave3', MTTX_RADIXGRAVITYWAVE, 99, 28, False, False, 'C');

    // MT_RADIXGRAVITYWAVEEXPOLOSION
    AList.AddOne('GravityWavePuf1', MTTX_RADIXGRAVITYWAVEEXPOLOSION, 19, 20, False, False, 'A');
    AList.AddOne('GravityWavePuf2', MTTX_RADIXGRAVITYWAVEEXPOLOSION, 19, 20, False, False, 'B');
    AList.AddOne('GravityWavePuf3', MTTX_RADIXGRAVITYWAVEEXPOLOSION, 19, 18, False, False, 'C');
    AList.AddOne('GravityWavePuf4', MTTX_RADIXGRAVITYWAVEEXPOLOSION, 19, 18, False, False, 'D');
    AList.AddOne('GravityWavePuf5', MTTX_RADIXGRAVITYWAVEEXPOLOSION, 11, 15, False, False, 'E');

    // MT_ENEMYMISSILE
    AList.AddRotating16('Missile', MTTX_ENEMYMISSILE, 1, 14, 12, False, False, 1);
    AList.AddRotating16('Missile', MTTX_ENEMYMISSILE, 1, 22, 12, False, False, 2);
    AList.AddRotating16('Missile', MTTX_ENEMYMISSILE, 1, 32, 12, False, False, 3);
    AList.AddRotating16('Missile', MTTX_ENEMYMISSILE, 1, 37, 12, False, False, 4);
    AList.AddRotating16('Missile', MTTX_ENEMYMISSILE, 1, 37, 12, False, False, 5);
    AList.AddRotating16('Missile', MTTX_ENEMYMISSILE, 1, 36, 13, False, False, 6);
    AList.AddRotating16('Missile', MTTX_ENEMYMISSILE, 1, 31, 14, False, False, 7);
    AList.AddRotating16('Missile', MTTX_ENEMYMISSILE, 1, 23, 14, False, False, 8);
    AList.AddRotating16('Missile', MTTX_ENEMYMISSILE, 1, 14, 13, False, False, 9);
    AList.AddRotating16('Missile', MTTX_ENEMYMISSILE, 1, 23, 14, False, False, 10);
    AList.AddRotating16('Missile', MTTX_ENEMYMISSILE, 1, 31, 14, False, False, 11);
    AList.AddRotating16('Missile', MTTX_ENEMYMISSILE, 1, 36, 13, False, False, 12);
    AList.AddRotating16('Missile', MTTX_ENEMYMISSILE, 1, 38, 13, False, False, 13);
    AList.AddRotating16('Missile', MTTX_ENEMYMISSILE, 1, 37, 12, False, False, 14);
    AList.AddRotating16('Missile', MTTX_ENEMYMISSILE, 1, 32, 12, False, False, 15);
    AList.AddRotating16('Missile', MTTX_ENEMYMISSILE, 1, 22, 12, False, False, 16);

    // MT_DRONEBODYB
    AList.AddRotating8('DroneBBody', MTTX_DRONEBODYB, 1, 93, 48, False, False);

    // MT_ENEMYLASER
    AList.AddOne('EnemyLaser1', MTTX_ENEMYLASER, 19, 18, False, False, 'A');
    AList.AddOne('EnemyLaser2', MTTX_ENEMYLASER, 16, 18, False, False, 'B');
    AList.AddOne('EnemyLaser3', MTTX_ENEMYLASER, 17, 18, False, False, 'C');

    // MT_DRONEBODYA
    AList.AddOne('DroneABodyBusted1', MTTX_DRONEBODYA, 63, 37, False, False);

    // MT_CHUNK
    AList.AddOne('StrongBio-MineDead1', MTTX_CHUNK, 11, 13, False, False, 'A');
    AList.AddOne('StrongBio-MineDead2', MTTX_CHUNK, 15, 15, False, False, 'B');
    AList.AddOne('StrongBio-MineDead3', MTTX_CHUNK, 17, 24, False, False, 'C');
    AList.AddOne('MetalChunk1', MTTX_CHUNK, 8, 8, False, False, 'D');
    AList.AddOne('MetalChunk2', MTTX_CHUNK, 9, 10, False, False, 'E');
    AList.AddOne('MetalChunk3', MTTX_CHUNK, 10, 15, False, False, 'F');
    AList.AddOne('MetalChunk4', MTTX_CHUNK, 11, 14, False, False, 'G');

    // MT_ALDSLASER
    AList.AddRotating16('ALDSLaser', MTTX_ALDSLASER, 1, 24, 4, False, False);

    // MT_LASER
    AList.AddRotating16('Laser', MTTX_LASER, 1, 24, 4, False, False);

    // MT_BLOODSPLAT
    AList.AddNonRotating('BloodSplat', MTTX_BLOODSPLAT, 3, 31, 33, False, False);

    // MT_SPARKS
    AList.AddNonRotating('Sparks', MTTX_SPARKS, 5, 73, 63, False, False);

    // MT_RADIXWATERSPLASH
    AList.AddNonRotating('WaterSplash', MTTX_RADIXWATERSPLASH, 6, 35, 43, False, False);
    AList.AddOne('WaterSplash7', MTTX_RADIXWATERSPLASH, 55, 33, False, False, 'G');
    AList.AddOne('WaterSplash8', MTTX_RADIXWATERSPLASH, 55, 33, False, False, 'H');
    AList.AddOne('WaterSplash9', MTTX_RADIXWATERSPLASH, 55, 33, False, False, 'I');

    // MT_RADIXMUDSPLASH
    AList.AddNonRotating('MudSplash', MTTX_RADIXMUDSPLASH, 6, 35, 43, False, False);
    AList.AddOne('MudSplash7', MTTX_RADIXMUDSPLASH, 55, 33, False, False, 'G');
    AList.AddOne('MudSplash8', MTTX_RADIXMUDSPLASH, 55, 33, False, False, 'H');
    AList.AddOne('MudSplash9', MTTX_RADIXMUDSPLASH, 55, 33, False, False, 'I');

    // MT_RADIXLAVASPLASH
    AList.AddNonRotating('LavaSplash', MTTX_RADIXLAVASPLASH, 6, 35, 43, False, False);
    AList.AddOne('LavaSplash7', MTTX_RADIXLAVASPLASH, 55, 33, False, False, 'G');
    AList.AddOne('LavaSplash8', MTTX_RADIXLAVASPLASH, 55, 33, False, False, 'H');
    AList.AddOne('LavaSplash9', MTTX_RADIXLAVASPLASH, 55, 33, False, False, 'I');

    // 'PLAY' sprite
    AList.AddRotating8('NetRadixPlane', DOOM_THING_2_RADIX + 5, 1);
  for LFrame := 'B' to 'W' do
    AList.AddRotating8('NetRadixPlane', DOOM_THING_2_RADIX + 5, 1, -255, -255, True, True, LFrame);

  // briefing screen sprites
  AList.AddOne('EndLevelDoor', 9000);
  AList.AddOne('MissileWallBitmap', 9001);
end;

end.
