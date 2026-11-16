{******************************************************************************}
{                                                                              }
{  DelphiDoom: pmove library - the item list of baseq3 (the tags)              }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): bg_itemlist of  }
{  bg_misc.c. Copyright (C) 1999-2005 Id Software, Inc. This unit is derived   }
{  from the Quake III Arena source code and is therefore available under the   }
{  GNU General Public License, version 2 or (at your option) any later         }
{  version.                                                                    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Pmove.Items;

interface

uses
  System.SysUtils, DelphiDoom.Pmove.Intf;

const
  /// <summary>
  ///   giTag of the 36 items of bg_itemlist (index 0 is the empty item), in the order of the table of
  ///   baseq3 without MISSIONPACK; the parity golden prints the table of the original and a test compares it
  /// </summary>
  Q3_BASE_ITEM_TAGS: array[0..35] of Integer = (
    0, 0, 0, 0, 0, 0, 0, 0, 1, 3, 2, 4, 5, 6, 7, 8, 9, 10, 3, 2,
    4, 8, 6, 5, 7, 9, 1, 2, 1, 2, 3, 4, 5, 6, 7, 8);

type
  /// <summary>The item list of baseq3 (a game with another list gives its own IPmoveItemCatalog)</summary>
  TPmoveBaseItemCatalog = class(TInterfacedObject, IPmoveItemCatalog)
  public
    function GameTag(const AIndex: Integer): Integer;
  end;

implementation

function TPmoveBaseItemCatalog.GameTag(const AIndex: Integer): Integer;
begin
  if (AIndex < 0) or (AIndex > High(Q3_BASE_ITEM_TAGS)) then
    Result := 0
  else
    Result := Q3_BASE_ITEM_TAGS[AIndex];
end;

end.
