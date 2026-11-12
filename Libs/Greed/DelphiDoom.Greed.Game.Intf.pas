{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - what the parts of the game ask of each other     }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): the calls between           }
{  raven.pas, spawn.pas, sprites.pas, event.pas, utils.pas and modplay.pas      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.Game.Intf;

interface

uses
  DelphiDoom.Greed.Types;

type
  /// <summary>SpawnSprite and DemandLoadMonster of spawn.pas</summary>
  IGreedSpawner = interface
    ['{0B6E1F53-9C2A-47D8-A5E4-31F7C08D6B92}']
    /// <summary>
    ///   SpawnSprite(value, x, y, z, zadj, angle, angle2, active, spawnid): makes what the value says (a sprite, an
    ///   elevator, a door, a spawn area ...). Returns the index of the new sprite in the pool of the sprites, or
    ///   GREED_POOL_NIL where the original returns nil
    /// </summary>
    function SpawnSprite(AValue: Integer; AX, AY, AZ, AZAdjust: TGreedFixed; AAngle, AAngle2: Integer;
      AActive: Boolean; ASpawnId: Integer): Integer;
    /// <summary>DemandLoadMonster(lump, num): the pictures of a monster are asked for before they are drawn</summary>
    procedure DemandLoadMonster(ALump, ACount: Integer);
  end;

  /// <summary>SoundEffect of modplay.pas: a sound of the world, heard from where the player is</summary>
  IGreedGameSound = interface
    ['{6D4A8E19-3F70-4B25-9E1C-A2B5D7046C38}']
    /// <summary>SoundEffect(n, variation, x, y): one of the GREED_SN_ sounds at a place of the map</summary>
    procedure SoundEffect(ASound, AVariation: Integer; AX, AY: TGreedFixed);
  end;

  /// <summary>RunEvent of event.pas: the scripts of the map</summary>
  IGreedEventRunner = interface
    ['{C3F9A0D4-5E17-4682-B0A9-7D4E2C15F86A}']
    /// <summary>RunEvent(eval, netsend); the net is not ported, ANetSend is kept for the order of the calls</summary>
    procedure RunEvent(AEvent: Integer; ANetSend: Boolean);
  end;

  /// <summary>writemsg of d_font.pas: the line of text that the game shows to the player for a while</summary>
  IGreedMessages = interface
    ['{84B2D6F1-A03C-4E79-8D52-F1C6093E7AB4}']
    procedure WriteMessage(const AText: string);
  end;

  /// <summary>hurt, heal, medpaks and addscore of utils.pas, on the player of the game</summary>
  IGreedPlayerHealth = interface
    ['{F15C7B82-D946-40A3-B7E8-2A6D9C1E0F47}']
    procedure Hurt(AAmount: Integer);
    procedure Heal(AAmount: Integer);
    procedure MedPaks(AAmount: Integer);
    procedure AddScore(AAmount: Integer);
  end;

  /// <summary>KillSprite of utils.pas</summary>
  IGreedSpriteKiller = interface
    ['{29E0C6A7-71B4-4D3F-8C95-E6A1F3B80D52}']
    /// <summary>KillSprite(sp, weapon): ASprite is the index in the pool of the sprites</summary>
    procedure KillSprite(ASprite, AWeapon: Integer);
  end;

implementation

end.
