{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ruleset library - a MCD file of tile parts that a terrain   }
{  refers to by name (MapDataSet)                                               }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMod.MapDataSet;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.XcomMod.Types, DelphiDoom.XcomMod.MapData;

type
  /// <summary>
  ///   A MCD file of tile parts that a terrain refers to by name. While the ruleset loads it is only a name;
  ///   TXcomMapDataLoader (MapDataSet::loadData) fills the parts when a battle needs them. The sprites
  ///   (SurfaceSet of the TERRAIN PCK and TAB files) are not here: Libs\XcomFormats reads them
  /// </summary>
  TXcomMapDataSet = class
  strict private
    FName: string;
    FLoaded: Boolean;
    FObjects: TObjectList<TXcomMapData>;
    FUsers: TList<TObject>;
  public
    constructor Create(const AName: string);
    destructor Destroy; override;
    property Name: string read FName;
    /// <summary>Whether loadData was called (it is set before the file is read, as the C++ does)</summary>
    property Loaded: Boolean read FLoaded;
    /// <summary>getSize: the number of parts</summary>
    function Size: Integer;
    /// <summary>
    ///   getObject: a part by index. The part belongs to the set. An index out of the range is
    ///   EXcomModException ("MCD name has no object n")
    /// </summary>
    function GetObject(AIndex: Cardinal): TXcomMapData;
    /// <summary>Adds a part that the set owns (what loadData does for every record of the file)</summary>
    function AddObject: TXcomMapData;
    /// <summary>The first lines of loadData: false if the data were already loaded (nothing is done twice)</summary>
    function BeginLoad: Boolean;
    /// <summary>unloadData: frees the parts; the set can be loaded again</summary>
    procedure Unload;
    /// <summary>
    ///   A battle says that its tiles point to the parts of the set (the sets belong to the rules and are shared:
    ///   a battle loaded while another is still alive uses the same parts). Not owned, counted once
    /// </summary>
    procedure Retain(AUser: TObject);
    /// <summary>
    ///   The battle that ends lets the set go: the parts are freed (Unload) only when no other battle uses them.
    ///   The C++ deletes the old battle before it loads the map of the new one; here the old one can die later
    /// </summary>
    procedure Release(AUser: TObject);
    /// <summary>
    ///   getBlankFloorTile / getScorchedEarthTile: the first and second parts of the set called BLANKS, or nil
    ///   (the C++ keeps them in statics; here they belong to the set)
    /// </summary>
    function BlankFloorTile: TXcomMapData;
    function ScorchedEarthTile: TXcomMapData;
  end;

implementation

{ TXcomMapDataSet }

constructor TXcomMapDataSet.Create(const AName: string);
begin
  inherited Create;
  FName := AName;
  FObjects := TObjectList<TXcomMapData>.Create(True);
  FUsers := TList<TObject>.Create;
end;

destructor TXcomMapDataSet.Destroy;
begin
  FUsers.Free;
  FObjects.Free;
  inherited Destroy;
end;

function TXcomMapDataSet.Size: Integer;
begin
  Result := FObjects.Count;
end;

function TXcomMapDataSet.GetObject(AIndex: Cardinal): TXcomMapData;
begin
  if AIndex >= Cardinal(FObjects.Count) then
    raise EXcomModException.CreateFmt('MCD %s has no object %u', [FName, AIndex]);
  Result := FObjects[AIndex];
end;

function TXcomMapDataSet.AddObject: TXcomMapData;
begin
  Result := TXcomMapData.Create;
  Result.Dataset := Self;
  FObjects.Add(Result);
end;

function TXcomMapDataSet.BeginLoad: Boolean;
begin
  Result := not FLoaded;
  FLoaded := True;
end;

procedure TXcomMapDataSet.Unload;
begin
  if FLoaded then
  begin
    FObjects.Clear;
    FLoaded := False;
  end;
end;

procedure TXcomMapDataSet.Retain(AUser: TObject);
begin
  if FUsers.IndexOf(AUser) < 0 then
    FUsers.Add(AUser);
end;

procedure TXcomMapDataSet.Release(AUser: TObject);
begin
  FUsers.Remove(AUser);
  if FUsers.Count = 0 then
    Unload;
end;

function TXcomMapDataSet.BlankFloorTile: TXcomMapData;
begin
  Result := nil;
  if (FName = 'BLANKS') and (FObjects.Count > 0) then
    Result := FObjects[0];
end;

function TXcomMapDataSet.ScorchedEarthTile: TXcomMapData;
begin
  Result := nil;
  if (FName = 'BLANKS') and (FObjects.Count > 1) then
    Result := FObjects[1];
end;

end.
