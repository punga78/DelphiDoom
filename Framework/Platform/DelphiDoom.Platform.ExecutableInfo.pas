{******************************************************************************}
{                                                                              }
{  DelphiDoom: platform library - facts about an executable file               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Platform.ExecutableInfo;

interface

uses
  DelphiDoom.Platform.Intf;

type
  /// <summary>IExecutableInfo: the PE header and the version resource of a file</summary>
  TExecutableInfo = class(TInterfacedObject, IExecutableInfo)
  public
    function ImageSize(const AFileName: string): Cardinal;
    function FileVersion(const AFileName: string): string;
  end;

implementation

uses
  System.SysUtils, System.Classes, Winapi.Windows, DelphiDoom.Platform.PeImageReader;

type
  TTranslation = packed record
    Language: Word;
    CodePage: Word;
  end;
  PTranslation = ^TTranslation;

{ TExecutableInfo }

function TExecutableInfo.ImageSize(const AFileName: string): Cardinal;
var
  LStream: TFileStream;
begin
  try
    LStream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
    try
      Result := TPeImageReader.ReadImageSize(LStream);
    finally
      LStream.Free;
    end;
  except
    on EStreamError do
      Result := 0;
  end;
end;

function TExecutableInfo.FileVersion(const AFileName: string): string;

  function QueryText(const ABlock: TBytes; const ALanguage: string; out AText: string): Boolean;
  var
    LValue: Pointer;
    LLength: UINT;
  begin
    LValue := nil;
    LLength := 0;
    Result := VerQueryValue(@ABlock[0], PChar('\StringFileInfo\' + ALanguage + '\FileVersion'),
      LValue, LLength) and (LValue <> nil) and (LLength > 0);
    if Result then
      AText := PChar(LValue);
  end;

var
  LHandle: DWORD;
  LSize: DWORD;
  LBlock: TBytes;
  LValue: Pointer;
  LLength: UINT;
  LTranslation: PTranslation;
  LIndex: Integer;
begin
  Result := '';
  LSize := GetFileVersionInfoSize(PChar(AFileName), LHandle);
  if LSize = 0 then
    Exit;
  SetLength(LBlock, LSize);
  if not GetFileVersionInfo(PChar(AFileName), 0, LSize, @LBlock[0]) then
    Exit;
  // the language the file declares first, then the ones of the old engine
  LValue := nil;
  LLength := 0;
  if VerQueryValue(@LBlock[0], '\VarFileInfo\Translation', LValue, LLength) and (LValue <> nil) then
  begin
    LTranslation := PTranslation(LValue);
    for LIndex := 0 to Integer(LLength div SizeOf(TTranslation)) - 1 do
    begin
      if QueryText(LBlock, Format('%.4x%.4x', [LTranslation.Language, LTranslation.CodePage]), Result) then
        Exit;
      Inc(LTranslation);
    end;
  end;
  if not QueryText(LBlock, '040904E4', Result) then
    QueryText(LBlock, '040904B0', Result);
end;

end.
