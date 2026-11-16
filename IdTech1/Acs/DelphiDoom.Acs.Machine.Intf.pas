{******************************************************************************}
{                                                                              }
{  DelphiDoom: ACS library - the contracts of the virtual machine              }
{  Port of the interpreter of Hexen (p_acs.c, Raven Software)                  }
{  Copyright (C) 1995 Raven Software, Corp.                                    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Acs.Machine.Intf;

interface

uses
  DelphiDoom.Acs.Machine.Types;

type
  /// <summary>
  ///   Everything that a script does to the game and everything that it asks of it. The machine
  ///   knows nothing else of the engine. Lines, activators and polyobjects are things of the
  ///   engine: the machine takes them from the script and gives them back, never looks into
  ///   them. A name that the host cannot resolve (a flat, a texture) is the host's business
  /// </summary>
  IAcsHost = interface
    ['{2E5B9C41-7D03-4A68-B1F4-93C8E60A57D2}']
    /// <summary>The tics in a second: an open script waits one second to start</summary>
    function TicsPerSecond: Integer;
    /// <summary>The map that is being played: a script for another map waits in the store</summary>
    function CurrentMap: Integer;
    function LevelTime: Integer;
    function GameType: TAcsGameType;
    function GameSkill: Integer;
    function PlayerCount: Integer;
    /// <summary>The next number of the random table of the game, 0..255</summary>
    function NextRandom: Integer;

    /// <summary>
    ///   A script that can run: a thinker with all zeroes in the part of the machine, which the
    ///   engine will give to Execute at every tic until ReleaseScript
    /// </summary>
    function AllocateScript: PAcsScript;
    /// <summary>The script ends: the thinker goes away</summary>
    procedure ReleaseScript(AScript: PAcsScript);

    /// <summary>
    ///   The special of a line, with the five arguments that the script gave. The arguments
    ///   after the fifth are the ones of the last special that was called
    /// </summary>
    procedure ExecuteLineSpecial(ASpecial: Integer; const AArguments: TAcsSpecialArguments;
      ALine, AActivator: Pointer; ASide: Integer);
    /// <summary>True if something is still moving a sector with the tag</summary>
    function IsTagBusy(ATag: Integer): Boolean;
    function IsPolyobjectBusy(APolyobject: Integer): Boolean;
    /// <summary>The floor or the ceiling of every sector with the tag takes the flat</summary>
    procedure ChangeSectorFlat(ATag: Integer; const AFlatName: string; AFloor: Boolean);
    /// <summary>
    ///   How many things of the type and with the tid (a type or a tid can be 0, not both).
    ///   Dead monsters are not counted
    /// </summary>
    function CountThings(AThingType, ATid: Integer): Integer;
    procedure SetLineTexture(ALineTag, ASide, APosition: Integer; const ATextureName: string);
    procedure SetLineBlocking(ALineTag: Integer; ABlocking: Boolean);
    procedure SetLineSpecial(ALineTag, ASpecial: Integer;
      const AArguments: TAcsLineSpecialArguments);
    procedure ClearLineSpecial(ALine: Pointer);

    /// <summary>A sound from the sector of the line (or from nowhere if there is no line)</summary>
    procedure PlaySectorSound(ALine: Pointer; const ASoundName: string; AVolume: Integer);
    /// <summary>The sound from every thing with the tid</summary>
    procedure PlayThingSound(ATid: Integer; const ASoundName: string; AVolume: Integer);
    procedure PlayAmbientSound(const ASoundName: string; AVolume: Integer);
    procedure StartSoundSequence(ALine: Pointer; const ASequenceName: string);

    /// <summary>The message goes to the player of the activator, or to the console player</summary>
    procedure ShowMessage(AActivator: Pointer; const AText: string);
    /// <summary>The message goes to every player that is in the game</summary>
    procedure ShowMessageToAll(const AText: string);
    /// <summary>A message for the console player: for the errors of a script that is missing</summary>
    procedure ShowConsoleMessage(const AText: string);
  end;

  /// <summary>
  ///   The virtual machine of the object code (BEHAVIOR) of a map: the scripts of the map, the
  ///   variables of the map and of the world and the store of the scripts for other maps
  /// </summary>
  IAcsMachine = interface
    ['{91C3E7A5-0B48-4D2F-8A16-D5F73B0C94E8}']
    /// <summary>
    ///   Takes the object code of a map: the table of the scripts, the strings and the variables
    ///   of the map (set to zero). The open scripts start, after one second. The memory stays
    ///   the caller's and has to stay there until the next Load. A wrong object code is not
    ///   loaded: the machine warns the log and has no scripts. Returns how many scripts it has
    /// </summary>
    function Load(ACode: PByte; ASize: Integer): Integer;
    /// <summary>The machine has no scripts</summary>
    procedure Unload;

    function GetScriptCount: Integer;
    function GetCodeBase: PByte;
    function GetScriptState(AIndex: Integer): TAcsScriptState;
    procedure SetScriptState(AIndex: Integer; AValue: TAcsScriptState);
    function GetScriptWaitValue(AIndex: Integer): Integer;
    procedure SetScriptWaitValue(AIndex: Integer; AValue: Integer);
    function GetMapVariables: TAcsMapVariables;
    procedure SetMapVariables(const AValue: TAcsMapVariables);
    function GetWorldVariables: TAcsWorldVariables;
    procedure SetWorldVariables(const AValue: TAcsWorldVariables);
    function GetStore: TAcsStore;
    procedure SetStore(const AValue: TAcsStore);

    /// <summary>How many scripts the object code has</summary>
    property ScriptCount: Integer read GetScriptCount;
    /// <summary>Where the object code is: the script that runs has its address from here</summary>
    property CodeBase: PByte read GetCodeBase;
    property ScriptState[AIndex: Integer]: TAcsScriptState read GetScriptState
      write SetScriptState;
    property ScriptWaitValue[AIndex: Integer]: Integer read GetScriptWaitValue
      write SetScriptWaitValue;
    property MapVariables: TAcsMapVariables read GetMapVariables write SetMapVariables;
    property WorldVariables: TAcsWorldVariables read GetWorldVariables write SetWorldVariables;
    property Store: TAcsStore read GetStore write SetStore;

    /// <summary>
    ///   Starts a script. A script for another map goes to the store (false if it is there
    ///   already); a script that is suspended goes on; one that runs already or that does not
    ///   exist gives false. Raises EAcsMachineException if the store is full
    /// </summary>
    function StartScript(ANumber, AMap: Integer; const AArguments: TAcsArguments;
      AActivator, ALine: Pointer; ASide: Integer): Boolean;
    function SuspendScript(ANumber: Integer): Boolean;
    function TerminateScript(ANumber: Integer): Boolean;
    /// <summary>Starts the scripts of the store that belong to the map that is being played</summary>
    procedure CheckStore;
    /// <summary>A new game: no variables of the world and an empty store</summary>
    procedure InitNewGame;
    /// <summary>A sector with the tag stopped moving: the scripts that wait for it can go on</summary>
    procedure TagFinished(ATag: Integer);
    procedure PolyobjectFinished(APolyobject: Integer);
    /// <summary>
    ///   One tic of a script: the commands up to the first delay, wait, suspend or end. The
    ///   engine calls it from the thinker of the script
    /// </summary>
    procedure Execute(AScript: PAcsScript);
  end;

implementation

end.
