{******************************************************************************}
{                                                                              }
{  DelphiDoom: ActorDef library - the contracts                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ActorDef.Intf;

interface

uses
  DelphiDoom.ActorDef.Types;

type
  /// <summary>The words of flags that the engine knows, one list for each category</summary>
  IActorDefFlagCatalog = interface
    ['{5D21B7C0-3F44-4E9A-8A71-0C6E94B2D1F3}']
    /// <summary>The names as the engine has them (MF_SOLID, MF_EX_FLOATBOB...)</summary>
    function Flags(ACategory: TActorDefFlagCategory): TArray<string>;
  end;

  /// <summary>The numbers and the names that the engine gives to the words of a definition</summary>
  IActorDefNameCatalog = interface
    ['{A93C61E8-70D5-4B12-9E4F-2B8D5C7A3016}']
    /// <summary>The number of a weapon by its name (or its number as a text); negative if it is not one</summary>
    function WeaponType(const AName: string): Integer;
    /// <summary>The number of an ammo (a mana in Hexen); negative if it is not one</summary>
    function AmmoType(const AName: string): Integer;
    /// <summary>The number of a class of the player (Hexen only); negative if it is not one</summary>
    function PlayerClass(const AName: string): Integer;
    /// <summary>The word of the engine for a render style written in a definition</summary>
    function RenderStyleToken(const AName: string): string;
    /// <summary>The word of the engine for a gender written in a definition</summary>
    function GenderName(const AName: string): string;
  end;

  /// <summary>The actors that are already in the engine: the ones that a definition inherits from or replaces</summary>
  IActorDefActorCatalog = interface
    ['{2E8B40D7-95A3-4C1F-B6D2-7A0F3E91C584}']
    /// <summary>
    ///   Looks an actor up by name (also by number or alias). The actor that comes back has the
    ///   values that an actor inherits: the numbers, the sounds, the flags as lists of words
    ///   (MF_ prefix included), the states as ACTORDEF_ORIGINAL_STATE_MARKER plus the state,
    ///   StatesDefined for the labels that exist; plus its Name and its DoomedNum
    /// </summary>
    function Find(const AName: string; out AIndex: Integer; out AActor: TActorDefActor): Boolean;
    /// <summary>The name of the actor of the engine with that number</summary>
    function NameOf(AIndex: Integer): string;
    /// <summary>Gives a second name to an actor; false if the first one is not an actor</summary>
    function AddAlias(const AName, AOtherName: string): Boolean;
  end;

  /// <summary>The names of the states that the engine knows (the old statenames list)</summary>
  IActorDefStateCatalog = interface
    ['{C4F7A2D9-18B6-4E03-A5D1-93E6B0287F4A}']
    /// <summary>The number of the state that has that name (some states have more than one); -1 if there is none</summary>
    function IndexOfToken(const AToken: string): Integer;
    /// <summary>A line of names: the first is the name of the state, the others (after a comma) are aliases</summary>
    procedure Add(const AEntry: string);
  end;

  /// <summary>Gives the engine the actors and the weapons as the definition ends</summary>
  IActorDefDefinitionSink = interface
    ['{7B05E3A1-D62C-4F98-8E37-A1C94D5B20F6}']
    procedure SubmitActor(const AActor: TActorDefActor);
    procedure SubmitWeapon(const AWeapon: TActorDefWeapon);
  end;

  /// <summary>Takes the thinkers: the engine writes each one as an actor and gives it back to the parser</summary>
  IActorDefThinkerSink = interface
    ['{E19D58B6-4A20-47C3-9F85-6D3B7C0A12E4}']
    procedure SubmitThinker(const AThinker: TActorDefThinker);
  end;

  /// <summary>The scripts and the patches that a definition names</summary>
  IActorDefScriptSink = interface
    ['{3A6F9C84-B1E7-4D50-82A3-F0D14E7B95C2}']
    procedure AddSourceScript(const AName, ASource: string; AType: TActorDefScriptType);
    /// <summary>A script that is in a file</summary>
    procedure AddExternalScript(const AName, AFileName: string; AType: TActorDefScriptType);
    procedure AddCompiledScript(const AName, AFileName: string);
    /// <summary>A patch (DEH) in a file</summary>
    procedure ParseDehFile(const AFileName: string);
    /// <summary>The patches in all the files of that name</summary>
    procedure ParseAllDehFiles(const AFileName: string);
  end;

  /// <summary>Prepares the text before it is read: includes, defines, directives</summary>
  IActorDefTextPreprocessor = interface
    ['{B8D2640F-9E71-43A5-A0C6-5F17E3D984B2}']
    function Process(const AText: string): string;
  end;

  /// <summary>Reads the text of an ACTORDEF or DECORATE lump</summary>
  IActorDefParser = interface
    ['{F46A1D73-2C90-4B8E-97D5-0E8A53C1B6D9}']
    /// <summary>
    ///   Reads the text and gives each thing to the sinks as soon as it ends; the sinks of the
    ///   engine apply it at once, so that the next definition finds it. A text can be parsed
    ///   while another is: the thinkers do it
    /// </summary>
    procedure Parse(const AText: string);
  end;

  /// <summary>Takes the text of a patch (DEH) that says what a definition means for the engine</summary>
  IActorDefDehConsumer = interface
    ['{19C7E5B2-D3A8-4F60-B417-8A2D90E6F5C3}']
    procedure ParseText(const AText: string);
  end;

  /// <summary>The sounds of the definitions: a name or an alias of SNDINFO to the name of a lump</summary>
  IActorDefSoundResolver = interface
    ['{84E0B1D5-6F29-4A73-AC9E-D5370F82B164}']
    /// <summary>The name of the lump of a sound; '0' if there is none</summary>
    function Resolve(const ASound: string): string;
  end;

  /// <summary>The names of SNDINFO: the resolver, with the aliases that fill it</summary>
  IActorDefSoundAliasTable = interface(IActorDefSoundResolver)
    ['{0B5E27C9-A1D4-4F38-8C60-3D9F7E4A15B2}']
    procedure Add(const AName, AValue: string);
    /// <summary>The lines NAME=VALUE, in the order in which they were added</summary>
    function Lines: TArray<string>;
  end;

  /// <summary>What the engine does with the lines of SNDINFO that are not sounds (Hexen)</summary>
  IActorDefSoundInfoListener = interface
    ['{D3A9F702-58C1-4E64-B0D7-26E1A4C98B53}']
    /// <summary>$MAP: the song of a map; the number is positive, the engine checks the other end</summary>
    procedure SongForMap(AMapId: Integer; const ASongName: string);
    /// <summary>A line of SNDINFO that gives a name to a sound (the tags of the sounds of the game)</summary>
    procedure AliasDeclared(const AName, AValue: string);
  end;

implementation

end.
