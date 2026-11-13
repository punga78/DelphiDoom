{******************************************************************************}
{                                                                              }
{  DelphiDoom: gui library - TGuiNamedEvent                                    }
{                                                                              }
{  Port of the GUI of Doom 3 (id Software, GPL v3): ui\Window.h                }
{  (rvNamedEvent). Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media    }
{  company.                                                                    }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore      }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.Window.NamedEvent;

interface

uses
  DelphiDoom.Gui.Script;

type
  /// <summary>An <c>onNamedEvent name</c> block: a script that runs when the game sends the event</summary>
  TGuiNamedEvent = class
  strict private
    FName: AnsiString;
    FScript: TGuiScriptList;
  public
    constructor Create(const AName: AnsiString);
    destructor Destroy; override;
    property Name: AnsiString read FName;
    property Script: TGuiScriptList read FScript;
  end;

implementation

constructor TGuiNamedEvent.Create(const AName: AnsiString);
begin
  inherited Create;
  FName := AName;
  FScript := TGuiScriptList.Create;
end;

destructor TGuiNamedEvent.Destroy;
begin
  FScript.Free;
  inherited Destroy;
end;

end.
