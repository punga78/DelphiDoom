{******************************************************************************}
{                                                                              }
{  DelphiDoom: ACS compiler library - the strings of the script                 }
{  Copyright (C) 1995 Raven Software, Corp. (original ACC 1.10)                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Acs.StringTable;

interface

uses
  DelphiDoom.Acs.Types, DelphiDoom.Acs.Diagnostics, DelphiDoom.Acs.ObjectWriter;

type
  /// <summary>A string is stored once, whatever the times the script uses it; its number is the order of the first use</summary>
  TAcsStringTable = class
  private
    FDiagnostics: TAcsDiagnostics;
    FNames: array[0..MAX_STRINGS - 1] of string;
    FAddresses: array[0..MAX_STRINGS - 1] of Integer;
    FCount: Integer;
  public
    constructor Create(const ADiagnostics: TAcsDiagnostics);
    property Count: Integer read FCount;
    /// <summary>The number of the string; it is added if it is new</summary>
    function Find(const AName: string): Integer;
    /// <summary>Writes the strings and pads them to a multiple of 4 bytes</summary>
    procedure WriteStrings(const AWriter: TAcsObjectWriter);
    /// <summary>Writes how many strings there are and the address of each</summary>
    procedure WriteList(const AWriter: TAcsObjectWriter);
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Acs.ErrorCodes;

{ TAcsStringTable }

constructor TAcsStringTable.Create(const ADiagnostics: TAcsDiagnostics);
begin
  inherited Create;
  FDiagnostics := ADiagnostics;
end;

function TAcsStringTable.Find(const AName: string): Integer;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FCount - 1 do
    if FNames[LIndex] = AName then
    begin
      Result := LIndex;
      Exit;
    end;

  if FCount = MAX_STRINGS then
    FDiagnostics.Fail(ERR_TOO_MANY_STRINGS, True, 'Current maximum: %d', [MAX_STRINGS]);

  FNames[FCount] := AName;
  Result := FCount;
  Inc(FCount);
end;

procedure TAcsStringTable.WriteStrings(const AWriter: TAcsObjectWriter);
var
  LIndex: Integer;
  LPadding: TBytes;
begin
  for LIndex := 0 to FCount - 1 do
  begin
    FAddresses[LIndex] := AWriter.Address;
    AWriter.AppendString(FNames[LIndex]);
  end;
  if AWriter.Address mod 4 <> 0 then
  begin
    // align to 4 bytes
    SetLength(LPadding, 4 - (AWriter.Address mod 4));
    AWriter.AppendBytes(LPadding);
  end;
end;

procedure TAcsStringTable.WriteList(const AWriter: TAcsObjectWriter);
var
  LIndex: Integer;
begin
  AWriter.AppendLong(LongWord(FCount));
  for LIndex := 0 to FCount - 1 do
    AWriter.AppendLong(LongWord(FAddresses[LIndex]));
end;

end.
