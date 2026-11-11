{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ruleset library - a block of a battlescape map (MapBlock)   }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMod.MapBlock;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Yaml.Types, DelphiDoom.Yaml.Intf,
  DelphiDoom.XcomMod.Types, DelphiDoom.XcomMod.NodeReader;

type
  /// <summary>Position: a place in a battlescape map (tiles)</summary>
  TXcomPosition = record
    X: Integer;
    Y: Integer;
    Z: Integer;
    /// <summary>Position(x, y, z)</summary>
    class function Make(AX, AY, AZ: Integer): TXcomPosition; static; inline;
    /// <summary>operator+ and operator- of Position</summary>
    class operator Add(const ALeft, ARight: TXcomPosition): TXcomPosition;
    class operator Subtract(const ALeft, ARight: TXcomPosition): TXcomPosition;
    /// <summary>operator/(int): each coordinate divided like a C++ int (towards zero)</summary>
    class operator IntDivide(const ALeft: TXcomPosition; ADivisor: Integer): TXcomPosition;
    /// <summary>operator*(Position): each coordinate multiplied by the one of the other</summary>
    class operator Multiply(const ALeft, ARight: TXcomPosition): TXcomPosition;
    /// <summary>operator/(Position): each coordinate divided by the one of the other like a C++ int</summary>
    class operator IntDivide(const ALeft, ARight: TXcomPosition): TXcomPosition;
    class operator Equal(const ALeft, ARight: TXcomPosition): Boolean;
    class operator NotEqual(const ALeft, ARight: TXcomPosition): Boolean;
  end;

  /// <summary>
  ///   Represents a rectangular block of a map used to build a battlescape: its size, the groups it belongs to,
  ///   the floors that start revealed and where items are placed (MapBlock)
  /// </summary>
  TXcomMapBlock = class
  strict private
    FName: string;
    FSizeX: Integer;
    FSizeY: Integer;
    FSizeZ: Integer;
    FGroups: TArray<Integer>;
    FRevealedFloors: TArray<Integer>;
    FItems: TXcomStringMap<TArray<TXcomPosition>>;
    class function ReadGroup(const ANode: IYamlNode; const AKey: string; const ACurrent: TArray<Integer>)
      : TArray<Integer>; static;
    procedure ReadItems(const ANode: IYamlNode);
    class function ReadPositions(const ANode: IYamlNode): TArray<TXcomPosition>; static;
  public
    constructor Create(const AName: string);
    destructor Destroy; override;
    /// <summary>Loads the block; a width or length that is not a multiple of ten is EXcomModException</summary>
    procedure Load(const ANode: IYamlNode);
    property Name: string read FName;
    property SizeX: Integer read FSizeX;
    property SizeY: Integer read FSizeY;
    property SizeZ: Integer read FSizeZ write FSizeZ;
    property Groups: TArray<Integer> read FGroups;
    property RevealedFloors: TArray<Integer> read FRevealedFloors;
    property Items: TXcomStringMap<TArray<TXcomPosition>> read FItems;
    function IsInGroup(AGroup: Integer): Boolean;
    function IsFloorRevealed(AFloor: Integer): Boolean;
  end;

implementation

{ TXcomPosition }

class function TXcomPosition.Make(AX, AY, AZ: Integer): TXcomPosition;
begin
  Result.X := AX;
  Result.Y := AY;
  Result.Z := AZ;
end;

class operator TXcomPosition.Add(const ALeft, ARight: TXcomPosition): TXcomPosition;
begin
  Result := Make(ALeft.X + ARight.X, ALeft.Y + ARight.Y, ALeft.Z + ARight.Z);
end;

class operator TXcomPosition.Subtract(const ALeft, ARight: TXcomPosition): TXcomPosition;
begin
  Result := Make(ALeft.X - ARight.X, ALeft.Y - ARight.Y, ALeft.Z - ARight.Z);
end;

class operator TXcomPosition.IntDivide(const ALeft: TXcomPosition; ADivisor: Integer): TXcomPosition;
begin
  Result := Make(ALeft.X div ADivisor, ALeft.Y div ADivisor, ALeft.Z div ADivisor);
end;

class operator TXcomPosition.Multiply(const ALeft, ARight: TXcomPosition): TXcomPosition;
begin
  Result := Make(ALeft.X * ARight.X, ALeft.Y * ARight.Y, ALeft.Z * ARight.Z);
end;

