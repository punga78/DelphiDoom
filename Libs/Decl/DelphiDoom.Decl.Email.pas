{******************************************************************************}
{                                                                              }
{  DelphiDoom: declaration manager - TDeclEmail, the "email" declaration       }
{                                                                              }
{  Port of the declaration manager of Doom 3 (id Software, GPL v3):            }
{  framework\DeclPDA.h, DeclPDA.cpp (idDeclEmail). Copyright (C) 1999-2011 id  }
{  Software LLC, a ZeniMax Media company.                                      }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Email;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Decl.Base;

type
  /// <summary>An e-mail of a PDA (idDeclEmail)</summary>
  IDeclEmail = interface
    ['{5E0C1A52-7B1E-4C0B-9D4B-4C6E3D0A0014}']
    function GetFrom: AnsiString;
    function GetBody: AnsiString;
    function GetSubject: AnsiString;
    function GetDate: AnsiString;
    function GetTo: AnsiString;
    function GetImage: AnsiString;
  end;

  /// <summary>
  ///   <c>email name { subject "s"  to "t"  from "f"  date "d"  image "i"  text { "line" ... } }</c>; the tokens of
  ///   the text block are joined without a separator. As in the original <c>FreeData</c> clears nothing, so
  ///   a reparse keeps the fields the new text does not set.
  /// </summary>
  TDeclEmail = class(TDecl, IDeclEmail)
  strict private
    FText: AnsiString;
    FSubject: AnsiString;
    FDate: AnsiString;
    FTo: AnsiString;
    FFrom: AnsiString;
    FImage: AnsiString;
  public
    function GetFrom: AnsiString;
    function GetBody: AnsiString;
    function GetSubject: AnsiString;
    function GetDate: AnsiString;
    function GetTo: AnsiString;
    function GetImage: AnsiString;
    function DefaultDefinition: AnsiString; override;
    function Parse(const AText: AnsiString): Boolean; override;
    function Size: NativeInt; override;
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Lexer, DelphiDoom.IdLib.Text.Token, DelphiDoom.IdLib.Text.Strings, DelphiDoom.Decl.Types;

{ TDeclEmail }

function TDeclEmail.GetFrom: AnsiString;
begin
  Result := FFrom;
end;

function TDeclEmail.GetBody: AnsiString;
begin
  Result := FText;
end;

function TDeclEmail.GetSubject: AnsiString;
begin
  Result := FSubject;
end;

function TDeclEmail.GetDate: AnsiString;
begin
  Result := FDate;
end;

function TDeclEmail.GetTo: AnsiString;
begin
  Result := FTo;
end;

function TDeclEmail.GetImage: AnsiString;
begin
  Result := FImage;
end;

function TDeclEmail.Size: NativeInt;
begin
  Result := InstanceSize;
end;

function TDeclEmail.DefaultDefinition: AnsiString;
begin
  Result := '{'#10#9'{'#10#9#9'to'#9'5Mail recipient'#10#9#9'subject'#9'5Nothing'#10#9#9'from'#9'5No one'#10#9'}'#10'}';
end;

function TDeclEmail.Parse(const AText: AnsiString): Boolean;
var
  LSource: TIdLexer;
  LToken: TIdToken;
begin
  LSource := OpenLexer(AText, DECL_PDA_LEXER_FLAGS);
  try
    FText := '';
    // scan through, identifying each individual parameter
    while True do
    begin
      if not LSource.ReadToken(LToken) then
        Break;
      if LToken.IsText('}') then
        Break;

      if TIdStrings.Icmp(LToken.Text, 'subject') = 0 then
      begin
        LSource.ReadToken(LToken);
        FSubject := LToken.Text;
      end
      else if TIdStrings.Icmp(LToken.Text, 'to') = 0 then
      begin
        LSource.ReadToken(LToken);
        FTo := LToken.Text;
      end
      else if TIdStrings.Icmp(LToken.Text, 'from') = 0 then
      begin
        LSource.ReadToken(LToken);
        FFrom := LToken.Text;
      end
      else if TIdStrings.Icmp(LToken.Text, 'date') = 0 then
      begin
        LSource.ReadToken(LToken);
        FDate := LToken.Text;
      end
      else if TIdStrings.Icmp(LToken.Text, 'text') = 0 then
      begin
        LSource.ReadToken(LToken);
        if not LToken.IsText('{') then
        begin
          LSource.Warning('Email decl ''%s'' had a parse error', [string(GetName)]);
          Exit(False);
        end;
        while LSource.ReadToken(LToken) and not LToken.IsText('}') do
          FText := FText + LToken.Text;
      end
      else if TIdStrings.Icmp(LToken.Text, 'image') = 0 then
      begin
        LSource.ReadToken(LToken);
        FImage := LToken.Text;
      end;
    end;

    if LSource.HadError then
    begin
      LSource.Warning('Email decl ''%s'' had a parse error', [string(GetName)]);
      Exit(False);
    end;
    Result := True;
  finally
    LSource.Free;
  end;
end;

end.
