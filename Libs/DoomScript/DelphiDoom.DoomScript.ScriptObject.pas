{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom script (id Tech 4) - TDoomScriptObject (idScriptObject)    }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): game\script\             }
{  Script_Program.h, Script_Program.cpp. Copyright (C) 1999-2011 id Software   }
{  LLC, a ZeniMax Media company.                                               }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3 or later, with    }
{  the additional terms of the Doom 3 Source Code License (see README.md of    }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.DoomScript.ScriptObject;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.DoomScript.Types, DelphiDoom.DoomScript.Defs,
  DelphiDoom.DoomScript.ScriptProgram;

type
  /// <summary>
  ///   idScriptObject: the in-game data of an object declared in script (the fields of its type and of
  ///   its super types). An entity of the host has one; it has no data until <c>SetType</c>. Every
  ///   access to the data is checked against its size.
  /// </summary>
  TDoomScriptObject = class
  strict private
    FProgram: TDoomScriptProgram;
    FType: TDoomScriptTypeDef;
    FData: TBytes;
  public
    constructor Create(const AProgram: TDoomScriptProgram);
    /// <summary>idScriptObject::Save</summary>
    procedure Save(const AStream: TStream);
    /// <summary>idScriptObject::Restore; raises EDoomScriptError for an unknown type or a different size</summary>
    procedure Restore(const AStream: TStream);
    /// <summary>idScriptObject::Free: drops the data and the type</summary>
    procedure FreeObject;
    /// <summary>
    ///   Allocates the object of a type declared in script and clears it; false (with a warning) if the
    ///   type is unknown or is not an object type
    /// </summary>
    function SetType(const ATypeName: AnsiString): Boolean;
    procedure ClearObject;
    function HasObject: Boolean;
    /// <summary>True when the object has data (what the interpreter asks before a field access)</summary>
    function HasData: Boolean; inline;
    function GetTypeDef: TDoomScriptTypeDef;
    function GetTypeName: AnsiString;
    /// <summary>The function "init" of the type or of a super type; nil if none</summary>
    function GetConstructor: TDoomScriptFunction;
    /// <summary>The function "destroy"</summary>
    function GetDestructor: TDoomScriptFunction;
    function GetFunction(const AName: AnsiString): TDoomScriptFunction;
    /// <summary>
    ///   idScriptObject::GetVariable: the offset of a field with this name and kind in the data, -1 if
    ///   there is none or the kind differs
    /// </summary>
    function GetVariable(const AName: AnsiString; const AKind: TDoomScriptEType): Integer;
    /// <summary>A checked pointer to <c>ASize</c> bytes of the data; raises EDoomScriptMemoryError</summary>
    function DataPtr(const AOffset, ASize: Integer): PByte;
    function DataSize: Integer;
  end;

implementation

uses
  DelphiDoom.DoomScript.SaveStream;

const
  SRestoreType = 'idScriptObject::Restore: failed to restore object of type ''%s''.';
  SRestoreSize = 'idScriptObject::Restore: size of object ''%s'' doesn''t match size in save game.';
  SUnknownType = 'idScriptObject::SetType: Unknown type ''%s''';
  SNotObjectType = 'idScriptObject::SetType: Can''t create object of type ''%s''.  Must be an object type.';
  SFieldOutOfRange = 'idScriptObject: access to %d bytes at %d is outside the object ''%s'' (%d bytes)';

constructor TDoomScriptObject.Create(const AProgram: TDoomScriptProgram);
begin
  inherited Create;
  FProgram := AProgram;
  FType := AProgram.TypeObject;
end;

procedure TDoomScriptObject.FreeObject;
begin
  FData := nil;
  FType := FProgram.TypeObject;
end;

function TDoomScriptObject.HasData: Boolean;
begin
  // Mem_Alloc( 0 ) of the original gives NULL: an object type without fields has no data
  Result := Length(FData) > 0;
end;

function TDoomScriptObject.HasObject: Boolean;
begin
  Result := FType <> FProgram.TypeObject;
end;

function TDoomScriptObject.DataSize: Integer;
begin
  Result := Length(FData);
end;

function TDoomScriptObject.DataPtr(const AOffset, ASize: Integer): PByte;
begin
  if (AOffset < 0) or (ASize < 0) or (AOffset > Length(FData) - ASize) then
    raise EDoomScriptMemoryError.CreateFmt(SFieldOutOfRange, [ASize, AOffset, string(FType.Name), Length(FData)]);
  Result := @FData[AOffset];
end;

procedure TDoomScriptObject.Save(const AStream: TStream);
begin
  if not HasObject then
    // empty string for an uninitialized object
    TDoomScriptSaveStream.WriteString(AStream, '')
  else
  begin
    TDoomScriptSaveStream.WriteString(AStream, FType.Name);
    TDoomScriptSaveStream.WriteInt(AStream, Length(FData));
    TDoomScriptSaveStream.WriteBytes(AStream, PByte(FData), Length(FData));
  end;
end;

procedure TDoomScriptObject.Restore(const AStream: TStream);
var
  LTypeName: AnsiString;
  LSize: Integer;
begin
  LTypeName := TDoomScriptSaveStream.ReadString(AStream);
  // an empty string signals an uninitialized object
  if LTypeName = '' then
    Exit;
  if not SetType(LTypeName) then
    raise EDoomScriptError.CreateFmt(SRestoreType, [string(LTypeName)]);
  LSize := TDoomScriptSaveStream.ReadInt(AStream);
  if LSize <> Length(FData) then
    raise EDoomScriptError.CreateFmt(SRestoreSize, [string(LTypeName)]);
  TDoomScriptSaveStream.ReadBytes(AStream, PByte(FData), LSize);
end;

function TDoomScriptObject.SetType(const ATypeName: AnsiString): Boolean;
var
  LNewType: TDoomScriptTypeDef;
begin
  // lookup the type
  LNewType := FProgram.FindType(ATypeName);
  // only allocate memory if the object type changes
  if LNewType <> FType then
  begin
    FreeObject;
    if not Assigned(LNewType) then
    begin
      if Assigned(FProgram.Log) then
        FProgram.Log.Warning(Format(SUnknownType, [string(ATypeName)]));
      Exit(False);
    end;
    if not LNewType.IsObject then
    begin
      if Assigned(FProgram.Log) then
        FProgram.Log.Warning(Format(SNotObjectType, [string(LNewType.Name)]));
      Exit(False);
    end;
    FType := LNewType;
    SetLength(FData, FType.Size);
  end;
  // init object memory
  ClearObject;
  Result := True;
end;

procedure TDoomScriptObject.ClearObject;
begin
  if HasObject and (Length(FData) > 0) then
    FillChar(FData[0], Length(FData), 0);
end;

function TDoomScriptObject.GetTypeDef: TDoomScriptTypeDef;
begin
  Result := FType;
end;

function TDoomScriptObject.GetTypeName: AnsiString;
begin
  Result := FType.Name;
end;

function TDoomScriptObject.GetConstructor: TDoomScriptFunction;
begin
  Result := GetFunction('init');
end;

function TDoomScriptObject.GetDestructor: TDoomScriptFunction;
begin
  Result := GetFunction('destroy');
end;

function TDoomScriptObject.GetFunction(const AName: AnsiString): TDoomScriptFunction;
begin
  if not HasObject then
    Exit(nil);
  Result := FProgram.FindFunction(AName, FType);
end;

function TDoomScriptObject.GetVariable(const AName: AnsiString; const AKind: TDoomScriptEType): Integer;
var
  LIndex: Integer;
  LPos: Integer;
  LType: TDoomScriptTypeDef;
  LParm: TDoomScriptTypeDef;
begin
  if not HasObject then
    Exit(-1);
  LType := FType;
  repeat
    if LType.SuperClass <> FProgram.TypeObject then
      LPos := LType.SuperClass.Size
    else
      LPos := 0;
    for LIndex := 0 to LType.NumParameters - 1 do
    begin
      LParm := LType.GetParmType(LIndex);
      if LType.GetParmName(LIndex) = AName then
      begin
        if AKind <> LParm.FieldType.Kind then
          Exit(-1);
        Exit(LPos);
      end;
      if LParm.FieldType.IsObject then
        Inc(LPos, 4)
      else
        Inc(LPos, LParm.FieldType.Size);
    end;
    LType := LType.SuperClass;
  until (not Assigned(LType)) or (LType = FProgram.TypeObject);
  Result := -1;
end;

end.
