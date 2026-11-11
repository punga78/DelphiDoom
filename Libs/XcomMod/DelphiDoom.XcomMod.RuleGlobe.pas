{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ruleset library - the contents of the globe (RuleGlobe):    }
{  polygons, lines, textures and colors                                         }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMod.RuleGlobe;

interface

uses
  System.SysUtils, System.Generics.Collections, System.Generics.Defaults, DelphiDoom.Yaml.Types,
  DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.Types, DelphiDoom.XcomMod.NodeReader, DelphiDoom.XcomMod.Areas,
  DelphiDoom.XcomMod.ModFiles.Intf, DelphiDoom.XcomMod.Polygon, DelphiDoom.XcomMod.Polyline,
  DelphiDoom.XcomMod.Texture;

type
  /// <summary>
  ///   What the globe of the geoscape shows (RuleGlobe): the polygons of the world map (from the WORLD.DAT
  ///   file or from the YAML), the lines, the textures by id and the colors that Globe keeps as statics (here
  ///   they belong to the rules). The lists belong to the object
  /// </summary>
  TXcomRuleGlobe = class
  strict private
    FFiles: IXcomModFiles;
    FPolygons: TObjectList<TXcomPolygon>;
    FPolylines: TObjectList<TXcomPolyline>;
    FTextures: TObjectDictionary<Integer, TXcomTexture>;
    FCountryLabelColor: Byte;
    FCityLabelColor: Byte;
    FBaseLabelColor: Byte;
    FLineColor: Byte;
    FOceanColor: Byte;
    FOceanShading: Boolean;
    procedure LoadDat(const AFileName: string);
    procedure LoadTextures(const ANode: IYamlNode);
  public
    /// <param name="AFiles">The virtual files of the mods (the "data" file); nil if there are none</param>
    constructor Create(const AFiles: IXcomModFiles = nil);
    destructor Destroy; override;
    /// <summary>
    ///   RuleGlobe::load. The colors start at the values that Mod::Mod sets for the Globe statics (ocean
    ///   palette block 12, country 239, line 162, city 138, base 133, shading on); the ones read from the YAML
    ///   are cut to a byte as the Uint8 statics are
    /// </summary>
    procedure Load(const ANode: IYamlNode);
    /// <summary>getPolygons</summary>
    property Polygons: TObjectList<TXcomPolygon> read FPolygons;
    /// <summary>getPolylines</summary>
    property Polylines: TObjectList<TXcomPolyline> read FPolylines;
    property CountryLabelColor: Byte read FCountryLabelColor;
    property CityLabelColor: Byte read FCityLabelColor;
    property BaseLabelColor: Byte read FBaseLabelColor;
    property LineColor: Byte read FLineColor;
    property OceanColor: Byte read FOceanColor;
    property OceanShading: Boolean read FOceanShading;
    /// <summary>getTexture: nil if the id is not there. The texture belongs to the globe</summary>
    function GetTexture(AId: Integer): TXcomTexture;
    /// <summary>The ids of the textures, in order (the order of the std::map)</summary>
    function TextureIds: TArray<Integer>;
    /// <summary>getTerrains: the terrains of the textures that have the deployment ("" = those with none)</summary>
    function GetTerrains(const ADeployment: string): TArray<string>;
    /// <summary>
    ///   Xcom2Rad: a longitude or latitude of WORLD.DAT (eighths of a degree) in radians, rounded at every step
    ///   as a double
    /// </summary>
    class function XcomToRadians(AValue: Integer): Double; static;
  end;

implementation

const
  SFileNotFound = 'Xcom: globe data file not found';
  SOceanBlock = 12;
  RECORD_BYTES = 20;

{ TXcomRuleGlobe }

constructor TXcomRuleGlobe.Create(const AFiles: IXcomModFiles);
begin
  inherited Create;
  FFiles := AFiles;
  FPolygons := TObjectList<TXcomPolygon>.Create(True);
  FPolylines := TObjectList<TXcomPolyline>.Create(True);
  FTextures := TObjectDictionary<Integer, TXcomTexture>.Create([doOwnsValues]);
  FCountryLabelColor := 239;
  FCityLabelColor := 138;
  FBaseLabelColor := 133;
  FLineColor := 162;
  FOceanColor := Byte(SOceanBlock * 16);
  FOceanShading := True;
end;

destructor TXcomRuleGlobe.Destroy;
begin
  FTextures.Free;
  FPolylines.Free;
  FPolygons.Free;
  inherited Destroy;
end;

class function TXcomRuleGlobe.XcomToRadians(AValue: Integer): Double;
var
  LEighths, LProduct: Double;
begin
  LEighths := AValue * 0.125;
  LProduct := LEighths * XCOM_PI;
  Result := LProduct / 180.0;
end;

procedure TXcomRuleGlobe.LoadDat(const AFileName: string);
var
  LBytes: TBytes;
  LOffset, LPoints, LPoint, LValue: Integer;
  LValues: array[0..9] of SmallInt;
  LPolygon: TXcomPolygon;
