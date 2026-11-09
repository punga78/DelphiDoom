{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ruleset library - a type of soldier (RuleSoldier)           }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMod.RuleSoldier;

interface

uses
  System.SysUtils, System.Generics.Collections, System.Generics.Defaults, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.NodeReader,
  DelphiDoom.XcomMod.ModOffsets, DelphiDoom.XcomMod.UnitStats, DelphiDoom.XcomMod.ModFiles.Intf,
  DelphiDoom.XcomMod.SoldierNamePool;

type
  /// <summary>
  ///   Constant data of a type of soldier: stats range and caps, armor, costs, heights, death sounds and the
  ///   pools of names (RuleSoldier). It owns the pools
  /// </summary>
  TXcomRuleSoldier = class
  strict private
    FType: string;
    FRequires: TArray<string>;
    FMinStats: TXcomUnitStats;
    FMaxStats: TXcomUnitStats;
    FStatCaps: TXcomUnitStats;
    FArmor: string;
    FCostBuy: Integer;
    FCostSalary: Integer;
    FStandHeight: Integer;
    FKneelHeight: Integer;
    FFloatHeight: Integer;
    FFemaleFrequency: Integer;
    FValue: Integer;
    FTransferTime: Integer;
    FDeathSoundMale: TArray<Integer>;
    FDeathSoundFemale: TArray<Integer>;
    FNames: TObjectList<TXcomSoldierNamePool>;
    procedure AddSoldierNamePool(const AFiles: IXcomModFiles; const AFileName: string);
  public
    constructor Create(const AType: string);
    destructor Destroy; override;
    /// <summary>
    ///   Loads the soldier from a YAML node. "soldierNames" lists name files, folders (ending in /: all their
    ///   .nam files) and "delete" (forgets the pools so far); AFiles gives the files (nil if there are none)
    /// </summary>
    procedure Load(const ANode: IYamlNode; const AOffsets: TXcomModOffsets; const AFiles: IXcomModFiles);
    property SoldierType: string read FType;
    property Requirements: TArray<string> read FRequires;
    property MinStats: TXcomUnitStats read FMinStats;
    property MaxStats: TXcomUnitStats read FMaxStats;
    property StatCaps: TXcomUnitStats read FStatCaps;
    property ArmorName: string read FArmor;
    property BuyCost: Integer read FCostBuy;
    property SalaryCost: Integer read FCostSalary;
    property StandHeight: Integer read FStandHeight;
    property KneelHeight: Integer read FKneelHeight;
    property FloatHeight: Integer read FFloatHeight;
    property FemaleFrequency: Integer read FFemaleFrequency;
    property Value: Integer read FValue;
    property TransferTime: Integer read FTransferTime;
    property DeathSoundMale: TArray<Integer> read FDeathSoundMale;
    property DeathSoundFemale: TArray<Integer> read FDeathSoundFemale;
    property Names: TObjectList<TXcomSoldierNamePool> read FNames;
  end;

implementation

uses
  DelphiDoom.XcomMod.Types;

resourcestring
  SSoldierNoFiles = 'The soldier %s names files but the mod has no files to read them from';

{ TXcomRuleSoldier }

constructor TXcomRuleSoldier.Create(const AType: string);
begin
  inherited Create;
  FType := AType;
  FFemaleFrequency := 50;
  FValue := 20;
  FNames := TObjectList<TXcomSoldierNamePool>.Create(True);
end;

destructor TXcomRuleSoldier.Destroy;
begin
  FNames.Free;
  inherited Destroy;
end;

procedure TXcomRuleSoldier.AddSoldierNamePool(const AFiles: IXcomModFiles; const AFileName: string);
var
  LPool: TXcomSoldierNamePool;
begin
  if not Assigned(AFiles) then
    raise EXcomModException.CreateFmt(SSoldierNoFiles, [FType]);
  LPool := TXcomSoldierNamePool.Create;
  try
    LPool.Load(AFiles.LoadYaml(AFileName));
  except
    LPool.Free;
    raise;
  end;
  FNames.Add(LPool);
end;

procedure TXcomRuleSoldier.Load(const ANode: IYamlNode; const AOffsets: TXcomModOffsets;
  const AFiles: IXcomModFiles);
var
  LItem: IYamlNode;
  LFileName, LName: string;
  LContents: TArray<string>;
  LSorted: TList<string>;
begin
  FType := TXcomNodeReader.ReadString(ANode, 'type', FType);
  // just in case
  if FType = 'XCOM' then
    FType := 'STR_SOLDIER';
  FRequires := TXcomNodeReader.ReadStrings(ANode, 'requires', FRequires);
  FMinStats.Merge(TXcomUnitStatsReader.Read(ANode, 'minStats', FMinStats));
  FMaxStats.Merge(TXcomUnitStatsReader.Read(ANode, 'maxStats', FMaxStats));
  FStatCaps.Merge(TXcomUnitStatsReader.Read(ANode, 'statCaps', FStatCaps));
  FArmor := TXcomNodeReader.ReadString(ANode, 'armor', FArmor);
  FCostBuy := TXcomNodeReader.ReadInteger(ANode, 'costBuy', FCostBuy);
  FCostSalary := TXcomNodeReader.ReadInteger(ANode, 'costSalary', FCostSalary);
  FStandHeight := TXcomNodeReader.ReadInteger(ANode, 'standHeight', FStandHeight);
  FKneelHeight := TXcomNodeReader.ReadInteger(ANode, 'kneelHeight', FKneelHeight);
  FFloatHeight := TXcomNodeReader.ReadInteger(ANode, 'floatHeight', FFloatHeight);
  FFemaleFrequency := TXcomNodeReader.ReadInteger(ANode, 'femaleFrequency', FFemaleFrequency);
  FValue := TXcomNodeReader.ReadInteger(ANode, 'value', FValue);
  FTransferTime := TXcomNodeReader.ReadInteger(ANode, 'transferTime', FTransferTime);
  AOffsets.LoadSoundOffset(FType, FDeathSoundMale, TXcomNodeReader.Field(ANode, 'deathMale'), 'BATTLE.CAT');
  AOffsets.LoadSoundOffset(FType, FDeathSoundFemale, TXcomNodeReader.Field(ANode, 'deathFemale'), 'BATTLE.CAT');
  for LItem in TXcomNodeReader.Field(ANode, 'soldierNames').Items do
  begin
    LFileName := TXcomNodeReader.TextOf(LItem);
    if LFileName = 'delete' then
      FNames.Clear
    else if (LFileName <> '') and (LFileName[Length(LFileName)] = '/') then
    begin
      // all the *.nam files of the folder, in the order of the names (a std::set)
      if not Assigned(AFiles) then
        raise EXcomModException.CreateFmt(SSoldierNoFiles, [FType]);
      LContents := AFiles.FolderContents(LFileName);
      LSorted := TList<string>.Create;
      try
        for LName in LContents do
          if SameText(ExtractFileExt(LName), '.nam') and not LSorted.Contains(LName) then
            LSorted.Add(LName);
        LSorted.Sort(TComparer<string>.Construct(
          function(const ALeft, ARight: string): Integer begin Result := XcomCompareUtf8(ALeft, ARight); end));
        for LName in LSorted do
          AddSoldierNamePool(AFiles, LFileName + LName);
      finally
        LSorted.Free;
      end;
    end
    else
      AddSoldierNamePool(AFiles, LFileName);
  end;
end;

end.
