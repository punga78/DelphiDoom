{******************************************************************************}
{                                                                              }
{  DelphiDoom: declaration manager - TDeclPda, the "pda" declaration           }
{                                                                              }
{  Port of the declaration manager of Doom 3 (id Software, GPL v3):            }
{  framework\DeclPDA.h, DeclPDA.cpp (idDeclPDA). Copyright (C) 1999-2011 id    }
{  Software LLC, a ZeniMax Media company.                                      }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Pda;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.IdLib.Core.Intf, DelphiDoom.Decl.Intf,
  DelphiDoom.Decl.Base;

type
  /// <summary>A PDA: the owner's names and the e-mails, audio logs and videos it holds (idDeclPDA)</summary>
  IDeclPda = interface
    ['{5E0C1A52-7B1E-4C0B-9D4B-4C6E3D0A0013}']
    /// <summary>Adds a video by name if it exists (a message to the log otherwise); with <c>AUnique</c> not twice</summary>
    procedure AddVideo(const AName: AnsiString; const AUnique: Boolean = True);
    procedure AddAudio(const AName: AnsiString; const AUnique: Boolean = True);
    procedure AddEmail(const AName: AnsiString; const AUnique: Boolean = True);
    /// <summary>Drops the e-mails and videos added after the parse (the audio logs are not dropped: as the original)</summary>
    procedure RemoveAddedEmailsAndVideos;
    function GetNumVideos: Integer;
    function GetNumAudios: Integer;
    function GetNumEmails: Integer;
    /// <summary>The video declaration (not created if it does not exist), nil if the index is out of range</summary>
    function GetVideoByIndex(const AIndex: Integer): IDecl;
    function GetAudioByIndex(const AIndex: Integer): IDecl;
    function GetEmailByIndex(const AIndex: Integer): IDecl;
    procedure SetSecurity(const ASecurity: AnsiString);
    function GetPdaName: AnsiString;
    function GetSecurity: AnsiString;
    function GetFullName: AnsiString;
    function GetIcon: AnsiString;
    function GetPost: AnsiString;
    function GetID: AnsiString;
    function GetTitle: AnsiString;
  end;

  /// <summary>
  ///   <c>pda name { name fullname icon id post title security pda_email pda_audio pda_video }</c>; each
  ///   <c>pda_*</c> key adds a name and finds (creating a default) the declaration of that name.
  /// </summary>
  TDeclPda = class(TDecl, IDeclPda)
  strict private
    FVideos: TList<AnsiString>;
    FAudios: TList<AnsiString>;
    FEmails: TList<AnsiString>;
    FPdaName: AnsiString;
    FFullName: AnsiString;
    FIcon: AnsiString;
    FId: AnsiString;
    FPost: AnsiString;
    FTitle: AnsiString;
    FSecurity: AnsiString;
    FOriginalEmails: Integer;
    FOriginalVideos: Integer;
    procedure AddName(const AList: TList<AnsiString>; const AType: Integer; const AName: AnsiString;
      const AUnique: Boolean; const AMissing: string);
    function ByIndex(const AList: TList<AnsiString>; const AType, AIndex: Integer): IDecl;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddVideo(const AName: AnsiString; const AUnique: Boolean = True);
    procedure AddAudio(const AName: AnsiString; const AUnique: Boolean = True);
    procedure AddEmail(const AName: AnsiString; const AUnique: Boolean = True);
    procedure RemoveAddedEmailsAndVideos;
    function GetNumVideos: Integer;
    function GetNumAudios: Integer;
    function GetNumEmails: Integer;
    function GetVideoByIndex(const AIndex: Integer): IDecl;
    function GetAudioByIndex(const AIndex: Integer): IDecl;
    function GetEmailByIndex(const AIndex: Integer): IDecl;
    procedure SetSecurity(const ASecurity: AnsiString);
    function GetPdaName: AnsiString;
    function GetSecurity: AnsiString;
    function GetFullName: AnsiString;
    function GetIcon: AnsiString;
    function GetPost: AnsiString;
    function GetID: AnsiString;
    function GetTitle: AnsiString;
    function DefaultDefinition: AnsiString; override;
    function Parse(const AText: AnsiString): Boolean; override;
    procedure FreeData; override;
    function Size: NativeInt; override;
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Lexer, DelphiDoom.IdLib.Text.Token, DelphiDoom.IdLib.Text.Strings, DelphiDoom.Decl.Types;

{ TDeclPda }

constructor TDeclPda.Create;
begin
  inherited Create;
  FVideos := TList<AnsiString>.Create;
  FAudios := TList<AnsiString>.Create;
  FEmails := TList<AnsiString>.Create;
end;

destructor TDeclPda.Destroy;
begin
  FEmails.Free;
  FAudios.Free;
  FVideos.Free;
  inherited Destroy;
end;

function TDeclPda.Size: NativeInt;
begin
  Result := InstanceSize;
end;

procedure TDeclPda.FreeData;
begin
  FVideos.Clear;
  FAudios.Clear;
  FEmails.Clear;
  FOriginalEmails := 0;
  FOriginalVideos := 0;
end;

function TDeclPda.DefaultDefinition: AnsiString;
begin
  Result := '{'#10#9'name  "default pda"'#10'}';
end;

procedure TDeclPda.AddName(const AList: TList<AnsiString>; const AType: Integer; const AName: AnsiString;
  const AUnique: Boolean; const AMissing: string);
var
  LName: AnsiString;
  LLog: IIdLibLog;
