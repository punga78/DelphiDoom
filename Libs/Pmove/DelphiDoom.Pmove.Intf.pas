{******************************************************************************}
{                                                                              }
{  DelphiDoom: pmove library - the player movement of Quake III Arena:         }
{  contracts                                                                   }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): bg_public.h.    }
{  Copyright (C) 1999-2005 Id Software, Inc. This unit is derived from the     }
{  Quake III Arena source code and is therefore available under the GNU        }
{  General Public License, version 2 or (at your option) any later version.    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Pmove.Intf;

interface

uses
  System.SysUtils, DelphiDoom.Collision.Q3.Types, DelphiDoom.Net.Q3.Types, DelphiDoom.Pmove.Types;

type
  /// <summary>
  ///   What the movement asks of the world: the two callbacks of pmove_t (pm->trace and pm->pointcontents).
  ///   The game gives the collision of the map plus the entities (the server and the client game differ); the
  ///   tests give a made up world. The entity number of a hit is part of the answer (ENTITYNUM_WORLD for the
  ///   map, ENTITYNUM_NONE when nothing was hit)
  /// </summary>
  IPmoveTrace = interface
    ['{7D1B3C58-2E4A-4F96-8B07-C5A91E3D6F24}']
    /// <summary>trap_Trace: a box swept from AStart to AEnd, AEntityToSkip is the player</summary>
    function Trace(const AStart, AMins, AMaxs, AEnd: TQ3Vec3; const AEntityToSkip, AContentMask: Integer): TQ3Trace;
    /// <summary>trap_PointContents: the contents of a point, ignoring the entity AEntityToSkip</summary>
    function PointContents(const APoint: TQ3Vec3; const AEntityToSkip: Integer): Integer;
  end;

  /// <summary>
  ///   bg_itemlist[index].giTag: PM_Weapon reads the tag of the holdable item in the stats of the player
  ///   (medkit, teleporter ...). The list belongs to the game (a mod can have another one)
  /// </summary>
  IPmoveItemCatalog = interface
    ['{2F6A9D14-B83E-4C70-A5D2-19E8F4B07C36}']
    /// <summary>giTag of the item AIndex; 0 for an index that is not in the list</summary>
    function GameTag(const AIndex: Integer): Integer;
  end;

  /// <summary>One way to move (air, water ...): a step of it on the state of the mover</summary>
  IPmoveMovement = interface
    ['{5C9E27B1-84D3-4A06-B1F8-3A6D0E92C715}']
    procedure Move;
  end;

  /// <summary>The movement in water, which also has the water jump on its own (the flag that makes it last)</summary>
  IPmoveWaterMovement = interface(IPmoveMovement)
    ['{E30B8A57-1C64-4D92-A7F5-9B2D6C40E813}']
    /// <summary>PM_WaterJumpMove: flying out of the water, no control but it falls</summary>
    procedure WaterJumpMove;
  end;

  /// <summary>The movement of one player: Pmove of bg_pmove.c with its state in the object instead of globals</summary>
  IPmove = interface
    ['{A4E83B60-5D17-4C29-96F2-0B7D1C8A3E95}']
    function GetCounter: Integer;
    /// <summary>
    ///   Pmove: the player state and the command in APmove give the next player state and the results; the
    ///   command is cut in steps of 66 msec (or of PmoveMsec when PmoveFixed is set). Raises EPmoveException
    ///   when PmoveFixed is set with a PmoveMsec under 1 (the original loops for ever)
    /// </summary>
    procedure Execute(var APmove: TPmove);
    /// <summary>PM_UpdateViewAngles: only the view angles of the state, from the command</summary>
    procedure UpdateViewAngles(var APlayerState: TQ3PlayerState; const ACommand: TQ3UserCmd);
    /// <summary>c_pmove: the number of single steps done by this mover</summary>
    property Counter: Integer read GetCounter;
  end;

implementation

end.
