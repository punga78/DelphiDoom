//------------------------------------------------------------------------------
//
//  DD_IDE: DelphiDoom Script IDE
//  Copyright (C) 2016-2022 by Jim Valavanis
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

program DD_IDE;

{$DESCRIPTION 'DelphiDoom Script IDE'}

uses
  DelphiDoom.Platform.Types in '..\Libs\Platform\DelphiDoom.Platform.Types.pas',
  DelphiDoom.Platform.DataFolder.Intf in '..\Libs\Platform\DelphiDoom.Platform.DataFolder.Intf.pas',
  DelphiDoom.Platform.DataFolder in '..\Libs\Platform\DelphiDoom.Platform.DataFolder.pas',
  DelphiDoom.Platform.DataFolder.Disk in '..\Libs\Platform\DelphiDoom.Platform.DataFolder.Disk.pas',
  DelphiDoom.Platform.DataFolder.Factory in '..\Libs\Platform\DelphiDoom.Platform.DataFolder.Factory.pas',
  Forms,
  main in '..\DD_IDE\main.pas' {Form1},
  DelphiDoom.Ide.Types in '..\Libs\Ide\DelphiDoom.Ide.Types.pas',
  DelphiDoom.Ide.Messages in '..\Libs\Ide\DelphiDoom.Ide.Messages.pas',
  DelphiDoom.Ide.Intf in '..\Libs\Ide\DelphiDoom.Ide.Intf.pas',
  DelphiDoom.Ide.Text in '..\Libs\Ide\DelphiDoom.Ide.Text.pas',
  DelphiDoom.Ide.ItemKinds in '..\Libs\Ide\DelphiDoom.Ide.ItemKinds.pas',
  DelphiDoom.Ide.Games in '..\Libs\Ide\DelphiDoom.Ide.Games.pas',
  DelphiDoom.Ide.ProjectFormat in '..\Libs\Ide\DelphiDoom.Ide.ProjectFormat.pas',
  DelphiDoom.Ide.UncountedObject in '..\Libs\Ide\DelphiDoom.Ide.UncountedObject.pas',
  DelphiDoom.Ide.UndoHistory in '..\Libs\Ide\DelphiDoom.Ide.UndoHistory.pas',
  DelphiDoom.Ide.Document in '..\Libs\Ide\DelphiDoom.Ide.Document.pas',
  DelphiDoom.Ide.ProjectItem in '..\Libs\Ide\DelphiDoom.Ide.ProjectItem.pas',
  DelphiDoom.Ide.Project in '..\Libs\Ide\DelphiDoom.Ide.Project.pas',
  DelphiDoom.Ide.Pk3Builder in '..\Libs\Ide\DelphiDoom.Ide.Pk3Builder.pas',
  DelphiDoom.Ide.CompilerMessages in '..\Libs\Ide\DelphiDoom.Ide.CompilerMessages.pas',
  DelphiDoom.Ide.PCodeFile in '..\Libs\Ide\DelphiDoom.Ide.PCodeFile.pas',
  DelphiDoom.Ide.CompileCommand in '..\Libs\Ide\DelphiDoom.Ide.CompileCommand.pas',
  DelphiDoom.Ide.Csv in '..\Libs\Ide\DelphiDoom.Ide.Csv.pas',
  DelphiDoom.Ide.Outline in '..\Libs\Ide\DelphiDoom.Ide.Outline.pas',
  DelphiDoom.Ide.RowSorter in '..\Libs\Ide\DelphiDoom.Ide.RowSorter.pas',
  DelphiDoom.Ide.LibraryTable in '..\Libs\Ide\DelphiDoom.Ide.LibraryTable.pas',
  DelphiDoom.Ide.NameValueTable in '..\Libs\Ide\DelphiDoom.Ide.NameValueTable.pas',
  DelphiDoom.Ide.ActorDefFunctionTable in '..\Libs\Ide\DelphiDoom.Ide.ActorDefFunctionTable.pas',
  DelphiDoom.Ide.UnitFunctionTable in '..\Libs\Ide\DelphiDoom.Ide.UnitFunctionTable.pas',
  DelphiDoom.Ide.FieldFormatter in '..\Libs\Ide\DelphiDoom.Ide.FieldFormatter.pas',
  DelphiDoom.Ide.StateTables in '..\Libs\Ide\DelphiDoom.Ide.StateTables.pas',
  DelphiDoom.Ide.StateCatalog in '..\Libs\Ide\DelphiDoom.Ide.StateCatalog.pas',
  DelphiDoom.Ide.MobjinfoCatalog in '..\Libs\Ide\DelphiDoom.Ide.MobjinfoCatalog.pas',
  DelphiDoom.Ide.ClassCatalog in '..\Libs\Ide\DelphiDoom.Ide.ClassCatalog.pas',
  DelphiDoom.Ide.SpriteCatalog in '..\Libs\Ide\DelphiDoom.Ide.SpriteCatalog.pas',
  DelphiDoom.Ide.ExampleStore in '..\Libs\Ide\DelphiDoom.Ide.ExampleStore.pas',
  DelphiDoom.Ide.ParameterHints in '..\Libs\Ide\DelphiDoom.Ide.ParameterHints.pas',
  DelphiDoom.Ide.SearchHistory in '..\Libs\Ide\DelphiDoom.Ide.SearchHistory.pas',
  DelphiDoom.Ide.SearchSettings in '..\Libs\Ide\DelphiDoom.Ide.SearchSettings.pas',
  DelphiDoom.Ide.SearchPlan in '..\Libs\Ide\DelphiDoom.Ide.SearchPlan.pas',
  DelphiDoom.Ide.MessageLog in '..\Libs\Ide\DelphiDoom.Ide.MessageLog.pas',
  DelphiDoom.Ide.ProjectOutline in '..\Libs\Ide\DelphiDoom.Ide.ProjectOutline.pas',
  DelphiDoom.Ide.EventSnippets in '..\Libs\Ide\DelphiDoom.Ide.EventSnippets.pas',
  DelphiDoom.Ide.Views.Intf in '..\Libs\Ide\DelphiDoom.Ide.Views.Intf.pas',
  DelphiDoom.Ide.MainPresenter in '..\Libs\Ide\DelphiDoom.Ide.MainPresenter.pas',
  DelphiDoom.Ide.ScriptEditorPresenter in '..\Libs\Ide\DelphiDoom.Ide.ScriptEditorPresenter.pas',
  DelphiDoom.Ide.Win.FileSystem in '..\DD_IDE\DelphiDoom.Ide.Win.FileSystem.pas',
  DelphiDoom.Ide.Win.Services in '..\DD_IDE\DelphiDoom.Ide.Win.Services.pas',
  DelphiDoom.Ide.Win.DdcLibrary in '..\DD_IDE\DelphiDoom.Ide.Win.DdcLibrary.pas',
  DelphiDoom.Ide.Win.Archive in '..\DD_IDE\DelphiDoom.Ide.Win.Archive.pas',
  DelphiDoom.Ide.Win.FileDialogs in '..\DD_IDE\DelphiDoom.Ide.Win.FileDialogs.pas',
  DelphiDoom.Ide.Vcl.ExampleEdit in '..\DD_IDE\DelphiDoom.Ide.Vcl.ExampleEdit.pas',
  DelphiDoom.Ide.Vcl.ListPanel in '..\DD_IDE\DelphiDoom.Ide.Vcl.ListPanel.pas',
  DelphiDoom.Ide.Vcl.TreePanel in '..\DD_IDE\DelphiDoom.Ide.Vcl.TreePanel.pas',
  DelphiDoom.Ide.Composition in '..\DD_IDE\DelphiDoom.Ide.Composition.pas',
  SynEdit in '..\DD_IDE\SynEdit\SynEdit.pas',
  SynEditHighlighter in '..\DD_IDE\SynEdit\SynEditHighlighter.pas',
  SynEditHighlighterOptions in '..\DD_IDE\SynEdit\SynEditHighlighterOptions.pas',
  SynEditKbdHandler in '..\DD_IDE\SynEdit\SynEditKbdHandler.pas',
  SynEditKeyCmds in '..\DD_IDE\SynEdit\SynEditKeyCmds.pas',
  SynEditKeyConst in '..\DD_IDE\SynEdit\SynEditKeyConst.pas',
  SynEditMiscClasses in '..\DD_IDE\SynEdit\SynEditMiscClasses.pas',
  SynEditMiscProcs in '..\DD_IDE\SynEdit\SynEditMiscProcs.pas',
  SynEditStrConst in '..\DD_IDE\SynEdit\SynEditStrConst.pas',
  SynEditTextBuffer in '..\DD_IDE\SynEdit\SynEditTextBuffer.pas',
  SynEditTypes in '..\DD_IDE\SynEdit\SynEditTypes.pas',
  SynEditWordWrap in '..\DD_IDE\SynEdit\SynEditWordWrap.pas',
  SynHighlighterMulti in '..\DD_IDE\SynEdit\SynHighlighterMulti.pas',
  SynRegExpr in '..\DD_IDE\SynEdit\SynRegExpr.pas',
  SynTextDrawer in '..\DD_IDE\SynEdit\SynTextDrawer.pas',
  SynUnicode in '..\DD_IDE\SynEdit\SynUnicode.pas',
  SynHighlighterActorDef in '..\DD_IDE\SynEdit\SynHighlighterActorDef.pas',
  SynHighlighterDDDisasm in '..\DD_IDE\SynEdit\SynHighlighterDDDisasm.pas',
  SynEditRegexSearch in '..\DD_IDE\SynEdit\SynEditRegexSearch.pas',
  SynEditSearch in '..\DD_IDE\SynEdit\SynEditSearch.pas',
  SynEditPrintTypes in '..\DD_IDE\SynEdit\SynEditPrintTypes.pas',
  SynEditPrint in '..\DD_IDE\SynEdit\SynEditPrint.pas',
  SynEditPrinterInfo in '..\DD_IDE\SynEdit\SynEditPrinterInfo.pas',
  SynEditPrintHeaderFooter in '..\DD_IDE\SynEdit\SynEditPrintHeaderFooter.pas',
  SynEditPrintMargins in '..\DD_IDE\SynEdit\SynEditPrintMargins.pas',
  SynEditPrintPreview in '..\DD_IDE\SynEdit\SynEditPrintPreview.pas',
  SynCompletionProposal in '..\DD_IDE\SynEdit\SynCompletionProposal.pas',
  frm_projectmanager in '..\DD_IDE\frm_projectmanager.pas' {Frame_ProjectManager: TFrame},
  frm_scripteditor in '..\DD_IDE\frm_scripteditor.pas' {Frame_ScriptEditor: TFrame},
  frm_GotoLine in '..\DD_IDE\frm_GotoLine.pas' {frmGotoLine},
  ide_version in '..\DD_IDE\ide_version.pas',
  ide_zipfile in '..\DD_IDE\ide_zipfile.pas',
  frm_SearchText in '..\DD_IDE\frm_SearchText.pas' {TextSearchDialog},
  frm_ReplaceText in '..\DD_IDE\frm_ReplaceText.pas' {TextReplaceDialog},
  frm_ConfirmReplace in '..\DD_IDE\frm_ConfirmReplace.pas' {ConfirmReplaceDialog},
  frm_message in '..\DD_IDE\frm_message.pas' {frmMessage},
  ddc_base in '..\Libs\Ddc\ddc_base.pas',
  frm_unitfunctions in '..\DD_IDE\frm_unitfunctions.pas' {Frame_UnitFunctions: TFrame},
  frm_PageSetup in '..\DD_IDE\SynEdit\frm_PageSetup.pas' {PageSetupDlg},
  frm_PrintPreview in '..\DD_IDE\SynEdit\frm_PrintPreview.pas' {ScriptPrintPreviewDlg},
  frm_constants in '..\DD_IDE\frm_constants.pas' {Frame_Constants: TFrame},
  frm_variables in '..\DD_IDE\frm_variables.pas' {Frame_Variables: TFrame},
  frm_classes in '..\DD_IDE\frm_classes.pas' {Frame_Classes: TFrame},
  frm_types in '..\DD_IDE\frm_types.pas' {Frame_Types: TFrame},
  SynHighlighterDDScript in '..\DD_IDE\SynEdit\SynHighlighterDDScript.pas',
  frm_actordef in '..\DD_IDE\frm_actordef.pas' {Frame_Actordef: TFrame},
  frm_mobjinfo in '..\DD_IDE\frm_mobjinfo.pas' {Frame_Mobjinfo: TFrame},
  frm_states in '..\DD_IDE\frm_states.pas' {Frame_States: TFrame},
  frm_sprites in '..\DD_IDE\frm_sprites.pas' {Frame_Sprites: TFrame};

{$R *.res}
{$R 'DD_IDE_Icon.res' 'DD_IDE_Icon.rc'}

var
  CommandLineProject: string;

begin
  Application.Initialize;
  Application.Title := 'DelphiDOOM Script IDE';
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TPageSetupDlg, PageSetupDlg);
  Application.CreateForm(TScriptPrintPreviewDlg, ScriptPrintPreviewDlg);
  // the composition root: the main window owns the services from here on
  Form1.Configure(TIdeServices.Create(Application.Title));
  if ParamCount > 0 then
    CommandLineProject := ParamStr(1)
  else
    CommandLineProject := '';
  Form1.Start(CommandLineProject);
  Application.Run;
end.
