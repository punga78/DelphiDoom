{******************************************************************************}
{                                                                              }
{  DelphiDoom: PAK - the bytes of one entry of a PAK, ZIP or WAD, read in      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Pak.EntryReader;

interface

uses
  System.SysUtils, DelphiDoom.Wad.Intf;

type
  /// <summary>
  ///   An open entry of the PAK file system: the whole entry is read from its source
  ///   when it is opened (a file of a ZIP has to be decompressed anyway) and
  ///   Read and Seek work on those bytes. It never reads past the end of the entry
  /// </summary>
  TPakEntryReader = class
  private
    FData: TBytes;
    FPosition: Integer;
  public
    /// <summary>Raises EWadException when the entry cannot be read</summary>
    constructor Create(const ASource: IWadSource; AIndex: Integer);
    /// <summary>Copies up to Count bytes; returns how many (0 at the end)</summary>
    function Read(var Buffer; Count: Integer): Integer;
    /// <summary>False when APosition is outside the entry</summary>
    function Seek(APosition: Integer): Boolean;
    function Size: Integer;
    property Position: Integer read FPosition;
  end;

implementation

{ TPakEntryReader }

constructor TPakEntryReader.Create(const ASource: IWadSource; AIndex: Integer);
begin
  inherited Create;
  FData := ASource.ReadEntry(AIndex);
  FPosition := 0;
end;

function TPakEntryReader.Read(var Buffer; Count: Integer): Integer;
begin
  Result := Length(FData) - FPosition;
  if Count < Result then
    Result := Count;
  if Result < 0 then
    Result := 0;
  if Result > 0 then
  begin
    Move(FData[FPosition], Buffer, Result);
    Inc(FPosition, Result);
  end;
end;

function TPakEntryReader.Seek(APosition: Integer): Boolean;
begin
  Result := (APosition >= 0) and (APosition <= Length(FData));
  if Result then
    FPosition := APosition;
end;

function TPakEntryReader.Size: Integer;
begin
  Result := Length(FData);
end;

end.
