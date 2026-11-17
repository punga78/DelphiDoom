{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III host library - the structures of the bot library in   }
{  the data of the program (bot_goal_t, bot_input_t, aas_entityinfo_t ...)     }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): botlib.h,       }
{  be_aas.h, be_ea.h, be_ai_*.h. Copyright (C) 1999-2005 Id Software, Inc.     }
{  This unit is derived from the Quake III Arena source code and is therefore  }
{  available under the GNU General Public License, version 2 or (at your       }
{  option) any later version.                                                  }
{                                                                              }
{******************************************************************************}
{$Q-}
{$R-}
unit DelphiDoom.Q3Host.Bot.Memory;

// Overflow and range checks are off: the words of the structures are 32 bit, as in the C.

interface

uses
  System.SysUtils, DelphiDoom.Qvm.Intf, DelphiDoom.MathCore.Types, DelphiDoom.BotAi.Ea.Types,
  DelphiDoom.BotAi.Goal.Types, DelphiDoom.BotAi.Move.Types, DelphiDoom.BotAi.Chat.Types,
  DelphiDoom.BotAi.Weapon.Types, DelphiDoom.Aas.Types, DelphiDoom.Aas.Route.Types, DelphiDoom.Aas.Move.Types,
  DelphiDoom.Aas.Entity.Types;

type
  /// <summary>
  ///   Reads and writes the structures the BOTLIB system calls pass by pointer, where the program keeps them:
  ///   little endian, 4 byte words, the layout the compiler of the C gives (Tests\Data\Q3Host\botlayout.golden.txt,
  ///   Tools\Verifica\254\botlayout.sh: sizeof and offsetof of every structure and field). A structure is written
  ///   only by the call that writes it in the C; the padding is not touched
  /// </summary>
  TQ3BotMemory = class
  public
    const
      SIZE_ENTITYSTATE = 112;
      SIZE_INPUT = 40;
      SIZE_GOAL = 56;
      SIZE_INITMOVE = 68;
      SIZE_MOVERESULT = 52;
      SIZE_ENTITYINFO = 140;
      SIZE_AREAINFO = 52;
      SIZE_CLIENTMOVE = 84;
      SIZE_ALTROUTEGOAL = 24;
      SIZE_PREDICTROUTE = 36;
      SIZE_MATCH = 328;
      SIZE_CONSOLEMESSAGE = 276;
      SIZE_WEAPONINFO = 552;
      MAX_MESSAGE_SIZE = 256;
      /// <summary>MAX_ITEMS of the game: the inventory is passed as a pointer to this many integers</summary>
      INVENTORY_ITEMS = 256;
    class function Bits(AValue: Single): Integer; static; inline;
    class function Float(AValue: Integer): Single; static; inline;
    class function ReadVec3(const AMemory: IQvmMemory; AAddress: Integer): TVec3; static;
    class procedure WriteVec3(const AMemory: IQvmMemory; AAddress: Integer; const AValue: TVec3); static;
    /// <summary>A string that may be NULL (VMA of a NULL pointer): the empty text</summary>
    class function OptionalText(const AMemory: IQvmMemory; AAddress: Integer): AnsiString; static;
    class function ReadInventory(const AMemory: IQvmMemory; AAddress: Integer): TArray<Integer>; static;
    class function ReadGoal(const AMemory: IQvmMemory; AAddress: Integer): TBotGoal; static;
    class procedure WriteGoal(const AMemory: IQvmMemory; AAddress: Integer; const AGoal: TBotGoal); static;
    class function ReadInitMove(const AMemory: IQvmMemory; AAddress: Integer): TBotInitMove; static;
    class function ReadEntityState(const AMemory: IQvmMemory; AAddress: Integer): TBotEntityState; static;
    class procedure WriteInput(const AMemory: IQvmMemory; AAddress: Integer; const AInput: TBotInput); static;
    class procedure WriteMoveResult(const AMemory: IQvmMemory; AAddress: Integer;
      const AResult: TBotMoveResult); static;
    class procedure WriteEntityInfo(const AMemory: IQvmMemory; AAddress: Integer;
      const AInfo: TAasEntityInfo); static;
    class procedure WriteAreaInfo(const AMemory: IQvmMemory; AAddress: Integer; const AInfo: TAasAreaInfo); static;
    class procedure WriteClientMove(const AMemory: IQvmMemory; AAddress: Integer;
      const AMove: TAasClientMove); static;
    class procedure WritePredictRoute(const AMemory: IQvmMemory; AAddress: Integer;
      const ARoute: TAasPredictRoute); static;
    class procedure WriteAltRouteGoal(const AMemory: IQvmMemory; AAddress: Integer;
      const AGoal: TAasAltRouteGoal); static;
    class procedure WriteWeaponInfo(const AMemory: IQvmMemory; AAddress: Integer;
      const AInfo: TBotWeaponInfo); static;
    /// <summary>
    ///   BotNextConsoleMessage: the C copies the list entry and then clears prev and next (host pointers): here
    ///   the two words are written as 0
    /// </summary>
    class procedure WriteConsoleMessage(const AMemory: IQvmMemory; AAddress: Integer;
      const AMessage: TBotConsoleMessage); static;
    class function ReadMatch(const AMemory: IQvmMemory; AAddress: Integer): TBotMatch; static;
    class procedure WriteMatch(const AMemory: IQvmMemory; AAddress: Integer; const AMatch: TBotMatch); static;
  end;

