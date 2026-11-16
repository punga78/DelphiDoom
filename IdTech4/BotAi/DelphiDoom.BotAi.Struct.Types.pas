{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - the description of a structure of a configuration file }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): fielddef_t,         }
{  structdef_t and the FT_ constants of code\botlib\l_struct.h. Based on the   }
{  Quake III Arena GPL Source Code (id Software).                              }
{  Copyright (C) 1999-2005 Id Software, Inc.                                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Struct.Types;

interface

const
  /// <summary>MAX_STRINGFIELD: the size of a text field (char [MAX_STRINGFIELD])</summary>
  MAX_STRINGFIELD = 80;

  /// <summary>The field types (FT_CHAR ... FT_STRUCT)</summary>
  FT_CHAR = 1;
  FT_INT = 2;
  FT_FLOAT = 3;
  FT_STRING = 4;
  FT_STRUCT = 6;
  /// <summary>FT_TYPE: the mask that clears the sub types</summary>
  FT_TYPE = $00FF;
  /// <summary>The sub types</summary>
  FT_ARRAY = $0100;
  FT_BOUNDED = $0200;
  FT_UNSIGNED = $0400;

type
  TBotStructDefinition = class;

  /// <summary>
  ///   fielddef_t: a field of a structure. The offset is the one of the C structure (the structures
  ///   are packed records with the layout of the C compiler), so a buffer of bytes is read and written
  ///   exactly as the original reads and writes memory.
  /// </summary>
  TBotFieldDefinition = record
    Name: AnsiString;
    Offset: Integer;
    FieldType: Integer;
    /// <summary>maxarray: the number of elements of an array field</summary>
    MaxArray: Integer;
    FloatMin: Single;
    FloatMax: Single;
    SubStruct: TBotStructDefinition;
    /// <summary>A field without bounds and without sub structure: {name, offset, type, maxarray}</summary>
    class function Make(const AName: AnsiString; const AOffset, AFieldType: Integer;
      const AMaxArray: Integer = 0): TBotFieldDefinition; static;
  end;

  /// <summary>structdef_t: the size of the structure and its fields</summary>
  TBotStructDefinition = class
  strict private
    FSize: Integer;
    FFields: TArray<TBotFieldDefinition>;
  public
    constructor Create(const ASize: Integer; const AFields: TArray<TBotFieldDefinition>);
    /// <summary>FindField: the field with the name, nil if there is none</summary>
    function FindField(const AName: AnsiString; out AField: TBotFieldDefinition): Boolean;
    property Size: Integer read FSize;
    property Fields: TArray<TBotFieldDefinition> read FFields;
  end;

implementation

{ TBotFieldDefinition }

class function TBotFieldDefinition.Make(const AName: AnsiString; const AOffset, AFieldType, AMaxArray: Integer): TBotFieldDefinition;
begin
  Result := Default(TBotFieldDefinition);
  Result.Name := AName;
  Result.Offset := AOffset;
  Result.FieldType := AFieldType;
  Result.MaxArray := AMaxArray;
end;

{ TBotStructDefinition }

constructor TBotStructDefinition.Create(const ASize: Integer; const AFields: TArray<TBotFieldDefinition>);
begin
  inherited Create;
  FSize := ASize;
  FFields := AFields;
end;

function TBotStructDefinition.FindField(const AName: AnsiString; out AField: TBotFieldDefinition): Boolean;
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(FFields) do
  begin
    if FFields[LIndex].Name = AName then
    begin
      AField := FFields[LIndex];
      Exit(True);
    end;
  end;
  AField := Default(TBotFieldDefinition);
  Result := False;
end;

end.
