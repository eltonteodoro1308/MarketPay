#include 'totvs.ch'

/*/{Protheus.doc} X7Aprov
Fun��o a ser utilizada no gatilho dos campos E2_MOEDA e E2_XCCAPRV, com a finalidade de buscar no cantro de custo 
aprovador do campo E2_XCCAPRV o c�digo do usu�rio aprovador do campo CTT_XUSAPR e com este buscar no cadastro de 
Gestores Financeiros (FINA003) c�digo do aprovador correspondente a moeda do t�tulo.
@type function
@version  12.1.33
@author elton.alves@totvs.com.br
@since 08/02/2022
@return character, C�digo do Aprovador
/*/
user function X7Aprov()

	local cUser  := ''
	local cAprov := ''
	local aArea  := GetArea()

	DbSelectArea('CTT')
	CTT->( DbSetOrder( 1 ) )

	if DbSeek( XFILIAL('CTT')+M->E2_XCCAPRV )

		cUser := CTT->CTT_XUSAPR

		DbSelectArea('FRP')
		FRP->( DbSetOrder( 2 ) )

		if DbSeek( XFILIAL("FRP") + cUser + STRZERO( M->E2_MOEDA, 2 ) )

			cAprov := FRP->FRP_COD

		end if

	end if

	RestArea( aArea )

return cAprov
