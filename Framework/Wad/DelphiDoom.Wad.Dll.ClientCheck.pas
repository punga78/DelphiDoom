{******************************************************************************}
{                                                                              }
{  DelphiDoom: WAD library - what a client does with the answers of the DLL    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Wad.Dll.ClientCheck;

interface

uses
  System.SysUtils, DelphiDoom.Wad.Dll.Intf;

type
  /// <summary>Asks the DLL for a text (the buffer of the caller, UTF-8)</summary>
  TWadDllTextFetch = reference to function(ABuffer: PAnsiChar; ABufferSize: Cardinal;
    out ALength: Cardinal): Integer;

  /// <summary>The checks the clients of the DLL share</summary>
  TWadDllClientCheck = class
  public
    /// <summary>
    ///   Does nothing for WADDLL_OK; else raises EWadException (the exception of the library,
    ///   so that code written for the classes of the library works on the DLL) with the
    ///   message the DLL kept
    /// </summary>
    class procedure Check(const ADll: IWadDll; ACode: Integer); static;
    /// <summary>A text from a method that follows the protocol of the texts of the DLL</summary>
    class function Text(const ADll: IWadDll; const AFetch: TWadDllTextFetch): string; static;
  end;

implementation

uses
  DelphiDoom.Wad.Types, DelphiDoom.Wad.Dll.Text;

{ TWadDllClientCheck }

class procedure TWadDllClientCheck.Check(const ADll: IWadDll; ACode: Integer);
var
  LLength: Cardinal;
  LBuffer: TBytes;
  LMessage: string;
begin
  if ACode = WADDLL_OK then
    Exit;
  LMessage := '';
  if (ADll <> nil) and (ADll.GetLastMessage(nil, 0, LLength) = WADDLL_OK) and (LLength > 0) then
  begin
    SetLength(LBuffer, LLength + 1);
    if ADll.GetLastMessage(PAnsiChar(@LBuffer[0]), LLength + 1, LLength) = WADDLL_OK then
      LMessage := TWadDllText.ToText(PAnsiChar(@LBuffer[0]));
  end;
  case ACode of
    WADDLL_ERR_RANGE: LMessage := 'Out of range ' + LMessage;
    WADDLL_ERR_BUFFER_TOO_SMALL: LMessage := 'Buffer too small ' + LMessage;
    WADDLL_ERR_FOREIGN_OBJECT: LMessage := 'The object was not made by this DLL ' + LMessage;
    WADDLL_ERR_INVALID_ARGUMENT: LMessage := 'Invalid argument ' + LMessage;
  end;
  raise EWadException.CreateFmt('WAD DLL (%d): %s', [ACode, Trim(LMessage)]);
end;

class function TWadDllClientCheck.Text(const ADll: IWadDll; const AFetch: TWadDllTextFetch): string;
var
  LLength: Cardinal;
  LBuffer: TBytes;
begin
  Check(ADll, AFetch(nil, 0, LLength));
  if LLength = 0 then
    Exit('');
  SetLength(LBuffer, LLength + 1);
  Check(ADll, AFetch(PAnsiChar(@LBuffer[0]), LLength + 1, LLength));
  Result := TWadDllText.ToText(PAnsiChar(@LBuffer[0]));
end;

end.
