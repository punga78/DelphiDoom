{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Doom 3 game library - the interpreter of the       }
{  scenarios of Tools\Verifica\255\harness_game.cpp, on the Delphi classes     }
{                                                                              }
{  The commands and the lines written are the ones of the C++ driver (see      }
{  the header of harness_game.cpp).                                            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.D3Game.Scenario;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DelphiDoom.Scanner.IdDict, DelphiDoom.D3Game.ClassBase, DelphiDoom.D3Game.ClassSystem, DelphiDoom.D3Game.Local,
  DelphiDoom.Tests.D3Game.Rig;

type
  /// <summary>Runs the lines of a scenario on a rig and writes the lines of the golden to the trace of its world</summary>
  TD3GameScenarioRunner = class
  strict private
    FRig: TD3GameRig;
    FObjects: TList<TD3Class>;
    FWords: TArray<AnsiString>;
    procedure Split(const ARest: string);
    procedure FillDict(const ADict: TIdDict; const AFrom: Integer);
    procedure Out(const AText: string);
    procedure ShowObject(const ATag: string; const AObject: TD3Class);
    procedure DumpState;
    procedure RunCommand(const ACommand: string; const ARest: string);
    function Word(const AIndex: Integer): AnsiString;
    function IntWord(const AIndex: Integer): Integer;
    function EntityAt(const AIndex: Integer): TObject;
  public
    constructor Create(const ARig: TD3GameRig);
    destructor Destroy; override;
    procedure Run(const ALines: TStrings);
  end;

implementation

uses
  DelphiDoom.DoomScript.EventDef, DelphiDoom.D3Game.Types, DelphiDoom.D3Game.Entity, DelphiDoom.Tests.D3Game.World;

function SuperName(const AType: TD3TypeInfo): string;
begin
  if Assigned(AType.Super) then
    Result := string(AType.Super.Name)
  else
    Result := '(none)';
end;

function EntityNumberOf(const AEntity: TD3Entity): Integer;
begin
  if Assigned(AEntity) then
    Result := AEntity.EntityNumber
  else
    Result := -1;
end;

constructor TD3GameScenarioRunner.Create(const ARig: TD3GameRig);
begin
  inherited Create;
  FRig := ARig;
  FObjects := TList<TD3Class>.Create;
end;

destructor TD3GameScenarioRunner.Destroy;
begin
  FObjects.Free;
  inherited Destroy;
end;

procedure TD3GameScenarioRunner.Out(const AText: string);
begin
  FRig.World.Line(AText);
end;

procedure TD3GameScenarioRunner.Split(const ARest: string);
var
  LPosition: Integer;
  LNext: Integer;
  LWord: string;
begin
  FWords := nil;
  LPosition := 1;
  while LPosition <= Length(ARest) do
  begin
    LNext := Pos(' ', ARest, LPosition);
    if LNext = 0 then
      LNext := Length(ARest) + 1;
    if LNext > LPosition then
    begin
      LWord := Copy(ARest, LPosition, LNext - LPosition);
      FWords := FWords + [TD3GameEscape.Unescape(LWord)];
    end;
    LPosition := LNext + 1;
  end;
end;

function TD3GameScenarioRunner.Word(const AIndex: Integer): AnsiString;
begin
  if AIndex < Length(FWords) then
    Result := FWords[AIndex]
  else
    Result := '';
end;

function TD3GameScenarioRunner.IntWord(const AIndex: Integer): Integer;
begin
  Result := StrToIntDef(string(Word(AIndex)), 0);
end;

procedure TD3GameScenarioRunner.FillDict(const ADict: TIdDict; const AFrom: Integer);
var
  LIndex: Integer;
begin
  LIndex := AFrom;
  while LIndex + 1 < Length(FWords) do
  begin
    ADict.SetValue(FWords[LIndex], FWords[LIndex + 1]);
    Inc(LIndex, 2);
  end;
end;

function TD3GameScenarioRunner.EntityAt(const AIndex: Integer): TObject;
begin
  Result := FRig.Game.Entities[IntWord(AIndex)];
end;

procedure TD3GameScenarioRunner.ShowObject(const ATag: string; const AObject: TD3Class);
var
  LIndex: Integer;
begin
  if not Assigned(AObject) then
  begin
    Out(ATag + ' null');
    Exit;
  end;
  LIndex := FObjects.IndexOf(AObject);
  if LIndex < 0 then
  begin
    LIndex := FObjects.Count;
    FObjects.Add(AObject);
  end;
  Out(Format('%s obj=%d class=%s', [ATag, LIndex, string(AObject.GetClassname)]));
end;

procedure TD3GameScenarioRunner.DumpState;
var
  LGame: TD3GameLocal;
  LIndex: Integer;
  LEntity: TD3Entity;
  LText: string;
begin
  LGame := FRig.Game;
  Out(Format('STATE num_entities=%d firstFree=%d spawnCount=%d mapSpawnCount=%d toDeactivate=%d time=%d frame=%d ' +
    'inCinematic=%d', [LGame.NumEntities, LGame.FirstFreeIndex, LGame.SpawnCount, LGame.MapSpawnCount,
    LGame.NumEntitiesToDeactivate, LGame.Time, LGame.FrameNum, Ord(LGame.InCinematic)]));
  for LIndex := 0 to D3_MAX_GENTITIES - 1 do
  begin
    LEntity := LGame.Entities[LIndex];
    if not Assigned(LEntity) then
      Continue;
    Out(Format('ENT %d name=%s class=%s def=%s spawnId=%d think=%d active=%d cinematic=%d health=%d number=%d',
      [LIndex, string(LEntity.GetName), string(LEntity.GetClassname), string(LEntity.GetEntityDefName),
      LGame.SpawnIds[LIndex], LEntity.ThinkFlags, Ord(LEntity.IsActive), Ord(LEntity.Cinematic), LEntity.Health,
      LEntity.EntityNumber]));
  end;
  LText := '';
  LEntity := LGame.SpawnedEntities.Next;
  while Assigned(LEntity) do
  begin
    LText := LText + ' ' + IntToStr(LEntity.EntityNumber);
    LEntity := LEntity.SpawnNode.Next;
  end;
  Out('SPAWNLIST ' + TD3GameEscape.Escape(AnsiString(LText)));
  LText := '';
  LEntity := LGame.ActiveEntities.Next;
  while Assigned(LEntity) do
  begin
    LText := LText + ' ' + IntToStr(LEntity.EntityNumber);
    LEntity := LEntity.ActiveNode.Next;
  end;
  Out('ACTIVELIST ' + TD3GameEscape.Escape(AnsiString(LText)));
end;

procedure TD3GameScenarioRunner.RunCommand(const ACommand: string; const ARest: string);
var
  LClasses: TD3ClassSystem;
  LType: TD3TypeInfo;
  LOther: TD3TypeInfo;
  LEvent: TDoomScriptEventDef;
  LObject: TD3Class;
  LEntity: TD3Entity;
  LDict: TIdDict;
  LIndex: Integer;
  LCount: Integer;
  LWorld: TD3GameFakeWorld;
begin
  Split(ARest);
  LClasses := FRig.Classes;
  LWorld := FRig.World;
  // ---- the type system
  if ACommand = 'inittypes' then
    LClasses.Init
  else if ACommand = 'shutdowntypes' then
    LClasses.Shutdown
  else if ACommand = 'numtypes' then
    Out(Format('RET %d', [LClasses.NumTypes]))
  else if ACommand = 'typenumbits' then
    Out(Format('RET %d', [LClasses.TypeNumBits]))
  else if ACommand = 'list' then
    LClasses.ListClasses
  else if ACommand = 'getclass' then
  begin
    LType := LClasses.GetClass(Word(0));
    if Assigned(LType) then
      Out(Format('CLASS %s super=%s typeNum=%d lastChild=%d', [string(LType.Name), string(LType.SuperclassName),
        LType.TypeNum, LType.LastChild]))
    else
      Out('CLASS null');
  end
  else if ACommand = 'gettype' then
  begin
    LType := LClasses.GetType(IntWord(0));
    if Assigned(LType) then
      Out('TYPE ' + string(LType.Name))
    else
      Out('TYPE null');
  end
  else if ACommand = 'super' then
  begin
    LType := LClasses.GetClass(Word(0));
    if not Assigned(LType) then
      Out('CLASS null')
    else if Assigned(LType.Super) then
      Out('SUPER ' + TD3GameEscape.Escape(LType.Super.Name))
    else
      Out('SUPER (none)');
  end
  else if ACommand = 'istype' then
  begin
    LType := LClasses.GetClass(Word(0));
    LOther := LClasses.GetClass(Word(1));
    if Assigned(LType) and Assigned(LOther) then
      Out(Format('RET %d', [Ord(LType.IsType(LOther))]))
    else
      Out('CLASS null');
  end
  else if ACommand = 'responds' then
  begin
    LType := LClasses.GetClass(Word(0));
    LEvent := FRig.Events.FindEvent(Word(1));
    if Assigned(LType) and Assigned(LEvent) then
      Out(Format('RET %d', [Ord(LType.RespondsTo(LEvent))]))
    else
      Out('NOTFOUND');
  end
  else if ACommand = 'evshare' then
  begin
    LType := LClasses.GetClass(Word(0));
    if Assigned(LType) then
      Out(Format('EVSHARE %s shared=%d free=%d hasMap=%d', [string(LType.Name),
        Ord(Assigned(LType.Super) and (LType.EventMap = LType.Super.EventMap)), Ord(LType.FreeEventMap),
        Ord(Assigned(LType.EventMap))]));
  end
  else if ACommand = 'dumptypes' then
  begin
    for LIndex := 0 to LClasses.DeclaredCount - 1 do
    begin
      LType := LClasses.DeclaredClass(LIndex);
      Out(Format('TYPE %s super=%s superPtr=%s typeNum=%d lastChild=%d free=%d map=%d', [string(LType.Name),
        string(LType.SuperclassName), SuperName(LType), LType.TypeNum,
        LType.LastChild, Ord(LType.FreeEventMap), Ord(Assigned(LType.EventMap))]));
    end;
    Out(Format('INIT initialized=%d types=%d typenums=%d bits=%d', [Ord(LClasses.Initialized), LClasses.NumTypes,
      LClasses.NumTypes, LClasses.TypeNumBits]));
  end
  // ---- the events
  else if ACommand = 'events' then
  begin
    Out(Format('EVENTS %d', [FRig.Events.Count]));
    for LIndex := 0 to FRig.Events.Count - 1 do
    begin
      LEvent := FRig.Events.GetEvent(LIndex);
      Out(Format('EVENT %d %s format=%s args=%d', [LEvent.EventNum, string(LEvent.Name), string(LEvent.ArgFormat),
        LEvent.GetNumArgs]));
    end;
  end
  else if ACommand = 'event' then
  begin
    LEvent := FRig.Events.FindEvent(Word(0));
    if Assigned(LEvent) then
      Out(Format('EVENT %d %s', [LEvent.EventNum, string(LEvent.Name)]))
    else
      Out('EVENT null');
  end
  else if ACommand = 'evinit' then
    // idEvent::initialized: nothing to do here
  // ---- objects
  else if ACommand = 'create' then
  begin
    LType := LClasses.GetClass(Word(0));
    if Assigned(LType) then
      ShowObject('OBJ', FRig.Game.CreateObject(LType))
    else
      Out('OBJ null');
  end
  else if ACommand = 'spawnobj' then
  begin
    LType := LClasses.GetClass(Word(0));
    LObject := nil;
    if Assigned(LType) then
      LObject := FRig.Game.CreateObject(LType);
    if Assigned(LObject) then
      LObject.CallSpawn;
    ShowObject('OBJ', LObject);
  end
  else if ACommand = 'callevent' then
  begin
    LObject := nil;
    if Word(0) = 'ent' then
      LObject := TD3Class(EntityAt(1))
    else if (IntWord(1) >= 0) and (IntWord(1) < FObjects.Count) then
      LObject := FObjects[IntWord(1)];
    LEvent := FRig.Events.FindEvent(Word(2));
    if (not Assigned(LObject)) or (not Assigned(LEvent)) then
      Out('NOTFOUND')
    else
    begin
      Out(Format('RESPONDS %d', [Ord(LObject.RespondsTo(LEvent))]));
      if LObject.RespondsTo(LEvent) then
      begin
        LObject.ProcessEvent(LEvent);
        // the immediate remove frees the object: the list must not give it again
        if (Word(0) <> 'ent') and (LEvent = FRig.Classes.EventRemove) then
          FObjects[IntWord(1)] := nil;
      end;
    end;
  end
  else if ACommand = 'destroy' then
  begin
    LIndex := IntWord(0);
    if (LIndex >= 0) and (LIndex < FObjects.Count) and Assigned(FObjects[LIndex]) then
    begin
      FObjects[LIndex].Free;
      FObjects[LIndex] := nil;
      Out(Format('DESTROYED %d', [LIndex]));
    end
    else
      Out('NOTFOUND');
  end
  // ---- the game
  else if ACommand = 'cvar' then
  begin
    if Word(0) = 'skill' then
      LWorld.Skill := IntWord(1)
    else
      LWorld.Multiplayer := IntWord(1) <> 0;
  end
  else if ACommand = 'def' then
    LWorld.AddDef(Word(0), Copy(FWords, 1, Length(FWords) - 1))
  else if ACommand = 'func' then
    LWorld.AddFunction(Word(0))
  else if ACommand = 'newmap' then
    FRig.Game.NewMap
  else if ACommand = 'spawndef' then
  begin
    LDict := TIdDict.Create;
    try
      FillDict(LDict, 0);
      LEntity := nil;
      if FRig.Game.SpawnEntityDef(LDict, LEntity) then
        LCount := 1
      else
        LCount := 0;
      Out(Format('RET %d ent=%d', [LCount, EntityNumberOf(LEntity)]));
    finally
      LDict.Free;
    end;
  end
  else if ACommand = 'spawntype' then
  begin
    LType := LClasses.GetClass(Word(0));
    if not Assigned(LType) then
      Out('CLASS null')
    else
    begin
      LDict := TIdDict.Create;
      try
        FillDict(LDict, 1);
        LEntity := FRig.Game.SpawnEntityType(LType, LDict);
        Out(Format('RET ent=%d', [EntityNumberOf(LEntity)]));
      finally
        LDict.Free;
      end;
    end;
  end
  else if ACommand = 'fill' then
  begin
    LType := LClasses.GetClass(Word(0));
    if not Assigned(LType) then
      Out('CLASS null')
    else
    begin
      LCount := IntWord(1);
      LIndex := 0;
      FRig.World.Quiet := True;
      try
        try
          while LIndex < LCount do
          begin
            LDict := TIdDict.Create;
            try
              LDict.SetValue('name', AnsiString('fill' + IntToStr(LIndex)));
              FRig.Game.SpawnEntityType(LType, LDict);
            finally
              LDict.Free;
            end;
            Inc(LIndex);
          end;
        finally
          FRig.World.Quiet := False;
        end;
      except
        Out(Format('FILLED %d', [LIndex]));
        raise;
      end;
      Out(Format('FILLED %d', [LIndex]));
    end;
  end
  else if ACommand = 'remove' then
  begin
    if FRig.Game.RemoveEntity(IntWord(0)) then
      Out('REMOVED ' + string(Word(0)))
    else
      Out('NOTFOUND');
  end
  else if ACommand = 'find' then
    Out(Format('FOUND %d', [EntityNumberOf(FRig.Game.FindEntity(Word(0)))]))
  else if ACommand = 'finddef' then
  begin
    if IntWord(0) < 0 then
      LEntity := nil
    else
      LEntity := TD3Entity(EntityAt(0));
    Out(Format('FOUND %d', [EntityNumberOf(FRig.Game.FindEntityUsingDef(LEntity, Word(1)))]));
  end
  else if ACommand = 'setname' then
  begin
    LEntity := TD3Entity(EntityAt(0));
    if Assigned(LEntity) then
      LEntity.SetName(Word(1))
    else
      Out('NOTFOUND');
  end
  else if ACommand = 'active' then
  begin
    LEntity := TD3Entity(EntityAt(0));
    if Assigned(LEntity) then
      LEntity.BecomeActive(IntWord(1))
    else
      Out('NOTFOUND');
  end
  else if ACommand = 'inactive' then
  begin
    LEntity := TD3Entity(EntityAt(0));
    if Assigned(LEntity) then
      LEntity.BecomeInactive(IntWord(1))
    else
      Out('NOTFOUND');
  end
  else if ACommand = 'isactive' then
  begin
    LEntity := TD3Entity(EntityAt(0));
    Out(Format('RET %d', [Ord(Assigned(LEntity) and LEntity.IsActive)]));
  end
  else if ACommand = 'mapclear' then
  begin
    LWorld.ClearMapFile;
    FRig.Game.MapSource := nil;
  end
  else if ACommand = 'mapnew' then
  begin
    LWorld.NewMapFile;
    FRig.Game.MapSource := LWorld;
  end
  else if ACommand = 'mapent' then
    LWorld.AddMapEntity(FWords)
  else if ACommand = 'spawnmap' then
    FRig.Game.SpawnMapEntities
  else if ACommand = 'populate' then
    FRig.Game.MapPopulate
  else if ACommand = 'inhibit' then
  begin
    LDict := TIdDict.Create;
    try
      FillDict(LDict, 0);
      Out(Format('RET %d', [Ord(FRig.Game.InhibitEntitySpawn(LDict))]));
    finally
      LDict.Free;
    end;
  end
  else if ACommand = 'msec' then
    FRig.Game.Msec := IntWord(0)
  else if ACommand = 'cinematic' then
    FRig.Game.InCinematic := IntWord(0) <> 0
  else if ACommand = 'frame' then
    FRig.Game.RunFrameThink
  else if ACommand = 'state' then
    DumpState
  else
    Out('UNKNOWN ' + ACommand);
end;

procedure TD3GameScenarioRunner.Run(const ALines: TStrings);
var
  LIndex: Integer;
  LLine: string;
  LSpace: Integer;
begin
  for LIndex := 0 to ALines.Count - 1 do
  begin
    LLine := ALines[LIndex];
    if (LLine = '') or (LLine[1] = '#') then
      Continue;
    Out('CMD ' + TD3GameEscape.Escape(AnsiString(LLine)));
    LSpace := Pos(' ', LLine);
    try
      if LSpace = 0 then
        RunCommand(LLine, '')
      else
        RunCommand(Copy(LLine, 1, LSpace - 1), Copy(LLine, LSpace + 1, MaxInt));
    except
      on E: ED3GameException do
        Out('THROW ' + TD3GameEscape.Escape(AnsiString(E.Message)));
    end;
  end;
end;

end.
