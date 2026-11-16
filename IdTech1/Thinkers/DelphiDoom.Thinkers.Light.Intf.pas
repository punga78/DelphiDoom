{******************************************************************************}
{                                                                              }
{  DelphiDoom: thinkers library - the contracts of the lights                  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Thinkers.Light.Intf;

interface

uses
  DelphiDoom.MathCore.Intf;

type
  /// <summary>
  ///   The part of a sector that the lights need when they are made: its light level, its special
  ///   and the sectors that touch it. It is not used while the lights run (they get the light
  ///   level as a variable), so a sector can be wrapped when it is needed
  /// </summary>
  /// <remarks>
  ///   The light level and the special are 16 bit in the engine: a value that does not fit is
  ///   truncated by the sector, and what is read back is what the sector kept
  /// </remarks>
  ILightSector = interface
    ['{4E7A1C93-5B28-4D60-9F13-A8C2E65D0B71}']
    function GetLightLevel: Integer;
    procedure SetLightLevel(AValue: Integer);
    function GetSpecial: Integer;
    procedure SetSpecial(AValue: Integer);
    function GetNeighborCount: Integer;
    function GetNeighbor(AIndex: Integer): ILightSector;
    function GetHandle: Pointer;
    /// <summary>The light level of the sector</summary>
    property LightLevel: Integer read GetLightLevel write SetLightLevel;
    /// <summary>The special (type) of the sector</summary>
    property Special: Integer read GetSpecial write SetSpecial;
    /// <summary>
    ///   How many lines the sector has: a neighbor is asked for each one, and a line that has no
    ///   sector on its other side gives nil
    /// </summary>
    property NeighborCount: Integer read GetNeighborCount;
    /// <summary>The sector on the other side of the line AIndex, or nil</summary>
    property Neighbors[AIndex: Integer]: ILightSector read GetNeighbor;
    /// <summary>What the host uses to find its own sector again; the library never looks at it</summary>
    property Handle: Pointer read GetHandle;
  end;

  /// <summary>
  ///   What changes between games in the fire flicker (the flicker of the lights of fire and of the
  ///   torches). Doom and Heretic flicker one way, Strife another
  /// </summary>
  ILightFlickerRules = interface
    ['{B3D96E04-7A5C-4F18-8E21-6C0F9A47D5E3}']
    /// <summary>How much darker than the maximum the light goes this time (may use the random)</summary>
    function NextAmount(const ARandom: IGameRandom): Integer;
    /// <summary>How many tics until the next change (may use the random)</summary>
    function NextCount(const ARandom: IGameRandom): Integer;
    /// <summary>The tics until the first change of a light that was just made</summary>
    function InitialCount: Integer;
    /// <summary>The darkest level of a light that was just made</summary>
    function InitialMinLight(ASectorLightLevel, ALowestSurrounding: Integer): Integer;
  end;

  /// <summary>Makes the thinker of one phased light: the host decides how a light is stored</summary>
  ILightPhaseSpawner = interface
    ['{7C25F8A1-0D4E-49B6-B3A7-1E58D9C02F64}']
    /// <param name="ABase">The base light level of the phase</param>
    /// <param name="AIndex">The first step of the phase, or -1 to take it from the light level</param>
    procedure SpawnPhased(const ASector: ILightSector; ABase, AIndex: Integer);
  end;

implementation

end.
