unit DBNavSch;

{$B-,R-,H+,X+}

interface

uses SysUtils, Windows, Messages, Classes, Controls, Forms,
  Graphics, Menus, StdCtrls, ExtCtrls, DB, DBTables, Mask, Buttons, DBCtrls,
  Variants;

type
  TNavButton = class;
  TNavDataLink = class;

  TNavGlyph = (ngEnabled, ngDisabled);
  TNavSchBtn = (nbFirst, nbPrior, nbNext, nbLast, nbInsert,
                nbDelete, nbEdit, nbPost, nbCancel, nbRefresh, nbSearch);
  TButtonSet = set of TNavSchBtn;
  TNavButtonStyle = set of (nsAllowTimer, nsFocusRect);

  ENavClick = procedure(Sender: TObject; Button: TNavSchBtn) of object;

{ TDBNavSearch }

  TDBNavSearch = class(TCustomPanel)
  private
    FDataLink: TNavDataLink;
    FVisibleButtons: TButtonSet;
    FHints: TStrings;
    FDefHints: TStrings;
    ButtonWidth: Integer;
    MinBtnSize: TPoint;
    FOnNavClick: ENavClick;
    FBeforeAction: ENavClick;
    FocusedButton: TNavSchBtn;
    FConfirmDelete: Boolean;
    FRuKeybrd: Boolean;
    SearchFrmOldCreated: Boolean;
    FFlat: Boolean;
    procedure BtnMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ClickHandler(Sender: TObject);
    function GetDataSource: TDataSource;
    function GetHints: TStrings;
    procedure HintsChanged(Sender: TObject);
    procedure InitButtons;
    procedure InitHints;
    procedure SetDataSource(Value: TDataSource);
    procedure SetFlat(Value: Boolean);
    procedure SetHints(Value: TStrings);
    procedure SetSize(var W: Integer; var H: Integer);
    procedure SetVisible(Value: TButtonSet);
    procedure WMSize(var Message: TWMSize);  message WM_SIZE;
    procedure WMSetFocus(var Message: TWMSetFocus); message WM_SETFOCUS;
    procedure WMKillFocus(var Message: TWMKillFocus); message WM_KILLFOCUS;
    procedure WMGetDlgCode(var Message: TWMGetDlgCode); message WM_GETDLGCODE;
    procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
    procedure WMWindowPosChanging(var Message: TWMWindowPosChanging); message WM_WINDOWPOSCHANGING;
  protected
    Buttons: array[TNavSchBtn] of TNavButton;
    procedure DataChanged;
    procedure EditingChanged;
    procedure ActiveChanged;
    procedure Loaded; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure Notification(AComponent: TComponent;
      Operation: TOperation); override;
    procedure GetChildren(Proc: TGetChildProc; Root: TComponent); override;
    procedure CalcMinSize(var W, H: Integer);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure SetBounds(ALeft, ATop, AWidth, AHeight: Integer); override;
    procedure BtnClick(Index: TNavSchBtn); virtual;
  published
    property DataSource: TDataSource read GetDataSource write SetDataSource;
    property VisibleButtons: TButtonSet read FVisibleButtons write SetVisible
      default [nbFirst, nbPrior, nbNext, nbLast, nbInsert, nbDelete,
        nbEdit, nbPost, nbCancel, nbRefresh, nbSearch];
    property Align;
    property Anchors;
    property Constraints;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Flat: Boolean read FFlat write SetFlat default False;
    property Ctl3D;
    property Hints: TStrings read GetHints write SetHints;
    property ParentCtl3D;
    property ParentShowHint;
    property PopupMenu;
    property ConfirmDelete: Boolean read FConfirmDelete write FConfirmDelete default True;
    property RuKeybrd: Boolean read FRuKeybrd write FRuKeybrd default True;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property Visible;
    property BeforeAction: ENavClick read FBeforeAction write FBeforeAction;
    property OnClick: ENavClick read FOnNavClick write FOnNavClick;
    property OnContextPopup;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnResize;
    property OnStartDock;
    property OnStartDrag;
  end;

{ TNavButton }

  TNavButton = class(TSpeedButton)
  private
    FIndex: TNavSchBtn;
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
    property Index : TNavSchBtn read FIndex write FIndex;
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

