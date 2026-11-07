unit frm_projectmanager;

interface

uses
  Windows, Classes, SysUtils, Forms, Controls, ExtCtrls, ComCtrls,
  ImgList, Buttons, StdCtrls, Graphics,
  DelphiDoom.Ide.Intf, DelphiDoom.Ide.Project;

type

  { TFrame_ProjectManager }

  /// <summary>
  ///   The tree of the files of the project and the box of the game. It follows the project: when
  ///   the project changes it is told and draws the tree again
  /// </summary>
  TFrame_ProjectManager = class(TFrame, IIdeDocumentObserver)
    Panel7: TPanel;
    TreeView1: TTreeView;
    ImageList1: TImageList;
    AddActorButton1: TSpeedButton;
    AddScriptButton1: TSpeedButton;
    AddCompiledScriptButton1: TSpeedButton;
    DeleteItemSpeedButton1: TSpeedButton;
    GameTypeImageList: TImageList;
    GameTypeComboBox: TComboBox;
    procedure GameTypeComboBoxDrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);
    procedure GameTypeComboBoxChange(Sender: TObject);
  private
    FProject: TIdeProject;
  public
    { public declarations }
    destructor Destroy; override;
    /// <summary>The frame shows this project from now on (and draws it at once)</summary>
    procedure AttachProject(const AProject: TIdeProject);
    procedure DocumentChanged(const AData: AnsiString);
  end;

implementation

{$R *.dfm}

uses
  DelphiDoom.Ide.Games, DelphiDoom.Ide.Outline, DelphiDoom.Ide.ProjectOutline;

const
  // the images of the tree: a branch has the image of its files plus 6, 8 or 10
  BRANCH_IMAGES: array[0..2, 0..1] of Integer = ((6, 7), (8, 9), (10, 11));
  FILE_IMAGES: array[0..2, 0..1] of Integer = ((0, 1), (2, 3), (4, 5));

destructor TFrame_ProjectManager.Destroy;
begin
  if FProject <> nil then
    FProject.Detach;
  inherited;
end;

procedure TFrame_ProjectManager.AttachProject(const AProject: TIdeProject);
begin
  if FProject <> nil then
    FProject.Detach;
  FProject := AProject;
  if FProject <> nil then
    FProject.Attach(Self);
end;

procedure TFrame_ProjectManager.DocumentChanged(const AData: AnsiString);
var
  LOutline: TIdeOutline;
  LBranch, LFile: TIdeOutlineNode;
  LNode, LChild: TTreeNode;
  LIndex: Integer;
begin
  LOutline := TIdeProjectOutline.Build(FProject);
  TreeView1.Items.BeginUpdate;
  try
    TreeView1.Items.Clear;
    for LIndex := 0 to LOutline.Roots.Count - 1 do
    begin
      LBranch := LOutline.Roots[LIndex];
      if LIndex = 0 then
        LNode := TreeView1.Items.AddFirst(nil, LBranch.Text)
      else
        LNode := TreeView1.Items.AddChild(nil, LBranch.Text);
      LNode.ImageIndex := BRANCH_IMAGES[LIndex, 0];
      LNode.SelectedIndex := BRANCH_IMAGES[LIndex, 1];
      for LFile in LBranch.Children do
      begin
        LChild := TreeView1.Items.AddChild(LNode, LFile.Text);
        LChild.ImageIndex := FILE_IMAGES[LIndex, 0];
        LChild.SelectedIndex := FILE_IMAGES[LIndex, 1];
      end;
    end;
  finally
    TreeView1.Items.EndUpdate;
    LOutline.Free;
  end;
  if FProject <> nil then
    GameTypeComboBox.ItemIndex := TIdeGames.BoxIndex(FProject.Game);
end;

procedure TFrame_ProjectManager.GameTypeComboBoxDrawItem(Control: TWinControl;
  Index: Integer; Rect: TRect; State: TOwnerDrawState);
var
  ComboBox: TComboBox;
  bitmap: TBitmap;
  s: string;
begin
  ComboBox := (Control as TComboBox);
  Bitmap := TBitmap.Create;
  try
    GameTypeImageList.GetBitmap(Index, Bitmap);
    with ComboBox.Canvas do
    begin
      FillRect(Rect);
      if Bitmap.Handle <> 0 then
        Draw(Rect.Left + 2, Rect.Top, Bitmap);
      Rect := Bounds(
        Rect.Left + ComboBox.ItemHeight + 2,
        Rect.Top,
        Rect.Right - Rect.Left,
        Rect.Bottom - Rect.Top
      );
      s := '  ' + ComboBox.Items[Index];
      DrawText(
        handle,
        PChar(s),
        Length(s),
        Rect,
        DT_VCENTER + DT_SINGLELINE
      );
    end;
  finally
    Bitmap.Free;
  end;
end;

procedure TFrame_ProjectManager.GameTypeComboBoxChange(Sender: TObject);
begin
  if FProject <> nil then
    if GameTypeComboBox.ItemIndex >= 0 then
      FProject.Game := GameTypeComboBox.Items.Strings[GameTypeComboBox.ItemIndex];
end;

end.
