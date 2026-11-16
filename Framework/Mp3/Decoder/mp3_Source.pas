{******************************************************************************}
{                                                                              }
{  DelphiDoom: mp3 - byte source read by the bit stream of the decoder         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit mp3_Source;
{$I Mp3Codegen.inc}

// Replaces the use of TDStream of IdTech1\Common\d_delphi.pas (issue #224): the decoder
// needs only Read, Seek, Size, Position and IOResult of its input.

interface

const
  sFromBeginning = 0;
  sFromCurrent = 1;
  sFromEnd = 2;

type
  /// <summary>
  ///   Source of bytes read by the bit stream of the decoder
  /// </summary>
  TMp3Source = class
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

implementation

{ TMp3Source }

constructor TMp3Source.Create;
begin
  inherited Create;
  FIOResult := 0;
end;

function TMp3Source.IOResult: Integer;
begin
  Result := FIOResult;
  FIOResult := 0;
end;

end.
