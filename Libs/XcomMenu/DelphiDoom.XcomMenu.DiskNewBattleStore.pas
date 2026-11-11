{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom menu library - battle.cfg on disk                           }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMenu.DiskNewBattleStore;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMenu.NewBattle.Intf;

type
  /// <summary>
  ///   IXcomNewBattleStore on a file (NewBattleState::load and save with their "battle" name): a file that is not
  ///   there or is not YAML gives nil, a folder that cannot be written is ignored as the C++ does (it only logs)
  /// </summary>
  TXcomDiskNewBattleStore = class(TInterfacedObject, IXcomNewBattleStore)
  strict private
    FFileName: string;
  public
    /// <param name="AFolder">Options::getMasterUserFolder</param>
    constructor Create(const AFolder: string);
    function Load: IYamlNode;
    procedure Save(const ADocument: IYamlNode);
  end;

const
  XCOM_NEW_BATTLE_FILE = 'battle.cfg';

implementation

uses
  System.Classes, System.IOUtils, DelphiDoom.Yaml.Types, DelphiDoom.Yaml.Factory;

constructor TXcomDiskNewBattleStore.Create(const AFolder: string);
begin
  inherited Create;
  FFileName := TPath.Combine(AFolder, XCOM_NEW_BATTLE_FILE);
end;

function TXcomDiskNewBattleStore.Load: IYamlNode;
begin
  Result := nil;
  if not TFile.Exists(FFileName) then
    Exit;
  try
    Result := TYamlFactory.CreateParser.Load(TFile.ReadAllBytes(FFileName));
  except
    // YAML::Exception: the screen starts from the defaults
    on EYamlException do
      Result := nil;
  end;
end;

procedure TXcomDiskNewBattleStore.Save(const ADocument: IYamlNode);
begin
  try
    TDirectory.CreateDirectory(ExtractFilePath(FFileName));
    TFile.WriteAllBytes(FFileName, BytesOf(TYamlFactory.Dump(ADocument)));
  except
    // "Failed to save battle.cfg": the battle goes on without the file
    on EInOutError do
      ;
    on EFOpenError do
      ;
    on EFCreateError do
      ;
  end;
end;

end.
