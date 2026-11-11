{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom geoscape library - Globe of OpenXcom (the 3D-looking earth  }
{  of the geoscape: land, shadow of the night, radars, markers and labels)      }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomGeoscape.Globe;

interface

uses
  System.SysUtils, System.Math, System.Generics.Collections, DelphiDoom.Xcom.Types, DelphiDoom.XcomSurface.Surface,
  DelphiDoom.XcomSurface.SurfaceSet, DelphiDoom.XcomMod.Polygon, DelphiDoom.XcomMod.RuleGlobe,
  DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomSave.Target, DelphiDoom.XcomSave.City,
  DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.Timer,
  DelphiDoom.XcomEngine.InteractiveSurface, DelphiDoom.XcomEngine.State, DelphiDoom.XcomUi.Text;

type
  /// <summary>A vector of the unit sphere (Cord of Globe.cpp)</summary>
  TXcomCord = record
    X: Double;
    Y: Double;
    Z: Double;
  end;

  /// <summary>
  ///   The generator of rand() of the C runtime of Windows (msvcrt: a linear congruential generator seeded with 1),
  ///   that Globe uses for the noise of the shadow. OpenXcom never calls srand, so every run draws the same noise
  /// </summary>
  TXcomCRandom = record
  strict private
    FSeed: Cardinal;
  public
    constructor Create(ASeed: Cardinal);
    function Next: Integer;
  end;

  /// <summary>
  ///   The globe: draws the sea, the land (polygons with the textures of the zoom), the radars and the flight
  ///   lines, the shadow of the night (with noise), the markers of the targets and, from the zoom 1, the borders,
  ///   the names of countries and cities. It reads the saved game (time, bases, UFOs...) and does not change it
  ///   but for the center and the zoom
  /// </summary>
  TXcomGlobe = class(TXcomInteractiveSurface)
  public
    const
      ROTATE_LONGITUDE = 0.10;
      ROTATE_LATITUDE = 0.06;
      NEAR_RADIUS = 25;
      DOGFIGHT_ZOOM = 3;
      CITY_MARKER = 8;
      NOISE_SIZE = 60;
  strict private
    FHost: TXcomStateHost;
    FSave: TXcomSavedGame;
    FRuleset: TXcomRuleset;
    FRules: TXcomRuleGlobe;
    FTexture: TXcomSurfaceSet;
    FMarkerSet: TXcomSurfaceSet;
    FCountries: TXcomSurface;
    FMarkers: TXcomSurface;
    FRadars: TXcomSurface;
    FBlinkTimer: TXcomTimer;
    FRotTimer: TXcomTimer;
    FCities: TObjectList<TXcomCity>;
    FCacheLand: TObjectList<TXcomPolygon>;
    FEarthData: array of TArray<TXcomCord>;
    FNoise: TArray<SmallInt>;
    FZoomRadius: array of Double;
    FColors: TXcomColors;
    FCenX: Integer;
    FCenY: Integer;
    FRotLon: Double;
    FRotLat: Double;
    FCenLon: Double;
    FCenLat: Double;
    FHoverLon: Double;
    FHoverLat: Double;
    FCraftLon: Double;
    FCraftLat: Double;
    FCraftRange: Double;
    FRadius: Double;
    FRadiusStep: Double;
    FZoom: Integer;
    FZoomOld: Integer;
    FZoomTexture: Integer;
    FHover: Boolean;
    FCraft: Boolean;
    FBlink: Integer;
    FDetail: Boolean;
    FRadarLines: Boolean;
    FFlightPaths: Boolean;
    FAllRadarsOnBaseBuild: Boolean;
    FSeasons: Boolean;
    FScrollSpeed: Integer;
    class var FShadeGradient: array[0..239] of SmallInt;
    class constructor CreateClass;
    procedure SetupRadii(AWidth, AHeight: Integer);
    function EarthData(AZoom: Integer): TArray<TXcomCord>;
    procedure BuildCities;
    procedure Blink;
    procedure Rotate;
    procedure CachePolygons;
    procedure DrawOcean;
    procedure DrawLand;
    procedure DrawRadars;
    procedure DrawFlights;
    procedure DrawPath(ASurface: TXcomSurface; ALon1, ALat1, ALon2, ALat2: Double);
    procedure DrawShadow;
    procedure DrawMarkers;
    procedure DrawDetail;
    procedure DrawTarget(ATarget: TXcomTarget; ASurface: TXcomSurface);
    procedure DrawGlobeCircle(ALat, ALon, ARadius: Double; ASegments: Integer; AFraction: Integer = 1);
    procedure XuLine(ASurface, ASource: TXcomSurface; AX1, AY1, AX2, AY2: Double; AShade: Integer);
    function ClipLine(var AX1, AY1, AX2, AY2: Double): Boolean;
    function SunDirection(ALon, ALat: Double): TXcomCord;
    class function CircleNorm(AOx, AOy, ARadius, AX, AY: Double): TXcomCord; static;
    class function ShadowValue(const AEarth, ASun: TXcomCord; ANoise: Integer): Byte; static;
    class function Nautical(AValue: Double): Double; static;
    procedure SetCenterValue(ALon, ALat: Double);
  protected
    procedure MouseClick(AAction: TXcomAction); override;
  public
    /// <summary>
    ///   Globe::Globe. The texture and the marker sets are copied (the markers blink); the rules, the saved game and
    ///   the host are not owned
    /// </summary>
    constructor Create(AHost: TXcomStateHost; ASave: TXcomSavedGame; ARuleset: TXcomRuleset;
      ATexture, AMarkerSet: TXcomSurfaceSet; ACenX, ACenY, AWidth, AHeight, AX, AY: Integer);
    destructor Destroy; override;
    procedure SetPalette(AColors: PXcomColor; AFirst: Integer = 0; ACount: Integer = 256); override;
    procedure Think; override;
    procedure Draw; override;
    procedure Blit(ATarget: TXcomSurface); override;
    /// <summary>polarToCart: the point of the globe (a position on the surface)</summary>
    procedure PolarToCart(ALon, ALat: Double; out AX, AY: SmallInt); overload;
    procedure PolarToCart(ALon, ALat: Double; out AX, AY: Double); overload;
    /// <summary>cartToPolar: false when the point is not on the globe (the C++ gets a NaN)</summary>
    function CartToPolar(AX, AY: SmallInt; out ALon, ALat: Double): Boolean;
    function PointBack(ALon, ALat: Double): Boolean;
    /// <summary>AreSame of fmath.h: equal up to the epsilon of a double</summary>
    class function AreSame(ALeft, ARight: Double): Boolean; static;
    /// <summary>getPolygonFromLonLat: the polygon of the land under the point, nil on the sea</summary>
    function GetPolygonFromLonLat(ALon, ALat: Double): TXcomPolygon;
    function InsideLand(ALon, ALat: Double): Boolean;
    /// <summary>
    ///   getPolygonTextureAndShade: the texture id of the land under the point (-1 on the sea) and the shade of the
    ///   place at this time, converted from the 32 levels of the geoscape to the 16 of the battlescape
    /// </summary>
    procedure GetPolygonTextureAndShade(ALon, ALat: Double; out ATexture, AShade: Integer);
    /// <summary>Mod::getGlobe()->getTexture(id) &lt;&gt; 0: the globe has the texture</summary>
    function HasTexture(AId: Integer): Boolean;
    /// <summary>
    ///   Globe::getTargets: the targets whose marker is within 5 pixels (squared distance 25) of the point; with
    ///   ACraftOnly only the things a craft can be sent to (no bases and no crafts). The list is the caller's
    ///   (the targets are not owned)
    /// </summary>
    function GetTargets(AX, AY: Integer; ACraftOnly: Boolean): TList<TXcomTarget>;
    procedure RotateLeft;
    procedure RotateRight;
    procedure RotateUp;
    procedure RotateDown;
    procedure RotateStop;
    procedure RotateStopLon;
    procedure RotateStopLat;
    procedure SetZoom(AZoom: Integer);
    procedure ZoomIn;
    procedure ZoomOut;
    procedure ZoomMin;
    procedure ZoomMax;
    /// <summary>Globe::center: also moves the center that the saved game keeps</summary>
    procedure Center(ALon, ALat: Double);
    procedure ToggleDetail;
    procedure ToggleRadarLines;
    procedure SetNewBaseHover(AHover: Boolean);
    procedure SetNewBaseHoverPos(ALon, ALat: Double);
    procedure SetCraftRange(ALon, ALat, ARange: Double);
    procedure DrawRadarsNow;
    /// <summary>
    ///   The table of noise of the shadow (60 x 60 values 0..3). The C++ fills it with rand() when the globe is built, and
    ///   what rand() gives depends on every call the program made before, so a game that must look like another one
    ///   (or a test) gives the table
    /// </summary>
    procedure SetNoise(const ANoise: TArray<SmallInt>);
    property Zoom: Integer read FZoom;
    property CenterLongitude: Double read FCenLon;
    property CenterLatitude: Double read FCenLat;
    property Radius: Double read FRadius;
    property Detail: Boolean read FDetail write FDetail;
    property RadarLines: Boolean read FRadarLines write FRadarLines;
    /// <summary>Options::globeFlightPaths: the paths of the crafts that are out, to their destination</summary>
    property FlightPaths: Boolean read FFlightPaths write FFlightPaths;
    property Seasons: Boolean read FSeasons write FSeasons;
    property AllRadarsOnBaseBuild: Boolean read FAllRadarsOnBaseBuild write FAllRadarsOnBaseBuild;
    property ScrollSpeed: Integer read FScrollSpeed write FScrollSpeed;
  end;

