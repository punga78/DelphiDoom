{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 game library - gameLocal.Error                           }
{                                                                              }
{  Port of Doom 3 (id Software): game\Game_local.cpp (idGameLocal::Error).     }
{  Based on the Doom 3 GPL Source Code (id Software).                          }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3 or (at your       }
{  option) any later version, with the additional terms of the Doom 3 Source   }
{  Code License (Reference\doom3\COPYING.txt: preservation of legal notices    }
{  and trademarks, no use of the licensors' names for publicity, warranty      }
{  disclaimer). The repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.D3Game.Errors;

interface

uses
  System.SysUtils, DelphiDoom.D3Game.Types, DelphiDoom.D3Game.Intf;

type
  /// <summary>
  ///   <c>idGameLocal::Error</c>: the message goes to the printer and the game is left by <c>ED3GameException</c>.
  ///   A class with no printer (nil) only raises.
  /// </summary>
  TD3GameErrors = class sealed
  public
    class procedure RaiseError(const APrinter: ID3GamePrinter; const AText: AnsiString); static;
  end;

implementation

class procedure TD3GameErrors.RaiseError(const APrinter: ID3GamePrinter; const AText: AnsiString);
begin
  if Assigned(APrinter) then
    APrinter.Error(AText);
  raise ED3GameException.Create(string(AText));
end;

end.
