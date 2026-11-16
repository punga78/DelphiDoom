unit frm_scripteditor;

interface

uses
  Classes, SysUtils, Forms, Controls, ExtCtrls, ComCtrls, Graphics,
  SynEdit, SynHighlighterMulti, SynHighlighterDDScript, SynHighlighterActorDef,
  SynHighlighterDDDisasm, SynEditSearch, SynEditRegexSearch, SynEditPrint,
  SynEditPrintTypes, SynCompletionProposal, SynUnicode,
  Buttons, Dialogs, Menus, Messages,
  DelphiDoom.Ide.Types, DelphiDoom.Ide.Intf, DelphiDoom.Ide.ProjectItem,
  DelphiDoom.Ide.ScriptEditorPresenter, DelphiDoom.Ide.Views.Intf,
  DelphiDoom.Ide.Composition;

type

  { TFrame_ScriptEditor }

  /// <summary>
  ///   One tab of the script editor: the SynEdit, the buttons and the dialogs. What the buttons do
  ///   (compile, save, the events, the hint of the parameters) is decided by its presenter
  /// </summary>
  TFrame_ScriptEditor = class(TFrame, IIdeScriptEditorView)
    Panel7: TPanel;
    Timer1: TTimer;
    Panel1: TPanel;
    CloseButton1: TSpeedButton;
    CompileButton1: TSpeedButton;
    SaveButton1: TSpeedButton;
    PrintDialog: TPrintDialog;
    CompileAndSaveButton1: TSpeedButton;
    PrintButton1: TSpeedButton;
    PrintPreviewButton1: TSpeedButton;
    PageSetupButton1: TSpeedButton;
    SavePCodeDialog1: TSaveDialog;
    EventsPopupMenu: TPopupMenu;
    N11: TMenuItem;
    N21: TMenuItem;
    N31: TMenuItem;
    N41: TMenuItem;
    N51: TMenuItem;
    N61: TMenuItem;
    N71: TMenuItem;
    N81: TMenuItem;
    N91: TMenuItem;
    N101: TMenuItem;
    N111: TMenuItem;
    N121: TMenuItem;
    N131: TMenuItem;
    N141: TMenuItem;
    N151: TMenuItem;
    N161: TMenuItem;
    N171: TMenuItem;
    N181: TMenuItem;
    N191: TMenuItem;
    N201: TMenuItem;
    EventsSpeedButton: TSpeedButton;
    procedure Timer1Timer(Sender: TObject);
    procedure CloseButton1Click(Sender: TObject);
    procedure CompileButton1Click(Sender: TObject);
    procedure SaveButton1Click(Sender: TObject);
    procedure PrintButton1Click(Sender: TObject);
    procedure PrintPreviewButton1Click(Sender: TObject);
    procedure PageSetupButton1Click(Sender: TObject);
    procedure CompileAndSaveButton1Click(Sender: TObject);
    procedure EventsSpeedButtonClick(Sender: TObject);
    procedure OnEventsPopupMenuClick(Sender: TObject);
  private
    { private declarations }
    SynEdit1: TSynEdit;
    SynPasSyn1: TSynDDScriptSyn;
    SynEditRegexSearch1: TSynEditRegexSearch;
    SynEditSearch1: TSynEditSearch;
    SynActordefSyn1: TSynActordefSyn;
    SynDDDisasmSyn1: TSynDDDisasmSyn;
    scpParams: TSynCompletionProposal;
    fSearchFromCaret: boolean;
    FServices: TIdeServices;
    FPresenter: TIdeScriptEditorPresenter;
    FItem: TIdeProjectItem;
    FPCodeDialog: IIdePCodeDialog;
    procedure ShowSearchReplaceDialog(AReplace: boolean);
    procedure DoSearchReplaceText(AReplace: boolean);
    procedure OnEditorChange(Sender: TObject);
    procedure scpParamsExecute(Kind: SynCompletionType; Sender: TObject;
      var AString: UnicodeString; var x, y: Integer; var CanExecute: Boolean);
    procedure UpdateEventsMenuItems;
    procedure UpdateNotFound(const AText: string; const AKind: TIdeMessageKind;
      const ABackwards: Boolean);
  public
    { public declarations }
    SynEditPrint: TSynEditPrint;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    /// <summary>Makes the editor follow a file of the project (the tab is built by the main window)</summary>
    procedure Configure(const AServices: TIdeServices; const AItem: TIdeProjectItem);
    procedure ShowSearchDialog;
    procedure SearchAgain;
    procedure ShowReplaceDialog;
    procedure GoToLineNumber;
    { IIdeScriptEditorView }
    function EditorText: string;
    procedure MoveCaretTo(const ALocation: TIdeSourceLocation);
    procedure ShowText(const AText: string);
    procedure ShowTools(const AKind: TIdeItemKind);
    property Item: TIdeProjectItem read FItem;
  end;

