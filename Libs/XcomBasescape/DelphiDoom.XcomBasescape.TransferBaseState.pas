{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom basescape library - TransferBaseState of OpenXcom (the base }
{  to transfer to)                                                              }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBasescape.TransferBaseState;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action,
  DelphiDoom.XcomEngine.State, DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text,
  DelphiDoom.XcomUi.TextButton, DelphiDoom.XcomUi.TextList, DelphiDoom.XcomSave.Base;

type
  /// <summary>The list of the other bases (name and area), to choose where the transfer goes</summary>
  TXcomTransferBaseState = class(TXcomState)
  strict private
    FBase: TXcomBase;
    FBases: TList<TXcomBase>;
    FWindow: TXcomWindow;
    FBtnCancel: TXcomTextButton;
    FTxtTitle: TXcomText;
    FTxtFunds: TXcomText;
    FTxtName: TXcomText;
    FTxtArea: TXcomText;
    FLstBases: TXcomTextList;
    procedure CancelClick(AAction: TXcomAction);
    procedure BasesClick(AAction: TXcomAction);
  public
    /// <param name="ABase">The base that sends (not owned)</param>
    constructor Create(AHost: TXcomStateHost; ABase: TXcomBase);
    destructor Destroy; override;
    property List: TXcomTextList read FLstBases;
  end;

implementation

uses
  DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomSave.Region, DelphiDoom.XcomGeoscape.Strategy,
  DelphiDoom.XcomGeoscape.Funding, DelphiDoom.XcomBasescape.TransferItemsState;

{ TXcomTransferBaseState }

constructor TXcomTransferBaseState.Create(AHost: TXcomStateHost; ABase: TXcomBase);
var
  LSave: TXcomSavedGame;
  LBase: TXcomBase;
  LRegion: TXcomRegion;
  LArea: string;
begin
  inherited Create(AHost);
  FBase := ABase;
  FBases := TList<TXcomBase>.Create;
  LSave := TXcomStrategy.SavedGame(AHost);
  FWindow := TXcomWindow.Create(Self, 280, 140, 20, 30);
  FBtnCancel := TXcomTextButton.Create(264, 16, 28, 146);
  FTxtTitle := TXcomText.Create(270, 17, 25, 38);
  FTxtFunds := TXcomText.Create(250, 9, 30, 54);
  FTxtName := TXcomText.Create(130, 17, 28, 64);
  FTxtArea := TXcomText.Create(130, 17, 160, 64);
  FLstBases := TXcomTextList.Create(Host.Options, Host.Clock, 248, 64, 28, 80);
  SetInterface('transferBaseSelect');
  Add(FWindow, 'window', 'transferBaseSelect');
  Add(FBtnCancel, 'button', 'transferBaseSelect');
  Add(FTxtTitle, 'text', 'transferBaseSelect');
  Add(FTxtFunds, 'text', 'transferBaseSelect');
  Add(FTxtName, 'text', 'transferBaseSelect');
  Add(FTxtArea, 'text', 'transferBaseSelect');
  Add(FLstBases, 'list', 'transferBaseSelect');
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK13.SCR'));
  FBtnCancel.SetText(Tr('STR_CANCEL'));
  FBtnCancel.OnMouseClick(CancelClick);
  FBtnCancel.OnKeyboardPress(CancelClick, Host.Options.KeyCancel);
  FTxtTitle.SetBig;
  FTxtTitle.SetAlign(haCenter);
  FTxtTitle.SetText(Tr('STR_SELECT_DESTINATION_BASE'));
  FTxtFunds.SetText(Tr('STR_CURRENT_FUNDS').Arg(TXcomFunding.Format(LSave.Funds)));
  FTxtName.SetText(Tr('STR_NAME'));
  FTxtName.SetBig;
  FTxtArea.SetText(Tr('STR_AREA'));
  FTxtArea.SetBig;
  FLstBases.SetColumns([130, 116]);
  FLstBases.SetSelectable(True);
  FLstBases.SetBackground(FWindow);
  FLstBases.SetMargin(2);
  FLstBases.OnMouseClick(BasesClick);
  for LBase in LSave.Bases do
    if LBase <> FBase then
    begin
      LArea := '';
      for LRegion in LSave.Regions do
        if LRegion.Rules.IsInside(LBase.Longitude, LBase.Latitude) then
        begin
          LArea := Tr(LRegion.Rules.RegionType).Text;
          Break;
        end;
      FLstBases.AddRow([LBase.Name, Chr(XCOM_TOKEN_COLOR_FLIP) + LArea]);
      FBases.Add(LBase);
    end;
end;

destructor TXcomTransferBaseState.Destroy;
begin
  inherited Destroy;
  FBases.Free;
end;

procedure TXcomTransferBaseState.CancelClick(AAction: TXcomAction);
begin
  Host.PopState;
end;

procedure TXcomTransferBaseState.BasesClick(AAction: TXcomAction);
begin
  Host.PushState(TXcomTransferItemsState.Create(Host, FBase, FBases[FLstBases.GetSelectedRow]));
end;

end.
