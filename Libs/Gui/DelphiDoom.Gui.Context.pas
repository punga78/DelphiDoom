{******************************************************************************}
{                                                                              }
{  DelphiDoom: gui library - TGuiContext, what the windows of a gui share      }
{                                                                              }
{  Port of the GUI of Doom 3 (id Software, GPL v3): ui\UserInterfaceLocal.h    }
{  (the state of idUserInterfaceLocal that idWindow reads through              }
{  <c>gui->...</c>) and the statics of idWindow::EvalRegs.                     }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore      }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.Context;

interface

uses
  DelphiDoom.IdLib.Core.Intf, DelphiDoom.Scanner.IdDict, DelphiDoom.Gui.Regs.Types, DelphiDoom.Gui.Regs.Intf,
  DelphiDoom.Gui.Window.Intf;

type
  /// <summary>
  ///   The state that the windows of one gui share: the time, the dictionary of the gui variables
  ///   (<c>gui::name</c>), the desktop, the commands to hand to the game, and the services (all optional)
  ///   the original takes from globals. It also holds the register array of <c>EvalRegs</c>, a static of the
  ///   original, and the window that evaluated last.
  /// </summary>
  TGuiContext = class
  strict private
    FStateDict: TIdDict;
    FLog: IIdLibLog;
  public
    Time: Integer;
    SourceFile: AnsiString;
    Active: Boolean;
    PendingCommand: AnsiString;
    Desktop: IGuiWindowNode;
    GameHost: IGuiGameHost;
    Language: IGuiLanguage;
    Tables: IGuiTables;
    Fonts: IGuiFontLookup;
    /// <summary>The registers of the last evaluation and the window that made it (idWindow::EvalRegs statics)</summary>
    EvalRegisters: TGuiRegisters;
    LastEvalWindow: TObject;
    constructor Create(const ALog: IIdLibLog);
    destructor Destroy; override;
    property StateDict: TIdDict read FStateDict;
    property Log: IIdLibLog read FLog;
  end;

implementation

constructor TGuiContext.Create(const ALog: IIdLibLog);
begin
  inherited Create;
  FLog := ALog;
  FStateDict := TIdDict.Create(ALog);
end;

destructor TGuiContext.Destroy;
begin
  Desktop := nil;
  FStateDict.Free;
  inherited Destroy;
end;

end.
