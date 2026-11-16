{******************************************************************************}
{                                                                              }
{  DelphiDoom: dynamic lights library - the contracts                         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.DynLights.Intf;

interface

uses
  DelphiDoom.GameState.Intf, DelphiDoom.DynLights.Types;

type
  /// <summary>The random numbers of the lights (the old C_Random with its own index)</summary>
  IDynLightRandom = interface
    ['{3A8E5C17-D492-4B60-9F1A-C70B2E6D8431}']
    /// <summary>0..255</summary>
    function NextByte: Integer;
  end;

  /// <summary>The number of a thing type of the game by its name</summary>
  IDynLightObjectResolver = interface
    ['{91C4F6A2-0B83-47D5-AE19-5D3F8C20B764}']
    /// <param name="AUpperName">The name in upper case</param>
    /// <returns>The number, or a negative one if the game has no such thing</returns>
    function ObjectForName(const AUpperName: string): Integer;
  end;

  /// <summary>The number of a sprite of the game by its four letters</summary>
  IDynLightSpriteResolver = interface
    ['{E7B30D58-A1C9-4F42-8B66-2C94F1D07A35}']
    /// <param name="AUpperName">Four letters in upper case</param>
    /// <returns>The number, or a negative one if the game has no such sprite</returns>
    function SpriteForName(const AUpperName: string): Integer;
  end;

  /// <summary>
  ///   The states of the game as the lights need them. The engine implements it over its table
  ///   of states, which keeps the lights of each state as a list of (object, light) pairs
  /// </summary>
  IDynLightStateTable = interface
    ['{5D2A9E80-73F6-4C1B-A08D-B4E619C7F352}']
    function StateCount: Integer;
    function SpriteOf(AState: Integer): Integer;
    /// <summary>The frame without the flags (the full bright bit...)</summary>
    function FrameOf(AState: Integer): Integer;
    /// <summary>The states that an object goes through; none if it has none or if it is unknown (-1)</summary>
    function StatesOfObject(AObject: Integer): TArray<Integer>;
    function HasLights(AState: Integer): Boolean;
    procedure CreateLights(AState: Integer);
    /// <summary>Takes away the lights that were bound to that object</summary>
    procedure RemoveLightsOfObject(AState, AObject: Integer);
    procedure AddLight(AState, AObject, ALight: Integer);
  end;

  /// <summary>Binds a light to the states of a sprite (a "frame" line of the lump)</summary>
  IDynLightBinder = interface
    ['{C08F3B74-2E5A-4D91-B7A6-19D8E4F05C23}']
    /// <summary>Called once for each text: the states that were bound before are not touched</summary>
    procedure BeginScript;
    /// <param name="AObject">The thing the light is for, or a negative number for any</param>
    /// <param name="AHasFrame">False: every frame of the sprite</param>
    /// <returns>False if there was no state to bind the light to</returns>
    function Bind(AObject, ASprite, AFrame: Integer; AHasFrame: Boolean; ALight: Integer): Boolean;
  end;

  /// <summary>The definitions that were read, by index and by name</summary>
  IDynLightRegistry = interface
    ['{7F19A6D3-48C0-4E25-93B8-D2E05A1C6B97}']
    /// <summary>The name is put in upper case and cut to 32 characters; the result is the index</summary>
    function Add(const ADefinition: TDynLightDefinition): Integer;
    /// <summary>The last light with that name (the name is put in upper case), or -1</summary>
    function Find(const AName: string): Integer;
    function Count: Integer;
    function Get(AIndex: Integer): TDynLightDefinition;
    procedure Clear;
  end;

  /// <summary>Where the texts of the lumps come from</summary>
  IDynLightTextSource = interface
    ['{B4E82D19-6A07-4F3C-8E51-A3C9D07F2B68}']
    /// <summary>The text of every WAD lump with that name, in the order of the directory, one by one</summary>
    function WadLumpTexts(const AName: string): TArray<string>;
    /// <summary>The text of every entry of the PAK/PK3 files with that file name, one by one</summary>
    function PakTexts(const AFileName: string): TArray<string>;
  end;

  /// <summary>The common preprocessor of the scripts (#define, #include...), done before the parser</summary>
  IDynLightTextFilter = interface
    ['{2C6D0F85-91B3-4A7E-B0D4-E58A1F3C9726}']
    function Filter(const AText: string): string;
  end;

  /// <summary>Reads the text of a GLDEFS or LIGHTDEF lump</summary>
  IDynLightParser = interface
    ['{F5A19C34-0D78-4B62-9E83-7B2C4D16A0E9}']
    /// <summary>
    ///   The lights go to the registry and the "frame" lines to the binder; what is wrong is a
    ///   warning to the log
    /// </summary>
    procedure Parse(const AText: string);
  end;

  /// <summary>Finds the lumps of lights and gives each one to the parser</summary>
  IDynLightLoader = interface
    ['{08D3E7B6-5C42-4A19-A6F0-3E91B8D25C74}']
    /// <param name="AGldefsAsLightDef">GLDEFS lumps are read as LIGHTDEF</param>
    /// <returns>True if there is at least one lump or file entry of lights, even an empty one</returns>
    function Load(AGldefsAsLightDef: Boolean): Boolean;
  end;

  /// <summary>The color, radius and offset of a light at a given time</summary>
  IDynLightAnimator = interface
    ['{6B91C5F2-3E08-4D74-82A7-D01F5E9C3B48}']
    /// <param name="ALevelTime">The tic of the level</param>
    function GetRender(AIndex, ALevelTime: Integer): TDynLightRender;
    /// <summary>Forgets what it computed; to call when the registry is cleared and filled again</summary>
    procedure Reset;
  end;

  /// <summary>
  ///   The lights of the level as the renderers read them: one stable record for each light (the
  ///   renderers keep the pointer for a frame), calculated at most once in a tic
  /// </summary>
  IDynLightRenderCache = interface
    ['{9E2B47D1-C803-4F6A-B5D9-12A7E06F3C84}']
    /// <summary>
    ///   Forgets the lights and reads the lumps again (IDynLightLoader.Load); then there is one
    ///   record for each light
    /// </summary>
    /// <returns>What the loader says: true if there is a lump or file entry of lights</returns>
    function Load(AGldefsAsLightDef: Boolean): Boolean;
    /// <summary>Forgets the lights and the records</summary>
    procedure Clear;
    /// <summary>How many records there are</summary>
    function Count: Integer;
    /// <summary>
    ///   The record of the light at that tic. The index is not checked: it is one of the lights
    ///   that the states hold. The shadow is always off
    /// </summary>
    function GetLight(AIndex, ALevelTime: Integer): PDynLightRender;
  end;

  /// <summary>What the parser needs; the context may be nil (then it never lists the text)</summary>
  TDynLightParserServices = record
    Registry: IDynLightRegistry;
    Random: IDynLightRandom;
    Objects: IDynLightObjectResolver;
    Sprites: IDynLightSpriteResolver;
    Binder: IDynLightBinder;
    Context: IGameContext;
  end;

implementation

end.
