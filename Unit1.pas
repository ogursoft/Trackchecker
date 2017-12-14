unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, UseNewFonts, Winapi.shlobj, System.DateUtils,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, CoolTrayIcon, IdBaseComponent,
  IdComponent, IdTCPConnection, IdTCPClient, IniFiles, System.Math,
  IdExplicitTLSClientServerBase, IdMessageClient, IdSMTPBase, IdSMTP,
  JvSimpleXml, Vcl.StdCtrls, Vcl.Buttons, System.StrUtils, UEncrypt,
  PngBitBtn, Vcl.Mask, JvExMask, JvToolEdit, Vcl.ExtCtrls, JvBaseDlg,
  JvBrowseFolder, Vcl.ImgList, PngImageList, IdMessage, JvComponentBase,
  JvLogFile, JvLogClasses, SpTBXItem, SpTBXControls, Vcl.ComCtrls, Vcl.Menus,
  IdIOHandler, IdIOHandlerSocket, IdIOHandlerStack, IdSSL, IdSSLOpenSSL, idText,
  IdThreadComponent, Winapi.ShellApi, IdHTTP, EncdDecd, System.ImageList;

type
  TEventInfo = packed record
    GroupsId, TrackId, EventId: Cardinal;
    GroupsDesc, TrackNo, TrackDesc, EventDesc, Servid, EventDescTr: String;
    Groupscrdt, Crdt, Dt: TDateTime;
    Idx, Auto, UseDtr, TrackFinalized, TrackFinalizedBySvc, NewEvent: integer;
  end;

  TEventsArray = array of TEventInfo;

  TfmMain = class(TForm)
    CoolTrayIcon1: TCoolTrayIcon;
    OldDataXML: TJvSimpleXML;
    ApplyBtn: TPngBitBtn;
    ExitBtn: TPngBitBtn;
    FirstNotifyCheckBox: TCheckBox;
    Timer1: TTimer;
    NewDataXML: TJvSimpleXML;
    OptionsInfoLabel: TLabel;
    OptionsXML: TJvSimpleXML;
    DirEdit: TLabeledEdit;
    DirButton: TSpeedButton;
    JvBrowseForFolderDialog1: TJvBrowseForFolderDialog;
    DataInfoLabel: TLabel;
    OptionsXmlStatusImage: TImage;
    DataXmlStatusImage: TImage;
    PngImageList1: TPngImageList;
    PngImageCollection1: TPngImageCollection;
    LastUpdateLabel: TLabel;
    NextUpdateLabel: TLabel;
    IdMessage1: TIdMessage;
    IdSMTP1: TIdSMTP;
    JvLogFile1: TJvLogFile;
    SmtpServerEdit: TLabeledEdit;
    SmtpPortEdit: TLabeledEdit;
    SenderEmailEdit: TLabeledEdit;
    SmtpLoginEdit: TLabeledEdit;
    SmtpPassEdit: TLabeledEdit;
    EventsLabel: TLabel;
    ProgressBar1: TSpTBXProgressBar;
    AboutBtn: TPngBitBtn;
    PopupMenu1: TPopupMenu;
    N1: TMenuItem;
    N2: TMenuItem;
    N3: TMenuItem;
    N4: TMenuItem;
    PngImageList2: TPngImageList;
    N5: TMenuItem;
    RecieverEmailEdit: TLabeledEdit;
    IdSSLIOHandlerSocketOpenSSL1: TIdSSLIOHandlerSocketOpenSSL;
    TestMessageBtn: TPngBitBtn;
    UseSSLCheckBox: TCheckBox;
    TplEdit: TLabeledEdit;
    TemplateButton: TSpeedButton;
    IdThreadComponent1: TIdThreadComponent;
    OpenDialog1: TOpenDialog;
    UsePushBulletCheckBox: TCheckBox;
    PushBulletApiEdit: TLabeledEdit;
    PushBulletDevIdEdit: TLabeledEdit;
    procedure ExitBtnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure ApplyBtnClick(Sender: TObject);
    procedure DirButtonClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure CoolTrayIcon1Startup(Sender: TObject; var ShowMainForm: Boolean);
    procedure CoolTrayIcon1Click(Sender: TObject);
    procedure AboutBtnClick(Sender: TObject);
    procedure SmtpPassEditEnter(Sender: TObject);
    function AppVersion(AFilename: string): string;
    procedure BitBtn1Click(Sender: TObject);
    procedure TestMessageBtnClick(Sender: TObject);
    procedure IdMessage1InitializeISO(var VHeaderEncoding: Char;
      var VCharSet: string);
    procedure TemplateButtonClick(Sender: TObject);
    procedure UsePushBulletCheckBoxClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure IdSMTP1Status(ASender: TObject; const AStatus: TIdStatus;
      const AStatusText: string);
    procedure IdSMTP1Work(ASender: TObject; AWorkMode: TWorkMode;
      AWorkCount: Int64);
    procedure IdSMTP1WorkBegin(ASender: TObject; AWorkMode: TWorkMode;
      AWorkCountMax: Int64);
    procedure IdSMTP1WorkEnd(ASender: TObject; AWorkMode: TWorkMode);
    procedure IdSMTP1Connected(Sender: TObject);
    procedure IdSMTP1Disconnected(Sender: TObject);
    procedure IdSMTP1FailedRecipient(Sender: TObject;
      const AAddress, ACode, AText: string; var VContinue: Boolean);
  private
    procedure WriteSettings;
    procedure Check(Sender: TObject);
    procedure ParseIntoEventsArray(AnXMLNode: TJvSimpleXmlElem;
      var Events: TEventsArray);
    procedure SendEmail;
    procedure UsePushBulletCheck(Sender: TObject);
    function SendPushBullet: Boolean;
    { Private declarations }
  public
    procedure ReadSettings;
    function GetSpecialFolderPath(folder: integer): string;
    { Public declarations }
  end;

