{******************************************************************************}
{                                                                              }
{  DelphiDoom: mp3 - minimal stand-in for Common\d_delphi.pas                  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit d_delphi;

// The units of Libs\Mp3\Decoder use d_delphi for a handful of declarations. The real
// unit is huge and drags the whole engine, so the mp3 DLL and its tests
// compile against this one instead (it must come first in the unit search
// path, or be listed with its path in the project). Declarations here have
// the same names and signatures as in Common\d_delphi.pas.

interface

const
  sFromBeginning = 0;
  sFromCurrent = 1;
  sFromEnd = 2;

type
  TByteArray = packed array[0..$7FFF] of Byte;
  PByteArray = ^TByteArray;

  /// <summary>
  ///   Source of bytes read by the bit stream of the decoder
  /// </summary>
  TDStream = class
  protected
    FIOResult: Integer;
  public
    constructor Create;
    function Read(var Buffer; Count: Longint): Longint; virtual; abstract;
    function Write(const Buffer; Count: Longint): Longint; virtual; abstract;
    function Seek(Offset: Longint; Origin: Word): Longint; virtual; abstract;
    function Size: Longint; virtual; abstract;
    function Position: Integer; virtual; abstract;
    function IOResult: Integer;
  end;

/// <summary>
///   Frees an object and clears the variable that holds it
/// </summary>
procedure FreeAndNil(var Obj);

implementation

{ TDStream }

constructor TDStream.Create;
begin
  inherited Create;
  FIOResult := 0;
end;

function TDStream.IOResult: Integer;
begin
  Result := FIOResult;
  FIOResult := 0;
end;

procedure FreeAndNil(var Obj);
var
  LTemp: TObject;
begin
  LTemp := TObject(Obj);
  Pointer(Obj) := nil;
  LTemp.Free;
end;

end.