class operator TXcomPosition.IntDivide(const ALeft, ARight: TXcomPosition): TXcomPosition;
begin
  Result := Make(ALeft.X div ARight.X, ALeft.Y div ARight.Y, ALeft.Z div ARight.Z);
end;

class operator TXcomPosition.Equal(const ALeft, ARight: TXcomPosition): Boolean;
begin
  Result := (ALeft.X = ARight.X) and (ALeft.Y = ARight.Y) and (ALeft.Z = ARight.Z);
end;

class operator TXcomPosition.NotEqual(const ALeft, ARight: TXcomPosition): Boolean;
begin
  Result := not (ALeft = ARight);
end;

{ TXcomMapBlock }

constructor TXcomMapBlock.Create(const AName: string);
begin
  inherited Create;
  FName := AName;
  FSizeX := 10;
  FSizeY := 10;
  FSizeZ := 4;
  SetLength(FGroups, 1);
  FItems := TXcomStringMap<TArray<TXcomPosition>>.Create;
end;

destructor TXcomMapBlock.Destroy;
begin
  FItems.Free;
  inherited Destroy;
end;

class function TXcomMapBlock.ReadGroup(const ANode: IYamlNode; const AKey: string;
  const ACurrent: TArray<Integer>): TArray<Integer>;
var
  LField: IYamlNode;
begin
  LField := TXcomNodeReader.Field(ANode, AKey);
  if not LField.IsDefined then
    Exit(ACurrent);
  // the C++ clears the list first: a sequence that does not convert (an exception) leaves nothing to keep
  if LField.IsSequence then
    Result := TXcomNodeReader.IntegersOf(LField)
  else
  begin
    SetLength(Result, 1);
    Result[0] := LField.AsInteger(0);
  end;
end;

class function TXcomMapBlock.ReadPositions(const ANode: IYamlNode): TArray<TXcomPosition>;
var
  LItems, LCells: TArray<IYamlNode>;
  LIndex: Integer;
begin
  if not ANode.IsSequence then
    raise TXcomNodeReader.BadConversion(ANode);
  LItems := ANode.Items;
  SetLength(Result, Length(LItems));
  for LIndex := 0 to High(LItems) do
  begin
    // convert<Position>::decode: a sequence of three numbers
    if not LItems[LIndex].IsSequence or (LItems[LIndex].Size <> 3) then
      raise TXcomNodeReader.BadConversion(LItems[LIndex]);
    LCells := LItems[LIndex].Items;
    Result[LIndex].X := LCells[0].AsInteger;
    Result[LIndex].Y := LCells[1].AsInteger;
    Result[LIndex].Z := LCells[2].AsInteger;
  end;
end;

procedure TXcomMapBlock.ReadItems(const ANode: IYamlNode);
var
  LField: IYamlNode;
  LPair: TYamlPair;
begin
  LField := TXcomNodeReader.Field(ANode, 'items');
  if not LField.IsDefined or not LField.IsMap then
    Exit;
  FItems.Clear;
  for LPair in LField.Pairs do
    FItems.SetValue(TXcomNodeReader.TextOf(LPair.Key), ReadPositions(LPair.Value));
end;

procedure TXcomMapBlock.Load(const ANode: IYamlNode);
begin
  FName := TXcomNodeReader.ReadString(ANode, 'name', FName);
  FSizeX := TXcomNodeReader.ReadInteger(ANode, 'width', FSizeX);
  FSizeY := TXcomNodeReader.ReadInteger(ANode, 'length', FSizeY);
  FSizeZ := TXcomNodeReader.ReadInteger(ANode, 'height', FSizeZ);
  if (FSizeX mod 10 <> 0) or (FSizeY mod 10 <> 0) then
    raise EXcomModException.Create('Error: MapBlock ' + FName + ': Size must be divisible by ten');
  FGroups := ReadGroup(ANode, 'groups', FGroups);
  FRevealedFloors := ReadGroup(ANode, 'revealedFloors', FRevealedFloors);
  ReadItems(ANode);
end;

function TXcomMapBlock.IsInGroup(AGroup: Integer): Boolean;
var
  LValue: Integer;
begin
  for LValue in FGroups do
    if LValue = AGroup then
      Exit(True);
  Result := False;
end;

function TXcomMapBlock.IsFloorRevealed(AFloor: Integer): Boolean;
var
  LValue: Integer;
begin
  for LValue in FRevealedFloors do
    if LValue = AFloor then
      Exit(True);
  Result := False;
end;

end.