Const
  SProgPath = 'Ogursoft\Trchkn\';
  SDataXML = 'data.xml';
  SOptionsXML = 'options.xml';
  SCurlCmd =
    ' --insecure https://api.pushbullet.com/v2/pushes -u %s: -d "type"="note" -d "title"="%s" -d "body"="%s" -X POST';
  // SCurlCmd = ' -k -u %s: -X POST https://api.pushbullet.com/v2/pushes --header '#39'Content-Type: application/json'#39' --data-binary '#39'{"type": "note", "title": "%s", "body": "%s"}'#39'';
  SPushBulletCmd = '-apikey "%s" -title "%s" -message "%s"';
  SCurlDeviceId = '-d device_iden=%s';
  SFileLoaded = '���� %s ��������';
  SFileNotLoaded = '���� %s �� ��������! (������������ ���� � �����?)';
  SLastUpd = '��������� �������� ����: dddd dd mmmm yyyy hh:mm:ss';
  SNextUpd = '��������� �������� �����: dddd dd mmmm yyyy hh:mm:ss';
  SMessStr = '%s, %s, %s, %s, %s';
  SMessHeader = '��������, � ��������� TrackChecker �������� ����� �������';
  SEventsInfo =
    '��������� ��������: ������: %d (%d), �������: %d (%d), �������������: %d';
  SEventsHint =
    '��������� ��������: ������: %d (%d), �������: %d (%d),'#13#10'�������������: %d';
  SDescription =
    '��������� ��� �������� �� �� ����� ���������� ��� ������������� ������� � ��������� TrackChecker';
  SAutor = '�����: Ogursoft';
  SVersion = '������: %s';
  SChangePassword = '[��� ��������� ������������ ������ �������� �����]';
  SProgVersion = '������ ���������: %s';
  ek = 16416;
  SNullDate = 693594;
  SNever = '��������� �������� ����: �������';
  SUnknown = '��������� �������� �����: ����������';
  SMailSendError = '������ �������� �����';
  SFileCopyError = '������ ����������� ����� %s. ��� ������: %d';
  SOptionsFileNotLoaded = '���� %s �� ��������. ������ ��������� ����������!';

  STplItems: array [0 .. 5] of string = ('<groups>', '<item>', '<trackno>',
    '<dt>', '<event_descr>', '<event_descr_tr>');

  SDefaultMailTpl =
    '������: <groups>, �������: <item>, ����: <trackno>, ����: <dt>, �������: <event_descr_tr>';
  STestMessage =
    '��� ������� ��������� ��� �������� ����������������� ��������� TrackCheckerNotifier';
  // 'This is just test message for check TrackCheckerNotifier application';

var
  fmMain: TfmMain;
  LastUpd, PrevUpd, CheckTime, FileDate: TDateTime;
  ProgPath, AppDataPath, DataPath, OptionsFile, DataLocalFile, DataFile,
    SenderLogin, SenderPass, SmtpServer, RecieverEmail, SenderEmail,
    MailSubject, MailText, TplText, TplFileName, PushBulletApiKey,
    PushBulletDevId, PushBulletDevIdStr, PushBulletCmd: String;
  FirstStartNotify, Sended, FirstCheck, PwdChanged: Boolean;
  Fs: TFormatSettings;
  CheckPeriod, SmtpPort: Cardinal;
  OldEvents, NewEvents, NotifyEvents: TEventsArray;
  NewEventsId, OldEventsId, NotifyEventsId, TplFile: TStringList;
  UnReadCount, TracksCount, EventsCount, ActiveTracksCount, GroupsId,
    TrackId: integer;
  UseSSL, UsePushBullet: Boolean;

implementation

{$R *.dfm}

uses Unit2;

function CheckTpl(TplText: String): Boolean;
var
  i: integer;
  AFile: TextFile;
begin
  result := false;
  for i := Low(STplItems) to High(STplItems) do
    if AnsiContainsText(TplText, STplItems[i]) then
    begin
      result := true;
      break;
    end;
end;

function Tpl(TplText, GroupsDesc, TrackDesc, TrackNo, Dt, EventDesc,
  EventDescTr: String): String;
var
  i: integer;
begin
  for i := Low(STplItems) to High(STplItems) do
    case i of
      0:
        TplText := System.StrUtils.ReplaceText(TplText, STplItems[i],
          GroupsDesc);
      1:
        TplText := System.StrUtils.ReplaceText(TplText, STplItems[i],
          TrackDesc);
      2:
        TplText := System.StrUtils.ReplaceText(TplText, STplItems[i], TrackNo);
      3:
        TplText := System.StrUtils.ReplaceText(TplText, STplItems[i], Dt);
      4:
        TplText := System.StrUtils.ReplaceText(TplText, STplItems[i],
          EventDesc);
      5:
        if Length(trim(EventDescTr)) = 0 then
          TplText := System.StrUtils.ReplaceText(TplText, STplItems[i],
            EventDesc)
        else
          TplText := System.StrUtils.ReplaceText(TplText, STplItems[i],
            EventDescTr);
    end;
  result := TplText;
end;

function GetFileDate(FileName: string): TDateTime;
var
  FHandle: integer;
begin
  FHandle := FileOpen(FileName, 0);
  try
    if FHandle >= 0 then
      result := FileDateToDateTime(FileGetDate(FHandle));
  finally
    FileClose(FHandle);
  end;
end;

function TfmMain.AppVersion(AFilename: string): string;
var
  szName: array [0 .. 255] of Char;
  P: Pointer;
  Value: Pointer;
  Len: UINT;
  GetTranslationString: string;
  FFileName: PChar;
  FValid: Boolean;
  FSize: DWORD;
  FHandle: DWORD;
  FBuffer: PChar;
