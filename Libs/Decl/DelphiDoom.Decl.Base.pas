{******************************************************************************}
{                                                                              }
{  DelphiDoom: declaration manager - TDecl, the base of every declaration      }
{                                                                              }
{  Port of the declaration manager of Doom 3 (id Software, GPL v3):            }
{  framework\DeclManager.h (idDecl). Copyright (C) 1999-2011 id Software LLC,  }
{  a ZeniMax Media company.                                                    }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Base;

interface

uses
  System.SysUtils, DelphiDoom.IdLib.Core.Intf, DelphiDoom.IdLib.Text.Lexer, DelphiDoom.Decl.Types,
  DelphiDoom.Decl.Intf;

type
  /// <summary>
  ///   The base class of a declaration type (idDecl). Used as it is it is a declaration of a type
  ///   whose data is not read yet: the default definition is <c>{ }</c> and a parse only skips the braces
  ///   (this is what a type that is registered but not ported gets). A type overrides <c>Parse</c>,
  ///   <c>FreeData</c>, <c>DefaultDefinition</c> and, if it wants, <c>SetDefaultText</c>, <c>Size</c>,
  ///   <c>List</c> and <c>Print</c>; everything else goes to the manager through <c>Base</c>.
  ///   <para>Lifetime: reference counted; the manager holds one reference for as long as it lives. The
  ///   link to <c>Base</c> is not counted (the manager owns it).</para>
  /// </summary>
  TDecl = class(TInterfacedObject, IDecl)
  strict private
    FBase: IDeclBase;
  protected
    /// <summary>The bookkeeping of this declaration (nil only before the manager adopts the object)</summary>
    property Base: IDeclBase read FBase;
    /// <summary>
    ///   A lexer on the text of the declaration, flags set, the text before the first "{" skipped (the first lines
    ///   of every <c>Parse</c> of the original). The caller frees it.
    /// </summary>
    function OpenLexer(const AText: AnsiString; const AFlags: Integer = DECL_LEXER_FLAGS): TIdLexer;
  public
    procedure SetBase(const ABase: IDeclBase); virtual;
    function GetName: AnsiString;
    function GetDeclType: Integer;
    function GetState: TDeclState;
    function IsImplicit: Boolean;
    function IsValid: Boolean;
    procedure Invalidate;
    procedure Reload;
    procedure EnsureNotPurged;
    function GetIndex: Integer;
    function GetLineNum: Integer;
    function GetFileName: AnsiString;
    function GetText: AnsiString;
    function GetTextLength: Integer;
    procedure SetText(const AText: AnsiString);
    function ReplaceSourceFileText: Boolean;
    function SourceFileChanged: Boolean;
    procedure MakeDefault;
    function EverReferenced: Boolean;
    function GetFinder: IDeclFinder;
    function GetLog: IIdLibLog;
    /// <summary>
    ///   Sets the text to a default one if there is none (a skin with the name of a material); true if it did.
    ///   The default does nothing.
    /// </summary>
    function SetDefaultText: Boolean; virtual;
    /// <summary>A text that always parses: it starts with an open brace and ends with a close brace</summary>
    function DefaultDefinition: AnsiString; virtual;
    /// <summary>
    ///   The manager has already freed the data. The text is the whole declaration ("skin name { ... }").
    ///   A parse error is a warning followed by <c>MakeDefault</c>; the result is ignored by the manager.
    /// </summary>
    function Parse(const AText: AnsiString): Boolean; virtual;
    /// <summary>Frees what the subclass holds; it can be called before any <c>Parse</c></summary>
    procedure FreeData; virtual;
    function Size: NativeInt; virtual;
    /// <summary>The manager has written the reference mark and the index of the line already</summary>
    procedure List; virtual;
    /// <summary>Called after the text and the common data are printed</summary>
    procedure Print; virtual;
  end;

implementation

{ TDecl }

procedure TDecl.SetBase(const ABase: IDeclBase);
begin
  FBase := ABase;
end;

function TDecl.OpenLexer(const AText: AnsiString; const AFlags: Integer): TIdLexer;
begin
  Result := TIdLexer.Create(0, FBase.GetLog);
  try
    Result.LoadMemory(AText, Length(AText), FBase.GetFileName, FBase.GetLineNum);
    Result.Flags := AFlags;
    Result.SkipUntilString('{');
  except
    Result.Free;
    raise;
  end;
end;

function TDecl.GetName: AnsiString;
begin
  Result := FBase.GetName;
end;

function TDecl.GetDeclType: Integer;
begin
  Result := FBase.GetDeclType;
end;

function TDecl.GetState: TDeclState;
begin
  Result := FBase.GetState;
end;

function TDecl.IsImplicit: Boolean;
begin
  Result := FBase.IsImplicit;
end;

function TDecl.IsValid: Boolean;
begin
  Result := FBase.IsValid;
end;

procedure TDecl.Invalidate;
begin
  FBase.Invalidate;
end;

procedure TDecl.Reload;
begin
  FBase.Reload;
end;

procedure TDecl.EnsureNotPurged;
begin
  FBase.EnsureNotPurged;
end;

function TDecl.GetIndex: Integer;
begin
  Result := FBase.GetIndex;
end;

function TDecl.GetLineNum: Integer;
begin
  Result := FBase.GetLineNum;
end;

function TDecl.GetFileName: AnsiString;
begin
  Result := FBase.GetFileName;
end;

function TDecl.GetText: AnsiString;
begin
  Result := FBase.GetText;
end;

function TDecl.GetTextLength: Integer;
begin
  Result := FBase.GetTextLength;
end;

procedure TDecl.SetText(const AText: AnsiString);
begin
  FBase.SetText(AText);
end;

function TDecl.ReplaceSourceFileText: Boolean;
begin
  Result := FBase.ReplaceSourceFileText;
end;

function TDecl.SourceFileChanged: Boolean;
begin
  Result := FBase.SourceFileChanged;
end;

procedure TDecl.MakeDefault;
begin
  FBase.MakeDefault;
end;

function TDecl.EverReferenced: Boolean;
begin
  Result := FBase.EverReferenced;
end;

function TDecl.GetFinder: IDeclFinder;
begin
  Result := FBase.GetFinder;
end;

function TDecl.GetLog: IIdLibLog;
begin
  Result := FBase.GetLog;
end;

function TDecl.SetDefaultText: Boolean;
begin
  Result := FBase.SetDefaultText;
end;

function TDecl.DefaultDefinition: AnsiString;
begin
  Result := FBase.DefaultDefinition;
end;

function TDecl.Parse(const AText: AnsiString): Boolean;
begin
  Result := FBase.Parse(AText);
end;

procedure TDecl.FreeData;
begin
  FBase.FreeData;
end;

function TDecl.Size: NativeInt;
begin
  Result := FBase.Size;
end;

procedure TDecl.List;
begin
  FBase.List;
end;

procedure TDecl.Print;
begin
  FBase.Print;
end;

end.
