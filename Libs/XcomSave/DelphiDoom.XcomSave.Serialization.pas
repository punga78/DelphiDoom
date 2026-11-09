{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom saved game library - the small binary and text numbers of   }
{  the saved game (SerializationHelper)                                         }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSave.Serialization;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Types, DelphiDoom.Yaml.Convert;

type
  /// <summary>An unsupported size or a value that does not fit (the asserts of the C++)</summary>
  EXcomSerializationException = class(Exception);

  /// <summary>
  ///   serializeInt, unserializeInt and serializeDouble: integers of one, two or four bytes in the byte order of
  ///   the machine that wrote them (little endian here, as every platform OpenXcom runs on) and doubles as text
  /// </summary>
  TXcomSerialization = class
  public
    /// <summary>
    ///   unserializeInt: the number of ASizeKey bytes at AOffset: one byte unsigned, two bytes signed, four bytes
    ///   as the unsigned number cast to int. Other sizes are EXcomSerializationException
    /// </summary>
    class function UnserializeInt(const ABuffer: TBytes; AOffset: Integer; ASizeKey: Byte): Integer; static;
    /// <summary>
    ///   serializeInt: writes a number of ASizeKey bytes (the low byte for one; the C++ asserts the value is below
    ///   256 for one byte and below 65536 for two); other sizes and values that do not fit are
    ///   EXcomSerializationException
    /// </summary>
    class procedure SerializeInt(var ABuffer: TBytes; AOffset: Integer; ASizeKey: Byte; AValue: Integer); static;
    /// <summary>serializeDouble: the text of a stream with 17 digits of precision (%.17g)</summary>
    class function SerializeDouble(AValue: Double): string; static;
  end;

implementation

{ TXcomSerialization }

class function TXcomSerialization.UnserializeInt(const ABuffer: TBytes; AOffset: Integer;
  ASizeKey: Byte): Integer;
begin
  case ASizeKey of
    1:
      Result := ABuffer[AOffset];
    2:
      Result := SmallInt(Word(ABuffer[AOffset]) or (Word(ABuffer[AOffset + 1]) shl 8));
    4:
      Result := Integer(Cardinal(ABuffer[AOffset]) or (Cardinal(ABuffer[AOffset + 1]) shl 8) or
        (Cardinal(ABuffer[AOffset + 2]) shl 16) or (Cardinal(ABuffer[AOffset + 3]) shl 24));
  else
    raise EXcomSerializationException.CreateFmt('Xcom: unserializeInt does not read %d bytes', [ASizeKey]);
  end;
end;

class procedure TXcomSerialization.SerializeInt(var ABuffer: TBytes; AOffset: Integer; ASizeKey: Byte;
  AValue: Integer);
begin
  case ASizeKey of
    1:
      begin
        if AValue >= 256 then
          raise EXcomSerializationException.CreateFmt('Xcom: %d does not fit in one byte', [AValue]);
        ABuffer[AOffset] := Byte(AValue and $FF);
      end;
    2:
      begin
        if AValue >= 65536 then
          raise EXcomSerializationException.CreateFmt('Xcom: %d does not fit in two bytes', [AValue]);
        ABuffer[AOffset] := Byte(AValue and $FF);
        ABuffer[AOffset + 1] := Byte((AValue shr 8) and $FF);
      end;
    4:
      begin
        ABuffer[AOffset] := Byte(AValue and $FF);
        ABuffer[AOffset + 1] := Byte((AValue shr 8) and $FF);
        ABuffer[AOffset + 2] := Byte((AValue shr 16) and $FF);
        ABuffer[AOffset + 3] := Byte((AValue shr 24) and $FF);
      end;
  else
    raise EXcomSerializationException.CreateFmt('Xcom: serializeInt does not write %d bytes', [ASizeKey]);
  end;
end;

class function TXcomSerialization.SerializeDouble(AValue: Double): string;
begin
  Result := YamlTextToString(TYamlConvert.FormatGeneral(AValue, 17));
end;

end.