begin
  try
    FFileName := StrPCopy(StrAlloc(Length(AFilename) + 1), AFilename);
    FValid := false;
    FSize := GetFileVersionInfoSize(FFileName, FHandle);
    if FSize > 0 then
      try
        GetMem(FBuffer, FSize);
        FValid := GetFileVersionInfo(FFileName, FHandle, FSize, FBuffer);
      except
        FValid := false;
        raise;
      end;
    result := '';
    if FValid then
      VerQueryValue(FBuffer, '\VarFileInfo\Translation', P, Len)
    else
      P := nil;
    if P <> nil then
      GetTranslationString :=
        IntToHex(MakeLong(HiWord(Longint(P^)), LoWord(Longint(P^))), 8);
    if FValid then
    begin
      StrPCopy(szName, '\StringFileInfo\' + GetTranslationString +
        '\FileVersion');
      if VerQueryValue(FBuffer, szName, Value, Len) then
        result := StrPas(PChar(Value));
    end;
  finally
    try
      if FBuffer <> nil then
        FreeMem(FBuffer, FSize);
    except
    end;
    try
      StrDispose(FFileName);
    except
    end;
  end;
end;

procedure TfmMain.BitBtn1Click(Sender: TObject);
var
  i: integer;
  Str, TrackNo: string;
begin
  { ShowMessage(Decrypt(SenderPass, ek));
    Str := EmptyStr;
    for i := Low(NewEvents) to High(NewEvents) do
    begin
    if NewEvents[i].TrackFinalizedBySvc = 1 then
    if TrackNo <> NewEvents[i].TrackNo then
    Str := Str + NewEvents[i].TrackNo + #13#10;
    TrackNo := NewEvents[i].TrackNo;
    end;
    ShowMessage(Str); }
end;

procedure TfmMain.SendEmail();
begin
  Sended := false;
  IdSMTP1.Host := SmtpServer;
  IdSMTP1.Username := SenderLogin;
  IdSMTP1.Password := Decrypt(SenderPass, ek);
  { TidText.Create(IdMessage1.MessageParts, idMessage1.Body);
    IdMessage1.MessageParts.Items[0].ContentType := 'text/html';
    IdMessage1.MessageParts.Items[0].CharSet := 'utf-8'; }
  IdMessage1.CharSet := 'utf-8';
  SysLocale.PriLangID := LANG_SYSTEM_DEFAULT;
  if (UseSSL) then
  begin
    IdSSLIOHandlerSocketOpenSSL1.Destination := IdSMTP1.Host + ':' +
      IntToStr(IdSMTP1.Port);
    IdSSLIOHandlerSocketOpenSSL1.Host := IdSMTP1.Host;
    IdSSLIOHandlerSocketOpenSSL1.Port := IdSMTP1.Port;
    IdSSLIOHandlerSocketOpenSSL1.DefaultPort := 0;
    IdSSLIOHandlerSocketOpenSSL1.SSLOptions.Method := sslvTLSv1;
    IdSSLIOHandlerSocketOpenSSL1.SSLOptions.Mode := sslmUnassigned;
    IdSMTP1.IOHandler := IdSSLIOHandlerSocketOpenSSL1;
    IdSMTP1.UseTLS := utUseRequireTLS;
  end
  else
  begin
    IdSMTP1.IOHandler := nil;
    IdSMTP1.UseTLS := utNoTLSSupport;
  end;
  try
    try
      IdSMTP1.Connect;
      if IdSMTP1.Connected = true then
        IdSMTP1.Send(IdMessage1);
      Sended := true;
    except
      on E: Exception do
      begin
        JvLogFile1.Add(SMailSendError, lesError, E.ToString);
        Sended := false;
      end;
      // E.Create('������ �������� �����' + E.ToString);
      // DoSMTPSendError(E);
    end;
  finally
    IdSMTP1.Disconnect;
  end;
end;

function Curl(aURL, Body: string): string;
const
  cUSER_AGENT = 'Mozilla/4.0 (MSIE 6.0; Windows NT 5.1)';
var
  IdHTTP: TIdHTTP;
  IdHandler: TIdSSLIOHandlerSocketOpenSSL;
  Stream: TStringStream;
begin
  result := '';
  IdHandler := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
  IdHTTP := TIdHTTP.Create(nil);
  IdHTTP.IOHandler := IdHandler;
  Stream := TStringStream.Create;
  try
    IdHTTP.Request.UserAgent := cUSER_AGENT;
    try
      IdHTTP.Get(aURL);
      IdHTTP.Post(aURL, Body);
      result := Stream.DataString;
    except
      { on Ex : EOSError do
        MessageDlg('Caught an OS error with code: ' + IntToStr(Ex.ErrorCode), mtError, [mbOK], 0); }
    end;
  finally
    Stream.Free;
    IdHTTP.Free;
  end;
end;

function Translit(s: string): string;
const
  rus: string =
    '�������������������������������������Ũ��������������������������';
  lat: array [1 .. 66] of string = ('a', 'b', 'v', 'g', 'd', 'e', 'yo', 'zh',
    'z', 'i', 'y', 'k', 'l', 'm', 'n', 'o', 'p', 'r', 's', 't', 'u', 'f', 'kh',
    'ts', 'ch', 'sh', 'shch', '''', 'y', '''', 'e', 'yu', 'ya', 'A', 'B', 'V',
    'G', 'D', 'E', 'Yo', 'Zh', 'Z', 'I', 'Y', 'K', 'L', 'M', 'N', 'O', 'P', 'R',
    'S', 'T', 'U', 'F', 'Kh', 'Ts', 'Ch', 'Sh', 'Shch', '''', 'y', '''', 'E',
    'Yu', 'Ya');
var
  P, i, l: integer;
begin
  result := '';
  l := Length(s);
  for i := 1 to l do
  begin
    P := Pos(s[i], rus);
    if P < 1 then
      result := result + s[i]
    else
      result := result + lat[P];
  end;
end;

function TfmMain.SendPushBullet(): Boolean;
var
  SEI: TShellExecuteInfo;
  lpExitCode: DWORD;
