unit FormUnit1;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Edit, IdHTTPWebBrokerBridge,
  IdHTTP,System.JSON,
  Vcl.ExtDlgs,
  Web.HTTPApp, FMX.Controls.Presentation, UWrp.Line.Notify, FMX.ScrollBox, FMX.Memo,
  FMX.TabControl, IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, UWrpAPI_Common, FMX.ListBox;

type
  TForm1 = class(TForm)
    ButtonStart: TButton;
    ButtonStop: TButton;
    EditPort: TEdit;
    Label1: TLabel;
    ButtonOpenBrowser: TButton;
    WrpLineNotify1: TWrpLineNotify;
    Label2: TLabel;
    edText: TMemo;
    edImage_Thumb: TEdit;
    edImage_Full: TEdit;
    edSticker_PackageID: TEdit;
    edSticker_ID: TEdit;
    edImage_File1: TEdit;
    edToken: TEdit;
    btnImageBrowse1: TButton;
    btnGetAuthrize: TButton;
    btnCPN_SendRevoke: TButton;
    btnGetStatus: TButton;
    btnNotify_Files: TButton;
    edImage_File2: TEdit;
    edImage_File3: TEdit;
    btnImageBrowse3: TButton;
    cbbAuto_GetLimitStatus: TCheckBox;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Label10: TLabel;
    Button2: TButton;
    TabControl1: TTabControl;
    TabItem1: TTabItem;
    TabItem2: TTabItem;
    edRedirect_URI: TEdit;
    edClient_Secret: TEdit;
    edClient_ID: TEdit;
    Label11: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    mmResponse: TMemo;
    edState: TEdit;
    edNewToken: TEdit;
    Label14: TLabel;
    Label15: TLabel;
    btnNotify2: TButton;
    btnNotify3: TButton;
    btnNotify1: TButton;
    Timer1: TTimer;
    btnNotifyAll: TButton;
    procedure FormCreate(Sender: TObject);
    procedure ButtonStartClick(Sender: TObject);
    procedure ButtonStopClick(Sender: TObject);
    procedure ButtonOpenBrowserClick(Sender: TObject);
    procedure btnGetStatusClick(Sender: TObject);
    procedure btnCPN_SendRevokeClick(Sender: TObject);
    procedure btnGetAuthrizeClick(Sender: TObject);
    procedure WrpLineNotify1APIResponse(Response: TIdHTTPResponse; ResponseText, ReponseRawHeaderText: string);
    procedure WrpLineNotify1AfterSendAPI(Response: TIdHTTPResponse; ResponseText, ReponseRawHeaderText: string);
    procedure Button2Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnImageBrowse1Click(Sender: TObject);
    procedure btnImageBrowse2Click(Sender: TObject);
    procedure btnImageBrowse3Click(Sender: TObject);
    procedure btnNotify2Click(Sender: TObject);
    procedure btnNotify3Click(Sender: TObject);
    procedure edTokenExit(Sender: TObject);
    procedure btnNotify1Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure btnNotifyAllClick(Sender: TObject);
    procedure btnNotify_FilesClick(Sender: TObject);
  private
    FServer: TIdHTTPWebBrokerBridge;
    procedure StartServer;
    procedure ApplicationIdle(Sender: TObject; var Done: Boolean);
    function SelectImageFile: String;
    { Private declarations }
  public
    { Public declarations }
    procedure DoOnLineSendResponse(Content: String);
  end;

var
  Form1: TForm1;

implementation

{$R *.fmx}

uses
  WinApi.Windows, Winapi.ShellApi, Datasnap.DSSession , IdURI;

procedure TForm1.DoOnLineSendResponse(Content : String);
var sAccess_Token : String;
begin
    mmResponse.Lines.Add('Line :: > '+FormatDateTime('DD/MM/YYYY HH:NN:SS',NOW));
    mmResponse.Lines.Add('Line :: > '+Content);

    // Compnent check content have word "code=XXXXX & state = ZZZZZ" (state as you Assigned)
    sAccess_Token := WrpLineNotify1.Get_AuthenCodeAndPostBack_ForAccessToken(Content);
    if sAccess_Token <> '' then
       begin
          edNewToken.Text := sAccess_Token;
          mmResponse.Lines.Add('Line :: > Accesss_Token : '+sAccess_Token);
       end;
end;