implementation

uses
  Windows,
  SynEditTypes,
  DelphiDoom.Ide.Messages,
  DelphiDoom.Ide.SearchPlan,
  DelphiDoom.Ide.SearchSettings,
  DelphiDoom.Ide.Win.FileDialogs,
  frm_GotoLine, frm_SearchText, frm_ReplaceText, frm_ConfirmReplace,
  frm_PrintPreview, frm_PageSetup;

{$R *.dfm}

function ToSynOptions(const AFlags: TIdeSearchFlags): TSynSearchOptions;
begin
  Result := [];
  if sfPrompt in AFlags then
    Include(Result, ssoPrompt);
  if sfReplace in AFlags then
    Include(Result, ssoReplace);
  if sfReplaceAll in AFlags then
    Include(Result, ssoReplaceAll);
  if sfBackwards in AFlags then
    Include(Result, ssoBackwards);
  if sfMatchCase in AFlags then
    Include(Result, ssoMatchCase);
  if sfEntireScope in AFlags then
    Include(Result, ssoEntireScope);
  if sfSelectedOnly in AFlags then
    Include(Result, ssoSelectedOnly);
  if sfWholeWord in AFlags then
    Include(Result, ssoWholeWord);
end;

//==============================================================================
//
// TFrame_ScriptEditor.Create
//
//==============================================================================
constructor TFrame_ScriptEditor.Create(AOwner: TComponent);
var
  AFont: TFont;
