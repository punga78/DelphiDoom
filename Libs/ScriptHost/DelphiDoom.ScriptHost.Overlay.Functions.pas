{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - the functions of the unit PS_OVERLAY              }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  OverlayClear and the nine OverlayDraw* (the PS_Overlay* of psi_overlay.pas) }
{  call the overlay of the game; the overlay may not exist yet (or any more)   }
{  and then they do nothing, as before.                                        }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ScriptHost.Overlay.Functions;

interface

uses
  System.SysUtils,
  DelphiDoom.ScriptHost.Intf,
  DelphiDoom.ScriptHost.Overlay.Drawer;

type
  /// <summary>The functions of the overlay of the unit PS_OVERLAY (called with the object as Self)</summary>
  TScriptOverlayFunctions = class(TInterfacedObject, IScriptFunctionSection)
  strict private
    FOverlay: TFunc<TOverlayDrawer>;
  public
    /// <summary>The overlay is asked at every call: it is made and freed by the engine</summary>
    /// <exception cref="EArgumentNilException">If the function is nil</exception>
    constructor Create(const AOverlay: TFunc<TOverlayDrawer>);
    procedure Describe(const ATable: IScriptFunctionTable);
    procedure OverlayClear;
    procedure OverlayDrawPatch(const ATicks: Integer; const APatchName: string; const X, Y: Integer);
    procedure OverlayDrawPatchStretched(const ATicks: Integer; const APatchName: string;
      const X1, Y1, X2, Y2: Integer);
    procedure OverlayDrawPixel(const ATicks: Integer; const ARed, AGreen, ABlue: Byte;
      const X, Y: Integer);
    procedure OverlayDrawRect(const ATicks: Integer; const ARed, AGreen, ABlue: Byte;
      const X1, Y1, X2, Y2: Integer);
    procedure OverlayDrawLine(const ATicks: Integer; const ARed, AGreen, ABlue: Byte;
      const X1, Y1, X2, Y2: Integer);
    procedure OverlayDrawText(const ATicks: Integer; const AText: string; const AAlign: Integer;
      const X, Y: Integer);
    procedure OverlayDrawLeftText(const ATicks: Integer; const AText: string; const X, Y: Integer);
    procedure OverlayDrawRightText(const ATicks: Integer; const AText: string; const X, Y: Integer);
    procedure OverlayDrawCenterText(const ATicks: Integer; const AText: string; const X, Y: Integer);
  end;

implementation

{ TScriptOverlayFunctions }

constructor TScriptOverlayFunctions.Create(const AOverlay: TFunc<TOverlayDrawer>);
begin
  inherited Create;
  if not Assigned(AOverlay) then
    raise EArgumentNilException.Create('AOverlay');
  FOverlay := AOverlay;
end;

procedure TScriptOverlayFunctions.Describe(const ATable: IScriptFunctionTable);
begin
  ATable.AddMethod('procedure OverlayClear;', Self, @TScriptOverlayFunctions.OverlayClear);
  ATable.AddMethod('procedure OverlayDrawPatch(const ticks: Integer; const patchname: string; const x, y: Integer);',
    Self, @TScriptOverlayFunctions.OverlayDrawPatch);
  ATable.AddMethod('procedure OverlayDrawPatchStretched(const ticks: Integer; const patchname: string; const x1, y1, x2, y2: Integer);',
    Self, @TScriptOverlayFunctions.OverlayDrawPatchStretched);
  ATable.AddMethod('procedure OverlayDrawPixel(const ticks: Integer; const red, green, blue : byte; const x, y : Integer);',
    Self, @TScriptOverlayFunctions.OverlayDrawPixel);
  ATable.AddMethod('procedure OverlayDrawRect(const ticks: Integer; const red, green, blue: byte; const x1, y1, x2, y2: Integer);',
    Self, @TScriptOverlayFunctions.OverlayDrawRect);
  ATable.AddMethod('procedure OverlayDrawLine(const ticks: Integer; const red, green, blue: byte; const x1, y1, x2, y2: Integer);',
    Self, @TScriptOverlayFunctions.OverlayDrawLine);
  ATable.AddMethod('procedure OverlayDrawText(const ticks: Integer; const txt: string; const align: Integer; const x, y: Integer);',
    Self, @TScriptOverlayFunctions.OverlayDrawText);
  ATable.AddMethod('procedure OverlayDrawLeftText(const ticks: Integer; const txt: string; const x, y: Integer);',
    Self, @TScriptOverlayFunctions.OverlayDrawLeftText);
  ATable.AddMethod('procedure OverlayDrawRightText(const ticks: Integer; const txt: string; const x, y: Integer);',
    Self, @TScriptOverlayFunctions.OverlayDrawRightText);
  ATable.AddMethod('procedure OverlayDrawCenterText(const ticks: Integer; const txt: string; const x, y: Integer);',
    Self, @TScriptOverlayFunctions.OverlayDrawCenterText);