begin
  if not Assigned(FFiles) then
    raise EXcomModException.Create(SFileNotFound);
  LBytes := FFiles.LoadBytes(AFileName);
  // read() of a partial last record sets eof, so the C++ ignores a tail shorter than a record
  LOffset := 0;
  while LOffset + RECORD_BYTES <= Length(LBytes) do
  begin
    for LValue := 0 to 9 do
      LValues[LValue] := SmallInt(LBytes[LOffset + LValue * 2] or (LBytes[LOffset + LValue * 2 + 1] shl 8));
    if LValues[6] <> -1 then
      LPoints := 4
    else
      LPoints := 3;
    LPolygon := TXcomPolygon.Create(LPoints);
    for LPoint := 0 to LPoints - 1 do
    begin
      LPolygon.SetLongitude(LPoint, XcomToRadians(LValues[LPoint * 2]));
      LPolygon.SetLatitude(LPoint, XcomToRadians(LValues[LPoint * 2 + 1]));
    end;
    LPolygon.Texture := LValues[8];
    FPolygons.Add(LPolygon);
    Inc(LOffset, RECORD_BYTES);
  end;
end;

procedure TXcomRuleGlobe.LoadTextures(const ANode: IYamlNode);
var
  LItem, LField: IYamlNode;
  LId: Integer;
  LTexture: TXcomTexture;
begin
  for LItem in TXcomNodeReader.Field(ANode, 'textures').Items do
  begin
    LField := TXcomNodeReader.Field(LItem, 'id');
    if LField.IsDefined then
    begin
      LId := LField.AsInteger;
      if not FTextures.TryGetValue(LId, LTexture) then
      begin
        LTexture := TXcomTexture.Create(LId);
        FTextures.Add(LId, LTexture);
      end;
      LTexture.Load(LItem);
    end
    else
    begin
      LField := TXcomNodeReader.Field(LItem, 'delete');
      if LField.IsDefined then
        // the C++ erases the pointer without deleting it (a leak); here the texture is freed
        FTextures.Remove(LField.AsInteger);
    end;
  end;
end;

procedure TXcomRuleGlobe.Load(const ANode: IYamlNode);
var
  LField, LItem: IYamlNode;
  LPolygon: TXcomPolygon;
  LPolyline: TXcomPolyline;
begin
  LField := TXcomNodeReader.Field(ANode, 'data');
  if LField.IsDefined then
  begin
    FPolygons.Clear;
    LoadDat(TXcomNodeReader.TextOf(LField));
  end;
  LField := TXcomNodeReader.Field(ANode, 'polygons');
  if LField.IsDefined then
  begin
    FPolygons.Clear;
    for LItem in LField.Items do
    begin
      LPolygon := TXcomPolygon.Create(3);
      FPolygons.Add(LPolygon);
      LPolygon.Load(LItem);
    end;
  end;
  LField := TXcomNodeReader.Field(ANode, 'polylines');
  if LField.IsDefined then
  begin
    FPolylines.Clear;
    for LItem in LField.Items do
    begin
      LPolyline := TXcomPolyline.Create(3);
      FPolylines.Add(LPolyline);
      LPolyline.Load(LItem);
    end;
  end;
  LoadTextures(ANode);
  FCountryLabelColor := Byte(TXcomNodeReader.ReadInteger(ANode, 'countryColor', FCountryLabelColor));
  FCityLabelColor := Byte(TXcomNodeReader.ReadInteger(ANode, 'cityColor', FCityLabelColor));
  FBaseLabelColor := Byte(TXcomNodeReader.ReadInteger(ANode, 'baseColor', FBaseLabelColor));
  FLineColor := Byte(TXcomNodeReader.ReadInteger(ANode, 'lineColor', FLineColor));
  if TXcomNodeReader.Field(ANode, 'oceanPalette').IsDefined then
    // Palette::blockOffset(Uint8 block) returns block * 16 as a Uint8; the default is the current block
    FOceanColor := Byte(Byte(TXcomNodeReader.ReadInteger(ANode, 'oceanPalette', FOceanColor)) * 16);
  FOceanShading := TXcomNodeReader.ReadBoolean(ANode, 'oceanShading', FOceanShading);
end;

function TXcomRuleGlobe.GetTexture(AId: Integer): TXcomTexture;
begin
  if not FTextures.TryGetValue(AId, Result) then
    Result := nil;
end;

function TXcomRuleGlobe.TextureIds: TArray<Integer>;
begin
  Result := FTextures.Keys.ToArray;
  TArray.Sort<Integer>(Result);
end;

function TXcomRuleGlobe.GetTerrains(const ADeployment: string): TArray<string>;
var
  LId: Integer;
  LTexture: TXcomTexture;
  LCriteria: TXcomTerrainCriteria;
  LNames: TList<string>;
begin
  LNames := TList<string>.Create;
  try
    for LId in TextureIds do
    begin
      LTexture := FTextures[LId];
      if ((ADeployment = '') and (LTexture.Deployments.Count = 0)) or LTexture.Deployments.ContainsKey(ADeployment) then
        for LCriteria in LTexture.Terrain do
          LNames.Add(LCriteria.Name);
    end;
    Result := LNames.ToArray;
  finally
    LNames.Free;
  end;
end;

end.
