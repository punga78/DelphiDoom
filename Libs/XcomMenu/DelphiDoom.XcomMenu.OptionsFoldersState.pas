{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom menu library - OptionsFoldersState of OpenXcom (where the data and the user files are)
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}unit DelphiDoom.XcomMenu.OptionsFoldersState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomEngine.InteractiveSurface, DelphiDoom.XcomUi.Text, DelphiDoom.XcomMenu.OptionsTypes,
  DelphiDoom.XcomMenu.OptionsNavigator.Intf, DelphiDoom.XcomMenu.OptionsBaseState;

type
  /// <summary>
  ///   The folders of the game (original data, mod data, user, saves, configuration) as texts; a click on a path asks
  ///   the host to open the folder (the file explorer on Windows)
  /// </summary>
  TXcomOptionsFoldersState = class(TXcomOptionsBaseState)
  strict private
    FTxtDataFolder: TXcomText;
    FTxtUserFolder: TXcomText;
    FTxtSaveFolder: TXcomText;
    FTxtConfigFolder: TXcomText;
    FTxtDataFolderPath1: TXcomText;
    FTxtDataFolderPath2: TXcomText;
    FTxtUserFolderPath: TXcomText;
    FTxtSaveFolderPath: TXcomText;
    FTxtConfigFolderPath: TXcomText;
    procedure Path(AText: TXcomText; const APath, ATooltip: string);
    procedure PathClick(AAction: TXcomAction);
  public
    constructor Create(AHost: TXcomStateHost; AOrigin: TXcomOptionsOrigin; const ANavigator: IXcomOptionsNavigator);
  end;

implementation

procedure TXcomOptionsFoldersState.Path(AText: TXcomText; const APath, ATooltip: string);
begin
  AText.SetText(APath);
  AText.SetWordWrap(True);
  AText.Tooltip := ATooltip;
  AText.OnMouseIn(TooltipIn);
  AText.OnMouseOut(TooltipOut);
  AText.OnMouseClick(PathClick);
end;

constructor TXcomOptionsFoldersState.Create(AHost: TXcomStateHost; AOrigin: TXcomOptionsOrigin;
  const ANavigator: IXcomOptionsNavigator);
begin
  inherited Create(AHost, AOrigin, ANavigator);
  SetCategory(FBtnFolders);
  FTxtDataFolder := TXcomText.Create(218, 9, 94, 8);
  FTxtUserFolder := TXcomText.Create(218, 9, 94, 59);
  FTxtSaveFolder := TXcomText.Create(218, 9, 94, 86);
  FTxtConfigFolder := TXcomText.Create(218, 9, 94, 121);
  FTxtDataFolderPath1 := TXcomText.Create(218, 17, 94, 18);
  FTxtDataFolderPath2 := TXcomText.Create(218, 17, 94, 38);
  FTxtUserFolderPath := TXcomText.Create(218, 17, 94, 69);
  FTxtSaveFolderPath := TXcomText.Create(218, 25, 94, 96);
  FTxtConfigFolderPath := TXcomText.Create(218, 17, 94, 131);
  Add(FTxtDataFolder, 'text1', 'foldersMenu');
  Add(FTxtUserFolder, 'text1', 'foldersMenu');
  Add(FTxtSaveFolder, 'text1', 'foldersMenu');
  Add(FTxtConfigFolder, 'text1', 'foldersMenu');
  Add(FTxtDataFolderPath1, 'text2', 'foldersMenu');
  Add(FTxtDataFolderPath2, 'text2', 'foldersMenu');
  Add(FTxtUserFolderPath, 'text2', 'foldersMenu');
  Add(FTxtSaveFolderPath, 'text2', 'foldersMenu');
  Add(FTxtConfigFolderPath, 'text2', 'foldersMenu');
  CenterAllSurfaces;
  FTxtDataFolder.SetText(Tr('STR_DATA_FOLDER'));
  FTxtUserFolder.SetText(Tr('STR_USER_FOLDER'));
  FTxtSaveFolder.SetText(Tr('STR_SAVE_FOLDER'));
  FTxtConfigFolder.SetText(Tr('STR_CONFIG_FOLDER'));
  Path(FTxtDataFolderPath1, Host.Options.OriginalDataFolder, 'STR_DATA_FOLDER_DESC_1');
  Path(FTxtDataFolderPath2, Host.Options.ModDataFolder, 'STR_DATA_FOLDER_DESC_2');
  Path(FTxtUserFolderPath, Host.Options.UserFolder, 'STR_USER_FOLDER_DESC');
  Path(FTxtSaveFolderPath, Host.Options.MasterUserFolder, 'STR_SAVE_FOLDER_DESC');
  Path(FTxtConfigFolderPath, Host.Options.ConfigFolder, 'STR_CONFIG_FOLDER_DESC');
end;

procedure TXcomOptionsFoldersState.PathClick(AAction: TXcomAction);
begin
  Host.OpenFolder(TXcomText(AAction.Sender).GetText);
end;

end.