end;

procedure TScriptOverlayFunctions.OverlayClear;
var
  LOverlay: TOverlayDrawer;
begin
  LOverlay := FOverlay();
  if Assigned(LOverlay) then
    LOverlay.Clear;
end;

procedure TScriptOverlayFunctions.OverlayDrawPatch(const ATicks: Integer; const APatchName: string;
  const X, Y: Integer);
var
  LOverlay: TOverlayDrawer;
begin
  LOverlay := FOverlay();
  if Assigned(LOverlay) then
    LOverlay.AddPatch(ATicks, APatchName, X, Y);
end;

procedure TScriptOverlayFunctions.OverlayDrawPatchStretched(const ATicks: Integer;
  const APatchName: string; const X1, Y1, X2, Y2: Integer);
var
  LOverlay: TOverlayDrawer;
begin
  LOverlay := FOverlay();
  if Assigned(LOverlay) then
    LOverlay.AddPatchStretched(ATicks, APatchName, X1, Y1, X2, Y2);
end;

procedure TScriptOverlayFunctions.OverlayDrawPixel(const ATicks: Integer;
  const ARed, AGreen, ABlue: Byte; const X, Y: Integer);
var
  LOverlay: TOverlayDrawer;
begin
  LOverlay := FOverlay();
  if Assigned(LOverlay) then
    LOverlay.AddPixel(ATicks, ARed, AGreen, ABlue, X, Y);
end;

procedure TScriptOverlayFunctions.OverlayDrawRect(const ATicks: Integer;
  const ARed, AGreen, ABlue: Byte; const X1, Y1, X2, Y2: Integer);
var
  LOverlay: TOverlayDrawer;
begin
  LOverlay := FOverlay();
  if Assigned(LOverlay) then
    LOverlay.AddRect(ATicks, ARed, AGreen, ABlue, X1, Y1, X2, Y2);
end;

procedure TScriptOverlayFunctions.OverlayDrawLine(const ATicks: Integer;
  const ARed, AGreen, ABlue: Byte; const X1, Y1, X2, Y2: Integer);
var
  LOverlay: TOverlayDrawer;
begin
  LOverlay := FOverlay();
  if Assigned(LOverlay) then
    LOverlay.AddLine(ATicks, ARed, AGreen, ABlue, X1, Y1, X2, Y2);
end;

procedure TScriptOverlayFunctions.OverlayDrawText(const ATicks: Integer; const AText: string;
  const AAlign: Integer; const X, Y: Integer);
var
  LOverlay: TOverlayDrawer;
begin
  LOverlay := FOverlay();
  if Assigned(LOverlay) then
    LOverlay.AddText(ATicks, AText, AAlign, X, Y);
end;

procedure TScriptOverlayFunctions.OverlayDrawLeftText(const ATicks: Integer; const AText: string;
  const X, Y: Integer);
var
  LOverlay: TOverlayDrawer;
begin
  LOverlay := FOverlay();
  if Assigned(LOverlay) then
    LOverlay.AddLeftText(ATicks, AText, X, Y);
end;

procedure TScriptOverlayFunctions.OverlayDrawRightText(const ATicks: Integer; const AText: string;
  const X, Y: Integer);
var
  LOverlay: TOverlayDrawer;
begin
  LOverlay := FOverlay();
  if Assigned(LOverlay) then
    LOverlay.AddRightText(ATicks, AText, X, Y);
end;

procedure TScriptOverlayFunctions.OverlayDrawCenterText(const ATicks: Integer; const AText: string;
  const X, Y: Integer);
var
  LOverlay: TOverlayDrawer;
begin
  LOverlay := FOverlay();
  if Assigned(LOverlay) then
    LOverlay.AddCenterText(ATicks, AText, X, Y);
end;

end.
