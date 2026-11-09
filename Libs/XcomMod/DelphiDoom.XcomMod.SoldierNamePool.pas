{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ruleset library - a list of soldier names (SoldierNamePool) }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMod.SoldierNamePool;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.NodeReader;

type
  /// <summary>The lists of names, look weights and female frequency of a .nam file (SoldierNamePool)</summary>
  TXcomSoldierNamePool = class
  strict private
    FMaleFirst: TArray<string>;
    FFemaleFirst: TArray<string>;
    FMaleLast: TArray<string>;
    FFemaleLast: TArray<string>;
    FLookWeights: TArray<Integer>;
    FTotalWeight: Integer;
    FFemaleFrequency: Integer;
  public
    constructor Create;
    /// <summary>Loads the pool from the document of a name file; empty female lists take the male ones</summary>
    procedure Load(const ADocument: IYamlNode);
    property MaleFirst: TArray<string> read FMaleFirst;
    property FemaleFirst: TArray<string> read FFemaleFirst;
    property MaleLast: TArray<string> read FMaleLast;
    property FemaleLast: TArray<string> read FFemaleLast;
    property LookWeights: TArray<Integer> read FLookWeights;
    property TotalWeight: Integer read FTotalWeight;
    property FemaleFrequency: Integer read FFemaleFrequency;
  end;

implementation

{ TXcomSoldierNamePool }

constructor TXcomSoldierNamePool.Create;
begin
  inherited Create;
  FFemaleFrequency := -1;
end;

procedure TXcomSoldierNamePool.Load(const ADocument: IYamlNode);
var
  LWeight: Integer;
  LItem: IYamlNode;
begin
  for LItem in TXcomNodeReader.Field(ADocument, 'maleFirst').Items do
  begin
    SetLength(FMaleFirst, Length(FMaleFirst) + 1);
    FMaleFirst[High(FMaleFirst)] := TXcomNodeReader.TextOf(LItem);
  end;
  for LItem in TXcomNodeReader.Field(ADocument, 'femaleFirst').Items do
  begin
    SetLength(FFemaleFirst, Length(FFemaleFirst) + 1);
    FFemaleFirst[High(FFemaleFirst)] := TXcomNodeReader.TextOf(LItem);
  end;
  for LItem in TXcomNodeReader.Field(ADocument, 'maleLast').Items do
  begin
    SetLength(FMaleLast, Length(FMaleLast) + 1);
    FMaleLast[High(FMaleLast)] := TXcomNodeReader.TextOf(LItem);
  end;
  for LItem in TXcomNodeReader.Field(ADocument, 'femaleLast').Items do
  begin
    SetLength(FFemaleLast, Length(FFemaleLast) + 1);
    FFemaleLast[High(FFemaleLast)] := TXcomNodeReader.TextOf(LItem);
  end;
  if Length(FFemaleFirst) = 0 then
    FFemaleFirst := Copy(FMaleFirst);
  if Length(FFemaleLast) = 0 then
    FFemaleLast := Copy(FMaleLast);
  FLookWeights := TXcomNodeReader.ReadIntegers(ADocument, 'lookWeights', FLookWeights);
  FTotalWeight := 0;
  for LWeight in FLookWeights do
    FTotalWeight := Integer(Cardinal(FTotalWeight) + Cardinal(LWeight));
  FFemaleFrequency := TXcomNodeReader.ReadInteger(ADocument, 'femaleFrequency', FFemaleFrequency);
end;

end.
