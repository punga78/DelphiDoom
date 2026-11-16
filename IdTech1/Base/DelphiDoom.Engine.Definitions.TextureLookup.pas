{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the textures that a table of switches can name         }
{  Copyright (C) 2004-2023 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Definitions.TextureLookup;

interface

uses
  DelphiDoom.Definitions.Intf;

type
  /// <summary>The number of a texture by its name, -1 if there is none</summary>
  TEngineTextureLookup = class(TInterfacedObject, IDefTextureLookup)
  public
    function CheckTextureNumForName(const AName: string): Integer;
  end;

implementation

uses
  r_data;

{ TEngineTextureLookup }

function TEngineTextureLookup.CheckTextureNumForName(const AName: string): Integer;
begin
  Result := R_CheckTextureNumForName(AName);
end;

end.
