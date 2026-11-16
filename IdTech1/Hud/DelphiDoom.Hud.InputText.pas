{******************************************************************************}
{                                                                              }
{  DelphiDoom: heads-up display library - a line where the player types        }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Hud.InputText;

interface

uses
  DelphiDoom.Hud.Types, DelphiDoom.Hud.TextLine;

type
  /// <summary>
  ///   A text line the player types in (the old hu_itext_t): characters go in at the end, the
  ///   backspace takes them away down to a left margin
  /// </summary>
  THudInputText = class sealed
  strict private
    FLine: THudTextLine;
    FLeftMargin: Integer;
    FLastVisible: Boolean;
    FBackspace: Integer;
    FEnter: Integer;
  public
    /// <summary>A line that knows the codes of the backspace and of the return key</summary>
    constructor Create(const AKeys: THudKeys);
    destructor Destroy; override;
    /// <summary>Puts the line back as new at the given place (HUlib_initIText)</summary>
    procedure Initialize(const AX, AY, AStartChar: Integer);
    /// <summary>Takes the last character away, not those before the left margin (HUlib_delCharFromIText)</summary>
    procedure DeleteChar;
    /// <summary>Empties the line and the left margin (HUlib_resetIText)</summary>
    procedure Reset;
    /// <summary>
    ///   Handles a key (HUlib_keyInIText): the printable characters from the space to the
    ///   underscore are added, the backspace deletes, the return key is eaten without effect.
    ///   Returns false if the key was not eaten
    /// </summary>
    function KeyIn(const AKey: Integer): Boolean;
    /// <summary>
    ///   The line is going to be erased, and is visible or not: when it has just become hidden it
    ///   must be erased again. Remembers the state for the next time
    /// </summary>
    procedure PrepareErase(const AVisible: Boolean);
    /// <summary>The line of text</summary>
    property Line: THudTextLine read FLine;
    /// <summary>Characters before this position are not deleted</summary>
    property LeftMargin: Integer read FLeftMargin;
  end;

implementation

const
  FIRST_PRINTABLE = Ord(' ');
  LAST_PRINTABLE = Ord('_');

{ THudInputText }

constructor THudInputText.Create(const AKeys: THudKeys);
begin
  inherited Create;
  FBackspace := AKeys.Backspace;
  FEnter := AKeys.Enter;
  FLine := THudTextLine.Create(0, 0, 0);
  FLastVisible := True;
end;

destructor THudInputText.Destroy;
begin
  FLine.Free;
  inherited Destroy;
end;

procedure THudInputText.Initialize(const AX, AY, AStartChar: Integer);
begin
  FLeftMargin := 0;
  FLastVisible := True;
  FLine.Initialize(AX, AY, AStartChar);
end;

procedure THudInputText.DeleteChar;
begin
  if FLine.Length <> FLeftMargin then
    FLine.DeleteChar;
end;

procedure THudInputText.Reset;
begin
  FLeftMargin := 0;
  FLine.Clear;
end;

function THudInputText.KeyIn(const AKey: Integer): Boolean;
begin
  Result := True;
  if (AKey >= FIRST_PRINTABLE) and (AKey <= LAST_PRINTABLE) then
    FLine.AddChar(Chr(AKey))
  else if AKey = FBackspace then
    DeleteChar
  else if AKey <> FEnter then
    Result := False;
end;

procedure THudInputText.PrepareErase(const AVisible: Boolean);
begin
  if FLastVisible and not AVisible then
    FLine.MarkChanged;
  FLastVisible := AVisible;
end;

end.
