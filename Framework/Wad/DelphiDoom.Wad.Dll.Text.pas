{******************************************************************************}
{                                                                              }
{  DelphiDoom: WAD library - text across the DLL boundary                      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Wad.Dll.Text;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   Texts of the DLL are UTF-8, zero terminated, in buffers of the caller (the 8 bit
  ///   characters of an old lump name are sent as the UTF-8 of the same characters)
  /// </summary>
  TWadDllText = class
  public
    /// <summary>
    ///   Copies AText to ABuffer (nil only asks the length). Returns WADDLL_OK,
    ///   or WADDLL_ERR_BUFFER_TOO_SMALL when ABufferSize cannot hold it with the terminator
    /// </summary>
    class function CopyOut(const AText: string; ABuffer: PAnsiChar; ABufferSize: Cardinal;
      out ALength: Cardinal): Integer; static;
    /// <summary>The string behind a zero terminated UTF-8 text (nil is the empty string)</summary>
    class function ToText(AText: PAnsiChar): string; static;
  end;

implementation

uses
  DelphiDoom.Wad.Dll.Intf;

{ TWadDllText }

class function TWadDllText.CopyOut(const AText: string; ABuffer: PAnsiChar;
  ABufferSize: Cardinal; out ALength: Cardinal): Integer;
var
  LBytes: TBytes;
begin
  LBytes := TEncoding.UTF8.GetBytes(AText);
  ALength := Length(LBytes);
  if ABuffer = nil then
    Exit(WADDLL_OK);
  if ABufferSize < ALength + 1 then
    Exit(WADDLL_ERR_BUFFER_TOO_SMALL);
  if ALength > 0 then
    Move(LBytes[0], ABuffer^, ALength);
  ABuffer[ALength] := #0;
  Result := WADDLL_OK;
end;

class function TWadDllText.ToText(AText: PAnsiChar): string;
begin
  if AText = nil then
    Exit('');
  Result := UTF8ToString(RawByteString(AText));
end;

end.
