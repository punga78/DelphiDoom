{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - a command of the computer player                   }
{                                                                              }
{  Port of war1 (acoto87/war1), war_ai.c (WarAICommand, wai_create*Request,     }
{  wai_createWaitForUnit, wai_createSleepForTime, wai_applyUnitRequestProgress),}
{  (c) 2019 Alejandro Coto Gutierrez, zlib License (see                         }
{  Libs\War\LICENSE-war1.txt). This is an altered version, not the original.   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Ai.Command;

interface

type
  /// <summary>
  ///   A WarAICommand: what the computer wants to do next. The union of the original (request and wait share the unit type
  ///   and the count; sleep has the end of the wait in real time) is three fields here. The commands of a player are
  ///   owned by it and freed with it (the original never frees them)
  /// </summary>
  TWarAiCommand = class
  strict private
    FId: Cardinal;
    FCommandType: Integer;
    FStatus: Integer;
    FUnitType: Integer;
    FCount: Integer;
    FEndRealTime: Double;
  public
    constructor Create(AId: Cardinal; ACommandType: Integer);
    /// <summary>wai_applyUnitRequestProgress: a REQUEST with units left starts, loses one and completes when none is left</summary>
    procedure ApplyUnitRequestProgress;
    /// <summary>
    ///   What a training state keeps instead of the pointer to the command of the original: the player and the id (the ids
    ///   count from 1 for each player), never 0
    /// </summary>
    class function MakeHandle(APlayer: Integer; AId: Cardinal): Cardinal; static; inline;
    /// <summary>The player of a handle (inverse of MakeHandle)</summary>
    class function HandlePlayer(AHandle: Cardinal): Integer; static; inline;
    /// <summary>The command id of a handle</summary>
    class function HandleId(AHandle: Cardinal): Cardinal; static; inline;
    /// <summary>wai_equalsAICommand: the same id</summary>
    function SameAs(const AOther: TWarAiCommand): Boolean;
    property Id: Cardinal read FId;
    property CommandType: Integer read FCommandType;
    property Status: Integer read FStatus write FStatus;
    /// <summary>The unit type of a REQUEST or a WAIT</summary>
    property UnitType: Integer read FUnitType write FUnitType;
    /// <summary>The units a REQUEST still has to train, or the units a WAIT waits for</summary>
    property Count: Integer read FCount write FCount;
    /// <summary>The real time (seconds) at which a SLEEP ends</summary>
    property EndRealTime: Double read FEndRealTime write FEndRealTime;
  end;

implementation

uses
  DelphiDoom.War.Ai.Types;

{ TWarAiCommand }

constructor TWarAiCommand.Create(AId: Cardinal; ACommandType: Integer);
begin
  inherited Create;
  FId := AId;
  FCommandType := ACommandType;
  FStatus := WAR_AI_STATUS_CREATED;
end;

procedure TWarAiCommand.ApplyUnitRequestProgress;
begin
  if (FCommandType <> WAR_AI_COMMAND_REQUEST) or (FCount <= 0) then
    Exit;
  FStatus := WAR_AI_STATUS_STARTED;
  Dec(FCount);
  if FCount = 0 then
    FStatus := WAR_AI_STATUS_COMPLETED;
end;

class function TWarAiCommand.MakeHandle(APlayer: Integer; AId: Cardinal): Cardinal;
begin
  Result := (Cardinal(APlayer + 1) shl 24) or (AId and $FFFFFF);
end;

class function TWarAiCommand.HandlePlayer(AHandle: Cardinal): Integer;
begin
  Result := Integer(AHandle shr 24) - 1;
end;

class function TWarAiCommand.HandleId(AHandle: Cardinal): Cardinal;
begin
  Result := AHandle and $FFFFFF;
end;

function TWarAiCommand.SameAs(const AOther: TWarAiCommand): Boolean;
begin
  Result := FId = AOther.FId;
end;

end.
