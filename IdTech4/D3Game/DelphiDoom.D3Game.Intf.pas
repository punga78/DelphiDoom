{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 game library - what the game asks of the rest of the     }
{  engine                                                                      }
{                                                                              }
{  The services that the C++ game reaches through globals (gameLocal's         }
{  Printf, declManager, program, idEvent, g_skill...) are small interfaces     }
{  here. Nothing in this unit is a port of one file of the original.           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.D3Game.Intf;

interface

uses
  DelphiDoom.Scanner.IdDict, DelphiDoom.DoomScript.Types, DelphiDoom.DoomScript.EventDef;

type
  /// <summary>
  ///   The output of the game: <c>idGameLocal::Printf</c>, <c>Warning</c> and the message of <c>Error</c>. The text is
  ///   already formatted (it ends in a line feed where the original's does). <c>Error</c> only reports: the game
  ///   raises <c>ED3GameException</c> itself, as <c>common->Error</c> does not return.
  /// </summary>
  ID3GamePrinter = interface
    ['{5B7C2E10-93A4-4D18-A6F5-0C81D3E7B942}']
    procedure Printf(const AText: AnsiString);
    procedure Warning(const AText: AnsiString);
    procedure Error(const AText: AnsiString);
  end;

  /// <summary>An <c>idDeclEntityDef</c>: the name, the index in the declaration table and the dictionary of defaults</summary>
  ID3EntityDef = interface
    ['{E3A19D54-27C0-4B6A-8F31-D5B0A7C2E968}']
    function GetName: AnsiString;
    function GetIndex: Integer;
    function GetDict: TIdDict;
  end;

  /// <summary><c>declManager->FindType( DECL_ENTITYDEF, ... )</c> and <c>DeclByIndex</c></summary>
  ID3EntityDefs = interface
    ['{0C58B7E2-4D19-48F3-A2D6-91E4B30C7A85}']
    /// <summary>The entityDef of that name (case-insensitive) or nil; never makes a default</summary>
    function FindEntityDef(const AName: AnsiString): ID3EntityDef;
    function FindEntityDefByIndex(const AIndex: Integer): ID3EntityDef;
  end;

  /// <summary>
  ///   The script functions that an entityDef can name in <c>spawnfunc</c>: <c>program.FindFunction</c> and a new thread
  ///   with <c>DelayedStart( 0 )</c>
  /// </summary>
  ID3SpawnFunctions = interface
    ['{9D2F6A83-1E57-4C04-B8A9-3F7C50D1E264}']
    /// <summary>False if the program has no such function</summary>
    function StartSpawnFunction(const AName: AnsiString): Boolean;
  end;

  /// <summary><c>gameLocal.program.SetEntity( name, ent )</c>: the entity a <c>$name</c> of a script stands for</summary>
  ID3ScriptNames = interface
    ['{47E81C09-B2D6-4F35-9A70-6C13E8D5A2F1}']
    /// <summary>The number of the entity, or -1 (<c>NULL</c>) to take the name away</summary>
    procedure SetEntity(const AName: AnsiString; const AEntityNumber: Integer);
  end;

  /// <summary>The entities of the map file, as <c>idMapFile::GetEntity( i )->epairs</c></summary>
  ID3MapSource = interface
    ['{B1F40D76-5A82-4E93-8C2B-07D9E6A31F58}']
    function GetNumEntities: Integer;
    function GetEntityEpairs(const AIndex: Integer): TIdDict;
  end;

  /// <summary>The cvars the game reads</summary>
  ID3GameSettings = interface
    ['{6A93E5C1-0D47-4B28-B15F-C8E2A7D9304B}']
    /// <summary>g_skill</summary>
    function GetSkill: Integer;
    /// <summary>gameLocal.isMultiplayer</summary>
    function GetIsMultiplayer: Boolean;
    /// <summary>g_cinematic</summary>
    function GetCinematicEnabled: Boolean;
  end;

  /// <summary>
  ///   What the map set-up calls that this phase does not port: <c>SetSkill</c>, <c>CacheDictionaryMedia</c>,
  ///   <c>SpreadLocations</c>, <c>RandomizeInitialSpawns</c>, the <c>r_skipSpecular</c> cvar and
  ///   <c>idEvent::ServiceEvents</c> (which runs the main script of the map)
  /// </summary>
  ID3MapSteps = interface
    ['{D40B7F92-83E1-4C65-A09D-1B52C6E8F37A}']
    procedure SetSkill(const ASkill: Integer);
    procedure CacheDictionaryMedia(const ADict: TIdDict);
    procedure SpreadLocations;
    procedure RandomizeInitialSpawns;
    procedure SetSkipSpecular(const AValue: Boolean);
    procedure ServiceEvents;
  end;

  /// <summary>
  ///   Who wants to know when an entity enters or leaves the table of the game (the script system keeps its own table of
  ///   the entities that a script can name; the original had one table, <c>gameLocal.entities</c>)
  /// </summary>
  ID3EntityObserver = interface
    ['{3C91E7A8-5D06-4B2F-A4E3-8B07F15C92D6}']
    /// <summary>The entity has its number and spawn id; it has no name yet</summary>
    procedure EntityRegistered(const AEntity: TObject; const AEntityNumber: Integer);
    /// <summary>The entity is leaving the table (the number is still its own)</summary>
    procedure EntityUnregistered(const AEntityNumber: Integer);
  end;

  /// <summary><c>idEvent::CancelEvents( this )</c> of the destructor of <c>idClass</c></summary>
  ID3EventCanceller = interface
    ['{28C6A1E5-7F03-4D9B-B4E8-A5D1930C72F6}']
    procedure CancelEvents(const AObject: TObject);
  end;

  /// <summary><c>idClass::PostEventMS</c> (used by the <c>remove</c> event of <c>idClass</c>)</summary>
  ID3EventPoster = interface
    ['{F7054B38-C19E-4A62-83D7-52E0A6B91C4D}']
    procedure PostEventMS(const AObject: TObject; const AEvent: TDoomScriptEventDef; const ATime: Integer);
  end;

implementation

end.
