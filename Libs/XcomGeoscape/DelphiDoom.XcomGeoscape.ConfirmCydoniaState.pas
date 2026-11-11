{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom geoscape library - ConfirmCydoniaState of OpenXcom (the     }
{  craft leaves for the last mission: Cydonia, or T'leth)                       }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomGeoscape.ConfirmCydoniaState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State, DelphiDoom.XcomUi.Window,
  DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton, DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomSave.Craft,
  DelphiDoom.XcomGeoscape.MissionLauncher.Intf;

type
  /// <summary>
  ///   "Are you sure you want to send this craft to the last mission?": Yes pops this screen and the one below
  ///   (the choice of the destination) and starts the battle of the first deployment of the rules that is a final
  ///   destination, with the race of that deployment; No goes back
  /// </summary>
  TXcomConfirmCydoniaState = class(TXcomState)
  strict private
    FCraft: TXcomCraft;
    FRuleset: TXcomRuleset;
    FLauncher: IXcomMissionLauncher;
    FWindow: TXcomWindow;
    FBtnYes: TXcomTextButton;
    FBtnNo: TXcomTextButton;
    FTxtMessage: TXcomText;
    procedure YesClick(AAction: TXcomAction);
    procedure NoClick(AAction: TXcomAction);
  public
    /// <param name="ACraft">The craft that leaves (not owned)</param>
    /// <param name="ARuleset">The rules, for the deployment of the last mission (not owned)</param>
    /// <param name="ALauncher">Starts the battle; nil: Yes only closes the screens</param>
    constructor Create(AHost: TXcomStateHost; ACraft: TXcomCraft; ARuleset: TXcomRuleset;
      const ALauncher: IXcomMissionLauncher);
    /// <summary>What Yes gives to the launcher: the mission type is empty when the rules have no final destination</summary>
    function Request: TXcomMissionRequest;
    property YesButton: TXcomTextButton read FBtnYes;
    property NoButton: TXcomTextButton read FBtnNo;
  end;

implementation

uses
  DelphiDoom.XcomUi.Types, DelphiDoom.XcomMod.AlienDeployment;

{ TXcomConfirmCydoniaState }

constructor TXcomConfirmCydoniaState.Create(AHost: TXcomStateHost; ACraft: TXcomCraft; ARuleset: TXcomRuleset;
  const ALauncher: IXcomMissionLauncher);
begin
  inherited Create(AHost);
  FCraft := ACraft;
  FRuleset := ARuleset;
  FLauncher := ALauncher;
  ToggleScreen;
  FWindow := TXcomWindow.Create(Self, 256, 160, 32, 20);
  FBtnYes := TXcomTextButton.Create(80, 20, 70, 142);
  FBtnNo := TXcomTextButton.Create(80, 20, 170, 142);
  FTxtMessage := TXcomText.Create(224, 48, 48, 76);
  SetInterface('confirmCydonia');
  Add(FWindow, 'window', 'confirmCydonia');
  Add(FBtnYes, 'button', 'confirmCydonia');
  Add(FBtnNo, 'button', 'confirmCydonia');
  Add(FTxtMessage, 'text', 'confirmCydonia');
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK12.SCR'));
  FBtnYes.SetText(Tr('STR_YES'));
  FBtnYes.OnMouseClick(YesClick);
  FBtnYes.OnKeyboardPress(YesClick, Host.Options.KeyOk);
  FBtnNo.SetText(Tr('STR_NO'));
  FBtnNo.OnMouseClick(NoClick);
  FBtnNo.OnKeyboardPress(NoClick, Host.Options.KeyCancel);
  FTxtMessage.SetAlign(haCenter);
  FTxtMessage.SetBig;
  FTxtMessage.SetWordWrap(True);
  FTxtMessage.SetText(Tr('STR_ARE_YOU_SURE_CYDONIA'));
end;

function TXcomConfirmCydoniaState.Request: TXcomMissionRequest;
var
  LName: string;
  LDeployment: TXcomAlienDeployment;
begin
  Result := Default(TXcomMissionRequest);
  Result.Craft := FCraft;
  Result.WorldTexture := -1;
  for LName in FRuleset.AlienDeployments.Index do
  begin
    LDeployment := FRuleset.AlienDeployments.Find(LName);
    if LDeployment.FinalDestination then
    begin
      Result.MissionType := LName;
      Result.AlienRace := LDeployment.Race;
      Break;
    end;
  end;
end;

procedure TXcomConfirmCydoniaState.YesClick(AAction: TXcomAction);
var
  LRequest: TXcomMissionRequest;
  LLauncher: IXcomMissionLauncher;
begin
  LRequest := Request;
  LLauncher := FLauncher;
  Host.PopState;
  Host.PopState;
  if Assigned(LLauncher) then
    LLauncher.BeginMission(LRequest);
end;

procedure TXcomConfirmCydoniaState.NoClick(AAction: TXcomAction);
begin
  Host.PopState;
end;

end.
