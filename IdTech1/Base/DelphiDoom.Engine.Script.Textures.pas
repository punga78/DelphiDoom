{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the textures that the functions of scripts describe    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Script.Textures;

interface

uses
  DelphiDoom.ScriptHost.Game.Intf;

type
  /// <summary>
  ///   The textures of the level for the scripts (r_data). The only class of the texture
  ///   functions that reads them; the number of a texture by name is the one that the other
  ///   functions of psi_game use
  /// </summary>
  TEngineScriptTextures = class(TInterfacedObject, IScriptTextureSource)
  public
    function TextureId(const AName: string): Integer;
    function TextureCount: Integer;
    function TextureWidth(const AId: Integer): Integer;
    function TextureHeight(const AId: Integer): Integer;
  end;

implementation

uses
  psi_game,
  r_data;

{ TEngineScriptTextures }

function TEngineScriptTextures.TextureId(const AName: string): Integer;
begin
  Result := psi_game._textureidfromname(AName);
end;

function TEngineScriptTextures.TextureCount: Integer;
begin
  Result := r_data.numtextures;
end;

function TEngineScriptTextures.TextureWidth(const AId: Integer): Integer;
begin
  Result := r_data.textures[AId].width;
end;

function TEngineScriptTextures.TextureHeight(const AId: Integer): Integer;
begin
  Result := r_data.textures[AId].height;
end;

end.
