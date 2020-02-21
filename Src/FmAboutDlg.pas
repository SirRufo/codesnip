{
 * This Source Code Form is subject to the terms of the Mozilla Public License,
 * v. 2.0. If a copy of the MPL was not distributed with this file, You can
 * obtain one at http://mozilla.org/MPL/2.0/
 *
 * Copyright (C) 2005-2016, Peter Johnson (www.delphidabbler.com).
 *
 * $Rev$
 * $Date$
 *
 * Implements the program's About dialogue box.
}


unit FmAboutDlg;


interface


uses
  // VCL
  Forms,
  ComCtrls,
  StdCtrls,
  Controls,
  ExtCtrls,
  Classes,
  Messages,
  // Project
  Browser.UHTMLEvents,
  DB.UMetaData,
  FmGenericViewDlg,
  FrBrowserBase,
  FrHTMLDlg,
  FrHTMLTpltDlg,
  UCSSBuilder,
  UIStringList;


type

  {
  TPathInfoBox:
    Component that displays a path in a group box with an associated button that
    displays the path in Windows Explorer.
  }
  TPathInfoBox = class(TCustomGroupBox)
  strict private
    fPathLbl: TLabel;   // Label that displays path
    fViewBtn: TButton;  // Button that displays path in explorer
    function GetPath: string;
      {Read accessor for Path property. Gets value from label.
        @return Property value.
      }
    procedure SetPath(const Value: string);
      {Write accessor for Path property. Stores value in label and updates state
      of button.
        @param Value [in] New property value.
      }
    procedure BtnClick(Sender: TObject);
      {Button click event handler. Displays folder stored in Path property in
      Windows Explorer.
        @param Sender [in] Not used.
      }
    procedure FontChange(var Msg: TMessage); message CM_FONTCHANGED;
      {Handles font changes by resizing control to allow for new font size.
        @param Msg [in/out] Not used.
      }
    procedure ReArrange;
      {Resizes and re-arranges control and its sub-components.
      }
  strict protected
    procedure Resize; override;
      {Handles control resizing. Re-arranges control's sub-components.
      }
  public
    constructor Create(AOwner: TComponent); override;
      {Component constructor. Creates sub-components and arranges them.
        @param AOwner [in] Owning component.
      }
    property Path: string read GetPath write SetPath;
      {Path displayed in group box and displayed by view button}
  end;

  {
  TAboutDlg:
    Implements an about dialog box that uses web browser controls to display
    information about the program and the database. HTML templates containing
    the dialog box content are loaded from resources. Also provides access to
    the program's easter egg.
  }
  TAboutDlg = class(TGenericViewDlg)
    bvlSeparator: TBevel;
    frmDatabase: THTMLTpltDlgFrame;
    frmProgram: THTMLTpltDlgFrame;
    pcDetail: TPageControl;
    tsDatabase: TTabSheet;
    tsProgram: TTabSheet;
    pnlTitle: TPanel;
    frmTitle: THTMLTpltDlgFrame;
    tsPaths: TTabSheet;
    btnViewAppConfig: TButton;
    btnViewUserConfig: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    ///  <summary>Handles event triggered when user clicks on one of page
    ///  control tabs. Ensures page control has focus.</summary>
    ///  <remarks>Without this fix, page control does not always get focus when
    ///  a tab is clicked.</remarks>
    procedure pcDetailMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure btnViewAppConfigClick(Sender: TObject);
    procedure btnViewUserConfigClick(Sender: TObject);
  strict private
    fMainDBPathGp: TPathInfoBox;  // control that displays main database folder
    fUserDBPathGp: TPathInfoBox;  // control that displays user database folder
    fInstallPathGp: TPathInfoBox; // control that displays program install path
    fMetaData: IDBMetaData;       // stores main database meta data
    procedure HTMLEventHandler(Sender: TObject;
      const EventInfo: THTMLEventInfo);
      {Handles title frame's OnHTMLEvent event. Checks for easter-egg related
      mouse events on icon image and acts accordingly.
        @param Sender [in] Not used.
        @param EventInfo [in] Object providing information about the event.
      }
    function ContribListHTML(ContribList: IStringList): string;
      {Builds HTML used to display list of contributors or creates an error
      message if contributor list is not available.
        @param ContribList [in] list of contributors.
        @return Required HTML.
      }
    procedure ViewConfigFile(const FileName, DlgTitle: string);
      {Displays content of a config file in a preview dialogue box. If file
      does not exist an error message is displayed.
        @param FileName [in] Name of config file.
        @param DlgTitle [in] Title of preview dialogue box.
      }
  strict protected
    procedure ConfigForm; override;
      {Configures form by creating custom controls and initialising HTML frames.
      Called from ancestor class.
      }
    procedure InitHTMLFrames;
      {Initialises HTML frames to use required template document with
      placeholders replaced by required values.
      }
    procedure ArrangeForm; override;
      {Arranges controls on form.
      }
    procedure UpdateTitleCSS(Sender: TObject; const CSSBuilder: TCSSBuilder);
      {Updates CSS used for HTML displayed in title frame.
        @param Sender [in] Not used.
        @param CSSBuilder [in] Object used to update CSS.
      }
    procedure UpdateDetailCSS(Sender: TObject; const CSSBuilder: TCSSBuilder);
      {Updates CSS used for HTML displayed in detail (i.e. program and database)
      frames.
        @param Sender [in] Not used.
        @param CSSBuilder [in] Object used to update CSS.
      }
  public
    class procedure Execute(AOwner: TComponent);
      {Displays dialog box.
        @param AOwner [in] Component that owns this dialog box.
      }
  end;


