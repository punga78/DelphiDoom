{******************************************************************************}
{                                                                              }
{  DelphiDoom: XMI - the chunks of an IFF file                                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xmi.Iff;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   A chunk found in the data: its name, the type of the group it opens
  ///   (FORM, CAT...), where its content starts and how long it is
  /// </summary>
  TXmiIffNode = record
    Name: AnsiString;
    Sub: AnsiString;
    DataOffset: Cardinal;
    Size: Cardinal;
  end;

  TXmiIffNodes = TArray<TXmiIffNode>;

  /// <summary>
  ///   Reads the chunks of the Electronic Arts IFF format (big endian sizes,
  ///   chunks padded to an even size), the container of XMIDI
  /// </summary>
  TXmiIff = class
  public
    /// <summary>
    ///   The chunks that follow one another from AOffset in a part of the data
    ///   AMaxSize bytes long. The groups are not entered: read their content
    ///   with another call. Stops at the first name that is not four printable
    ///   characters
    /// </summary>
    class function GetNodes(const AData: TBytes; AOffset,
      AMaxSize: Cardinal): TXmiIffNodes; static;

    /// <summary>
    ///   The nodes with that name and, if given, that group type
    /// </summary>
    class function Search(const ANodes: TXmiIffNodes; const AName: AnsiString;
      const ASub: AnsiString = ''): TXmiIffNodes; static;

    class function Count(const ANodes: TXmiIffNodes; const AName: AnsiString;
      const ASub: AnsiString = ''): Integer; static;
  end;

implementation

const
  // Chunks that contain other chunks
  GROUP_NAMES: array[0..30] of AnsiString = (
    'FORM', 'FOR1', 'FOR2', 'FOR3', 'FOR4', 'FOR5', 'FOR6', 'FOR7', 'FOR8',
    'FOR9', 'CAT ', 'CAT1', 'CAT2', 'CAT3', 'CAT4', 'CAT5', 'CAT6', 'CAT7',
    'CAT8', 'CAT9', 'LIST', 'LIS1', 'LIS2', 'LIS3', 'LIS4', 'LIS5', 'LIS6',
    'LIS7', 'LIS8', 'LIS9', 'PROP');

function IsGroupName(const AName: AnsiString): Boolean;
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(GROUP_NAMES) do
    if GROUP_NAMES[LIndex] = AName then
      Exit(True);

  Result := False;
end;

function IsChunkName(const AName: AnsiString): Boolean;
var
  LIndex: Integer;
begin
  Result := Length(AName) = 4;
  if not Result then
    Exit;

  for LIndex := 1 to 4 do
    if (Byte(AName[LIndex]) < $20) or (Byte(AName[LIndex]) > $7E) then
      Exit(False);
end;

{ TXmiIff }

class function TXmiIff.GetNodes(const AData: TBytes; AOffset,
  AMaxSize: Cardinal): TXmiIffNodes;
var
  LPosition: Cardinal;
  LCount: Integer;
  LName: AnsiString;
  LSize: Cardinal;
  LIsGroup: Boolean;

  // Reads relative to AOffset; beyond AMaxSize (or the data) it gives zeros
  function NextByte: Byte;
  var
    LAbsolute: Int64;
  begin
    LAbsolute := Int64(AOffset) + LPosition;
    if (LPosition < AMaxSize) and (LAbsolute < Length(AData)) then
      Result := AData[LAbsolute]
    else
      Result := 0;
    Inc(LPosition);
  end;

  function NextName: AnsiString;
  var
    LIndex: Integer;
  begin
    SetLength(Result, 4);
    for LIndex := 1 to 4 do
      Result[LIndex] := AnsiChar(NextByte);
  end;

  function NextSize: Cardinal;
  begin
    Result := Cardinal(NextByte) shl 24;
    Result := Result or (Cardinal(NextByte) shl 16);
    Result := Result or (Cardinal(NextByte) shl 8);
    Result := Result or NextByte;
  end;

begin
  Result := nil;
  LCount := 0;
  LPosition := 0;
  while LPosition < AMaxSize do
  begin
    LName := NextName;
    if not IsChunkName(LName) then
      Break;

    LSize := NextSize;
    Inc(LCount);
    SetLength(Result, LCount);
    Result[LCount - 1].Name := LName;

    LIsGroup := (LSize >= 4) and IsGroupName(LName);
    if LIsGroup then
    begin
      Result[LCount - 1].Sub := NextName;
      Result[LCount - 1].DataOffset := AOffset + LPosition;
      Result[LCount - 1].Size := LSize - 4;
      // A group is not skipped: its content comes right after its type
      Inc(LPosition, LSize - 4);
      Continue;
    end;

    Result[LCount - 1].Sub := '';
    Result[LCount - 1].DataOffset := AOffset + LPosition;
    Result[LCount - 1].Size := LSize;
    if Odd(LSize) then
      Inc(LPosition, LSize + 1)
    else
      Inc(LPosition, LSize);
  end;
end;

class function TXmiIff.Search(const ANodes: TXmiIffNodes;
  const AName: AnsiString; const ASub: AnsiString): TXmiIffNodes;
var
  LIndex: Integer;
  LCount: Integer;
begin
  Result := nil;
  LCount := 0;
  for LIndex := 0 to High(ANodes) do
    if (ANodes[LIndex].Name = AName) and
       ((ASub = '') or (ANodes[LIndex].Sub = ASub)) then
    begin
      Inc(LCount);
      SetLength(Result, LCount);
      Result[LCount - 1] := ANodes[LIndex];
    end;
end;

class function TXmiIff.Count(const ANodes: TXmiIffNodes;
  const AName: AnsiString; const ASub: AnsiString): Integer;
begin
  Result := Length(Search(ANodes, AName, ASub));
end;

end.