implementation

type
  /// <summary>Writes consecutive 32 bit words from an address</summary>
  TWordCursor = record
  strict private
    FMemory: IQvmMemory;
    FAddress: Integer;
  public
    constructor Create(const AMemory: IQvmMemory; AAddress: Integer);
    procedure PutInt(AValue: Integer);
    procedure PutFloat(AValue: Single);
    procedure PutVec3(const AValue: TVec3);
    procedure PutBool(AValue: Boolean);
    function GetInt: Integer;
    function GetFloat: Single;
    function GetVec3: TVec3;
  end;

constructor TWordCursor.Create(const AMemory: IQvmMemory; AAddress: Integer);
begin
  FMemory := AMemory;
  FAddress := AAddress;
end;

procedure TWordCursor.PutInt(AValue: Integer);
begin
  FMemory.WriteInt32(FAddress, AValue);
  Inc(FAddress, 4);
end;

procedure TWordCursor.PutFloat(AValue: Single);
begin
  PutInt(TQ3BotMemory.Bits(AValue));
end;

procedure TWordCursor.PutVec3(const AValue: TVec3);
begin
  PutFloat(AValue[0]);
  PutFloat(AValue[1]);
  PutFloat(AValue[2]);
end;

procedure TWordCursor.PutBool(AValue: Boolean);
begin
  PutInt(Ord(AValue));
end;

function TWordCursor.GetInt: Integer;
begin
  Result := FMemory.ReadInt32(FAddress);
  Inc(FAddress, 4);
end;

function TWordCursor.GetFloat: Single;
begin
  Result := TQ3BotMemory.Float(GetInt);
end;

function TWordCursor.GetVec3: TVec3;
begin
  Result[0] := GetFloat;
  Result[1] := GetFloat;
  Result[2] := GetFloat;
end;

{ TQ3BotMemory }

class function TQ3BotMemory.Bits(AValue: Single): Integer;
begin
  Result := PInteger(@AValue)^;
end;

class function TQ3BotMemory.Float(AValue: Integer): Single;
begin
  Result := PSingle(@AValue)^;
end;

class function TQ3BotMemory.ReadVec3(const AMemory: IQvmMemory; AAddress: Integer): TVec3;
var
  LCursor: TWordCursor;
begin
  LCursor := TWordCursor.Create(AMemory, AAddress);
  Result := LCursor.GetVec3;
end;

class procedure TQ3BotMemory.WriteVec3(const AMemory: IQvmMemory; AAddress: Integer; const AValue: TVec3);
var
  LCursor: TWordCursor;
begin
  LCursor := TWordCursor.Create(AMemory, AAddress);
  LCursor.PutVec3(AValue);
end;

class function TQ3BotMemory.OptionalText(const AMemory: IQvmMemory; AAddress: Integer): AnsiString;
begin
  if AAddress = 0 then
    Result := ''
  else
    Result := AMemory.ReadString(AAddress);
end;

class function TQ3BotMemory.ReadInventory(const AMemory: IQvmMemory; AAddress: Integer): TArray<Integer>;
var
  LCursor: TWordCursor;
  LIndex: Integer;
begin
  SetLength(Result, INVENTORY_ITEMS);
  LCursor := TWordCursor.Create(AMemory, AAddress);
  for LIndex := 0 to INVENTORY_ITEMS - 1 do
    Result[LIndex] := LCursor.GetInt;
