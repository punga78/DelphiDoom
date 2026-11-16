{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - what the game, texture and keyboard functions     }
{  of the scripts ask of the engine                                            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ScriptHost.Game.Intf;

interface

uses
  DelphiDoom.ScriptHost.Types;

type
  /// <summary>The running game, for the functions _GAME, GameSkill, GameMap, GameEpisode and the earthquakes</summary>
  IScriptGameInfoSource = interface
    ['{A4C81D37-5E90-4B2F-96D3-0F7E21B8C5A9}']
    /// <summary>The name of the game as scripts see it (Doom, Heretic, Hexen, Strife)</summary>
    function GameName: string;
    function Skill: Integer;
    function MapNumber: Integer;
    /// <summary>Only the games that have episodes (Doom, Heretic) declare GameEpisode</summary>
    function Episode: Integer;
    /// <summary>Shakes the view of every player in the game</summary>
    procedure GlobalEarthQuake(const ATics: Integer);
    /// <summary>Shakes the view of the players near a point</summary>
    procedure LocalEarthQuake(const X, Y, Z: Integer; const ATics: Integer; const AIntensity: Integer;
      const AMaxDistance: Integer);
  end;

  /// <summary>The textures of the level, for IsValidTexture, GetTextureWidth and GetTextureHeight</summary>
  IScriptTextureSource = interface
    ['{6B2D90E4-17C3-4A58-8E61-D5F4A3079B2C}']
    /// <summary>The number of a texture; 0 for an empty name or "-", a number that is no texture if it is not there</summary>
    function TextureId(const AName: string): Integer;
    function TextureCount: Integer;
    function TextureWidth(const AId: Integer): Integer;
    function TextureHeight(const AId: Integer): Integer;
  end;

  /// <summary>The keys, the mouse buttons and the joystick buttons of the game, for the functions of the keyboard</summary>
  IScriptKeyboardSource = interface
    ['{F1957A0C-3D48-4E26-B7AC-92E86C50D134}']
    /// <summary>
    ///   True while the input of the player is not the one of a script: in a demo or in a network
    ///   game the scripts see no key
    /// </summary>
    function IsInputBlocked: Boolean;
    /// <summary>The key (or button) number that the player has chosen for an action; 0 if the game has no such action</summary>
    function KeyValue(const AKey: TScriptKey): Integer;
    /// <summary>The number of keys of the keyboard (the valid indexes are 0 to KeyCount - 1)</summary>
    function KeyCount: Integer;
    /// <summary>The number of buttons of the joystick</summary>
    function JoyButtonCount: Integer;
    function IsKeyDown(const AIndex: Integer): Boolean;
    function IsMouseButtonDown(const AIndex: Integer): Boolean;
    function IsJoyButtonDown(const AIndex: Integer): Boolean;
  end;

implementation

end.