implementation


uses
  // Delphi
  SysUtils,
  Graphics,
  Math,
  Windows,
  ShellAPI,
  IOUtils,
  // Project
  DB.UMain,
  FmEasterEgg,
  FmPreviewDlg,
  UAppInfo,
  UColours,
  UConsts,
  UCSSUtils,
  UCtrlArranger,
  UEncodings,
  UFontHelper,
  UGraphicUtils,
  UHTMLUtils,
  UHTMLTemplate,
  UIOUtils,
  UMessageBox,
  UResourceUtils,
  UStrUtils,
  UThemesEx;

{$R *.dfm}

function ExploreFolder(const Folder: string): Boolean;
  {Displays Windows Explorer showing a specified folder.
    @param Folder [in] Folder to explore.
    @return True if explorer displayed, False if not.
  }
begin
  if TDirectory.Exists(Folder) then
    Result := ShellExecute(
      0, 'explore', PChar(Folder), nil, nil, SW_SHOWNORMAL
    ) > 32
  else
    Result := False;
end;

{ TAboutDlg }

procedure TAboutDlg.ArrangeForm;
  {Arranges controls on form.
  }
var
  PathTabHeight: Integer;
begin
  fMainDBPathGp.Top := TCtrlArranger.BottomOf(fInstallPathGp, 8);
  fUserDBPathGp.Top := TCtrlArranger.BottomOf(fMainDBPathGp, 8);
  TCtrlArranger.AlignTops(
    [btnViewAppConfig, btnViewUserConfig],
    TCtrlArranger.BottomOf(fUserDBPathGp, 8)
  );
  PathTabHeight := TCtrlArranger.BottomOf(
    [btnViewUserConfig, btnViewAppConfig]
  );
  TCtrlArranger.AlignLefts([fUserDBPathGp, btnViewAppConfig]);
  TCtrlArranger.AlignRights([fUserDBPathGp, btnViewUserConfig]);
  // Set height of title frame and page control
  pnlTitle.Height := frmTitle.DocHeight;
  pcDetail.ClientHeight :=
    pcDetail.Height - tsProgram.ClientHeight +
    Max(
      PathTabHeight,
      Max(frmProgram.DocHeight, frmDatabase.DocHeight)
    ) + 8;
  pnlBody.ClientHeight := pnlTitle.Height + bvlSeparator.Height +
    pcDetail.Height;
  inherited;
end;

procedure TAboutDlg.btnViewAppConfigClick(Sender: TObject);
resourcestring
  sTitle = 'Application Config File';
begin
  ViewConfigFile(TAppInfo.AppConfigFileName, sTitle);
end;

procedure TAboutDlg.btnViewUserConfigClick(Sender: TObject);
resourcestring
  sTitle = 'Per-User Config File';
begin
  ViewConfigFile(TAppInfo.UserConfigFileName, sTitle);
end;

