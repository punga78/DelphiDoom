{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the xcom ruleset library - the real mods of TFTD and UFO       }
{  (the manifest of a golden of modload.exe and the files it names)             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later)               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomMod.RealData;

interface

uses
  DelphiDoom.Tests.Shared.Files,
  System.SysUtils, System.Classes, System.Generics.Collections, DelphiDoom.XcomMod.ModOffsets,
  DelphiDoom.XcomMod.ModLoader, DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomMod.ModFiles.Intf;

type
  /// <summary>The sizes of the common sets that the real Mod had when the golden was written</summary>
  TXcomGoldenShared = class(TInterfacedObject, IXcomSharedResources)
  strict private
    FSprites: TDictionary<string, Integer>;
    FSounds: TDictionary<string, Integer>;
  public
    constructor Create(const ASprites, ASounds: TDictionary<string, Integer>);
    function MaxSharedSounds(const ASet: string): Integer;
    function MaxSharedFrames(const ASet: string): Integer;
  end;

  /// <summary>
  ///   A golden of modload.exe: the lines of the manifest (mods, files, shared sets) and the lines of the
  ///   rules, and the means to load the same mods with the library
  /// </summary>
  TXcomRealData = class
  strict private
    FGolden: TStringList;
    FSprites: TDictionary<string, Integer>;
    FSounds: TDictionary<string, Integer>;
    FSources: TList<TXcomModSource>;
    FDataFolder: string;
    FGameFolder: string;
    class function ParseList(const AText: string): TArray<string>; static;
    procedure ParseManifest;
  public
    /// <param name="AGoldenName">The file in Tests\Data\XcomMod</param>
    constructor Create(const AGoldenName: string);
    destructor Destroy; override;
    /// <summary>The folder of the data of the C++ run (the standard mods are in standard\): empty if it is missing</summary>
    function DataFolder: string;
    /// <summary>Loads the mods of the manifest; the caller frees the ruleset</summary>
    function Load: TXcomRuleset;
    /// <summary>The virtual files of the mods and the game (what Load reads the ruleset from)</summary>
    function CreateFiles: IXcomModFiles;
    /// <summary>The golden lines of the sections in ASections, in the order of the golden</summary>
    function RuleLines(const ASections: TArray<string>): TStringList;
    property Golden: TStringList read FGolden;
  end;

implementation

uses
  System.ZLib, DelphiDoom.Tests.XcomMod.DiskModFiles, DelphiDoom.XcomMod.Types, DelphiDoom.Yaml.Factory;

{ TXcomGoldenShared }

constructor TXcomGoldenShared.Create(const ASprites, ASounds: TDictionary<string, Integer>);
begin
  inherited Create;
  FSprites := ASprites;
  FSounds := ASounds;
end;

function TXcomGoldenShared.MaxSharedSounds(const ASet: string): Integer;
begin
  if not FSounds.TryGetValue(ASet, Result) then
    raise EXcomModException.CreateFmt('Sound Set %s not found', [ASet]);
end;

function TXcomGoldenShared.MaxSharedFrames(const ASet: string): Integer;
begin
  if not FSprites.TryGetValue(ASet, Result) then
    raise EXcomModException.CreateFmt('Sprite Set %s not found', [ASet]);
end;

{ TXcomRealData }

class function TXcomRealData.ParseList(const AText: string): TArray<string>;
var
  LInner: string;
  LParts: TArray<string>;
  LIndex: Integer;
begin
  // ['a','b'] with the quote of every item; the names of files have no quote, comma or backslash
  LInner := Copy(AText, 2, Length(AText) - 2);
  if LInner = '' then
    Exit(nil);
  LParts := LInner.Split([',']);
  SetLength(Result, Length(LParts));
  for LIndex := 0 to High(LParts) do
    Result[LIndex] := Copy(LParts[LIndex], 2, Length(LParts[LIndex]) - 2);
end;

constructor TXcomRealData.Create(const AGoldenName: string);
var
  LPath: string;
  LSource: TFileStream;
  LUnzipped: TDecompressionStream;