procedure TForm1.edTokenExit(Sender: TObject);
begin
   WrpLineNotify1.Token  := edToken.Text;
end;

procedure TForm1.ApplicationIdle(Sender: TObject; var Done: Boolean);
begin
  ButtonStart.Enabled := not FServer.Active;
  ButtonStop.Enabled := FServer.Active;
  EditPort.Enabled := not FServer.Active;
end;

procedure TForm1.btnCPN_SendRevokeClick(Sender: TObject);
begin
    if MessageDlg('Token นี้จะใช้งานไม่ได้อีก ตลอดไป'+#13#10+
        'ถ้าต้องการใช้งาน ต้องไปสร้าง Token ใหม่ถึงจะใช้งานได้'+#13#10+
       'ยืนยันการยกเลิก Token ??',
        TMsgDlgType.mtConfirmation,[TMsgDlgBtn.mbYes,TMsgDlgBtn.mbNo],0) = mrYES then
        begin
            WrpLineNotify1.Token       := edToken.Text;
            WrpLineNotify1.DoRevoke_Token;
            edToken.Text := 'Token ถูกยกเลิก';
        end;
end;

procedure TForm1.btnGetAuthrizeClick(Sender: TObject);
begin
    mmResponse.Lines.Clear;
    WrpLineNotify1.OAuth.Client_ID     := edClient_id.Text;
    WrpLineNotify1.OAuth.Client_Secret := edClient_Secret.Text;
    WrpLineNotify1.OAuth.Redirect_URI  := edRedirect_URI.text;

    // Field for Separate user who ,Get Token
    // เป็นฟิลด์ที่เอาไว้สำหรับบอกผู้ใช้ว่า ไอดีนี้เป็นใคร
    // โปรแกรมเมอร์เอาไปใส่ในฐานข้อมูล แยก LINE USER

    WrpLineNotify1.OAuth.State := edState.Text;

    if edState.Text = '' then
       WrpLineNotify1.OAuth.State := 'PROJECT1@'+FormatDateTime('YYYYMMDDHHNNSS',NOW);

    WrpLineNotify1.Get_Authorize;
end;

function TForm1.SelectImageFile : String;
var  OpenPict : TOpenPictureDialog;   // Vcl.ExtDlgs
begin
    {$IFDEF MSWINDOWS}
    OpenPict := TOpenPictureDialog.Create(NIL);
    if OpenPict.Execute() then
       begin
          Result :=  OpenPict.FileName;
       end;
    FreeAndNil(OpenPict);
    {$ELSE}
        //sOpenImage
    {$ENDIF}
end;

procedure TForm1.btnImageBrowse1Click(Sender: TObject);
begin
    edImage_File1.Text := SelectImageFile();
end;

procedure TForm1.btnImageBrowse2Click(Sender: TObject);
begin
    edImage_File2.Text := SelectImageFile();
end;

procedure TForm1.btnImageBrowse3Click(Sender: TObject);
begin
    edImage_File3.Text := SelectImageFile();
end;

procedure TForm1.btnNotify1Click(Sender: TObject);
begin
    // Notify( Message )
   WrpLineNotify1.Notify(edText.Text);
end;

procedure TForm1.btnNotify2Click(Sender: TObject);
begin
    // Notify( Message , StickerPackageID , StickerID )
   WrpLineNotify1.Notify(edText.Text,
                    StrToInt(edSticker_PackageID.Text),
                    StrToInt(edSticker_ID.Text));
end;

procedure TForm1.btnNotify3Click(Sender: TObject);
begin
    // Notify( Message , FileUrl_Thumb , FileUrl_Full )
   WrpLineNotify1.Notify(edText.Text,
                    edImage_Thumb.Text,
                    edImage_Full.Text);
end;