implementation

uses
  System.Generics.Defaults, DelphiDoom.XcomSave.Base, DelphiDoom.XcomSave.Craft, DelphiDoom.XcomSave.BaseFacility,
  DelphiDoom.XcomSave.Rules.Intf, DelphiDoom.XcomSave.FloatMode, DelphiDoom.XcomMod.Areas,
  DelphiDoom.XcomMod.RuleRegion, DelphiDoom.XcomMod.RuleBaseFacility, DelphiDoom.XcomMod.RuleCountry,
  DelphiDoom.XcomMod.Polyline, DelphiDoom.XcomSave.Region, DelphiDoom.XcomSave.Country, DelphiDoom.XcomSave.Ufo,
  DelphiDoom.XcomSave.Waypoint, DelphiDoom.XcomSave.MissionSite, DelphiDoom.XcomSave.AlienBase,
  DelphiDoom.XcomSurface.Gfx, DelphiDoom.XcomEngine.Language, DelphiDoom.XcomUi.Types;

{ TXcomCRandom }

constructor TXcomCRandom.Create(ASeed: Cardinal);
begin
  FSeed := ASeed;
end;

function TXcomCRandom.Next: Integer;
begin
  // 32 bit arithmetic that wraps, as the unsigned of the C runtime
  FSeed := Cardinal((UInt64(FSeed) * 214013 + 2531011) and $FFFFFFFF);
  Result := (FSeed shr 16) and $7FFF;
end;

{ TXcomGlobe }

class constructor TXcomGlobe.CreateClass;
var
  LIndex, LValue: Integer;
begin
  // the table of GlobeStaticData
  for LIndex := 0 to 239 do
  begin
    LValue := LIndex - 120;
    if LValue < -66 then
      LValue := -16
    else if LValue < -48 then
      LValue := -15
    else if LValue < -33 then
      LValue := -14
    else if LValue < -22 then
      LValue := -13
    else if LValue < -15 then
      LValue := -12
    else if LValue < -11 then
      LValue := -11
    else if LValue < -9 then
      LValue := -10;
    if LValue > 120 then
      LValue := 19
    else if LValue > 98 then
      LValue := 18
    else if LValue > 86 then
      LValue := 17
    else if LValue > 74 then
      LValue := 16
    else if LValue > 54 then
      LValue := 15
    else if LValue > 38 then
      LValue := 14
    else if LValue > 26 then
      LValue := 13
    else if LValue > 18 then
      LValue := 12
    else if LValue > 13 then
      LValue := 11
    else if LValue > 10 then
      LValue := 10
    else if LValue > 8 then
      LValue := 9;
    FShadeGradient[LIndex] := LValue + 16;
  end;
end;

class function TXcomGlobe.Nautical(AValue: Double): Double;
var
  LStep: Double;
begin
  LStep := AValue * (1 / 60.0);
  Result := LStep * (PI / 180.0);
end;

class function TXcomGlobe.AreSame(ALeft, ARight: Double): Boolean;
const
  DBL_EPSILON = 2.2204460492503131E-16;
begin
  Result := Abs(ALeft - ARight) <= DBL_EPSILON * Max(1.0, Max(Abs(ALeft), Abs(ARight)));
end;

class function TXcomGlobe.CircleNorm(AOx, AOy, ARadius, AX, AY: Double): TXcomCord;
var
  LLimit, LNorm, LTemp: Double;
begin
  LLimit := ARadius * ARadius;
  LNorm := 1.0 / ARadius;
  Result.X := AX - AOx;
  Result.Y := AY - AOy;
  LTemp := Result.X * Result.X + Result.Y * Result.Y;
  if LLimit > LTemp then
  begin
    Result.X := Result.X * LNorm;
    Result.Y := Result.Y * LNorm;
    Result.Z := Sqrt(LLimit - LTemp) * LNorm;
  end
  else
  begin
    Result.X := 0;
    Result.Y := 0;
    Result.Z := 0;
  end;
end;

class function TXcomGlobe.ShadowValue(const AEarth, ASun: TXcomCord; ANoise: Integer): Byte;
var
  LX, LY, LZ, LTemp: Double;
begin
  LX := AEarth.X - ASun.X;
  LY := AEarth.Y - ASun.Y;
  LZ := AEarth.Z - ASun.Z;
  LX := LX * LX;
  LY := LY * LY;
  LZ := LZ * LZ;
  LTemp := LZ + LY;
  LX := LX + LTemp;
  LX := LX - 2;
  LX := LX * 125.0;
  if LX < -110 then
    LX := -31
  else if LX > 120 then
    LX := 50
  else
    LX := FShadeGradient[SmallInt(Trunc(LX)) + 120];
  LX := LX - ANoise;
  Result := Byte(Trunc(Min(Max(LX, 0.0), 31.0)));
end;