var
  FirstLocate, LocateFound, RusKbLayout: Boolean;

implementation

uses BDE, Dialogs, DBSearch;

{$R DBNAV.RES}

{ TDBNavSearch }

const
  BtnTypeName: array[TNavSchBtn] of PChar = ('FIRST', 'PRIOR', 'NEXT',
    'LAST', 'INSERT', 'DELETE', 'EDIT', 'POST', 'CANCEL', 'REFRESH', 'SEARCH');
  BtnHintId: array[TNavSchBtn] of AnsiString = ('На первую запись', 'На предыдущую запись',
    'На следующую запись', 'На последнюю запись', 'Добавить новую запись', 'Удалить запись', 'Редактировать запись',
    'Записать изменения', 'Отменить изменения', 'Обновить данные', 'Найти запись');

constructor TDBNavSearch.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle - [csAcceptsControls, csSetCaption] + [csOpaque];
  if not NewStyleControls then ControlStyle := ControlStyle + [csFramed];
  FDataLink := TNavDataLink.Create(Self);
  FVisibleButtons := [nbFirst, nbPrior, nbNext, nbLast, nbInsert,
    nbDelete, nbEdit, nbPost, nbCancel, nbRefresh, nbSearch];
  FHints := TStringList.Create;
  TStringList(FHints).OnChange := HintsChanged;
  InitButtons;
  InitHints;
  BevelOuter := bvNone;
  BevelInner := bvNone;
  Width := 241;
  Height := 25;
  ButtonWidth := 0;
  FocusedButton := nbFirst;
  FConfirmDelete := True;
  FRuKeybrd := True;
  SearchFrmOldCreated := False;
  FullRepaint := False;
end;

destructor TDBNavSearch.Destroy;
begin
  FreeAndNil(FDefHints);
  FreeAndNil(FHints);
  FreeAndNil(FDataLink);
  inherited Destroy;
end;

procedure TDBNavSearch.InitButtons;
var
  I: TNavSchBtn;
  Btn: TNavButton;
  X: Integer;
begin
  MinBtnSize := Point(20, 18);
  X := 0;
  for I := Low(Buttons) to High(Buttons) do
    begin
    Btn := TNavButton.Create (Self);
    Btn.Flat := Flat;
    Btn.Index := I;
    Btn.Visible := I in FVisibleButtons;
    Btn.Enabled := True;
    Btn.SetBounds (X, 0, MinBtnSize.X, MinBtnSize.Y);
    Btn.Glyph.LoadFromResourceName(HInstance, 'DBNS' + BtnTypeName[I]);
    Btn.NumGlyphs := 2;
    Btn.Enabled := False;
    Btn.Enabled := True;
    Btn.OnClick := ClickHandler;
    Btn.OnMouseDown := BtnMouseDown;
    Btn.Parent := Self;
    Buttons[I] := Btn;
    X := X + MinBtnSize.X;
    end;
  Buttons[nbPrior].NavStyle := Buttons[nbPrior].NavStyle + [nsAllowTimer];
  Buttons[nbNext].NavStyle  := Buttons[nbNext].NavStyle + [nsAllowTimer];
end;

procedure TDBNavSearch.InitHints;
var
  I: Integer;
  J: TNavSchBtn;
begin
  if not Assigned(FDefHints) then
    begin
    FDefHints := TStringList.Create;
    for J := Low(Buttons) to High(Buttons) do
      FDefHints.Add(BtnHintId[J]);
    end;
  for J := Low(Buttons) to High(Buttons) do
    Buttons[J].Hint := FDefHints[Ord(J)];
  J := Low(Buttons);
  for I := 0 to (FHints.Count - 1) do
    begin
    if FHints.Strings[I] <> '' then Buttons[J].Hint := FHints.Strings[I];
    if J = High(Buttons) then Exit;
    Inc(J);
    end;
end;

procedure TDBNavSearch.HintsChanged(Sender: TObject);
begin
  InitHints;
end;

procedure TDBNavSearch.SetFlat(Value: Boolean);
var
  I: TNavSchBtn;
begin
  if FFlat <> Value then
    begin
    FFlat := Value;
    for I := Low(Buttons) to High(Buttons) do
      Buttons[I].Flat := Value;
    end;