begin
  try
    Timer1.Enabled := false;
    ProgressBar1.Position := 0;
    ProgressBar1.Caption := '���� �������� ��������� Pushbullet...';
    if Length(PushBulletDevId) <> 22 then
      PushBulletDevIdStr := EmptyStr
    else
      PushBulletDevIdStr := ' ' + Format(SCurlDeviceId,
        [trim(PushBulletDevId)]);
    PushBulletCmd := PushBulletDevIdStr +
      ReplaceText(Format(SPushBulletCmd, [trim(PushBulletApiKey),
      Utf8Encode(Translit(trim(IdMessage1.Subject))),
      Utf8Encode(Translit(trim(IdMessage1.Body.Text)))]), #13#10, ' ');
    if FileExists(ProgPath + 'pushbullet.exe') then
    begin
      ZeroMemory(@SEI, SizeOf(SEI));
      SEI.cbSize := SizeOf(TShellExecuteInfo);
      SEI.Wnd := 0;
      SEI.fMask := SEE_MASK_FLAG_DDEWAIT or SEE_MASK_FLAG_NO_UI;
      SEI.lpVerb := PChar('open');
      SEI.lpFile := PChar(ProgPath + 'pushbullet.exe');
      SEI.nShow := SW_HIDE;
      SEI.lpParameters := PChar(PushBulletCmd);
      result := ShellExecuteEx(@SEI);
    end;
  finally
    Timer1.Enabled := true;
  end;
end;

procedure TfmMain.SmtpPassEditEnter(Sender: TObject);
begin
  SmtpPassEdit.Clear;
  SmtpPassEdit.PasswordChar := '*';
  PwdChanged := true;
end;

function TfmMain.GetSpecialFolderPath(folder: integer): string;
const
  SHGFP_TYPE_CURRENT = 0;
var
  path: array [0 .. MAX_PATH] of Char;
begin
  if SUCCEEDED(SHGetFolderPath(0, folder, 0, SHGFP_TYPE_CURRENT, @path[0])) then
    result := path
  else
    result := '';
end;

procedure TfmMain.IdMessage1InitializeISO(var VHeaderEncoding: Char;
  var VCharSet: string);
begin
  VCharSet := IdMessage1.CharSet;
end;

procedure TfmMain.IdSMTP1Connected(Sender: TObject);
begin
  ProgressBar1.Caption := '���������� � �������� �������� �����������';
end;

procedure TfmMain.IdSMTP1Disconnected(Sender: TObject);
begin
  ProgressBar1.Caption := '���������� � �������� �������� ���������';
end;

procedure TfmMain.IdSMTP1FailedRecipient(Sender: TObject;
  const AAddress, ACode, AText: string; var VContinue: Boolean);
begin
  ProgressBar1.Caption := AText;
end;

procedure TfmMain.IdSMTP1Status(ASender: TObject; const AStatus: TIdStatus;
  const AStatusText: string);
begin
  ProgressBar1.Caption := '���� �������� ��������� ���������...';
end;

procedure TfmMain.IdSMTP1Work(ASender: TObject; AWorkMode: TWorkMode;
  AWorkCount: Int64);
begin
  Application.ProcessMessages;
  ProgressBar1.Position := AWorkCount;
end;

procedure TfmMain.IdSMTP1WorkBegin(ASender: TObject; AWorkMode: TWorkMode;
  AWorkCountMax: Int64);
begin
  Timer1.Enabled := false;
  ProgressBar1.Max := AWorkCountMax;
end;

procedure TfmMain.IdSMTP1WorkEnd(ASender: TObject; AWorkMode: TWorkMode);
begin
  Timer1.Enabled := true;
  ProgressBar1.Max := 100;
end;

procedure TfmMain.ReadSettings();
var
  Reg: TiniFile;
begin
  try
    Reg := TiniFile.Create(AppDataPath +
      ChangeFileExt(ExtractFileName(Application.ExeName), '.ini'));
    DataPath := Reg.ReadString('Main', 'DataPath', EmptyStr);
    FirstStartNotify := Reg.ReadBool('Main', 'FirstStartNotify', false);
    SmtpServer := Reg.ReadString('Main', 'SmtpServer', EmptyStr);
    SmtpPort := Reg.ReadInteger('Main', 'SmtpPort', 25);
    SenderLogin := Reg.ReadString('Main', 'SenderLogin', EmptyStr);
    SenderPass := Reg.ReadString('Main', 'SenderPass', EmptyStr);
    SenderEmail := Reg.ReadString('Main', 'SenderEmail', EmptyStr);
    RecieverEmail := Reg.ReadString('Main', 'RecieverEmail', EmptyStr);
    UseSSL := Reg.ReadBool('Main', 'useSSL', false);
    TplFileName := Reg.ReadString('Main', 'tpl', EmptyStr);
    UsePushBullet := Reg.ReadBool('Main', 'UsePushBullet', false);
    PushBulletApiKey := Reg.ReadString('Main', 'PushBulletApiKey', EmptyStr);
    PushBulletDevId := Reg.ReadString('Main', 'PushBulletDevId', EmptyStr);
  finally
    Reg.Free;
  end;
end;

procedure TfmMain.DirButtonClick(Sender: TObject);
begin
  if JvBrowseForFolderDialog1.Execute then
    DirEdit.Text := JvBrowseForFolderDialog1.Directory;
end;

procedure TfmMain.WriteSettings();
var
  Reg: TiniFile;
begin
  try
    Reg := TiniFile.Create(AppDataPath +
      ChangeFileExt(ExtractFileName(Application.ExeName), '.ini'));
    Reg.WriteString('Main', 'DataPath', DataPath);
    Reg.WriteBool('Main', 'FirstStartNotify', FirstStartNotify);
    Reg.WriteString('Main', 'SmtpServer', SmtpServer);
    Reg.WriteInteger('Main', 'SmtpPort', SmtpPort);
    Reg.WriteString('Main', 'SenderLogin', SenderLogin);
    Reg.WriteString('Main', 'SenderPass', SenderPass);
    Reg.WriteString('Main', 'SenderEmail', SenderEmail);
    Reg.WriteString('Main', 'RecieverEmail', RecieverEmail);
    Reg.WriteBool('Main', 'useSSL', UseSSL);
    Reg.WriteString('Main', 'tpl', TplFileName);
    Reg.WriteBool('Main', 'UsePushBullet', UsePushBullet);
    Reg.WriteString('Main', 'PushBulletApiKey', PushBulletApiKey);
    Reg.WriteString('Main', 'PushBulletDevId', PushBulletDevId);
  finally
    Reg.Free;
  end;
end;

procedure TfmMain.ApplyBtnClick(Sender: TObject);
begin
  DataPath := DirEdit.Text;
  OptionsFile := IncludeTrailingPathDelimiter(DataPath) + SOptionsXML;
  DataFile := IncludeTrailingPathDelimiter(DataPath) + SDataXML;
  FirstStartNotify := not FirstNotifyCheckBox.Checked;
  SmtpServer := SmtpServerEdit.Text;
  SmtpPort := StrToInt(SmtpPortEdit.Text);
  SenderLogin := SmtpLoginEdit.Text;
  if PwdChanged then
    SenderPass := Encrypt(SmtpPassEdit.Text, ek);
  SenderEmail := SenderEmailEdit.Text;
  RecieverEmail := RecieverEmailEdit.Text;
  UseSSL := UseSSLCheckBox.Checked;
  TplFileName := TplEdit.Text;
  if FileExists(TplFileName) then
  begin
    TplFile.Clear;
    TplFile.LoadFromFile(TplFileName);
  end;
  TplText := TplFile.Text;
  UsePushBullet := UsePushBulletCheckBox.Checked;
  PushBulletApiKey := PushBulletApiEdit.Text;
  PushBulletDevId := PushBulletDevIdEdit.Text;
  WriteSettings();
  Check(Sender);
end;

procedure TfmMain.ExitBtnClick(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TfmMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := false;
  CoolTrayIcon1.HideMainForm;
end;

procedure TfmMain.FormCreate(Sender: TObject);
var
  TimeStamp: TTimeStamp;
begin
  Fs := TFormatSettings.Create('ru-RU');
  Fs.DateSeparator := '-';
  Fs.ShortDateFormat := 'yyyy-mm-dd';
  fmMain.Caption := Application.title;
  fmMain.Font.Assign(GUIFont);
  DirEdit.Text := DataPath;
  FirstNotifyCheckBox.Checked := not FirstStartNotify;
  OptionsFile := IncludeTrailingPathDelimiter(DataPath) + SOptionsXML;
  DataFile := IncludeTrailingPathDelimiter(DataPath) + SDataXML;
  NewEventsId := TStringList.Create;
  OldEventsId := TStringList.Create;
  TplFile := TStringList.Create;
  NotifyEventsId := TStringList.Create;
  SmtpServerEdit.Text := SmtpServer;
  SmtpPortEdit.Text := IntToStr(SmtpPort);
  SmtpLoginEdit.Text := SenderLogin;
  PwdChanged := false;
  SmtpPassEdit.Text := SChangePassword;
  SenderEmailEdit.Text := SenderEmail;
  RecieverEmailEdit.Text := RecieverEmail;
  UseSSLCheckBox.Checked := UseSSL;
  TplEdit.Text := TplFileName;
  UsePushBulletCheckBox.Checked := UsePushBullet;
  PushBulletApiEdit.Text := PushBulletApiKey;
  PushBulletDevIdEdit.Text := PushBulletDevId;
  FirstCheck := false;
  // Check(Sender);
  if FileExists(OptionsFile) then
    FileDate := GetFileDate(OptionsFile);
  JvLogFile1.FileName := AppDataPath +
    ChangeFileExt(ExtractFileName(Application.ExeName), '.log');
  JvLogFile1.AutoSave := true;
end;

procedure TfmMain.FormShow(Sender: TObject);
begin
  UsePushBulletCheck(Sender);
end;

procedure TfmMain.ParseIntoEventsArray(AnXMLNode: TJvSimpleXmlElem;
  var Events: TEventsArray);
var
  i, j, k: integer;
  s, T: string;
begin
  if AnXMLNode <> nil then
  begin
    if AnXMLNode.Value <> '' then
      s := AnXMLNode.Name + '=' + AnXMLNode.Value
    else
      s := AnXMLNode.Name;
    T := '';
    if AnXMLNode.Name = 'event' then
    // for j := 0 to AnXMLNode.Properties.Count - 1 do
    // T := T + ' ' + AnXMLNode.Properties[j].Name + '="' + System.UTF8ToString(AnXMLNode.Properties[j].Value) + '"';
    begin
      SetLength(Events, Length(Events) + 1);
      if AnXMLNode.Properties.ItemNamed['id'] <> nil then
        Events[Length(Events) - 1].EventId := AnXMLNode.Properties.ItemNamed
          ['id'].IntValue;
      if AnXMLNode.Properties.ItemNamed['desc'] <> nil then
        Events[Length(Events) - 1].EventDesc :=
          System.UTF8ToString(AnXMLNode.Properties.ItemNamed['desc'].Value);
      if AnXMLNode.Properties.ItemNamed['dt'] <> nil then
        Events[Length(Events) - 1].Dt :=
          StrToDateTime(AnsiReplaceStr(AnXMLNode.Properties.ItemNamed['dt']
          .Value, 'T', ' '), Fs);
      if AnXMLNode.Properties.ItemNamed['newevt'] <> nil then
        Events[Length(Events) - 1].NewEvent := AnXMLNode.Properties.ItemNamed
          ['newevt'].IntValue;
      if AnXMLNode.Properties.ItemNamed['desc_tr'] <> nil then
        Events[Length(Events) - 1].EventDescTr :=
          System.UTF8ToString(AnXMLNode.Properties.ItemNamed['desc_tr'].Value);
      if AnXMLNode.Parent.Properties.ItemNamed['id'] <> nil then
        Events[Length(Events) - 1].TrackId :=
          AnXMLNode.Parent.Properties.ItemNamed['id'].IntValue;

      if AnXMLNode.Parent.Parent.Properties.ItemNamed['id'] <> nil then
        Events[Length(Events) - 1].GroupsId :=
          AnXMLNode.Parent.Parent.Properties.ItemNamed['id'].IntValue;

      if AnXMLNode.Parent.Parent.Properties.ItemNamed['desc'] <> nil then
        Events[Length(Events) - 1].GroupsDesc :=
          System.UTF8ToString(AnXMLNode.Parent.Parent.Properties.ItemNamed
          ['desc'].Value);

      if AnXMLNode.Parent.Parent.Properties.ItemNamed['crdt'] <> nil then
        Events[Length(Events) - 1].Groupscrdt :=
          StrToDateTime(AnsiReplaceStr(AnXMLNode.Properties.ItemNamed['crdt']
          .Value, 'T', ' '), Fs);

      if AnXMLNode.Parent.Properties.ItemNamed['desc'] <> nil then
        Events[Length(Events) - 1].TrackDesc :=
          System.UTF8ToString(AnXMLNode.Parent.Properties.ItemNamed
          ['desc'].Value);
      if AnXMLNode.Parent.Properties.ItemNamed['final'] <> nil then
        Events[Length(Events) - 1].TrackFinalized :=
          AnXMLNode.Parent.Properties.ItemNamed['final'].IntValue
      else
        Events[Length(Events) - 1].TrackFinalized := -1;

      if AnXMLNode.Parent.Properties.ItemNamed['track'] <> nil then
        Events[Length(Events) - 1].TrackNo :=
          AnXMLNode.Parent.Properties.ItemNamed['track'].Value;
      for j := 0 to AnXMLNode.Parent.Items.Count - 1 do
      begin
        if AnXMLNode.Parent.Items[j].Name = 'servs' then
          for k := 0 to AnXMLNode.Parent.Items[j].Items.Count - 1 do
            if AnXMLNode.Parent.Items[j].Items[k] <> nil then
            begin
              if AnXMLNode.Parent.Items[j].Items[k].Properties.ItemNamed
                ['finalized'] <> nil then
                Events[Length(Events) - 1].TrackFinalizedBySvc :=
                  AnXMLNode.Parent.Items[j].Items[k].Properties.ItemNamed
                  ['finalized'].IntValue
              else
              begin
                Events[Length(Events) - 1].TrackFinalizedBySvc := -1;
                break;
              end;
            end;
      end;
    end;
    // ATreeNode := JvTreeView1.Items.AddChild(ATreeNode, S + ' (' + trim(T) + ')');
    for i := 0 to AnXMLNode.Items.Count - 1 do
      ParseIntoEventsArray(AnXMLNode.Items[i], Events);
  end;
end;

procedure TfmMain.TemplateButtonClick(Sender: TObject);
begin
  if FileExists(TplFileName) then
    OpenDialog1.InitialDir := ExtractFileDir(TplFileName)
  else
    OpenDialog1.InitialDir := ProgPath;
  if OpenDialog1.Execute then
    TplEdit.Text := OpenDialog1.FileName;
end;

procedure TfmMain.TestMessageBtnClick(Sender: TObject);
var
  i: integer;
begin
  IdMessage1.Body.Text := STestMessage + #13#10 + Format(SEventsHint,
    [ActiveTracksCount, TracksCount, Length(NotifyEvents), EventsCount,
    UnReadCount]);
  for i := Low(NotifyEvents) to High(NotifyEvents) do
    IdMessage1.Body.Text := IdMessage1.Body.Text +
    { Format(SMessStr, [NotifyEvents[i].GroupsDesc, NotifyEvents[i].TrackDesc,
      NotifyEvents[i].TrackNo, FormatDateTime('dd.mm.yyyy hh:nn:ss',
      NotifyEvents[i].Dt), NotifyEvents[i].EventDesc]) + #13#10; }
      Tpl(SDefaultMailTpl, NotifyEvents[i].GroupsDesc,
      NotifyEvents[i].TrackDesc, NotifyEvents[i].TrackNo,
      FormatDateTime('dd.mm.yyyy hh:nn:ss', NotifyEvents[i].Dt),
      NotifyEvents[i].EventDesc, NotifyEvents[i].EventDescTr) + #13#10;

  IdMessage1.Subject := SMessHeader;
  IdMessage1.Recipients.EMailAddresses := RecieverEmail;
  IdMessage1.Sender.Address := SenderLogin;
  IdMessage1.From.Address := SenderEmail;
  fmMain.SendEmail();
  if UsePushBullet then
    fmMain.SendPushBullet();
end;

procedure TfmMain.AboutBtnClick(Sender: TObject);
begin
  try
    fmAbout := TfmAbout.Create(self);
    if fmMain.Visible then
      fmAbout.Position := poMainFormCenter
    else
      fmAbout.Position := poDesktopCenter;
    fmAbout.Font.Assign(GUIFont);
    fmAbout.Caption := Application.title;
    fmAbout.AppTitleLabel.Font.Size := fmAbout.AppTitleLabel.Font.Size + 2;
    fmAbout.AppTitleLabel.Caption := Application.title;
    fmAbout.DescLabel.Caption := SDescription;
    fmAbout.AutorLabel.Font.Style := fmAbout.AutorLabel.Font.Style +
      [fsUnderLine];
    fmAbout.AutorLabel.Font.Color := clHotLight;
    fmAbout.AutorLabel.Caption := SAutor;
    fmAbout.VersionLabel.Caption := Format(SProgVersion,
      [fmMain.AppVersion(Application.ExeName)]);
    fmAbout.ShowModal;
  finally
    fmAbout.Free;
  end;
end;

procedure TfmMain.Check(Sender: TObject);
var
  i, j, ErrCode, GroupId: integer;
  Str, MailTpl: string;
begin
  { if not FileExists(DataFile) then
    Exit;
    if not FileExists(OptionsFile) then
    Exit; }
  UnReadCount := 0;
  TracksCount := 0;
  ActiveTracksCount := 0;
  EventsCount := 0;
  TrackId := -1;
  // ���������� ��� ����� ��� ����� data.xml
  DataLocalFile := AppDataPath + ExtractFileName(DataFile);
  // ���� ���� ����������, �� ���������� OldDataXML � ��� �� ������ ������
  if FileExists(DataLocalFile) then
  begin
    OldDataXML.LoadFromFile(DataLocalFile);
    // ��������� ������� ����� ��� ������� OldEvents
    SetLength(OldEvents, 0);
    // ��������� ������ OldEvents ������� �� ���������� ������ data.xml
    ParseIntoEventsArray(OldDataXML.Root, OldEvents);
    OldEventsId.Clear;
    for i := Low(OldEvents) to High(OldEvents) do
      if (OldEvents[i].TrackFinalized <> 1) and
        (OldEvents[i].TrackFinalizedBySvc <> 1) then
        OldEventsId.Add(IntToStr(OldEvents[i].EventId));
    OldEventsId.Sort;
    FirstCheck := false;
  end
  else
    FirstCheck := true;
  // ���� ���� ������ ��������, �� ������ ��� ����� � �������� � ���
  if FileExists(DataFile) then
    if not CopyFile(PChar(DataFile), PChar(DataLocalFile), false) then
    begin
      ErrCode := GetLastError();
      if ErrCode <> ERROR_SUCCESS then
        JvLogFile1.Add('', lesError, Format(SFileCopyError,
          [ExtractFileName(DataFile), ErrCode]));
    end;
  // ���� ��������� ���� options.xml ��������� ���
  if FileExists(OptionsFile) then
  begin
    // ��������� OptionsXML
    OptionsXML.LoadFromFile(OptionsFile);
    OptionsInfoLabel.Caption := Format(SFileLoaded, [OptionsFile]);
    OptionsInfoLabel.Update;
    OptionsXmlStatusImage.Picture.Graphic := PngImageCollection1.Items.Items
      [0].PngImage;
    // ��������� �� options.xml ��������� <lastupd> � <achek_period_h>
    if OptionsXML.Root.Items.ItemNamed['add'].Properties.ItemNamed['lastupd'] <> nil
    then
      LastUpd := StrToDateTime(AnsiReplaceStr(OptionsXML.Root.Items.ItemNamed
        ['add'].Properties.ItemNamed['lastupd'].Value, 'T', ' '), Fs);
    LastUpdateLabel.Caption := FormatDateTime(SLastUpd, LastUpd);
    if OptionsXML.Root.Items.ItemNamed['main'].Properties.ItemNamed
      ['acheck_period_h'] <> nil then
      CheckPeriod := OptionsXML.Root.Items.ItemNamed['main']
        .Properties.ItemNamed['acheck_period_h'].IntValue
    else
      CheckPeriod := 3;
    // ��������� ����� ��������� ��������
    CheckTime := System.DateUtils.IncHour(LastUpd, CheckPeriod);
    NextUpdateLabel.Caption := FormatDateTime(SNextUpd, CheckTime);
  end
  else
  begin
    OptionsInfoLabel.Caption := Format(SFileNotLoaded, [OptionsFile]);
    OptionsInfoLabel.Update;
    OptionsXmlStatusImage.Picture.Graphic := PngImageCollection1.Items.Items
      [1].PngImage;
    LastUpdateLabel.Caption := SNever;
    NextUpdateLabel.Caption := SUnknown;
  end;
  // ���� ��������� ���� data.xml ���������� (� �� ��� ��������������� � ������ � ��� ������ ���� data.xml)
  if FileExists(DataLocalFile) then
  begin
    // ��������� NewDataXml
    NewDataXML.LoadFromFile(DataLocalFile);
    DataInfoLabel.Caption := Format(SFileLoaded, [DataLocalFile]);
    DataInfoLabel.Update;
    DataXmlStatusImage.Picture.Graphic := PngImageCollection1.Items.Items
      [0].PngImage;
  end
  else
  begin
    DataInfoLabel.Caption := Format(SFileNotLoaded, [DataLocalFile]);
    DataInfoLabel.Update;
    DataXmlStatusImage.Picture.Graphic := PngImageCollection1.Items.Items
      [1].PngImage;
  end;
  // ��������� ������� ����� ��� ������� NewEvents
  SetLength(NewEvents, 0);
  ParseIntoEventsArray(NewDataXML.Root, NewEvents);
  NewEventsId.Clear;
  NotifyEventsId.Clear;
  SetLength(NotifyEvents, 0);
  // TrackId := NewEvents[0].TrackId;
  // ShowMessage( IntToStr(High(NewEvents)));
  for i := Low(NewEvents) to High(NewEvents) do
  begin
    if (NewEvents[i].TrackFinalized <> 1) and
      (NewEvents[i].TrackFinalizedBySvc <> 1) then
    begin
      NewEventsId.Add(IntToStr(NewEvents[i].EventId));
      if (TrackId <> NewEvents[i].TrackId) then
      begin
        Inc(ActiveTracksCount);
        // ShowMessage(NewEvents[i].TrackDesc);
      end;
    end;
    if TrackId <> NewEvents[i].TrackId then
      Inc(TracksCount);
    if NewEvents[i].NewEvent = 1 then
      Inc(UnReadCount);
    TrackId := NewEvents[i].TrackId;
    Inc(EventsCount);
  end;

  // ShowMessage(IntToStr(ActiveTracksCount));

  NewEventsId.Sort;
  if not NewEventsId.Equals(OldEventsId) then
  begin
    for i := 0 to NewEventsId.Count - 1 do
      if OldEventsId.IndexOf(NewEventsId.Strings[i]) = -1 then
      begin
        NotifyEventsId.Add(NewEventsId.Strings[i]);
      end;
  end;
  SetLength(NotifyEvents, 0);
  for i := Low(NewEvents) to High(NewEvents) do
    if (NotifyEventsId.IndexOf(IntToStr(NewEvents[i].EventId)) <> -1) and
      (NewEvents[i].TrackFinalized <> 1) and
      (NewEvents[i].TrackFinalizedBySvc <> 1) then
    begin
      SetLength(NotifyEvents, Length(NotifyEvents) + 1);
      NotifyEvents[Length(NotifyEvents) - 1].GroupsId := NewEvents[i].GroupsId;
      NotifyEvents[Length(NotifyEvents) - 1].GroupsDesc :=
        NewEvents[i].GroupsDesc;
      NotifyEvents[Length(NotifyEvents) - 1].Groupscrdt :=
        NewEvents[i].Groupscrdt;
      NotifyEvents[Length(NotifyEvents) - 1].TrackId := NewEvents[i].TrackId;
      NotifyEvents[Length(NotifyEvents) - 1].EventId := NewEvents[i].EventId;
      NotifyEvents[Length(NotifyEvents) - 1].TrackNo := NewEvents[i].TrackNo;
      NotifyEvents[Length(NotifyEvents) - 1].TrackDesc :=
        NewEvents[i].TrackDesc;
      NotifyEvents[Length(NotifyEvents) - 1].EventDesc :=
        NewEvents[i].EventDesc;
      NotifyEvents[Length(NotifyEvents) - 1].Servid := NewEvents[i].Servid;
      NotifyEvents[Length(NotifyEvents) - 1].EventDescTr :=
        NewEvents[i].EventDescTr;
      NotifyEvents[Length(NotifyEvents) - 1].NewEvent := NewEvents[i].NewEvent;
      NotifyEvents[Length(NotifyEvents) - 1].Crdt := NewEvents[i].Crdt;
      NotifyEvents[Length(NotifyEvents) - 1].Dt := NewEvents[i].Dt;
      NotifyEvents[Length(NotifyEvents) - 1].Idx := NewEvents[i].Idx;
      NotifyEvents[Length(NotifyEvents) - 1].Auto := NewEvents[i].Auto;
      NotifyEvents[Length(NotifyEvents) - 1].UseDtr := NewEvents[i].UseDtr;
    end;
  // ShowMessage(IntToStr(Length(NotifyEvents)));
  IdMessage1.Body.Text := EmptyStr;
  if CheckTpl(TplText) then
    MailTpl := TplText
  else
    MailTpl := SDefaultMailTpl;
  for i := Low(NotifyEvents) to High(NotifyEvents) do
    IdMessage1.Body.Text := IdMessage1.Body.Text +
    { Format(SMessStr, [NotifyEvents[i].GroupsDesc, NotifyEvents[i].TrackDesc,
      NotifyEvents[i].TrackNo, FormatDateTime('dd.mm.yyyy hh:nn:ss',
      NotifyEvents[i].Dt), NotifyEvents[i].EventDesc]) + #13#10; }
      Tpl(MailTpl, NotifyEvents[i].GroupsDesc, NotifyEvents[i].TrackDesc,
      NotifyEvents[i].TrackNo, FormatDateTime('dd.mm.yyyy hh:nn:ss',
      NotifyEvents[i].Dt), NotifyEvents[i].EventDesc,
      NotifyEvents[i].EventDescTr) + #13#10;
  IdMessage1.Subject := SMessHeader;
  IdMessage1.Recipients.EMailAddresses := RecieverEmail;
  IdMessage1.Sender.Address := SenderLogin;
  IdMessage1.From.Address := SenderEmail;
  if FirstCheck then
  begin
    if (FirstStartNotify) and (Length(NotifyEvents) > 0) then
    begin
      SendEmail();
      if UsePushBullet then
        SendPushBullet();
    end;
  end
  else if Length(NotifyEvents) > 0 then
  begin
    SendEmail();
    if UsePushBullet then
      SendPushBullet();
  end;
  EventsLabel.Caption := Format(SEventsInfo, [ActiveTracksCount, TracksCount,
    Length(NotifyEvents), EventsCount, UnReadCount]);
  CoolTrayIcon1.Hint := Application.title + #13#10 +
    Format(SEventsHint, [ActiveTracksCount, TracksCount, Length(NotifyEvents),
    EventsCount, UnReadCount]);
end;

procedure TfmMain.CoolTrayIcon1Click(Sender: TObject);
begin
  if not fmMain.Visible then
    CoolTrayIcon1.ShowMainForm
  else
    CoolTrayIcon1.HideMainForm;
end;

procedure TfmMain.CoolTrayIcon1Startup(Sender: TObject;
  var ShowMainForm: Boolean);
begin
  ShowMainForm := false;
end;

procedure TfmMain.Timer1Timer(Sender: TObject);
var
  MsecsTime: TTimeStamp;
begin
  if CheckTime - Now > 0 then
  begin
    MsecsTime := DateTimeToTimeStamp(CheckTime - Now);
    if CheckPeriod > 0 then
      ProgressBar1.Position :=
        trunc(MsecsTime.Time / (CheckPeriod * 60 * 60 * 10));
    ProgressBar1.Caption := '�� ��������� �������� �������� ' +
      FormatDateTime('hh:mm:ss', Now - CheckTime);
  end;
  if not FileExists(OptionsFile) then
  begin
    ProgressBar1.Position := 0;
    ProgressBar1.Caption := Format(SOptionsFileNotLoaded, [OptionsFile]);
    exit;
  end;
  if (CheckTime < Now) or (FileDate < GetFileDate(OptionsFile)) then
  begin
    Check(Sender);
    if FileExists(OptionsFile) then
      FileDate := GetFileDate(OptionsFile);
  end;
end;

procedure TfmMain.UsePushBulletCheck(Sender: TObject);
begin
  PushBulletApiEdit.Enabled := UsePushBulletCheckBox.Checked;
  PushBulletDevIdEdit.Enabled := UsePushBulletCheckBox.Checked;
end;

procedure TfmMain.UsePushBulletCheckBoxClick(Sender: TObject);
begin
  UsePushBulletCheck(Sender);
end;

end.
