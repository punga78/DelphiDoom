{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - the description of a mod (ModInfo of       }
{  OpenXcom, read from the metadata.yml of the folder of the mod)               }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.ModInfo;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Intf;

type
  /// <summary>What metadata.yml says of a mod, with the defaults of ModInfo for the keys it leaves out</summary>
  TXcomModInfo = class
  strict private
    FPath: string;
    FName: string;
    FDescription: string;
    FVersion: string;
    FAuthor: string;
    FId: string;
    FMaster: string;
    FIsMaster: Boolean;
    FReservedSpace: Integer;
    FEngineOk: Boolean;
  public
    /// <param name="APath">The folder of the mod: its name is the default name and id</param>
    constructor Create(const APath: string);
    /// <summary>ModInfo::load: reads the document of metadata.yml</summary>
    procedure Load(const ADocument: IYamlNode);
    /// <summary>
    ///   ModInfo::canActivate: a master, a mod with no master or one that depends on the master in use can be
    ///   switched on
    /// </summary>
    function CanActivate(const ACurrentMaster: string): Boolean;
    property Path: string read FPath;
    property Name: string read FName;
    property Description: string read FDescription;
    property Version: string read FVersion;
    property Author: string read FAuthor;
    property Id: string read FId;
    property Master: string read FMaster;
    property IsMaster: Boolean read FIsMaster;
    property ReservedSpace: Integer read FReservedSpace;
    /// <summary>The engine this program is can run the mod: it asks for no extended engine (OPENXCOM_VERSION_ENGINE is empty)</summary>
    property EngineOk: Boolean read FEngineOk;
  end;

implementation

uses
  DelphiDoom.XcomEngine.YamlFields;

constructor TXcomModInfo.Create(const APath: string);
begin
  inherited Create;
  FPath := APath;
  FName := ExtractFileName(ExcludeTrailingPathDelimiter(APath));
  FDescription := 'No description.';
  FVersion := '1.0';
  FAuthor := 'unknown author';
  FId := FName;
  FMaster := 'xcom1';
  FReservedSpace := 1;
end;

procedure TXcomModInfo.Load(const ADocument: IYamlNode);
var
  LEngine: string;
begin
  FName := TXcomYamlFields.ReadString(ADocument, 'name', FName);
  FDescription := TXcomYamlFields.ReadString(ADocument, 'description', FDescription);
  FVersion := TXcomYamlFields.ReadString(ADocument, 'version', FVersion);
  FAuthor := TXcomYamlFields.ReadString(ADocument, 'author', FAuthor);
  FId := TXcomYamlFields.ReadString(ADocument, 'id', FId);
  FIsMaster := TXcomYamlFields.ReadBoolean(ADocument, 'isMaster', FIsMaster);
  FReservedSpace := TXcomYamlFields.ReadInteger(ADocument, 'reservedSpace', FReservedSpace);
  // requiredExtendedVersion is the old name of an extended engine called "Extended"
  LEngine := '';
  if Assigned(TXcomYamlFields.Field(ADocument, 'requiredExtendedVersion')) then
    LEngine := 'Extended';
  LEngine := TXcomYamlFields.ReadString(ADocument, 'requiredExtendedEngine', LEngine);
  // the engine of this program is "" and the supported engines are it and "" (every engine runs the base game)
  FEngineOk := LEngine = '';
  if FReservedSpace < 1 then
    FReservedSpace := 1
  else if FReservedSpace > 100 then
    FReservedSpace := 100;
  // a master has no master unless it says so
  if FIsMaster then
    FMaster := '';
  FMaster := TXcomYamlFields.ReadString(ADocument, 'master', FMaster);
  if FMaster = '*' then
    FMaster := '';
end;

function TXcomModInfo.CanActivate(const ACurrentMaster: string): Boolean;
begin
  Result := FIsMaster or (FMaster = '') or (FMaster = ACurrentMaster);
end;

end.
