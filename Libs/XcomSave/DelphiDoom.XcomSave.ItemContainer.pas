{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom saved game library - a container of items (ItemContainer)  }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSave.ItemContainer;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.Types, DelphiDoom.XcomMod.NodeReader,
  DelphiDoom.XcomSave.NodeWriter;

type
  /// <summary>
  ///   Represents a list of items and their quantities (a base's stores, the items on a craft...), kept in the
  ///   order of the item types. getTotalSize needs the item rules (Mod) and is not ported
  /// </summary>
  TXcomItemContainer = class
  strict private
    FQuantities: TXcomStringMap<Integer>;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>
    ///   Loads a map of types and quantities; a node that is not a map keeps the contents, a quantity that is not
    ///   an integer raises EYamlBadConversion and keeps them too
    /// </summary>
    procedure Load(const ANode: IYamlNode);
    function Save: IYamlNode;
    /// <summary>addItem: an empty type does nothing</summary>
    procedure AddItem(const AType: string; AQuantity: Integer = 1);
    /// <summary>removeItem: takes the type out when the quantity is not less than what is there</summary>
    procedure RemoveItem(const AType: string; AQuantity: Integer = 1);
    /// <summary>getItem: 0 for an empty or unknown type</summary>
    function GetItem(const AType: string): Integer;
    /// <summary>getTotalQuantity</summary>
    function TotalQuantity: Integer;
    /// <summary>getContents: owned by the container</summary>
    property Contents: TXcomStringMap<Integer> read FQuantities;
  end;

implementation

{ TXcomItemContainer }

constructor TXcomItemContainer.Create;
begin
  inherited Create;
  FQuantities := TXcomStringMap<Integer>.Create;
end;

destructor TXcomItemContainer.Destroy;
begin
  FQuantities.Free;
  inherited Destroy;
end;

procedure TXcomItemContainer.Load(const ANode: IYamlNode);
var
  LLoaded: TXcomStringMap<Integer>;
  LPair: TYamlPair;
begin
  // node.as<map>(fallback) of the C++: a missing key (an invalid node) and a node that is no map keep the contents
  if not ANode.IsDefined or not ANode.IsMap then
    Exit;
  LLoaded := TXcomStringMap<Integer>.Create;
  try
    for LPair in ANode.Pairs do
      LLoaded.SetValue(TXcomNodeReader.TextOf(LPair.Key), LPair.Value.AsInteger);
  except
    LLoaded.Free;
    raise;
  end;
  FQuantities.Free;
  FQuantities := LLoaded;
end;

function TXcomItemContainer.Save: IYamlNode;
var
  LIndex: Integer;
begin
  Result := TXcomNodeWriter.NewEmptyMap;
  for LIndex := 0 to FQuantities.Count - 1 do
    TXcomNodeWriter.SetInteger(Result, FQuantities.Key(LIndex), FQuantities.Value(LIndex));
end;

procedure TXcomItemContainer.AddItem(const AType: string; AQuantity: Integer);
var
  LCurrent: Integer;
begin
  if AType = '' then
    Exit;
  if not FQuantities.TryGetValue(AType, LCurrent) then
    LCurrent := 0;
  FQuantities.SetValue(AType, LCurrent + AQuantity);
end;

procedure TXcomItemContainer.RemoveItem(const AType: string; AQuantity: Integer);
var
  LCurrent: Integer;
begin
  if (AType = '') or not FQuantities.TryGetValue(AType, LCurrent) then
    Exit;
  if AQuantity < LCurrent then
    FQuantities.SetValue(AType, LCurrent - AQuantity)
  else
    FQuantities.Remove(AType);
end;

function TXcomItemContainer.GetItem(const AType: string): Integer;
begin
  if (AType = '') or not FQuantities.TryGetValue(AType, Result) then
    Result := 0;
end;

function TXcomItemContainer.TotalQuantity: Integer;
var
  LIndex: Integer;
begin
  Result := 0;
  for LIndex := 0 to FQuantities.Count - 1 do
    Inc(Result, FQuantities.Value(LIndex));
end;

end.
