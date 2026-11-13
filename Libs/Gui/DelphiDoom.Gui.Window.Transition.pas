{******************************************************************************}
{                                                                              }
{  DelphiDoom: gui library - TGuiTransition                                    }
{                                                                              }
{  Port of the GUI of Doom 3 (id Software, GPL v3): ui\Window.h                }
{  (idTransitionData). Copyright (C) 1999-2011 id Software LLC, a ZeniMax      }
{  Media company.                                                              }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore      }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.Window.Transition;

interface

uses
  DelphiDoom.Gui.WinVar.Base, DelphiDoom.Gui.Interpolator;

type
  /// <summary>A transition of a variable (a vec4, a float or a rectangle) of a window; the variable is not owned</summary>
  TGuiTransition = class
  strict private
    FVariable: TGuiWinVar;
    FInterpolator: TGuiInterpolator;
  public
    constructor Create(const AVariable: TGuiWinVar);
    destructor Destroy; override;
    property Variable: TGuiWinVar read FVariable;
    property Interpolator: TGuiInterpolator read FInterpolator;
  end;

implementation

constructor TGuiTransition.Create(const AVariable: TGuiWinVar);
begin
  inherited Create;
  FVariable := AVariable;
  FInterpolator := TGuiInterpolator.Create;
end;

destructor TGuiTransition.Destroy;
begin
  FInterpolator.Free;
  inherited Destroy;
end;

end.