constructor TXcomGlobe.Create(AHost: TXcomStateHost; ASave: TXcomSavedGame; ARuleset: TXcomRuleset;
  ATexture, AMarkerSet: TXcomSurfaceSet; ACenX, ACenY, AWidth, AHeight, AX, AY: Integer);
var
  LRandom: TXcomCRandom;
  LIndex: Integer;
begin
  inherited Create(AWidth, AHeight, AX, AY);
  FHost := AHost;
  FSave := ASave;
  FRuleset := ARuleset;
  FRules := ARuleset.Globe;
  FTexture := ATexture.Clone;
  FMarkerSet := AMarkerSet.Clone;
  FCenX := ACenX;
  FCenY := ACenY;
  FBlink := -1;
  FDetail := True;
  FRadarLines := True;
  FFlightPaths := True;
  FAllRadarsOnBaseBuild := True;
  FScrollSpeed := 20;
  FCountries := TXcomSurface.Create(AWidth, AHeight, AX, AY);
  FMarkers := TXcomSurface.Create(AWidth, AHeight, AX, AY);
  FRadars := TXcomSurface.Create(AWidth, AHeight, AX, AY);
  FBlinkTimer := TXcomTimer.Create(AHost.Clock, 100);
  FBlinkTimer.OnTimerSurface(Blink);
  FBlinkTimer.Start;
  FRotTimer := TXcomTimer.Create(AHost.Clock, 10);
  FRotTimer.OnTimerSurface(Rotate);
  FCacheLand := TObjectList<TXcomPolygon>.Create(True);
  FCities := TObjectList<TXcomCity>.Create(True);
  BuildCities;
  FCenLon := ASave.GlobeLongitude;
  FCenLat := ASave.GlobeLatitude;
  FZoom := ASave.GlobeZoom;
  FZoomOld := FZoom;
  SetupRadii(AWidth, AHeight);
  SetZoom(FZoom);
  SetLength(FNoise, NOISE_SIZE * NOISE_SIZE);
  LRandom := TXcomCRandom.Create(1);
  for LIndex := 0 to High(FNoise) do
    FNoise[LIndex] := LRandom.Next mod 4;
  CachePolygons;
end;

destructor TXcomGlobe.Destroy;
begin
  FCities.Free;
  FCacheLand.Free;
  FRotTimer.Free;
  FBlinkTimer.Free;
  FRadars.Free;
  FMarkers.Free;
  FCountries.Free;
  FMarkerSet.Free;
  FTexture.Free;
  inherited Destroy;
end;

procedure TXcomGlobe.BuildCities;
var
  LRegion: TXcomRegion;
  LZone: TXcomMissionZone;
  LArea: TXcomMissionArea;
begin
  // RuleRegion::getCities: the areas of every zone that are a point with a name
  for LRegion in FSave.Regions do
    for LZone in LRegion.Rules.MissionZones do
      for LArea in LZone.Areas do
        if AreSame(LArea.LonMin, LArea.LonMax) and AreSame(LArea.LatMin, LArea.LatMax) and (LArea.Name <> '') then
          FCities.Add(TXcomCity.Create(LArea.Name, LArea.LonMin, LArea.LatMin));
end;

procedure TXcomGlobe.SetupRadii(AWidth, AHeight: Integer);
begin
  SetLength(FZoomRadius, 6);
  FZoomRadius[0] := 0.45 * AHeight;
  FZoomRadius[1] := 0.60 * AHeight;
  FZoomRadius[2] := 0.90 * AHeight;
  FZoomRadius[3] := 1.40 * AHeight;
  FZoomRadius[4] := 2.25 * AHeight;
  FZoomRadius[5] := 3.60 * AHeight;
  FRadius := FZoomRadius[FZoom];
  FRadiusStep := (FZoomRadius[DOGFIGHT_ZOOM] - FZoomRadius[0]) / 10.0;
  SetLength(FEarthData, 6);
end;

function TXcomGlobe.EarthData(AZoom: Integer): TArray<TXcomCord>;
var
  LX, LY: Integer;
begin
  // the C++ fills the six tables when it is built; here a table is made the first time its zoom is drawn
  if Length(FEarthData[AZoom]) = 0 then
  begin
    SetLength(FEarthData[AZoom], Width * Height);
    for LY := 0 to Height - 1 do
      for LX := 0 to Width - 1 do
        FEarthData[AZoom][Width * LY + LX] := CircleNorm(Width div 2, Height div 2, FZoomRadius[AZoom], LX + 0.5,
          LY + 0.5);
  end;
  Result := FEarthData[AZoom];
end;

procedure TXcomGlobe.PolarToCart(ALon, ALat: Double; out AX, AY: SmallInt);
var
  LValue: Double;
begin
  LValue := FRadius * Cos(ALat) * Sin(ALon - FCenLon);
  AX := SmallInt(FCenX + SmallInt(Floor(LValue)));
  LValue := FRadius * (Cos(FCenLat) * Sin(ALat) - Sin(FCenLat) * Cos(ALat) * Cos(ALon - FCenLon));
  AY := SmallInt(FCenY + SmallInt(Floor(LValue)));
end;

procedure TXcomGlobe.PolarToCart(ALon, ALat: Double; out AX, AY: Double);
begin
  AX := FCenX + FRadius * Cos(ALat) * Sin(ALon - FCenLon);
  AY := FCenY + FRadius * (Cos(FCenLat) * Sin(ALat) - Sin(FCenLat) * Cos(ALat) * Cos(ALon - FCenLon));
end;

function TXcomGlobe.CartToPolar(AX, AY: SmallInt; out ALon, ALat: Double): Boolean;
var
  LX, LY, LRho, LC, LRatio: Double;
begin
  LX := AX - FCenX;
  LY := AY - FCenY;
  LRho := Sqrt(LX * LX + LY * LY);
  LRatio := LRho / FRadius;
  if LRatio > 1.0 then
  begin
    ALon := 0;
    ALat := 0;
    Exit(False);
  end;
  LC := ArcSin(LRatio);
  if AreSame(LRho, 0.0) then
  begin
    ALat := FCenLat;
    ALon := FCenLon;
  end
  else
  begin
    ALat := ArcSin((LY * Sin(LC) * Cos(FCenLat)) / LRho + Cos(LC) * Sin(FCenLat));
    ALon := ArcTan2(LX * Sin(LC), LRho * Cos(FCenLat) * Cos(LC) - LY * Sin(FCenLat) * Sin(LC)) + FCenLon;
  end;
  while ALon < 0 do
    ALon := ALon + 2 * PI;
  while ALon >= 2 * PI do
    ALon := ALon - 2 * PI;
  Result := True;
end;

function TXcomGlobe.PointBack(ALon, ALat: Double): Boolean;
var
  LValue: Double;
begin
  LValue := Cos(FCenLat) * Cos(ALat) * Cos(ALon - FCenLon) + Sin(FCenLat) * Sin(ALat);
  Result := LValue < 0.0;
end;

function TXcomGlobe.GetPolygonFromLonLat(ALon, ALat: Double): TXcomPolygon;
const
  Z_DISCARD = 0.75;
var
  LCosLat, LSinLat, LX, LY, LZ, LX2, LY2, LCLat, LCLon: Double;
  LPolygon: TXcomPolygon;
  LPoint, LNext: Integer;
  LOdd: Boolean;