begin
  if AUnique then
    for LName in AList do
      if LName = AName then
        Exit;
  if not Assigned(GetFinder.FindType(AType, AName, False)) then
  begin
    LLog := GetLog;
    if Assigned(LLog) then
      LLog.Printf(Format(AMissing, [string(AName)]));
    Exit;
  end;
  AList.Add(AName);
end;

procedure TDeclPda.AddVideo(const AName: AnsiString; const AUnique: Boolean);
begin
  AddName(FVideos, DECL_VIDEO, AName, AUnique, 'Video %s not found'#10);
end;

procedure TDeclPda.AddAudio(const AName: AnsiString; const AUnique: Boolean);
begin
  AddName(FAudios, DECL_AUDIO, AName, AUnique, 'Audio log %s not found'#10);
end;

procedure TDeclPda.AddEmail(const AName: AnsiString; const AUnique: Boolean);
begin
  AddName(FEmails, DECL_EMAIL, AName, AUnique, 'Email %s not found'#10);
end;

procedure TDeclPda.RemoveAddedEmailsAndVideos;
begin
  while FEmails.Count > FOriginalEmails do
    FEmails.Delete(FEmails.Count - 1);
  while FVideos.Count > FOriginalVideos do
    FVideos.Delete(FVideos.Count - 1);
end;

procedure TDeclPda.SetSecurity(const ASecurity: AnsiString);
begin
  FSecurity := ASecurity;
end;

function TDeclPda.GetNumVideos: Integer;
begin
  Result := FVideos.Count;
end;

function TDeclPda.GetNumAudios: Integer;
begin
  Result := FAudios.Count;
end;

function TDeclPda.GetNumEmails: Integer;
begin
  Result := FEmails.Count;
end;

function TDeclPda.ByIndex(const AList: TList<AnsiString>; const AType, AIndex: Integer): IDecl;
begin
  if (AIndex >= 0) and (AIndex < AList.Count) then
    Result := GetFinder.FindType(AType, AList[AIndex], False)
  else
    Result := nil;
end;

function TDeclPda.GetVideoByIndex(const AIndex: Integer): IDecl;
begin
  Result := ByIndex(FVideos, DECL_VIDEO, AIndex);
end;

function TDeclPda.GetAudioByIndex(const AIndex: Integer): IDecl;
begin
  Result := ByIndex(FAudios, DECL_AUDIO, AIndex);
end;

function TDeclPda.GetEmailByIndex(const AIndex: Integer): IDecl;
begin
  Result := ByIndex(FEmails, DECL_EMAIL, AIndex);
end;

function TDeclPda.GetPdaName: AnsiString;
begin
  Result := FPdaName;
end;

function TDeclPda.GetSecurity: AnsiString;
begin
  Result := FSecurity;
end;

function TDeclPda.GetFullName: AnsiString;
begin
  Result := FFullName;
end;

function TDeclPda.GetIcon: AnsiString;
begin
  Result := FIcon;
end;

function TDeclPda.GetPost: AnsiString;
begin
  Result := FPost;
end;

function TDeclPda.GetID: AnsiString;
begin
  Result := FId;
end;

function TDeclPda.GetTitle: AnsiString;
begin
  Result := FTitle;
end;

function TDeclPda.Parse(const AText: AnsiString): Boolean;
var
  LSource: TIdLexer;
  LToken: TIdToken;
  LFinder: IDeclFinder;
begin
  LSource := OpenLexer(AText);
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
        FPdaName := LToken.Text;
      end
      else if TIdStrings.Icmp(LToken.Text, 'fullname') = 0 then
      begin
        LSource.ReadToken(LToken);
        FFullName := LToken.Text;
      end
      else if TIdStrings.Icmp(LToken.Text, 'icon') = 0 then
      begin
        LSource.ReadToken(LToken);
        FIcon := LToken.Text;
      end
      else if TIdStrings.Icmp(LToken.Text, 'id') = 0 then
      begin
        LSource.ReadToken(LToken);
        FId := LToken.Text;
      end
      else if TIdStrings.Icmp(LToken.Text, 'post') = 0 then
      begin
        LSource.ReadToken(LToken);
        FPost := LToken.Text;
      end
      else if TIdStrings.Icmp(LToken.Text, 'title') = 0 then
      begin
        LSource.ReadToken(LToken);
        FTitle := LToken.Text;
      end
      else if TIdStrings.Icmp(LToken.Text, 'security') = 0 then
      begin
        LSource.ReadToken(LToken);
        FSecurity := LToken.Text;
      end
      else if TIdStrings.Icmp(LToken.Text, 'pda_email') = 0 then
      begin
        LSource.ReadToken(LToken);
        FEmails.Add(LToken.Text);
        LFinder.FindType(DECL_EMAIL, LToken.Text);
      end
      else if TIdStrings.Icmp(LToken.Text, 'pda_audio') = 0 then
      begin
        LSource.ReadToken(LToken);
        FAudios.Add(LToken.Text);
        LFinder.FindType(DECL_AUDIO, LToken.Text);
      end
      else if TIdStrings.Icmp(LToken.Text, 'pda_video') = 0 then
      begin
        LSource.ReadToken(LToken);
        FVideos.Add(LToken.Text);
        LFinder.FindType(DECL_VIDEO, LToken.Text);
      end;
    end;

    if LSource.HadError then
    begin
      LSource.Warning('PDA decl ''%s'' had a parse error', [string(GetName)]);
      Exit(False);
    end;

    FOriginalVideos := FVideos.Count;
    FOriginalEmails := FEmails.Count;
    Result := True;
  finally
    LSource.Free;
  end;
end;

end.