end;

class function TQ3BotMemory.ReadGoal(const AMemory: IQvmMemory; AAddress: Integer): TBotGoal;
var
  LCursor: TWordCursor;
begin
  LCursor := TWordCursor.Create(AMemory, AAddress);
  Result.Origin := LCursor.GetVec3;
  Result.AreaNum := LCursor.GetInt;
  Result.Mins := LCursor.GetVec3;
  Result.Maxs := LCursor.GetVec3;
  Result.EntityNum := LCursor.GetInt;
  Result.Number := LCursor.GetInt;
  Result.Flags := LCursor.GetInt;
  Result.ItemInfo := LCursor.GetInt;
end;

class procedure TQ3BotMemory.WriteGoal(const AMemory: IQvmMemory; AAddress: Integer; const AGoal: TBotGoal);
var
  LCursor: TWordCursor;
begin
  LCursor := TWordCursor.Create(AMemory, AAddress);
  LCursor.PutVec3(AGoal.Origin);
  LCursor.PutInt(AGoal.AreaNum);
  LCursor.PutVec3(AGoal.Mins);
  LCursor.PutVec3(AGoal.Maxs);
  LCursor.PutInt(AGoal.EntityNum);
  LCursor.PutInt(AGoal.Number);
  LCursor.PutInt(AGoal.Flags);
  LCursor.PutInt(AGoal.ItemInfo);
end;

class function TQ3BotMemory.ReadInitMove(const AMemory: IQvmMemory; AAddress: Integer): TBotInitMove;
var
  LCursor: TWordCursor;
begin
  LCursor := TWordCursor.Create(AMemory, AAddress);
  Result.Origin := LCursor.GetVec3;
  Result.Velocity := LCursor.GetVec3;
  Result.ViewOffset := LCursor.GetVec3;
  Result.EntityNum := LCursor.GetInt;
  Result.Client := LCursor.GetInt;
  Result.ThinkTime := LCursor.GetFloat;
  Result.PresenceType := LCursor.GetInt;
  Result.ViewAngles := LCursor.GetVec3;
  Result.OrMoveFlags := LCursor.GetInt;
end;

class function TQ3BotMemory.ReadEntityState(const AMemory: IQvmMemory; AAddress: Integer): TBotEntityState;
var
  LCursor: TWordCursor;
begin
  LCursor := TWordCursor.Create(AMemory, AAddress);
  Result.EntityType := LCursor.GetInt;
  Result.Flags := LCursor.GetInt;
  Result.Origin := LCursor.GetVec3;
  Result.Angles := LCursor.GetVec3;
  Result.OldOrigin := LCursor.GetVec3;
  Result.Mins := LCursor.GetVec3;
  Result.Maxs := LCursor.GetVec3;
  Result.GroundEnt := LCursor.GetInt;
  Result.Solid := LCursor.GetInt;
  Result.ModelIndex := LCursor.GetInt;
  Result.ModelIndex2 := LCursor.GetInt;
  Result.Frame := LCursor.GetInt;
  Result.Event := LCursor.GetInt;
  Result.EventParm := LCursor.GetInt;
  Result.Powerups := LCursor.GetInt;
  Result.Weapon := LCursor.GetInt;
  Result.LegsAnim := LCursor.GetInt;
  Result.TorsoAnim := LCursor.GetInt;
end;

class procedure TQ3BotMemory.WriteInput(const AMemory: IQvmMemory; AAddress: Integer; const AInput: TBotInput);
var
  LCursor: TWordCursor;
begin
  LCursor := TWordCursor.Create(AMemory, AAddress);
  LCursor.PutFloat(AInput.ThinkTime);
  LCursor.PutVec3(AInput.Dir);
  LCursor.PutFloat(AInput.Speed);
  LCursor.PutVec3(AInput.ViewAngles);
  LCursor.PutInt(AInput.ActionFlags);
  LCursor.PutInt(AInput.Weapon);
end;

class procedure TQ3BotMemory.WriteMoveResult(const AMemory: IQvmMemory; AAddress: Integer;
  const AResult: TBotMoveResult);
var
  LCursor: TWordCursor;