begin
  Result := nil;
  LCosLat := Cos(ALat);
  LSinLat := Sin(ALat);
  for LPolygon in FRules.Polygons do
  begin
    LZ := 0;
    for LPoint := 0 to LPolygon.Points - 1 do
    begin
      LZ := LCosLat * Cos(LPolygon.GetLatitude(LPoint)) * Cos(LPolygon.GetLongitude(LPoint) - ALon) +
        LSinLat * Sin(LPolygon.GetLatitude(LPoint));
      if LZ < Z_DISCARD then
        Break;
    end;
    if LZ < Z_DISCARD then
      Continue;
    LOdd := False;
    LCLat := LPolygon.GetLatitude(0);
    LCLon := LPolygon.GetLongitude(0);
    LX := Cos(LCLat) * Sin(LCLon - ALon);
    LY := LCosLat * Sin(LCLat) - LSinLat * Cos(LCLat) * Cos(LCLon - ALon);
    for LPoint := 0 to LPolygon.Points - 1 do
    begin
      LNext := (LPoint + 1) mod LPolygon.Points;
      LCLat := LPolygon.GetLatitude(LNext);
      LCLon := LPolygon.GetLongitude(LNext);
      LX2 := Cos(LCLat) * Sin(LCLon - ALon);
      LY2 := LCosLat * Sin(LCLat) - LSinLat * Cos(LCLat) * Cos(LCLon - ALon);
      if ((LY > 0) <> (LY2 > 0)) and (0 < (LX2 - LX) * (0 - LY) / (LY2 - LY) + LX) then
        LOdd := not LOdd;
      LX := LX2;
      LY := LY2;
    end;
    if LOdd then
      Exit(LPolygon);
  end;
end;

function TXcomGlobe.InsideLand(ALon, ALat: Double): Boolean;
begin
  Result := GetPolygonFromLonLat(ALon, ALat) <> nil;
end;

function TXcomGlobe.GetTargets(AX, AY: Integer; ACraftOnly: Boolean): TList<TXcomTarget>;

  function Near(const ATarget: TXcomTarget): Boolean;
  var
    LX, LY: SmallInt;
  begin
    // Globe::targetNear (NEAR_RADIUS = 25, compared with the squared distance)
    if PointBack(ATarget.Longitude, ATarget.Latitude) then
      Exit(False);
    PolarToCart(ATarget.Longitude, ATarget.Latitude, LX, LY);
    Result := Sqr(AX - LX) + Sqr(AY - LY) <= 25;
  end;

var
  LBase: TXcomBase;
  LCraft: TXcomCraft;
  LUfo: TXcomUfo;
  LWaypoint: TXcomWaypoint;
  LSite: TXcomMissionSite;
  LAlienBase: TXcomAlienBase;
begin
  Result := TList<TXcomTarget>.Create;
  if not ACraftOnly then
    for LBase in FSave.Bases do
    begin
      if (LBase.Longitude = 0.0) and (LBase.Latitude = 0.0) then
        Continue;
      if Near(LBase) then
        Result.Add(LBase);
      for LCraft in LBase.Crafts do
      begin
        if (LCraft.Longitude = LBase.Longitude) and (LCraft.Latitude = LBase.Latitude)
          and (LCraft.Destination = nil) then
          Continue;
        if Near(LCraft) then
          Result.Add(LCraft);
      end;
    end;
  for LUfo in FSave.Ufos do
    if LUfo.Detected and Near(LUfo) then
      Result.Add(LUfo);
  for LWaypoint in FSave.Waypoints do
    if Near(LWaypoint) then
      Result.Add(LWaypoint);
  for LSite in FSave.MissionSites do
    if Near(LSite) then
      Result.Add(LSite);
  for LAlienBase in FSave.AlienBases do
    if LAlienBase.Discovered and Near(LAlienBase) then
      Result.Add(LAlienBase);
end;

procedure TXcomGlobe.RotateLeft;
begin
  FRotLon := -ROTATE_LONGITUDE;
  if not FRotTimer.IsRunning then
    FRotTimer.Start;
end;

procedure TXcomGlobe.RotateRight;
begin
  FRotLon := ROTATE_LONGITUDE;
  if not FRotTimer.IsRunning then
    FRotTimer.Start;
end;

procedure TXcomGlobe.RotateUp;
begin
  FRotLat := -ROTATE_LATITUDE;
  if not FRotTimer.IsRunning then
    FRotTimer.Start;
end;

procedure TXcomGlobe.RotateDown;
begin
  FRotLat := ROTATE_LATITUDE;
  if not FRotTimer.IsRunning then
    FRotTimer.Start;
end;

procedure TXcomGlobe.RotateStop;
begin
  FRotLon := 0.0;
  FRotLat := 0.0;
  FRotTimer.Stop;
end;

procedure TXcomGlobe.RotateStopLon;
begin
  FRotLon := 0.0;
  if AreSame(FRotLat, 0.0) then
    FRotTimer.Stop;
end;

procedure TXcomGlobe.RotateStopLat;
begin
  FRotLat := 0.0;
  if AreSame(FRotLon, 0.0) then
    FRotTimer.Stop;
end;

procedure TXcomGlobe.SetZoom(AZoom: Integer);
begin
  FZoom := Min(Max(AZoom, 0), High(FZoomRadius));
  FZoomTexture := (2 - Floor(FZoom / 2.0)) * (FTexture.TotalFrames div 3);
  FRadius := FZoomRadius[FZoom];
  FSave.GlobeZoom := FZoom;
  Invalidate;
end;

procedure TXcomGlobe.ZoomIn;
begin
  if FZoom < High(FZoomRadius) then
    SetZoom(FZoom + 1);
end;

procedure TXcomGlobe.ZoomOut;
begin
  if FZoom > 0 then
    SetZoom(FZoom - 1);
end;

procedure TXcomGlobe.ZoomMin;
begin
  if FZoom > 0 then
    SetZoom(0);
end;

procedure TXcomGlobe.ZoomMax;
begin
  if FZoom < High(FZoomRadius) then
    SetZoom(High(FZoomRadius));
end;

procedure TXcomGlobe.SetCenterValue(ALon, ALat: Double);
begin
  FCenLon := ALon;
  FCenLat := ALat;
  FSave.GlobeLongitude := FCenLon;
  FSave.GlobeLatitude := FCenLat;
end;

procedure TXcomGlobe.Center(ALon, ALat: Double);
begin
  SetCenterValue(ALon, ALat);
  Invalidate;
end;

procedure TXcomGlobe.ToggleDetail;
begin
  FDetail := not FDetail;
  DrawDetail;
end;

procedure TXcomGlobe.ToggleRadarLines;
begin
  FRadarLines := not FRadarLines;
  DrawRadars;
end;

procedure TXcomGlobe.SetNewBaseHover(AHover: Boolean);
begin
  FHover := AHover;
end;

procedure TXcomGlobe.SetNewBaseHoverPos(ALon, ALat: Double);
begin
  FHoverLon := ALon;
  FHoverLat := ALat;
end;

procedure TXcomGlobe.SetCraftRange(ALon, ALat, ARange: Double);
begin
  FCraft := ARange > 0.0;
  FCraftLon := ALon;
  FCraftLat := ALat;
  FCraftRange := ARange;
