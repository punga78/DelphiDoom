{******************************************************************************}
{                                                                              }
{  DD_IDE: small services of Windows and of the VCL for the ide library        }
{  Copyright (C) 2016-2022 by Jim Valavanis (original DD_IDE)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Ide.Win.Services;

interface

uses
  System.SysUtils,
  System.Classes,
  Vcl.Controls,
  DelphiDoom.Ide.Types,
  DelphiDoom.Ide.Intf;

type
  /// <summary>The time of the day</summary>
  TWindowsIdeClock = class(TInterfacedObject, IIdeClock)
  public
    function Now: TDateTime;
  end;

  /// <summary>The hourglass: it stays while at least one operation is busy</summary>
  TVclIdeBusy = class(TInterfacedObject, IIdeBusy)
  strict private
    FDepth: Integer;
    FSaved: TCursor;
  public
    procedure Enter;
    procedure Leave;
  end;

  /// <summary>The clipboard of Windows</summary>
  TVclIdeClipboard = class(TInterfacedObject, IIdeClipboard)
  public
    procedure SetText(const AText: string);
  end;

  /// <summary>The yes, no and cancel question and the "about" window</summary>
  TVclIdeMessageDialogs = class(TInterfacedObject, IIdeMessageDialogs)
  strict private
    FTitle: string;
  public
    constructor Create(const ATitle: string);
    function AskSaveChanges(const AQuestion: string): TIdeConfirmation;
    procedure ShowAbout(const AText: string);
  end;

implementation

uses
  Winapi.Windows,
  Vcl.Forms,
  Vcl.Clipbrd,
  frm_message;

{ TWindowsIdeClock }

function TWindowsIdeClock.Now: TDateTime;
begin
  Result := System.SysUtils.Now;
end;

{ TVclIdeBusy }

procedure TVclIdeBusy.Enter;
begin
  if FDepth = 0 then
    FSaved := Screen.Cursor;
  Inc(FDepth);
  Screen.Cursor := crHourGlass;
end;

procedure TVclIdeBusy.Leave;
begin
  if FDepth > 0 then
    Dec(FDepth);
  if FDepth = 0 then
    Screen.Cursor := crDefault;
end;

{ TVclIdeClipboard }

procedure TVclIdeClipboard.SetText(const AText: string);
begin
  Clipboard.AsText := AText;
end;

{ TVclIdeMessageDialogs }

constructor TVclIdeMessageDialogs.Create(const ATitle: string);
begin
  inherited Create;
  FTitle := ATitle;
end;

function TVclIdeMessageDialogs.AskSaveChanges(const AQuestion: string): TIdeConfirmation;
var
  LHandle: HWND;
begin
  if Assigned(Screen.ActiveForm) then
    LHandle := Screen.ActiveForm.Handle
  else
    LHandle := 0;
  case MessageBox(LHandle, PChar(AQuestion), PChar(FTitle),
    MB_YESNOCANCEL or MB_ICONQUESTION or MB_APPLMODAL) of
    IDYES:
      Result := cfYes;
    IDNO:
      Result := cfNo;
  else
    Result := cfCancel;
  end;
end;

procedure TVclIdeMessageDialogs.ShowAbout(const AText: string);
begin
  IDEMessage(AText);
end;

end.
