unit Unit5;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Dominio, Vcl.StdCtrls, Vcl.OleCtrls,
  SHDocVw;

type
  TForm5 = class(TForm)
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Button1: TButton;
    Button2: TButton;
    edToken: TEdit;
    Button3: TButton;
    edUsername: TEdit;
    edPassword: TEdit;
    cbAmbiente: TComboBox;
    Button4: TButton;
    Memo1: TMemo;
    DTDominio1: TDTDominio;
    Label9: TLabel;
    OpenDialog1: TOpenDialog;
    Button5: TButton;
    procedure Button2Click(Sender: TObject);
    procedure WebBrowser1NavigateComplete2(ASender: TObject;
      const pDisp: IDispatch; const URL: OleVariant);
    procedure Button1Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
  private
    procedure CarregaInformacoes;
  public
    { Public declarations }
  end;

var
  Form5: TForm5;

implementation

{$R *.dfm}

procedure TForm5.Button1Click(Sender: TObject);
begin
      CarregaInformacoes;
      edToken.Text := DTDominio1.AccessToken;

end;

procedure TForm5.Button2Click(Sender: TObject);
begin
      CarregaInformacoes;
      DTDominio1.Login;

end;

procedure TForm5.Button3Click(Sender: TObject);
var
Msg : String;
begin
  CarregaInformacoes;
  if OpenDialog1.Execute then
  begin
      DTDominio1.EnviaXML(OpenDialog1.FileName, Msg);
      if DTDominio1.Retorno.Codigo = 201 then
      begin
          Memo1.Lines.Add('Sucesso:' + IntToStr( DTDominio1.Retorno.Codigo ) + ' - ' + DTDominio1.Retorno.Mensagem);
          Memo1.Lines.Add('Id: ' + DTDominio1.Retorno.id);
      end else begin
          Memo1.Lines.Add('Erro:' +IntToStr( DTDominio1.Retorno.Codigo ) + ' - ' + DTDominio1.Retorno.Mensagem);
      end;
  end;
end;

procedure TForm5.Button4Click(Sender: TObject);
var
msg:string;
Resposta:string;
begin
    CarregaInformacoes;
    Resposta := InputBox('informe o id de envio', 'Informe o id: ' ,'');

    DTDominio1.StatusFile(resposta);
    Memo1.Lines.Add( DTDominio1.Retorno.status );
    Memo1.Lines.Add( IntToStr( DTDominio1.Retorno.Codigo ) );
    Memo1.Lines.Add( DTDominio1.Retorno.Mensagem );
end;

procedure TForm5.Button5Click(Sender: TObject);
begin
      CarregaInformacoes;
      DTDominio1.GetKeyIntegracao;

      Memo1.Lines.Clear;
      Memo1.Lines.Add(DTDominio1.Retorno.Mensagem);
end;

procedure TForm5.CarregaInformacoes;
begin
      DTDominio1.ClientID            := edUsername.Text;
      DTDominio1.ClientSecret        := edPassword.Text;
      DTDominio1.Ambiente            := TAmbiente(cbAmbiente.ItemIndex);
      DTDominio1.audience            := '7';
      DTDominio1.CaminhoArquivoToken := 'C:\TEMP\';
      DTDominio1.gravarlog           := True;
      DTDominio1.caminhoArqLog       := 'c:\temp\log.txt';
      DTDominio1.keycontabilidade    := '';
      DTDominio1.GetToken;

      edToken.Text                   := DTDominio1.AccessToken;
end;

procedure TForm5.WebBrowser1NavigateComplete2(ASender: TObject;
  const pDisp: IDispatch; const URL: OleVariant);
begin
      // ShowMessage(url);
end;

end.
