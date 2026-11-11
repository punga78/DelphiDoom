{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape states library - the window that asks to        }
{  abort the mission (AbortMissionState)                                        }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattleStates.AbortMissionState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton,
  DelphiDoom.XcomBattleStates.BattlescapeState;

type
  /// <summary>
  ///   The window over the battlescape that counts the soldiers in the craft (or in the entrance), in the exit and
  ///   outside, and asks whether to abort the mission. OK ends the battle as aborted, Cancel goes back
  /// </summary>
  TXcomAbortMissionState = class(TXcomState)
  strict private
    FParent: TXcomBattlescapeState;
    FWindow: TXcomWindow;
    FTxtInEntrance: TXcomText;
    FTxtInExit: TXcomText;
    FTxtOutside: TXcomText;
    FTxtAbort: TXcomText;
    FBtnOk: TXcomTextButton;
    FBtnCancel: TXcomTextButton;
    FInEntrance: Integer;
    FInExit: Integer;
    FOutside: Integer;
    procedure CountUnits;
    procedure FindAreas(out AExit, ACraft: Boolean);
    procedure BtnOkClick(AAction: TXcomAction);
    procedure BtnCancelClick(AAction: TXcomAction);
  public
    /// <param name="AParent">The battlescape whose battle is aborted</param>
    constructor Create(AHost: TXcomStateHost; AParent: TXcomBattlescapeState);
    procedure Init; override;
    /// <summary>The soldiers alive on a tile of the start (the craft or the entrance)</summary>
    property InEntrance: Integer read FInEntrance;
    /// <summary>The soldiers alive on a tile of the exit</summary>
    property InExit: Integer read FInExit;
    /// <summary>The soldiers alive anywhere else</summary>
    property Outside: Integer read FOutside;
    property TxtInEntrance: TXcomText read FTxtInEntrance;
    property TxtInExit: TXcomText read FTxtInExit;
    property TxtOutside: TXcomText read FTxtOutside;
    property BtnOk: TXcomTextButton read FBtnOk;
    property BtnCancel: TXcomTextButton read FBtnCancel;
  end;

implementation

uses
  System.Generics.Collections, DelphiDoom.XcomUi.Types, DelphiDoom.XcomMod.MapData,
  DelphiDoom.XcomMod.AlienDeployment, DelphiDoom.XcomMod.MapScript, DelphiDoom.XcomBattle.Model,
  DelphiDoom.XcomBattle.Types, DelphiDoom.XcomBattle.SavedBattleGame, DelphiDoom.XcomBattleStates.Session.Intf;

const
  // SpecialTileType
  START_POINT = 1;
  END_POINT = 13;
  // EscapeType
  ESCAPE_EXIT = 1;
  ESCAPE_EITHER = 3;
  MISSION_BASE_DEFENSE = 'STR_BASE_DEFENSE';

constructor TXcomAbortMissionState.Create(AHost: TXcomStateHost; AParent: TXcomBattlescapeState);
var
  LSession: IXcomBattleSession;
  LExit, LCraft: Boolean;
begin
  inherited Create(AHost);
  FParent := AParent;
  LSession := AParent.Session;
  // the battlescape stays visible behind the window
  ToggleScreen;
  FWindow := TXcomWindow.Create(Self, 320, 144, 0, 0);
  FTxtInEntrance := TXcomText.Create(304, 17, 16, 20);
  FTxtInExit := TXcomText.Create(304, 17, 16, 40);
  FTxtOutside := TXcomText.Create(304, 17, 16, 60);
  FTxtAbort := TXcomText.Create(320, 17, 0, 80);
  FBtnOk := TXcomTextButton.Create(120, 16, 16, 110);
  FBtnCancel := TXcomTextButton.Create(120, 16, 184, 110);
  // SavedBattleGame::setPaletteByDepth
  SetPalette('PAL_BATTLESCAPE', -1);
  SetPalette(LSession.Graphics.Palette(LSession.Battle.Depth), 0, 256);
  LSession.Graphics.SetPalette(@Palette^[0]);
  Add(FWindow, 'messageWindowBorder', 'battlescape');
  Add(FTxtInEntrance, 'messageWindows', 'battlescape');
  Add(FTxtInExit, 'messageWindows', 'battlescape');
  Add(FTxtOutside, 'messageWindows', 'battlescape');
  Add(FTxtAbort, 'messageWindows', 'battlescape');
  Add(FBtnOk, 'messageWindowButtons', 'battlescape');
  Add(FBtnCancel, 'messageWindowButtons', 'battlescape');
  FindAreas(LExit, LCraft);
  CountUnits;
  FWindow.SetHighContrast(True);
  FWindow.SetBackground(LSession.Graphics.Surface('TAC00.SCR'));
  FTxtInEntrance.SetBig;
  FTxtInEntrance.SetHighContrast(True);
  if LCraft then
    FTxtInEntrance.SetText(Tr('STR_UNITS_IN_CRAFT', Cardinal(FInEntrance)))
  else
    FTxtInEntrance.SetText(Tr('STR_UNITS_IN_ENTRANCE', Cardinal(FInEntrance)));
  FTxtInExit.SetBig;
  FTxtInExit.SetHighContrast(True);
  FTxtInExit.SetText(Tr('STR_UNITS_IN_EXIT', Cardinal(FInExit)));
  FTxtOutside.SetBig;
  FTxtOutside.SetHighContrast(True);
  FTxtOutside.SetText(Tr('STR_UNITS_OUTSIDE', Cardinal(FOutside)));
  if LSession.Battle.MissionType = MISSION_BASE_DEFENSE then
  begin
    FTxtInEntrance.Visible := False;
    FTxtInExit.Visible := False;
    FTxtOutside.Visible := False;
  end
  else if not LExit then
  begin
    FTxtInEntrance.Y := 26;
    FTxtOutside.Y := 54;
    FTxtInExit.Visible := False;
  end;
  FTxtAbort.SetBig;
  FTxtAbort.SetAlign(haCenter);
  FTxtAbort.SetHighContrast(True);
  FTxtAbort.SetText(Tr('STR_ABORT_MISSION_QUESTION'));
  FBtnOk.SetText(Tr('STR_OK'));
  FBtnOk.SetHighContrast(True);
  FBtnOk.OnMouseClick(BtnOkClick);
  FBtnOk.OnKeyboardPress(BtnOkClick, Host.Options.KeyOk);
  FBtnCancel.SetText(Tr('STR_CANCEL_UC'));
  FBtnCancel.SetHighContrast(True);
  FBtnCancel.OnMouseClick(BtnCancelClick);
  FBtnCancel.OnKeyboardPress(BtnCancelClick, Host.Options.KeyCancel);
  FBtnCancel.OnKeyboardPress(BtnCancelClick, Host.Options.GetValue('keyBattleAbort'));
  CenterAllSurfaces;
