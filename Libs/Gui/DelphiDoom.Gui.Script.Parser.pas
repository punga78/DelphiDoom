{******************************************************************************}
{                                                                              }
{  DelphiDoom: gui library - TGuiScriptParser                                  }
{                                                                              }
{  Port of the GUI of Doom 3 (id Software, GPL v3): ui\Window.cpp              }
{  (idWindow::ParseScript). Copyright (C) 1999-2011 id Software LLC, a ZeniMax }
{  Media company.                                                              }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore      }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.Script.Parser;

interface

uses
  DelphiDoom.Scanner.IdParser, DelphiDoom.Gui.Regs.Intf, DelphiDoom.Gui.Script;

type
  /// <summary>
  ///   Reads a script block <c>{ command args ; ... if (expr) { } else { } }</c> into a list. The
  ///   condition of an <c>if</c> is an expression of the window that owns the script.
  /// </summary>
  TGuiScriptParser = class
  strict private
    FOwner: IGuiRegisterOwner;
  public
    constructor Create(const AOwner: IGuiRegisterOwner);
    /// <summary>
    ///   ParseScript: False on a syntax error (the parser has reported it). <c>AElseBlock</c> is the
    ///   block after an "else": a "{" or an "if" (else if) is accepted.
    /// </summary>
    function ParseScript(const ASource: TIdParser; const AList: TGuiScriptList;
      const AElseBlock: Boolean = False): Boolean;
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Token, DelphiDoom.IdLib.Text.Strings;

constructor TGuiScriptParser.Create(const AOwner: IGuiRegisterOwner);
begin
  inherited Create;
  FOwner := AOwner;
end;

function TGuiScriptParser.ParseScript(const ASource: TIdParser; const AList: TGuiScriptList;
  const AElseBlock: Boolean): Boolean;
var
  LToken: TIdToken;
  LScript: TGuiScript;
  LIfElseBlock: Boolean;
  LNest: Integer;
begin
  LIfElseBlock := False;
  LToken := TIdToken.Create;
  // scripts start with "{" (an else may be an "if") and have ";" separated commands
  if AElseBlock then
  begin
    ASource.ReadToken(LToken);
    if TIdStrings.Icmp(LToken.Text, 'if') = 0 then
      LIfElseBlock := True;
    ASource.UnreadToken(LToken);
    if (not LIfElseBlock) and (not ASource.ExpectTokenString('{')) then
      Exit(False);
  end
  else if not ASource.ExpectTokenString('{') then
    Exit(False);
  LNest := 0;
  while True do
  begin
    if not ASource.ReadToken(LToken) then
    begin
      ASource.Error('Unexpected end of file');
      Exit(False);
    end;
    if LToken.IsText('{') then
      Inc(LNest);
    if LToken.IsText('}') then
    begin
      Dec(LNest);
      if LNest < 0 then
        Exit(True);
    end;
    LScript := TGuiScript.Create;
    if TIdStrings.Icmp(LToken.Text, 'if') = 0 then
    begin
      LScript.ConditionReg := FOwner.ParseExpression(ASource);
      LScript.IfList := TGuiScriptList.Create;
      ParseScript(ASource, LScript.IfList);
      if ASource.ReadToken(LToken) then
      begin
        if LToken.IsText('else') then
        begin
          LScript.ElseList := TGuiScriptList.Create;
          ParseScript(ASource, LScript.ElseList, True);
        end
        else
          ASource.UnreadToken(LToken);
      end;
      AList.Append(LScript);
      // an "else if" returns so the first "if" reads the rest
      if LIfElseBlock then
        Exit(True);
      Continue;
    end
    else
      ASource.UnreadToken(LToken);
    // an empty { } is not allowed
    if LToken.IsText('{') then
    begin
      ASource.Error('Unexpected {');
      LScript.Free;
      Exit(False);
    end;
    LScript.Parse(ASource);
    AList.Append(LScript);
  end;
end;

end.
