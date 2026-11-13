{******************************************************************************}
{                                                                              }
{  DelphiDoom: net library - the delta of playerState_t of Quake III           }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): msg.c.          }
{  Copyright (C) 1999-2005 id Software, Inc.                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Net.Q3.PlayerStateCodec;

{$Q-}
{$R-}
{$POINTERMATH ON}

interface

uses
  System.SysUtils, DelphiDoom.Net.Q3.Types, DelphiDoom.Net.Q3.Intf, DelphiDoom.Net.Q3.Message;

type
  /// <summary>
  ///   MSG_WriteDeltaPlayerstate and MSG_ReadDeltaPlayerstate: the fields of the table as for the entities
  ///   (without the "zero" shortcut), then the four arrays (stats, persistant, ammo, powerups) as a mask of
  ///   the elements that changed and their values
  /// </summary>
  TQ3PlayerStateCodec = class
  strict private
    FTable: IQ3NetFieldTable;
    class function FieldAt(AState: PQ3PlayerState; const AField: TQ3NetField): PInteger; static; inline;
    class procedure WriteArray(AMessage: TQ3Message; const AFrom, ATo: array of Integer; ALongValues: Boolean); static;
    class procedure ReadArray(AMessage: TQ3Message; var AValues: array of Integer; ALongValues: Boolean); static;
  public
    /// <summary>ATable is the table of playerState_t (<c>TQ3NetFieldTable.ForPlayerState</c>)</summary>
    constructor Create(const ATable: IQ3NetFieldTable);
    /// <summary>A nil AFrom is the zero state</summary>
    procedure WriteDelta(AMessage: TQ3Message; AFrom, ATo: PQ3PlayerState);
    /// <summary>
    ///   ATo gets AFrom (the zero state if nil) with the changes. A count of fields above the table is an
    ///   <c>EQ3MessageException</c> (the original reads past the end of its table)
    /// </summary>
    procedure ReadDelta(AMessage: TQ3Message; AFrom, ATo: PQ3PlayerState);
  end;

implementation

{ TQ3PlayerStateCodec }

constructor TQ3PlayerStateCodec.Create(const ATable: IQ3NetFieldTable);
begin
  inherited Create;
  FTable := ATable;
end;

class function TQ3PlayerStateCodec.FieldAt(AState: PQ3PlayerState; const AField: TQ3NetField): PInteger;
begin
  Result := PInteger(PByte(AState) + AField.Offset);
end;

class procedure TQ3PlayerStateCodec.WriteArray(AMessage: TQ3Message; const AFrom, ATo: array of Integer;
  ALongValues: Boolean);
var
  LIndex, LBits: Integer;
begin
  LBits := 0;
  for LIndex := 0 to 15 do
    if ATo[LIndex] <> AFrom[LIndex] then
      LBits := LBits or (1 shl LIndex);
  if LBits = 0 then
  begin
    AMessage.WriteBits(0, 1); // no change
    Exit;
  end;
  AMessage.WriteBits(1, 1); // changed
  AMessage.WriteShort(LBits);
  for LIndex := 0 to 15 do
    if (LBits and (1 shl LIndex)) <> 0 then
    begin
      if ALongValues then
        AMessage.WriteLong(ATo[LIndex])
      else
        AMessage.WriteShort(ATo[LIndex]);
    end;
end;

class procedure TQ3PlayerStateCodec.ReadArray(AMessage: TQ3Message; var AValues: array of Integer;
  ALongValues: Boolean);
var
  LIndex, LBits: Integer;
begin
  if AMessage.ReadBits(1) = 0 then
    Exit;
  LBits := AMessage.ReadShort;
  for LIndex := 0 to 15 do
    if (LBits and (1 shl LIndex)) <> 0 then
    begin
      if ALongValues then
        AValues[LIndex] := AMessage.ReadLong
      else
        AValues[LIndex] := AMessage.ReadShort;
    end;
end;

procedure TQ3PlayerStateCodec.WriteDelta(AMessage: TQ3Message; AFrom, ATo: PQ3PlayerState);
var
  LIndex, LLastChanged, LTrunc: Integer;
  LField: TQ3NetField;
  LFromField, LToField: PInteger;
  LFullFloat: Single;
  LZero: TQ3PlayerState;
  LAnyChange: Boolean;
  LChanged: array[0..3] of Boolean;
begin
  if AFrom = nil then
  begin
    FillChar(LZero, SizeOf(LZero), 0);
    AFrom := @LZero;
  end;

  LLastChanged := 0;
  for LIndex := 0 to FTable.Count - 1 do
  begin
    LField := FTable[LIndex];
    if FieldAt(AFrom, LField)^ <> FieldAt(ATo, LField)^ then
      LLastChanged := LIndex + 1;
  end;

  AMessage.WriteByte(LLastChanged); // # of changes

  for LIndex := 0 to LLastChanged - 1 do
  begin
    LField := FTable[LIndex];
    LFromField := FieldAt(AFrom, LField);
    LToField := FieldAt(ATo, LField);

    if LFromField^ = LToField^ then
    begin
      AMessage.WriteBits(0, 1); // no change
      Continue;
    end;

    AMessage.WriteBits(1, 1); // changed

    if LField.Bits = 0 then
    begin
      // float
      LFullFloat := TQ3Message.BitsToFloat(LToField^);
      LTrunc := TQ3Message.TruncToInteger(LFullFloat);

      if (LTrunc + Q3_FLOAT_INT_BIAS >= 0) and (LTrunc + Q3_FLOAT_INT_BIAS < (1 shl Q3_FLOAT_INT_BITS))
        and TQ3Message.FloatsEqual(LTrunc, LFullFloat) then
      begin
        // send as small integer
        AMessage.WriteBits(0, 1);
        AMessage.WriteBits(LTrunc + Q3_FLOAT_INT_BIAS, Q3_FLOAT_INT_BITS);
      end
      else
      begin
        // send as full floating point value
        AMessage.WriteBits(1, 1);
        AMessage.WriteBits(LToField^, 32);
      end;
    end
    else
      AMessage.WriteBits(LToField^, LField.Bits); // integer
  end;

  // send the arrays
  LChanged[0] := False;
  LChanged[1] := False;
  LChanged[2] := False;
  LChanged[3] := False;
  for LIndex := 0 to 15 do
  begin
    if ATo^.Stats[LIndex] <> AFrom^.Stats[LIndex] then
      LChanged[0] := True;
    if ATo^.Persistant[LIndex] <> AFrom^.Persistant[LIndex] then
      LChanged[1] := True;
    if ATo^.Ammo[LIndex] <> AFrom^.Ammo[LIndex] then
      LChanged[2] := True;
    if ATo^.Powerups[LIndex] <> AFrom^.Powerups[LIndex] then
      LChanged[3] := True;
  end;
  LAnyChange := LChanged[0] or LChanged[1] or LChanged[2] or LChanged[3];
  if not LAnyChange then
  begin
    AMessage.WriteBits(0, 1); // no change
    Exit;
  end;
  AMessage.WriteBits(1, 1); // changed
  WriteArray(AMessage, AFrom^.Stats, ATo^.Stats, False);
  WriteArray(AMessage, AFrom^.Persistant, ATo^.Persistant, False);
  WriteArray(AMessage, AFrom^.Ammo, ATo^.Ammo, False);
  WriteArray(AMessage, AFrom^.Powerups, ATo^.Powerups, True);
end;

procedure TQ3PlayerStateCodec.ReadDelta(AMessage: TQ3Message; AFrom, ATo: PQ3PlayerState);
var
  LIndex, LChanged, LTrunc: Integer;
  LField: TQ3NetField;
  LFromField, LToField: PInteger;
  LZero: TQ3PlayerState;
begin
  if AFrom = nil then
  begin
    FillChar(LZero, SizeOf(LZero), 0);
    AFrom := @LZero;
  end;
  ATo^ := AFrom^;

  LChanged := AMessage.ReadByte;
  if (LChanged < 0) or (LChanged > FTable.Count) then
    raise EQ3MessageException.CreateFmt(SQ3MessageBadFieldCount, ['playerState', LChanged, FTable.Count]);

  for LIndex := 0 to LChanged - 1 do
  begin
    LField := FTable[LIndex];
    LFromField := FieldAt(AFrom, LField);
    LToField := FieldAt(ATo, LField);

    if AMessage.ReadBits(1) = 0 then
      LToField^ := LFromField^ // no change
    else if LField.Bits = 0 then
    begin
      // float
      if AMessage.ReadBits(1) = 0 then
      begin
        // integral float, biased to allow equal parts positive and negative
        LTrunc := AMessage.ReadBits(Q3_FLOAT_INT_BITS) - Q3_FLOAT_INT_BIAS;
        PSingle(LToField)^ := LTrunc;
      end
      else
        LToField^ := AMessage.ReadBits(32); // full floating point value
    end
    else
      LToField^ := AMessage.ReadBits(LField.Bits); // integer
  end;
  for LIndex := LChanged to FTable.Count - 1 do
  begin
    LField := FTable[LIndex];
    FieldAt(ATo, LField)^ := FieldAt(AFrom, LField)^; // no change
  end;

  // read the arrays
  if AMessage.ReadBits(1) <> 0 then
  begin
    ReadArray(AMessage, ATo^.Stats, False);
    ReadArray(AMessage, ATo^.Persistant, False);
    ReadArray(AMessage, ATo^.Ammo, False);
    ReadArray(AMessage, ATo^.Powerups, True);
  end;
end;

end.
