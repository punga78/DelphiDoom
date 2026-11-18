{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Doom 3 game library - the scenario runner of the   }
{  world harness (triggers, movers, doors): the commands and the lines of      }
{  Tools\Verifica\255\harness_world.cpp, run on the Delphi classes             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.D3Game.WorldScenario;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.DoomScript.EventDef, DelphiDoom.D3Game.Entity,
  DelphiDoom.Tests.D3Game.WorldRig;

type
  /// <summary>
  ///   Runs the commands of a scenario of the world harness (see the header of <c>harness_world.cpp</c>) on a game with
  ///   fakes and writes the same lines to the trace of the fake world
  /// </summary>
  TD3WorldScenarioRunner = class
  strict private
    FRig: TD3WorldRig;
    FWords: TArray<string>;
    procedure Line(const AText: string);
    procedure Split(const ARest: string);
    function Bits(const AValue: Single): string;
    function VectorText(const AX, AY, AZ: Single): string;
    function EntityAt(const AText: string): TD3Entity;
    function Word(const AIndex: Integer): string;
    procedure DumpEntity(const AEntity: TD3Entity);
    procedure DumpQueue;
    procedure DumpFrame;
    procedure CallEvent(const AEntity: TD3Entity; const AEvent: TDoomScriptEventDef; const AFrom, ATime: Integer;
      const APost: Boolean);
    procedure RunCommand(const ACommand, ARest: string);
  public
    constructor Create(const ARig: TD3WorldRig);
    procedure Run(const ALines: TStrings);
  end;

implementation

uses
  DelphiDoom.IdLib.Math.Vec3, DelphiDoom.DoomScript.Types, DelphiDoom.Scanner.IdDict, DelphiDoom.D3Game.Types,
  DelphiDoom.D3Game.Trigger.Multi, DelphiDoom.D3Game.Trigger.Timer, DelphiDoom.D3Game.Trigger.Count,
  DelphiDoom.D3Game.Trigger.Hurt, DelphiDoom.D3Game.MoverBinary, DelphiDoom.D3Game.Mover,
  DelphiDoom.Tests.D3Game.World;

constructor TD3WorldScenarioRunner.Create(const ARig: TD3WorldRig);
begin
  inherited Create;
  FRig := ARig;
end;

procedure TD3WorldScenarioRunner.Line(const AText: string);
begin
  FRig.World.Line(AText);
end;

function TD3WorldScenarioRunner.Bits(const AValue: Single): string;
var
  LValue: Single;
begin
  LValue := AValue;
  Result := IntToHex(PCardinal(@LValue)^, 8);
end;

function TD3WorldScenarioRunner.VectorText(const AX, AY, AZ: Single): string;
begin
  Result := Bits(AX) + ' ' + Bits(AY) + ' ' + Bits(AZ);
end;

function TD3WorldScenarioRunner.Word(const AIndex: Integer): string;
begin
  if (AIndex >= 0) and (AIndex < Length(FWords)) then
    Result := FWords[AIndex]
  else
    Result := '0';
end;

function TD3WorldScenarioRunner.EntityAt(const AText: string): TD3Entity;
begin
  Result := FRig.Game.Entities[StrToIntDef(AText, -1)];
end;

procedure TD3WorldScenarioRunner.Split(const ARest: string);
var
  LStart: Integer;
  LEnd: Integer;
  LWord: string;
begin
  FWords := nil;
  LStart := 1;
  while LStart <= Length(ARest) do
  begin
    LEnd := Pos(' ', ARest, LStart);
    if LEnd = 0 then
      LEnd := Length(ARest) + 1;
    if LEnd > LStart then
    begin
      LWord := string(TD3GameEscape.Unescape(Copy(ARest, LStart, LEnd - LStart)));
      FWords := FWords + [LWord];
    end;
    LStart := LEnd + 1;
  end;
end;

procedure TD3WorldScenarioRunner.DumpEntity(const AEntity: TD3Entity);
var
  LOrigin: TIdVec3;
  LBinary: TD3MoverBinary;
  LMover: TD3Mover;
  LMultiple: TD3TriggerMulti;
  LTimer: TD3TriggerTimer;
  LCount: TD3TriggerCount;
  LHurt: TD3TriggerHurt;
  LMasterNumber: Integer;
  LChainNumber: Integer;
begin
  LOrigin := AEntity.GetPhysics.GetOrigin;
  Line(Format('ENT %d name=%s class=%s think=%d active=%d hidden=%d origin=%s targets=%d',
    [AEntity.EntityNumber, string(AEntity.GetName), string(AEntity.GetClassname), AEntity.ThinkFlags,
    Ord(AEntity.IsActive), Ord(AEntity.IsHidden), VectorText(LOrigin.X, LOrigin.Y, LOrigin.Z), AEntity.NumTargets]));
  if AEntity is TD3TriggerMulti then
  begin
    LMultiple := TD3TriggerMulti(AEntity);
    Line(Format('MULTI wait=%s random=%s delay=%s random_delay=%s next=%d triggerFirst=%d',
      [Bits(LMultiple.Wait), Bits(LMultiple.Random), Bits(LMultiple.Delay), Bits(LMultiple.RandomDelay),
      LMultiple.NextTriggerTime, Ord(LMultiple.TriggerFirst)]));
  end;
  if AEntity is TD3TriggerTimer then
  begin
    LTimer := TD3TriggerTimer(AEntity);
    Line(Format('TIMER on=%d random=%s wait=%s delay=%s', [Ord(LTimer.IsOn), Bits(LTimer.Random), Bits(LTimer.Wait),
      Bits(LTimer.Delay)]));
  end;
  if AEntity is TD3TriggerCount then
  begin
    LCount := TD3TriggerCount(AEntity);
    Line(Format('COUNT goal=%d count=%d delay=%s', [LCount.Goal, LCount.Count, Bits(LCount.Delay)]));
  end;
  if AEntity is TD3TriggerHurt then
  begin
    LHurt := TD3TriggerHurt(AEntity);
    Line(Format('HURT on=%d delay=%s nextTime=%d', [Ord(LHurt.IsOn), Bits(LHurt.Delay), LHurt.NextTime]));
  end;
  if AEntity is TD3MoverBinary then
  begin
    LBinary := TD3MoverBinary(AEntity);
    LMasterNumber := -1;
    if Assigned(LBinary.MoveMaster) then
      LMasterNumber := LBinary.MoveMaster.EntityNumber;
    LChainNumber := -1;
    if Assigned(LBinary.ActivateChain) then
      LChainNumber := LBinary.ActivateChain.EntityNumber;
    Line(Format('BINARY state=%d pos1=%s pos2=%s duration=%d accel=%d decel=%d enabled=%d wait=%s start=%d blocked=%d ' +
      'master=%d chain=%d', [Ord(LBinary.MoverState), VectorText(LBinary.Pos1.X, LBinary.Pos1.Y, LBinary.Pos1.Z),
      VectorText(LBinary.Pos2.X, LBinary.Pos2.Y, LBinary.Pos2.Z), LBinary.Duration, LBinary.AccelTime,
      LBinary.DecelTime, Ord(LBinary.Enabled), Bits(LBinary.Wait), LBinary.StateStartTime, Ord(LBinary.IsBlocked),
      LMasterNumber, LChainNumber]));
  end;
  if AEntity is TD3Mover then
  begin
    LMover := TD3Mover(AEntity);
    Line(Format('MOVE stage=%d accel=%d movetime=%d decel=%d dir=%s dest=%s speed=%s time=%d acceltime=%d ' +
      'deceltime=%d last=%d thread=%d', [Ord(LMover.Move.Stage), LMover.Move.Acceleration, LMover.Move.MoveTime,
      LMover.Move.Deceleration, VectorText(LMover.Move.Dir.X, LMover.Move.Dir.Y, LMover.Move.Dir.Z),
      VectorText(LMover.DestPosition.X, LMover.DestPosition.Y, LMover.DestPosition.Z), Bits(LMover.MoveSpeed),
      LMover.MoveTime, LMover.AccelTime, LMover.DecelTime, Ord(LMover.LastCommand), LMover.MoveThread]));
  end;
end;

procedure TD3WorldScenarioRunner.DumpQueue;
var
  LPending: string;
begin
  LPending := FRig.Queue.Pending;
  if LPending <> '' then
    LPending := ' ' + LPending.Replace(' ', ' ');
  Line('QUEUE ' + TD3GameEscape.Escape(AnsiString(LPending)));
end;

procedure TD3WorldScenarioRunner.DumpFrame;
var
  LText: string;
  LEntity: TD3Entity;
  LOrigin: TIdVec3;
begin
  LText := '';
  LEntity := FRig.Game.SpawnedEntities.Next;
  while Assigned(LEntity) do
  begin
    LOrigin := LEntity.GetPhysics.GetOrigin;
    if LEntity is TD3MoverBinary then
      LText := LText + Format(' %d:%d:%s', [LEntity.EntityNumber, Ord(TD3MoverBinary(LEntity).MoverState),
        VectorText(LOrigin.X, LOrigin.Y, LOrigin.Z)])
    else if LEntity is TD3Mover then
      LText := LText + Format(' %d:m:%s', [LEntity.EntityNumber, VectorText(LOrigin.X, LOrigin.Y, LOrigin.Z)]);
    LEntity := LEntity.SpawnNode.Next;
  end;
  Line(Format('FRAME t=%d toDeactivate=%d%s', [FRig.Game.Time, FRig.Game.NumEntitiesToDeactivate, LText]));
end;

procedure TD3WorldScenarioRunner.CallEvent(const AEntity: TD3Entity; const AEvent: TDoomScriptEventDef;
  const AFrom, ATime: Integer; const APost: Boolean);
var
  LArgs: TDoomScriptEventArgs;
  LIndex: Integer;
  LWord: string;
  LNumber: Integer;
  LX, LY, LZ: Single;
  LParts: TArray<string>;
  LResult: Boolean;
  LFormatSettings: TFormatSettings;
  LPosted: TArray<TDoomScriptEventArg>;
begin
  LFormatSettings := TFormatSettings.Invariant;
  LArgs := Default(TDoomScriptEventArgs);
  for LIndex := 0 to AEvent.GetNumArgs - 1 do
  begin
    LWord := Word(AFrom + LIndex);
    case AEvent.ArgFormat[LIndex + 1] of
      DS_EVENT_ENTITY:
        begin
          LNumber := StrToIntDef(LWord, 0);
          if LNumber >= 0 then
            LArgs[LIndex] := TD3Entity.EntityArg(FRig.Game.Entities[LNumber])
          else
            LArgs[LIndex] := TD3Entity.EntityArg(nil);
        end;
      DS_EVENT_INTEGER:
        begin
          LArgs[LIndex].Kind := DS_EVENT_INTEGER;
          LArgs[LIndex].IntValue := StrToIntDef(LWord, 0);
        end;
      DS_EVENT_FLOAT:
        begin
          LArgs[LIndex].Kind := DS_EVENT_FLOAT;
          LArgs[LIndex].FloatValue := StrToFloatDef(LWord, 0, LFormatSettings);
        end;
      DS_EVENT_VECTOR:
        begin
          LParts := LWord.Split([',']);
          LX := 0;
          LY := 0;
          LZ := 0;
          if Length(LParts) > 0 then
            LX := StrToFloatDef(LParts[0], 0, LFormatSettings);
          if Length(LParts) > 1 then
            LY := StrToFloatDef(LParts[1], 0, LFormatSettings);
          if Length(LParts) > 2 then
            LZ := StrToFloatDef(LParts[2], 0, LFormatSettings);
          LArgs[LIndex].Kind := DS_EVENT_VECTOR;
          LArgs[LIndex].VectorValue := TIdVec3.Create(LX, LY, LZ);
        end;
      DS_EVENT_STRING:
        begin
          LArgs[LIndex].Kind := DS_EVENT_STRING;
          LArgs[LIndex].StringValue := AnsiString(LWord);
        end;
    end;
  end;
  if APost then
  begin
    LResult := AEntity.RespondsTo(AEvent);
    SetLength(LPosted, AEvent.GetNumArgs);
    for LIndex := 0 to High(LPosted) do
      LPosted[LIndex] := LArgs[LIndex];
    AEntity.PostEventMS(AEvent, ATime, LPosted);
  end
  else
    LResult := AEntity.ProcessEvent(AEvent, LArgs);
  if APost then
    Line('POSTED ' + IntToStr(Ord(LResult)))
  else
    Line('PROCESSED ' + IntToStr(Ord(LResult)));
end;

procedure TD3WorldScenarioRunner.RunCommand(const ACommand, ARest: string);
var
  LArgs: TIdDict;
  LEntity: TD3Entity;
  LOther: TD3Entity;
  LEvent: TDoomScriptEventDef;
  LIndex: Integer;
  LCount: Integer;
  LKeys: TArray<AnsiString>;
  LTouch: TDoomScriptEventArgs;
  LResult: Boolean;
begin
  Split(ARest);
  if ACommand = 'def' then
  begin
    LKeys := nil;
    for LIndex := 1 to High(FWords) do
      LKeys := LKeys + [AnsiString(FWords[LIndex])];
    FRig.World.AddDef(AnsiString(FWords[0]), LKeys);
  end
  else if ACommand = 'func' then
    FRig.World.AddFunction(AnsiString(FWords[0]))
  else if ACommand = 'spawn' then
  begin
    LArgs := TIdDict.Create;
    try
      LIndex := 0;
      while LIndex + 1 < Length(FWords) do
      begin
        LArgs.SetValue(AnsiString(FWords[LIndex]), AnsiString(FWords[LIndex + 1]));
        Inc(LIndex, 2);
      end;
      LEntity := nil;
      LResult := FRig.Game.SpawnEntityDef(LArgs, LEntity);
    finally
      LArgs.Free;
    end;
    if Assigned(LEntity) then
      Line(Format('RET %d ent=%d', [Ord(LResult), LEntity.EntityNumber]))
    else
      Line(Format('RET %d ent=-1', [Ord(LResult)]));
  end
  else if ACommand = 'frame' then
  begin
    LCount := 1;
    if Length(FWords) > 0 then
      LCount := StrToIntDef(FWords[0], 1);
    for LIndex := 1 to LCount do
    begin
      FRig.Frame;
      DumpFrame;
    end;
  end
  else if (ACommand = 'event') or (ACommand = 'post') then
  begin
    LEntity := EntityAt(Word(0));
    if ACommand = 'post' then
      LEvent := FRig.Events.FindEvent(AnsiString(Word(2)))
    else
      LEvent := FRig.Events.FindEvent(AnsiString(Word(1)));
    if (not Assigned(LEntity)) or (not Assigned(LEvent)) then
      Line('NOTFOUND')
    else if ACommand = 'post' then
      CallEvent(LEntity, LEvent, 3, StrToIntDef(Word(1), 0), True)
    else
      CallEvent(LEntity, LEvent, 2, 0, False);
  end
  else if ACommand = 'touch' then
  begin
    LEntity := EntityAt(Word(0));
    LOther := EntityAt(Word(1));
    if (not Assigned(LEntity)) or (not Assigned(LOther)) then
      Line('NOTFOUND')
    else
    begin
      LTouch := Default(TDoomScriptEventArgs);
      LTouch[0] := TD3Entity.EntityArg(LOther);
      LResult := LEntity.ProcessEvent(FRig.EntityEvents.Touch, LTouch);
      Line('PROCESSED ' + IntToStr(Ord(LResult)));
    end;
  end
  else if ACommand = 'thread' then
    FRig.Threads.Current := StrToIntDef(Word(0), 0)
  else if ACommand = 'dump' then
  begin
    LEntity := EntityAt(Word(0));
    if Assigned(LEntity) then
      DumpEntity(LEntity)
    else
      Line('NOTFOUND');
  end
  else if ACommand = 'queue' then
    DumpQueue
  else if ACommand = 'startup' then
  begin
    if StrToIntDef(Word(0), 0) <> 0 then
      FRig.Game.BeginStartup
    else
      FRig.Game.EndStartup;
  end
  else if ACommand = 'remove' then
  begin
    if FRig.Game.RemoveEntity(StrToIntDef(Word(0), -1)) then
      Line('REMOVED ' + Word(0))
    else
      Line('NOTFOUND');
  end
  else if ACommand = 'find' then
  begin
    LEntity := nil;
    if Length(FWords) > 0 then
      LEntity := FRig.Game.FindEntity(AnsiString(FWords[0]))
    else
      LEntity := FRig.Game.FindEntity('');
    if Assigned(LEntity) then
      Line('FOUND ' + IntToStr(LEntity.EntityNumber))
    else
      Line('FOUND -1');
  end
  else
    Line('UNKNOWN ' + ACommand);
end;

procedure TD3WorldScenarioRunner.Run(const ALines: TStrings);
var
  LLine: string;
  LSpace: Integer;
  LCommand: string;
  LRest: string;
  LIndex: Integer;
begin
  for LIndex := 0 to ALines.Count - 1 do
  begin
    LLine := ALines[LIndex];
    if (LLine = '') or (LLine[1] = '#') then
      Continue;
    Line('CMD ' + TD3GameEscape.Escape(AnsiString(LLine)));
    LSpace := Pos(' ', LLine);
    if LSpace = 0 then
    begin
      LCommand := LLine;
      LRest := '';
    end
    else
    begin
      LCommand := Copy(LLine, 1, LSpace - 1);
      LRest := Copy(LLine, LSpace + 1, MaxInt);
    end;
    try
      RunCommand(LCommand, LRest);
    except
      on E: ED3GameException do
        Line('THROW ' + TD3GameEscape.Escape(AnsiString(E.Message)));
    end;
  end;
end;

end.
