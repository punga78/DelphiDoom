{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the declaration manager - the shared setup             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Decl.Support;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.IdLib.Core.Intf, DelphiDoom.Decl.Intf, DelphiDoom.Decl.Source.Memory,
  DelphiDoom.Tests.Scanner.IdFakes;

type
  /// <summary>A manager with the standard types over files in memory, and the log it writes to</summary>
  TDeclKit = class
  strict private
    FSource: TDeclMemorySource;
    FSourceIntf: IInterface;
    FLogObject: TFakeIdLibLog;
    FLog: IIdLibLog;
    FManager: IDeclManager;
  public
    constructor Create(const AStandard: Boolean = True);
    destructor Destroy; override;
    /// <summary>Builds the manager after the files are added (a folder is read when it is registered)</summary>
    procedure Start(const AStandard: Boolean = True; const ALoadFolders: Boolean = True;
      const APlaceholderMaterials: Boolean = False);
    property Source: TDeclMemorySource read FSource;
    property Manager: IDeclManager read FManager;
    function Lines: TStrings;
    function LogText: string;
  end;

implementation

uses
  DelphiDoom.Decl.Factory, DelphiDoom.Decl.StandardTypes, DelphiDoom.Decl.Types, DelphiDoom.Decl.Base;

{ TDeclKit }

constructor TDeclKit.Create(const AStandard: Boolean);
begin
  inherited Create;
  FSource := TDeclMemorySource.Create;
  FSourceIntf := FSource;
  FLogObject := TFakeIdLibLog.Create;
  FLog := FLogObject;
end;

destructor TDeclKit.Destroy;
begin
  FManager := nil;
  FLog := nil;
  FSourceIntf := nil;
  inherited Destroy;
end;

procedure TDeclKit.Start(const AStandard: Boolean; const ALoadFolders: Boolean;
  const APlaceholderMaterials: Boolean);
begin
  if AStandard and APlaceholderMaterials then
  begin
    // the materials of the golden of the C++ harness are stubs that keep the text and skip it
    FManager := TDeclFactory.CreateManager(FSource, FLog);
    // (the fx and the particles of that harness are stubs as well)
    TDeclStandardTypes.RegisterTypes(FManager.GetRegistry, [DECL_MATERIAL, DECL_FX, DECL_PARTICLE, DECL_SOUND]);
    TDeclStandardTypes.RegisterPlaceholderMaterial(FManager.GetRegistry);
    // (and so are the sound shaders: the golden of the manager has no data of theirs)
    FManager.GetRegistry.RegisterDeclType('sound', DECL_SOUND, function: IDecl begin Result := TDecl.Create; end);
    FManager.GetRegistry.RegisterDeclType('fx', DECL_FX, function: IDecl begin Result := TDecl.Create; end);
    FManager.GetRegistry.RegisterDeclType('particle', DECL_PARTICLE,
      function: IDecl begin Result := TDecl.Create; end);
    if ALoadFolders then
      TDeclStandardTypes.RegisterFolders(FManager.GetRegistry);
  end
  else if AStandard then
    FManager := TDeclFactory.CreateStandardManager(FSource, FLog, ALoadFolders)
  else
    FManager := TDeclFactory.CreateManager(FSource, FLog);
end;

function TDeclKit.Lines: TStrings;
begin
  Result := FLogObject.Lines;
end;

function TDeclKit.LogText: string;
begin
  Result := FLogObject.Lines.Text;
end;

end.