end;

procedure TXcomGlobe.DrawRadarsNow;
begin
  DrawRadars;
end;

procedure TXcomGlobe.SetNoise(const ANoise: TArray<SmallInt>);
begin
  if Length(ANoise) <> NOISE_SIZE * NOISE_SIZE then
    raise EArgumentException.Create('XcomGlobe: the noise has 60 x 60 values');
  FNoise := System.Copy(ANoise);
  Invalidate;
end;

procedure TXcomGlobe.CachePolygons;
var
  LPolygon, LCopy: TXcomPolygon;
  LPoint: Integer;
  LClosest, LFurthest, LZ: Double;
  LX, LY: SmallInt;
begin
  FCacheLand.Clear;
  for LPolygon in FRules.Polygons do
  begin
    LClosest := 0.0;
    LFurthest := 0.0;
    for LPoint := 0 to LPolygon.Points - 1 do
    begin
      LZ := Cos(FCenLat) * Cos(LPolygon.GetLatitude(LPoint)) * Cos(LPolygon.GetLongitude(LPoint) - FCenLon) +
        Sin(FCenLat) * Sin(LPolygon.GetLatitude(LPoint));
      if LZ > LClosest then
        LClosest := LZ
      else if LZ < LFurthest then
        LFurthest := LZ;
    end;
    if -LFurthest > LClosest then
      Continue;
    LCopy := TXcomPolygon.CreateCopy(LPolygon);
    for LPoint := 0 to LCopy.Points - 1 do
    begin
      PolarToCart(LCopy.GetLongitude(LPoint), LCopy.GetLatitude(LPoint), LX, LY);
      LCopy.SetX(LPoint, LX);
      LCopy.SetY(LPoint, LY);
    end;
    FCacheLand.Add(LCopy);
  end;
end;

procedure TXcomGlobe.SetPalette(AColors: PXcomColor; AFirst, ACount: Integer);
var
  LColors: TArray<TXcomColor>;
  LIndex: Integer;
begin
  inherited SetPalette(AColors, AFirst, ACount);
  SetLength(LColors, ACount);
  for LIndex := 0 to ACount - 1 do
  begin
    LColors[LIndex] := PXcomColor(PByte(AColors) + LIndex * SizeOf(TXcomColor))^;
    if AFirst + LIndex <= 255 then
      FColors[AFirst + LIndex] := LColors[LIndex];
  end;
  FTexture.SetPalette(LColors, AFirst);
  FMarkerSet.SetPalette(LColors, AFirst);
  FCountries.SetColors(LColors, AFirst);
  FMarkers.SetColors(LColors, AFirst);
  FRadars.SetColors(LColors, AFirst);
end;

procedure TXcomGlobe.Think;
begin
  inherited Think;
  FBlinkTimer.Think(False, True);
  FRotTimer.Think(False, True);
end;

procedure TXcomGlobe.Blink;
var
  LIndex: Integer;
begin
  FBlink := -FBlink;
  for LIndex in FMarkerSet.Indexes do
    if LIndex <> CITY_MARKER then
      FMarkerSet.GetFrame(LIndex).Offset(FBlink);
  DrawMarkers;
end;

procedure TXcomGlobe.Rotate;
begin
  SetCenterValue(FCenLon + FRotLon * ((110 - FScrollSpeed) / 100.0) / (FZoom + 1),
    FCenLat + FRotLat * ((110 - FScrollSpeed) / 100.0) / (FZoom + 1));
  Invalidate;
end;

procedure TXcomGlobe.Draw;
var
  LMode: TXcomFloatMode;
begin
  LMode := TXcomFloatMode.Enter;
  try
    if Redraw then
      CachePolygons;
    inherited Draw;
    DrawOcean;
    DrawLand;
    DrawRadars;
    DrawFlights;
    DrawShadow;
    DrawMarkers;
    DrawDetail;
  finally
    LMode.Leave;
  end;
end;

procedure TXcomGlobe.DrawOcean;
begin
  TXcomGfx.DrawCircle(Self, FCenX + 1, FCenY, Trunc(FRadius + 20), FRules.OceanColor);
end;

procedure TXcomGlobe.DrawLand;
var
  LPolygon: TXcomPolygon;
  LX, LY: array[0..3] of SmallInt;
  LPoint: Integer;
  LTexture: TXcomSurface;
begin
  for LPolygon in FCacheLand do
  begin
    for LPoint := 0 to LPolygon.Points - 1 do
    begin
      LX[LPoint] := LPolygon.GetX(LPoint);
      LY[LPoint] := LPolygon.GetY(LPoint);
    end;
    LTexture := FTexture.GetFrame(LPolygon.Texture + FZoomTexture);
    if Assigned(LTexture) then
      TXcomGfx.DrawTexturedPolygon(Self, Slice(LX, LPolygon.Points), Slice(LY, LPolygon.Points), LTexture, 0, 0);
  end;
end;

procedure TXcomGlobe.GetPolygonTextureAndShade(ALon, ALat: Double; out ATexture, AShade: Integer);
const
  WORLD_SHADES: array[0..31] of Integer = (0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 11,
    11, 12, 12, 13, 13, 14, 15, 15);
var
  LEarth: TXcomCord;
  LPolygon: TXcomPolygon;
begin
  LEarth.X := 0;
  LEarth.Y := 0;
  LEarth.Z := 1;
  AShade := WORLD_SHADES[ShadowValue(LEarth, SunDirection(ALon, ALat), 0)];
  LPolygon := GetPolygonFromLonLat(ALon, ALat);
  if LPolygon = nil then
    ATexture := -1
  else
    ATexture := LPolygon.Texture;
end;

function TXcomGlobe.HasTexture(AId: Integer): Boolean;
begin
  Result := FRules.GetTexture(AId) <> nil;
end;

function TXcomGlobe.SunDirection(ALon, ALat: Double): TXcomCord;
const
  MONTH_DAYS_COMMON: array[0..12] of Integer = (0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365);
  MONTH_DAYS_LEAP: array[0..12] of Integer = (0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335, 366);
var
  LRot, LSun, LTime, LCurDay, LNorm, LFactor: Double;
  LYear, LMonth, LDay: Integer;
  LDirection, LPole: TXcomCord;