begin
  inherited;

  SynEditRegexSearch1 := TSynEditRegexSearch.Create(Self);
  SynEditSearch1 := TSynEditSearch.Create(Self);

  SynEdit1 := TSynEdit.Create(Self);
  SynEdit1.Parent := Self;
  SynEdit1.Align := alClient;
  SynEdit1.Highlighter := nil;
  SynEdit1.OnChange := OnEditorChange;
  SynEdit1.Gutter.ShowLineNumbers := True;
  SynEdit1.Gutter.AutoSize := True;
  SynEdit1.MaxScrollWidth := 255;
  SynEdit1.WantTabs := True;
  SynEdit1.ReadOnly := True;

  SynPasSyn1 := TSynDDScriptSyn.Create(Self);

  SynActordefSyn1 := TSynActordefSyn.Create(self);
  SynActordefSyn1.CommentAttri.Foreground := RGB(0, 128, 0);
  SynActordefSyn1.IdentifierAttri.Foreground := RGB(0, 0, 0);
  SynActordefSyn1.KeyAttri.Foreground := RGB(0, 0, 128);
  SynActordefSyn1.NumberAttri.Foreground := RGB(0, 0, 255);
  SynActordefSyn1.StringAttri.Foreground := RGB(0, 0, 255);

  SynDDDisasmSyn1 := TSynDDDisasmSyn.Create(self);
  SynDDDisasmSyn1.CommentAttri.Foreground := RGB(0, 128, 0);
  SynDDDisasmSyn1.IdentifierAttri.Foreground := RGB(0, 0, 0);
  SynDDDisasmSyn1.KeyAttri.Foreground := RGB(0, 0, 128);
  SynDDDisasmSyn1.NumberAttri.Foreground := RGB(0, 0, 255);
  SynDDDisasmSyn1.StringAttri.Foreground := RGB(0, 0, 255);

  SynEditPrint := TSynEditPrint.Create(self);
  SynEditPrint.Copies := 1;
  SynEditPrint.Header.FrameTypes := [ftBox, ftShaded];
  SynEditPrint.Header.DefaultFont.Charset := DEFAULT_CHARSET;
  SynEditPrint.Header.DefaultFont.Color := clBlack;
  SynEditPrint.Header.DefaultFont.Height := -13;
  SynEditPrint.Header.DefaultFont.Name := 'Arial';
  SynEditPrint.Header.DefaultFont.Style := [];
  SynEditPrint.Footer.DefaultFont.Charset := DEFAULT_CHARSET;
  SynEditPrint.Footer.DefaultFont.Color := clBlack;
  SynEditPrint.Footer.DefaultFont.Height := -13;
  SynEditPrint.Footer.DefaultFont.Name := 'Arial';
  SynEditPrint.Footer.DefaultFont.Style := [];
  SynEditPrint.Margins.Left := 25.000000000000000000;
  SynEditPrint.Margins.Right := 15.000000000000000000;
  SynEditPrint.Margins.Top := 25.000000000000000000;
  SynEditPrint.Margins.Bottom := 25.000000000000000000;
  SynEditPrint.Margins.Header := 15.000000000000000000;
  SynEditPrint.Margins.Footer := 15.000000000000000000;
  SynEditPrint.Margins.LeftHFTextIndent := 2.000000000000000000;
  SynEditPrint.Margins.RightHFTextIndent := 2.000000000000000000;
  SynEditPrint.Margins.HFInternalMargin := 0.500000000000000000;
  SynEditPrint.Margins.MirrorMargins := False;
  SynEditPrint.Font.Charset := DEFAULT_CHARSET;
  SynEditPrint.Font.Color := clWindowText;
  SynEditPrint.Font.Height := -11;
  SynEditPrint.Font.Name := 'MS Sans Serif';
  SynEditPrint.Font.Style := [];
  SynEditPrint.Colors := True;
  SynEditPrint.Highlighter := SynPasSyn1;
  SynEditPrint.TabWidth := 2;
  SynEditPrint.Color := clWhite;

  SynEditPrint.Header.Add('$TITLE$', nil, taLeftJustify, 1);
  SynEditPrint.Footer.Add('$PAGENUM$/$PAGECOUNT$', nil, taRightJustify, 1);
  AFont := TFont.Create;
  AFont.Assign(SynEditPrint.Footer.DefaultFont);
  AFont.Size := 6;
  SynEditPrint.Footer.Add('Print Date: $DATE$. Time: $TIME$', AFont, taRightJustify, 2);
  AFont.Free;

  scpParams := TSynCompletionProposal.Create(self);
  scpParams.DefaultType := ctParams;
  scpParams.Options := [scoLimitToMatchedText, scoUsePrettyText, scoUseBuiltInTimer];
  scpParams.ClBackground := clInfoBk;
  scpParams.Width := 262;
  scpParams.EndOfTokenChr := '()[]. ';
  scpParams.TriggerChars := '(';
  scpParams.Font.Charset := DEFAULT_CHARSET;
  scpParams.Font.Color := clWindowText;
  scpParams.Font.Height := -11;
  scpParams.Font.Name := 'MS Sans Serif';
  scpParams.Font.Style := [];
  scpParams.TitleFont.Charset := DEFAULT_CHARSET;
  scpParams.TitleFont.Color := clBtnText;
  scpParams.TitleFont.Height := -11;
  scpParams.TitleFont.Name := 'MS Sans Serif';
  scpParams.TitleFont.Style := [fsBold];
  scpParams.OnExecute := scpParamsExecute;
  scpParams.ShortCut := 24608;
  scpParams.Editor := SynEdit1;
  scpParams.TimerInterval := 1000;
  scpParams.EndOfTokenChr := '';
