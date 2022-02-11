#include 'totvs.ch'

/*
https://interno.totvs.com/mktfiles/tdiportais/helponlineprotheus/p12/portuguese/sigaworkflow.htm
https://tdn.totvs.com/display/PROT/WFPE007
https://centraldeatendimento.totvs.com/hc/pt-br/articles/360016596851-Cross-Segmento-Backoffice-Linha-Protheus-SIGAFIN-FINA580-Como-utilizar-a-rotina-libera%C3%A7%C3%A3o-para-baixa-#:~:text=A%20libera%C3%A7%C3%A3o%20de%20pagamentos%20pode,valores%20e%20tipos%20de%20t%C3%ADtulos.
https://centraldeatendimento.totvs.com/hc/pt-br/articles/360018466992-MP-SIGAFIN-Desbloqueio-dos-campos-Tipo-Natureza-ED-TIPO-e-Codigo-Pai-ED-PAI-no-Cadastro-de-Naturezas
https://tdn.totvs.com/pages/viewpage.action?pageId=312165041
https://tdn.totvs.com/display/PROT/FIN0072_CPAG_MV_CTLIPAG_MV_CANLIPG_MV_ALTLIPG_FINA580
https://centraldeatendimento.totvs.com/hc/pt-br/articles/360024732031-Cross-Segmento-BackOffice-Linha-Protheus-Como-parametrizar-os-cadastros-para-que-os-t%C3%ADtulos-a-pagar-necessite-de-aprova%C3%A7%C3%A3o
https://centraldeatendimento.totvs.com/hc/pt-br/articles/360016596851-Cross-Segmento-Backoffice-Linha-Protheus-SIGAFIN-FINA580-Como-utilizar-a-rotina-libera%C3%A7%C3%A3o-para-baixa-
https://centraldeatendimento.totvs.com/hc/pt-br/articles/360006469332-MP-SIGACOM-Pontos-de-entrada-do-Documento-de-Entrada-MATA103
https://tdn.totvs.com/pages/viewpage.action?pageId=6085406
https://tdn.totvs.com/pages/releaseview.action?pageId=6085400
https://siga0984.wordpress.com/2018/11/11/o-protheus-como-servidor-http-parte-01/
*/

user function wf()

   //CoNoUT(LEN('                         '))

   cTeste := PadR('123',25)

   ConOut( MD5( cTeste, 1 ) )
   ConOut( MD5( cTeste, 2 ) )

return
