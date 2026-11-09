{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom formats library - WORLD.DAT, the polygons of the globe      }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xcom.WorldReader;

interface

uses
  System.SysUtils, DelphiDoom.Xcom.Types, DelphiDoom.Xcom.Intf;

type
  /// <summary>
  ///   RuleGlobe::loadDat: polygons of 10 signed 16 bit words: longitude and latitude of 3 or 4 points (the fourth
  ///   is there when the word 6 is not -1), the texture in the word 8. The angles are in eighths of a degree
  ///   and become radians in a double, the way fmath.h does it (deg * 0.125 * pi / 180)
  /// </summary>
  TXcomWorldReader = class(TInterfacedObject, IXcomWorldReader)
  public
    function Read(const ABytes: TBytes): TArray<TXcomWorldPolygon>;
    function ToRadians(ADegrees: Integer): Double;
  end;

implementation

const
  PI_DOUBLE: Double = 3.14159265358979323846;

{ TXcomWorldReader }

function TXcomWorldReader.ToRadians(ADegrees: Integer): Double;
var
  LEighths: Double;
  LScaled: Double;
begin
  // every step stored in a double: the FPU of the 32 bit programs would keep 64 bits of mantissa between them
  LEighths := ADegrees * 0.125;
  LScaled := LEighths * PI_DOUBLE;
  Result := LScaled / 180.0;
end;

function TXcomWorldReader.Read(const ABytes: TBytes): TArray<TXcomWorldPolygon>;
var
  LCount: Integer;
  LIndex: Integer;
  LRecord: TXcomWorldRecord;
  LPoint: Integer;
begin
  LCount := Length(ABytes) div XCOM_WORLD_RECORD_BYTES;
  SetLength(Result, LCount);
  for LIndex := 0 to LCount - 1 do
  begin
    Move(ABytes[LIndex * XCOM_WORLD_RECORD_BYTES], LRecord, XCOM_WORLD_RECORD_BYTES);
    FillChar(Result[LIndex], SizeOf(TXcomWorldPolygon), 0);
    if LRecord.Values[6] <> -1 then
      Result[LIndex].Points := 4
    else
      Result[LIndex].Points := 3;
    for LPoint := 0 to Result[LIndex].Points - 1 do
    begin
      Result[LIndex].Longitude[LPoint] := ToRadians(LRecord.Values[LPoint * 2]);
      Result[LIndex].Latitude[LPoint] := ToRadians(LRecord.Values[LPoint * 2 + 1]);
    end;
    Result[LIndex].Texture := LRecord.Values[8];
  end;
end;

end.
