{******************************************************************************}
{                                                                              }
{  DelphiDoom: gui library - TGuiUserInterfaceManager, the registry of guis    }
{                                                                              }
{  Port of idUserInterfaceManagerLocal (ui\UserInterface.cpp, id Software,     }
{  GPL v3): the guis that were read, shared when they are not interactive,     }
{  reloaded when the file is newer, purged after a level; it owns the device   }
{  context of the guis. Copyright (C) 1999-2011 id Software LLC, a ZeniMax     }
{  Media company.                                                              }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3 or (at your       }
{  option) any later version, with the additional terms of the Doom 3 Source   }
{  Code License (Reference\doom3\COPYING.txt: preservation of legal notices    }
{  and trademarks, no use of the licensors' names for publicity, warranty      }
{  disclaimer). The repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.Manager;

interface

uses
  System.Classes, System.Generics.Collections, DelphiDoom.IdLib.Core.Intf, DelphiDoom.Gui.Cvars.Intf,
  DelphiDoom.Gui.Material.Intf, DelphiDoom.Gui.DeviceContext.Intf, DelphiDoom.Gui.DrawContext,
  DelphiDoom.Gui.Window.Keys, DelphiDoom.Gui.Window.Intf, DelphiDoom.Gui.Regs.Intf, DelphiDoom.Gui.UserInterface,
  DelphiDoom.Gui.ListGui;

type
  /// <summary>
  ///   Whether a material still refers to the gui (<c>material->GlobalGui() == gui</c>): a gui that a material uses
  ///   is not purged by EndLevelLoad. Nil: no material does.
  /// </summary>
  TGuiGlobalGuiCheck = reference to function(const AGui: TGuiUserInterface): Boolean;

  /// <summary>
  ///   idUserInterfaceManagerLocal. <c>Init</c> makes the device context (the surface and the lookups are given to the
  ///   constructor); the guis it creates share it. The manager owns the guis and the demo guis.
  /// </summary>
  TGuiUserInterfaceManager = class
  strict private
    FFileSystem: IIdLibFileSystem;
    FLog: IIdLibLog;
    FSurface: IGuiDeviceContext;
    FMaterials: IGuiMaterialLookup;
    FCvars: IGuiCvars;
    FKeys: IGuiKeyState;
    FGameHost: IGuiGameHost;
    FLanguage: IGuiLanguage;
    FTables: IGuiTables;
    FGuis: TObjectList<TGuiUserInterface>;
    FDemoGuis: TObjectList<TGuiUserInterface>;
    FDrawContext: TGuiDrawContext;
    FGlobalGuiCheck: TGuiGlobalGuiCheck;
    FFrameTime: Integer;
    function GetDrawContext: TGuiDrawContext;
    function GetCount: Integer;
    function GetGuis(const AIndex: Integer): TGuiUserInterface;
  public
    constructor Create(const AFileSystem: IIdLibFileSystem; const ALog: IIdLibLog; const ASurface: IGuiDeviceContext;
      const AMaterials: IGuiMaterialLookup; const ACvars: IGuiCvars; const AKeys: IGuiKeyState = nil;
      const AGameHost: IGuiGameHost = nil; const ALanguage: IGuiLanguage = nil; const ATables: IGuiTables = nil);
    destructor Destroy; override;
    /// <summary>Init: the device context</summary>
    procedure Init;
    procedure Shutdown;
    /// <summary>Touch: reads a gui (it is kept in the list)</summary>
    procedure Touch(const AName: AnsiString);
    /// <summary>WritePrecacheCommands: a line "touchGui name" for each gui, to the list and to the log</summary>
    procedure WritePrecacheCommands(const ALines: TStrings);
    /// <summary>SetSize: the size of the screen of the device context</summary>
    procedure SetSize(const AWidth, AHeight: Single);
    /// <summary>BeginLevelLoad: the guis that are not menus lose their users</summary>
    procedure BeginLevelLoad;
    /// <summary>EndLevelLoad: the guis nobody uses (and no material refers to) are freed</summary>
    procedure EndLevelLoad;
    /// <summary>Reload: a gui whose file is newer (or all of them) is read again</summary>
    procedure Reload(const AAll: Boolean);
    /// <summary>ListGuis: the list of the guis to the log</summary>
    procedure ListGuis;
    function CheckGui(const AName: AnsiString): Boolean;
    /// <summary>Alloc: a gui that is not in the list until it reads a file</summary>
    function Alloc: TGuiUserInterface;
    procedure DeAlloc(const AGui: TGuiUserInterface);
    /// <summary>
    ///   FindGui: the gui of a name that can be shared (its count of users grows), or a new one read from the file when
    ///   <c>AAutoLoad</c> is set; nil if there is none
    /// </summary>
    function FindGui(const AName: AnsiString; const AAutoLoad: Boolean = False; const ANeedUnique: Boolean = False;
      const AForceNotUnique: Boolean = False): TGuiUserInterface;
    function FindDemoGui(const AName: AnsiString): TGuiUserInterface;
    function AllocListGui: TGuiListGui;
    /// <summary>A gui given to the manager as a demo gui (it is owned)</summary>
    procedure AddDemoGui(const AGui: TGuiUserInterface);
    property DrawContext: TGuiDrawContext read GetDrawContext;
    property GlobalGuiCheck: TGuiGlobalGuiCheck read FGlobalGuiCheck write FGlobalGuiCheck;
    property FrameTime: Integer read FFrameTime write FFrameTime;
    property Count: Integer read GetCount;
    property Guis[const AIndex: Integer]: TGuiUserInterface read GetGuis;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.IdLib.Text.Strings, DelphiDoom.Gui.Window, DelphiDoom.Gui.Window.Types,
  DelphiDoom.Gui.Window.Factory;

constructor TGuiUserInterfaceManager.Create(const AFileSystem: IIdLibFileSystem; const ALog: IIdLibLog;
  const ASurface: IGuiDeviceContext; const AMaterials: IGuiMaterialLookup; const ACvars: IGuiCvars;
  const AKeys: IGuiKeyState; const AGameHost: IGuiGameHost; const ALanguage: IGuiLanguage; const ATables: IGuiTables);
begin
  inherited Create;
  FFileSystem := AFileSystem;
  FLog := ALog;
  FSurface := ASurface;
  FMaterials := AMaterials;
  FCvars := ACvars;
  FKeys := AKeys;
  FGameHost := AGameHost;
  FLanguage := ALanguage;
  FTables := ATables;
  FGuis := TObjectList<TGuiUserInterface>.Create(True);
  FDemoGuis := TObjectList<TGuiUserInterface>.Create(True);
end;

destructor TGuiUserInterfaceManager.Destroy;
begin
  FDemoGuis.Free;
  FGuis.Free;
  FDrawContext.Free;
  inherited Destroy;
end;

function TGuiUserInterfaceManager.GetDrawContext: TGuiDrawContext;
begin
  Result := FDrawContext;
end;

function TGuiUserInterfaceManager.GetCount: Integer;
begin
  Result := FGuis.Count;
end;

function TGuiUserInterfaceManager.GetGuis(const AIndex: Integer): TGuiUserInterface;
begin
  Result := FGuis[AIndex];
end;

procedure TGuiUserInterfaceManager.Init;
begin
  FreeAndNil(FDrawContext);
  FDrawContext := TGuiDrawContext.Create(FSurface, FMaterials, FFileSystem, FLog, FCvars);
  FDrawContext.Initialize;
end;

procedure TGuiUserInterfaceManager.Shutdown;
begin
  FGuis.Clear;
  FDemoGuis.Clear;
  if Assigned(FDrawContext) then
    FDrawContext.Shutdown;
end;

function TGuiUserInterfaceManager.Alloc: TGuiUserInterface;
begin
  Result := TGuiUserInterface.Create(FFileSystem, FLog, TGuiWindowFactory.Create, FGameHost, FLanguage, FTables,
    FDrawContext);
  Result.Context.DrawContext := FDrawContext;
  Result.Context.Materials := FMaterials;
  Result.Context.Cvars := FCvars;
  Result.Context.Keys := FKeys;
  Result.OnRead := procedure(const AGui: TGuiUserInterface)
    begin
      if FGuis.IndexOf(AGui) < 0 then
        FGuis.Add(AGui);
    end;
end;

procedure TGuiUserInterfaceManager.Touch(const AName: AnsiString);
var
  LGui: TGuiUserInterface;
begin
  LGui := Alloc;
  if not LGui.InitFromFile(AName) then
    LGui.Free;
end;

procedure TGuiUserInterfaceManager.WritePrecacheCommands(const ALines: TStrings);
var
  LIndex: Integer;
  LText: string;
begin
  for LIndex := 0 to FGuis.Count - 1 do
  begin
    LText := Format('touchGui %s'#10, [string(FGuis[LIndex].SourceFile)]);
    if Assigned(FLog) then
      FLog.Printf(LText);
    ALines.Add(Format('touchGui %s', [string(FGuis[LIndex].SourceFile)]));
  end;
end;

procedure TGuiUserInterfaceManager.SetSize(const AWidth, AHeight: Single);
begin
  FDrawContext.SetSize(AWidth, AHeight);
end;

procedure TGuiUserInterfaceManager.BeginLevelLoad;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FGuis.Count - 1 do
    if (FGuis[LIndex].Desktop.Flags and WIN_MENUGUI) = 0 then
      FGuis[LIndex].ClearRefs;
end;

procedure TGuiUserInterfaceManager.EndLevelLoad;
var
  LIndex: Integer;
  LRemove: Boolean;
begin
  LIndex := 0;
  while LIndex < FGuis.Count do
  begin
    if FGuis[LIndex].Refs = 0 then
    begin
      // use this to make sure no materials still reference this gui
      LRemove := not (Assigned(FGlobalGuiCheck) and FGlobalGuiCheck(FGuis[LIndex]));
      if LRemove then
      begin
        FGuis.Delete(LIndex);
        Continue;
      end;
    end;
    Inc(LIndex);
  end;
end;

procedure TGuiUserInterfaceManager.Reload(const AAll: Boolean);
var
  LIndex: Integer;
  LFile: TIdLibFileData;
  LName: AnsiString;
begin
  for LIndex := 0 to FGuis.Count - 1 do
  begin
    LName := FGuis[LIndex].SourceFile;
    if not AAll then
    begin
      if not FFileSystem.TryReadFile(LName, False, LFile) then
        LFile.Timestamp := 0;
      if LFile.Timestamp <= FGuis[LIndex].TimeStamp then
        Continue;
    end;
    FGuis[LIndex].InitFromFile(LName);
    if Assigned(FLog) then
      FLog.Printf(Format('reloading %s.'#10, [string(LName)]));
  end;
end;

procedure TGuiUserInterfaceManager.ListGuis;
var
  LIndex, LCopies, LUnique: Integer;
  LUniqueText: string;
begin
  if not Assigned(FLog) then
    Exit;
  FLog.Printf(#10'   size   refs   name'#10);
  LCopies := 0;
  LUnique := 0;
  for LIndex := 0 to FGuis.Count - 1 do
  begin
    // the size in memory is not kept: 0.0k
    if FGuis[LIndex].Interactive then
    begin
      Inc(LUnique);
      LUniqueText := 'unique';
    end
    else
    begin
      Inc(LCopies);
      LUniqueText := 'copy';
    end;
    FLog.Printf(Format('%6.1fk %4d (%s) %s ( %d transitions )'#10, [0.0, FGuis[LIndex].Refs, LUniqueText,
      string(FGuis[LIndex].SourceFile), FGuis[LIndex].Desktop.NumTransitions]));
  end;
  FLog.Printf(Format('==========='#10'  %d total Guis ( %d copies, %d unique ), %.2f total Mbytes',
    [FGuis.Count, LCopies, LUnique, 0.0]));
end;

function TGuiUserInterfaceManager.CheckGui(const AName: AnsiString): Boolean;
var
  LFile: TIdLibFileData;
begin
  Result := FFileSystem.TryReadFile(AName, False, LFile);
end;

procedure TGuiUserInterfaceManager.DeAlloc(const AGui: TGuiUserInterface);
begin
  if Assigned(AGui) then
    FGuis.Remove(AGui);
end;

function TGuiUserInterfaceManager.FindGui(const AName: AnsiString; const AAutoLoad, ANeedUnique,
  AForceNotUnique: Boolean): TGuiUserInterface;
var
  LIndex: Integer;
  LGui: TGuiUserInterface;
begin
  for LIndex := 0 to FGuis.Count - 1 do
    if TIdStrings.Icmp(FGuis[LIndex].SourceFile, AName) = 0 then
    begin
      if (not AForceNotUnique) and (ANeedUnique or FGuis[LIndex].Interactive) then
        Break;
      FGuis[LIndex].AddRef;
      Exit(FGuis[LIndex]);
    end;
  Result := nil;
  if AAutoLoad then
  begin
    LGui := Alloc;
    if LGui.InitFromFile(AName) then
    begin
      LGui.Uniqued := (not AForceNotUnique) and ANeedUnique;
      Result := LGui;
    end
    else
    begin
      FGuis.Remove(LGui);
      LGui.Free;
    end;
  end;
end;

function TGuiUserInterfaceManager.FindDemoGui(const AName: AnsiString): TGuiUserInterface;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FDemoGuis.Count - 1 do
    if TIdStrings.Icmp(FDemoGuis[LIndex].SourceFile, AName) = 0 then
      Exit(FDemoGuis[LIndex]);
  Result := nil;
end;

procedure TGuiUserInterfaceManager.AddDemoGui(const AGui: TGuiUserInterface);
begin
  FDemoGuis.Add(AGui);
end;

function TGuiUserInterfaceManager.AllocListGui: TGuiListGui;
begin
  Result := TGuiListGui.Create;
end;

end.
