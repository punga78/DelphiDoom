{******************************************************************************}
{                                                                              }
{  DelphiDoom: net library - the delta of usercmd_t of Quake III               }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): msg.c.          }
{  Copyright (C) 1999-2005 id Software, Inc.                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Net.Q3.UserCmdCodec;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.Net.Q3.Types, DelphiDoom.Net.Q3.Message;

type
  /// <summary>
  ///   MSG_WriteDeltaUsercmd, MSG_ReadDeltaUsercmd and the Key versions that xor the values with a key
  ///   (the server time makes it change with every command)
  /// </summary>
  TQ3UserCmdCodec = class
  public
    class procedure WriteDelta(AMessage: TQ3Message; const AFrom, ATo: TQ3UserCmd); static;
    class procedure ReadDelta(AMessage: TQ3Message; const AFrom: TQ3UserCmd; out ATo: TQ3UserCmd); static;
    class procedure WriteDeltaKey(AMessage: TQ3Message; AKey: Integer; const AFrom, ATo: TQ3UserCmd); static;
    class procedure ReadDeltaKey(AMessage: TQ3Message; AKey: Integer; const AFrom: TQ3UserCmd;
      out ATo: TQ3UserCmd); static;
  end;

implementation

{ TQ3UserCmdCodec }

class procedure TQ3UserCmdCodec.WriteDelta(AMessage: TQ3Message; const AFrom, ATo: TQ3UserCmd);
begin
  if ATo.ServerTime - AFrom.ServerTime < 256 then
  begin
    AMessage.WriteBits(1, 1);
    AMessage.WriteBits(ATo.ServerTime - AFrom.ServerTime, 8);
  end
  else
  begin
    AMessage.WriteBits(0, 1);
    AMessage.WriteBits(ATo.ServerTime, 32);
  end;
  AMessage.WriteDelta(AFrom.Angles[0], ATo.Angles[0], 16);
  AMessage.WriteDelta(AFrom.Angles[1], ATo.Angles[1], 16);
  AMessage.WriteDelta(AFrom.Angles[2], ATo.Angles[2], 16);
  AMessage.WriteDelta(AFrom.ForwardMove, ATo.ForwardMove, 8);
  AMessage.WriteDelta(AFrom.RightMove, ATo.RightMove, 8);
  AMessage.WriteDelta(AFrom.UpMove, ATo.UpMove, 8);
  AMessage.WriteDelta(AFrom.Buttons, ATo.Buttons, 16);
  AMessage.WriteDelta(AFrom.Weapon, ATo.Weapon, 8);
end;

class procedure TQ3UserCmdCodec.ReadDelta(AMessage: TQ3Message; const AFrom: TQ3UserCmd; out ATo: TQ3UserCmd);
begin
  if AMessage.ReadBits(1) <> 0 then
    ATo.ServerTime := AFrom.ServerTime + AMessage.ReadBits(8)
  else
    ATo.ServerTime := AMessage.ReadBits(32);
  ATo.Angles[0] := AMessage.ReadDelta(AFrom.Angles[0], 16);
  ATo.Angles[1] := AMessage.ReadDelta(AFrom.Angles[1], 16);
  ATo.Angles[2] := AMessage.ReadDelta(AFrom.Angles[2], 16);
  ATo.ForwardMove := ShortInt(AMessage.ReadDelta(AFrom.ForwardMove, 8));
  ATo.RightMove := ShortInt(AMessage.ReadDelta(AFrom.RightMove, 8));
  ATo.UpMove := ShortInt(AMessage.ReadDelta(AFrom.UpMove, 8));
  ATo.Buttons := AMessage.ReadDelta(AFrom.Buttons, 16);
  ATo.Weapon := Byte(AMessage.ReadDelta(AFrom.Weapon, 8));
end;

class procedure TQ3UserCmdCodec.WriteDeltaKey(AMessage: TQ3Message; AKey: Integer; const AFrom, ATo: TQ3UserCmd);
begin
  if ATo.ServerTime - AFrom.ServerTime < 256 then
  begin
    AMessage.WriteBits(1, 1);
    AMessage.WriteBits(ATo.ServerTime - AFrom.ServerTime, 8);
  end
  else
  begin
    AMessage.WriteBits(0, 1);
    AMessage.WriteBits(ATo.ServerTime, 32);
  end;
  if (AFrom.Angles[0] = ATo.Angles[0]) and (AFrom.Angles[1] = ATo.Angles[1])
    and (AFrom.Angles[2] = ATo.Angles[2]) and (AFrom.ForwardMove = ATo.ForwardMove)
    and (AFrom.RightMove = ATo.RightMove) and (AFrom.UpMove = ATo.UpMove)
    and (AFrom.Buttons = ATo.Buttons) and (AFrom.Weapon = ATo.Weapon) then
  begin
    AMessage.WriteBits(0, 1); // no change
    Exit;
  end;
  AKey := AKey xor ATo.ServerTime;
  AMessage.WriteBits(1, 1);
  AMessage.WriteDeltaKey(AKey, AFrom.Angles[0], ATo.Angles[0], 16);
  AMessage.WriteDeltaKey(AKey, AFrom.Angles[1], ATo.Angles[1], 16);
  AMessage.WriteDeltaKey(AKey, AFrom.Angles[2], ATo.Angles[2], 16);
  AMessage.WriteDeltaKey(AKey, AFrom.ForwardMove, ATo.ForwardMove, 8);
  AMessage.WriteDeltaKey(AKey, AFrom.RightMove, ATo.RightMove, 8);
  AMessage.WriteDeltaKey(AKey, AFrom.UpMove, ATo.UpMove, 8);
  AMessage.WriteDeltaKey(AKey, AFrom.Buttons, ATo.Buttons, 16);
  AMessage.WriteDeltaKey(AKey, AFrom.Weapon, ATo.Weapon, 8);
end;

class procedure TQ3UserCmdCodec.ReadDeltaKey(AMessage: TQ3Message; AKey: Integer; const AFrom: TQ3UserCmd;
  out ATo: TQ3UserCmd);
begin
  if AMessage.ReadBits(1) <> 0 then
    ATo.ServerTime := AFrom.ServerTime + AMessage.ReadBits(8)
  else
    ATo.ServerTime := AMessage.ReadBits(32);
  if AMessage.ReadBits(1) <> 0 then
  begin
    AKey := AKey xor ATo.ServerTime;
    ATo.Angles[0] := AMessage.ReadDeltaKey(AKey, AFrom.Angles[0], 16);
    ATo.Angles[1] := AMessage.ReadDeltaKey(AKey, AFrom.Angles[1], 16);
    ATo.Angles[2] := AMessage.ReadDeltaKey(AKey, AFrom.Angles[2], 16);
    ATo.ForwardMove := ShortInt(AMessage.ReadDeltaKey(AKey, AFrom.ForwardMove, 8));
    ATo.RightMove := ShortInt(AMessage.ReadDeltaKey(AKey, AFrom.RightMove, 8));
    ATo.UpMove := ShortInt(AMessage.ReadDeltaKey(AKey, AFrom.UpMove, 8));
    ATo.Buttons := AMessage.ReadDeltaKey(AKey, AFrom.Buttons, 16);
    ATo.Weapon := Byte(AMessage.ReadDeltaKey(AKey, AFrom.Weapon, 8));
  end
  else
  begin
    ATo.Angles[0] := AFrom.Angles[0];
    ATo.Angles[1] := AFrom.Angles[1];
    ATo.Angles[2] := AFrom.Angles[2];
    ATo.ForwardMove := AFrom.ForwardMove;
    ATo.RightMove := AFrom.RightMove;
    ATo.UpMove := AFrom.UpMove;
    ATo.Buttons := AFrom.Buttons;
    ATo.Weapon := AFrom.Weapon;
  end;
end;

end.
