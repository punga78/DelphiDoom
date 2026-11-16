{******************************************************************************}
{                                                                              }
{  DelphiDoom: thinkers library - the contracts of the vertical doors          }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Thinkers.Door.Intf;

interface

uses
  DelphiDoom.Thinkers.Door.Types;

type
  /// <summary>
  ///   Moves the ceiling of a sector (T_MovePlane of the classic doors, TH_MovePlane of the
  ///   scripted ones). The sector is a handle that only the engine understands
  /// </summary>
  IDoorPlaneMover = interface
    ['{2D8F4A61-93B7-4E05-A1C8-5F6E0B7D3924}']
    /// <param name="AFloorOrCeiling">1 moves the ceiling, 0 the floor</param>
    function MovePlane(ASector: Pointer; ASpeed, ADestination: Integer; ACrush: Boolean;
      AFloorOrCeiling, ADirection: Integer): TDoorPlaneResult;
  end;

  /// <summary>Plays and stops the sounds of a door, at the sound origin of its sector</summary>
  IDoorSounds = interface
    ['{6B1E93C7-48DA-4F52-8E0D-C3A7195F6B48}']
    /// <param name="AState">The door as it is: Strife keeps the sounds in it</param>
    procedure Play(ASector: Pointer; ASound: TDoorSound; const AState: TDoorState);
    procedure Stop(ASector: Pointer);
  end;

  /// <summary>What a new door asks about the sectors around its own</summary>
  IDoorSectorQueries = interface
    ['{F4A2D86B-1C93-47E5-B07A-9E3D58C1A6F2}']
    function LowestCeilingSurrounding(ASector: Pointer): Integer;
    function LowestFloorSurrounding(ASector: Pointer): Integer;
    function HighestFloorSurrounding(ASector: Pointer): Integer;
  end;

  /// <summary>The options of the game that change how a door behaves</summary>
  IDoorOptions = interface
    ['{A93C7E15-D260-4B8F-9C41-72E5B08D3F6A}']
    /// <summary>The game runs as the original: the doors do not touch the lights</summary>
    function GetCompatibilityMode: Boolean;
    property CompatibilityMode: Boolean read GetCompatibilityMode;
  end;

  /// <summary>Runs one tic of a door</summary>
  IDoorRunner = interface
    ['{3E6D1B94-7A52-4C08-B8F3-D1A94C5E7B20}']
    /// <summary>
    ///   One tic. The state is changed in place and the outcome tells what the engine has to do
    ///   (free the door, switch lights). The sounds and the movement of the ceiling are done
    ///   here, through the services the runner was given
    /// </summary>
    /// <param name="ASector">The sector of the door (the engine's handle)</param>
    /// <param name="AFloorHeight">The floor of the sector: where a closing door stops</param>
    function Tick(var AState: TDoorState; ASector: Pointer; AFloorHeight: Integer): TDoorTickOutcome;
  end;

  /// <summary>Makes the state of a new door, in the same way for every game</summary>
  IDoorSpawner = interface
    ['{C81F5A37-0E9B-4D62-A7C4-6B2D9E083F15}']
    /// <summary>
    ///   A door for a sector found by tag (EV_DoDoor, EVH_DoDoor): sets the direction, the top
    ///   and the speed of the kind and plays its sound
    /// </summary>
    function SpawnTagged(ASector: Pointer; ACeilingHeight: Integer; AKind: TDoorKind;
      const AInput: TDoorSpawnInput): TDoorState;
    /// <summary>
    ///   A door opened by hand (EV_VerticalDoor, EVH_VerticalDoor): the special of the line says the
    ///   kind and the sound. AConsumeSpecial tells that the engine has to clear the special of the line
    /// </summary>
    function SpawnManual(ASector: Pointer; ASpecial: Integer; const AInput: TDoorSpawnInput;
      out AConsumeSpecial: Boolean): TDoorState;
    /// <summary>The door of a sector that closes after 30 seconds (P_SpawnDoorCloseIn30)</summary>
    function CloseInThirtySeconds: TDoorState;
    /// <summary>The door of a sector that opens after 5 minutes (P_SpawnDoorRaiseIn5Mins)</summary>
    function RaiseInFiveMinutes(ASector: Pointer): TDoorState;
    /// <summary>
    ///   A line is used again on a sector whose door is working. Gives false when the special
    ///   does not touch a working door (the engine makes a new one); otherwise AAction says what to
    ///   do with it
    /// </summary>
    function Retrigger(ASpecial, ADirection: Integer; AThingIsPlayer: Boolean;
      out AAction: TDoorRetrigger): Boolean;
  end;

implementation

end.