procedure TForm1.btnNotifyAllClick(Sender: TObject);
begin
   // All in one //

   // Clear Data
   WrpLineNotify1.Init();

   // 1. Message
   WrpLineNotify1.Params.Message    := edText.Text;

   // 2. Image from URL (HTTP/HTTPS)
   if (edImage_Thumb.Text <> '') and (edImage_Full.Text <> '') then
       begin
          WrpLineNotify1.Params.ImageURLThumbnil := edImage_Thumb.Text;
          WrpLineNotify1.Params.ImageURLFullSize := edImage_Full.Text;
       end;

   // 3. Image Files (Local Files)
   if (edImage_File1.Text <> '') or
      (edImage_File2.Text <> '') or
      (edImage_File3.Text <> '') then
      begin

         if (edImage_File1.Text <> '') then
             WrpLineNotify1.Params.ImageFileNames.Add(edImage_File1.Text);

         if (edImage_File2.Text <> '') then
             WrpLineNotify1.Params.ImageFileNames.Add(edImage_File2.Text);

         if (edImage_File3.Text <> '') then
             WrpLineNotify1.Params.ImageFileNames.Add(edImage_File3.Text);
      end;

   // 4. Sticker
   if (edSticker_PackageID.Text <> '' ) and (edSticker_ID.Text <> '') then
       begin
          WrpLineNotify1.Params.StickerPackageID := StrToInt(edSticker_PackageID.Text);
          WrpLineNotify1.Params.StickerID        := StrToInt(edSticker_ID.Text);
       end;

   WrpLineNotify1.Notify();
end;

procedure TForm1.btnNotify_FilesClick(Sender: TObject);
begin
   // Clear Data
   WrpLineNotify1.Init();

   // 1. Message
   WrpLineNotify1.Params.Message    := edText.Text;


   if (edImage_File1.Text <> '') or
      (edImage_File2.Text <> '') or
      (edImage_File3.Text <> '') then
      begin

         if (edImage_File1.Text <> '') then
             WrpLineNotify1.Params.ImageFileNames.Add(edImage_File1.Text);

         if (edImage_File2.Text <> '') then
             WrpLineNotify1.Params.ImageFileNames.Add(edImage_File2.Text);

         if (edImage_File3.Text <> '') then
             WrpLineNotify1.Params.ImageFileNames.Add(edImage_File3.Text);
      end;

   WrpLineNotify1.Notify();
end;

procedure TForm1.btnGetStatusClick(Sender: TObject);
begin
    WrpLineNotify1.DoGetAccess_Status;
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
    //
    ShellExecute(0,'open','https://notify-bot.line.me/th/',NIL,NIL,SW_SHOWNORMAL);
end;

procedure TForm1.ButtonOpenBrowserClick(Sender: TObject);
var
  LURL: string;
begin
  StartServer;
  LURL := Format('http://localhost:%s', [EditPort.Text]);
  ShellExecute(0,
        nil,
        PChar(LURL), nil, nil, SW_SHOWNOACTIVATE);
end;

procedure TForm1.ButtonStartClick(Sender: TObject);
begin
  StartServer;
end;

procedure TerminateThreads;
begin
  if TDSSessionManager.Instance <> nil then
    TDSSessionManager.Instance.TerminateAllSessions;
end;

procedure TForm1.ButtonStopClick(Sender: TObject);
begin
  TerminateThreads;
  FServer.Active := False;
  FServer.Bindings.Clear;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  FServer := TIdHTTPWebBrokerBridge.Create(Self);
  Application.OnIdle := ApplicationIdle;
end;

procedure TForm1.FormShow(Sender: TObject);
begin
   WrpLineNotify1.Token  := edToken.Text;
   StartServer;
end;

procedure TForm1.StartServer;
begin
  if not FServer.Active then
  begin
    FServer.Bindings.Clear;
    FServer.DefaultPort := StrToInt(EditPort.Text);
    FServer.Active := True;
  end;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
    Caption := 'Line Notify (Server) FMX :: Warapetch  Ruangpornvisuthi   '+formatDateTime('DD/MM/YYYY HH:NN:SS',NOW);
end;

procedure TForm1.WrpLineNotify1AfterSendAPI(Response: TIdHTTPResponse; ResponseText, ReponseRawHeaderText: string);
begin
  mmResponse.Lines.Add('-- After Send API -- ');
end;

procedure TForm1.WrpLineNotify1APIResponse(Response: TIdHTTPResponse; ResponseText, ReponseRawHeaderText: string);
begin
  mmResponse.Lines.Add('');
  mmResponse.Lines.Add('Response :: > '+FormatDateTime('DD/MM/YYYY HH:NN:SS',NOW));
  mmResponse.Lines.Add(ResponseText);

  if ReponseRawHeaderText = 'RateLimit' then
     mmResponse.Lines.Add(
            WrpLineNotify1.Status.Info
            )
  else
     mmResponse.Lines.Add(ReponseRawHeaderText);
end;

end.