procedure TAboutDlg.ConfigForm;
  {Configures form by creating custom controls and initialising HTML frames.
  Called from ancestor class.
  }

  function CreatePathInfoBox(const Caption, Path: string;
    const TabOrder: Integer): TPathInfoBox;
    {Creates and initialises a custom path information control.
      @param Caption [in] Group box caption.
      @param Path [in] Path to be displayed.
      @param TabOrder [in] Tab order of info box.
      @return New control.
    }
  begin
    Result := TPathInfoBox.CreateParented(tsPaths.Handle);
    Result.Parent := tsPaths;
    Result.SetBounds(8, 8, tsPaths.ClientWidth - 16, 0);
    Result.Caption := Caption;
    Result.Path := Path;
    Result.TabOrder := TabOrder;
  end;

resourcestring
  // Captions for custom controls
  sInstallPathGpCaption = 'Install Directory';
  sMainDBPathGpCaption = 'Main Database Directory';
  sUserDBPathGpCaption = 'User Database Directory';
begin
  inherited;
  // Creates required custom controls
  fInstallPathGp := CreatePathInfoBox(
    sInstallPathGpCaption, TAppInfo.AppExeDir, 0
  );
  fMainDBPathGp := CreatePathInfoBox(
    sMainDBPathGpCaption, TAppInfo.AppDataDir, 1
  );
  fUserDBPathGp := CreatePathInfoBox(
    sUserDBPathGpCaption, TAppInfo.UserDataDir, 2
  );
  btnViewAppConfig.TabOrder := fUserDBPathGp.TabOrder + 1;
  btnViewUserConfig.TabOrder := btnViewAppConfig.TabOrder + 1;
  // Create meta data object
  fMetaData := TMainDBMetaDataFactory.MainDBMetaDataInstance;
  // Load content into HTML frames
  InitHTMLFrames;
end;

function TAboutDlg.ContribListHTML(ContribList: IStringList):
  string;
  {Builds HTML used to display list of contributors or creates an error message
  if contributor list is not available.
    @param ContribList [in] list of contributors.
    @return Required HTML.
  }
resourcestring
  // Error string used when contributor file not available
  sNoContributors = 'No contributors list available. Database may be corrupt';
var
  Contributor: string;          // name of a contributor
  DivAttrs: IHTMLAttributes;    // attributes of div tag
begin
  Result := '';
  if ContribList.Count > 0 then
  begin
    for Contributor in ContribList do
      Result := Result
        + THTML.CompoundTag('div', THTML.Entities(Contributor))
        + EOL;
  end
  else
  begin
    // List couldn't be found: display warning message
    DivAttrs := THTMLAttributes.Create('class', 'warning');
    Result := THTML.CompoundTag(
      'div', DivAttrs, THTML.Entities(sNoContributors)
    );
  end;
end;

class procedure TAboutDlg.Execute(AOwner: TComponent);
  {Displays dialog box.
    @param AOwner [in] Component that owns this dialog box.
  }
begin
  with Create(AOwner) do
    try
      ShowModal;
    finally
      Free;
    end;
end;

procedure TAboutDlg.FormCreate(Sender: TObject);
  {Form initialisation event handler. Sets handler that updates frame's CSS.
    @param Sender [in] Not used.
  }
begin
  inherited;
  frmTitle.OnBuildCSS := UpdateTitleCSS;
  frmProgram.OnBuildCSS := UpdateDetailCSS;
  frmDatabase.OnBuildCSS := UpdateDetailCSS;
end;

procedure TAboutDlg.FormDestroy(Sender: TObject);
  {Form destruction event handler. Frees non-owned controls.
    @param Sender [in] Not used.
  }
begin
  inherited;
  fInstallPathGp.Free;
  fMainDBPathGp.Free;
  fUserDBPathGp.Free;
end;

procedure TAboutDlg.HTMLEventHandler(Sender: TObject;
  const EventInfo: THTMLEventInfo);
  {Handles title frame's OnHTMLEvent event. Checks for easter-egg related mouse
  events on icon image and acts accordingly.
    @param Sender [in] Not used.
    @param EventInfo [in] Object providing information about the event.
  }
const
  cIconImgId = 'icon';  // id of icon image