begin
  LRot := FSave.Time.Daylight * 2 * PI;
  if FSeasons then
  begin
    LYear := FSave.Time.Year;
    LMonth := FSave.Time.Month - 1;
    LDay := FSave.Time.Day - 1;
    LTime := ((FSave.Time.Hour * 60 + FSave.Time.Minute) * 60 + FSave.Time.Second) / 86400;
    if (LYear mod 4 = 0) and not ((LYear mod 100 = 0) and (LYear mod 400 <> 0)) then
      LCurDay := (MONTH_DAYS_LEAP[LMonth] + LDay + LTime) / 366 - 0.219
    else
      LCurDay := (MONTH_DAYS_COMMON[LMonth] + LDay + LTime) / 365 - 0.219;
    if LCurDay < 0 then
      LCurDay := LCurDay + 1.0;
    LSun := -0.261 * Sin(LCurDay * 2 * PI);
  end
  else
    LSun := 0;
  LDirection.X := Cos(LRot + ALon);
  LDirection.Y := Sin(LRot + ALon) * -Sin(ALat);
  LDirection.Z := Sin(LRot + ALon) * Cos(ALat);
  LPole.X := 0;
  LPole.Y := Cos(ALat);
  LPole.Z := Sin(ALat);
  if LSun > 0 then
    LFactor := 1.0 - LSun
  else
    LFactor := 1.0 + LSun;
  LDirection.X := LDirection.X * LFactor;
  LDirection.Y := LDirection.Y * LFactor;
  LDirection.Z := LDirection.Z * LFactor;
  LPole.X := LPole.X * LSun;
  LPole.Y := LPole.Y * LSun;
  LPole.Z := LPole.Z * LSun;
  LDirection.X := LDirection.X + LPole.X;
  LDirection.Y := LDirection.Y + LPole.Y;
  LDirection.Z := LDirection.Z + LPole.Z;
  LNorm := Sqrt(LDirection.X * LDirection.X + LDirection.Y * LDirection.Y + LDirection.Z * LDirection.Z);
  LNorm := 1.0 / LNorm;
  LDirection.X := LDirection.X * LNorm;
  LDirection.Y := LDirection.Y * LNorm;
  LDirection.Z := LDirection.Z * LNorm;
  Result := LDirection;
end;

procedure TXcomGlobe.DrawShadow;
var
  LEarth: TArray<TXcomCord>;
  LSun: TXcomCord;
  LX, LY, LShadow, LSplit, LEnd, LGroup: Integer;
  LDest: PByte;
  LOcean: Byte;
begin
  LEarth := EarthData(FZoom);
  LSun := SunDirection(FCenLon, FCenLat);
  LOcean := FRules.OceanColor;
  // the earth table is moved by (cenX - width/2, cenY - height/2); the shade is drawn where table and surface meet
  for LY := 0 to Height - 1 do
    for LX := 0 to Width - 1 do
    begin
      LDest := PixelPointer(LX, LY);
      if (LX - (FCenX - Width div 2) < 0) or (LX - (FCenX - Width div 2) >= Width) or
        (LY - (FCenY - Height div 2) < 0) or (LY - (FCenY - Height div 2) >= Height) then
        Continue;
      if (LDest^ <> 0) and (LEarth[(LY - (FCenY - Height div 2)) * Width + (LX - (FCenX - Width div 2))].Z <> 0) then
      begin
        LShadow := ShadowValue(LEarth[(LY - (FCenY - Height div 2)) * Width + (LX - (FCenX - Width div 2))], LSun,
          FNoise[(LY mod NOISE_SIZE) * NOISE_SIZE + (LX mod NOISE_SIZE)]);
        if FRules.OceanShading and (LDest^ >= LOcean) and (LDest^ < LOcean + 32) then
          LDest^ := Byte(LOcean + LShadow)
        else if LShadow <> 0 then
        begin
          LSplit := LShadow div 3;
          LEnd := LDest^ + LSplit;
          LGroup := LDest^ and $F0;
          if LEnd > LGroup + $0F then
            LDest^ := Byte(LGroup + $0F)
          else
            LDest^ := Byte(LEnd);
        end;
      end
      else
        LDest^ := 0;
    end;
end;

function TXcomGlobe.ClipLine(var AX1, AY1, AX2, AY2: Double): Boolean;
var
  LLeft, LRight, LTop, LBottom: Double;
  function Code(AX, AY: Double): Integer;
  begin
    Result := 0;
    if AX < LLeft then
      Result := Result or 1
    else if AX > LRight then
      Result := Result or 2;
    if AY < LTop then
      Result := Result or 4
    else if AY > LBottom then
      Result := Result or 8;
  end;
var
  LCode1, LCode2, LCode: Integer;
  LX, LY: Double;
begin
  // FastLineClip is a Cohen-Sutherland with the cases written out; the window is the surface
  LLeft := X;
  LRight := X + Width;
  LTop := Y;
  LBottom := Y + Height;
  LCode1 := Code(AX1, AY1);
  LCode2 := Code(AX2, AY2);
  while True do
  begin
    if (LCode1 or LCode2) = 0 then
      Exit(True);
    if (LCode1 and LCode2) <> 0 then
      Exit(False);
    if LCode1 <> 0 then
      LCode := LCode1
    else
      LCode := LCode2;
    if (LCode and 8) <> 0 then
    begin
      LX := AX1 + (AX2 - AX1) * (LBottom - AY1) / (AY2 - AY1);
      LY := LBottom;
    end
    else if (LCode and 4) <> 0 then
    begin
      LX := AX1 + (AX2 - AX1) * (LTop - AY1) / (AY2 - AY1);
      LY := LTop;
    end
    else if (LCode and 2) <> 0 then
    begin
      LY := AY1 + (AY2 - AY1) * (LRight - AX1) / (AX2 - AX1);
      LX := LRight;
    end
    else
    begin
      LY := AY1 + (AY2 - AY1) * (LLeft - AX1) / (AX2 - AX1);
      LX := LLeft;
    end;
    if LCode = LCode1 then
    begin
      AX1 := LX;
      AY1 := LY;
      LCode1 := Code(AX1, AY1);
    end
    else
    begin
      AX2 := LX;
      AY2 := LY;
      LCode2 := Code(AX2, AY2);
    end;
  end;
end;

procedure TXcomGlobe.XuLine(ASurface, ASource: TXcomSurface; AX1, AY1, AX2, AY2: Double; AShade: Integer);
var
  LDeltaX, LDeltaY, LLength, LX0, LY0, LSX, LSY: Double;
  LInverse: Boolean;
  LColor, LOcean: Integer;
  LGroup, LEnd: Integer;
begin
  if not ClipLine(AX1, AY1, AX2, AY2) then
    Exit;
  LDeltaX := AX2 - AX1;
  LDeltaY := AY2 - AY1;
  if Abs(Trunc(AY2) - Trunc(AY1)) > Abs(Trunc(AX2) - Trunc(AX1)) then
  begin
    LLength := Abs(Trunc(AY2) - Trunc(AY1));
    LInverse := False;
  end
  else
  begin
    LLength := Abs(Trunc(AX2) - Trunc(AX1));
    LInverse := True;
  end;
  if AY2 < AY1 then
    LSY := -1
  else if AreSame(LDeltaY, 0.0) then
    LSY := 0
  else
    LSY := 1;
  if AX2 < AX1 then
    LSX := -1
  else if AreSame(LDeltaX, 0.0) then
    LSX := 0
  else
    LSX := 1;
  LX0 := AX1;
  LY0 := AY1;
  if LInverse then
    LSY := LDeltaY / LLength
  else
    LSX := LDeltaX / LLength;
  LOcean := FRules.OceanColor;
  while LLength > 0 do
  begin
    LColor := ASource.GetPixel(Trunc(LX0), Trunc(LY0));
    if LColor <> 0 then
    begin
      if FRules.OceanShading and (LColor >= LOcean) and (LColor < LOcean + 32) then
        LColor := Byte(LOcean + AShade + 8)
      else
      begin
        // getLandShadow(color, shade * 3)
        if (AShade * 3) <> 0 then
        begin
          LEnd := LColor + (Byte(AShade * 3) div 3);
          LGroup := LColor and $F0;
          if LEnd > LGroup + $0F then
            LColor := LGroup + $0F
          else
            LColor := LEnd;
        end;
      end;
      ASurface.SetPixel(Trunc(LX0), Trunc(LY0), Byte(LColor));
    end;
    LX0 := LX0 + LSX;
    LY0 := LY0 + LSY;
    LLength := LLength - 1.0;
  end;
