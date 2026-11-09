{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - the serializer of the script state                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  It is TScriptSerializer of ps_serializer.pas: the interpreter and the log   }
{  come from the constructor. The format of the state in the savegames is      }
{  the same: strings are saved with 2 bytes for each character.                }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ScriptHost.Serializer;

{$I PascalScript.inc}

interface

uses
  System.Classes,
  System.SysUtils,
  ps_defs,
  ps_utils,
  ps_runtime,
  DelphiDoom.Logging.Intf,
  DelphiDoom.ScriptHost.Serializer.Intf;

type
  /// <summary>Saves and loads the global variables of the script of an interpreter</summary>
  TScriptSerializer = class(TInterfacedObject, IScriptSerializer)
  strict private
    FExec: TPSExec;
    FLog: ILog;
    function SaveVariable(const ASaveStream: TStream; ASource: Pointer; AType: TPSTypeRec): Boolean;
    function LoadVariable(const ALoadStream: TStream; ASource: Pointer; AType: TPSTypeRec): Boolean;
  public
    /// <summary>The interpreter is not owned: it must live as long as the serializer</summary>
    constructor Create(const AExec: TPSExec; const ALog: ILog);
    function SaveToFile(const AName: string): Boolean;
    function AppendToFile(const AName: string): Boolean;
    function LoadFromFile(const AName: string): Boolean;
    function LoadFromFilePos(const AName: string; var APosition: Integer): Boolean;
    function SaveToStream(const AStream: TStream): Boolean;
    function LoadFromStream(const AStream: TStream): Boolean;
    function SaveSize: Integer;
  end;

implementation

{ TScriptSerializer }

constructor TScriptSerializer.Create(const AExec: TPSExec; const ALog: ILog);
begin
  inherited Create;
  if not Assigned(AExec) then
    raise EArgumentNilException.Create('AExec');
  if not Assigned(ALog) then
    raise EArgumentNilException.Create('ALog');
  FExec := AExec;
  FLog := ALog;
end;

function TScriptSerializer.SaveVariable(const ASaveStream: TStream; ASource: Pointer;
  AType: TPSTypeRec): Boolean;
var
  LElementCount: Integer;
  LText: string;
  LWideText: WideString;
  LWideChar: WideChar;
  LIndex: Integer;
  LSize: Integer;
  LOffset: Cardinal;
