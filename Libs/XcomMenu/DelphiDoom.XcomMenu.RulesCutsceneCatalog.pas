{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom menu library - the cutscenes of the ruleset and the files   }
{  of the loaded mod                                                            }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMenu.RulesCutsceneCatalog;

interface

uses
  System.SysUtils, DelphiDoom.XcomMod.RuleVideo, DelphiDoom.XcomEngine.Rules.Intf, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomMenu.CutsceneCatalog.Intf;

type
  /// <summary>IXcomCutsceneCatalog over the rules of the game (IXcomGameRules: the ruleset and the files of the mod)</summary>
  TXcomRulesCutsceneCatalog = class(TInterfacedObject, IXcomCutsceneCatalog)
  strict private
    FRules: IXcomGameRules;
    class procedure SplitPath(const AVirtualPath: string; out AFolder, AName: string); static;
  public
    constructor Create(const ARules: IXcomGameRules);
    /// <summary>The catalog of the data of the host; nil when the data have no rules (before the load, in the tests)</summary>
    class function FromHost(AHost: TXcomStateHost): IXcomCutsceneCatalog; static;
    function FindCutscene(const AId: string): TXcomRuleVideo;
    function FileExists(const AVirtualPath: string): Boolean;
    function LoadBytes(const AVirtualPath: string): TBytes;
  end;

implementation

{ TXcomRulesCutsceneCatalog }

constructor TXcomRulesCutsceneCatalog.Create(const ARules: IXcomGameRules);
begin
  inherited Create;
  FRules := ARules;
end;

class function TXcomRulesCutsceneCatalog.FromHost(AHost: TXcomStateHost): IXcomCutsceneCatalog;
var
  LRules: IXcomGameRules;
begin
  Result := nil;
  if Supports(AHost.Resources, IXcomGameRules, LRules) and (LRules.Ruleset <> nil) and (LRules.ModFiles <> nil) then
    Result := TXcomRulesCutsceneCatalog.Create(LRules);
end;

class procedure TXcomRulesCutsceneCatalog.SplitPath(const AVirtualPath: string; out AFolder, AName: string);
var
  LPath: string;
  LSlash: Integer;
begin
  LPath := AVirtualPath.Replace('\', '/');
  LSlash := LPath.LastIndexOf('/');
  AFolder := LPath.Substring(0, LSlash);
  AName := LPath.Substring(LSlash + 1);
end;

function TXcomRulesCutsceneCatalog.FindCutscene(const AId: string): TXcomRuleVideo;
begin
  Result := FRules.Ruleset.Videos.Find(AId);
end;

function TXcomRulesCutsceneCatalog.FileExists(const AVirtualPath: string): Boolean;
var
  LFolder: string;
  LName: string;
  LEntry: string;
begin
  SplitPath(AVirtualPath, LFolder, LName);
  for LEntry in FRules.ModFiles.FolderContents(LFolder) do
    if SameText(LEntry, LName) then
      Exit(True);
  Result := False;
end;

function TXcomRulesCutsceneCatalog.LoadBytes(const AVirtualPath: string): TBytes;
begin
  Result := FRules.ModFiles.LoadBytes(AVirtualPath);
end;

end.
