{******************************************************************************}
{                                                                              }
{  DelphiDoom: gui library - TGuiRenderWindow (renderDef)                      }
{                                                                              }
{  Port of the GUI of Doom 3 (id Software, GPL v3): ui\RenderWindow.h,         }
{  RenderWindow.cpp (idRenderWindow: the parse). Copyright (C) 1999-2011 id    }
{  Software LLC, a ZeniMax Media company.                                      }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3 or (at your       }
{  option) any later version, with the additional terms of the Doom 3 Source   }
{  Code License (Reference\doom3\COPYING.txt: preservation of legal notices    }
{  and trademarks, no use of the licensors' names for publicity, warranty      }
{  disclaimer). The repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.Window.Render;

interface

uses
  DelphiDoom.Scanner.IdParser, DelphiDoom.Gui.Context, DelphiDoom.Gui.Window, DelphiDoom.Gui.Window.Intf,
  DelphiDoom.Gui.WinVar.Base, DelphiDoom.Gui.WinVar.Bool, DelphiDoom.Gui.WinVar.Str, DelphiDoom.Gui.WinVar.Vec4,
  DelphiDoom.Gui.Window.Hosts;

type
  /// <summary>
  ///   idRenderWindow: the key <c>animClass</c> and the variables <c>model</c>, <c>anim</c>,
  ///   <c>lightOrigin</c>, <c>lightColor</c>, <c>modelOrigin</c>, <c>modelRotate</c>, <c>viewOffset</c>,
  ///   <c>needsRender</c>. It draws a model with a light into the rectangle of the window through <c>IGuiRenderHost</c> and its
  ///   render world; the game edit functions (the model, the animation) are the host's.
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
    FWorld: IGuiRenderWorld;
    FLight: TGuiRenderLight;
    FEntity: TGuiRenderEntity;
    FLightDef: Integer;
    FModelDef: Integer;
    FAnimLength: Integer;
    FAnimEndTime: Integer;
    FUpdateAnimation: Boolean;
    FAnimated: Boolean;
    procedure BuildAnimation(const ATime: Integer);
    procedure PreRender;
    procedure Render(const ATime: Integer);
  protected
    function ParseInternalVar(const AName: AnsiString; const ASource: TIdParser): Boolean; override;
  public
    constructor Create(const AContext: TGuiContext; const ACreator: TGuiWindowCreator); override;
    destructor Destroy; override;
    /// <summary>idRenderWindow::Draw: the light and the model are made at the first draw, then updated and the scene is rendered</summary>
    procedure Draw(const ATime: Integer; const AX, AY: Single); override;
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
  System.SysUtils, System.Math, DelphiDoom.IdLib.Math.Vec3, DelphiDoom.IdLib.Math.Vec4, DelphiDoom.IdLib.Text.Strings;

constructor TGuiRenderWindow.Create(const AContext: TGuiContext; const ACreator: TGuiWindowCreator);
begin
  inherited Create(AContext, ACreator);
  FModelDef := -1;
  FAnimEndTime := -1;
  FUpdateAnimation := True;
  FModelName := TGuiWinStr.Create;
  FAnimName := TGuiWinStr.Create;
  FLightOrigin := TGuiWinVec4.Create;
  FLightColor := TGuiWinVec4.Create;
  FModelOrigin := TGuiWinVec4.Create;
  FModelRotate := TGuiWinVec4.Create;
  FViewOffset := TGuiWinVec4.Create;
  FNeedsRender := TGuiWinBool.Create;
  FNeedsRender.Value := True;
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

procedure TGuiRenderWindow.BuildAnimation(const ATime: Integer);
begin
  if not FUpdateAnimation then
    Exit;
  if (FAnimName.AsText <> '') and (FAnimClass <> '') and Assigned(Context.RenderHost) then
  begin
    FAnimLength := Context.RenderHost.AnimationLength(FAnimClass, FAnimName.AsText);
    FAnimated := FAnimLength > 0;
    if FAnimated then
      FAnimEndTime := ATime + FAnimLength;
  end;
  FUpdateAnimation := False;
end;

procedure TGuiRenderWindow.PreRender;
begin
  if not FNeedsRender.Value then
    Exit;
  FWorld.InitFromMap;
  FLight.Origin := TIdVec3.Create(FLightOrigin.Value.X, FLightOrigin.Value.Y, FLightOrigin.Value.Z);
  FLight.Red := FLightColor.Value.X;
  FLight.Green := FLightColor.Value.Y;
  FLight.Blue := FLightColor.Value.Z;
  FLightDef := FWorld.AddLightDef(FLight);
  if FModelName.AsText = '' then
    Warning(Format('Window ''%s'' in gui ''%s'': no model set', [string(Name), string(Context.SourceFile)]));
  FEntity := Context.RenderHost.ParseModelEntity(FModelName.AsText, FModelOrigin.AsText);
  if FEntity.HasModel then
  begin
    FEntity.Pitch := FModelRotate.Value.X;
    FEntity.Yaw := FModelRotate.Value.Y;
    FEntity.Roll := FModelRotate.Value.Z;
    FModelDef := FWorld.AddEntityDef(FEntity);
  end;
  FNeedsRender.Value := False;
end;

procedure TGuiRenderWindow.Render(const ATime: Integer);
begin
  FLight.Origin := TIdVec3.Create(FLightOrigin.Value.X, FLightOrigin.Value.Y, FLightOrigin.Value.Z);
  FLight.Red := FLightColor.Value.X;
  FLight.Green := FLightColor.Value.Y;
  FLight.Blue := FLightColor.Value.Z;
  FWorld.UpdateLightDef(FLightDef, FLight);
  if FEntity.HasModel then
  begin
    if FUpdateAnimation then
      BuildAnimation(ATime);
    if FAnimated then
    begin
      if ATime > FAnimEndTime then
        FAnimEndTime := ATime + FAnimLength;
      Context.RenderHost.CreateAnimationFrame(FAnimClass, FAnimName.AsText, FAnimLength - (FAnimEndTime - ATime));
    end;
    FEntity.Pitch := FModelRotate.Value.X;
    FEntity.Yaw := FModelRotate.Value.Y;
    FEntity.Roll := FModelRotate.Value.Z;
    FWorld.UpdateEntityDef(FModelDef, FEntity);
  end;
end;

procedure TGuiRenderWindow.Draw(const ATime: Integer; const AX, AY: Single);
var
  LView: TGuiRenderView;
  LRatio, LAngle: Single;
begin
  if not Assigned(Context.RenderHost) then
    Exit;
  if not Assigned(FWorld) then
    FWorld := Context.RenderHost.AllocRenderWorld;
  PreRender;
  Render(ATime);
  LView.ViewOrigin := TIdVec3.Create(FViewOffset.Value.X, FViewOffset.Value.Y, FViewOffset.Value.Z);
  LView.X := DrawRect.X;
  LView.Y := DrawRect.Y;
  LView.Width := DrawRect.W;
  LView.Height := DrawRect.H;
  LView.FovX := 90;
  // refdef.fov_y = 2 * atan( h / w ) * M_RAD2DEG
  LRatio := DrawRect.H / DrawRect.W;
  LAngle := ArcTan(LRatio);
  LAngle := 2 * LAngle;
  LAngle := LAngle * Single(180.0 / Pi);
  LView.FovY := LAngle;
  LView.Time := ATime;
  FWorld.RenderScene(LView);
end;

end.