begin
  Result := True;
  case AType.BaseType of
    btU8:
      ASaveStream.Write(TbtU8(ASource^), SizeOf(TbtU8)); //Byte, Boolean
    btS8:
      ASaveStream.Write(TbtS8(ASource^), SizeOf(TbtS8)); //short int
    btU16:
      ASaveStream.Write(TbtU16(ASource^), SizeOf(TbtU16)); // word
    btS16:
      ASaveStream.Write(TbtS16(ASource^), SizeOf(TbtS16)); // smallint
    btU32:
      ASaveStream.Write(TbtU32(ASource^), SizeOf(TbtU32)); //Longword
    btS32:
      ASaveStream.Write(TbtS32(ASource^), SizeOf(TbtS32)); //Integer
    {$IFNDEF PS_NOINT64}
    btS64:
      ASaveStream.Write(TbtS64(ASource^), SizeOf(TbtS64)); //Int64
    {$ENDIF}
    btChar:
      ASaveStream.Write(TbtChar(ASource^), SizeOf(TbtChar)); //Char
    btWideChar:
      ASaveStream.Write(TbtWideChar(ASource^), SizeOf(TbtWideChar)); //WideChar
    btSingle:
      ASaveStream.Write(TbtSingle(ASource^), SizeOf(TbtSingle));
    btDouble:
      ASaveStream.Write(TbtDouble(ASource^), SizeOf(TbtDouble));
    btExtended:
      ASaveStream.Write(TbtExtended(ASource^), SizeOf(TbtExtended));
    btCurrency:
      ASaveStream.Write(TbtCurrency(ASource^), SizeOf(TbtCurrency));
    btString:
      begin
        LText := string(TbtString(ASource^));
        LElementCount := Length(LText);
        ASaveStream.Write(LElementCount, SizeOf(LElementCount));
        for LIndex := 1 to LElementCount do
          ASaveStream.Write(LText[LIndex], SizeOf(Char));
      end;
    btWideString:
      begin
        LWideText := TbtWideString(ASource^);
        LElementCount := Length(LWideText);
        ASaveStream.Write(LElementCount, SizeOf(LElementCount));
        for LIndex := 1 to LElementCount do
        begin
          LWideChar := LWideText[LIndex];
          ASaveStream.Write(LWideChar, SizeOf(WideChar));
        end;
      end;
    btUnicodeString:
      begin
        LWideText := TbtUnicodeString(ASource^);
        LElementCount := Length(LWideText);
        ASaveStream.Write(LElementCount, SizeOf(LElementCount));
        for LIndex := 1 to LElementCount do
        begin
          LWideChar := LWideText[LIndex];
          ASaveStream.Write(LWideChar, SizeOf(WideChar));
        end;
      end;
    btStaticArray:
      begin
        LElementCount := TPSTypeRec_StaticArray(AType).Size;
        ASaveStream.Write(LElementCount, SizeOf(LElementCount));
        LSize := TPSTypeRec_Array(AType).ArrayType.RealSize;
        for LIndex := 0 to LElementCount - 1 do
        begin
          LOffset := LSize * LIndex;
          SaveVariable(ASaveStream, Pointer(IPointer(ASource) + LOffset),
            TPSTypeRec_Array(AType).ArrayType);
        end;
      end;
    btArray:
      begin
        LElementCount := PSDynArrayGetLength(Pointer(ASource^), AType);
        ASaveStream.Write(LElementCount, SizeOf(LElementCount));
        LSize := TPSTypeRec_Array(AType).ArrayType.RealSize;
        for LIndex := 0 to LElementCount - 1 do
        begin
          LOffset := LSize * LIndex;
          SaveVariable(ASaveStream, Pointer(IPointer(ASource^) + LOffset),
            TPSTypeRec_Array(AType).ArrayType);
        end;
      end;
    btRecord:
      begin
        LElementCount := TPSTypeRec_Record(AType).FieldTypes.Count;
        ASaveStream.Write(LElementCount, SizeOf(LElementCount));
        for LIndex := 0 to LElementCount - 1 do
        begin
          LOffset := Cardinal(TPSTypeRec_Record(AType).RealFieldOffsets[LIndex]);
          SaveVariable(ASaveStream, Pointer(IPointer(ASource) + LOffset),
            TPSTypeRec_Record(AType).FieldTypes[LIndex]);
        end;
      end;
    btSet:
      begin
        LElementCount := TPSTypeRec_Set(AType).RealSize;
        ASaveStream.Write(LElementCount, SizeOf(LElementCount));
        ASaveStream.Write(ASource^, LElementCount);
      end;
  end;
end;

function TScriptSerializer.LoadVariable(const ALoadStream: TStream; ASource: Pointer;
  AType: TPSTypeRec): Boolean;
var
  LElementCount: Integer;
  LText: string;
  LWideText: WideString;
  LWideChar: WideChar;
  LIndex: Integer;
  LSize: Integer;
  LOffset: Cardinal;
