{******************************************************************************}
{                                                                              }
{  DelphiDoom: info tables library - monsters placed at random                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Info.RandomMonsters;

interface

uses
  System.Generics.Collections,
  DelphiDoom.Info.Intf;

type
  /// <summary>
  ///   The monsters sorted in five classes by their health, from which a monster of the same
  ///   class is chosen at random (the old info_rnd)
  /// </summary>
  TInfoRandomMonsters = class sealed
  strict private
    const
      ClassCount = 5;
    var
      FMobjs: IInfoMobjSource;
      FRules: IInfoRandomRules;
      FRandom: IInfoRandom;
      FLimits: array[0..ClassCount - 1] of Integer;
      FPools: array[0..ClassCount - 1] of TList<Integer>;
      FReady: Boolean;
    function ClassOf(const AHealth: Integer): Integer;
  public
    constructor Create(const AMobjs: IInfoMobjSource; const ARules: IInfoRandomRules;
      const ARandom: IInfoRandom);
    destructor Destroy; override;
    /// <summary>
    ///   Sorts the monsters of the table; the thresholds are asked now, at the first call
    ///   (they depend on the version of the game being played). A second call does nothing
    /// </summary>
    procedure Initialize;
    /// <summary>Forgets the classes, so that Initialize makes them again</summary>
    procedure Shutdown;
    /// <summary>
    ///   A monster of the class of AType, chosen at random: the rules say how many random numbers
    ///   to throw away first, then one number chooses. Needs Initialize
    /// </summary>
    function Select(const AType: Integer): Integer;
    /// <summary>True if the thing is a monster (the rules of the game)</summary>
    function IsMonster(const AType: Integer): Boolean;
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.Info.Types;

{ TInfoRandomMonsters }

constructor TInfoRandomMonsters.Create(const AMobjs: IInfoMobjSource; const ARules: IInfoRandomRules;
  const ARandom: IInfoRandom);
begin
  inherited Create;
  if not Assigned(AMobjs) then
    raise EArgumentNilException.Create('AMobjs');
  if not Assigned(ARules) then
    raise EArgumentNilException.Create('ARules');
  if not Assigned(ARandom) then
    raise EArgumentNilException.Create('ARandom');
  FMobjs := AMobjs;
  FRules := ARules;
  FRandom := ARandom;
end;

destructor TInfoRandomMonsters.Destroy;
begin
  Shutdown;
  inherited Destroy;
end;

function TInfoRandomMonsters.ClassOf(const AHealth: Integer): Integer;
begin
  Result := 0;
  while (Result < ClassCount) and (AHealth >= FLimits[Result]) do
    Inc(Result);
end;

procedure TInfoRandomMonsters.Initialize;
var
  LThresholds: TArray<Integer>;
  LIndex: Integer;
  LMobj: TInfoMobj;
begin
  if FReady then
    Exit;
  LThresholds := FRules.Thresholds;
  if Length(LThresholds) <> ClassCount - 1 then
    raise EInfoException.Create('The rules of the random monsters must give four thresholds');
  for LIndex := 0 to ClassCount - 2 do
    FLimits[LIndex] := LThresholds[LIndex];
  FLimits[ClassCount - 1] := MaxInt;

  for LIndex := 0 to ClassCount - 1 do
    FPools[LIndex] := TList<Integer>.Create;
  FReady := True;

  for LIndex := 0 to FMobjs.Count - 1 do
  begin
    LMobj := FMobjs.Get(LIndex);
    if FRules.IsMonster(LMobj) and FRules.IsValidThing(LMobj.DoomedNum) then
      FPools[ClassOf(LMobj.SpawnHealth)].Add(LIndex);
  end;
end;

procedure TInfoRandomMonsters.Shutdown;
var
  LIndex: Integer;
begin
  if not FReady then
    Exit;
  for LIndex := 0 to ClassCount - 1 do
    FreeAndNil(FPools[LIndex]);
  FReady := False;
end;

function TInfoRandomMonsters.Select(const AType: Integer): Integer;
var
  LPool: Integer;
  LIndex: Integer;
begin
  if not FReady then
    raise EInfoException.Create('The random monsters were not initialized');
  LPool := ClassOf(FMobjs.Get(AType).SpawnHealth);
  for LIndex := 1 to FRules.DiscardCount do
    FRandom.Next;
  if FPools[LPool].Count = 0 then
    raise EInfoException.Create('There is no monster in the class of the thing');
  Result := FPools[LPool][FRandom.Next mod FPools[LPool].Count];
end;

function TInfoRandomMonsters.IsMonster(const AType: Integer): Boolean;
begin
  Result := FRules.IsMonster(FMobjs.Get(AType));
end;

end.
