{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - the help texts as files next to the data          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.HelpFiles;

interface

uses
  System.SysUtils, DelphiDoom.Keen.Intf, DelphiDoom.Keen.UserIntf;

const
  /// <summary>The files of the three help buttons, in their order: "I'm lost", the controls, the story</summary>
  KEEN_HELP_FILE_NAMES: array[0..2] of string = ('GAMETEXT.KDR', 'CONTEXT.KDR', 'STORY.KDR');

type
  /// <summary>
  ///   The original program has the three help texts linked inside it (static\GAMETEXT.KDR, CONTEXT.KDR and
  ///   STORY.KDR of the sources). Here they are files that are looked for with the data: a game that does not
  ///   have them shows an error instead of the text
  /// </summary>
  TKeenHelpFiles = class(TInterfacedObject, IKeenHelpTexts)
  strict private
    FFiles: IKeenDataFiles;
  public
    constructor Create(const AFiles: IKeenDataFiles);
    function TryGetText(AIndex: Integer; out AText: TBytes): Boolean;
  end;

implementation

{ TKeenHelpFiles }

constructor TKeenHelpFiles.Create(const AFiles: IKeenDataFiles);
begin
  inherited Create;
  if not Assigned(AFiles) then
    raise EArgumentNilException.Create('AFiles');
  FFiles := AFiles;
end;

function TKeenHelpFiles.TryGetText(AIndex: Integer; out AText: TBytes): Boolean;
begin
  AText := nil;
  Result := (AIndex >= Low(KEEN_HELP_FILE_NAMES)) and (AIndex <= High(KEEN_HELP_FILE_NAMES)) and
    FFiles.Exists(KEEN_HELP_FILE_NAMES[AIndex]);
  if Result then
    AText := FFiles.ReadAll(KEEN_HELP_FILE_NAMES[AIndex]);
end;

end.