end;

procedure TDBNavSearch.SetHints(Value: TStrings);
begin
  if Value.Text = FDefHints.Text then
    FHints.Clear
  else
    FHints.Assign(Value);
end;

function TDBNavSearch.GetHints: TStrings;
begin
  if (csDesigning in ComponentState) and not (csWriting in ComponentState) and
     not (csReading in ComponentState) and (FHints.Count = 0) then
    Result := FDefHints
  else
    Result := FHints;
end;

procedure TDBNavSearch.GetChildren(Proc: TGetChildProc; Root: TComponent);
begin
  // Do nothing
end;

procedure TDBNavSearch.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (FDataLink <> nil) and
     (AComponent = DataSource) then
    DataSource := nil;
end;

procedure TDBNavSearch.SetVisible(Value: TButtonSet);
var
  I: TNavSchBtn;
  W, H: Integer;
begin
  W := Width;
  H := Height;
  FVisibleButtons := Value;
  for I := Low(Buttons) to High(Buttons) do
    Buttons[I].Visible := I in FVisibleButtons;
  SetSize(W, H);
  if (W <> Width) or (H <> Height) then
    inherited SetBounds(Left, Top, W, H);
  Invalidate;
end;

procedure TDBNavSearch.CalcMinSize(var W, H: Integer);
var
  Count, Temp: Integer;
  I: TNavSchBtn;
begin
  if (csLoading in ComponentState) then Exit;
  if Buttons[nbFirst] = nil then Exit;
  Count := 0;
  for I := Low(Buttons) to High(Buttons) do
    if Buttons[I].Visible then
      Inc(Count);
  if Count = 0 then Inc(Count);
  Temp := Count * MinBtnSize.X;
  if W <= Temp then W := Temp;
  if H <= MinBtnSize.Y then H := MinBtnSize.Y;
  if Align = alNone then W := (W div Count) * Count;
end;

procedure TDBNavSearch.SetSize(var W: Integer; var H: Integer);
var
  Count: Integer;
  I: TNavSchBtn;
  Space, Temp, Remain: Integer;
  X: Integer;
begin
  if (csLoading in ComponentState) then Exit;
  if Buttons[nbFirst] = nil then Exit;
  CalcMinSize(W, H);
  Count := 0;
  for I := Low(Buttons) to High(Buttons) do
    if Buttons[I].Visible then
      Inc(Count);
  if Count = 0 then Inc(Count);
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
      Buttons[I].SetBounds(Width + 1, 0, ButtonWidth, Height);
    end;
end;

procedure TDBNavSearch.SetBounds(ALeft, ATop, AWidth, AHeight: Integer);
var
  W, H: Integer;
begin
  W := AWidth;
  H := AHeight;
  if not HandleAllocated then SetSize(W, H);
  inherited SetBounds(ALeft, ATop, W, H);
end;

procedure TDBNavSearch.WMSize(var Message: TWMSize);
var
  W, H: Integer;
begin
  inherited;
  W := Width; H := Height;
  SetSize(W, H);
end;

procedure TDBNavSearch.WMWindowPosChanging(var Message: TWMWindowPosChanging);
begin
  inherited;
  if (SWP_NOSIZE and Message.WindowPos.Flags) = 0 then
    CalcMinSize(Message.WindowPos.cx, Message.WindowPos.cy);
end;

procedure TDBNavSearch.ClickHandler(Sender: TObject);
begin
  BtnClick(TNavButton(Sender).Index);
end;

procedure TDBNavSearch.BtnMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  OldFocus: TNavSchBtn;
begin
  OldFocus := FocusedButton;
  FocusedButton := TNavButton(Sender).Index;
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