begin
  // Check for onclick event on icon tag: display easter egg if ctrl key
  // pressed. Such an event is cancelled.
  if EventInfo.IsEvent(
      THTMLDocumentEvents2Sink.EventIntf,
      THTMLDocumentEvents2Sink.DISPID_OnClick
    )
    and EventInfo.Args.ctrlKey
    and EventInfo.ElemHasId(cIconImgId) then
  begin
    EventInfo.Cancelled := True;
    TEasterEggForm.Execute(Self);
  end;
  // Check for mouse move over icon tag: change cursor to hand if ctrl key
  // pressed to indicate clickable. Event permitted to bubble up.
  if EventInfo.IsEvent(
      THTMLDocumentEvents2Sink.EventIntf,
      THTMLDocumentEvents2Sink.DISPID_OnMouseMove
    )
    and EventInfo.ElemHasId(cIconImgId) then
  begin
    if EventInfo.Args.ctrlKey then
      EventInfo.Args.srcElement.style.cursor := 'hand'
    else
      EventInfo.Args.srcElement.style.cursor := 'auto';
  end;
end;

procedure TAboutDlg.InitHTMLFrames;
  {Initialises HTML frames to use required template document with placeholders
  replaced by required values.
  }

  // ---------------------------------------------------------------------------
  procedure InitTitleFrame;
    {Initialises and loads HTML into title frame.
    }
  begin
    frmTitle.Initialise(
      'dlg-about-head-tplt.html',
      procedure(Tplt: THTMLTemplate)
      begin
        Tplt.ResolvePlaceholderText('Release', TAppInfo.ProgramReleaseInfo);
        // MakeResourceURL('') provides just URL part before resource name
        Tplt.ResolvePlaceholderHTML('ResURL', MakeResourceURL(''));
      end
    );
    frmTitle.OnHTMLEvent := HTMLEventHandler;
  end;

  procedure InitProgramFrame;
    {Initialises and loads HTML into program frame.
    }
  begin
    pcDetail.ActivePage := tsProgram;   // display page to let browser load OK
    { TODO -cRefactor: Change this frmProgram so it's no longer a HTML template
            unless we need to add a gravatar link from Web.UInfo unit. }
    frmProgram.Initialise(
      'dlg-about-program-tplt.html',
      procedure(Tplt: THTMLTemplate)
      begin
        // Do nothing: no template placeholders now registration removed
      end
    );
  end;

  procedure InitDatabaseFrame;
    {Initialises and loads HTML into database frame.
    }
  begin
    // Ensure browser loads page so we can process it
    pcDetail.ActivePage := tsDatabase;

    frmDatabase.Initialise(
      'dlg-about-database-tplt.html',
      procedure(Tplt: THTMLTemplate)
      var
        IsDBAvalable: Boolean;
        IsMetaDataAvailable: Boolean;
        IsLicenseInfomAvailable: Boolean;
      begin
        // Resolve conditionally displayed block placeholders
        IsDBAvalable := Database.Snippets.Count(False) > 0;
        IsMetaDataAvailable := fMetaData.IsSupportedVersion
          and not fMetaData.IsCorrupt;
        IsLicenseInfomAvailable := IsMetaDataAvailable
          and (fMetaData.GetLicenseInfo.Name <> '')
          and (fMetaData.GetCopyrightInfo.Date <> '')
          and (fMetaData.GetCopyrightInfo.Holder <> '');
        Tplt.ResolvePlaceholderHTML(
          'DBAvailable',
          TCSS.BlockDisplayProp(IsDBAvalable)
        );
        Tplt.ResolvePlaceholderHTML(
          'DBNotAvailable',
          TCSS.BlockDisplayProp(not IsDBAvalable)
        );
        Tplt.ResolvePlaceholderHTML(
          'MetaDataAvailable',
          TCSS.BlockDisplayProp(IsMetaDataAvailable)
        );
        Tplt.ResolvePlaceholderHTML(
          'MetaDataNotAvailable',
          TCSS.BlockDisplayProp(not IsMetaDataAvailable)
        );
        Tplt.ResolvePlaceholderHTML(
          'LicenseInfoAvailable',
          TCSS.BlockDisplayProp(IsLicenseInfomAvailable)
        );
        Tplt.ResolvePlaceholderHTML(
          'LicenseInfoNotAvailable',
          TCSS.BlockDisplayProp(not IsLicenseInfomAvailable)
        );

        // Rsolve content placeholders
        Tplt.ResolvePlaceholderText(
          'CopyrightYear',
          fMetaData.GetCopyrightInfo.Date
        );
        Tplt.ResolvePlaceholderText(
          'CopyrightHolders',
          fMetaData.GetCopyrightInfo.Holder
        );
        Tplt.ResolvePlaceholderHTML(
          'DBLicense',
          StrIf(
            fMetaData.GetLicenseInfo.URL <> '',
            THTML.CompoundTag(
              'a',
              THTMLAttributes.Create([
                THTMLAttribute.Create('href', fMetaData.GetLicenseInfo.URL),
                THTMLAttribute.Create('class', 'external-link')
              ]),
              THTML.Entities(fMetaData.GetLicenseInfo.Name)
            ),
            THTML.Entities(fMetaData.GetLicenseInfo.Name)
          )
        );
        Tplt.ResolvePlaceholderHTML(
          'ContribList', ContribListHTML(fMetaData.GetContributors)
        );
        Tplt.ResolvePlaceholderHTML(
          'TesterList', ContribListHTML(fMetaData.GetTesters)
        );
      end
    );
  end;
  // ---------------------------------------------------------------------------

