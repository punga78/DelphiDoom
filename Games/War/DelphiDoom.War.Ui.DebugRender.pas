{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the flags of the debug drawing                     }
{                                                                              }
{  Port of war1 (acoto87/war1), war_cheats.c (wcheat_applyDebugRenderCheat) and  }
{  war_map.c (updateDebugRenderShortcuts), (c) 2019 Alejandro Coto Gutierrez,   }
{  zlib License (see Games\War\LICENSE-war1.txt). This is an altered version,   }
{  not the original.                                                           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Ui.DebugRender;

{$R-}
{$Q-}

interface

uses
  System.SysUtils, DelphiDoom.War.Ui.Types, DelphiDoom.War.Ui.Intf, DelphiDoom.War.Text.Intf;

type
  /// <summary>
  ///   The flags of the debug drawing and what changes them: the keys Ctrl+Shift+letter and the cheat "Debug render".
  ///   Defect of the original kept: the names of the cheat are twelve and the flags thirteen (there is a flag for the paths
  ///   of the units that has no name), so from "unit-info" on a name toggles the flag before the one it names
  ///   ("state-machine" toggles the rvo, "rvo" the flow field...) and the last flag has no name: an empty one finds it
  /// </summary>
  TWarDebugRender = class(TInterfacedObject, IWarDebugRender, IWarTextDebug)
  strict private
    FFlags: array[TWarDebugRenderFlag] of Boolean;
    function FlagOfName(const AName: AnsiString; out AFlag: TWarDebugRenderFlag): Boolean;
    function NameOf(AFlag: TWarDebugRenderFlag): AnsiString;
  public
    /// <summary>IWarTextDebug: the flag "font", read by the text renderer of every scene</summary>
    function IsFontOutlineOn: Boolean;
    function GetFlag(AFlag: TWarDebugRenderFlag): Boolean;
    procedure SetFlag(AFlag: TWarDebugRenderFlag; AValue: Boolean);
    function ApplyCheat(const AArgument: AnsiString): AnsiString;
    procedure UpdateShortcuts(const AInput: IWarUiInput);
  end;

implementation

uses
  DelphiDoom.War.Ui.Strings;

const
  // debugRenderFlagNames: twelve names for thirteen flags
  FLAG_NAMES: array[0..11] of AnsiString = ('map-grid', 'spatial-grid', 'near-units', 'passable-info', 'unit-info',
    'unit-animations', 'map-animations', 'font', 'projectiles', 'flow-field', 'rvo', 'state-machine');

{ TWarDebugRender }

function TWarDebugRender.GetFlag(AFlag: TWarDebugRenderFlag): Boolean;
begin
  Result := FFlags[AFlag];
end;

function TWarDebugRender.IsFontOutlineOn: Boolean;
begin
  Result := FFlags[wdrFont];
end;

procedure TWarDebugRender.SetFlag(AFlag: TWarDebugRenderFlag; AValue: Boolean);
begin
  FFlags[AFlag] := AValue;
end;

function TWarDebugRender.NameOf(AFlag: TWarDebugRenderFlag): AnsiString;
begin
  // the thirteenth name is a null pointer: it is empty to the parser and "(null)" to printf
  if Ord(AFlag) <= High(FLAG_NAMES) then
    Result := FLAG_NAMES[Ord(AFlag)]
  else
    Result := '(null)';
end;

function TWarDebugRender.FlagOfName(const AName: AnsiString; out AFlag: TWarDebugRenderFlag): Boolean;
var
  LFlag: TWarDebugRenderFlag;
begin
  Result := False;
  AFlag := wdrMapGrid;
  for LFlag := Low(TWarDebugRenderFlag) to High(TWarDebugRenderFlag) do
  begin
    if Ord(LFlag) <= High(FLAG_NAMES) then
    begin
      if TWarStrings.EqualsIgnoreCase(AName, FLAG_NAMES[Ord(LFlag)]) then
      begin
        AFlag := LFlag;
        Exit(True);
      end;
    end
    else if AName = '' then
    begin
      AFlag := LFlag;
      Exit(True);
    end;
  end;
end;

function TWarDebugRender.ApplyCheat(const AArgument: AnsiString): AnsiString;
var
  LArgument: AnsiString;
  LFeature: AnsiString;
  LValue: AnsiString;
  LSeparator: Integer;
  LFlag: TWarDebugRenderFlag;
  LNewValue: Boolean;
  LCount: Integer;
begin
  LArgument := TWarStrings.Trim(AArgument);
  if TWarStrings.EqualsIgnoreCase(LArgument, 'status') then
  begin
    LCount := 0;
    for LFlag := Low(TWarDebugRenderFlag) to High(TWarDebugRenderFlag) do
      if FFlags[LFlag] then
        Inc(LCount);
    Exit(AnsiString(Format('%d/%d debug render flags on (see log)', [LCount, Ord(High(TWarDebugRenderFlag)) + 1])));
  end;
  // the feature and an optional value, split at the first space
  LSeparator := Pos(AnsiString(' '), LArgument);
  if LSeparator = 0 then
  begin
    LFeature := LArgument;
    LValue := '';
  end
  else
  begin
    LFeature := Copy(LArgument, 1, LSeparator - 1);
    LValue := Copy(LArgument, LSeparator + 1, MaxInt);
  end;
  LFeature := TWarStrings.Trim(LFeature);
  LValue := TWarStrings.Trim(LValue);
  if not FlagOfName(LFeature, LFlag) then
    Exit(AnsiString(Format('Unknown debug render flag: %s', [string(LFeature)])));
  if LValue = '' then
    LNewValue := not FFlags[LFlag]
  else if LValue = '0' then
    LNewValue := False
  else if LValue = '1' then
    LNewValue := True
  else
    Exit(AnsiString(Format('Invalid value: %s (use 0 or 1)', [string(LValue)])));
  FFlags[LFlag] := LNewValue;
  if LNewValue then
    Result := AnsiString(Format('%s on', [string(NameOf(LFlag))]))
  else
    Result := AnsiString(Format('%s off', [string(NameOf(LFlag))]));
end;

procedure TWarDebugRender.UpdateShortcuts(const AInput: IWarUiInput);
const
  KEYS: array[0..11] of TWarKey = (wkG, wkS, wkN, wkP, wkI, wkU, wkA, wkF, wkJ, wkW, wkR, wkT);
  // the flag of each key, by the enum (not by the names): the keys are right where the names are not
  FLAGS: array[0..11] of TWarDebugRenderFlag = (wdrMapGrid, wdrSpatialGrid, wdrNearUnits, wdrPassableInfo, wdrUnitInfo,
    wdrUnitAnimations, wdrMapAnimations, wdrFont, wdrProjectiles, wdrFlowField, wdrRvo, wdrStateMachine);
var
  LIndex: Integer;
begin
  if (not AInput.IsKeyHeld(wkCtrl)) or (not AInput.IsKeyHeld(wkShift)) then
    Exit;
  for LIndex := 0 to High(KEYS) do
    if AInput.IsKeyJustPressed(KEYS[LIndex]) then
      FFlags[FLAGS[LIndex]] := not FFlags[FLAGS[LIndex]];
end;

end.
