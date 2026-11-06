{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Wad library - files built in memory                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Wad.Helpers;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, DelphiDoom.Wad.Types, DelphiDoom.Wad.Intf;

type
  TWadTestHelpers = class
  public
    class function Bytes(const AText: string): TBytes; static;
    /// <summary>A PWAD with the given lumps, made by the builder</summary>
    class function MakeWad(const ANames: array of string; const AData: array of TBytes;
      AKind: TWadKind = TWadKind.PWad): TBytes; static;
    /// <summary>A PAK made by hand: 'PACK', the directory at the end</summary>
    class function MakePak(const ANames: array of string; const AData: array of TBytes): TBytes; static;
    /// <summary>A new empty folder in the temporary files; the caller deletes it</summary>
    class function NewTempFolder: string; static;
  end;

implementation

{ TWadTestHelpers }

class function TWadTestHelpers.Bytes(const AText: string): TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, Length(AText));
  for LIndex := 1 to Length(AText) do
    Result[LIndex - 1] := Ord(AText[LIndex]);
end;

class function TWadTestHelpers.MakeWad(const ANames: array of string;
  const AData: array of TBytes; AKind: TWadKind): TBytes;
var
  LStream: TBytesStream;
  LHeader: TWadHeader;
  LRecord: TWadDirectoryRecord;
  LOffset, LIndex, LCharIndex: Integer;
begin
  // by hand and without padding, so that the tests do not depend on the builder
  LStream := TBytesStream.Create;
  try
    case AKind of
      TWadKind.IWad: LHeader.Identification := WAD_ID_IWAD;
      TWadKind.DWad: LHeader.Identification := WAD_ID_DWAD;
    else
      LHeader.Identification := WAD_ID_PWAD;
    end;
    LHeader.NumLumps := Length(ANames);
    LOffset := WAD_HEADER_SIZE;
    for LIndex := 0 to High(AData) do
      Inc(LOffset, Length(AData[LIndex]));
    LHeader.InfoTableOfs := LOffset;
    LStream.WriteBuffer(LHeader, SizeOf(LHeader));
    for LIndex := 0 to High(AData) do
      if Length(AData[LIndex]) > 0 then
        LStream.WriteBuffer(AData[LIndex][0], Length(AData[LIndex]));
    LOffset := WAD_HEADER_SIZE;
    for LIndex := 0 to High(ANames) do
    begin
      FillChar(LRecord, SizeOf(LRecord), 0);
      for LCharIndex := 1 to Length(ANames[LIndex]) do
        LRecord.Name[LCharIndex - 1] := AnsiChar(Ord(ANames[LIndex][LCharIndex]));
      LRecord.FilePos := LOffset;
      LRecord.Size := Length(AData[LIndex]);
      Inc(LOffset, LRecord.Size);
      LStream.WriteBuffer(LRecord, SizeOf(LRecord));
    end;
    Result := Copy(LStream.Bytes, 0, LStream.Size);
  finally
    LStream.Free;
  end;
end;

class function TWadTestHelpers.MakePak(const ANames: array of string;
  const AData: array of TBytes): TBytes;
var
  LStream: TBytesStream;
  LId, LOffset, LLength, LIndex: Integer;
  LRecord: TPakDirectoryRecord;
  LNameIndex: Integer;
begin
  LStream := TBytesStream.Create;
  try
    LId := PAK_ID;
    LOffset := 12;
    for LIndex := 0 to High(AData) do
      Inc(LOffset, Length(AData[LIndex]));
    LLength := Length(ANames) * PAK_DIRECTORY_RECORD_SIZE;
    LStream.WriteBuffer(LId, 4);
    LStream.WriteBuffer(LOffset, 4);
    LStream.WriteBuffer(LLength, 4);
    for LIndex := 0 to High(AData) do
      if Length(AData[LIndex]) > 0 then
        LStream.WriteBuffer(AData[LIndex][0], Length(AData[LIndex]));
    LOffset := 12;
    for LIndex := 0 to High(ANames) do
    begin
      FillChar(LRecord, SizeOf(LRecord), 0);
      for LNameIndex := 1 to Length(ANames[LIndex]) do
        LRecord.Name[LNameIndex - 1] := AnsiChar(Ord(ANames[LIndex][LNameIndex]));
      LRecord.FilePos := LOffset;
      LRecord.Size := Length(AData[LIndex]);
      Inc(LOffset, LRecord.Size);
      LStream.WriteBuffer(LRecord, SizeOf(LRecord));
    end;
    Result := Copy(LStream.Bytes, 0, LStream.Size);
  finally
    LStream.Free;
  end;
end;

class function TWadTestHelpers.NewTempFolder: string;
begin
  Result := TPath.Combine(TPath.GetTempPath, 'ddwad_' + TGUID.NewGuid.ToString.Replace('{', '').Replace('}', ''));
  TDirectory.CreateDirectory(Result);
end;

end.
