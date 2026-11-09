{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ruleset library - loading the mods (Mod::loadAll and        }
{  Mod::loadMod)                                                                }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMod.ModLoader;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.Types, DelphiDoom.XcomMod.ModOffsets,
  DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomMod.ModFiles.Intf;

type
  /// <summary>A mod to load: its id, the space it reserves in the common sets and its ruleset files in order</summary>
  TXcomModSource = record
    /// <summary>The id of the mod (a name that is not master or current and is not used twice)</summary>
    Name: string;
    /// <summary>ModInfo::getReservedSpace: how many thousands of resources of each common set it may add</summary>
    ReservedSpace: Cardinal;
    /// <summary>The ruleset files of the mod, in the order the engine loads them</summary>
    Files: TArray<string>;
    /// <summary>
    ///   The resource config file of the mod (ModInfo::getResourceConfigFile: sound definitions and transparency
    ///   colors), read before the rulesets of all the mods; empty if the mod has none
    /// </summary>
    ResourceConfigFile: string;
    class function Make(const AName: string; AReservedSpace: Cardinal; const AFiles: TArray<string>;
      const AResourceConfigFile: string = ''): TXcomModSource; static;
  end;

  /// <summary>
  ///   Mod::loadAll for the rules: gives each mod its place in the common sets (offset = 1000 x the space of the
  ///   mods before, size = 1000 x its own space) and loads the files of every mod in order. The resources are
  ///   not loaded here: their sizes come from IXcomSharedResources
  /// </summary>
  TXcomModLoader = class
  strict private
    FParser: IYamlParser;
    FShared: IXcomSharedResources;
    FFiles: IXcomModFiles;
  public
    /// <param name="AFiles">The virtual files of the mods (soldier names); nil if there are none</param>
    constructor Create(const AParser: IYamlParser; const AShared: IXcomSharedResources;
      const AFiles: IXcomModFiles = nil);
    /// <summary>
    ///   A new ruleset (the caller frees it). An error of a file is EXcomModException: "failed to load 'mod'" and
    ///   the text "file: message" of Mod::loadMod, as the C++ throws it
    /// </summary>
    function LoadAll(const AMods: TArray<TXcomModSource>): TXcomRuleset;
  end;

implementation

uses
  DelphiDoom.Yaml.Types;

resourcestring
  SModLoaderFailed = 'failed to load ''%s''';
  SModLoaderNameUsed = 'this mod name is already used';

/// <summary>throwModOnErrorHelper: the message of a mod that fails to load</summary>
function Failure(const AModName, AError: string): string;
begin
  Result := Format(SModLoaderFailed, [AModName]) + sLineBreak + AError;
end;

{ TXcomModSource }

class function TXcomModSource.Make(const AName: string; AReservedSpace: Cardinal; const AFiles: TArray<string>;
  const AResourceConfigFile: string): TXcomModSource;
begin
  Result.ResourceConfigFile := AResourceConfigFile;
  Result.Name := AName;
  Result.ReservedSpace := AReservedSpace;
  Result.Files := AFiles;
end;

{ TXcomModLoader }

constructor TXcomModLoader.Create(const AParser: IYamlParser; const AShared: IXcomSharedResources;
  const AFiles: IXcomModFiles);
begin
  inherited Create;
  if not Assigned(AParser) then
    raise EArgumentNilException.Create('AParser');
  if not Assigned(AShared) then
    raise EArgumentNilException.Create('AShared');
  FParser := AParser;
  FShared := AShared;
  FFiles := AFiles;
end;

function TXcomModLoader.LoadAll(const AMods: TArray<TXcomModSource>): TXcomRuleset;
var
  LData: TArray<TXcomModData>;
  LIndex, LFile, LUsed: Integer;
  LOffset: Cardinal;
  LFileName: string;
begin
  SetLength(LData, Length(AMods));
  LOffset := 0;
  for LIndex := 0 to High(AMods) do
  begin
    if (AMods[LIndex].Name = TXcomModOffsets.MOD_NAME_MASTER) or
      (AMods[LIndex].Name = TXcomModOffsets.MOD_NAME_CURRENT) then
      raise EXcomModException.Create(Failure(AMods[LIndex].Name, SModLoaderNameUsed));
    for LUsed := 0 to LIndex - 1 do
      if AMods[LUsed].Name = AMods[LIndex].Name then
        raise EXcomModException.Create(Failure(AMods[LIndex].Name, SModLoaderNameUsed));
    LData[LIndex] := TXcomModData.Make(AMods[LIndex].Name, 1000 * LOffset, 1000 * AMods[LIndex].ReservedSpace);
    Inc(LOffset, AMods[LIndex].ReservedSpace);
  end;
  Result := TXcomRuleset.Create(FShared, FFiles);
  try
    // the rulesets that can change how the vanilla resources load come first
    for LIndex := 0 to High(AMods) do
      if AMods[LIndex].ResourceConfigFile <> '' then
      begin
        Result.SetMods(LData, LIndex);
        Result.LoadResourceConfig(FParser.LoadFile(AMods[LIndex].ResourceConfigFile));
      end;
    for LIndex := 0 to High(AMods) do
    begin
      Result.SetMods(LData, LIndex);
      try
        for LFile := 0 to High(AMods[LIndex].Files) do
        begin
          LFileName := AMods[LIndex].Files[LFile];
          try
            Result.LoadFile(FParser.LoadFile(LFileName));
          except
            on LError: EYamlException do
              raise EXcomModException.Create(LFileName + ': ' + LError.Message);
          end;
        end;
        Result.ValidateMissions;
      except
        on LError: EXcomModException do
          raise EXcomModException.Create(Failure(AMods[LIndex].Name, LError.Message));
      end;
    end;
    // back to the master, then sort
    Result.SetMods(LData, 0);
    Result.SortLists;
  except
    Result.Free;
    raise;
  end;
end;

end.