begin
  InitTitleFrame;
  InitDatabaseFrame;
  InitProgramFrame;
end;

procedure TAboutDlg.pcDetailMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if htOnItem in pcDetail.GetHitTestInfoAt(X, Y) then
    pcDetail.SetFocus;
end;

procedure TAboutDlg.UpdateDetailCSS(Sender: TObject;
  const CSSBuilder: TCSSBuilder);
  {Updates CSS used for HTML displayed in detail (i.e. program and database)
  frames.
    @param Sender [in] Not used.
    @param CSSBuilder [in] Object used to update CSS.
  }
var
  ContentFont: TFont; // font used for content
begin
  // Modify body's margin and, for themed windows, background colour
  with CSSBuilder.Selectors['body'] do
  begin
    ContentFont := TFont.Create;
    try
      TFontHelper.SetContentFont(ContentFont);
      AddProperty(TCSS.FontProps(ContentFont));
      if ThemeServicesEx.ThemesEnabled then
        AddProperty(TCSS.BackgroundColorProp(ThemeServicesEx.GetTabBodyColour));
      AddProperty(UCSSUtils.TCSS.MarginProp(0, 2, 6, 2));
    finally
      FreeAndNil(ContentFont);
    end;
  end;
  // Put border round scroll box
  with CSSBuilder.AddSelector('.scrollbox') do
    AddProperty(UCSSUtils.TCSS.BorderProp(cssAll, 1, cbsSolid, clBorder));
  // Set colours and font style of contributors and testers headings
  with CSSBuilder.AddSelector('.contrib-head, .tester-head') do
  begin
    AddProperty(TCSS.BackgroundColorProp(clBtnFace));
    AddProperty(TCSS.ColorProp(clBtnText));
    AddProperty(TCSS.FontWeightProp(cfwBold));
  end;
end;

procedure TAboutDlg.UpdateTitleCSS(Sender: TObject;
  const CSSBuilder: TCSSBuilder);
  {Updates CSS used for HTML displayed in title frame.
    @param Sender [in] Not used.
    @param CSSBuilder [in] Object used to update CSS.
  }
begin
  // Set body colour, and put border round it
  with CSSBuilder.Selectors['body'] do
  begin
    AddProperty(TCSS.BackgroundColorProp(clWindow));
    AddProperty(TCSS.PaddingProp(4));
  end;
end;

procedure TAboutDlg.ViewConfigFile(const FileName, DlgTitle: string);
var
  Data: TEncodedData;
resourcestring
  sErrorMsg = 'Sorry, this config file does not (yet) exist.';
begin
  if not TFile.Exists(FileName) then
  begin
    TMessageBox.Error(Self, sErrorMsg);
    Exit;
  end;
  Data := TEncodedData.Create(
    TFileIO.ReadAllText(FileName, TEncoding.Unicode, True),
    etUTF16LE
  );
  TPreviewDlg.Execute(Self, Data, dtPlainText, DlgTitle);
end;

{ TPathInfoBox }