end;

//==============================================================================
//
// TFrame_ScriptEditor.Destroy
//
//==============================================================================
destructor TFrame_ScriptEditor.Destroy;
begin
  // the presenter stops following the file
  FreeAndNil(FPresenter);
  inherited;
end;

//==============================================================================
//
// TFrame_ScriptEditor.Configure
//
//==============================================================================
procedure TFrame_ScriptEditor.Configure(const AServices: TIdeServices;
  const AItem: TIdeProjectItem);
begin
  FServices := AServices;
  FItem := AItem;
  FPCodeDialog := TVclIdePCodeDialog.Create(SavePCodeDialog1);
  // the presenter asks the editor to show the text as soon as it is made
  FPresenter := TIdeScriptEditorPresenter.Create(AItem, Self, AServices.Compiler,
    AServices.GameLibrary, AServices.FileSystem, FPCodeDialog, AServices.Busy, AServices.LogIntf);
end;

//==============================================================================
//
// IIdeScriptEditorView
//
//==============================================================================
function TFrame_ScriptEditor.EditorText: string;
begin
  Result := SynEdit1.Text;
end;

procedure TFrame_ScriptEditor.MoveCaretTo(const ALocation: TIdeSourceLocation);
begin
  SynEdit1.CaretX := ALocation.Column;
  SynEdit1.CaretY := ALocation.Line;
  SynEdit1.SetFocus;
end;

procedure TFrame_ScriptEditor.ShowText(const AText: string);
begin
  SynEdit1.Lines.Text := AText;
end;

procedure TFrame_ScriptEditor.ShowTools(const AKind: TIdeItemKind);
begin
  case AKind of
    ikScript:
      begin
        SaveButton1.Visible := True;
        SynEdit1.Highlighter := SynPasSyn1;
        SynEditPrint.Highlighter := SynPasSyn1;
        CompileButton1.Visible := True;
        CompileAndSaveButton1.Visible := True;
        EventsSpeedButton.Visible := True;
        SynEdit1.ReadOnly := False;
      end;
    ikActor:
      begin
        SaveButton1.Visible := True;
        SynEdit1.Highlighter := SynActordefSyn1;
        SynEditPrint.Highlighter := SynActordefSyn1;
        SynEdit1.ReadOnly := False;
      end;
    ikCompiledScript:
      begin
        SaveButton1.Visible := False;
        SynEdit1.Highlighter := SynDDDisasmSyn1;
        SynEditPrint.Highlighter := SynDDDisasmSyn1;
        SynEdit1.ReadOnly := True;
      end;
  else
    begin
      SynEdit1.Highlighter := nil;
      SynEditPrint.Highlighter := nil;
    end;
  end;
  Timer1.Enabled := False;
end;

//==============================================================================
//
// TFrame_ScriptEditor.GoToLineNumber
//
//==============================================================================
procedure TFrame_ScriptEditor.GoToLineNumber;
begin
  with TfrmGotoLine.Create(self) do
  try
    Char := SynEdit1.CaretX;
    Line := SynEdit1.CaretY;
    ShowModal;
    if ModalResult = mrOK then
      SynEdit1.CaretXY := CaretXY;
  finally
    Free;
  end;
  try
    SynEdit1.SetFocus;
  except
  end;
end;

//==============================================================================
//
// TFrame_ScriptEditor.Timer1Timer
//
//==============================================================================
procedure TFrame_ScriptEditor.Timer1Timer(Sender: TObject);
begin
  if FPresenter <> nil then
    FPresenter.UpdateControls;
end;

//==============================================================================
//
// TFrame_ScriptEditor.CloseButton1Click
//
//==============================================================================
procedure TFrame_ScriptEditor.CloseButton1Click(Sender: TObject);
begin
  if Parent <> nil then
    if Parent is TTabSheet then
      (Parent as TTabSheet).Enabled := False;
end;

