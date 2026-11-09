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
  System.SysUtils, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.NodeReader, DelphiDoom.XcomMod.Types,
  DelphiDoom.XcomMod.Random;

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
    /// <summary>
    ///   genName: a name by gender (the pool frequency if it has one, otherwise the one of the soldier type);
    ///   AFemale tells the gender that came out. An empty first-name list is EXcomModException (the C++
    ///   reads past a vector of size 0)
    /// </summary>
    function GenName(out AFemale: Boolean; AFemaleFrequency: Integer; const ARandom: IXcomRandom): string;
    /// <summary>
    ///   genLook: a look by weight; the weights are made as long as the number of looks (new ones weigh 2) and
    ///   the total follows
    /// </summary>
    function GenLook(ALooks: Integer; const ARandom: IXcomRandom): Integer;
  end;

implementation

{ TXcomSoldierNamePool }

function TXcomSoldierNamePool.GenName(out AFemale: Boolean; AFemaleFrequency: Integer;
  const ARandom: IXcomRandom): string;
var
  LFirst, LLast: TArray<string>;
begin
  if FFemaleFrequency > -1 then
    AFemale := ARandom.Generate(0, 99) < FFemaleFrequency
  else
    AFemale := ARandom.Generate(0, 99) < AFemaleFrequency;
  if AFemale then
  begin
    LFirst := FFemaleFirst;
    LLast := FFemaleLast;
  end
  else
  begin
    LFirst := FMaleFirst;
    LLast := FMaleLast;
  end;
  if Length(LFirst) = 0 then
    raise EXcomModException.Create('Xcom: the name file has no first names');
  Result := LFirst[ARandom.Generate(0, Length(LFirst) - 1)];
  if Length(LLast) > 0 then
    Result := Result + ' ' + LLast[ARandom.Generate(0, Length(LLast) - 1)];
end;

function TXcomSoldierNamePool.GenLook(ALooks: Integer; const ARandom: IXcomRandom): Integer;
const
  MINIMUM_CHANCE = 2;
var
  LRandom, LIndex: Integer;
begin
  while Length(FLookWeights) < ALooks do
  begin
    SetLength(FLookWeights, Length(FLookWeights) + 1);
    FLookWeights[High(FLookWeights)] := MINIMUM_CHANCE;
    Inc(FTotalWeight, MINIMUM_CHANCE);
  end;
  while Length(FLookWeights) > ALooks do
  begin
    Dec(FTotalWeight, FLookWeights[High(FLookWeights)]);
    SetLength(FLookWeights, Length(FLookWeights) - 1);
  end;
  LRandom := ARandom.Generate(0, FTotalWeight);
  for LIndex := 0 to High(FLookWeights) do
  begin
    if LRandom <= FLookWeights[LIndex] then
      Exit(LIndex);
    Dec(LRandom, FLookWeights[LIndex]);
  end;
  Result := ARandom.Generate(0, ALooks - 1);
end;

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
