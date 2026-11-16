{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - the actors and the special places of a level      }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later:        }
{  HandleInfo, ScanInfoPlane and PatchWorldMap of kd_play.c                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.LevelScanner;

interface

uses
  System.SysUtils, DelphiDoom.Keen.Types, DelphiDoom.Keen.GameTypes, DelphiDoom.Keen.Intf;

const
  /// <summary>The groups of graphics that the level needs (lumpneeded[] of kd_play.c): which actors are on the map</summary>
  KEEN_LUMP_CONTROLS = 0;
  KEEN_LUMP_KEEN = 1;
  KEEN_LUMP_WORLDKEEN = 2;
  KEEN_LUMP_BROCCO = 3;
  KEEN_LUMP_TOMAT = 4;
  KEEN_LUMP_CARROT = 5;
  KEEN_LUMP_ASPAR = 6;
  KEEN_LUMP_GRAPE = 7;
  KEEN_LUMP_TATER = 8;
  KEEN_LUMP_CART = 9;
  KEEN_LUMP_FRENCHY = 10;
  KEEN_LUMP_MELON = 11;
  KEEN_LUMP_SQUASH = 12;
  KEEN_LUMP_APEL = 13;
  KEEN_LUMP_PEA = 14;
  KEEN_LUMP_BOOBUS = 15;
  KEEN_NUMLUMPS = 22;

type
  /// <summary>
  ///   Goes through the info plane of a map (a word for each tile: 0 is nothing) and makes the actor that each
  ///   number is, with the functions of the spawner. All the actors start asleep, except the ones that say
  ///   they never sleep. It also says which groups of graphics the actors of the level need
  /// </summary>
  TKeenLevelScanner = class
  strict private
    FObjects: IKeenObjectList;
    FSpawner: IKeenActorSpawner;
    FLumpNeeded: array[0..KEEN_NUMLUMPS - 1] of Boolean;
    FBombsPresent: Boolean;
    procedure HandleInfo(ATile, AX, AY: Integer);
    procedure Need(ALump: Integer);
  public
    constructor Create(const AObjects: IKeenObjectList; const ASpawner: IKeenActorSpawner);
    /// <summary>ScanInfoPlane: starts a new list of actors and spawns the ones of the info plane</summary>
    procedure ScanInfoPlane(const AMap: IKeenWorkingMap);
    /// <summary>
    ///   PatchWorldMap: the world map takes out the places that block the way and plants a flag where a city
    ///   is done. A place that is on the row 0 or at the left has no flag drawn above it (the C reads outside
    ///   the map there)
    /// </summary>
    procedure PatchWorldMap(const AMap: IKeenWorkingMap; const AGameState: TKeenGameState);
    function LumpNeeded(ALump: Integer): Boolean;
    /// <summary>True if there is a bonus of the bombs of Boobus on the map ("Boobus Bombs Near!")</summary>
    property BombsPresent: Boolean read FBombsPresent;
  end;

implementation

{ TKeenLevelScanner }

constructor TKeenLevelScanner.Create(const AObjects: IKeenObjectList; const ASpawner: IKeenActorSpawner);
begin
  inherited Create;
  if not Assigned(AObjects) then
    raise EArgumentNilException.Create('AObjects');
  if not Assigned(ASpawner) then
    raise EArgumentNilException.Create('ASpawner');
  FObjects := AObjects;
  FSpawner := ASpawner;
end;

procedure TKeenLevelScanner.Need(ALump: Integer);
begin
  FLumpNeeded[ALump] := True;
end;

function TKeenLevelScanner.LumpNeeded(ALump: Integer): Boolean;
begin
  Result := (ALump >= 0) and (ALump < KEEN_NUMLUMPS) and FLumpNeeded[ALump];
end;

procedure TKeenLevelScanner.HandleInfo(ATile, AX, AY: Integer);
begin
  case ATile of
    1:
      FSpawner.SpawnKeen(AX, AY, 1);
    2:
      FSpawner.SpawnKeen(AX, AY, -1);
    19:
      begin
        FSpawner.SpawnWorldKeen(AX, AY);
        Need(KEEN_LUMP_WORLDKEEN);
      end;
    21..32:
      // the bonuses: the type is the number minus 21, and the 31 is the bomb of Boobus
      begin
        if ATile = 31 then
          FBombsPresent := True;
        FSpawner.SpawnBonus(AX, AY, ATile - 21);
        FObjects.New^.Active := kaNo;
      end;
    33:
      begin
        FSpawner.SpawnDoor(AX, AY);
        FObjects.New^.Active := kaNo;
      end;
    41:
      begin
        FSpawner.SpawnBrocco(AX, AY);
        FObjects.New^.Active := kaNo;
        Need(KEEN_LUMP_BROCCO);
      end;
    42:
      begin
        FSpawner.SpawnTomat(AX, AY);
        FObjects.New^.Active := kaNo;
        Need(KEEN_LUMP_TOMAT);
      end;
    43:
      begin
        FSpawner.SpawnCarrot(AX, AY);
        FObjects.New^.Active := kaNo;
        Need(KEEN_LUMP_CARROT);
      end;
    45:
      begin
        FSpawner.SpawnAspar(AX, AY);
        FObjects.New^.Active := kaNo;
        Need(KEEN_LUMP_ASPAR);
      end;
    46:
      begin
        FSpawner.SpawnGrape(AX, AY);
        FObjects.New^.Active := kaNo;
        Need(KEEN_LUMP_GRAPE);
      end;
    47:
      begin
        FSpawner.SpawnTater(AX, AY);
        FObjects.New^.Active := kaNo;
        Need(KEEN_LUMP_TATER);
      end;
    48:
      begin
        FSpawner.SpawnCart(AX, AY);
        Need(KEEN_LUMP_CART);
      end;
    49:
      begin
        FSpawner.SpawnFrenchy(AX, AY);
        FObjects.New^.Active := kaNo;
        Need(KEEN_LUMP_FRENCHY);
      end;
    50..52:
      begin
        FSpawner.SpawnMelon(AX, AY, ATile - 50);
        FObjects.New^.Active := kaNo;
        Need(KEEN_LUMP_MELON);
      end;
    57:
      begin
        FSpawner.SpawnSquasher(AX, AY);
        FObjects.New^.Active := kaNo;
        Need(KEEN_LUMP_SQUASH);
      end;
    58:
      begin
        FSpawner.SpawnApel(AX, AY);
        FObjects.New^.Active := kaNo;
        Need(KEEN_LUMP_APEL);
      end;
    59:
      begin
        FSpawner.SpawnPeaPod(AX, AY);
        FObjects.New^.Active := kaNo;
        Need(KEEN_LUMP_PEA);
      end;
    60:
      begin
        FSpawner.SpawnPeaBrain(AX, AY);
        FObjects.New^.Active := kaNo;
        Need(KEEN_LUMP_PEA);
      end;
    61:
      begin
        FSpawner.SpawnBoobus(AX, AY);
        Need(KEEN_LUMP_BOOBUS);
      end;
  end;
  // every actor starts asleep unless it says that it never sleeps. The C does this for any number of the
  // plane, also for a number that spawns nothing: then it is the last actor made that goes to sleep
  if FObjects.New^.Active <> kaAllways then
    FObjects.New^.Active := kaNo;
end;

procedure TKeenLevelScanner.ScanInfoPlane(const AMap: IKeenWorkingMap);
var
  LY: Integer;
  LX: Integer;
  LTile: Integer;
  LPlane: TArray<Word>;
begin
  if not Assigned(AMap) then
    raise EArgumentNilException.Create('AMap');
  // start spawning things with a clean slate
  FObjects.Init;
  FillChar(FLumpNeeded, SizeOf(FLumpNeeded), 0);
  FBombsPresent := False;
  LPlane := AMap.Planes[2];
  for LY := 0 to AMap.Height - 1 do
    for LX := 0 to AMap.Width - 1 do
    begin
      LTile := LPlane[LY * AMap.Width + LX];
      if LTile <> 0 then
        HandleInfo(LTile, LX, LY);
    end;
end;

procedure TKeenLevelScanner.PatchWorldMap(const AMap: IKeenWorkingMap; const AGameState: TKeenGameState);
var
  LSize: Integer;
  LSpot: Integer;
  LInfo: Integer;
  LForeground: Integer;
  LWidth: Integer;
  LInfoPlane: TArray<Word>;
  LFront: TArray<Word>;
begin
  if not Assigned(AMap) then
    raise EArgumentNilException.Create('AMap');
  LWidth := AMap.Width;
  LSize := LWidth * AMap.Height;
  LInfoPlane := AMap.Planes[2];
  LFront := AMap.Planes[1];
  for LSpot := 0 to LSize - 1 do
  begin
    LInfo := LInfoPlane[LSpot];
    // finished a city here?
    if (LInfo >= 3) and (LInfo <= 18) and AGameState.LevelDone[LInfo - 2] then
    begin
      LInfoPlane[LSpot] := 0;
      LForeground := LFront[LSpot];
      if LForeground = 130 then
        LFront[LSpot] := 0 // not blocking now
      else if LForeground = 90 then
      begin
        // plant the done flag
        LFront[LSpot] := 133;
        if LSpot - LWidth - 1 >= 0 then
        begin
          LFront[LSpot - LWidth - 1] := 131;
          LFront[LSpot - LWidth] := 132;
        end;
      end;
    end;
  end;
end;

end.
