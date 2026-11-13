{******************************************************************************}
{                                                                              }
{  DelphiDoom: gui library - TGuiRenderWindow (renderDef)                      }
{                                                                              }
{  Port of the GUI of Doom 3 (id Software, GPL v3): ui\RenderWindow.h,         }
{  RenderWindow.cpp (idRenderWindow: the parse). Copyright (C) 1999-2011 id    }
{  Software LLC, a ZeniMax Media company.                                      }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore      }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.Window.Render;

interface

uses
  DelphiDoom.Scanner.IdParser, DelphiDoom.Gui.Context, DelphiDoom.Gui.Window, DelphiDoom.Gui.Window.Intf,
  DelphiDoom.Gui.WinVar.Base, DelphiDoom.Gui.WinVar.Bool, DelphiDoom.Gui.WinVar.Str, DelphiDoom.Gui.WinVar.Vec4;

type
  /// <summary>
  ///   idRenderWindow: the key <c>animClass</c> and the variables <c>model</c>, <c>anim</c>,
  ///   <c>lightOrigin</c>, <c>lightColor</c>, <c>modelOrigin</c>, <c>modelRotate</c>, <c>viewOffset</c>,
  ///   <c>needsRender</c>. Not ported: the render world, the model and the animation.
  /// </summary>
  TGuiRenderWindow = class(TGuiWindow)
  strict private
    FAnimClass: AnsiString;
    FModelName: TGuiWinStr;
    FAnimName: TGuiWinStr;
    FLightOrigin: TGuiWinVec4;
    FLightColor: TGuiWinVec4;
    FModelOrigin: TGuiWinVec4;
    FModelRotate: TGuiWinVec4;
    FViewOffset: TGuiWinVec4;
    FNeedsRender: TGuiWinBool;
  protected
    function ParseInternalVar(const AName: AnsiString; const ASource: TIdParser): Boolean; override;
  public
    constructor Create(const AContext: TGuiContext; const ACreator: TGuiWindowCreator); override;
    destructor Destroy; override;
    function GetWinVarByName(const AName: AnsiString; const AFixup: Boolean;
      out AOwner: IGuiWindowNode): TGuiWinVar; override;
    property AnimClass: AnsiString read FAnimClass;
    property ModelName: TGuiWinStr read FModelName;
    property AnimName: TGuiWinStr read FAnimName;
    property LightOrigin: TGuiWinVec4 read FLightOrigin;
    property LightColor: TGuiWinVec4 read FLightColor;
    property ModelOrigin: TGuiWinVec4 read FModelOrigin;
    property ModelRotate: TGuiWinVec4 read FModelRotate;
    property ViewOffset: TGuiWinVec4 read FViewOffset;
    property NeedsRender: TGuiWinBool read FNeedsRender;
  end;

implementation

uses
  DelphiDoom.IdLib.Math.Vec4, DelphiDoom.IdLib.Text.Strings;

constructor TGuiRenderWindow.Create(const AContext: TGuiContext; const ACreator: TGuiWindowCreator);
begin
  inherited Create(AContext, ACreator);
  FModelName := TGuiWinStr.Create;
  FAnimName := TGuiWinStr.Create;
  FLightOrigin := TGuiWinVec4.Create;
  FLightColor := TGuiWinVec4.Create;
  FModelOrigin := TGuiWinVec4.Create;
  FModelRotate := TGuiWinVec4.Create;
  FViewOffset := TGuiWinVec4.Create;
  FNeedsRender := TGuiWinBool.Create;
  FNeedsRender.Value := True;
  FLightOrigin.Value := TIdVec4.Create(-128.0, 0.0, 0.0, 1.0);
  FLightColor.Value := TIdVec4.Create(1.0, 1.0, 1.0, 1.0);
  FModelOrigin.Zero;
  FModelRotate.Zero;
  FViewOffset.Value := TIdVec4.Create(-128.0, 0.0, 0.0, 1.0);
end;

destructor TGuiRenderWindow.Destroy;
begin
  FNeedsRender.Free;
  FViewOffset.Free;
  FModelRotate.Free;
  FModelOrigin.Free;
  FLightColor.Free;
  FLightOrigin.Free;
  FAnimName.Free;
  FModelName.Free;
  inherited Destroy;
end;

function TGuiRenderWindow.ParseInternalVar(const AName: AnsiString; const ASource: TIdParser): Boolean;
begin
  if TIdStrings.Icmp(AName, 'animClass') = 0 then
  begin
    ParseString(ASource, FAnimClass);
    Exit(True);
  end;
  Result := inherited ParseInternalVar(AName, ASource);
end;

function TGuiRenderWindow.GetWinVarByName(const AName: AnsiString; const AFixup: Boolean;
  out AOwner: IGuiWindowNode): TGuiWinVar;
begin
  AOwner := nil;
  if TIdStrings.Icmp(AName, 'model') = 0 then
    Exit(FModelName);
  if TIdStrings.Icmp(AName, 'anim') = 0 then
    Exit(FAnimName);
  if TIdStrings.Icmp(AName, 'lightOrigin') = 0 then
    Exit(FLightOrigin);
  if TIdStrings.Icmp(AName, 'lightColor') = 0 then
    Exit(FLightColor);
  if TIdStrings.Icmp(AName, 'modelOrigin') = 0 then
    Exit(FModelOrigin);
  if TIdStrings.Icmp(AName, 'modelRotate') = 0 then
    Exit(FModelRotate);
  if TIdStrings.Icmp(AName, 'viewOffset') = 0 then
    Exit(FViewOffset);
  if TIdStrings.Icmp(AName, 'needsRender') = 0 then
    Exit(FNeedsRender);
  Result := inherited GetWinVarByName(AName, AFixup, AOwner);
end;

end.
