{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - Quake III player models, the MD3 files      }
{                                                                              }
{  Port of the checks of RE_RegisterModel of renderer\tr_model.c. Based on the }
{  Quake III Arena GPL Source Code (id Software). Copyright (C) 1999-2005 Id   }
{  Software, Inc. This unit is derived from the Quake III Arena source code    }
{  and is therefore available under the GNU General Public License, version 2  }
{  or (at your option) any later version.                                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Q3Player.Md3ModelSource;

interface

uses
  System.SysUtils,
  DelphiDoom.Logging.Intf,
  DelphiDoom.Models.Static.Md3.Intf,
  DelphiDoom.Models.Q3Player.Intf,
  DelphiDoom.Models.Q3Player.Skin.Intf;

type
  /// <summary>
  ///   The MD3 of a file of a text source (bytes as an 8-bit string). A name that is empty or
  ///   too long, a missing file or a file that is not a valid MD3 (an MD4 included) give nil with a
  ///   warning in the log (may be nil). The models are not cached: they are not changed.
  /// </summary>
  TQ3Md3ModelSource = class(TInterfacedObject, IQ3ModelSource)
  strict private
    FSource: IQ3TextSource;
    FReader: IMd3Reader;
    FLog: ILog;
    procedure Warn(const AMessage: string);
  public
    constructor Create(const ASource: IQ3TextSource; const AReader: IMd3Reader; const ALog: ILog);
    function RegisterModel(const AFileName: AnsiString): IMd3Model;
  end;

implementation

uses
  DelphiDoom.Models.Static.Types,
  DelphiDoom.Models.Q3Player.Skin.Types;

constructor TQ3Md3ModelSource.Create(const ASource: IQ3TextSource; const AReader: IMd3Reader; const ALog: ILog);
begin
  inherited Create;
  if not Assigned(ASource) then
    raise EArgumentNilException.Create('ASource');
  if not Assigned(AReader) then
    raise EArgumentNilException.Create('AReader');
  FSource := ASource;
  FReader := AReader;
  FLog := ALog;
end;

procedure TQ3Md3ModelSource.Warn(const AMessage: string);
begin
  if Assigned(FLog) then
    FLog.Warning(AMessage);
end;

function TQ3Md3ModelSource.RegisterModel(const AFileName: AnsiString): IMd3Model;
var
  LText: AnsiString;
  LBytes: TBytes;
begin
  Result := nil;
  if AFileName = '' then
  begin
    Warn(SQ3ModelEmptyName);
    Exit;
  end;
  if Length(AFileName) >= Q3_MAX_QPATH then
  begin
    Warn(SQ3ModelNameTooLong);
    Exit;
  end;
  LText := FSource.ReadText(string(AFileName));
  if LText = '' then
  begin
    Warn(Format(SQ3ModelNotLoaded, [string(AFileName)]));
    Exit;
  end;
  SetLength(LBytes, Length(LText));
  Move(LText[1], LBytes[0], Length(LText));
  try
    Result := FReader.Read(LBytes, string(AFileName));
  except
    on E: EStaticModelException do
    begin
      Warn(Format(SQ3ModelNotLoaded, [string(AFileName)]) + ': ' + E.Message);
      Result := nil;
    end;
  end;
end;

end.
