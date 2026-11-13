{******************************************************************************}
{                                                                              }
{  DelphiDoom: gui library - TGuiMarkerWindow (markerDef)                      }
{                                                                              }
{  Port of the GUI of Doom 3 (id Software, GPL v3): ui\MarkerWindow.h,         }
{  MarkerWindow.cpp (idMarkerWindow: the parse). Copyright (C) 1999-2011 id    }
{  Software LLC, a ZeniMax Media company.                                      }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore      }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.Window.Marker;

interface

uses
  DelphiDoom.IdLib.Math.Vec4, DelphiDoom.Scanner.IdParser, DelphiDoom.Gui.Context, DelphiDoom.Gui.Window;

type
  /// <summary>
  ///   idMarkerWindow: the keys <c>markerMat</c>, <c>markerStop</c> (material names) and <c>markerColor</c>.
  ///   Not ported: the statistics, the marker image and the mouse.
  /// </summary>
  TGuiMarkerWindow = class(TGuiWindow)
  strict private
    FMarkerMaterial: AnsiString;
    FMarkerStopMaterial: AnsiString;
    FMarkerColor: TIdVec4;
  protected
    function ParseInternalVar(const AName: AnsiString; const ASource: TIdParser): Boolean; override;
  public
    constructor Create(const AContext: TGuiContext; const ACreator: TGuiWindowCreator); override;
    property MarkerMaterial: AnsiString read FMarkerMaterial;
    property MarkerStopMaterial: AnsiString read FMarkerStopMaterial;
    property MarkerColor: TIdVec4 read FMarkerColor;
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Strings;

constructor TGuiMarkerWindow.Create(const AContext: TGuiContext; const ACreator: TGuiWindowCreator);
begin
  inherited Create(AContext, ACreator);
  FMarkerColor.Zero;
end;

function TGuiMarkerWindow.ParseInternalVar(const AName: AnsiString; const ASource: TIdParser): Boolean;
begin
  Result := True;
  if TIdStrings.Icmp(AName, 'markerMat') = 0 then
    ParseString(ASource, FMarkerMaterial)
  else if TIdStrings.Icmp(AName, 'markerStop') = 0 then
    ParseString(ASource, FMarkerStopMaterial)
  else if TIdStrings.Icmp(AName, 'markerColor') = 0 then
    ParseVec4(ASource, FMarkerColor)
  else
    Result := inherited ParseInternalVar(AName, ASource);
end;

end.