//==============================================================================
//
// TFrame_ScriptEditor.OnEditorChange
//
//==============================================================================
procedure TFrame_ScriptEditor.OnEditorChange(Sender: TObject);
begin
  if FPresenter <> nil then
    FPresenter.EditorChanged(SynEdit1.Text, SynEdit1.Modified);
end;

//==============================================================================
//
// the search and replace dialogs
//
//==============================================================================
procedure TFrame_ScriptEditor.ShowSearchReplaceDialog(AReplace: boolean);
var
  dlg: TTextSearchDialog;
  LSettings: TIdeSearchSettings;
begin
  LSettings := FServices.Search;
  if AReplace then
    dlg := TTextReplaceDialog.Create(Self)
  else
    dlg := TTextSearchDialog.Create(Self);
  with dlg do
  try
    // assign search options
    SearchBackwards := LSettings.Backwards;
    SearchCaseSensitive := LSettings.CaseSensitive;
    SearchFromCursor := LSettings.FromCaret;
    SearchInSelectionOnly := LSettings.SelectionOnly;
    // start with last search text
    SearchText := LSettings.SearchText;
    if LSettings.TextAtCaret then
    begin
      // if something is selected search for that text
      if SynEdit1.SelAvail and (SynEdit1.BlockBegin.Line = SynEdit1.BlockEnd.Line) //Birb (fix at SynEdit's SearchReplaceDemo)
      then
        SearchText := SynEdit1.SelText
      else
        SearchText := SynEdit1.GetWordAtRowCol(SynEdit1.CaretXY);
    end;
    SearchTextHistory := LSettings.SearchHistory.AsText;
    if AReplace then with dlg as TTextReplaceDialog do
    begin
      ReplaceText := LSettings.ReplaceText;
      ReplaceTextHistory := LSettings.ReplaceHistory.AsText;
    end;
    SearchWholeWords := LSettings.WholeWords;
    if ShowModal = mrOK then
    begin
      LSettings.Backwards := SearchBackwards;
      LSettings.CaseSensitive := SearchCaseSensitive;
      LSettings.FromCaret := SearchFromCursor;
      LSettings.SelectionOnly := SearchInSelectionOnly;
      LSettings.WholeWords := SearchWholeWords;
      LSettings.RegularExpression := SearchRegularExpression;
      LSettings.SearchText := SearchText;
      LSettings.SearchHistory.LoadFromText(SearchTextHistory);
      if AReplace then
        with dlg as TTextReplaceDialog do
        begin
          LSettings.ReplaceText := ReplaceText;
          LSettings.ReplaceHistory.LoadFromText(ReplaceTextHistory);
        end;
      fSearchFromCaret := LSettings.FromCaret;
      if LSettings.SearchText <> '' then
      begin
        DoSearchReplaceText(AReplace);
        fSearchFromCaret := True;
      end;
    end;
  finally
    dlg.Free;
  end;
end;

procedure TFrame_ScriptEditor.UpdateNotFound(const AText: string; const AKind: TIdeMessageKind;
  const ABackwards: Boolean);
begin
  MessageBeep(MB_ICONASTERISK);
  FServices.LogIntf.WriteFormat(AKind, SSearchNotFound, [AText]);
  if ABackwards then
    SynEdit1.BlockEnd := SynEdit1.BlockBegin
  else
    SynEdit1.BlockBegin := SynEdit1.BlockEnd;
  SynEdit1.CaretXY := SynEdit1.BlockBegin;
end;

procedure TFrame_ScriptEditor.DoSearchReplaceText(AReplace: boolean);
var
  LPlan: TIdeSearchPlan;
  LSettings: TIdeSearchSettings;
begin
  LSettings := FServices.Search;
  LPlan := TIdeSearchPlans.ForDialog(LSettings, AReplace, fSearchFromCaret);
  if LPlan.UseRegularExpression then
    SynEdit1.SearchEngine := SynEditRegexSearch1
  else
    SynEdit1.SearchEngine := SynEditSearch1;
  if SynEdit1.SearchReplace(LSettings.SearchText, LSettings.ReplaceText,
    ToSynOptions(LPlan.Flags)) = 0 then
    UpdateNotFound(LSettings.SearchText, mkInfo, sfBackwards in LPlan.Flags);

  if ConfirmReplaceDialog <> nil then
    ConfirmReplaceDialog.Free;
