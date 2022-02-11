#include 'totvs.ch'

user function MT100TOK()

	Local oBtnOk   := nil
	Local oBtnCanc := nil
	Local oGet     := nil
	Local cGet     := Space( GetSX3Cache( 'CTT_CUSTO', 'X3_TAMANHO' ) )
	Local oSay     := nil
	Local oDlg     := nil
	Local lRet     := .F.

	Public cCCAprv  := ''
	Public cCodApro := ''

	if GeraSe2()

		DEFINE MSDIALOG oDlg TITLE "Centro de Custo de Aprovação" FROM 000, 000  TO 125, 210 PIXEL

		@ 007, 007 SAY oSay PROMPT "Centro de Custo de Aprovação" SIZE 075, 007 OF oDlg COLORS 0, 16777215 PIXEL
		@ 022, 007 MSGET oGet VAR cGet SIZE 075, 010 OF oDlg VALID {|| Empty(cGet) .Or. VldCTT( cGet, @cCodApro ) } F3 "CTT" HASBUTTON PIXEL
		@ 035, 007 BUTTON oBtnOk PROMPT "Ok" SIZE 037, 012 OF oDlg ACTION { || oDlg:End(), lRet := .T. } WHEN {||!Empty( cGet )} PIXEL
		@ 035, 047 BUTTON oBtnCanc PROMPT "Cancelar" SIZE 037, 012 OF oDlg ACTION { || oDlg:End(), lRet := .F. } WHEN { || .T. } PIXEL

		ACTIVATE MSDIALOG oDlg CENTERED

		cCCAprv := cGet

	else

		lRet := .T.

	end if

return lRet

static function GeraSe2()

	local nX    := 1
	local lRet  := .F.
	local cTes  := ''
	local aArea := GetArea()

	for nX := 1 to Len( aCols )

		if ! aTail( aCols[nX] )

			cTes := GdFieldGet( 'D1_TES', nX, , aHeader, aCols )

			if posicione( 'SF4', 1, Xfilial('SF4') + cTes, 'F4_DUPLIC' ) == 'S'

				lRet  := .T.

				Exit

			end if

		end if

	next nX

	Restarea( aArea )

return lRet

static function VldCTT( cCC, cAprov )

	local cMoeda := strZero( nMoedaCor, 2 )
	local cUser  := ''
	local aArea  := GetArea()
	local lRet   := .F.

	DbSelectArea('CTT')
	CTT->( DbSetOrder( 1 ) )

	if DbSeek( XFILIAL('CTT') + cCC )

		cUser := CTT->CTT_XUSAPR

		if ! Empty( cUser )

			DbSelectArea('FRP')
			FRP->( DbSetOrder( 2 ) )

			if DbSeek( XFILIAL("FRP") + cUser + cMoeda )

				cAprov := FRP->FRP_COD

				lRet   := .T.

			else

				ApMsgAlert( 'O Usuário aprovador deste Centro de Custo não tem autorização de liberar para a moeda ' + cMoeda )

			end if

		else

			ApMsgAlert( 'Este Centro de Custo não tem usuário aprovador vinculado' )

		end if

	else

		ApMsgAlert( 'Informe um Centro de Custo válido.' )

	end if

	RestArea( aArea )

return lRet