procedure TDBNavSearch.BtnClick(Index: TNavSchBtn);
const
  FldHeight = 30;
  TopPos = 2;
  LeftPos = 2;

  function VarArrayToSingle(VarArray: Variant): Variant;
  var
    ActualElements, Counter: Integer;
  begin
    if VarIsArray(VarArray) then
      begin
      ActualElements := 0;
      for Counter := VarArrayLowBound(VarArray, 1) to VarArrayHighBound(VarArray, 1) do
        if (VarArray[Counter] <> '') then
          inc(ActualElements);
      if (ActualElements = 1) then
        Result := VarArray[VarArrayLowBound(VarArray, 1)]
      else
        Result := VarArray;
      end
    else
      Result := VarArray;
  end;

  function Replicate(c: Char; w: Integer): String;
  begin
    SetLength(Result, w);
    FillChar(Result[1], w, c);
  end;

  function LeftString(s: String; w: Integer): String;
  begin
    Result := Copy(s, 1, w);
  end;

  function PadR(s: String; w: Integer; c: Char): String;
  begin
    if Length(s) > w then
      Result := LeftString(s, w)
    else
      if Length(s) = w then
        Result := s
      else
        Result := s + Replicate(c, w - Length(s));
  end;

var
  c, d, VisibleFields: Integer; TempLabel: TLabel;
  TempEdit: TWinControl; WidestLabelWidth, FieldWidth: Integer;
  FieldString: AnsiString; FValues: Variant; SearchOpts: TLocateOptions;
  b: TBookmark; fl: TList; fld: Variant; val: Array of Variant;
  i, fld_cnt: Integer; fld_str: String;