end;

procedure TXcomAbortMissionState.Init;
begin
  inherited Init;
  // State::init, Mod::setPalette: the pictures of the battle follow the palette of the state on screen
  FParent.Session.Graphics.SetPalette(@Palette^[0]);
end;

procedure TXcomAbortMissionState.FindAreas(out AExit, ACraft: Boolean);
var
  LSession: IXcomBattleSession;
  LDeployment: TXcomAlienDeployment;
  LScripts: TObjectList<TXcomMapScript>;
  LScript: TXcomMapScript;
  LIndex: Integer;
  LTile: TXcomTile;
  LFloor: TXcomMapData;
begin
  // check available areas (maybe should be cached somewhere)
  AExit := False;
  ACraft := True;
  LSession := FParent.Session;
  LDeployment := LSession.Ruleset.AlienDeployments.Find(LSession.Battle.MissionType);
  if Assigned(LDeployment) then
  begin
    AExit := (LDeployment.NextStage <> '') or (LDeployment.EscapeType = ESCAPE_EXIT) or
      (LDeployment.EscapeType = ESCAPE_EITHER);
    if LSession.Ruleset.MapScripts.TryGetValue(LDeployment.Script, LScripts) and Assigned(LScripts) then
    begin
      ACraft := False;
      for LScript in LScripts do
        if LScript.CommandType = TXcomMapScript.MSC_ADDCRAFT then
        begin
          ACraft := True;
          Break;
        end;
    end;
  end;
  if not AExit then
    Exit;
  AExit := False;
  for LIndex := 0 to LSession.Battle.MapSizeXyz - 1 do
  begin
    LTile := LSession.Battle.TileByIndex(LIndex);
    if not Assigned(LTile) then
      Continue;
    LFloor := LTile.MapData[XCOM_PART_FLOOR];
    if Assigned(LFloor) and (LFloor.SpecialType = END_POINT) then
    begin
      AExit := True;
      Break;
    end;
  end;
end;

procedure TXcomAbortMissionState.CountUnits;
var
  LBattle: TXcomSavedBattleGame;
  LUnit: TXcomBattleUnit;
  LTile: TXcomTile;
  LFloor: TXcomMapData;
  LSpecial: Integer;
begin
  LBattle := FParent.Session.Battle;
  for LUnit in LBattle.Units do
  begin
    if (LUnit.OriginalFaction <> FACTION_PLAYER) or (LUnit.Status = STATUS_DEAD) or
      (LUnit.Status = STATUS_IGNORE_ME) then
      Continue;
    LSpecial := -1;
    LTile := LBattle.TileAt(LUnit.Position);
    if Assigned(LTile) then
    begin
      LFloor := LTile.MapData[XCOM_PART_FLOOR];
      if Assigned(LFloor) then
        LSpecial := LFloor.SpecialType;
    end;
    if LSpecial = START_POINT then
      Inc(FInEntrance)
    else if LSpecial = END_POINT then
      Inc(FInExit)
    else
      Inc(FOutside);
  end;
end;

procedure TXcomAbortMissionState.BtnOkClick(AAction: TXcomAction);
begin
  Host.PopState;
  FParent.Session.Battle.Aborted := True;
  FParent.FinishBattle(True, FInExit);
end;

procedure TXcomAbortMissionState.BtnCancelClick(AAction: TXcomAction);
begin
  Host.PopState;
end;

end.