end;

procedure TXcomGlobe.DrawGlobeCircle(ALat, ALon, ARadius: Double; ASegments, AFraction: Integer);
var
  LX, LY, LX2, LY2, LLat1, LLon1, LSegment, LAzimuth: Double;
  LIndex: Integer;
begin
  LX2 := 0;
  LY2 := 0;
  LIndex := 0;
  LSegment := PI / (ASegments / 2);
  LAzimuth := 0;
  while LAzimuth <= PI * 2 + 0.01 do
  begin
    LLat1 := ArcSin(Sin(ALat) * Cos(ARadius) + Cos(ALat) * Sin(ARadius) * Cos(LAzimuth));
    LLon1 := ALon + ArcTan2(Sin(LAzimuth) * Sin(ARadius) * Cos(ALat), Cos(ARadius) - Sin(ALat) * Sin(LLat1));
    PolarToCart(LLon1, LLat1, LX, LY);
    if AreSame(LAzimuth, 0.0) then
    begin
      LX2 := LX;
      LY2 := LY;
    end
    else
    begin
      if (not PointBack(LLon1, LLat1)) and (LIndex mod AFraction = 0) then
        XuLine(FRadars, Self, LX, LY, LX2, LY2, 6);
      LX2 := LX;
      LY2 := LY;
      Inc(LIndex);
    end;
    LAzimuth := LAzimuth + LSegment;
  end;
end;

procedure TXcomGlobe.DrawPath(ASurface: TXcomSurface; ALon1, ALat1, ALon2, ALat2: Double);
var
  LA, LB: TXcomCord;
  LLength, LInverse: Double;
  LCount: SmallInt;
  LIndex: Integer;
  LX1, LY1, LX2, LY2: Double;
  LLon1, LLat1, LLon2, LLat2: Double;

  function ToCord(ALon, ALat: Double): TXcomCord;
  begin
    Result.X := Sin(ALon) * Cos(ALat);
    Result.Y := Sin(ALat);
    Result.Z := Cos(ALon) * Cos(ALat);
  end;

  procedure ToPolar(const ACord: TXcomCord; out ALon, ALat: Double);
  var
    LNorm: Double;
  begin
    LNorm := 1 / Sqrt(ACord.X * ACord.X + ACord.Y * ACord.Y + ACord.Z * ACord.Z);
    ALat := ArcSin(ACord.Y * LNorm);
    ALon := ArcTan2(ACord.X, ACord.Z);
  end;

begin
  LA := ToCord(ALon1, ALat1);
  LB := ToCord(ALon2, ALat2);
  // the opposite point of the globe: there is no shortest path
  if AreSame(-LB.X, LA.X) and AreSame(-LB.Y, LA.Y) and AreSame(-LB.Z, LA.Z) then
    Exit;
  LB.X := LB.X - LA.X;
  LB.Y := LB.Y - LA.Y;
  LB.Z := LB.Z - LA.Z;
  // a longer path has more parts
  LLength := Sqrt(LB.X * LB.X + LB.Y * LB.Y + LB.Z * LB.Z);
  LLength := LLength * LLength * 15;
  LCount := Trunc(LLength + 1);
  LInverse := 1.0 / LCount;
  LB.X := LB.X * LInverse;
  LB.Y := LB.Y * LInverse;
  LB.Z := LB.Z * LInverse;
  ToPolar(LA, LLon1, LLat1);
  PolarToCart(LLon1, LLat1, LX1, LY1);
  for LIndex := 0 to LCount - 1 do
  begin
    LA.X := LA.X + LB.X;
    LA.Y := LA.Y + LB.Y;
    LA.Z := LA.Z + LB.Z;
    ToPolar(LA, LLon2, LLat2);
    PolarToCart(LLon2, LLat2, LX2, LY2);
    if not PointBack(LLon1, LLat1) and not PointBack(LLon2, LLat2) then
      XuLine(ASurface, Self, LX1, LY1, LX2, LY2, 8);
    LLon1 := LLon2;
    LLat1 := LLat2;
    LX1 := LX2;
    LY1 := LY2;
  end;
end;

procedure TXcomGlobe.DrawFlights;
var
  LBase: TXcomBase;
  LCraft: TXcomCraft;
  LLon1, LLat1, LLon2, LLat2: Double;
begin
  if not FFlightPaths then
    Exit;
  for LBase in FSave.Bases do
    for LCraft in LBase.Crafts do
    begin
      // the crafts docked at the base have no path
      if (LCraft.Status <> 'STR_OUT') or (LCraft.Destination = nil) then
        Continue;
      LLon1 := LCraft.Longitude;
      LLat1 := LCraft.Latitude;
      LLon2 := LCraft.Destination.Longitude;
      LLat2 := LCraft.Destination.Latitude;
      if LCraft.MeetCalculated then
      begin
        LLon2 := LCraft.MeetLongitude;
        LLat2 := LCraft.MeetLatitude;
      end;
      DrawPath(FRadars, LLon1, LLat1, LLon2, LLat2);
      // from the point where the craft meets its target to where the target is now
      if LCraft.MeetCalculated then
      begin
        LLon1 := LCraft.Destination.Longitude;
        LLat1 := LCraft.Destination.Latitude;
        DrawPath(FRadars, LLon1, LLat1, LLon2, LLat2);
      end;
    end;
end;

procedure TXcomGlobe.DrawRadars;
var
  LBase: TXcomBase;
  LFacility: TXcomBaseFacility;
  LCraft: TXcomCraft;
  LRange, LTemp: Double;
  LRanges: TList<Double>;
  LIndex, LRule: Integer;
  LRuleFacility: TXcomRuleBaseFacility;
begin
  FRadars.Clear;
  if FCraft then
  begin
    if FCraftRange < PI then
    begin
      DrawGlobeCircle(FCraftLat, FCraftLon, FCraftRange, 64);
      DrawGlobeCircle(FCraftLat, FCraftLon, FCraftRange - 0.025, 64, 2);
    end;
    Exit;
  end;
  if not FRadarLines then
    Exit;
  LRanges := TList<Double>.Create;
  try
    if FHover then
      for LRule := 0 to FRuleset.Facilities.Count - 1 do
      begin
        LRange := Nautical(FRuleset.Facilities.Rule(LRule).RadarRange);
        DrawGlobeCircle(FHoverLat, FHoverLon, LRange, 48);
        if FAllRadarsOnBaseBuild then
          LRanges.Add(LRange);
      end;
    for LBase in FSave.Bases do
    begin
      if not (AreSame(LBase.Longitude, 0.0) and AreSame(LBase.Latitude, 0.0)) then
      begin
        if FHover and FAllRadarsOnBaseBuild then
        begin
          for LIndex := 0 to LRanges.Count - 1 do
            DrawGlobeCircle(LBase.Latitude, LBase.Longitude, LRanges[LIndex], 48);
        end
        else
        begin
          LRange := 0;
          for LFacility in LBase.Facilities do
            if LFacility.BuildTime = 0 then
            begin
              LRuleFacility := FRuleset.Facilities.Find(LFacility.Rules.FacilityType);
              if Assigned(LRuleFacility) then
              begin
                LTemp := LRuleFacility.RadarRange;
                if LTemp > LRange then
                  LRange := LTemp;
              end;
            end;
          LRange := Nautical(LRange);
          if LRange > 0 then
            DrawGlobeCircle(LBase.Latitude, LBase.Longitude, LRange, 48);
        end;
      end;
      for LCraft in LBase.Crafts do
      begin
        if LCraft.Status <> 'STR_OUT' then
          Continue;
        LRange := Nautical(LCraft.Rules.RadarRange);
        if LRange > 0 then
          DrawGlobeCircle(LCraft.Latitude, LCraft.Longitude, LRange, 24);
      end;
    end;
  finally
    LRanges.Free;
  end;
