{******************************************************************************}
{                                                                              }
{  DelphiDoom: gui library - TGuiFieldWindow (fieldDef)                        }
{                                                                              }
{  Port of the GUI of Doom 3 (id Software, GPL v3): ui\FieldWindow.h,          }
{  FieldWindow.cpp (idFieldWindow: the parse). Copyright (C) 1999-2011 id      }
{  Software LLC, a ZeniMax Media company.                                      }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore      }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.Window.Field;

interface

uses
  DelphiDoom.Scanner.IdParser, DelphiDoom.Gui.Window;

type
  /// <summary>idFieldWindow: the keys <c>cursorvar</c> and <c>showcursor</c>. Not ported: the cursor and the drawing.</summary>
  TGuiFieldWindow = class(TGuiWindow)
  strict private
    FCursorVar: AnsiString;
    FShowCursor: Boolean;
  protected
    function ParseInternalVar(const AName: AnsiString; const ASource: TIdParser): Boolean; override;
  public
    property CursorVar: AnsiString read FCursorVar;
    property ShowCursor: Boolean read FShowCursor;
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Strings;

function TGuiFieldWindow.ParseInternalVar(const AName: AnsiString; const ASource: TIdParser): Boolean;
begin
  Result := True;
  if TIdStrings.Icmp(AName, 'cursorvar') = 0 then
    ParseString(ASource, FCursorVar)
  else if TIdStrings.Icmp(AName, 'showcursor') = 0 then
    FShowCursor := ASource.ParseBool
  else
    Result := inherited ParseInternalVar(AName, ASource);
end;

end.
