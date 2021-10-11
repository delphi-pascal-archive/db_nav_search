
{*******************************************************}
{                                                       }
{       Delphi Visual Component Library                 }
{                                                       }
{       Copyright (c) 1995 Borland International        }
{                                                       }
{*******************************************************}
{
DBNavSearch Delphi Component

Enhances the standard DBNavigator component by adding a search button to
it.  This button allows a table to be scanned using the key fields of its
current index.  A second unit, DBSearch, contains the search form that
DBNavSearch instantiates when the button is clicked.

Original DBNavigator component written by Borland International, et al.
DBNavSearch modifications written by Ken Henderson.

Copyright (c) 1995 by Ken Henderson.
}

unit DBNavSch;

interface

uses SysUtils, Windows, Messages, Classes, Controls, Forms,
  Graphics, Menus, StdCtrls, ExtCtrls, DB, DBTables, Mask, Buttons, DBCtrls,
  DBSearch;

type
  TNavButton = class;
  TNavDataLink = class;

  TNavGlyph = (ngEnabled, ngDisabled);
  TNavigateBtn = (nbFirst, nbPrior, nbNext, nbLast,
                  nbInsert, nbDelete, nbEdit, nbPost, nbCancel, nbRefresh, nbSearch);
  TButtonSet = set of TNavigateBtn;
  TNavButtonStyle = set of (nsAllowTimer, nsFocusRect);

  ENavClick = procedure (Sender: TObject; Button: TNavigateBtn) of object;

