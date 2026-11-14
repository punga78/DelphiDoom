{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom script (id Tech 4) - the primitives of a save game         }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): game\gamesys\            }
{  SaveGame.cpp (the encodings of idSaveGame and idRestoreGame). Copyright     }
{  (C) 1999-2011 id Software LLC, a ZeniMax Media company.                     }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3 or later, with    }
{  the additional terms of the Doom 3 Source Code License (see README.md of    }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.DoomScript.SaveStream;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.DoomScript.Types, DelphiDoom.IdLib.Math.Vec3, DelphiDoom.Scanner.IdDict;

type
  /// <summary>How a save writes the reference to an object (idSaveGame::WriteObject)</summary>
  TDoomScriptWriteObject = reference to procedure(const AStream: TStream; const AObject: TObject);
  /// <summary>idRestoreGame::ReadObject: the object of a saved reference, nil for none</summary>
  TDoomScriptReadObject = reference to function(const AStream: TStream): TObject;

  /// <summary>
  ///   The encodings idSaveGame and idRestoreGame use, on a stream: little endian integers and floats, a
  ///   string as its length and its bytes, a boolean as one byte, a dictionary as the number of pairs and
  ///   the pairs. A read past the end of the stream or a bad length raises EDoomScriptError: a damaged
  ///   save never reads outside the stream.
  /// </summary>
  TDoomScriptSaveStream = record
  public
    class procedure WriteInt(const AStream: TStream; const AValue: Integer); static;
    class procedure WriteByte(const AStream: TStream; const AValue: Byte); static;
    class procedure WriteBool(const AStream: TStream; const AValue: Boolean); static;
    class procedure WriteFloat(const AStream: TStream; const AValue: Single); static;
    class procedure WriteVec3(const AStream: TStream; const AValue: TIdVec3); static;
    class procedure WriteString(const AStream: TStream; const AValue: AnsiString); static;
    class procedure WriteBytes(const AStream: TStream; const AData: PByte; const ASize: Integer); static;
    /// <summary>idSaveGame::WriteDict; a nil dictionary is written as -1</summary>
    class procedure WriteDict(const AStream: TStream; const ADict: TIdDict); static;
    class function ReadInt(const AStream: TStream): Integer; static;
    class function ReadByte(const AStream: TStream): Byte; static;
    class function ReadBool(const AStream: TStream): Boolean; static;
    class function ReadFloat(const AStream: TStream): Single; static;
    class function ReadVec3(const AStream: TStream): TIdVec3; static;
    class function ReadString(const AStream: TStream): AnsiString; static;
    class procedure ReadBytes(const AStream: TStream; const AData: PByte; const ASize: Integer); static;
    /// <summary>idRestoreGame::ReadDict: clears the dictionary and reads the pairs (-1 leaves it empty)</summary>
    class procedure ReadDict(const AStream: TStream; const ADict: TIdDict); static;
  end;

implementation

const
  SReadPastEnd = 'idRestoreGame: read past the end of the save data';
  SInvalidLength = 'idRestoreGame::ReadString: invalid length (%d)';

class procedure TDoomScriptSaveStream.WriteBytes(const AStream: TStream; const AData: PByte; const ASize: Integer);
begin
  if ASize > 0 then
    AStream.WriteBuffer(AData^, ASize);
end;

class procedure TDoomScriptSaveStream.ReadBytes(const AStream: TStream; const AData: PByte; const ASize: Integer);
begin
  if ASize <= 0 then
    Exit;
  if AStream.Read(AData^, ASize) <> ASize then
    raise EDoomScriptError.Create(SReadPastEnd);
end;

class procedure TDoomScriptSaveStream.WriteInt(const AStream: TStream; const AValue: Integer);
begin
  WriteBytes(AStream, @AValue, SizeOf(AValue));
end;

class procedure TDoomScriptSaveStream.WriteByte(const AStream: TStream; const AValue: Byte);
begin
  WriteBytes(AStream, @AValue, 1);
end;

class procedure TDoomScriptSaveStream.WriteBool(const AStream: TStream; const AValue: Boolean);
begin
  WriteByte(AStream, Ord(AValue));
end;

class procedure TDoomScriptSaveStream.WriteFloat(const AStream: TStream; const AValue: Single);
begin
  WriteBytes(AStream, @AValue, SizeOf(AValue));
end;

class procedure TDoomScriptSaveStream.WriteVec3(const AStream: TStream; const AValue: TIdVec3);
begin
  WriteFloat(AStream, AValue.X);
  WriteFloat(AStream, AValue.Y);
  WriteFloat(AStream, AValue.Z);
end;

class procedure TDoomScriptSaveStream.WriteString(const AStream: TStream; const AValue: AnsiString);
begin
  WriteInt(AStream, Length(AValue));
  if AValue <> '' then
    WriteBytes(AStream, PByte(PAnsiChar(AValue)), Length(AValue));
end;

class procedure TDoomScriptSaveStream.WriteDict(const AStream: TStream; const ADict: TIdDict);
var
  LIndex: Integer;
  LPair: TIdKeyValue;
begin
  if not Assigned(ADict) then
  begin
    WriteInt(AStream, -1);
    Exit;
  end;
  WriteInt(AStream, ADict.GetNumKeyVals);
  for LIndex := 0 to ADict.GetNumKeyVals - 1 do
    if ADict.TryGetKeyVal(LIndex, LPair) then
    begin
      WriteString(AStream, LPair.Key);
      WriteString(AStream, LPair.Value);
    end;
end;

class function TDoomScriptSaveStream.ReadInt(const AStream: TStream): Integer;
begin
  ReadBytes(AStream, @Result, SizeOf(Result));
end;

class function TDoomScriptSaveStream.ReadByte(const AStream: TStream): Byte;
begin
  ReadBytes(AStream, @Result, 1);
end;

class function TDoomScriptSaveStream.ReadBool(const AStream: TStream): Boolean;
begin
  Result := ReadByte(AStream) <> 0;
end;

class function TDoomScriptSaveStream.ReadFloat(const AStream: TStream): Single;
begin
  ReadBytes(AStream, @Result, SizeOf(Result));
end;

class function TDoomScriptSaveStream.ReadVec3(const AStream: TStream): TIdVec3;
begin
  Result.X := ReadFloat(AStream);
  Result.Y := ReadFloat(AStream);
  Result.Z := ReadFloat(AStream);
end;

class function TDoomScriptSaveStream.ReadString(const AStream: TStream): AnsiString;
var
  LLength: Integer;
begin
  LLength := ReadInt(AStream);
  if LLength < 0 then
    raise EDoomScriptError.CreateFmt(SInvalidLength, [LLength]);
  if LLength > AStream.Size - AStream.Position then
    raise EDoomScriptError.Create(SReadPastEnd);
  SetLength(Result, LLength);
  if LLength > 0 then
    ReadBytes(AStream, PByte(PAnsiChar(Result)), LLength);
end;

class procedure TDoomScriptSaveStream.ReadDict(const AStream: TStream; const ADict: TIdDict);
var
  LCount: Integer;
  LIndex: Integer;
  LKey: AnsiString;
  LValue: AnsiString;
begin
  ADict.Clear;
  LCount := ReadInt(AStream);
  for LIndex := 0 to LCount - 1 do
  begin
    LKey := ReadString(AStream);
    LValue := ReadString(AStream);
    ADict.SetValue(LKey, LValue);
  end;
end;

end.