begin {1}
  if (DataSource <> nil) and (DataSource.State <> dsInactive) then
    begin {2}
    if not (csDesigning in ComponentState) and Assigned(FBeforeAction) then
      FBeforeAction(Self, Index);
    with DataSource.DataSet do
      begin {3}
      case Index of
        nbPrior:   Prior;
        nbNext:    Next;
        nbFirst:   First;
        nbLast:    Last;
        nbInsert:  Append;
        nbEdit:    Edit;
        nbCancel:  Cancel;
        nbPost:    Post;
        nbRefresh: Refresh;
        nbDelete:
          if not FConfirmDelete or
             (Application.MessageBox('Удалить запись?', 'Подтверждение',
                MB_ICONQUESTION or MB_YESNO or MB_DEFBUTTON2) <> ID_NO) then
            Delete;
        nbSearch:
          begin {4}
          if not SearchFrmOldCreated then
            SearchForm := TSearchForm.Create(Self);
          try
            with FDataLink.DataSet as TDataSet do
              begin {5}
              VisibleFields := 0;
              for c := 0 to Pred(FieldCount) do
                if Fields[c].Visible then
                  inc(VisibleFields);
              FValues := VarArrayCreate([0, Pred(VisibleFields)], varOleStr);
              if not SearchFrmOldCreated then
                begin {55}
                SearchFrmOldCreated := True;
                WidestLabelWidth := 0; d := 0;
                for c := 0 to Pred(FieldCount) do
                  if Fields[c].Visible then
                    begin {6}
                    TempLabel := TLabel.Create(SearchForm.ScrollBox1);
                    TempLabel.Parent := SearchForm.ScrollBox1;
                    TempLabel.AutoSize := True;
                    TempLabel.Caption := Fields[c].DisplayLabel;
                    If (d <> 0) then
                      TempLabel.Top := TopPos + (d * FldHeight)
                    else
                      TempLabel.Top := TopPos;
                    TempLabel.Left := LeftPos;
                    If (TempLabel.Width > WidestLabelWidth) then
                      WidestLabelWidth := TempLabel.Width;
                    inc(d);
                    end; {6}
                d := 0;
                for c := 0 to Pred(FieldCount) do
                  if Fields[c].Visible then
                    begin {6}
                    If (Fields[c].DataType <> ftBoolean) then
                      begin {7}
                      TempEdit := TEdit.Create(SearchForm.ScrollBox1);
                      TempEdit.Name := Fields[c].FieldName;
                      TEdit(TempEdit).Text := '';
                      if (Fields[c].DataType = ftString) then
                        if (Fields[c].DisplayWidth > Fields[c].Size) then
                          TEdit(TempEdit).MaxLength := Fields[c].DisplayWidth
                        else
                          TEdit(TempEdit).MaxLength := Fields[c].Size
                      else
                        TEdit(TempEdit).MaxLength := Fields[c].DisplayWidth;
                      end {7}
                    else
                      begin {7}
                      TempEdit := TCheckBox.Create(SearchForm.ScrollBox1);
                      TempEdit.Name := Fields[c].FieldName;
                      TCheckBox(TempEdit).Caption := '';
                      TCheckBox(TempEdit).State := cbGrayed;
                      end; {7}
                    TempEdit.Parent := SearchForm.ScrollBox1;
                    if (Fields[c].DataType = ftString) then
                      if (Fields[c].DisplayWidth > Fields[c].Size) then
                        FieldWidth := Fields[c].DisplayWidth + 2
                      else
                        FieldWidth := Fields[c].Size + 2
                    else
                      FieldWidth := Fields[c].DisplayWidth + 2;
                    TempEdit.Width := SearchForm.Canvas.TextWidth('W') * FieldWidth;
                    if (d <> 0) then
                      TempEdit.Top := TopPos + (d * FldHeight)
                    else
                      TempEdit.Top := TopPos;
                    TempEdit.Left := WidestLabelWidth + 5;
                    inc(d);
                    end; {6}
                end; {55}
              Self.Enabled := False;
              SearchForm.BitBtn1.Caption := 'Найти'; LocateFound := True;
              SearchForm.BitBtn1.Default := True; FirstLocate := True;
              RusKbLayout := False;
              if FRuKeybrd then
                RusKbLayout := True;
              while (SearchForm.ShowModal = mrOK) do
                begin {6}
                FieldString := ''; d := 0;
                with SearchForm do
                  begin {7}
                  for c := 0 to Pred(ScrollBox1.ComponentCount) do
                    if (ScrollBox1.Components[c] is TEdit) and
                       (TEdit(ScrollBox1.Components[c]).Text <> '') then
                      begin {8}
                      FieldString := FieldString + ScrollBox1.Components[c].Name + ';';
                      FValues[d] := TEdit(ScrollBox1.Components[c]).Text;
                      inc(d);
                      end {8}
                    else
                      if (ScrollBox1.Components[c] is TCheckBox) and
                         (TCheckBox(ScrollBox1.Components[c]).State <> cbGrayed) then
                        begin {8}
                        FieldString := FieldString + ScrollBox1.Components[c].Name + ';';
                        FValues[d] := TCheckBox(ScrollBox1.Components[c]).Checked;
                        inc(d);
                        end; {8}
                  SearchOpts := [];
                  If IgnoreCase.Checked then
                    SearchOpts := SearchOpts + [loCaseInsensitive];
                  If AllowPartial.Checked then
                    SearchOpts := SearchOpts + [loPartialKey];
                  end; {7}
                if (FieldString <> '') then
                  begin {7}
                  SetLength(FieldString, Pred(Length(FieldString)));
                  Screen.Cursor := crHourGlass;
                  DisableControls;
                  b := GetBookmark;
                  try
                    if FirstLocate then First else Next;
                    fl := TList.Create;
                    try
                      GetFieldList(fl, FieldString);
                      fld_cnt := fl.Count;
                      LocateFound := False;
                      SetLength(val, fld_cnt);
                      if not Eof then
                        for i := 0 to fld_cnt - 1 do
                          begin
                          if VarIsArray(FValues) then
                            val[i] := FValues[i]
                          else
                            val[i] := FValues;
                          if (TField(fl[i]).DataType = ftString) and
                             not VarIsNull(val[i]) then
                            begin
                            if (loCaseInsensitive in SearchOpts) then
                              val[i] := AnsiUpperCase(val[i]);
                            end;
                          end;
                      while ((not LocateFound) and (not Eof)) do
                        begin
                        i := 0;
                        LocateFound := True;
                        while (LocateFound and (i < fld_cnt)) do
                          begin
                          fld := TField(fl[i]).Value;
                          if VarIsNull(fld) then
                            LocateFound := LocateFound and VarIsNull(val[i])
                          else
                            begin
                            LocateFound := LocateFound and not VarIsNull(val[i]);
                            if LocateFound then
                              begin
                              try
                                fld := VarAsType(fld, VarType(val[i]));
                              except
                                on E: EVariantError do LocateFound := False;
                              end;
                              if TField(fl[i]).DataType = ftString then
                                begin
                                fld_str := TField(fl[i]).AsString;
                                if (loCaseInsensitive in SearchOpts) then
                                  fld_str := AnsiUpperCase(fld_str);
                                if (loPartialKey in SearchOpts) then
                                  LocateFound := LocateFound and (AnsiPos(val[i], fld_str) = 1)
                                else
                                  LocateFound := LocateFound and (fld_str = PadR(val[i], Length(fld_str), ' '));
                                end
                              else
                                if TField(fl[i]).DataType in [ftDate, ftTime, ftDateTime] then
                                  LocateFound := LocateFound and (DateTimeToStr(val[i]) = DateTimeToStr(fld))
                                else
                                  LocateFound := LocateFound and (val[i] = fld);
                              end;
                            end;
                          Inc(i);
                          end;
                        if not LocateFound then
                          Next;
                        end;
                    finally
                      fl.Free;
                      val := nil;
                    end;
                    if LocateFound then
                      CursorPosChanged
                    else
                      GotoBookmark(b);
                  finally
                    FreeBookmark(b);
                    EnableControls;
                  end; {try}
                  Screen.Cursor := crDefault;
                  if not LocateFound then break;
                  end {7}
                else break;
                SearchForm.BitBtn1.Caption := 'Найти еще';
                SearchForm.BitBtn1.Default := True; FirstLocate := False;
                end; {6}
              if not LocateFound then
                Application.MessageBox('Запись не найдена', 'Информация',
                  MB_ICONINFORMATION or MB_OK);
              end; {5}
          finally
            Self.Enabled := True;
          end; {try}
          end; {4}
      end; {case}
      end; {3}
    end; {2}
  if not (csDesigning in ComponentState) and Assigned(FOnNavClick) then
    FOnNavClick(Self, Index);
