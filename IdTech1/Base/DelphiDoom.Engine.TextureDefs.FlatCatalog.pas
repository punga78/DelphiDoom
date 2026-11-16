{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the flats that FLATINFO can name                       }
{  Copyright (C) 2004-2023 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.TextureDefs.FlatCatalog;

interface

uses
  DelphiDoom.TextureDefs.Intf;

type
  /// <summary>
  ///   The number of a flat by its name: the search goes from the last flat to the first, so the
  ///   last one wins when a name is twice in the list
  /// </summary>
  TEngineFlatCatalog = class(TInterfacedObject, ITextureDefsFlatCatalog)
  public
    function LastIndexOf(const AUpperName: string): Integer;
  end;

implementation

uses
  r_data,
  w_wad;

{ TEngineFlatCatalog }

function TEngineFlatCatalog.LastIndexOf(const AUpperName: string): Integer;
var
  LIndex: Integer;
begin
  for LIndex := numflats - 1 downto 0 do
    if AUpperName = char8tostring(flats[LIndex].name) then
      Exit(LIndex);
  Result := -1;
end;

end.
