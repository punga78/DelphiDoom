{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the tables of the game: weapons, characters,     }
{  texts. Port of xGreed (Jim Valavanis, GPL v2 or later): constant.pas         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.Game.Tables;

interface

uses
  DelphiDoom.Greed.Types, DelphiDoom.Greed.Game.Constants;

type
  /// <summary>weapon_t: how a weapon charges and what ammunition it uses</summary>
  TGreedWeaponInfo = packed record
    /// <summary>How fast it charges</summary>
    ChargeRate: Integer;
    /// <summary>The current charge level</summary>
    Charge: Integer;
    /// <summary>timecount + chargetime</summary>
    ChargeTime: Integer;
    AmmoType: Integer;
    AmmoRate: Integer;
  end;

  /// <summary>
  ///   The tables of constant.pas, as the original has them: the weapons (the game keeps its own copy, the charge
  ///   changes), the frames of the weapons, the bobbing of the head and of the weapon, the names of the items and
  ///   of the characters, the numbers of the six characters, and the texts of the missions
  /// </summary>
  TGreedGameTables = class
  public
    const
      PlayerMoveSpeed = (GREED_FRACUNIT * 5) div 2;
      DefaultPlayerTurnSpeed = 8;
      DefaultTurnUnit = 2;

    const
      // weapon info
      Weapons: array[0..18] of TGreedWeaponInfo = (
        (ChargeRate: 6;  Charge: 0; ChargeTime: 0; AmmoType: 0; AmmoRate:  0),   //0  double shot rifle    energy      // removed not
        (ChargeRate: 4;  Charge: 0; ChargeTime: 0; AmmoType: 1; AmmoRate:  1),   //1  psyborg #2           ballistic
        (ChargeRate: 3;  Charge: 0; ChargeTime: 0; AmmoType: 1; AmmoRate:  1),   //2  pulserifle           ballistic
        (ChargeRate: 1;  Charge: 0; ChargeTime: 0; AmmoType: 2; AmmoRate:  1),   //3  flamer               plasma
        (ChargeRate: 12; Charge: 0; ChargeTime: 0; AmmoType: 0; AmmoRate:  5),   //4  spreadgun            energy
        (ChargeRate: 32; Charge: 0; ChargeTime: 0; AmmoType: 2; AmmoRate:  5),   //5  bfg                  plasma      // removed not
        (ChargeRate: 32; Charge: 0; ChargeTime: 0; AmmoType: 3; AmmoRate:  5),   //6  grenade              grenade     // removed not
        (ChargeRate: 6;  Charge: 0; ChargeTime: 0; AmmoType: 0; AmmoRate:  0),   //7  psyborg #1           energy
        (ChargeRate: 12; Charge: 0; ChargeTime: 0; AmmoType: 0; AmmoRate:  0),   //8  lizard #1            energy
        (ChargeRate: 8;  Charge: 0; ChargeTime: 0; AmmoType: 1; AmmoRate:  2),   //9  lizard #2            ballistic
        (ChargeRate: 6;  Charge: 0; ChargeTime: 0; AmmoType: 0; AmmoRate:  1),   //10 specimen #2          energy
        (ChargeRate: 6;  Charge: 0; ChargeTime: 0; AmmoType: 1; AmmoRate:  1),   //11 mooman #2            ballistic
        (ChargeRate: 12; Charge: 0; ChargeTime: 0; AmmoType: 2; AmmoRate:  2),   //12 trix #2              plasma
        (ChargeRate: 12; Charge: 0; ChargeTime: 0; AmmoType: 0; AmmoRate:  0),   //13 mooman #1            energy
        (ChargeRate: 12; Charge: 0; ChargeTime: 0; AmmoType: 0; AmmoRate:  0),   //14 specimen #1          energy
        (ChargeRate: 12; Charge: 0; ChargeTime: 0; AmmoType: 0; AmmoRate:  0),   //15 trix #1              energy
        (ChargeRate: 3;  Charge: 0; ChargeTime: 0; AmmoType: 0; AmmoRate:  1),   //16 red gun              energy
        (ChargeRate: 12; Charge: 0; ChargeTime: 0; AmmoType: 1; AmmoRate:  7),   //17 blue gun             ballistic
        (ChargeRate: 20; Charge: 0; ChargeTime: 0; AmmoType: 2; AmmoRate: 75)    //18 green gun            plasma
      );

    (*
    0 energy
    1 ballistic
    2 plasma
    3 grenade
    *)

    const
      // finite state machine (modes of weapon frames)
      WeaponState: packed array[0..18, 0..4] of Byte = (
        (0, 0, 0, 0, 0),    //0
        (0, 2, 0, 0, 0),    //1
        (0, 2, 3, 0, 0),    //2
        (0, 2, 3, 0, 0),    //3
        (0, 2, 3, 0, 0),    //4
        (0, 2, 3, 4, 0),    //5
        (0, 0, 0, 0, 0),    //6
        (0, 2, 0, 0, 0),    //7
        (0, 2, 3, 0, 0),    //8
        (0, 2, 0, 0, 0),    //9
        (0, 2, 3, 0, 0),    //10
        (0, 2, 0, 0, 0),    //11
        (0, 2, 0, 0, 0),    //12
        (0, 2, 0, 0, 0),    //13
        (0, 2, 0, 0, 0),    //14
        (0, 2, 0, 0, 0),    //15
        (0, 0, 0, 0, 0),    //16
        (0, 2, 0, 0, 0),    //17
        (0, 2, 3, 4, 0)     //18
      );


    const
      // sinusoidal head movement table
      HeadMove: array[0..GREED_HEADBOBFACTOR * GREED_MAXBOBS] of Integer = (
        GREED_BOBFACTOR * 0,
        GREED_BOBFACTOR * 1715,
        GREED_BOBFACTOR * 3425,
        GREED_BOBFACTOR * 5126,
        GREED_BOBFACTOR * 6813,
        GREED_BOBFACTOR * 8481,
        GREED_BOBFACTOR * 10126,
        GREED_BOBFACTOR * 11743,
        GREED_BOBFACTOR * 13328,
        GREED_BOBFACTOR * 14876,
        GREED_BOBFACTOR * 16384,
        GREED_BOBFACTOR * 17847,
        GREED_BOBFACTOR * 19261,
        GREED_BOBFACTOR * 20622,
        GREED_BOBFACTOR * 21926,
        GREED_BOBFACTOR * 23170,
        GREED_BOBFACTOR * 24351,
        GREED_BOBFACTOR * 25466,
        GREED_BOBFACTOR * 26510,
        GREED_BOBFACTOR * 27482,
        GREED_BOBFACTOR * 28378,
        GREED_BOBFACTOR * 29197,
        GREED_BOBFACTOR * 29935,
        GREED_BOBFACTOR * 30592,
        GREED_BOBFACTOR * 31164,
        GREED_BOBFACTOR * 31651,
        GREED_BOBFACTOR * 32052,
        GREED_BOBFACTOR * 32365,
        GREED_BOBFACTOR * 32588,
        GREED_BOBFACTOR * 32723,
        GREED_BOBFACTOR * 32768,
        GREED_BOBFACTOR * 32723,
        GREED_BOBFACTOR * 32588,
        GREED_BOBFACTOR * 32365,
        GREED_BOBFACTOR * 32052,
        GREED_BOBFACTOR * 31651,
        GREED_BOBFACTOR * 31164,
        GREED_BOBFACTOR * 30592,
        GREED_BOBFACTOR * 29935,
        GREED_BOBFACTOR * 29197,
        GREED_BOBFACTOR * 28378,
        GREED_BOBFACTOR * 27482,
        GREED_BOBFACTOR * 26510,
        GREED_BOBFACTOR * 25466,
        GREED_BOBFACTOR * 24351,
        GREED_BOBFACTOR * 23170,
        GREED_BOBFACTOR * 21926,
        GREED_BOBFACTOR * 20622,
        GREED_BOBFACTOR * 19261,
        GREED_BOBFACTOR * 17847,
        GREED_BOBFACTOR * 16384,
        GREED_BOBFACTOR * 14876,
        GREED_BOBFACTOR * 13328,
        GREED_BOBFACTOR * 11743,
        GREED_BOBFACTOR * 10126,
        GREED_BOBFACTOR * 8481,
        GREED_BOBFACTOR * 6813,
        GREED_BOBFACTOR * 5126,
        GREED_BOBFACTOR * 3425,
        GREED_BOBFACTOR * 1715,
        GREED_BOBFACTOR * 0,
        -GREED_BOBFACTOR * 1715,
        -GREED_BOBFACTOR * 3425,
        -GREED_BOBFACTOR * 5126,
        -GREED_BOBFACTOR * 6813,
        -GREED_BOBFACTOR * 8481,
        -GREED_BOBFACTOR * 10126,
        -GREED_BOBFACTOR * 11743,
        -GREED_BOBFACTOR * 13328,
        -GREED_BOBFACTOR * 14876,
        -GREED_BOBFACTOR * 16384,
        -GREED_BOBFACTOR * 17847,
        -GREED_BOBFACTOR * 19261,
        -GREED_BOBFACTOR * 20622,
        -GREED_BOBFACTOR * 21926,
        -GREED_BOBFACTOR * 23170,
        -GREED_BOBFACTOR * 24351,
        -GREED_BOBFACTOR * 25466,
        -GREED_BOBFACTOR * 26510,
        -GREED_BOBFACTOR * 27482,
        -GREED_BOBFACTOR * 28378,
        -GREED_BOBFACTOR * 29197,
        -GREED_BOBFACTOR * 29935,
        -GREED_BOBFACTOR * 30592,
        -GREED_BOBFACTOR * 31164,
        -GREED_BOBFACTOR * 31651,
        -GREED_BOBFACTOR * 32052,
        -GREED_BOBFACTOR * 32365,
        -GREED_BOBFACTOR * 32588,
        -GREED_BOBFACTOR * 32723,
        -GREED_BOBFACTOR * 32768,
        -GREED_BOBFACTOR * 32723,
        -GREED_BOBFACTOR * 32588,
        -GREED_BOBFACTOR * 32365,
        -GREED_BOBFACTOR * 32052,
        -GREED_BOBFACTOR * 31651,
        -GREED_BOBFACTOR * 31164,
        -GREED_BOBFACTOR * 30592,
        -GREED_BOBFACTOR * 29935,
        -GREED_BOBFACTOR * 29197,
        -GREED_BOBFACTOR * 28378,
        -GREED_BOBFACTOR * 27482,
        -GREED_BOBFACTOR * 26510,
        -GREED_BOBFACTOR * 25466,
        -GREED_BOBFACTOR * 24351,
        -GREED_BOBFACTOR * 23170,
        -GREED_BOBFACTOR * 21926,
        -GREED_BOBFACTOR * 20622,
        -GREED_BOBFACTOR * 19261,
        -GREED_BOBFACTOR * 17847,
        -GREED_BOBFACTOR * 16384,
        -GREED_BOBFACTOR * 14876,
        -GREED_BOBFACTOR * 13328,
        -GREED_BOBFACTOR * 11743,
        -GREED_BOBFACTOR * 10126,
        -GREED_BOBFACTOR * 8481,
        -GREED_BOBFACTOR * 6813,
        -GREED_BOBFACTOR * 5126,
        -GREED_BOBFACTOR * 3425,
        -GREED_BOBFACTOR * 1715,
        GREED_BOBFACTOR * 0
      );

    const
      WeaponMove: array[0..GREED_WEAPONBOBFACTOR * GREED_MAXBOBS] of Integer = (
        0, 1715, 3425, 5126, 6813, 8481, 10126, 11743, 13328, 14876, 16384, 17847, 19261, 20622, 21926,
        23170, 24351, 25466, 26510, 27482, 28378, 29197, 29935, 30592, 31164, 31651, 32052, 32365, 32588, 32723,
        32768, 32723, 32588, 32365, 32052, 31651, 31164, 30592, 29935, 29197, 28378, 27482, 26510, 25466, 24351,
        23170, 21926, 20622, 19261, 17847, 16384, 14876, 13328, 11743, 10126, 8481, 6813, 5126, 3425, 1715,
        0, -1715, -3425, -5126, -6813, -8481, -10126, -11743, -13328, -14876, -16384, -17847, -19261, -20622, -21926,
        -23170, -24351, -25466, -26510, -27482, -28378, -29197, -29935, -30592, -31164, -31651, -32052, -32365, -32588, -32723,
        -32768, -32723, -32588, -32365, -32052, -31651, -31164, -30592, -29935, -29197, -28378, -27482, -26510, -25466, -24351,
        -23170, -21926, -20622, -19261, -17847, -16384, -14876, -13328, -11743, -10126, -8481, -6813, -5126, -3425, -1715,
        0
      );

    const
      RandomItemNames: array[0..GREED_MAXRANDOMITEMS - 1] of string = (
        'Quantum Energy Lattice',
        'Verton Battery Pack',
        'Hezfu Mind Grubs',
        'Solar Particle Collector',
        'Exo-Suit Patching Kit',
        'Gates22 Anti-Viral Algorithms',
        'Pelermid Gorgon Scale',
        'Fertility Charm from Vozara 3',
        'D) and (H Nucleo-Pistol (disfunct)',
        'Needle Drive Micro-Insulation',
        'Formani Shunt Cortex',
        'Auto-Med Surgical Platform',
        'Gygaxian Meditation Tome',
        'Pan Flute of Harask',
        'Cryo-Fugue Refrigerant GelPak',
        'Veros VIII Crown Jewels',
        'Adhesive Message Pads',
        'Self-Replicating Food Ration',
        'Selukani Hull Scouring Fungi',
        'Mnemony 6 Neural Net Crystals',
        'Harag Species Bio-Index',
        'Dane-Kyna Seeker Module',
        'Inertia-Absorb Armor Plating',
        'Selan Energy Scythe',
        'Transcendant Flea',
        'Xolas-Prime Prayer Icon',
        'Kriijing Spider Mono-Webbing',
        'Dysolv-It Pressurized Spray',
        'Galactic Shock Troop Insignia',
        'Hawking Singularity Framework',
        'Enviro-Stabilizer',
        'Audio Signal Generator',
        'EchoDrome Motion Sensor',
        'RGK Heat Sensor',
        'Rad12 Radiation Patches',
        'Hydro Nutrient Solu-Drink',
        'Semantik Lingua Pad',
        'Werton System Travel Guide',
        'Kaltrop mk 4 Mine (nonfunct)',
        'Jabberwock Phase Dish',
        'D-Gauss Energy Dampener',
        'Vyvald Amino Acid Solution',
        'Zheldisian Logic Trap',
        'Feldscape Holo-Generator',
        'Ruwelda-Trieu Currency',
        'Android Recharge Station',
        'Vesppil Witch Charm',
        'Iedine Crystal Psyche Skull'
      );

    const
      PickupMessageCount = 14;
      PickupMessages: array[0..PickupMessageCount - 1] of string = (
        'Grenades picked up!',
        'ReversoPill picked up!',
        'Proximity Mines picked up!',
        'Time Bombs picked up!',
        'Decoy picked up!',
        'InstaWall picked up!',
        'Clone picked up!',
        'HoloSuit picked up!',
        'Invisibility Shield picked up!',
        'Warp Jammer picked up!',
        'Soul Stealer picked up!',
        'Ammo Box picked up!',
        'Auto-Doc picked up!',
        'Utility Chest picked up!'
      );

    const
      PickupAmountCount = 12;
      PickupAmounts: array[0..PickupAmountCount - 1] of Byte = (
        5, 1, 2, 2, 1, 1, 1, 1, 1, 1, 1, 125
      );

    const
      PickupAmmoMessageCount = 3;
      PickupAmmoMessages: array[0..PickupAmmoMessageCount - 1] of string = (
        'Energy ammo picked up!',
        'Bullets picked up!',
        'Plasma ammo picked up!'
      );

    const
      ViewSizes: array[0..GREED_MAXVIEWSIZE * 2 - 1] of Integer = (
        320, 200,
        320, 200,
        320, 200,
        320, 200,
        320, 200
      );

    const
      ViewLocations: array[0..GREED_MAXVIEWSIZE * 2 - 1] of Integer = (
        0, 0,
        0, 0,
        0, 0,
        0, 0,
        0, 0
      );


    const
      SpriteLumpNames: array[0..GREED_S_END - GREED_S_START] of string = (
        // player Weapons shots
        'pulsebullet', 'pulsebullet', 'fireball',
        'spreadshot', 'pulsebullet', 'crossshot', 'spec7shot',
        'pulsebullet', 'prongshot', 'pinkball', 'missile', 'greenball',

        'explode', 'explode2',
        'pulsebullet', 'firewall',  // mine stuff
        'pulsebullet',              // hand weapon attack
        'pulsebullet',              // soul stealer bullet
        'wallpuff', 'blood', 'greedblood',
        'plasmawallpuff', 'greenring', 'explode',
        'generator', 'warp',

        'pulsebullet', 'fireball', 'probebullet', 'missile', 'spreadshot',  // kaal

        'missile', 'pulsebullet', // 6 & 7
        'fireball', 'pulsebullet', 'pulsebullet', 'spreadshot',  // prison

        'bigredball', 'greenball', 'greenarrow', 'pulsebullet' // 12, 13, 14, 15
      );

    const
      CharacterNames: array[0..GREED_MAXCHARTYPES - 1] of string = (
        'cyborg',
        'lizardman',
        'mooman',
        'specimen7',
        'dominatrix',
        'bighead'
      );

    const
      StatusBarLocations: array[0..GREED_MAXVIEWSIZE * 2 - 1] of Integer = (
        0, 0,
        220, 149,
        4, 149,
        4, 149,
        4, 149
      );

    const
      PlayerHeights: array[0..GREED_MAXCHARTYPES - 1] of TGreedFixed = (
        42 * GREED_FRACUNIT,
        35 * GREED_FRACUNIT,
        50 * GREED_FRACUNIT,
        35 * GREED_FRACUNIT,
        38 * GREED_FRACUNIT,
        32 * GREED_FRACUNIT
      );

    const
      PlayerMaxShield: array[0..GREED_MAXCHARTYPES - 1] of Integer = (
        700, 400, 500, 300, 500, 700
      );

    const
      PlayerMaxAngst: array[0..GREED_MAXCHARTYPES - 1] of Integer = (
        600, 400, 700, 500, 500, 700
      );

    const
      PlayerWalkMod: array[0..GREED_MAXCHARTYPES - 1] of Integer = (
        -PlayerMoveSpeed,
        PlayerMoveSpeed,
        -PlayerMoveSpeed,
        PlayerMoveSpeed,
        0,
        PlayerMoveSpeed * 3 div 2
      );

    const
      PlayerRunMod: array[0..GREED_MAXCHARTYPES - 1] of Integer = (
        -PlayerMoveSpeed,
        PlayerMoveSpeed div 2,
        -PlayerMoveSpeed,
        PlayerMoveSpeed div 2,
        0,
        PlayerMoveSpeed * 2
      );

    const
      PlayerJumpMod: array[0..GREED_MAXCHARTYPES - 1] of TGreedFixed = (
        -GREED_FRACUNIT,
        0,
        0,
        0,
        -GREED_FRACUNIT,
        0
      );


    /// <summary>
    ///   missioninfo: one of the three pieces (0..2) of the briefing of a map; '' outside the maps 0..29. ADemo
    ///   chooses the texts of the demo
    /// </summary>
    class function MissionInfo(AMap, AStringNumber: Integer; ADemo: Boolean): string; static;
    /// <summary>IsMonster of protos_h.pas: the kind is one of the fifteen monsters (with or without the _NS)</summary>
    class function IsMonster(AKind: Integer): Boolean; static;
  end;

implementation

class function TGreedGameTables.IsMonster(AKind: Integer): Boolean;
begin
  Result := AKind in [GREED_S_MONSTER1, GREED_S_MONSTER1_NS, GREED_S_MONSTER2, GREED_S_MONSTER2_NS, GREED_S_MONSTER3,
    GREED_S_MONSTER3_NS, GREED_S_MONSTER5, GREED_S_MONSTER5_NS, GREED_S_MONSTER4, GREED_S_MONSTER4_NS, GREED_S_MONSTER6,
    GREED_S_MONSTER6_NS, GREED_S_MONSTER7, GREED_S_MONSTER7_NS, GREED_S_MONSTER8, GREED_S_MONSTER8_NS, GREED_S_MONSTER9,
    GREED_S_MONSTER9_NS, GREED_S_MONSTER10, GREED_S_MONSTER10_NS, GREED_S_MONSTER11, GREED_S_MONSTER11_NS,
    GREED_S_MONSTER12, GREED_S_MONSTER12_NS, GREED_S_MONSTER13, GREED_S_MONSTER13_NS, GREED_S_MONSTER14,
    GREED_S_MONSTER14_NS, GREED_S_MONSTER15, GREED_S_MONSTER15_NS];
end;

class function TGreedGameTables.MissionInfo(AMap, AStringNumber: Integer; ADemo: Boolean): string;
begin
  Result := '';

  if (AMap < 0) or (AMap >= 30) or (AStringNumber < 0) or (AStringNumber >= 3) then
    Exit;

  if not ADemo then
  begin
    case AMap of
      1:
        case AStringNumber of
        0: Result :=
            'Sublevel 2:'#13#10 +
            'Primary Holding'#13#10 +
            ' THIS SUBLEVEL SERVES AS THE SUPPLIES ENTRY POINT ON THE COLONY'#13#10 +
            'AS WELL AS THE INMATE FREEHOLD.  THE PRIMARY OBJECT TO BE'#13#10 +
            'ACQUIRED IN THIS SUBLEVEL IS A SPACE GENERATOR WHICH HELPS POWER'#13#10; //
        1: Result :=
            'THE OUTER SHIELDING FOR THE DETENTION FACILITY.  REMOVING THIS'#13#10 +
            'ITEM IS NECESSARY IF YOU ARE TO MOVE INTO THE NEXT SUBLEVEL.'#13#10 +
            ' SECONDARY TARGETS INCLUDE VIALS OF TRUTH SERUM AND HYPODERMIC'#13#10 +
            'NEEDLES USED DURING INMATE INTERROGATION.  ONCE YOU''VE ACQUIRED'#13#10; //
        else
          Result :=
            'THE PRIMARY GOAL AND YOUR POINT TOTAL MEETS OR EXCEEDS 55,000'#13#10 +
            'WE''LL OPEN A TRANSLATION NEXUS TO THE NEXT SUBLEVEL.  OH, AND ONE'#13#10 +
            'LAST THING...'#13#10 +
            '...DON''T TRIGGER THE AIRLOCKS IN THIS AREA UNLESS YOU WANT THE'#13#10 +
            'AIR RIPPED VIOLENTY FROM YOUR LUNGS.'#13#10; //
        end;

      2:
        case AStringNumber of
        0: Result :=
            'Sublevel 3:'#13#10 +
            'Detention Facility'#13#10 +
            'THE RIOT IN THE COLONY HAS REACHED NEW HEIGHTS OF CHAOS.  THE'#13#10; //
        1: Result :=
            'WARDEN''S QUARTERS HAVE BEEN BREACHED, HIS HEAD WAS CUT FROM HIS'#13#10 +
            'BODY AND SUBSEQUENTLY HIDDEN IN A JAR ON THIS SUBLEVEL.  THE'#13#10 +
            'A.V.C. IS INTERESTED IN REVIVING THE BRAIN SO IT HAS BECOME YOUR'#13#10; //
        else
          Result :=
            'PRIMARY TARGET ITEM.  SECONDARIES INCLUDE LUBRICANTS AND'#13#10 +
            'EMERGENCY LANTERNS.  IF AFTER ACQUIRING THE PRIMARY ITEM YOUR'#13#10 +
            'POINT TOTAL MEETS OR EXCEEDS 60,000 POINTS WE''LL OPEN A NEXUS'#13#10 +
            'AND TRANSLATE YOU TO THE PURIFICATION FACILITY.'#13#10 +
            'HAPPY HEAD HUNTING.'#13#10; //
        end;

      3:
        case AStringNumber of
        0: Result :=
            'Sublevel 4:'#13#10 +
            'Station Manufacturing Facility'#13#10 +
            'THIS NEXT AREA IS THE ON-STATION PRODUCTION CENTER USED BY THE'#13#10; //
        2: Result :=
            'PRISONERS.  THIS WILL BE THE FIRST TEST OF YOUR TRUE SCAVENGING'#13#10 +
            'ABILITIES.  INSTEAD OF HAVING PRIMARY OR SECONDARY OBJECTS, YOU'#13#10 +
            'WILL HAVE TO REACH A SCORE OF 50000 BY FINDING RANDOM BONUS'#13#10 +
            'ITEMS AND KILLING NOPS.  THE KEYS TO SUCCEEDING HERE ARE SPEED,'#13#10; //
        else
          Result :=
            'ACCURACY, AND CONSERVATION OF YOUR RESOURCES.'#13#10; //
        end;

      4:
        case AStringNumber of
        0: Result :=
            'Sublevel 5:'#13#10 +
            'Water Purification Facility'#13#10 +
            'THE PRISON BILGE WAS OF NO INTEREST TO THE A.V.C. WHEN THE HUNT'#13#10 +
            'BEGAN, BUT AFTER ACCESSING THE ON-STATION COMPUTER WE FOUND'#13#10 +
            'STRANGE TRACE COMPOUNDS IN THE WATER TANKS.  THE UNIQUE CHEMICAL'#13#10; //
        1: Result :=
            'SIGNATURE IS THAT OF A PHLEGMATIC EEL--A RARE FRESH WATER'#13#10 +
            'CREATURE OF NON-GENE CLUSTER-VIRUS COMPOSITION.  IT IS A WORTHY'#13#10 +
            'FIND AND OF GREAT INTEREST TO A.V.C. RESEARCH.'#13#10; //
        else
          Result :=
            ' YOU ARE TO DRAIN THE PRISON WATER RESEVOIRS TO ACQUIRE THE EEL.'#13#10 +
            'SECONDARIES INCLUDE WATER AND OXYGEN TANKS.  THE POINT QUOTA FOR'#13#10 +
            'EXITING HAS BEEN SET AT 70,000.'#13#10 +
            ' WE ARE WITH YOU.'#13#10; //
        end;

      5:
        case AStringNumber of
        0: Result :=
            'Sublevel 6:'#13#10 +
            'Power Substation Alpha'#13#10 +
            ' THERE IS A POWER COUPLING THAT MAINTAINS A CYRO-RIDON FORCE'#13#10; //
        1: Result :=
            'FIELD THAT PREVENTS YOUR TRANSLATION INTO THE COMMAND CENTER. '#13#10 +
            'YOUR PRIMARY TARGET IS THE COUPLING ITSELF.  YOUR SECONDARY'#13#10 +
            'TARGETS ARE RAD-SHIELD GOGGLES AND VERIMAX INSULATED GLOVES'#13#10 +
            'LOCATED WITHIN THE POWER CHAMBERS AND STORAGE ROOMS.'#13#10 +
            ' IF YOU ACQUIRE THE COUPLING AND ACHIEVE A QUOTA OF 80,000'#13#10; //
        else
          Result :=
            'WE''LL MOVE YOU THROUGH TO THE NEXT SUBLEVEL.'#13#10 +
            ''#13#10; //
        end;

      6:
        case AStringNumber of
        0: Result :=
            'Sublevel 7:'#13#10 +
            'Maximum Security Detention Area'#13#10 +
            ' THIS HUNT IS ALMOST COMPLETE.  WE WOULD HAVE MOVED YOU ON INTO'#13#10 +
            'THE COMMAND CENTER BUT THE MISSION ARBITER DISCOVERED THAT THE'#13#10 +
            'ENTIRE POPULATION OF THE STATION HAD BEEN GENE-CODED AND THAT'#13#10; //
        1: Result :=
            'THE GENE CODING CUBE IS HIDDEN IN THIS AREA.  THE A.V.C.'#13#10 +
            'IS INTERESTED IN OBTAINING THE SAMPLES FOR MILITARY RESEARCH SO'#13#10 +
            'WE''RE SENDING YOU IN.  ACQUIRE THE GENE CODING CUBE AND A'#13#10; //
        else
          Result :=
            'POINT QUOTA OF 90,000 AND YOU EARN TRANSLATION TO THE FINAL'#13#10 +
            'SUBLEVEL.  PICK UP TRIBOLEK CUBES AND SPACE HEATERS AS'#13#10 +
            'SECONDARIES TO HELP REACH THE QUOTA.'#13#10; //
        end;

      7:
        case AStringNumber of
        0: Result :=
            'Sublevel 8:'#13#10 +
            'Primary Command Center'#13#10 +
            ' YOU HAVE ARRIVED.  THE BRASS RING OF BYZANT IS SOMEWHERE IN THE'#13#10 +
            'COMMAND CENTER.  IT IS UP TO YOU TO FIND IT AND BRING IT BACK.'#13#10 +
            'THERE IS A POWERFUL SHIELD AROUND THE RING, CONTROLLED BY THREE'#13#10 +
            'NEARBY POWER STATIONS.  EVEN MORE, EACH POWER STATION HAS ITS'#13#10; //
        1: Result :=
            'OWN SHIELD THAT IS CONTROLLED BY A SENTINAL GUARD.  SUMMON EACH'#13#10 +
            'SENTINAL AND DESTROY IT.  BY DESTROYING THE SENTINALS, YOU SHOULD'#13#10 +
            'DESTROY THE SHIELDS TO THE POWER STATIONS AS WELL.  STAND ON THE'#13#10 +
            'POWER CORES TO DISABLE THEM.  WHEN YOU FINALLY MAKE YOUR WAY TO'#13#10; //
        else
          Result :=
            'THE RING, BE PREPARED TO LEAVE IN A HURRY.  THERE IS STILL A'#13#10 +
            'QUOTA OF 150,000 POINTS, SO REACTOR COOLANT CONTAINERS AND'#13#10 +
            'POWER FLOW CALIBRATORS HAVE BEEN DESIGNATED AS SECONDARY POINT'#13#10 +
            'ITEMS.  YOUR DATE WITH TRUE GLORY AWAITS...DON''T BE LATE.'#13#10; //
        end;

(* TEMPLE *)

      8:
        case AStringNumber of
        0: Result :=
            'Sublevel 1:'#13#10 +
            'Outer Towers'#13#10 +
            'THIS WILL BE YOUR ENTRY POINT FOR THE CITY-TEMPLE.  YOUR FIRST'#13#10 +
            'TARGET WILL BE THE MOST HOLY INCANTATION BRAZIER.  BEFORE YOU CAN'#13#10; //
        1: Result :=
            'GET TO IT YOU''LL NEED TO BRING DOWN THE BARRIER GUARDING IT USING'#13#10 +
            'THE SWITCHES LOCATED IN THE TOWERS THROUGHOUT THE SUBLEVEL.'#13#10; //
        else
          Result :=
            'SECONDARY ITEMS WILL BE RITUAL CANDLES HIDDEN IN THE NOOKS AND'#13#10 +
            'CRANNIES OF THE TOWER.  ACQUIRE THE PRIMARY TARGET AND A POINT'#13#10 +
            'QUOTA OF 50,000 AND ON YOU''LL GO.'#13#10; //
        end;

      9:
        case AStringNumber of
        0: Result :=
            'Sublevel 2:'#13#10 +
            'Ritual Spires'#13#10 +
            'YOUR FIRST OBSTACLE FOR THIS AREA WILL BE GETTING BEYOND THE'#13#10 +
            'OUTER WALL INTO THE COURTYARD.  ONCE INSIDE YOU HAVE TO FIND A'#13#10 +
            'WAY INTO THE SPIRES THEMSELVES.  THERE ARE THREE SMALLER SPIRES'#13#10; //
        1: Result :=
            'AND ONE LARGER ONE WHICH HOUSES YOUR PRIMARY TARGET, THE IDOL OF'#13#10 +
            'THE FELASHA PONT.  SECONDARY ITEMS WILL BE PRAYER SCROLLS ON'#13#10 +
            'WHICH ARE WRITTEN SPECIAL IDTH RITUAL MANTRA''S.  THE A.V.C WANTS'#13#10 +
            'THE ICON AND SCROLLS TO RANSOM BACK TO THE IDTH FROM WHICH THEY'#13#10; //
        else
          Result :=
            'WERE TAKEN.'#13#10 +
            ' ACQUIRE THE PRIMARY AND A POINT QUOTA OF 55,000 AND WE''LL'#13#10 +
            'TRANSLATE YOU OUT.'#13#10; //
        end;

      10:
        case AStringNumber of
        0: Result :=
            'Sublevel 3:'#13#10 +
            'Temple Catacombs'#13#10 +
            'YOUR PRIMARY GOAL FOR THIS AREA IS THE BOOK OF CHANTS SINCE THE'#13#10 +
            'BOOK WAS CONSTRUCTED BY THE ANCIENT TRIBE-OF-NINE. ITS VALUE IS'#13#10 +
            'OBVIOUS.'#13#10; //
        1: Result :=
            ' SCANS OF THE CATACOMBS HAVE ALSO REVEALED THE PRESENCE OF A'#13#10 +
            'PRICELESS RARE INSECT KNOWN AS THE SILVER BEETLE.  BECAUSE OF'#13#10 +
            'THEIR WORTH THEY WILL MAKE EXCELLENT SECONDARY TARGETS.'#13#10; //
        else
          Result :=
            ' AFTER YOU HAVE ACQUIRED THE PRIMARY OBJECT AND YOUR POINT TOTAL'#13#10 +
            'MEETS OR EXCEEDS 60,000 WE''LL... EH... YOU KNOW THE ROUTINE.'#13#10; //
        end;

      11:
        case AStringNumber of
        0: Result :=
            'Sublevel 4:'#13#10 +
            'Training Grounds'#13#10 +
            ' AS WELL AS PREPARING THEMSLEVES PSYCHICALLY, THE ACOLYTES OF THE'#13#10 +
            'AKI-VORTELASH ORDER ARE GIVEN TO THE CARE AND TRAINING OF WAR'#13#10 +
            'SLUGS AS PART OF THEIR DISCIPLINE.  IT IS FOR THIS REASON THAT'#13#10 +
            'THE PRIESTHOOD COMBINED THE SLUG LARVA HOLDS AND THEIR MARTIAL'#13#10; //
        1: Result :=
            'TRAINING GROUNDS.  SECONDARY OBJECTS ARE THEREFORE WAR SLUG'#13#10 +
            'LARVAE AND SLUG FOOD.'#13#10 +
            'THE PRIMARY TARGET, HOWEVER, IS THE YRKTAREL''S'#13#10 +
            'SKULL SCEPTER.  YOU MUST KILL ALL OF THE HIGH PRIESTS IN THE OUTER'#13#10 +
            'COURTYARD IN ORDER TO ANGER YRKTAREL, CAUSING HIM TO APPEAR.'#13#10; //
        else
          Result :=
            'YOU MUST WREST THE STAFF FROM HIM.  IF YOU DO SO SUCCESSFULLY AND'#13#10 +
            'YOUR POINT TOTAL MEETS OR EXCEEDS 65,000, A TRANSLATION NEXUS'#13#10 +
            'WILL BE OPENED TO SEND YOU TO THE NEXT SUBLEVEL.'#13#10 +
            'GOD SPEED.'#13#10; //
        end;

      12:
        case AStringNumber of
        0: Result :=
            'Sublevel 5:'#13#10 +
            'Summoning Circles'#13#10 +
            ' DON''T THINK Y''ARK TAREL IS GONE--JUST MAD AND RESTING, SO DON''T'#13#10 +
            'DISTURB HIM OR YOU''LL PROBABLY LEARN A NEW MEANING OF HURT.'#13#10 +
            ' IN THIS AREA YOU WILL FIND 4 SUMMONING CHAMBERS WHICH THE'#13#10 +
            'PRIESTHOOD USES TO CONTROL VOID-FORCE AND THE IDTH DEMONS THEY'#13#10 +
            'SUMMON.  EACH CHAMBER IS PROTECTED BY A FORCE BARRIER.  THESE'#13#10; //
        1: Result :=
            'BARRIERS CAN ONLY BE PIERCED BY SPECIFIC FORCE KEYS.  YOU MUST'#13#10 +
            'FIND THE FOUR KEYS TO THE SUMMONING CHAMBERS, FOR ONLY THEN WILL'#13#10 +
            'THE FORCE BARRIERS FALL AND ALLOW YOU INTO THE CHAMBERS.  THE'#13#10 +
            'ACTUAL DESECRATION OF THE SUMMONING CIRCLES IS YOUR PRIMARY'#13#10; //
        else
          Result :=
            'OBJECTIVE.  THIS IS DONE MERELY BY THOROUGHLY STOMPING ON THEM.'#13#10 +
            'ONCE THIS IS DONE, IF YOUR POINT TOTAL MEETS OR EXCEEDS 70,000'#13#10 +
            'POINTS WE''LL MOVE YOU TO THE NEXT SUBLEVEL.'#13#10; //
        end;

      13:
        case AStringNumber of
        0: Result :=
            'Sublevel 6:'#13#10 +
            'Priest Village'#13#10 +
            'FOR THIS MISSION YOU WILL HUNT FOR THE SACRIFICIAL DAGGER OF'#13#10 +
            'SYDRUS.  IT IS HIDDEN IN AN OUTDOOR OFFERING SHRINE AND'#13#10; //
        1: Result :=
            'CAN ONLY BE REACHED AFTER YOU OPERATE AN INTRICATE SERIES OF'#13#10 +
            'GUARD SWITCHES.  ALL OF THESE ARE LOCATED IN THE PRIEST QUARTERS,'#13#10 +
            'SAVE FOR ONE WHICH WAS PLACED NEAR THE WATER ACCESS NEAR WHAT'#13#10; //
        else
          Result :=
            'WAS ONCE THE WAR SLUG KENNEL. SECONDARY GOAL ITEMS ARE CURED'#13#10 +
            'FINGER BONES AND PRIEST PAIN ANKHS.  MEET A POINT QUOTA OF'#13#10 +
            '85,000 AND SNATCH THE DAGGER AND WE''LL TRANSLATE YOU ONWARD.'#13#10; //
        end;

      14:
        case AStringNumber of
        0: Result :=
            'Sublevel 7:'#13#10 +
            'Vaults of Vortelash'#13#10 +
            ' THIS IS THE AQUEDUCT MAIN FOR THE ENTIRE CITY-TEMPLE.  A RIVER'#13#10 +
            'RUNS THROUGH IT.'#13#10 +
            ' THIS AREA CONTAINS THREE VAULTS, EACH HOLDING PRIZE GOLD'#13#10; //
        1: Result :=
            'INGOTS, ALL OF WHICH WILL BE YOUR SECONDARY TARGET ITEMS.  YOUR'#13#10 +
            'MAIN CONCERN, HOWEVER, IS THE SACRED COW KEPT WITHIN THE LARGEST'#13#10 +
            'OF THE VAULTS.  SNARE THE COW AND A POINT TOTAL OF 100,000'#13#10; //
        else
          Result :=
            'AND WE''LL TRANSLATE YOU OUT.'#13#10; //
        end;

      15:
        case AStringNumber of
        0: Result :=
            'Sublevel 8:'#13#10 +
            'Inner Sanctum'#13#10 +
            ' THIS IS IT.  THE A.V.C. SEEKS TO PROFIT FROM A DESTABILIZATION'#13#10 +
            'OF THE LOCAL SYSTEM POLITICS.  IN ORDER TO DO THIS IT IS YOUR'#13#10; //
        1: Result :=
            'MISSION TO ERADICATE THE SOUL OF THE PAGAN GOD THE PRIESTHOOD'#13#10 +
            'WORSHIPS.  IN ORDER TO DO SO YOU MUST GATHER THE FOUR SOUL ORBS'#13#10 +
            'AND BRING THEM TO THE STATUE FROM WHICH HE DRAWS HIS POWER.  BY'#13#10; //
        else
          Result :=
            'DOING SO YOU WILL SUMMON HIS TRUE SPIRIT, THAT IT MIGHT BE'#13#10 +
            'SLAIN...'#13#10 +
            '...PERMANANTLY.'#13#10; //
        end;

(* KAAL *)
      16:
        case AStringNumber of
        0: Result :=
            'Sublevel 1:'#13#10 +
            'Reception Area'#13#10 +
            ' BEFORE YOU CAN ENTER THE BASE ITSELF YOU MUST PASS THROUGH THE'#13#10 +
            'ENTRANCE AT THE FOOT OF THE MOUNTAIN.  PASS THE ENTRANCE GATE'#13#10; //
        1: Result :=
            'BETWEEN THE GLASS ENLOSURES AND THE INNER RECEPTION AREA. YOUR'#13#10 +
            'PRIMARY TARGET IS THE QUAI MUMMIFICATION GLYPH WHICH IS A'#13#10 +
            'VALUABLE PIECE OF ART FROM THE UNITY PERIOD. IT IS KEPT ATOP A'#13#10 +
            'COLUMN BEYOND THE RECEPTION AREA AND SHOULD BE EASY TO LOCATE.'#13#10; //
        else
          Result :=
            'TO LOWER THE PILLER, A SERIES OF SECURITY SWITCHES MUST BE SET,'#13#10 +
            'ONE OF WHICH IS IN THE SECURITY TOWER (IT''S UP TO YOU TO GET'#13#10 +
            'INSIDE.)'#13#10; //
        end;

      17:
        case AStringNumber of
        0: Result :=
            'Sublevel 2:'#13#10 +
            'Primary Resource Hold Zeta'#13#10 +
            ' WATCH YOUR BACK.  THIS AREA IS A MAZE OF CRATES AND SENTRY'#13#10 +
            'SPHERES ARE EVERYWHERE.  YOUR PRIMARY GOAL IS A SHIPMENT OF VIRAL'#13#10; //
        1: Result :=
            'STABALIZATION PODS, WHILE THE SECONDARY TARGET ITEMS ARE THE'#13#10 +
            'ACCOMPANYING DENATURED BIO-PROTEINS TO BE USED WITH THE VIRAL'#13#10; //
        else
          Result :=
            'PODS.  PROTEIN CONTAINERS ABOUND.  POINTS SHOULD BE NO PROBLEM'#13#10 +
            'HERE.  WHEN YOU''VE AQUIRED AT LEAST ONE PRIMARY AND A POINT QUOTA'#13#10 +
            'OF 70,000 WE''LL MOVE YOU TO THE NEXT AREA.'#13#10; //
        end;

      18:
        case AStringNumber of
        0: Result :=
            'Sublevel 3:'#13#10 +
            'The Hanger'#13#10 +
            ' THE A.V.C. HAS ACQUIRED INFORMATION WHICH SUGGESTS SECRET'#13#10 +
            'EXPERIMENTS WERE SECRETLY CONDUCTED ON THE JUMP BASE INVOLVING'#13#10 +
            'VOID-MATRIX TRANSLATION.  YOU ARE LOOKING FOR THE FISSURE-PRISM'#13#10; //
        1: Result :=
            'THEY HAD TO BE USING TO GENERATE THE TROJAN POINTS NECESSARY FOR'#13#10 +
            'SUCH EXPERIMENTS. SINCE THEY WOULDN''T HAVE HAD TIME TO MOVE IT'#13#10 +
            'FAR FROM THE JUNCTION IT MUST BE LOCATED SOMEWHERE IN THE HANGER.'#13#10 +
            'THE JUMP TROOPS KNOW YOU''RE COMING AND MAY HAVE HIDDEN. IF SO IT'#13#10; //
        else
          Result :=
            'COULD BE WELL GUARDED.'#13#10 +
            ' SECONDARY TARGETS ARE SHUNT MATRICES AND PLASMA COUPLINGS, THE'#13#10 +
            'OTHER TWO COMPONENTS FOR A VOID-TRANSLATION DEVICE.'#13#10 +
            ' GET YOURSELF 90,000 IN POINTS AND THE PRIMARY AND YOU''RE OUT'#13#10 +
            'OF THERE.  GOOD LUCK.'#13#10; //
        end;

      19:
        case AStringNumber of
        0: Result :=
            'Sublevel 4:'#13#10 +
            'Cybergenation Facility'#13#10 +
            ' IN THIS AREA YOU MUST ACQUIRE THE PSIFLEX DATA CUBE WHICH'#13#10 +
            'CONTAINS THE BIRTHING HISTORIES AND GENETIC SIGNATURES FOR HALF'#13#10; //
        1: Result :=
            'OF THE MILLION STRATEGIC SUBSENTIENT RACES KNOWN TO EXIST BY'#13#10 +
            'IMPERIAL SECRET SECURITY.  YOU WILL FIND IT MOUNTED TO THE'#13#10; //
        else
          Result :=
            'CONDUIT IN THE MIDDLE OF THE CONTROL CENTER.'#13#10 +
            ' POINT QUOTA IS 110,000.  GET THE PRIMARY TARGET AND THE QUOTA'#13#10 +
            'AND ON YOU GO.'#13#10; //
        end;

      20:
        case AStringNumber of
        0: Result :=
            'Sublevel 5:'#13#10 +
            'The Gauntlet (Trial Zone)'#13#10 +
            ' THIS TEST AREA IS FOR TRAINING THE KAAL JUMP TROOPS. THE PRIMARY'#13#10 +
            'GOAL IS A SINGLE SOYLENT BROWN NARCOTIC,  BUT TO ACQUIRE IT YOU'#13#10 +
            'MUST GAIN INFORMATION ON KAAL TROOP TRAINING TECHNIQUES BY'#13#10; //
        1: Result :=
            'RUNNING THEIR GAUNTLET (THE NARCOTIC IS A STANDARD PART OF THE'#13#10 +
            'KAAL TROOP REWARD SYSTEM.)'#13#10 +
            ' NO MAN-TROOPS ARE ON THIS LEVEL SINCE THOSE TROOPS WERE'#13#10; //
        else
          Result :=
            'SCRAMBLED DURING FULL ALERT DUE TO THE HUNT.  EXPECT RESISTANCE'#13#10 +
            'FROM SENTINALS.  QUOTA IS SET AT 50,000 POINTS.  GET THE PRIMARY'#13#10 +
            'AND QUOTA AND WE''LL TRANSLATE YOU TO THE FINAL AREA FOR THE'#13#10 +
            'GRAND TEST OF YOUR HUNTER''S SKILLS!'#13#10; //
        end;

      21:
        case AStringNumber of
        0: Result :=
            'Sublevel 6:'#13#10 +
            'Command Bunker'#13#10 +
            ' THIS IS IT.  THIS ONE COULD WIN YOU THE JACKPOT...#13#10'#13#10 +
            ' IT IS WELL KNOWN THAT THE KAAL CHANCELLOR''S POWER IS IN THE'#13#10 +
            'IMPERIAL SYGIL OF HIS POSITION.  TO POSSESS IT IS TO BE'#13#10 +
            'CHANCELLOR.  WHETHER BY FOOLISHNESS OR ARROGANCE THE CHANCELLOR'#13#10; //
        1: Result :=
            'HAS TAKEN TO REMOVING THE SYGIL FROM HIS PERSON AND LEAVING IT'#13#10 +
            'UNGUARDED.  THE SYGIL ITSELF IS ON A PEDESTAL BEYOND THE COMMAND'#13#10 +
            'BUNKER...  BEFORE YOU CAN ENTER THIS AREA YOU MUST FIND THE'#13#10 +
            'SECURITY KEY WHICH WILL ALLOW YOU TO ENTER HIS QUARTERS.'#13#10; //
        else
          Result :=
            ' RETRIEVE THE SYGIL AND THE A.V.C. WILL GRANT YOU FAME, FORTUNE'#13#10 +
            'AND YOUR FREEDOM...'#13#10 +
            '...FAIL, AND YOU''LL FIND YOUR BURNING ENTRAILS FALLING FROM HIGH'#13#10 +
            'ORBIT.'#13#10; //
        end;
    end;
  end
  else
  begin
    (* DEMO DATA *)

    case AMap of
      1:
        case AStringNumber of
        0: Result :=
            'LEVEL 2: PRIMARY HOLDING'#13#10 +
            'THIS SUBLEVEL SERVES AS THE SUPPLIES ENTRY POINT ON THE'#13#10 +
            'COLONY AS WELL AS THE INMATE FREEHOLD.'#13#10 +
            'THE PRIMARY OBJECT FOR THIS SUBLEVEL IS A DESARIAN SPACE'#13#10 +
            'GENERATOR WHICH HELPS POWER THE OUTER SHIELDING FOR THE'#13#10 +
            'RING.  SECONDARY TARGETS INCLUDE VIALS OF TRUTH SERUM'#13#10; //
        1: Result :=
            'AND HYPODERMIC NEEDLES USED DURING INMATE INTERROGATION.'#13#10 +
            'ONCE YOU''VE ACQUIRED THE PRIMARY GOAL AND YOUR POINT'#13#10 +
            'TOTAL MEETS OR EXCEEDS 55000 WE''LL OPEN A TRANSLATION'#13#10 +
            'NEXUS TO THE NEXT SUBLEVEL.'#13#10 +
            'OH, AND ONE LAST THING...'#13#10; //
        else
          Result :=
            '...DON''T TRIGGER THE AIRLOCKS IN THIS AREA UNLESS YOU'#13#10 +
            'WANT THE AIR RIPPED VIOLENTY FROM YOUR LUNGS.';
        end;

      2:
        case AStringNumber of
        0: Result :=
            'LEVEL 3: DETENTION FACILITY A'#13#10 +
            'THE RIOT IN THE COLONY HAS REACHED NEW HEIGHTS OF CHAOS.'#13#10 +
            'THE WARDEN''S QUARTERS HAVE BEEN BREACHED AND SUSEQUENTLY,'#13#10 +
            'HIS HEAD IS HIDDEN IN A JAR ON THIS SUBLEVEL.  THE A.V.C.'#13#10 +
            'IS INTERESTED IN REVIVING THE BRAIN SO IT HAS BECOME YOUR'#13#10; //
        1: Result :=
            'NEXT PRIMARY TARGET ITEM.  SECONDARIES INCLUDE LUBRICANTS'#13#10 +
            'AND EMERGENCY LANTERNS.'#13#10; //
        else
          Result :=
            'IF AFTER ACQUIRING THE PRIMARY ITEM YOUR POINT TOTAL MEETS'#13#10 +
            'OR EXCEEDS 60000 POINTS WE''LL OPEN A NEXUS AND TRANSLATE'#13#10 +
            'YOU TO THE PURIFICATION FACILITY.'#13#10 +
            'HAPPY HEAD HUNTING.';
        end;

      3:  // demo end
        case AStringNumber of
        0: Result :=
            'YOU HAVE PROVEN YOURSELF TO BE A FORMIDABLE HUNTER.'#13#10 +
            'KNOW THEN THAT YOU HAVE EARNED THE COVETED SECRET PHRASE:'#13#10 +
            'BLACK DOVE FRONT'#13#10 +
            'UTTER OR INSCRIBE THE SECRET PHRASE WHEN YOU ORDER THE'#13#10 +
            'FULL VERSION OF ''IN PURSUIT OF GREED'' DIRECTLY FROM'#13#10 +
            'SOFTDISK AND YOU''LL GET FREE SHIPPING!!  THE FULL GAME OF'#13#10 +
            '''IN PURSUIT OF GREED'' WILL SHIP IN EARLY JANUARY, SO GET'#13#10 +
            'YOUR COPY ON CD-ROM NOW, FOR JUST 39.95 US DOLLARS.'#13#10; //
        1: Result :=
            'CALL 1-800-831-2694 OR 1-318-221-8718 TO ORDER BY PHONE'#13#10 +
            'WITH A CREDIT CARD OR MAIL CHECK OR MONEY ORDER FOR 39.95'#13#10 +
            'TO: SOFTDISK PUBLISHING GREED DEMO OFFER #GDC115,'#13#10 +
            'P.O. BOX 30008. SHREVEPORT, LA 71130-0008'#13#10; //
        else
          Result :=
            'BE SURE TO MENTION THE SECRET PHRASE'#13#10 +
            'ALSO, BE SURE TO VISIT OUR INTERNET SITE AT'#13#10 +
            'HTTP://WWW.SOFTDISK.COM'#13#10 +
            'YOU CAN BE AS TWISTED AS YOU''VE ALWAYS WANTED TO BE!!'#13#10 +
            'WHAT ARE YOU WAITING FOR? CALL NOW!!'#13#10; //
        end;
    end;
  end;
end;

end.