begin
  Result := True;
  case AType.BaseType of
    btU8:
      ALoadStream.Read(TbtU8(ASource^), SizeOf(TbtU8)); //Byte, Boolean
    btS8:
      ALoadStream.Read(TbtS8(ASource^), SizeOf(TbtS8)); //shortint
    btU16:
      ALoadStream.Read(TbtU16(ASource^), SizeOf(TbtU16)); //Longword
    btS16:
      ALoadStream.Read(TbtS16(ASource^), SizeOf(TbtS16)); //Integer
    btU32:
      ALoadStream.Read(TbtU32(ASource^), SizeOf(TbtU32)); //Longword
    btS32:
      ALoadStream.Read(TbtS32(ASource^), SizeOf(TbtS32)); //Integer
    {$IFNDEF PS_NOINT64}
    btS64:
      ALoadStream.Read(TbtS64(ASource^), SizeOf(TbtS64)); //Int64
    {$ENDIF}
    btChar:
      ALoadStream.Read(TbtChar(ASource^), SizeOf(TbtChar)); //Char
    btWideChar:
      ALoadStream.Read(TbtWideChar(ASource^), SizeOf(TbtWideChar)); //WideChar
    btSingle:
      ALoadStream.Read(TbtSingle(ASource^), SizeOf(TbtSingle)); // Single
    btDouble:
      ALoadStream.Read(TbtDouble(ASource^), SizeOf(TbtDouble)); // Double
    btExtended:
      ALoadStream.Read(TbtExtended(ASource^), SizeOf(TbtExtended)); // Extended
    btCurrency:
      ALoadStream.Read(TbtCurrency(ASource^), SizeOf(TbtCurrency)); // Currency
    btString:
      begin
        ALoadStream.Read(LElementCount, SizeOf(LElementCount));
        SetLength(LText, LElementCount);
        for LIndex := 1 to LElementCount do
          ALoadStream.Read(LText[LIndex], SizeOf(Char));
        TbtString(ASource^) := TbtString(LText);
      end;
    btWideString:
      begin
        ALoadStream.Read(LElementCount, SizeOf(LElementCount));
        SetLength(LWideText, LElementCount);
        for LIndex := 1 to LElementCount do
        begin
          ALoadStream.Read(LWideChar, SizeOf(WideChar));
          LWideText[LIndex] := LWideChar;
        end;
        TbtWideString(ASource^) := LWideText;
      end;
    btUnicodeString:
      begin
        ALoadStream.Read(LElementCount, SizeOf(LElementCount));
        SetLength(LWideText, LElementCount);
        for LIndex := 1 to LElementCount do
        begin
          ALoadStream.Read(LWideChar, SizeOf(WideChar));
          LWideText[LIndex] := LWideChar;
        end;
        TbtUnicodeString(ASource^) := LWideText;
      end;
    btStaticArray:
      begin
        ALoadStream.Read(LElementCount, SizeOf(LElementCount));
        if LElementCount <> TPSTypeRec_StaticArray(AType).Size then
        begin
          FLog.Warning(Format('TScriptSerializer.LoadVariable(): Array "%s" element count does not match saved count'#13#10,
            [string(TPSTypeRec_StaticArray(AType).ExportName)]));
          Exit(False);
        end;
        LSize := TPSTypeRec_Array(AType).ArrayType.RealSize;
        for LIndex := 0 to LElementCount - 1 do
        begin
          LOffset := LSize * LIndex;
          if not LoadVariable(ALoadStream, Pointer(IPointer(ASource) + LOffset),
            TPSTypeRec_Array(AType).ArrayType) then
            Exit(False);
        end;
      end;
    btArray:
      begin
        ALoadStream.Read(LElementCount, SizeOf(LElementCount));
        PSDynArraySetLength(Pointer(ASource^), AType, LElementCount);
        LSize := TPSTypeRec_Array(AType).ArrayType.RealSize;
        for LIndex := 0 to LElementCount - 1 do
        begin
          LOffset := LSize * LIndex;
          if not LoadVariable(ALoadStream, Pointer(IPointer(ASource^) + LOffset),
            TPSTypeRec_Array(AType).ArrayType) then
            Exit(False);
        end;
      end;
    btRecord:
      begin
        ALoadStream.Read(LElementCount, SizeOf(LElementCount));
        LSize := TPSTypeRec_Record(AType).FieldTypes.Count;
        if LElementCount <> LSize then
        begin
          FLog.Warning(Format('TScriptSerializer.LoadVariable(): Record "%s" element count does not match saved count'#13#10,
            [string(TPSTypeRec_Record(AType).ExportName)]));
          Exit(False);
        end;
        for LIndex := 0 to LElementCount - 1 do
        begin
          LOffset := Cardinal(TPSTypeRec_Record(AType).RealFieldOffsets[LIndex]);
          if not LoadVariable(ALoadStream, Pointer(IPointer(ASource) + LOffset),
            TPSTypeRec_Record(AType).FieldTypes[LIndex]) then
            Exit(False);
        end;
      end;
    btSet:
      begin
        ALoadStream.Read(LElementCount, SizeOf(LElementCount));
        LSize := TPSTypeRec_Set(AType).RealSize;
        if LElementCount <> LSize then
        begin
          FLog.Warning(Format('TScriptSerializer.LoadVariable(): Set "%s" element count does not match saved count'#13#10,
            [string(TPSTypeRec_Set(AType).ExportName)]));
          Exit(False);
        end;
        ALoadStream.Read(ASource^, LElementCount);
      end;
  end;
