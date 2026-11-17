{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III host library - network addresses of the server lists   }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): net_chan.c       }
{  (NET_StringToAdr, NET_AdrToString, NET_CompareAdr) and win_net.c             }
{  (Sys_StringToAdr). Copyright (C) 1999-2005 Id Software, Inc. This unit is    }
{  derived from the Quake III Arena source code and is therefore available      }
{  under the GNU General Public License, version 2 or (at your option) any      }
{  later version.                                                               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Q3Host.UiNetAddress;

interface

type
  /// <summary>netadrtype_t</summary>
  TQ3NetAddressType = (NaBot, NaBad, NaLoopback, NaBroadcast, NaIp, NaIpx, NaBroadcastIpx);

  /// <summary>netadr_t: the port is in host order (the C keeps it big endian and swaps to print)</summary>
  TQ3NetAddress = record
    AddressType: TQ3NetAddressType;
    Ip: array[0..3] of Byte;
    Ipx: array[0..9] of Byte;
    Port: Word;
  end;

  /// <summary>
  ///   NET_StringToAdr and its friends. Names are not resolved (the C asks the resolver of the machine): only
  ///   "localhost", four decimal numbers and an optional ":port" make an address; anything else is NA_BAD
  /// </summary>
  TQ3NetAddresses = class sealed
  strict private
    class function ParseText(const AText: AnsiString; out AAddress: TQ3NetAddress): Boolean; static;
  public
    const
      PORT_SERVER = 27960;
    /// <summary>NET_StringToAdr: False (and NA_BAD) when the text is not an address</summary>
    class function Parse(const AText: AnsiString; out AAddress: TQ3NetAddress): Boolean; static;
    /// <summary>NET_AdrToString</summary>
    class function ToText(const AAddress: TQ3NetAddress): AnsiString; static;
    /// <summary>NET_CompareAdr (a bad type is never equal; the C also prints a warning)</summary>
    class function Same(const AAddress, AOther: TQ3NetAddress): Boolean; static;
  end;

implementation

uses
  System.SysUtils;

class function TQ3NetAddresses.Parse(const AText: AnsiString; out AAddress: TQ3NetAddress): Boolean;
begin
  Result := ParseText(AText, AAddress);
  if not Result then
  begin
    // the C leaves what the lookup left in the structure; here it is NA_BAD and nothing else
    AAddress := Default(TQ3NetAddress);
    AAddress.AddressType := NaBad;
  end;
end;

class function TQ3NetAddresses.ParseText(const AText: AnsiString; out AAddress: TQ3NetAddress): Boolean;
var
  LBase, LPortText: AnsiString;
  LColon, LPart, LIndex, LValue, LDigits, LPort: Integer;
begin
  AAddress := Default(TQ3NetAddress);
  if AText = 'localhost' then
  begin
    AAddress.AddressType := NaLoopback;
    Exit(True);
  end;
  // look for a port number
  LColon := Pos(':', string(AText));
  LBase := AText;
  LPortText := '';
  if LColon > 0 then
  begin
    LBase := Copy(AText, 1, LColon - 1);
    LPortText := Copy(AText, LColon + 1, MaxInt);
  end;

  AAddress.AddressType := NaBad;
  // Sys_StringToSockaddr: a name that starts with a digit goes to inet_addr (four numbers here), the others
  // to the resolver
  if (LBase = '') or not (LBase[1] in ['0'..'9']) then
    Exit(False);
  LPart := 0;
  LValue := 0;
  LDigits := 0;
  for LIndex := 1 to Length(LBase) + 1 do
    if (LIndex <= Length(LBase)) and (LBase[LIndex] in ['0'..'9']) then
    begin
      LValue := LValue * 10 + Ord(LBase[LIndex]) - Ord('0');
      Inc(LDigits);
      if (LValue > 255) or (LDigits > 3) then
        Exit(False);
    end
    else if ((LIndex > Length(LBase)) or (LBase[LIndex] = '.')) and (LDigits > 0) and (LPart < 4) then
    begin
      AAddress.Ip[LPart] := LValue;
      Inc(LPart);
      LValue := 0;
      LDigits := 0;
    end
    else
      Exit(False);
  if LPart <> 4 then
    Exit(False);
  // inet_addr returns this if out of range
  if (AAddress.Ip[0] = 255) and (AAddress.Ip[1] = 255) and (AAddress.Ip[2] = 255) and (AAddress.Ip[3] = 255) then
    Exit(False);

  AAddress.AddressType := NaIp;
  if LColon > 0 then
  begin
    // atoi: blanks, a sign, digits; the port is the low 16 bits (the cast to short)
    LPort := 0;
    LIndex := 1;
    while (LIndex <= Length(LPortText)) and (LPortText[LIndex] in [' ', #9]) do
      Inc(LIndex);
    LValue := 1;
    if (LIndex <= Length(LPortText)) and (LPortText[LIndex] in ['+', '-']) then
    begin
      if LPortText[LIndex] = '-' then
        LValue := -1;
      Inc(LIndex);
    end;
    while (LIndex <= Length(LPortText)) and (LPortText[LIndex] in ['0'..'9']) do
    begin
      LPort := (LPort * 10 + Ord(LPortText[LIndex]) - Ord('0')) and $FFFF;
      Inc(LIndex);
    end;
    AAddress.Port := Word((LPort * LValue) and $FFFF);
  end
  else
    AAddress.Port := PORT_SERVER;
  Result := True;
end;

class function TQ3NetAddresses.ToText(const AAddress: TQ3NetAddress): AnsiString;
var
  LIndex: Integer;
begin
  case AAddress.AddressType of
    NaLoopback:
      Result := 'loopback';
    NaBot:
      Result := 'bot';
    NaIp:
      Result := AnsiString(Format('%d.%d.%d.%d:%d', [AAddress.Ip[0], AAddress.Ip[1], AAddress.Ip[2],
        AAddress.Ip[3], AAddress.Port]));
  else
    begin
      // the IPX form, for every other type
      Result := '';
      for LIndex := 0 to 3 do
        Result := Result + AnsiString(Format('%.2x', [AAddress.Ip[LIndex]]));
      Result := Result + '.';
      for LIndex := 0 to 9 do
        Result := Result + AnsiString(Format('%.2x', [AAddress.Ipx[LIndex]]));
      Result := Result + AnsiString(Format(':%d', [AAddress.Port]));
    end;
  end;
end;

class function TQ3NetAddresses.Same(const AAddress, AOther: TQ3NetAddress): Boolean;
begin
  if AAddress.AddressType <> AOther.AddressType then
    Exit(False);
  case AAddress.AddressType of
    NaLoopback:
      Result := True;
    NaIp:
      Result := CompareMem(@AAddress.Ip, @AOther.Ip, 4) and (AAddress.Port = AOther.Port);
    NaIpx:
      Result := CompareMem(@AAddress.Ipx, @AOther.Ipx, 10) and (AAddress.Port = AOther.Port);
  else
    Result := False;
  end;
end;

end.