end;

procedure TFrame_ScriptEditor.ShowSearchDialog;
begin
  ShowSearchReplaceDialog(False);
end;

procedure TFrame_ScriptEditor.SearchAgain;
var
  LPlan: TIdeSearchPlan;
  LSettings: TIdeSearchSettings;
begin
  LSettings := FServices.Search;
  if LSettings.SearchText = '' then
  begin
    ShowSearchDialog;
    Exit;
  end;

  LPlan := TIdeSearchPlans.ForSearchAgain(LSettings);
  if LPlan.UseRegularExpression then
    SynEdit1.SearchEngine := SynEditRegexSearch1
  else
    SynEdit1.SearchEngine := SynEditSearch1;
  if SynEdit1.SearchReplace(LSettings.SearchText, '', ToSynOptions(LPlan.Flags)) = 0 then
    UpdateNotFound(LSettings.SearchText, mkNormal, sfBackwards in LPlan.Flags);

  if ConfirmReplaceDialog <> nil then
    ConfirmReplaceDialog.Free;
end;

procedure TFrame_ScriptEditor.ShowReplaceDialog;
begin
  ShowSearchReplaceDialog(True);
end;

//==============================================================================
//
// the buttons
//
//==============================================================================
procedure TFrame_ScriptEditor.CompileButton1Click(Sender: TObject);
begin
  FPresenter.Compile(False);
end;

procedure TFrame_ScriptEditor.CompileAndSaveButton1Click(Sender: TObject);
begin
  FPresenter.Compile(True);
end;

procedure TFrame_ScriptEditor.SaveButton1Click(Sender: TObject);
begin
  FPresenter.Save;
end;

procedure TFrame_ScriptEditor.PrintButton1Click(Sender: TObject);
begin
  if PrintDialog.Execute then
  begin
    SynEditPrint.SynEdit := SynEdit1;
    SynEditPrint.Title := FItem.FileName;
    SynEditPrint.Print;
  end;
end;

procedure TFrame_ScriptEditor.PrintPreviewButton1Click(Sender: TObject);
begin
  SynEditPrint.SynEdit := SynEdit1;
  SynEditPrint.Title := FItem.FileName;
  ScriptPrintPreviewDlg.Caption := 'Print Preview - ' + FItem.FileName;
  ScriptPrintPreviewDlg.SynEditPrintPreview.SynEditPrint := SynEditPrint;
  ScriptPrintPreviewDlg.ShowModal;
end;

procedure TFrame_ScriptEditor.PageSetupButton1Click(Sender: TObject);
begin
  PageSetupDlg.SetValues(SynEditPrint);
  if PageSetupDlg.ShowModal = mrOk then
    PageSetupDlg.GetValues(SynEditPrint);
end;

//==============================================================================
//
// the hint with the parameters of a function
//
//==============================================================================
procedure TFrame_ScriptEditor.scpParamsExecute(Kind: SynCompletionType; Sender: TObject;
  var AString: UnicodeString; var x, y: Integer; var CanExecute: Boolean);
var
  LName, LParameters: string;
  LIndex: Integer;
begin
  CanExecute := False;
  if FPresenter <> nil then
    CanExecute := FPresenter.FindCall(TSynCompletionProposal(Sender).Editor.LineText,
      TSynCompletionProposal(Sender).Editor.CaretX,
      function(AChar: Char): Boolean
      begin
        Result := SynEdit1.IsIdentChar(AChar);
      end, LName, LIndex, LParameters);

  if CanExecute then
  begin
    TSynCompletionProposal(Sender).Form.CurrentIndex := LIndex;
    if LName <> TSynCompletionProposal(Sender).PreviousToken then
    begin
      TSynCompletionProposal(Sender).ItemList.Clear;
      TSynCompletionProposal(Sender).ItemList.Add(LParameters);
    end;
  end
  else
    TSynCompletionProposal(Sender).ItemList.Clear;
