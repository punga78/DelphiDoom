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
  DelphiDoom.Platform.Types in '..\..\Framework\Platform\DelphiDoom.Platform.Types.pas',
  DelphiDoom.Platform.DataFolder.Intf in '..\..\Framework\Platform\DelphiDoom.Platform.DataFolder.Intf.pas',
  DelphiDoom.Platform.DataFolder in '..\..\Framework\Platform\DelphiDoom.Platform.DataFolder.pas',
  DelphiDoom.Platform.DataFolder.Disk in '..\..\Framework\Platform\DelphiDoom.Platform.DataFolder.Disk.pas',
  DelphiDoom.Platform.DataFolder.Factory in '..\..\Framework\Platform\DelphiDoom.Platform.DataFolder.Factory.pas',
  Forms,
  main in 'main.pas' {Form1},
  DelphiDoom.Ide.Types in '..\Ide\DelphiDoom.Ide.Types.pas',
  DelphiDoom.Ide.Messages in '..\Ide\DelphiDoom.Ide.Messages.pas',
  DelphiDoom.Ide.Intf in '..\Ide\DelphiDoom.Ide.Intf.pas',
  DelphiDoom.Ide.Text in '..\Ide\DelphiDoom.Ide.Text.pas',
  DelphiDoom.Ide.ItemKinds in '..\Ide\DelphiDoom.Ide.ItemKinds.pas',
  DelphiDoom.Ide.Games in '..\Ide\DelphiDoom.Ide.Games.pas',
  DelphiDoom.Ide.ProjectFormat in '..\Ide\DelphiDoom.Ide.ProjectFormat.pas',
  DelphiDoom.Ide.UncountedObject in '..\Ide\DelphiDoom.Ide.UncountedObject.pas',
  DelphiDoom.Ide.UndoHistory in '..\Ide\DelphiDoom.Ide.UndoHistory.pas',
  DelphiDoom.Ide.Document in '..\Ide\DelphiDoom.Ide.Document.pas',
  DelphiDoom.Ide.ProjectItem in '..\Ide\DelphiDoom.Ide.ProjectItem.pas',
  DelphiDoom.Ide.Project in '..\Ide\DelphiDoom.Ide.Project.pas',
  DelphiDoom.Ide.Pk3Builder in '..\Ide\DelphiDoom.Ide.Pk3Builder.pas',
  DelphiDoom.Ide.CompilerMessages in '..\Ide\DelphiDoom.Ide.CompilerMessages.pas',
  DelphiDoom.Ide.PCodeFile in '..\Ide\DelphiDoom.Ide.PCodeFile.pas',
  DelphiDoom.Ide.CompileCommand in '..\Ide\DelphiDoom.Ide.CompileCommand.pas',
  DelphiDoom.Ide.Csv in '..\Ide\DelphiDoom.Ide.Csv.pas',
  DelphiDoom.Ide.Outline in '..\Ide\DelphiDoom.Ide.Outline.pas',
  DelphiDoom.Ide.RowSorter in '..\Ide\DelphiDoom.Ide.RowSorter.pas',
  DelphiDoom.Ide.LibraryTable in '..\Ide\DelphiDoom.Ide.LibraryTable.pas',
  DelphiDoom.Ide.NameValueTable in '..\Ide\DelphiDoom.Ide.NameValueTable.pas',
  DelphiDoom.Ide.ActorDefFunctionTable in '..\Ide\DelphiDoom.Ide.ActorDefFunctionTable.pas',
  DelphiDoom.Ide.UnitFunctionTable in '..\Ide\DelphiDoom.Ide.UnitFunctionTable.pas',
  DelphiDoom.Ide.FieldFormatter in '..\Ide\DelphiDoom.Ide.FieldFormatter.pas',
  DelphiDoom.Ide.StateTables in '..\Ide\DelphiDoom.Ide.StateTables.pas',
  DelphiDoom.Ide.StateCatalog in '..\Ide\DelphiDoom.Ide.StateCatalog.pas',
  DelphiDoom.Ide.MobjinfoCatalog in '..\Ide\DelphiDoom.Ide.MobjinfoCatalog.pas',
  DelphiDoom.Ide.ClassCatalog in '..\Ide\DelphiDoom.Ide.ClassCatalog.pas',
  DelphiDoom.Ide.SpriteCatalog in '..\Ide\DelphiDoom.Ide.SpriteCatalog.pas',
  DelphiDoom.Ide.ExampleStore in '..\Ide\DelphiDoom.Ide.ExampleStore.pas',
  DelphiDoom.Ide.ParameterHints in '..\Ide\DelphiDoom.Ide.ParameterHints.pas',
  DelphiDoom.Ide.SearchHistory in '..\Ide\DelphiDoom.Ide.SearchHistory.pas',
  DelphiDoom.Ide.SearchSettings in '..\Ide\DelphiDoom.Ide.SearchSettings.pas',
  DelphiDoom.Ide.SearchPlan in '..\Ide\DelphiDoom.Ide.SearchPlan.pas',
  DelphiDoom.Ide.MessageLog in '..\Ide\DelphiDoom.Ide.MessageLog.pas',
  DelphiDoom.Ide.ProjectOutline in '..\Ide\DelphiDoom.Ide.ProjectOutline.pas',
  DelphiDoom.Ide.EventSnippets in '..\Ide\DelphiDoom.Ide.EventSnippets.pas',
  DelphiDoom.Ide.Views.Intf in '..\Ide\DelphiDoom.Ide.Views.Intf.pas',
  DelphiDoom.Ide.MainPresenter in '..\Ide\DelphiDoom.Ide.MainPresenter.pas',
  DelphiDoom.Ide.ScriptEditorPresenter in '..\Ide\DelphiDoom.Ide.ScriptEditorPresenter.pas',
  DelphiDoom.Ide.Win.FileSystem in 'DelphiDoom.Ide.Win.FileSystem.pas',
  DelphiDoom.Ide.Win.Services in 'DelphiDoom.Ide.Win.Services.pas',
  DelphiDoom.Ide.Win.DdcLibrary in 'DelphiDoom.Ide.Win.DdcLibrary.pas',
  DelphiDoom.Ide.Win.Archive in 'DelphiDoom.Ide.Win.Archive.pas',
  DelphiDoom.Ide.Win.FileDialogs in 'DelphiDoom.Ide.Win.FileDialogs.pas',
  DelphiDoom.Ide.Vcl.ExampleEdit in 'DelphiDoom.Ide.Vcl.ExampleEdit.pas',
  DelphiDoom.Ide.Vcl.ListPanel in 'DelphiDoom.Ide.Vcl.ListPanel.pas',
  DelphiDoom.Ide.Vcl.TreePanel in 'DelphiDoom.Ide.Vcl.TreePanel.pas',
  DelphiDoom.Ide.Composition in 'DelphiDoom.Ide.Composition.pas',
  SynEdit in 'SynEdit\SynEdit.pas',
  SynEditHighlighter in 'SynEdit\SynEditHighlighter.pas',
  SynEditHighlighterOptions in 'SynEdit\SynEditHighlighterOptions.pas',
  SynEditKbdHandler in 'SynEdit\SynEditKbdHandler.pas',
  SynEditKeyCmds in 'SynEdit\SynEditKeyCmds.pas',
  SynEditKeyConst in 'SynEdit\SynEditKeyConst.pas',
  SynEditMiscClasses in 'SynEdit\SynEditMiscClasses.pas',
  SynEditMiscProcs in 'SynEdit\SynEditMiscProcs.pas',
  SynEditStrConst in 'SynEdit\SynEditStrConst.pas',
  SynEditTextBuffer in 'SynEdit\SynEditTextBuffer.pas',
  SynEditTypes in 'SynEdit\SynEditTypes.pas',
  SynEditWordWrap in 'SynEdit\SynEditWordWrap.pas',
  SynHighlighterMulti in 'SynEdit\SynHighlighterMulti.pas',
  SynRegExpr in 'SynEdit\SynRegExpr.pas',
  SynTextDrawer in 'SynEdit\SynTextDrawer.pas',
  SynUnicode in 'SynEdit\SynUnicode.pas',
  SynHighlighterActorDef in 'SynEdit\SynHighlighterActorDef.pas',
  SynHighlighterDDDisasm in 'SynEdit\SynHighlighterDDDisasm.pas',
  SynEditRegexSearch in 'SynEdit\SynEditRegexSearch.pas',
  SynEditSearch in 'SynEdit\SynEditSearch.pas',
  SynEditPrintTypes in 'SynEdit\SynEditPrintTypes.pas',
  SynEditPrint in 'SynEdit\SynEditPrint.pas',
  SynEditPrinterInfo in 'SynEdit\SynEditPrinterInfo.pas',
  SynEditPrintHeaderFooter in 'SynEdit\SynEditPrintHeaderFooter.pas',
  SynEditPrintMargins in 'SynEdit\SynEditPrintMargins.pas',
  SynEditPrintPreview in 'SynEdit\SynEditPrintPreview.pas',
  SynCompletionProposal in 'SynEdit\SynCompletionProposal.pas',
  frm_projectmanager in 'frm_projectmanager.pas' {Frame_ProjectManager: TFrame},
  frm_scripteditor in 'frm_scripteditor.pas' {Frame_ScriptEditor: TFrame},
  frm_GotoLine in 'frm_GotoLine.pas' {frmGotoLine},
  ide_version in 'ide_version.pas',
  ide_zipfile in 'ide_zipfile.pas',
  frm_SearchText in 'frm_SearchText.pas' {TextSearchDialog},
  frm_ReplaceText in 'frm_ReplaceText.pas' {TextReplaceDialog},
  frm_ConfirmReplace in 'frm_ConfirmReplace.pas' {ConfirmReplaceDialog},
  frm_message in 'frm_message.pas' {frmMessage},
  DelphiDoom.ScriptHost.Compiled in '..\..\Framework\ScriptHost\DelphiDoom.ScriptHost.Compiled.pas',
  ddc_base in '..\..\Framework\Ddc\ddc_base.pas',
  frm_unitfunctions in 'frm_unitfunctions.pas' {Frame_UnitFunctions: TFrame},
  frm_PageSetup in 'SynEdit\frm_PageSetup.pas' {PageSetupDlg},
  frm_PrintPreview in 'SynEdit\frm_PrintPreview.pas' {ScriptPrintPreviewDlg},
  frm_constants in 'frm_constants.pas' {Frame_Constants: TFrame},
  frm_variables in 'frm_variables.pas' {Frame_Variables: TFrame},
  frm_classes in 'frm_classes.pas' {Frame_Classes: TFrame},
  frm_types in 'frm_types.pas' {Frame_Types: TFrame},
  SynHighlighterDDScript in 'SynEdit\SynHighlighterDDScript.pas',
  frm_actordef in 'frm_actordef.pas' {Frame_Actordef: TFrame},
  frm_mobjinfo in 'frm_mobjinfo.pas' {Frame_Mobjinfo: TFrame},
  frm_states in 'frm_states.pas' {Frame_States: TFrame},
  frm_sprites in 'frm_sprites.pas' {Frame_Sprites: TFrame};

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