{ TDBNavSearch }

  TDBNavSearch = class (TCustomPanel)
  private
    FDataLink: TNavDataLink;
    FVisibleButtons: TButtonSet;
    FHints: TStrings;
    ButtonWidth: Integer;
    MinBtnSize: TPoint;
    FOnNavClick: ENavClick;
    FocusedButton: TNavigateBtn;
    FConfirmDelete: Boolean;
    function GetDataSource: TDataSource;
    procedure SetDataSource(Value: TDataSource);
    procedure InitButtons;
    procedure InitHints;
    procedure Click(Sender: TObject);
    procedure BtnMouseDown (Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure SetVisible(Value: TButtonSet);
    procedure AdjustSize (var W: Integer; var H: Integer);
    procedure SetHints(Value: TStrings);
    procedure WMSize(var Message: TWMSize);  message WM_SIZE;
    procedure WMSetFocus(var Message: TWMSetFocus); message WM_SETFOCUS;
    procedure WMKillFocus(var Message: TWMKillFocus); message WM_KILLFOCUS;
    procedure WMGetDlgCode(var Message: TWMGetDlgCode); message WM_GETDLGCODE;
    procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
  protected
    Buttons: array[TNavigateBtn] of TNavButton;
    procedure DataChanged;
    procedure EditingChanged;
    procedure ActiveChanged;
    procedure Loaded; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure Notification(AComponent: TComponent;
      Operation: TOperation); override;
    procedure GetChildren(Proc: TGetChildProc); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure SetBounds(ALeft, ATop, AWidth, AHeight: Integer); override;
    procedure BtnClick(Index: TNavigateBtn);
  published
    property DataSource: TDataSource read GetDataSource write SetDataSource;
    property VisibleButtons: TButtonSet read FVisibleButtons write SetVisible
      default [nbFirst, nbPrior, nbNext, nbLast, nbInsert, nbDelete,
        nbEdit, nbPost, nbCancel, nbRefresh, nbSearch];
    property Align;
    property DragCursor;
    property DragMode;
    property Enabled;
    property Ctl3D;
    property Hints: TStrings read FHints write SetHints;
    property ParentCtl3D;
    property ParentShowHint;
    property PopupMenu;
    property ConfirmDelete: Boolean read FConfirmDelete write FConfirmDelete default True;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property Visible;
    property OnClick: ENavClick read FOnNavClick write FOnNavClick;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnResize;
    property OnStartDrag;
  end;

{ TNavButton }

  TNavButton = class(TSpeedButton)
  private
    FIndex: TNavigateBtn;
    FNavStyle: TNavButtonStyle;
    FRepeatTimer: TTimer;
    procedure TimerExpired(Sender: TObject);
  protected
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
  public
    destructor Destroy; override;
    property NavStyle: TNavButtonStyle read FNavStyle write FNavStyle;
    property Index : TNavigateBtn read FIndex write FIndex;
  end;

{ TNavDataLink }

  TNavDataLink = class(TDataLink)
  private
    FNavigator: TDBNavSearch;
  protected
    procedure EditingChanged; override;
    procedure DataSetChanged; override;
    procedure ActiveChanged; override;
  public
    constructor Create(ANav: TDBNavSearch);
    destructor Destroy; override;
  end;

procedure Register;

implementation

uses BDE, Clipbrd, DBConsts, Dialogs;

{$R DBNAV}

{ TDBNavSearch }

const
  SSearchRecord = 65535;
  BtnStateName: array[TNavGlyph] of PChar = ('EN', 'DI');
  BtnTypeName: array[TNavigateBtn] of PChar = ('FIRST', 'PRIOR', 'NEXT',
    'LAST', 'INSERT', 'DELETE', 'EDIT', 'POST', 'CANCEL', 'REFRESH', 'SEARCH');
  BtnHintId: array[TNavigateBtn] of Word = (SFirstRecord, SPriorRecord,
    SNextRecord, SLastRecord, SInsertRecord, SDeleteRecord, SEditRecord,
    SPostEdit, SCancelEdit, SRefreshRecord, SSearchRecord);

constructor TDBNavSearch.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle - [csAcceptsControls, csSetCaption] + [csOpaque];
  if not NewStyleControls then ControlStyle := ControlStyle + [csFramed];
  FDataLink := TNavDataLink.Create(Self);
  FVisibleButtons := [nbFirst, nbPrior, nbNext, nbLast, nbInsert,
    nbDelete, nbEdit, nbPost, nbCancel, nbRefresh, nbSearch];
  FHints := TStringList.Create;
  InitButtons;
  BevelOuter := bvNone;
  BevelInner := bvNone;
  Width := 241;
  Height := 25;
  ButtonWidth := 0;
  FocusedButton := nbFirst;
  FConfirmDelete := True;
end;

destructor TDBNavSearch.Destroy;
begin
  FDataLink.Free;
  FDataLink := nil;
  inherited Destroy;
end;

procedure TDBNavSearch.InitButtons;
var
  I: TNavigateBtn;
  Btn: TNavButton;
  X: Integer;
  ResName: string;
begin
  MinBtnSize := Point(20, 18);
  X := 0;
  for I := Low(Buttons) to High(Buttons) do
  begin
    Btn := TNavButton.Create (Self);
    Btn.Index := I;
    Btn.Visible := I in FVisibleButtons;
    Btn.Enabled := True;
    Btn.SetBounds (X, 0, MinBtnSize.X, MinBtnSize.Y);
    FmtStr(ResName, 'dbn_%s', [BtnTypeName[I]]);
    Btn.Glyph.Handle := LoadBitmap(HInstance, PChar(ResName));
    Btn.NumGlyphs := 2;
    Btn.Enabled := False;  {!!! Force creation of speedbutton images !!!}
    Btn.Enabled := True;
    Btn.OnClick := Click;
    Btn.OnMouseDown := BtnMouseDown;
    Btn.Parent := Self;
    Buttons[I] := Btn;
    X := X + MinBtnSize.X;
  end;
  InitHints;
  Buttons[nbPrior].NavStyle := Buttons[nbPrior].NavStyle + [nsAllowTimer];
  Buttons[nbNext].NavStyle  := Buttons[nbNext].NavStyle + [nsAllowTimer];
end;

procedure TDBNavSearch.InitHints;
var
  I: Integer;
  J: TNavigateBtn;
begin
  for J := Low(Buttons) to High(Buttons) do
    Buttons[J].Hint := LoadStr (BtnHintId[J]);
  J := Low(Buttons);
  for I := 0 to (FHints.Count - 1) do
  begin
    if FHints.Strings[I] <> '' then Buttons[J].Hint := FHints.Strings[I];
    if J = High(Buttons) then Exit;
    Inc(J);
  end;
end;

procedure TDBNavSearch.SetHints(Value: TStrings);
begin
  FHints.Assign(Value);
  InitHints;
end;

procedure TDBNavSearch.GetChildren(Proc: TGetChildProc);
begin
end;

procedure TDBNavSearch.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (FDataLink <> nil) and
    (AComponent = DataSource) then DataSource := nil;
end;

procedure TDBNavSearch.SetVisible(Value: TButtonSet);
var
  I: TNavigateBtn;
  W, H: Integer;
begin
  W := Width;
  H := Height;
  FVisibleButtons := Value;
  for I := Low(Buttons) to High(Buttons) do
    Buttons[I].Visible := I in FVisibleButtons;
  AdjustSize (W, H);
  if (W <> Width) or (H <> Height) then
    inherited SetBounds (Left, Top, W, H);
  Invalidate;
end;

procedure TDBNavSearch.AdjustSize (var W: Integer; var H: Integer);
var
  Count: Integer;
  MinW: Integer;
  I: TNavigateBtn;
  Space, Temp, Remain: Integer;
  X: Integer;
begin
  if (csLoading in ComponentState) then Exit;
  if Buttons[nbFirst] = nil then Exit;

  Count := 0;
  for I := Low(Buttons) to High(Buttons) do
  begin
    if Buttons[I].Visible then
    begin
      Inc(Count);
    end;
  end;
  if Count = 0 then Inc(Count);

  MinW := Count * MinBtnSize.X;
  if W < MinW then W := MinW;
  if H < MinBtnSize.Y then H := MinBtnSize.Y;

  ButtonWidth := W div Count;
  Temp := Count * ButtonWidth;
  if Align = alNone then W := Temp;

  X := 0;
  Remain := W - Temp;
  Temp := Count div 2;
  for I := Low(Buttons) to High(Buttons) do
  begin
    if Buttons[I].Visible then
    begin
      Space := 0;
      if Remain <> 0 then
      begin
        Dec(Temp, Remain);
        if Temp < 0 then
        begin
          Inc(Temp, Count);
          Space := 1;
        end;
      end;
      Buttons[I].SetBounds(X, 0, ButtonWidth + Space, Height);
      Inc(X, ButtonWidth + Space);
    end
    else
      Buttons[I].SetBounds (Width + 1, 0, ButtonWidth, Height);
  end;
end;

procedure TDBNavSearch.SetBounds(ALeft, ATop, AWidth, AHeight: Integer);
var
  W, H: Integer;
begin
  W := AWidth;
  H := AHeight;
  AdjustSize (W, H);
  inherited SetBounds (ALeft, ATop, W, H);
end;

procedure TDBNavSearch.WMSize(var Message: TWMSize);
var
  W, H: Integer;
begin
  inherited;

  { check for minimum size }
  W := Width;
  H := Height;
  AdjustSize (W, H);
  if (W <> Width) or (H <> Height) then
    inherited SetBounds(Left, Top, W, H);
  Message.Result := 0;
end;

procedure TDBNavSearch.Click(Sender: TObject);
begin
  BtnClick (TNavButton (Sender).Index);
end;

procedure TDBNavSearch.BtnMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  OldFocus: TNavigateBtn;
begin
  OldFocus := FocusedButton;
  FocusedButton := TNavButton (Sender).Index;
  if TabStop and (GetFocus <> Handle) and CanFocus then
  begin
    SetFocus;
    if (GetFocus <> Handle) then
      Exit;
  end
  else if TabStop and (GetFocus = Handle) and (OldFocus <> FocusedButton) then
  begin
    Buttons[OldFocus].Invalidate;
    Buttons[FocusedButton].Invalidate;
  end;
end;

procedure TDBNavSearch.BtnClick(Index: TNavigateBtn);
const
  FldHeight = 30;
  TopPos = 2;
  LeftPos = 2;
var
  c,d : integer;
  TempLabel : TLabel;
  TempEdit : TControl;
  WidestLabelWidth, FieldWidth : Byte;
  FieldString : String;
  FValues : Variant;
  SearchOpts : TLocateOptions;

  function VarArrayToSingle(VarArray : Variant) : Variant;
  {Hoop-jumping code due to a bug in DB.Pas}
  var
    ActualElements, Counter : Integer;
  begin
    If VarIsArray(VarArray) then begin
      ActualElements:=0;
      For Counter:=VarArrayLowBound(VarArray,1) to
          VarArrayHighBound(VarArray,1) do
            If (VarArray[Counter]<>'') then Inc(ActualElements);
      If (ActualElements=1) then
        Result:=VarArray[VarArrayLowBound(VarArray,1)]
      else
        Result:=VarArray;
    end Else Result:=VarArray;
  end;

begin
  if (DataSource <> nil) and (DataSource.State <> dsInactive) then
  begin
    with DataSource.DataSet do
    begin
      case Index of
        nbPrior: Prior;
        nbNext: Next;
        nbFirst: First;
        nbLast: Last;
        nbInsert: Insert;
        nbEdit: Edit;
        nbCancel: Cancel;
        nbPost: Post;
        nbRefresh: Refresh;
        nbDelete:
          if not FConfirmDelete or
            (MessageDlg(LoadStr(SDeleteRecordQuestion), mtConfirmation,
            mbOKCancel, 0) <> idCancel) then Delete;
        nbSearch: begin
            WidestLabelWidth:=0;
            SearchForm:=TSearchForm.Create(Self);
            try
              With FDataLink.DataSet as TTable do begin
                FValues:=VarArrayCreate([0,Pred(FieldCount)],varOleStr);
                for c:=0 to Pred(FieldCount) do begin
                  TempLabel:=TLabel.Create(SearchForm.ScrollBox1);
                  TempLabel.Parent:=SearchForm.ScrollBox1;
                  TempLabel.AutoSize:=True;
                  TempLabel.Caption:=Fields[c].FieldName;
                  If (c<>0) then TempLabel.Top:=TopPos+(c*FldHeight)
                  else TempLabel.Top:=TopPos;
                  TempLabel.Left:=LeftPos;
                  If (TempLabel.Width>WidestLabelWidth) then
                    WidestLabelWidth:=TempLabel.Width;
                end;

                {Use two separate loops so that the widest label can be
                 detected and allowed for.}
                for c:=0 to Pred(FieldCount) do begin
                  If (Fields[c].DataType<>ftBoolean) then begin
                    TempEdit:=TEdit.Create(SearchForm.ScrollBox1);
                    TempEdit.Name:=Fields[c].FieldName;
                    TEdit(TempEdit).Text:='';
                    if (Fields[c].DataType = ftString) then
                      TEdit(TempEdit).MaxLength := Fields[c].Size
                    else
                      TEdit(TempEdit).MaxLength := Fields[c].DisplayWidth;
                  end else begin
                    TempEdit:=TCheckBox.Create(SearchForm.ScrollBox1);
                    TempEdit.Name:=Fields[c].FieldName;
                    TCheckBox(TempEdit).Caption:='';
                    TCheckBox(TempEdit).State:=cbGrayed;
                  end;
                  TempEdit.Parent:=SearchForm.ScrollBox1;

                  FieldWidth:=Fields[c].DisplayWidth+2;
                  TempEdit.Width:=(Canvas.TextWidth('M')*FieldWidth);

                  If (c<>0) then TempEdit.Top:=TopPos+(c*FldHeight)
                  else TempEdit.Top:=TopPos;
                 TempEdit.Left:=WidestLabelWidth+5;
                end;
                If (SearchForm.ShowModal=mrOK) then begin
                  FieldString:='';
                  d:=0;
                  With SearchForm do begin
                    For c:=0 to Pred(ScrollBox1.ComponentCount) do begin
                      If (ScrollBox1.Components[c] is TEdit) and
                         (TEdit(ScrollBox1.Components[c]).Text<>'') then begin
                        FieldString:=FieldString+ScrollBox1.Components[c].Name+';';
                        FValues[d]:=TEdit(ScrollBox1.Components[c]).Text;
                        Inc(d);
                      end else
                      If (ScrollBox1.Components[c] is TCheckBox) and
                         (TCheckBox(ScrollBox1.Components[c]).State<>cbGrayed) then begin
                        FieldString:=FieldString+ScrollBox1.Components[c].Name+';';
                        FValues[d]:=TCheckBox(ScrollBox1.Components[c]).Checked;
                        Inc(d);
                      end;
                    end;
                    SetLength(FieldString,Pred(Length(FieldString)));

                    SearchOpts:=[];
                    If IgnoreCase.Checked then
                      SearchOpts:=SearchOpts+[loCaseInsensitive];
                    If AllowPartial.Checked then
                      SearchOpts:=SearchOpts+[loPartialKey];
                  end;
                  If Not Locate(FieldString,VarArrayToSingle(FValues),SearchOpts) then
                    MessageDlg('Row not found',mtError,[mbOK],0);
                end else Cancel;
              end;
            finally
              SearchForm.Free;
            end;
        end;
      end;
    end;
  end;
  if not (csDesigning in ComponentState) and Assigned(FOnNavClick) then
    FOnNavClick(Self, Index);
end;

procedure TDBNavSearch.WMSetFocus(var Message: TWMSetFocus);
begin
  Buttons[FocusedButton].Invalidate;
end;

procedure TDBNavSearch.WMKillFocus(var Message: TWMKillFocus);
begin
  Buttons[FocusedButton].Invalidate;
end;

procedure TDBNavSearch.KeyDown(var Key: Word; Shift: TShiftState);
var
  NewFocus: TNavigateBtn;
  OldFocus: TNavigateBtn;
begin
  OldFocus := FocusedButton;
  case Key of
    VK_RIGHT:
      begin
        NewFocus := FocusedButton;
        repeat
          if NewFocus < High(Buttons) then
            NewFocus := Succ(NewFocus);
        until (NewFocus = High(Buttons)) or (Buttons[NewFocus].Visible);
        if NewFocus <> FocusedButton then
        begin
          FocusedButton := NewFocus;
          Buttons[OldFocus].Invalidate;
          Buttons[FocusedButton].Invalidate;
        end;
      end;
    VK_LEFT:
      begin
        NewFocus := FocusedButton;
        repeat
          if NewFocus > Low(Buttons) then
            NewFocus := Pred(NewFocus);
        until (NewFocus = Low(Buttons)) or (Buttons[NewFocus].Visible);
        if NewFocus <> FocusedButton then
        begin
          FocusedButton := NewFocus;
          Buttons[OldFocus].Invalidate;
          Buttons[FocusedButton].Invalidate;
        end;
      end;
    VK_SPACE:
      begin
        if Buttons[FocusedButton].Enabled then
          Buttons[FocusedButton].Click;
      end;
  end;
end;

procedure TDBNavSearch.WMGetDlgCode(var Message: TWMGetDlgCode);
begin
  Message.Result := DLGC_WANTARROWS;
end;

procedure TDBNavSearch.DataChanged;
var
  UpEnable, DnEnable: Boolean;
begin
  UpEnable := Enabled and FDataLink.Active and not FDataLink.DataSet.BOF;
  DnEnable := Enabled and FDataLink.Active and not FDataLink.DataSet.EOF;
  Buttons[nbFirst].Enabled := UpEnable;
  Buttons[nbPrior].Enabled := UpEnable;
  Buttons[nbNext].Enabled := DnEnable;
  Buttons[nbLast].Enabled := DnEnable;
  Buttons[nbDelete].Enabled := Enabled and FDataLink.Active and
    FDataLink.DataSet.CanModify and
    not (FDataLink.DataSet.BOF and FDataLink.DataSet.EOF);
end;

procedure TDBNavSearch.EditingChanged;
var
  CanModify: Boolean;
begin
  CanModify := Enabled and FDataLink.Active and FDataLink.DataSet.CanModify;
  Buttons[nbInsert].Enabled := CanModify;
  Buttons[nbEdit].Enabled := CanModify and not FDataLink.Editing;
  Buttons[nbPost].Enabled := CanModify and FDataLink.Editing;
  Buttons[nbCancel].Enabled := CanModify and FDataLink.Editing;
  Buttons[nbRefresh].Enabled := not (FDataLink.DataSet is TQuery);
  Buttons[nbSearch].Enabled := (FDataLink.DataSet is TTable) and
                               (TTable(FDataLink.DataSet).IndexFieldCount<>0);
end;

procedure TDBNavSearch.ActiveChanged;
var
  I: TNavigateBtn;
begin
  if not (Enabled and FDataLink.Active) then
    for I := Low(Buttons) to High(Buttons) do
      Buttons[I].Enabled := False
  else
  begin
    DataChanged;
    EditingChanged;
  end;
end;

procedure TDBNavSearch.CMEnabledChanged(var Message: TMessage);
begin
  inherited;
  if not (csLoading in ComponentState) then
    ActiveChanged;
end;

procedure TDBNavSearch.SetDataSource(Value: TDataSource);
begin
  FDataLink.DataSource := Value;
  if not (csLoading in ComponentState) then
    ActiveChanged;
  if Value <> nil then Value.FreeNotification(Self);
end;

function TDBNavSearch.GetDataSource: TDataSource;
begin
  Result := FDataLink.DataSource;
end;

procedure TDBNavSearch.Loaded;
var
  W, H: Integer;
begin
  inherited Loaded;
  W := Width;
  H := Height;
  AdjustSize (W, H);
  if (W <> Width) or (H <> Height) then
    inherited SetBounds (Left, Top, W, H);
  InitHints;
  ActiveChanged;
end;

{TNavButton}

destructor TNavButton.Destroy;
begin
  if FRepeatTimer <> nil then
    FRepeatTimer.Free;
  inherited Destroy;
end;

procedure TNavButton.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
  inherited MouseDown (Button, Shift, X, Y);
  if nsAllowTimer in FNavStyle then
  begin
    if FRepeatTimer = nil then
      FRepeatTimer := TTimer.Create(Self);

    FRepeatTimer.OnTimer := TimerExpired;
    FRepeatTimer.Interval := InitRepeatPause;
    FRepeatTimer.Enabled  := True;
  end;
end;

procedure TNavButton.MouseUp(Button: TMouseButton; Shift: TShiftState;
                                  X, Y: Integer);
begin
  inherited MouseUp (Button, Shift, X, Y);
  if FRepeatTimer <> nil then
    FRepeatTimer.Enabled  := False;
end;

procedure TNavButton.TimerExpired(Sender: TObject);
begin
  FRepeatTimer.Interval := RepeatPause;
  if (FState = bsDown) and MouseCapture then
  begin
    try
      Click;
    except
      FRepeatTimer.Enabled := False;
      raise;
    end;
  end;
end;

procedure TNavButton.Paint;
var
  R: TRect;
begin
  inherited Paint;
  if (GetFocus = Parent.Handle) and
     (FIndex = TDBNavSearch (Parent).FocusedButton) then
  begin
    R := Bounds(0, 0, Width, Height);
    InflateRect(R, -3, -3);
    if FState = bsDown then
      OffsetRect(R, 1, 1);
    DrawFocusRect(Canvas.Handle, R);
  end;
end;

{ TNavDataLink }

constructor TNavDataLink.Create(ANav: TDBNavSearch);
begin
  inherited Create;
  FNavigator := ANav;
end;

destructor TNavDataLink.Destroy;
begin
  FNavigator := nil;
  inherited Destroy;
end;

procedure TNavDataLink.EditingChanged;
begin
  if FNavigator <> nil then FNavigator.EditingChanged;
end;

procedure TNavDataLink.DataSetChanged;
begin
  if FNavigator <> nil then FNavigator.DataChanged;
end;

procedure TNavDataLink.ActiveChanged;
begin
  if FNavigator <> nil then FNavigator.ActiveChanged;
end;

procedure Register;
begin
  RegisterComponents('Data Controls',[TDBNavSearch]);
end;


end.