begin
  LCursor := TWordCursor.Create(AMemory, AAddress);
  LCursor.PutBool(AResult.Failure);
  LCursor.PutInt(AResult.ResultType);
  LCursor.PutBool(AResult.Blocked);
  LCursor.PutInt(AResult.BlockEntity);
  LCursor.PutInt(AResult.TravelType);
  LCursor.PutInt(AResult.Flags);
  LCursor.PutInt(AResult.Weapon);
  LCursor.PutVec3(AResult.MoveDir);
  LCursor.PutVec3(AResult.IdealViewAngles);
end;

class procedure TQ3BotMemory.WriteEntityInfo(const AMemory: IQvmMemory; AAddress: Integer;
  const AInfo: TAasEntityInfo);
var
  LCursor: TWordCursor;
begin
  LCursor := TWordCursor.Create(AMemory, AAddress);
  LCursor.PutBool(AInfo.Valid);
  LCursor.PutInt(AInfo.EntityType);
  LCursor.PutInt(AInfo.Flags);
  LCursor.PutFloat(AInfo.LocalTime);
  LCursor.PutFloat(AInfo.UpdateTime);
  LCursor.PutInt(AInfo.Number);
  LCursor.PutVec3(AInfo.Origin);
  LCursor.PutVec3(AInfo.Angles);
  LCursor.PutVec3(AInfo.OldOrigin);
  LCursor.PutVec3(AInfo.LastVisOrigin);
  LCursor.PutVec3(AInfo.Mins);
  LCursor.PutVec3(AInfo.Maxs);
  LCursor.PutInt(AInfo.GroundEnt);
  LCursor.PutInt(AInfo.Solid);
  LCursor.PutInt(AInfo.ModelIndex);
  LCursor.PutInt(AInfo.ModelIndex2);
  LCursor.PutInt(AInfo.Frame);
  LCursor.PutInt(AInfo.Event);
  LCursor.PutInt(AInfo.EventParm);
  LCursor.PutInt(AInfo.Powerups);
  LCursor.PutInt(AInfo.Weapon);
  LCursor.PutInt(AInfo.LegsAnim);
  LCursor.PutInt(AInfo.TorsoAnim);
end;

class procedure TQ3BotMemory.WriteAreaInfo(const AMemory: IQvmMemory; AAddress: Integer; const AInfo: TAasAreaInfo);
var
  LCursor: TWordCursor;
begin
  LCursor := TWordCursor.Create(AMemory, AAddress);
  LCursor.PutInt(AInfo.Contents);
  LCursor.PutInt(AInfo.Flags);
  LCursor.PutInt(AInfo.PresenceType);
  LCursor.PutInt(AInfo.Cluster);
  LCursor.PutVec3(AInfo.Mins);
  LCursor.PutVec3(AInfo.Maxs);
  LCursor.PutVec3(AInfo.Center);
end;

class procedure TQ3BotMemory.WriteClientMove(const AMemory: IQvmMemory; AAddress: Integer;
  const AMove: TAasClientMove);
var
  LCursor: TWordCursor;
begin
  LCursor := TWordCursor.Create(AMemory, AAddress);
  LCursor.PutVec3(AMove.EndPos);
  LCursor.PutInt(AMove.EndArea);
  LCursor.PutVec3(AMove.Velocity);
  // aas_trace_t
  LCursor.PutBool(AMove.Trace.StartSolid);
  LCursor.PutFloat(AMove.Trace.Fraction);
  LCursor.PutVec3(AMove.Trace.EndPos);
  LCursor.PutInt(AMove.Trace.Ent);
  LCursor.PutInt(AMove.Trace.LastArea);
  LCursor.PutInt(AMove.Trace.Area);
  LCursor.PutInt(AMove.Trace.PlaneNum);
  LCursor.PutInt(AMove.PresenceType);
  LCursor.PutInt(AMove.StopEvent);
  LCursor.PutInt(AMove.EndContents);
  LCursor.PutFloat(AMove.Time);
  LCursor.PutInt(AMove.Frames);
end;

class procedure TQ3BotMemory.WritePredictRoute(const AMemory: IQvmMemory; AAddress: Integer;
  const ARoute: TAasPredictRoute);
var
  LCursor: TWordCursor;
