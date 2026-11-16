{******************************************************************************}
{                                                                              }
{  DelphiDoom: Speed library - pictures of the game under the names of Doom    }
{  Copyright (C) 1995 by Noriaworks                                            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom, GLSpeed)     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Speed.DoomPictureAliases;

interface

uses
  DelphiDoom.GameData.Intf;

type
  /// <summary>
  ///   The engine of Doom reads the picture of the title and of the pause by name; the fork changed
  ///   the engine, here the WAD gets a copy of the picture of the game under the name of Doom (a
  ///   datum, not a define). A name that the WAD already has is not touched
  /// </summary>
  TSpeedDoomPictureAliases = class
  public
    /// <summary>Adds the aliases</summary>
    /// <returns>How many lumps were added</returns>
    /// <exception cref="EArgumentNilException">AWad is nil</exception>
    class function Append(const AWad: IGameWadComposer): Integer; static;
  end;

implementation

uses
  System.SysUtils;

const
  // the name of Doom and the name of Speed Haste
  ALIASES: array[0..1, 0..1] of string = (
    ('TITLEPIC', 'DEMOLOGO'),
    ('M_PAUSE', 'PAUSE')
  );

{ TSpeedDoomPictureAliases }

class function TSpeedDoomPictureAliases.Append(const AWad: IGameWadComposer): Integer;
var
  LIndex: Integer;
  LSource: Integer;
begin
  if not Assigned(AWad) then
    raise EArgumentNilException.Create('AWad');
  Result := 0;
  for LIndex := 0 to High(ALIASES) do
  begin
    LSource := AWad.IndexOf(ALIASES[LIndex, 1]);
    if (LSource >= 0) and (AWad.IndexOf(ALIASES[LIndex, 0]) < 0) then
    begin
      AWad.AddLump(ALIASES[LIndex, 0], AWad.LumpData[LSource]);
      Inc(Result);
    end;
  end;
end;

end.
