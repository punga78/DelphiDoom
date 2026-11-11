{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - the mods of the folders of the disk        }
{  (_scanMods and refreshMods of Options.cpp of OpenXcom)                       }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.DiskModCatalog;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Yaml.Intf, DelphiDoom.XcomEngine.Options,
  DelphiDoom.XcomEngine.ModInfo, DelphiDoom.XcomEngine.ModCatalog.Intf;

type
  /// <summary>
  ///   IXcomModCatalog over folders: each sub folder of the standard folder and of the mods folder of the user is a
  ///   mod (its metadata.yml gives the description; without one the defaults are used). The mods of the games that
  ///   are not installed (xcom1, xcom2) are left out
  /// </summary>
  TXcomDiskModCatalog = class(TInterfacedObject, IXcomModCatalog)
  strict private
    FFolders: TArray<string>;
    FInstalled: TArray<string>;
    FParser: IYamlParser;
    FInfos: TObjectDictionary<string, TXcomModInfo>;
    FMasterMod: string;
    function IsInstalled(const AId: string): Boolean;
    procedure Scan(const AFolder: string);
  public
    /// <param name="AFolders">The folders that hold mods, in order: the standard one, then the one of the user</param>
    /// <param name="AInstalled">The ids of the master mods whose game data is installed (xcom1, xcom2)</param>
    constructor Create(const AFolders, AInstalled: TArray<string>; const AParser: IYamlParser);
    destructor Destroy; override;
    procedure Refresh(var AMods: TArray<TXcomModSetting>);
    function TryGetInfo(const AId: string; out AInfo: TXcomModInfo): Boolean;
    function ActiveMaster: string;
  end;

implementation

uses
  System.IOUtils, System.Generics.Defaults, DelphiDoom.Yaml.Types, DelphiDoom.XcomEngine.Types;

constructor TXcomDiskModCatalog.Create(const AFolders, AInstalled: TArray<string>; const AParser: IYamlParser);
begin
  inherited Create;
  FFolders := AFolders;
  FInstalled := AInstalled;
  FParser := AParser;
  FInfos := TObjectDictionary<string, TXcomModInfo>.Create([doOwnsValues]);
end;

destructor TXcomDiskModCatalog.Destroy;
begin
  FInfos.Free;
  inherited Destroy;
end;

function TXcomDiskModCatalog.IsInstalled(const AId: string): Boolean;
var
  LGame: string;
begin
  // only the two original games need data on the disk
  if (AId <> 'xcom1') and (AId <> 'xcom2') then
    Exit(True);
  for LGame in FInstalled do
    if LGame = AId then
      Exit(True);
  Result := False;
end;

procedure TXcomDiskModCatalog.Scan(const AFolder: string);
var
  LPath: string;
  LInfo: TXcomModInfo;
  LMetadata: string;
begin
  if not TDirectory.Exists(AFolder) then
    Exit;
  for LPath in TDirectory.GetDirectories(AFolder) do
  begin
    LInfo := TXcomModInfo.Create(LPath);
    LMetadata := TPath.Combine(LPath, 'metadata.yml');
    if TFile.Exists(LMetadata) then
      try
        LInfo.Load(FParser.Load(TFile.ReadAllBytes(LMetadata)));
      except
        on E: EYamlException do
        begin
          LInfo.Free;
          raise EXcomEngineException.Create(LMetadata + ': ' + E.Message);
        end;
      end;
    // std::map::insert keeps the first mod that has an id
    if (not IsInstalled(LInfo.Id)) or FInfos.ContainsKey(LInfo.Id) then
      LInfo.Free
    else
      FInfos.Add(LInfo.Id, LInfo);
  end;
end;

procedure TXcomDiskModCatalog.Refresh(var AMods: TArray<TXcomModSetting>);
var
  LFolder: string;
  LMods: TList<TXcomModSetting>;
  LIds: TList<string>;
  LId: string;
  LIndex: Integer;
  LActiveMaster: string;
  LInactiveMaster: string;
  LFound: Boolean;
  LMod: TXcomModSetting;
  LInfo: TXcomModInfo;
begin
  FInfos.Clear;
  for LFolder in FFolders do
    Scan(LFolder);
  LMods := TList<TXcomModSetting>.Create;
  LIds := TList<string>.Create;
  try
    LMods.AddRange(AMods);
    // remove mods from the list that no longer exist
    for LIndex := LMods.Count - 1 downto 0 do
      if not FInfos.ContainsKey(LMods[LIndex].Id) then
        LMods.Delete(LIndex);
    // the std::map goes by id, compared as bytes
    LIds.AddRange(FInfos.Keys);
    LIds.Sort(TComparer<string>.Construct(
      function(const ALeft, ARight: string): Integer
      begin
        Result := CompareStr(ALeft, ARight);
      end));
    LActiveMaster := '';
    LInactiveMaster := '';
    for LId in LIds do
    begin
      LInfo := FInfos[LId];
      LFound := False;
      for LIndex := 0 to LMods.Count - 1 do
        if LMods[LIndex].Id = LId then
        begin
          LFound := True;
          LMod := LMods[LIndex];
          if LInfo.IsMaster then
          begin
            if FMasterMod <> '' then
              LMod.Active := FMasterMod = LId;
            if LMod.Active then
            begin
              if LActiveMaster <> '' then
                LMod.Active := False
              else
                LActiveMaster := LId;
            end
            else if (LInactiveMaster = '') or (LId = 'xcom1') or (LId = 'xcom2') then
              LInactiveMaster := LId;
            LMods[LIndex] := LMod;
          end;
          Break;
        end;
      if LFound then
        Continue;
      // not active by default
      LMod := TXcomModSetting.Create(LId, False);
      if LInfo.IsMaster then
      begin
        LMods.Insert(0, LMod);
        if LInactiveMaster = '' then
          LInactiveMaster := LId;
      end
      else
        LMods.Add(LMod);
    end;
    if LActiveMaster = '' then
    begin
      if LInactiveMaster = '' then
        raise EXcomEngineException.Create('No X-COM installations found');
      for LIndex := 0 to LMods.Count - 1 do
        if (LMods[LIndex].Id = LInactiveMaster) and not LMods[LIndex].Active then
        begin
          LMod := LMods[LIndex];
          LMod.Active := True;
          LMods[LIndex] := LMod;
          Break;
        end;
      FMasterMod := LInactiveMaster;
    end
    else
      FMasterMod := LActiveMaster;
    AMods := LMods.ToArray;
  finally
    LIds.Free;
    LMods.Free;
  end;
end;

function TXcomDiskModCatalog.TryGetInfo(const AId: string; out AInfo: TXcomModInfo): Boolean;
begin
  Result := FInfos.TryGetValue(AId, AInfo);
end;

function TXcomDiskModCatalog.ActiveMaster: string;
begin
  Result := FMasterMod;
end;

end.
