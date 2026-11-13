{******************************************************************************}
{                                                                              }
{  DelphiDoom: declaration manager - TDeclAudio, the "audio" declaration       }
{                                                                              }
{  Port of the declaration manager of Doom 3 (id Software, GPL v3):            }
{  framework\DeclPDA.h, DeclPDA.cpp (idDeclAudio). Copyright (C) 1999-2011 id  }
{  Software LLC, a ZeniMax Media company.                                      }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Audio;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Decl.Base;

type
  /// <summary>An audio log of a PDA (idDeclAudio)</summary>
  IDeclAudio = interface
    ['{5E0C1A52-7B1E-4C0B-9D4B-4C6E3D0A0016}']
    function GetAudioName: AnsiString;
    /// <summary>The sound shader (the "audio" key)</summary>
    function GetWave: AnsiString;
    function GetInfo: AnsiString;
    function GetPreview: AnsiString;
  end;

  /// <summary>
  ///   <c>audio name { name "n"  audio "sound"  info "i"  preview "p" }</c>. The audio is looked up as a sound shader
  ///   while it parses. <c>FreeData</c> clears nothing (as the original).
  /// </summary>
  TDeclAudio = class(TDecl, IDeclAudio)
  strict private
    FAudio: AnsiString;
    FAudioName: AnsiString;
    FInfo: AnsiString;
    FPreview: AnsiString;
  public
    function GetAudioName: AnsiString;
    function GetWave: AnsiString;
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

{ TDeclAudio }

function TDeclAudio.GetAudioName: AnsiString;
begin
  Result := FAudioName;
end;

function TDeclAudio.GetWave: AnsiString;
begin
  Result := FAudio;
end;

function TDeclAudio.GetInfo: AnsiString;
begin
  Result := FInfo;
end;

function TDeclAudio.GetPreview: AnsiString;
begin
  Result := FPreview;
end;

function TDeclAudio.Size: NativeInt;
begin
  Result := InstanceSize;
end;

function TDeclAudio.DefaultDefinition: AnsiString;
begin
  Result := '{'#10#9'{'#10#9#9'name'#9'5Default Audio'#10#9'}'#10'}';
end;

function TDeclAudio.Parse(const AText: AnsiString): Boolean;
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
        FAudioName := LToken.Text;
      end
      else if TIdStrings.Icmp(LToken.Text, 'audio') = 0 then
      begin
        LSource.ReadToken(LToken);
        FAudio := LToken.Text;
        LFinder.FindType(DECL_SOUND, FAudio);
      end
      else if TIdStrings.Icmp(LToken.Text, 'info') = 0 then
      begin
        LSource.ReadToken(LToken);
        FInfo := LToken.Text;
      end
      else if TIdStrings.Icmp(LToken.Text, 'preview') = 0 then
      begin
        LSource.ReadToken(LToken);
        FPreview := LToken.Text;
      end;
    end;

    if LSource.HadError then
    begin
      LSource.Warning('Audio decl ''%s'' had a parse error', [string(GetName)]);
      Exit(False);
    end;
    Result := True;
  finally
    LSource.Free;
  end;
end;

end.