procedure TPathInfoBox.BtnClick(Sender: TObject);
  {Button click event handler. Displays folder stored in Path property in
  Windows Explorer.
    @param Sender [in] Not used.
  }
begin
  if Assigned(fPathLbl) and (fPathLbl.Caption <> '') then
    ExploreFolder(fPathLbl.Caption);
end;

constructor TPathInfoBox.Create(AOwner: TComponent);
  {Component constructor. Creates sub-components and arranges them.
    @param AOwner [in] Owning component.
  }
resourcestring
  // Hint attached to view button
  sViewBtnHint = 'Explore...|Display the path in Windows Explorer';
begin
  inherited;
  // Create and setup path label
  fPathLbl := TLabel.Create(Self);
  fPathLbl.Parent := Self;
  fPathLbl.Left := 8;
  fPathLbl.Top := 8;
  fPathLbl.Width := 120;
  fPathLbl.AutoSize := False;
  fPathLbl.EllipsisPosition := epPathEllipsis;
  fPathLbl.Width := Self.Width - 16;
  fPathLbl.Caption := ' ';
  fPathLbl.Transparent := True;
  fPathLbl.ShowHint := True;
  // Create and setup view button
  fViewBtn := TButton.Create(Self);
  fViewBtn.Parent := Self;
  fViewBtn.OnClick := BtnClick;
  fViewBtn.Height := 19;
  fViewBtn.Width := 26;
  fViewBtn.Caption := '...';
  fViewBtn.Hint := sViewBtnHint;
  fViewBtn.ShowHint := True;
  // Ensure correct default font is used
  TFontHelper.SetDefaultBaseFont(Font);
  // Size and arrange controls
  ReArrange;
end;

procedure TPathInfoBox.FontChange(var Msg: TMessage);
  {Handles font changes by resizing control to allow for new font size.
    @param Msg [in/out] Not used.
  }
begin
  inherited;
  ReArrange;
end;

function TPathInfoBox.GetPath: string;
  {Read accessor for Path property. Gets value from label.
    @return Property value.
  }
begin
  Result := fPathLbl.Caption;
end;

procedure TPathInfoBox.ReArrange;
  {Resizes and re-arranges control and its sub-components.
  }
begin
  TCtrlArranger.SetLabelHeight(fPathLbl);
  Height := Max(fPathLbl.Height, fViewBtn.Height) + 24;
  TCtrlArranger.AlignVCentres(
    (ClientHeight - Max(fPathLbl.Height, fViewBtn.Height)) div 3 * 2,
    [fPathLbl, fViewBtn]
  );
  fViewBtn.Left := ClientWidth - fViewBtn.Width - 8;
  fPathLbl.Left := 8;
  fPathLbl.Width := fViewBtn.Left - fPathLbl.Left - 8;
end;

procedure TPathInfoBox.Resize;
  {Handles control resizing. Re-arranges control's sub-components.
  }
begin
  inherited;
  ReArrange;
end;

procedure TPathInfoBox.SetPath(const Value: string);
  {Write accessor for Path property. Stores value in label and updates state
  of button.
    @param Value [in] New property value.
  }
resourcestring
  // hints used when path doesn't exist
  sShortPathDoesNotExist = 'Path does not exist';
  sLongPathDoesNotExist = 'Path "%s"' + EOL + 'does not exist';
var
  TextW: Integer; // width of full path name in label in pixels
begin
  fPathLbl.Caption := Value;
  TextW := StringExtent(Value, fPathLbl.Font).cx;
  if TDirectory.Exists(Value) then
  begin
    if TextW > fPathLbl.Width then
      // path will contain ellipsis in label: display full path as hint
      fPathLbl.Hint := Value + '|'  // pipe char makes this short (pop-up) hint
    else
      // path fully displayed in label: no hint
      fPathLbl.Hint := '';
    fViewBtn.Enabled := True;
  end
  else
  begin
    if TextW > fPathLbl.Width then
      // path will contain ellipsis: display full path with message as hint
      fPathLbl.Hint := Format(sLongPathDoesNotExist, [Value]) + '|'
    else
      // path fully displayed in label: don't include full path in hint
      fPathLbl.Hint := sShortPathDoesNotExist;
    fViewBtn.Enabled :=  False;
  end;
end;

end.

