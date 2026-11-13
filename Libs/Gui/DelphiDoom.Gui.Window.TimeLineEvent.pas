{******************************************************************************}
{                                                                              }
{  DelphiDoom: gui library - TGuiTimeLineEvent                                 }
{                                                                              }
{  Port of the GUI of Doom 3 (id Software, GPL v3): ui\Window.h                }
{  (idTimeLineEvent). Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media }
{  company.                                                                    }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore      }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.Window.TimeLineEvent;

interface

uses
  DelphiDoom.Gui.Script;

type
  /// <summary>An <c>onTime</c> block: a script that runs once when the time line of the window reaches <c>Time</c></summary>
  TGuiTimeLineEvent = class
  strict private
    FTime: Integer;
    FScript: TGuiScriptList;
    FPending: Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    property Time: Integer read FTime write FTime;
    property Script: TGuiScriptList read FScript;
    property Pending: Boolean read FPending write FPending;
  end;

implementation

constructor TGuiTimeLineEvent.Create;
begin
  inherited Create;
  FScript := TGuiScriptList.Create;
end;

destructor TGuiTimeLineEvent.Destroy;
begin
  FScript.Free;
  inherited Destroy;
end;

end.
