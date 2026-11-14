{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the Doom script library - fake entity of the      }
{  parity driver                                                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.DoomScript.Parity.Entity;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.IdLib.Math.Vec3, DelphiDoom.Scanner.IdDict,
  DelphiDoom.DoomScript.Types, DelphiDoom.DoomScript.Defs, DelphiDoom.DoomScript.ClassInfo,
  DelphiDoom.DoomScript.EventTarget;

type
  /// <summary>A function a thread asked to run when an entity gets a signal (harnessSignal_t)</summary>
  TDoomScriptParitySignal = record
    ThreadNum: Integer;
    Func: TDoomScriptFunction;
  end;

  /// <summary>
  ///   The fake entity of the C++ harness (idEntity of Tools\Verifica\110\Game_local.h and its sub classes
  ///   idMover, idCamera, idPlayer, idAFEntity_Base): the class of the entity is its event class, the data
  ///   of every sub class is here. The game of the driver owns the entities.
  /// </summary>
  TDoomScriptParityEntity = class(TDoomScriptEventTarget)
  public
    EntityNumber: Integer;
    Name: AnsiString;
    SpawnArgs: TIdDict;
    Value: Single;
    Origin: TIdVec3;
    /// <summary>Entity number + 1, 0 = none</summary>
    Owner: Integer;
    Signals: array[0..DS_NUM_SIGNALS - 1] of TList<TDoomScriptParitySignal>;
    // idMover
    Moving: Boolean;
    MoveThread: Integer;
    Dest: TIdVec3;
    TurnLeft: Integer;
    // idPlayer
    InfluenceLevel: Integer;
    constructor Create(const AClassInfo: TDoomScriptClassInfo; const ANumber: Integer; const AName: AnsiString);
    destructor Destroy; override;
  end;

implementation

constructor TDoomScriptParityEntity.Create(const AClassInfo: TDoomScriptClassInfo; const ANumber: Integer;
  const AName: AnsiString);
var
  LIndex: Integer;
begin
  inherited Create(AClassInfo);
  EntityNumber := ANumber;
  Name := AName;
  SpawnArgs := TIdDict.Create;
  for LIndex := Low(Signals) to High(Signals) do
    Signals[LIndex] := TList<TDoomScriptParitySignal>.Create;
end;

destructor TDoomScriptParityEntity.Destroy;
var
  LIndex: Integer;
begin
  for LIndex := Low(Signals) to High(Signals) do
    Signals[LIndex].Free;
  SpawnArgs.Free;
  inherited;
end;

end.
