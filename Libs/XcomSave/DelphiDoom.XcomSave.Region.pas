{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom saved game library - a region in a game (Region)            }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSave.Region;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.Types, DelphiDoom.XcomMod.RuleRegion,
  DelphiDoom.XcomMod.NodeReader, DelphiDoom.XcomSave.NodeWriter;

type
  /// <summary>
  ///   A region of the world in a game: the activity of aliens and X-COM there over the last months (one entry
  ///   per month, at most 12; the last one is the current month; adding to an empty list raises EXcomModException)
  /// </summary>
  TXcomRegion = class
  strict private
    FRules: TXcomRuleRegion;
    FActivityXcom: TArray<Integer>;
    FActivityAlien: TArray<Integer>;
    class procedure AddToLast(var AValues: TArray<Integer>; AActivity: Integer); static;
    class procedure DropFirstIfLong(var AValues: TArray<Integer>); static;
  public
    /// <param name="ARules">Not owned</param>
    constructor Create(const ARules: TXcomRuleRegion);
    procedure Load(const ANode: IYamlNode);
    function Save: IYamlNode;
    property Rules: TXcomRuleRegion read FRules;
    property ActivityXcom: TArray<Integer> read FActivityXcom write FActivityXcom;
    property ActivityAlien: TArray<Integer> read FActivityAlien write FActivityAlien;
    procedure AddActivityXcom(AActivity: Integer);
    procedure AddActivityAlien(AActivity: Integer);
    /// <summary>newMonth: a new month with no activity; at most 12 are kept</summary>
    procedure NewMonth;
  end;

implementation

{ TXcomRegion }

constructor TXcomRegion.Create(const ARules: TXcomRuleRegion);
begin
  inherited Create;
  FRules := ARules;
  SetLength(FActivityAlien, 1);
  SetLength(FActivityXcom, 1);
end;

class procedure TXcomRegion.AddToLast(var AValues: TArray<Integer>; AActivity: Integer);
begin
  if Length(AValues) = 0 then
    raise EXcomModException.Create('Xcom: the region has no entry for the current month');
  Inc(AValues[High(AValues)], AActivity);
end;

class procedure TXcomRegion.DropFirstIfLong(var AValues: TArray<Integer>);
begin
  if Length(AValues) > 12 then
    Delete(AValues, 0, 1);
end;

procedure TXcomRegion.Load(const ANode: IYamlNode);

  function ReadIntegers(const AKey: string; const ADefault: TArray<Integer>): TArray<Integer>;
  var
    LField: IYamlNode;
    LItems: TArray<IYamlNode>;
    LIndex: Integer;
  begin
    LField := TXcomNodeReader.Field(ANode, AKey);
    if not LField.IsDefined or not LField.IsSequence then
      Exit(ADefault);
    LItems := LField.Items;
    SetLength(Result, Length(LItems));
    for LIndex := 0 to High(LItems) do
      Result[LIndex] := LItems[LIndex].AsInteger;
  end;

begin
  FActivityXcom := ReadIntegers('activityXcom', FActivityXcom);
  FActivityAlien := ReadIntegers('activityAlien', FActivityAlien);
end;

function TXcomRegion.Save: IYamlNode;
begin
  Result := TXcomNodeWriter.NewMap;
  TXcomNodeWriter.SetString(Result, 'type', FRules.RegionType);
  TXcomNodeWriter.SetIntegers(Result, 'activityXcom', FActivityXcom);
  TXcomNodeWriter.SetIntegers(Result, 'activityAlien', FActivityAlien);
end;

procedure TXcomRegion.AddActivityXcom(AActivity: Integer);
begin
  AddToLast(FActivityXcom, AActivity);
end;

procedure TXcomRegion.AddActivityAlien(AActivity: Integer);
begin
  AddToLast(FActivityAlien, AActivity);
end;

procedure TXcomRegion.NewMonth;
begin
  SetLength(FActivityAlien, Length(FActivityAlien) + 1);
  SetLength(FActivityXcom, Length(FActivityXcom) + 1);
  DropFirstIfLong(FActivityAlien);
  DropFirstIfLong(FActivityXcom);
end;

end.