end;

function TScriptSerializer.SaveToFile(const AName: string): Boolean;
var
  LStream: TFileStream;
begin
  Result := True;
  try
    LStream := TFileStream.Create(AName, fmCreate);
    if not SaveToStream(LStream) then
      Result := False;
    LStream.Free;
  except
    Result := False;
  end;
end;

function TScriptSerializer.AppendToFile(const AName: string): Boolean;
var
  LStream: TFileStream;
begin
  Result := True;
  try
    LStream := TFileStream.Create(AName, fmOpenReadWrite);
    LStream.Position := LStream.Size;
    if not SaveToStream(LStream) then
      Result := False;
    LStream.Free;
  except
    Result := False;
  end;
end;

function TScriptSerializer.LoadFromFile(const AName: string): Boolean;
var
  LStream: TFileStream;
begin
  Result := True;
  try
    LStream := TFileStream.Create(AName, fmOpenRead or fmShareDenyWrite);
    try
      if not LoadFromStream(LStream) then
        Result := False;
    finally
      LStream.Free;
    end;
  except
    Result := False;
  end;
end;

function TScriptSerializer.LoadFromFilePos(const AName: string; var APosition: Integer): Boolean;
var
  LStream: TFileStream;
begin
  Result := True;
  try
    LStream := TFileStream.Create(AName, fmOpenRead or fmShareDenyWrite);
    try
      LStream.Position := APosition;
      if not LoadFromStream(LStream) then
        Result := False;
      APosition := LStream.Position;
    finally
      LStream.Free;
    end;
  except
    Result := False;
  end;
end;

function TScriptSerializer.SaveToStream(const AStream: TStream): Boolean;
var
  LElementCount: Integer;
  LIndex: Integer;
  LVariable: PIFVariant;
  LStart: Integer;
  LEnd: Integer;
  LSize: Integer;
begin
  LStart := AStream.Position;
  LSize := 0;
  AStream.Write(LSize, SizeOf(LSize));

  Result := True;
  try
    LElementCount := FExec.GetVarCount;
    AStream.Write(LElementCount, SizeOf(LElementCount));
    for LIndex := 0 to LElementCount - 1 do
    begin
      LVariable := FExec.GetVarNo(LIndex);
      if not SaveVariable(AStream, @PPSVariantData(LVariable).Data, LVariable.FType) then
        Exit(False);
    end;
    LEnd := AStream.Position;
    AStream.Position := LStart;
    LSize := LEnd - LStart - SizeOf(LSize);
    AStream.Write(LSize, SizeOf(LSize));
    AStream.Position := LEnd;
  except
    Result := False;
  end;
end;

function TScriptSerializer.LoadFromStream(const AStream: TStream): Boolean;
var
  LElementCount: Integer;
  LIndex: Integer;
  LVariable: PIFVariant;
  LStart: Integer;
  LEnd: Integer;
  LSize: Integer;
begin
  LStart := AStream.Position;
  AStream.Read(LSize, SizeOf(LSize));
  AStream.Read(LElementCount, SizeOf(LElementCount));
  if LElementCount <> FExec.GetVarCount then
  begin
    FLog.Warning(Format('TScriptSerializer.LoadFromStream(): Variable count (%d) does not match saved variables count (%d)'#13#10,
      [FExec.GetVarCount, LElementCount]));
    Exit(False);
  end;

  Result := True;
  try
    for LIndex := 0 to FExec.GetVarCount - 1 do
    begin
      LVariable := FExec.GetVarNo(LIndex);
      if not LoadVariable(AStream, @PPSVariantData(LVariable).Data, LVariable.FType) then
        Exit(False);
    end;
    LEnd := AStream.Position;
    if LSize <> LEnd - LStart - SizeOf(LSize) then
    begin
      FLog.Warning('TScriptSerializer.LoadFromStream(): Invalid stream size'#13#10);
      Exit(False);
    end;
  except
    Result := False;
  end;
end;

function TScriptSerializer.SaveSize: Integer;
var
  LStream: TMemoryStream;
begin
  Result := 0;
  LStream := TMemoryStream.Create;
  try
    if SaveToStream(LStream) then
      Result := LStream.Size;
  finally
    LStream.Free;
  end;
end;

end.