begin
  LCursor := TWordCursor.Create(AMemory, AAddress);
  LCursor.PutVec3(ARoute.EndPos);
  LCursor.PutInt(ARoute.EndArea);
  LCursor.PutInt(ARoute.StopEvent);
  LCursor.PutInt(ARoute.EndContents);
  LCursor.PutInt(ARoute.EndTravelFlags);
  LCursor.PutInt(ARoute.NumAreas);
  LCursor.PutInt(ARoute.Time);
end;

class procedure TQ3BotMemory.WriteAltRouteGoal(const AMemory: IQvmMemory; AAddress: Integer;
  const AGoal: TAasAltRouteGoal);
var
  LCursor: TWordCursor;
begin
  LCursor := TWordCursor.Create(AMemory, AAddress);
  LCursor.PutVec3(AGoal.Origin);
  LCursor.PutInt(AGoal.AreaNum);
  // three unsigned shorts; the two bytes of padding after them are not written
  AMemory.WriteByte(AAddress + 16, AGoal.StartTravelTime and $FF);
  AMemory.WriteByte(AAddress + 17, AGoal.StartTravelTime shr 8);
  AMemory.WriteByte(AAddress + 18, AGoal.GoalTravelTime and $FF);
  AMemory.WriteByte(AAddress + 19, AGoal.GoalTravelTime shr 8);
  AMemory.WriteByte(AAddress + 20, AGoal.ExtraTravelTime and $FF);
  AMemory.WriteByte(AAddress + 21, AGoal.ExtraTravelTime shr 8);
end;

class procedure TQ3BotMemory.WriteWeaponInfo(const AMemory: IQvmMemory; AAddress: Integer;
  const AInfo: TBotWeaponInfo);
begin
  // weaponinfo_t is the packed record of the library: same bytes
  Move(AInfo, AMemory.Range(AAddress, SIZE_WEAPONINFO)^, SIZE_WEAPONINFO);
end;

class procedure TQ3BotMemory.WriteConsoleMessage(const AMemory: IQvmMemory; AAddress: Integer;
  const AMessage: TBotConsoleMessage);
var
  LCursor: TWordCursor;
begin
  LCursor := TWordCursor.Create(AMemory, AAddress);
  LCursor.PutInt(AMessage.Handle);
  LCursor.PutFloat(AMessage.Time);
  LCursor.PutInt(AMessage.MessageType);
  AMemory.WriteString(AAddress + 12, AMessage.Text, MAX_MESSAGE_SIZE);
  AMemory.WriteInt32(AAddress + 268, 0);
  AMemory.WriteInt32(AAddress + 272, 0);
end;

class function TQ3BotMemory.ReadMatch(const AMemory: IQvmMemory; AAddress: Integer): TBotMatch;
var
  LIndex, LLength: Integer;
begin
  // the text is a char[256]: it stops at the zero or at its end
  LLength := 0;
  while (LLength < MAX_MESSAGE_SIZE) and (AMemory.ReadByte(AAddress + LLength) <> 0) do
    Inc(LLength);
  SetLength(Result.Text, LLength);
  for LIndex := 0 to LLength - 1 do
    Result.Text[LIndex + 1] := AnsiChar(AMemory.ReadByte(AAddress + LIndex));
  Result.MatchType := AMemory.ReadInt32(AAddress + 256);
  Result.SubType := AMemory.ReadInt32(AAddress + 260);
  for LIndex := 0 to MAX_MATCHVARIABLES - 1 do
  begin
    Result.Variables[LIndex].Offset := ShortInt(AMemory.ReadByte(AAddress + 264 + 8 * LIndex));
    Result.Variables[LIndex].Length := AMemory.ReadInt32(AAddress + 264 + 8 * LIndex + 4);
  end;
end;

class procedure TQ3BotMemory.WriteMatch(const AMemory: IQvmMemory; AAddress: Integer; const AMatch: TBotMatch);
var
  LIndex: Integer;
begin
  AMemory.WriteString(AAddress, AMatch.Text, MAX_MESSAGE_SIZE);
  AMemory.WriteInt32(AAddress + 256, AMatch.MatchType);
  AMemory.WriteInt32(AAddress + 260, AMatch.SubType);
  for LIndex := 0 to MAX_MATCHVARIABLES - 1 do
  begin
    AMemory.WriteByte(AAddress + 264 + 8 * LIndex, Byte(AMatch.Variables[LIndex].Offset));
    AMemory.WriteInt32(AAddress + 264 + 8 * LIndex + 4, AMatch.Variables[LIndex].Length);
  end;
end;

end.
