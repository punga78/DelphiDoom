{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the sprite lumps of the WAD for the renderer library   }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Renderer.SpriteSource;

{$I Doom32.inc}

interface

uses
  System.SysUtils,
  DelphiDoom.Renderer.Types,
  DelphiDoom.Renderer.Intf;

type
  /// <summary>
  ///   Gives the builder of the sprite definitions the sprite lumps that R_InitSpriteLumps
  ///   found (the globals of r_data, read when the sprites are built), the lump names of the
  ///   WAD and the state of the game that R_InitSpriteDefs used to read
  /// </summary>
  TEngineRendererSpriteSource = class(TInterfacedObject, IRendererSpriteSource)
  public
    function FirstLump: Integer;
    function LastLump: Integer;
    function IsPresent(ALump: Integer): Boolean;
    function LumpName(ALump: Integer): TRendererLumpName;
    function PatchedLump(ALump: Integer): Integer;
    function DeveloperMode: Boolean;
  end;

implementation

uses
  d_main,
  doomstat,
  r_data,
  w_wad;

{ TEngineRendererSpriteSource }

function TEngineRendererSpriteSource.FirstLump: Integer;
begin
  Result := firstspritelump;
end;

function TEngineRendererSpriteSource.LastLump: Integer;
begin
  Result := lastspritelump;
end;

function TEngineRendererSpriteSource.IsPresent(ALump: Integer): Boolean;
begin
  Result := spritepresent[ALump - firstspritelump];
end;

function TEngineRendererSpriteSource.LumpName(ALump: Integer): TRendererLumpName;
var
  LName: char8_t;
begin
  LName := TWadRoutines.W_GetNameForNum(ALump);
  Move(LName, Result, SizeOf(Result));
end;

function TEngineRendererSpriteSource.PatchedLump(ALump: Integer): Integer;
begin
  if modifiedgame then
    Result := TWadRoutines.W_GetNumForName(TWadRoutines.char8tostring(TWadRoutines.W_GetNameForNum(ALump)))
  else
    Result := ALump;
end;

function TEngineRendererSpriteSource.DeveloperMode: Boolean;
begin
  Result := devparm;
end;

end.
