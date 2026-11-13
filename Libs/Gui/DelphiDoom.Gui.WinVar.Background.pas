{******************************************************************************}
{                                                                              }
{  DelphiDoom: gui library - TGuiWinBackground                                 }
{                                                                              }
{  Port of the GUI of Doom 3 (id Software, GPL v3): ui\Winvar.h                }
{  (idWinBackground). Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media }
{  company.                                                                    }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore      }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.WinVar.Background;

interface

uses
  DelphiDoom.Gui.WinVar.Str;

type
  /// <summary>
  ///   idWinBackground: the name of the material of a window. The original also finds the material
  ///   (<c>declManager->FindMaterial</c>) each time the name changes; here the name is the whole state
  ///   and the renderer that draws the window resolves it (the material is not part of the model).
  /// </summary>
  TGuiWinBackground = class(TGuiWinStr)
  end;

implementation

end.
