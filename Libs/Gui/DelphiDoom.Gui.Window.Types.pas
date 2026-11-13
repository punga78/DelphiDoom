{******************************************************************************}
{                                                                              }
{  DelphiDoom: gui library - constants and exceptions of the windows of Doom 3 }
{                                                                              }
{  Port of the GUI of Doom 3 (id Software, GPL v3): ui\Window.h.               }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore      }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.Window.Types;

interface

uses
  System.SysUtils;

const
  WIN_CHILD = $00000001;
  WIN_CAPTION = $00000002;
  WIN_BORDER = $00000004;
  WIN_SIZABLE = $00000008;
  WIN_MOVABLE = $00000010;
  WIN_FOCUS = $00000020;
  WIN_CAPTURE = $00000040;
  WIN_HCENTER = $00000080;
  WIN_VCENTER = $00000100;
  WIN_MODAL = $00000200;
  WIN_INTRANSITION = $00000400;
  WIN_CANFOCUS = $00000800;
  WIN_SELECTED = $00001000;
  WIN_TRANSFORM = $00002000;
  WIN_HOLDCAPTURE = $00004000;
  WIN_NOWRAP = $00008000;
  WIN_NOCLIP = $00010000;
  WIN_INVERTRECT = $00020000;
  WIN_NATURALMAT = $00040000;
  WIN_NOCURSOR = $00080000;
  WIN_MENUGUI = $00100000;
  WIN_ACTIVE = $00200000;
  WIN_SHOWCOORDS = $00400000;
  WIN_SHOWTIME = $00800000;
  WIN_WANTENTER = $01000000;
  WIN_DESKTOP = $10000000;

  /// <summary>USERCMD_MSEC (1000 / USERCMD_HZ, 60 Hz): the minimum time between two runs of the time events</summary>
  GUI_USERCMD_MSEC = 16;
  /// <summary>idDeviceContext::CURSOR_ARROW / CURSOR_HAND</summary>
  GUI_CURSOR_ARROW = 0;
  GUI_CURSOR_HAND = 1;

type
  /// <summary>The script lists of a window (idWindow::ON_MOUSEENTER ... SCRIPT_COUNT)</summary>
  TGuiScriptEvent = (seMouseEnter, seMouseExit, seAction, seActivate, seDeactivate, seEsc, seFrame, seTrigger,
    seActionRelease, seEnter, seEnterRelease);

const
  /// <summary>idWindow::ScriptNames, in the order of TGuiScriptEvent</summary>
  GUI_SCRIPT_NAMES: array[TGuiScriptEvent] of AnsiString = ('onMouseEnter', 'onMouseExit', 'onAction',
    'onActivate', 'onDeactivate', 'onESC', 'onEvent', 'onTrigger', 'onActionRelease', 'onEnter',
    'onEnterRelease');

type
  /// <summary>A contract violation of the windows (idCommon::FatalError of the original)</summary>
  EGuiWindowException = class(Exception);

  /// <summary>A .gui that does not parse, with file and line (raised only in strict mode)</summary>
  EGuiWindowParseException = class(EGuiWindowException)
  strict private
    FFileName: string;
    FLine: Integer;
  public
    constructor Create(const AFileName: string; const ALine: Integer; const AText: string);
    property FileName: string read FFileName;
    property Line: Integer read FLine;
  end;

implementation

constructor EGuiWindowParseException.Create(const AFileName: string; const ALine: Integer; const AText: string);
begin
  inherited CreateFmt('%s, line %d: %s', [AFileName, ALine, AText]);
  FFileName := AFileName;
  FLine := ALine;
end;

end.
