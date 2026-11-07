{******************************************************************************}
{                                                                              }
{  DD_IDE: the composition root of the script ide                              }
{  Copyright (C) 2016-2022 by Jim Valavanis (original DD_IDE)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Ide.Composition;

interface

uses
  System.SysUtils,
  DelphiDoom.Ide.Intf,
  DelphiDoom.Ide.MessageLog,
  DelphiDoom.Ide.SearchSettings,
  DelphiDoom.Ide.Pk3Builder,
  DelphiDoom.Ide.ExampleStore;

type
  /// <summary>
  ///   The one place that knows the classes of Windows and of the compiler dlls and makes them: the
  ///   program creates it, gives it to the windows (which ask it for what they need), and frees it
  ///   when it closes. The windows only know the interfaces of the ide library
  /// </summary>
  TIdeServices = class
  strict private
    FTitle: string;
    FDeveloperMode: Boolean;
    FFileSystem: IIdeFileSystem;
    FClock: IIdeClock;
    FBusy: IIdeBusy;
    FClipboard: IIdeClipboard;
    FMessageDialogs: IIdeMessageDialogs;
    FCompiler: IIdeScriptCompiler;
    FGameLibrary: IIdeGameLibrary;
    FLog: TIdeMessageLog;
    FLogIntf: IIdeLog;
    FSearch: TIdeSearchSettings;
    FPk3Builder: TIdePk3Builder;
  public
    constructor Create(const ATitle: string);
    destructor Destroy; override;
    /// <summary>The store of the examples of a panel; they can be edited only with -devparm</summary>
    function CreateExampleStore(const AFolderName, AExtension: string): TIdeExampleStore;
    /// <summary>The text of the version of the program</summary>
    function VersionText: string;
    property Title: string read FTitle;
    property FileSystem: IIdeFileSystem read FFileSystem;
    property Clock: IIdeClock read FClock;
    property Busy: IIdeBusy read FBusy;
    property Clipboard: IIdeClipboard read FClipboard;
    property MessageDialogs: IIdeMessageDialogs read FMessageDialogs;
    property Compiler: IIdeScriptCompiler read FCompiler;
    property GameLibrary: IIdeGameLibrary read FGameLibrary;
    property Log: TIdeMessageLog read FLog;
    property LogIntf: IIdeLog read FLogIntf;
    property Search: TIdeSearchSettings read FSearch;
    property Pk3Builder: TIdePk3Builder read FPk3Builder;
  end;

implementation

uses
  DelphiDoom.Ide.Win.FileSystem,
  DelphiDoom.Ide.Win.Services,
  DelphiDoom.Ide.Win.DdcLibrary,
  DelphiDoom.Ide.Win.Archive,
  ide_version;

{ TIdeServices }

constructor TIdeServices.Create(const ATitle: string);
var
  LDdc: TDdcIdeLibrary;
  LIndex: Integer;
begin
  inherited Create;
  FTitle := ATitle;
  FDeveloperMode := False;
  for LIndex := 1 to ParamCount do
    if SameText(ParamStr(LIndex), '-devparm') then
      FDeveloperMode := True;
  FFileSystem := TWindowsIdeFileSystem.Create;
  FClock := TWindowsIdeClock.Create;
  FBusy := TVclIdeBusy.Create;
  FClipboard := TVclIdeClipboard.Create;
  FMessageDialogs := TVclIdeMessageDialogs.Create(ATitle);
  LDdc := TDdcIdeLibrary.Create;
  FCompiler := LDdc;
  FGameLibrary := LDdc;
  FLog := TIdeMessageLog.Create;
  FLogIntf := FLog;
  FSearch := TIdeSearchSettings.Create;
  FPk3Builder := TIdePk3Builder.Create(
    function: IIdeArchive
    begin
      Result := TZipIdeArchive.Create;
    end, FLogIntf, FClock);
end;

destructor TIdeServices.Destroy;
begin
  FPk3Builder.Free;
  FSearch.Free;
  inherited Destroy;
end;

function TIdeServices.CreateExampleStore(const AFolderName, AExtension: string): TIdeExampleStore;
begin
  Result := TIdeExampleStore.Create(FFileSystem, AFolderName, AExtension, not FDeveloperMode);
end;

function TIdeServices.VersionText: string;
begin
  Result := I_VersionBuilt;
end;

end.
