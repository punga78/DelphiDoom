{******************************************************************************}
{                                                                              }
{  DelphiDoom: net library - the delta of entityState_t of Quake III           }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): msg.c.          }
{  Copyright (C) 1999-2005 id Software, Inc.                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Net.Q3.EntityStateCodec;

{$Q-}
{$R-}
{$POINTERMATH ON}

interface

uses
  System.SysUtils, DelphiDoom.Net.Q3.Types, DelphiDoom.Net.Q3.Intf, DelphiDoom.Net.Q3.Message;

type
  /// <summary>
  ///   MSG_WriteDeltaEntity and MSG_ReadDeltaEntity: the changes of an entity since a base state (a baseline
  ///   or the entity of the previous snapshot) as a count of fields and, for each of them up to the last
  ///   that changed, a "changed" bit and the value. Floats that are small integers go out in 13 bits
  /// </summary>
  TQ3EntityStateCodec = class
  strict private
    FTable: IQ3NetFieldTable;
    class function FieldAt(AState: PQ3EntityState; const AField: TQ3NetField): PInteger; static; inline;
  public
    /// <summary>ATable is the table of entityState_t (<c>TQ3NetFieldTable.ForEntityState</c>)</summary>
    constructor Create(const ATable: IQ3NetFieldTable);
    /// <summary>
    ///   Writes part of a packetentities message, entity number included. ATo = nil writes a remove of the
    ///   entity of AFrom. Without AForce nothing at all is written when the entity did not change. A nil
    ///   AFrom with an entity to write is the zero state (the original would read through a null pointer)
    /// </summary>
    procedure WriteDelta(AMessage: TQ3Message; AFrom, ATo: PQ3EntityState; AForce: Boolean);
    /// <summary>
    ///   The entity number has already been read (that is how the base state is found). A remove sets the
    ///   number to MAX_GENTITIES - 1 and clears the rest. A count of fields above the table, which the
    ///   original reads past the end of its table for, is an <c>EQ3MessageException</c>
    /// </summary>
    procedure ReadDelta(AMessage: TQ3Message; AFrom, ATo: PQ3EntityState; ANumber: Integer);
  end;

implementation

{ TQ3EntityStateCodec }

constructor TQ3EntityStateCodec.Create(const ATable: IQ3NetFieldTable);
begin
  inherited Create;
  FTable := ATable;
end;

class function TQ3EntityStateCodec.FieldAt(AState: PQ3EntityState; const AField: TQ3NetField): PInteger;
begin
  Result := PInteger(PByte(AState) + AField.Offset);
end;

procedure TQ3EntityStateCodec.WriteDelta(AMessage: TQ3Message; AFrom, ATo: PQ3EntityState; AForce: Boolean);
var
  LIndex, LLastChanged, LTrunc: Integer;
  LField: TQ3NetField;
  LFromField, LToField: PInteger;
  LFullFloat: Single;
  LZero: TQ3EntityState;
begin
  // a nil "to" is a delta remove message
  if ATo = nil then
  begin
    if AFrom = nil then
      Exit;
    AMessage.WriteBits(AFrom^.Number, Q3_GENTITYNUM_BITS);
    AMessage.WriteBits(1, 1);
    Exit;
  end;

  if (ATo^.Number < 0) or (ATo^.Number >= Q3_MAX_GENTITIES) then
    raise EQ3MessageException.CreateFmt(SQ3MessageBadEntityNumber, [ATo^.Number]);

  if AFrom = nil then
  begin
    FillChar(LZero, SizeOf(LZero), 0);
    AFrom := @LZero;
  end;

  LLastChanged := 0;
  // build the change vector
  for LIndex := 0 to FTable.Count - 1 do
  begin
    LField := FTable[LIndex];
    if FieldAt(AFrom, LField)^ <> FieldAt(ATo, LField)^ then
      LLastChanged := LIndex + 1;
  end;

  if LLastChanged = 0 then
  begin
    // nothing at all changed
    if not AForce then
      Exit;
    // write two bits for no change
    AMessage.WriteBits(ATo^.Number, Q3_GENTITYNUM_BITS);
    AMessage.WriteBits(0, 1); // not removed
    AMessage.WriteBits(0, 1); // no delta
    Exit;
  end;

  AMessage.WriteBits(ATo^.Number, Q3_GENTITYNUM_BITS);
  AMessage.WriteBits(0, 1); // not removed
  AMessage.WriteBits(1, 1); // we have a delta

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

      if TQ3Message.FloatsEqual(LFullFloat, 0.0) then
        AMessage.WriteBits(0, 1)
      else
      begin
        AMessage.WriteBits(1, 1);
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
      end;
    end
    else
    begin
      if LToField^ = 0 then
        AMessage.WriteBits(0, 1)
      else
      begin
        AMessage.WriteBits(1, 1);
        // integer
        AMessage.WriteBits(LToField^, LField.Bits);
      end;
    end;
  end;
end;

procedure TQ3EntityStateCodec.ReadDelta(AMessage: TQ3Message; AFrom, ATo: PQ3EntityState; ANumber: Integer);
var
  LIndex, LChanged, LTrunc: Integer;
  LField: TQ3NetField;
  LFromField, LToField: PInteger;
begin
  if (ANumber < 0) or (ANumber >= Q3_MAX_GENTITIES) then
    raise EQ3MessageException.CreateFmt('Bad delta entity number: %d', [ANumber]);

  // check for a remove
  if AMessage.ReadBits(1) = 1 then
  begin
    FillChar(ATo^, SizeOf(ATo^), 0);
    ATo^.Number := Q3_MAX_GENTITIES - 1;
    Exit;
  end;

  // check for no delta
  if AMessage.ReadBits(1) = 0 then
  begin
    ATo^ := AFrom^;
    ATo^.Number := ANumber;
    Exit;
  end;

  LChanged := AMessage.ReadByte;
  if (LChanged < 0) or (LChanged > FTable.Count) then
    raise EQ3MessageException.CreateFmt(SQ3MessageBadFieldCount, ['entityState', LChanged, FTable.Count]);

  ATo^.Number := ANumber;

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
        LToField^ := 0
      else if AMessage.ReadBits(1) = 0 then
      begin
        // integral float, biased to allow equal parts positive and negative
        LTrunc := AMessage.ReadBits(Q3_FLOAT_INT_BITS) - Q3_FLOAT_INT_BIAS;
        PSingle(LToField)^ := LTrunc;
      end
      else
        LToField^ := AMessage.ReadBits(32); // full floating point value
    end
    else if AMessage.ReadBits(1) = 0 then
      LToField^ := 0
    else
      LToField^ := AMessage.ReadBits(LField.Bits);
  end;
  for LIndex := LChanged to FTable.Count - 1 do
  begin
    LField := FTable[LIndex];
    // no change
    FieldAt(ATo, LField)^ := FieldAt(AFrom, LField)^;
  end;
end;

end.