end;

//==============================================================================
//
// the menu of the events
//
//==============================================================================
procedure TFrame_ScriptEditor.EventsSpeedButtonClick(Sender: TObject);
var
  p: TPoint;
begin
  UpdateEventsMenuItems;
  p := EventsSpeedButton.ClientToScreen(Point(0, EventsSpeedButton.Height));
  EventsPopupMenu.Popup(p.X, p.Y);
  EventsSpeedButton.Down := False;
end;

procedure TFrame_ScriptEditor.UpdateEventsMenuItems;
var
  i: integer;
  cnt: integer;
begin
  cnt := FPresenter.EventCount;
  if cnt > EventsPopupMenu.Items.Count then
    cnt := EventsPopupMenu.Items.Count;
  for i := 0 to cnt - 1 do
  begin
    EventsPopupMenu.Items[i].Visible := True;
    EventsPopupMenu.Items[i].Caption := FPresenter.EventCaption(i);
    EventsPopupMenu.Items[i].Tag := i;
  end;
  for i := cnt to EventsPopupMenu.Items.Count - 1 do
  begin
    EventsPopupMenu.Items[i].Visible := False;
    EventsPopupMenu.Items[i].Tag := i;
  end;
end;

procedure TFrame_ScriptEditor.OnEventsPopupMenuClick(Sender: TObject);
var
  mitem: TMenuItem;
  id: integer;
  skey, sevent: string;
  fHighlighter: TSynDDScriptSyn;
  p: integer;
  found: boolean;
  newtext: string;
  caretoffset: integer;
begin
  mitem := Sender as TMenuItem;
  id := mitem.tag;
  if id >= FPresenter.EventCount then
    Exit;

  // is the event in the script already? The highlighter finds the "event Name" words
  sevent := FPresenter.EventScriptName(id);
  fHighlighter := TSynDDScriptSyn.Create(nil);
  try
    fHighlighter.ResetRange;
    fHighlighter.SetLine(SynEdit1.Lines.Text, 1);
    p := -1;
    found := False;
    while not fHighlighter.GetEol do
    begin
      if fHighlighter.GetTokenKind = Ord(SynHighlighterDDScript.tkKey) then
      begin
        skey := UpperCase(fHighlighter.GetToken);
        if skey = 'EVENT' then
        begin
          p := fHighlighter.GetTokenPos;
          while not fHighlighter.GetEol do
          begin
            fHighlighter.Next;
            if fHighlighter.GetTokenKind = Ord(SynHighlighterDDScript.tkIdentifier) then
            begin
              if UpperCase(fHighlighter.GetToken) = sevent then
                found := True;
              Break;
            end;
            if (fHighlighter.GetTokenKind = Ord(SynHighlighterDDScript.tkComment)) or
               (fHighlighter.GetTokenKind = Ord(SynHighlighterDDScript.tkPreprocessor)) or
               (fHighlighter.GetTokenKind = Ord(SynHighlighterDDScript.tkSpace)) or
               (fHighlighter.GetTokenKind = Ord(SynHighlighterDDScript.tkNull)) then
              Continue;
            Break;
          end;
          if found then
            Break
          else
            p := -1;
        end;
      end;
      fHighlighter.Next;
    end;
  finally
    fHighlighter.Free;
  end;

  if found then
  begin
    SynEdit1.SelStart := p;
    SynEdit1.SelEnd := p;
    SynEdit1.SetFocus;
    Exit;
  end;

  newtext := FPresenter.AppendEvent(id, SynEdit1.Lines.Text, caretoffset);
  SynEdit1.Lines.Text := newtext;
  SynEdit1.SelStart := caretoffset;
  SynEdit1.SelEnd := caretoffset;
  SynEdit1.SetFocus;
end;

end.
