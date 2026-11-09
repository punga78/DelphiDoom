{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ruleset library - changes to the tile parts of a MCD file   }
{  (MCDPatch)                                                                   }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMod.McdPatch;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.NodeReader;

type
  /// <summary>A change of one tile part: the index in the MCD file and the new number (a flag is 0 or 1)</summary>
  TXcomMcdChange = record
    McdIndex: Cardinal;
    Value: Integer;
  end;

  /// <summary>The changes that a mod makes to the tile parts of a MCD file, by property (MCDPatch)</summary>
  TXcomMcdPatch = class
  public
    const
      /// <summary>The properties that take a number, in the order of the C++ members</summary>
      NUMBER_FIELDS: array[0..12] of string = ('bigWall', 'TUWalk', 'TUFly', 'TUSlide', 'deathTile', 'terrainHeight',
        'specialType', 'explosive', 'armor', 'flammability', 'fuel', 'footstepSound', 'HEBlock');
      /// <summary>The properties that take a flag</summary>
      FLAG_FIELDS: array[0..2] of string = ('noFloor', 'stopLOS', 'objectType');
  strict private
    FNumbers: array[0..12] of TArray<TXcomMcdChange>;
    FNoFloors: TArray<TXcomMcdChange>;
    FStopLos: TArray<TXcomMcdChange>;
    FObjectTypes: TArray<TXcomMcdChange>;
    FLofts: TArray<Cardinal>;
    FLoftValues: TArray<TArray<Integer>>;
    class procedure Add(var AList: TArray<TXcomMcdChange>; AIndex: Cardinal; AValue: Integer); static;
  public
    /// <summary>Loads "data": a list of tile parts with their MCDIndex and the properties to change</summary>
    procedure Load(const ANode: IYamlNode);
    /// <summary>The changes of a number property (one of NUMBER_FIELDS)</summary>
    function Numbers(const AField: string): TArray<TXcomMcdChange>;
    property NoFloors: TArray<TXcomMcdChange> read FNoFloors;
    property StopLos: TArray<TXcomMcdChange> read FStopLos;
    property ObjectTypes: TArray<TXcomMcdChange> read FObjectTypes;
    /// <summary>The MCD indexes of the LOFTS changes, and their lists of numbers in LoftValues</summary>
    property Lofts: TArray<Cardinal> read FLofts;
    property LoftValues: TArray<TArray<Integer>> read FLoftValues;
  end;

implementation

{ TXcomMcdPatch }

class procedure TXcomMcdPatch.Add(var AList: TArray<TXcomMcdChange>; AIndex: Cardinal; AValue: Integer);
begin
  SetLength(AList, Length(AList) + 1);
  AList[High(AList)].McdIndex := AIndex;
  AList[High(AList)].Value := AValue;
end;

procedure TXcomMcdPatch.Load(const ANode: IYamlNode);
var
  LItem, LField: IYamlNode;
  LIndex: Cardinal;
  LField_: Integer;
begin
  for LItem in TXcomNodeReader.Field(ANode, 'data').Items do
  begin
    LIndex := TXcomNodeReader.Field(LItem, 'MCDIndex').AsCardinal;
    for LField_ := 0 to High(NUMBER_FIELDS) do
    begin
      LField := TXcomNodeReader.Field(LItem, NUMBER_FIELDS[LField_]);
      if LField.IsDefined then
        Add(FNumbers[LField_], LIndex, LField.AsInteger);
    end;
    LField := TXcomNodeReader.Field(LItem, 'noFloor');
    if LField.IsDefined then
      Add(FNoFloors, LIndex, Ord(LField.AsBoolean));
    LField := TXcomNodeReader.Field(LItem, 'LOFTS');
    if LField.IsDefined then
    begin
      SetLength(FLofts, Length(FLofts) + 1);
      FLofts[High(FLofts)] := LIndex;
      SetLength(FLoftValues, Length(FLoftValues) + 1);
      FLoftValues[High(FLoftValues)] := TXcomNodeReader.IntegersOf(LField);
    end;
    LField := TXcomNodeReader.Field(LItem, 'stopLOS');
    if LField.IsDefined then
      Add(FStopLos, LIndex, Ord(LField.AsBoolean));
    LField := TXcomNodeReader.Field(LItem, 'objectType');
    if LField.IsDefined then
      Add(FObjectTypes, LIndex, LField.AsInteger);
  end;
end;

function TXcomMcdPatch.Numbers(const AField: string): TArray<TXcomMcdChange>;
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(NUMBER_FIELDS) do
    if NUMBER_FIELDS[LIndex] = AField then
      Exit(FNumbers[LIndex]);
  Result := nil;
end;

end.
