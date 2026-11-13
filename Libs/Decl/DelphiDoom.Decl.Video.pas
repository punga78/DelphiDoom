{******************************************************************************}
{                                                                              }
{  DelphiDoom: declaration manager - TDeclVideo, the "video" declaration       }
{                                                                              }
{  Port of the declaration manager of Doom 3 (id Software, GPL v3):            }
{  framework\DeclPDA.h, DeclPDA.cpp (idDeclVideo). Copyright (C) 1999-2011 id  }
{  Software LLC, a ZeniMax Media company.                                      }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Video;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Decl.Base;

type
  /// <summary>A video of a PDA (idDeclVideo)</summary>
  IDeclVideo = interface
    ['{5E0C1A52-7B1E-4C0B-9D4B-4C6E3D0A0015}']
    /// <summary>The material of the video (the "video" key)</summary>
    function GetRoq: AnsiString;
    /// <summary>The sound shader (the "audio" key)</summary>
    function GetWave: AnsiString;
    function GetVideoName: AnsiString;
    function GetInfo: AnsiString;
    function GetPreview: AnsiString;
  end;

  /// <summary>
  ///   <c>video name { name "n"  preview "p"  video "material"  info "i"  audio "sound" }</c>. The video and the audio
  ///   are looked up as a material and a sound shader while it parses. <c>FreeData</c> clears nothing (as the original).
  /// </summary>
  TDeclVideo = class(TDecl, IDeclVideo)
  strict private
    FPreview: AnsiString;
    FVideo: AnsiString;
    FVideoName: AnsiString;
    FInfo: AnsiString;
    FAudio: AnsiString;
  public
    function GetRoq: AnsiString;
    function GetWave: AnsiString;
    function GetVideoName: AnsiString;
    function GetInfo: AnsiString;
    function GetPreview: AnsiString;
    function DefaultDefinition: AnsiString; override;
    function Parse(const AText: AnsiString): Boolean; override;
    function Size: NativeInt; override;
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Lexer, DelphiDoom.IdLib.Text.Token, DelphiDoom.IdLib.Text.Strings, DelphiDoom.Decl.Types,
  DelphiDoom.Decl.Intf;

{ TDeclVideo }

function TDeclVideo.GetRoq: AnsiString;
begin
  Result := FVideo;
end;

function TDeclVideo.GetWave: AnsiString;
begin
  Result := FAudio;
end;

function TDeclVideo.GetVideoName: AnsiString;
begin
  Result := FVideoName;
end;

function TDeclVideo.GetInfo: AnsiString;
begin
  Result := FInfo;
end;

function TDeclVideo.GetPreview: AnsiString;
begin
  Result := FPreview;
end;

function TDeclVideo.Size: NativeInt;
begin
  Result := InstanceSize;
end;

function TDeclVideo.DefaultDefinition: AnsiString;
begin
  Result := '{'#10#9'{'#10#9#9'name'#9'5Default Video'#10#9'}'#10'}';
end;

function TDeclVideo.Parse(const AText: AnsiString): Boolean;
var
  LSource: TIdLexer;
  LToken: TIdToken;
  LFinder: IDeclFinder;
begin
  LSource := OpenLexer(AText, DECL_PDA_LEXER_FLAGS);
  try
    LFinder := GetFinder;
    // scan through, identifying each individual parameter
    while True do
    begin
      if not LSource.ReadToken(LToken) then
        Break;
      if LToken.IsText('}') then
        Break;

      if TIdStrings.Icmp(LToken.Text, 'name') = 0 then
      begin
        LSource.ReadToken(LToken);
        FVideoName := LToken.Text;
      end
      else if TIdStrings.Icmp(LToken.Text, 'preview') = 0 then
      begin
        LSource.ReadToken(LToken);
        FPreview := LToken.Text;
      end
      else if TIdStrings.Icmp(LToken.Text, 'video') = 0 then
      begin
        LSource.ReadToken(LToken);
        FVideo := LToken.Text;
        LFinder.FindType(DECL_MATERIAL, FVideo);
      end
      else if TIdStrings.Icmp(LToken.Text, 'info') = 0 then
      begin
        LSource.ReadToken(LToken);
        FInfo := LToken.Text;
      end
      else if TIdStrings.Icmp(LToken.Text, 'audio') = 0 then
      begin
        LSource.ReadToken(LToken);
        FAudio := LToken.Text;
        LFinder.FindType(DECL_SOUND, FAudio);
      end;
    end;

    if LSource.HadError then
    begin
      LSource.Warning('Video decl ''%s'' had a parse error', [string(GetName)]);
      Exit(False);
    end;
    Result := True;
  finally
    LSource.Free;
  end;
end;

end.