begin
  inherited Create;
  FGolden := TStringList.Create;
  FSprites := TDictionary<string, Integer>.Create;
  FSounds := TDictionary<string, Integer>.Create;
  FSources := TList<TXcomModSource>.Create;
  // the golden is committed gzipped
  LPath := TTestFiles.FindUp('Tests\Data\XcomMod\' + AGoldenName + '.gz', False);
  if LPath = '' then
    raise Exception.CreateFmt('Golden %s not found', [AGoldenName]);
  LSource := TFileStream.Create(LPath, fmOpenRead or fmShareDenyWrite);
  try
    LUnzipped := TDecompressionStream.Create(LSource, 15 + 16);
    try
      FGolden.LoadFromStream(LUnzipped, TEncoding.UTF8);
    finally
      LUnzipped.Free;
    end;
  finally
    LSource.Free;
  end;
  // the goldens of UFO (ufo.*) come from Reference\_dati\xcom_ufo\openxcom, the others from the TFTD one
  if Copy(AGoldenName, 1, 4) = 'ufo.' then
  begin
    FDataFolder := TTestFiles.FindUp('Reference\_dati\xcom_ufo\openxcom', True);
    FGameFolder := 'UFO';
  end
  else
  begin
    FDataFolder := TTestFiles.FindUp('Reference\_dati\xcom_tftd\openxcom', True);
    FGameFolder := 'TFTD';
  end;
  ParseManifest;
end;

destructor TXcomRealData.Destroy;
begin
  FSources.Free;
  FSounds.Free;
  FSprites.Free;
  FGolden.Free;
  inherited Destroy;
end;

procedure TXcomRealData.ParseManifest;
var
  LLine, LName, LKey, LValue: string;
  LParts: TArray<string>;
  LSizes: TDictionary<string, Cardinal>;
  LFiles: TDictionary<string, TArray<string>>;
  LOrder: TList<string>;
  LSource: TXcomModSource;
  LText: string;
begin
  LSizes := TDictionary<string, Cardinal>.Create;
  LFiles := TDictionary<string, TArray<string>>.Create;
  LOrder := TList<string>.Create;
  try
    for LLine in FGolden do
    begin
      LParts := LLine.Split(['|'], 3);
      if Length(LParts) < 3 then
        Continue;
      LName := LParts[1];
      LText := LParts[2];
      LKey := Copy(LText, 1, Pos('=', LText) - 1);
      LValue := Copy(LText, Pos('=', LText) + 1, MaxInt);
      if LParts[0] = 'mods' then
      begin
        if LKey = 'size' then
        begin
          LSizes.Add(LName, StrToUInt(LValue));
          LOrder.Add(LName);
        end;
      end
      else if LParts[0] = 'files' then
        LFiles.Add(LName, ParseList(LValue))
      else if LParts[0] = 'sprites' then
        FSprites.Add(LName, StrToInt(LValue))
      else if LParts[0] = 'sounds' then
        FSounds.Add(LName, StrToInt(LValue));
    end;
    for LName in LOrder do
    begin
      LSource := TXcomModSource.Make(LName, LSizes[LName] div 1000, LFiles[LName]);
      FSources.Add(LSource);
    end;
  finally
    LOrder.Free;
    LFiles.Free;
    LSizes.Free;
  end;
end;

function TXcomRealData.DataFolder: string;
begin
  Result := FDataFolder;
end;

function TXcomRealData.CreateFiles: IXcomModFiles;
var
  LSources: TArray<TXcomModSource>;
  LIndex: Integer;
  LRoots: TList<string>;
  LFolder: string;
begin
  LSources := FSources.ToArray;
  LRoots := TList<string>.Create;
  try
    for LIndex := 0 to High(LSources) do
      // the folder of the mod: the later a mod, the sooner its files are found
      if Length(LSources[LIndex].Files) > 0 then
      begin
        LFolder := ExtractFilePath(IncludeTrailingPathDelimiter(FDataFolder) +
          StringReplace(LSources[LIndex].Files[0], '/', '\', [rfReplaceAll]));
        LRoots.Insert(0, LFolder);
      end;
    LRoots.Add(IncludeTrailingPathDelimiter(FDataFolder) + 'common');
    // the data folder of the game (GEODATA\WORLD.DAT of the globe)
    LRoots.Add(IncludeTrailingPathDelimiter(FDataFolder) + FGameFolder);
    Result := TXcomDiskModFiles.Create(LRoots.ToArray, TYamlFactory.CreateDiskParser);
  finally
    LRoots.Free;
  end;
end;

function TXcomRealData.Load: TXcomRuleset;
var
  LLoader: TXcomModLoader;
  LSources: TArray<TXcomModSource>;
  LIndex, LFile: Integer;
begin
  LSources := FSources.ToArray;
  for LIndex := 0 to High(LSources) do
  begin
    LSources[LIndex].Files := Copy(LSources[LIndex].Files);
    for LFile := 0 to High(LSources[LIndex].Files) do
      LSources[LIndex].Files[LFile] := IncludeTrailingPathDelimiter(FDataFolder) +
        StringReplace(LSources[LIndex].Files[LFile], '/', '\', [rfReplaceAll]);
  end;
  LLoader := TXcomModLoader.Create(TYamlFactory.CreateDiskParser, TXcomGoldenShared.Create(FSprites, FSounds),
    CreateFiles);
  try
    Result := LLoader.LoadAll(LSources);
  finally
    LLoader.Free;
  end;
end;

function TXcomRealData.RuleLines(const ASections: TArray<string>): TStringList;
var
  LSection: string;
  LLine: string;
begin
  Result := TStringList.Create;
  for LSection in ASections do
    for LLine in FGolden do
      if Copy(LLine, 1, Length(LSection) + 1) = LSection + '|' then
        Result.Add(LLine);
end;

end.