end;

procedure TXcomGlobe.DrawTarget(ATarget: TXcomTarget; ASurface: TXcomSurface);
var
  LX, LY: SmallInt;
  LMarker: TXcomSurface;
begin
  if (ATarget.Marker <> -1) and not PointBack(ATarget.Longitude, ATarget.Latitude) then
  begin
    PolarToCart(ATarget.Longitude, ATarget.Latitude, LX, LY);
    LMarker := FMarkerSet.GetFrame(ATarget.Marker);
    if Assigned(LMarker) then
    begin
      LMarker.X := LX - LMarker.Width div 2;
      LMarker.Y := LY - LMarker.Height div 2;
      LMarker.Blit(ASurface);
    end;
  end;
end;

procedure TXcomGlobe.DrawMarkers;
var
  LBase: TXcomBase;
  LCraft: TXcomCraft;
  LWaypoint: TXcomWaypoint;
  LSite: TXcomMissionSite;
  LAlienBase: TXcomAlienBase;
  LUfo: TXcomUfo;
begin
  FMarkers.Clear;
  for LBase in FSave.Bases do
    DrawTarget(LBase, FMarkers);
  for LWaypoint in FSave.Waypoints do
    DrawTarget(LWaypoint, FMarkers);
  for LSite in FSave.MissionSites do
    DrawTarget(LSite, FMarkers);
  for LAlienBase in FSave.AlienBases do
    DrawTarget(LAlienBase, FMarkers);
  for LUfo in FSave.Ufos do
    DrawTarget(LUfo, FMarkers);
  for LBase in FSave.Bases do
    for LCraft in LBase.Crafts do
      DrawTarget(LCraft, FMarkers);
end;

procedure TXcomGlobe.DrawDetail;
var
  LPolyline: TXcomPolyline;
  LPoint: Integer;
  LX, LY: array[0..1] of SmallInt;
  LLabel: TXcomText;
  LCountry: TXcomCountry;
  LCity: TXcomCity;
  LBase: TXcomBase;
  LLabelX, LLabelY: SmallInt;
begin
  FCountries.Clear;
  if not FDetail then
    Exit;
  if FZoom >= 1 then
    for LPolyline in FRules.Polylines do
      for LPoint := 0 to LPolyline.Points - 2 do
      begin
        if PointBack(LPolyline.GetLongitude(LPoint), LPolyline.GetLatitude(LPoint)) or
          PointBack(LPolyline.GetLongitude(LPoint + 1), LPolyline.GetLatitude(LPoint + 1)) then
          Continue;
        PolarToCart(LPolyline.GetLongitude(LPoint), LPolyline.GetLatitude(LPoint), LX[0], LY[0]);
        PolarToCart(LPolyline.GetLongitude(LPoint + 1), LPolyline.GetLatitude(LPoint + 1), LX[1], LY[1]);
        TXcomGfx.DrawLine(FCountries, LX[0], LY[0], LX[1], LY[1], FRules.LineColor);
      end;
  if FZoom >= 2 then
  begin
    LLabel := TXcomText.Create(100, 9, 0, 0);
    try
      LLabel.SetPalette(@FColors[0], 0, 256);
      LLabel.InitText(FHost.Resources.GetFont('FONT_BIG'), FHost.Resources.GetFont('FONT_SMALL'), FHost.Language);
      LLabel.SetAlign(haCenter);
      LLabel.SetColor(FRules.CountryLabelColor);
      for LCountry in FSave.Countries do
      begin
        if PointBack(LCountry.Rules.LabelLongitude, LCountry.Rules.LabelLatitude) then
          Continue;
        PolarToCart(LCountry.Rules.LabelLongitude, LCountry.Rules.LabelLatitude, LLabelX, LLabelY);
        LLabel.X := LLabelX - 50;
        LLabel.Y := LLabelY;
        LLabel.SetText(FHost.Language.GetString(LCountry.Rules.CountryType));
        LLabel.Blit(FCountries);
      end;
    finally
      LLabel.Free;
    end;
  end;
  if FZoom >= 3 then
  begin
    LLabel := TXcomText.Create(100, 9, 0, 0);
    try
      LLabel.SetPalette(@FColors[0], 0, 256);
      LLabel.InitText(FHost.Resources.GetFont('FONT_BIG'), FHost.Resources.GetFont('FONT_SMALL'), FHost.Language);
      LLabel.SetAlign(haCenter);
      LLabel.SetColor(FRules.CityLabelColor);
      for LCity in FCities do
      begin
        DrawTarget(LCity, FCountries);
        if PointBack(LCity.Longitude, LCity.Latitude) then
          Continue;
        PolarToCart(LCity.Longitude, LCity.Latitude, LLabelX, LLabelY);
        LLabel.X := LLabelX - 50;
        LLabel.Y := LLabelY + 2;
        LLabel.SetText(FHost.Language.GetString(LCity.CityName));
        LLabel.Blit(FCountries);
      end;
      for LBase in FSave.Bases do
      begin
        if (LBase.Marker = -1) or PointBack(LBase.Longitude, LBase.Latitude) then
          Continue;
        PolarToCart(LBase.Longitude, LBase.Latitude, LLabelX, LLabelY);
        LLabel.X := LLabelX - 50;
        LLabel.Y := LLabelY + 2;
        LLabel.SetColor(FRules.BaseLabelColor);
        LLabel.SetText(LBase.Name);
        LLabel.Blit(FCountries);
      end;
    finally
      LLabel.Free;
    end;
  end;
end;

procedure TXcomGlobe.Blit(ATarget: TXcomSurface);
begin
  inherited Blit(ATarget);
  FRadars.Blit(ATarget);
  FCountries.Blit(ATarget);
  FMarkers.Blit(ATarget);
end;

procedure TXcomGlobe.MouseClick(AAction: TXcomAction);
var
  LLon, LLat: Double;
begin
  if AAction.Details^.Button = XCOM_BUTTON_WHEELUP then
    ZoomIn
  else if AAction.Details^.Button = XCOM_BUTTON_WHEELDOWN then
    ZoomOut;
  if CartToPolar(SmallInt(Floor(AAction.AbsoluteXMouse)), SmallInt(Floor(AAction.AbsoluteYMouse)), LLon, LLat) then
  begin
    inherited MouseClick(AAction);
    if AAction.Details^.Button = XCOM_BUTTON_RIGHT then
      Center(LLon, LLat);
  end;
end;

end.