end; {1}

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
  NewFocus, OldFocus: TNavSchBtn;
begin
  OldFocus := FocusedButton;
  case Key of
    VK_RIGHT:
      begin
      if OldFocus < High(Buttons) then
        begin
        NewFocus := OldFocus;
        repeat
          NewFocus := Succ(NewFocus);
        until (NewFocus = High(Buttons)) or (Buttons[NewFocus].Visible);
        if Buttons[NewFocus].Visible then
          begin
          FocusedButton := NewFocus;
          Buttons[OldFocus].Invalidate;
          Buttons[NewFocus].Invalidate;
          end;
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
  CanModify, InEdit: Boolean;
begin
  CanModify := Enabled and FDataLink.Active and FDataLink.DataSet.CanModify;
  InEdit := FDataLink.Editing;
  Buttons[nbInsert].Enabled := CanModify;
  Buttons[nbEdit].Enabled := CanModify and not FDataLink.Editing;
  Buttons[nbPost].Enabled := CanModify and FDataLink.Editing;
  Buttons[nbCancel].Enabled := CanModify and FDataLink.Editing;
  Buttons[nbRefresh].Enabled := not (FDataLink.DataSet is TQuery);
  Buttons[nbSearch].Enabled := not InEdit;
end;

procedure TDBNavSearch.ActiveChanged;
var
  I: TNavSchBtn;
begin
  if not (Enabled and FDataLink.Active) then
    begin
    if SearchFrmOldCreated and (not FDataLink.Active) then
      begin
      FreeAndNil(SearchForm);
      SearchFrmOldCreated := False;
      end;
    for I := Low(Buttons) to High(Buttons) do
      Buttons[I].Enabled := False;
    end
  else
    begin
    DataChanged; EditingChanged;
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
  SetSize(W, H);
  if (W <> Width) or (H <> Height) then
    inherited SetBounds(Left, Top, W, H);
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
  inherited MouseDown(Button, Shift, X, Y);
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
  inherited MouseUp(Button, Shift, X, Y);
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
     (FIndex = TDBNavSearch(Parent).FocusedButton) then
  begin
    R := Bounds(0, 0, Width, Height);
    InflateRect(R, -3, -3);
    if FState = bsDown then
      OffsetRect(R, 1, 1);
    Canvas.Brush.Style := bsSolid;
    Font.Color := clBtnShadow;
    DrawFocusRect(Canvas.Handle, R);
  end;
end;

{ TNavDataLink }

constructor TNavDataLink.Create(ANav: TDBNavSearch);
begin
  inherited Create;
  FNavigator := ANav;
  VisualControl := True;
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
  RegisterComponents('Data Controls', [TDBNavSearch]);
end;

end.
