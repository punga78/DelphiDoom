{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - which flats and textures exist, for ANIMDEFS           }
{  Copyright (C) 2004-2023 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Definitions.AnimCatalog;

interface

uses
  DelphiDoom.Definitions.Intf;

type
  /// <summary>
  ///   Tells the ANIMDEFS parser if a flat or a texture exists: an animation of something that does
  ///   not exist is left out. A flat exists when a lump has its name (as it has always been)
  /// </summary>
  TEngineAnimNameCatalog = class(TInterfacedObject, IDefAnimNameCatalog)
  public
    function HasFlat(const AName: string): Boolean;
    function HasTexture(const AName: string): Boolean;
  end;

implementation

uses
  r_data,
  w_wad;

{ TEngineAnimNameCatalog }

function TEngineAnimNameCatalog.HasFlat(const AName: string): Boolean;
begin
  Result := W_CheckNumForName(AName) <> -1;
end;

function TEngineAnimNameCatalog.HasTexture(const AName: string): Boolean;
begin
  Result := R_CheckTextureNumForName(AName) <> -1;
end;

end.
