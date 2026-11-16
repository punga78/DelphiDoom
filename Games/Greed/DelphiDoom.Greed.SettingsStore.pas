{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the file of the settings                         }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): M_LoadDefaults and          }
{  M_SaveDefaults of m_defs.pas                                                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.SettingsStore;

interface

uses
  System.SysUtils, DelphiDoom.Greed.Save.Intf, DelphiDoom.Greed.Settings.Intf;

type
  /// <summary>
  ///   The file xGreed.ini (or the one of -config) in the folder of the game: a text file in the code page of the
  ///   system, as TStringList.LoadFromFile and SaveToFile give it
  /// </summary>
  TGreedSettingsStore = class(TInterfacedObject, IGreedSettingsStore)
  strict private
    FFiles: IGreedSaveFiles;
    FFileName: string;
  public
    constructor Create(const AFiles: IGreedSaveFiles; const AFileName: string);
    function Load(const ASettings: IGreedSettings; ACommandLineGame: Integer): Boolean;
    procedure Save(const ASettings: IGreedSettings);
  end;

const
  /// <summary>basedefault of m_defs.pas: APPNAME + '.ini'</summary>
  GREED_SETTINGS_FILE = 'xGreed.ini';

implementation

{ TGreedSettingsStore }

constructor TGreedSettingsStore.Create(const AFiles: IGreedSaveFiles; const AFileName: string);
begin
  inherited Create;
  if not Assigned(AFiles) then
    raise EArgumentNilException.Create('AFiles');
  FFiles := AFiles;
  FFileName := AFileName;
end;

function TGreedSettingsStore.Load(const ASettings: IGreedSettings; ACommandLineGame: Integer): Boolean;
var
  LBytes: TBytes;
  LEncoding: TEncoding;
  LSize: Integer;
begin
  ASettings.Reset;
  Result := False;
  if FFiles.Exists(FFileName) then
  begin
    LBytes := FFiles.ReadAll(FFileName);
    LEncoding := nil;
    LSize := TEncoding.GetBufferEncoding(LBytes, LEncoding, TEncoding.Default);
    Result := ASettings.LoadFromText(LEncoding.GetString(LBytes, LSize, Length(LBytes) - LSize));
  end;
  ASettings.ApplyCommandLineGame(ACommandLineGame);
end;

procedure TGreedSettingsStore.Save(const ASettings: IGreedSettings);
begin
  FFiles.WriteAll(FFileName, TEncoding.Default.GetBytes(ASettings.SaveToText));
end;

end.
