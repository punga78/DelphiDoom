{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - Quake III player models, .skin files        }
{                                                                              }
{  Port of the loop of RE_RegisterSkin of renderer\tr_image.c. Based on the    }
{  Quake III Arena GPL Source Code (id Software). Copyright (C) 1999-2005 Id   }
{  Software, Inc. This unit is derived from the Quake III Arena source code    }
{  and is therefore available under the GNU General Public License, version 2  }
{  or (at your option) any later version.                                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Q3Player.Skin.Parser;

interface

uses
  System.SysUtils,
  DelphiDoom.Logging.Intf,
  DelphiDoom.Models.Q3Player.Skin.Types,
  DelphiDoom.Models.Q3Player.Skin.Intf;

type
  /// <summary>
  ///   A line of a .skin file is "surface,shader": the surface name is lowercased, a line of a
  ///   "tag_" is skipped (only the word, the next one is read as a surface), a word is cut at 63
  ///   characters. More than MD3_MAX_SURFACES surfaces overflow the structure of the original: here
  ///   the others are ignored with a warning (ALog may be nil).
  /// </summary>
  TQ3SkinParser = class(TInterfacedObject, IQ3SkinParser)
  strict private
    FLog: ILog;
  public
    constructor Create(const ALog: ILog);
    function Parse(const AName, AText: AnsiString): IQ3Skin;
  end;

implementation

uses
  DelphiDoom.Models.Q3Player.Skin.TokenReader,
  DelphiDoom.Models.Q3Player.Skin.Skin;

// Q_strncpyz( dest, src, MAX_QPATH )
function CutToPath(const AText: AnsiString): AnsiString;
begin
  Result := Copy(AText, 1, Q3_MAX_QPATH - 1);
  // strncpy stops at a NUL byte
  if Pos(#0, string(Result)) > 0 then
    Result := Copy(Result, 1, Pos(#0, string(Result)) - 1);
end;

// Q_strlwr: tolower of the C locale
function LowerAscii(const AText: AnsiString): AnsiString;
var
  LIndex: Integer;
begin
  Result := AText;
  for LIndex := 1 to Length(Result) do
    if (Result[LIndex] >= 'A') and (Result[LIndex] <= 'Z') then
      Result[LIndex] := AnsiChar(Ord(Result[LIndex]) + 32);
end;

constructor TQ3SkinParser.Create(const ALog: ILog);
begin
  inherited Create;
  FLog := ALog;
end;

function TQ3SkinParser.Parse(const AName, AText: AnsiString): IQ3Skin;
var
  LReader: TQ3SkinTokenReader;
  LSurfaces: TArray<TQ3SkinSurface>;
  LToken: AnsiString;
  LSurface: TQ3SkinSurface;
  LWarned: Boolean;
begin
  LWarned := False;
  LReader := TQ3SkinTokenReader.Create(AText);
  try
    while not LReader.AtEnd do
    begin
      LToken := LReader.Next;
      if LToken = '' then
        Break;
      LSurface.Name := LowerAscii(CutToPath(LToken));
      LReader.SkipComma;
      if Pos('tag_', string(LToken)) > 0 then
        Continue;
      LSurface.Shader := LReader.Next;
      if Length(LSurfaces) >= Q3_MD3_MAX_SURFACES then
      begin
        if (not LWarned) and Assigned(FLog) then
          FLog.Warning(Format(SQ3SkinTooManySurfaces, [string(AName), Q3_MD3_MAX_SURFACES]));
        LWarned := True;
        Continue;
      end;
      SetLength(LSurfaces, Length(LSurfaces) + 1);
      LSurfaces[High(LSurfaces)] := LSurface;
    end;
  finally
    LReader.Free;
  end;
  if Length(LSurfaces) = 0 then
    Result := nil
  else
    Result := TQ3Skin.Create(AName, LSurfaces);
end;

end.
