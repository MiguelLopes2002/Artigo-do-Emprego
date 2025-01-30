* Script para Analisar Fatores que Influenciam a Permanência no Emprego usando Modelos Logit/Probit

* Limpar memória de trabalho
clear all
set more off

* Definir diretório de trabalho
cd "C:/Users/Miguel/Desktop/Trabalho do Tillmann/"

* Importar a base de dados da RAIS, mantendo apenas as variáveis necessárias
import delimited "RAIS_VINC_PUB_SUL_2022.txt", delimiter(";") varnames(1) clear
keep idade escolaridadeapós2005 raçacor sexotrabalhador vlremunmédianom tipovínculo faixahoracontrat indtrabintermitente tamanhoestabelecimento cnae20classe indsimples tempoemprego cboocupação2002

* Substituir valores inválidos (99) por um valor apropriado (9 - Não Identificado)
replace raçacor = 9 if raçacor == 99
* Verificar a distribuição após a correção
tabulate raçacor

* Limpeza e conversão da variável 'vlremunmédianom'
* Criar uma nova variável 'vlremunmédianom_clean' para preservar o valor original
clonevar vlremunmédianom_clean = vlremunmédianom
* Substituir vírgulas por pontos, para padronização de separadores decimais
replace vlremunmédianom_clean = subinstr(vlremunmédianom_clean, ",", ".", .)
* Remover zeros à esquerda, que podem causar problemas de conversão
replace vlremunmédianom_clean = regexr(vlremunmédianom_clean, "^0+", "")
* Converter a variável de string para numérica, forçando a conversão
destring vlremunmédianom_clean, replace force

* Limpeza e conversão da variável 'tempoemprego'
* Criar uma cópia 'tempoemprego_clean' para preservar o original
clonevar tempoemprego_clean = tempoemprego
* Substituir vírgulas por pontos
replace tempoemprego_clean = subinstr(tempoemprego_clean, ",", ".", .)
* Converter a variável de string para numérica
destring tempoemprego_clean, replace force

* Verificar se as conversões foram bem-sucedidas
summarize vlremunmédianom_clean tempoemprego_clean

* Criar a variável dependente binária 'permanencia' para indicar se o trabalhador permaneceu no emprego por mais de 2 anos
gen permanencia = 0
replace permanencia = 1 if tempoemprego_clean > 24

* Criar faixas etárias (arredondadas a cada 5 anos) para análise de efeitos marginais
* A multiplicação por 5 permite que as variáveis fiquem de 5 em 5 anos
gen idade_grupo = round(idade/5)*5

* Criar faixas de remuneração para facilitar a análise
gen vlremun_faixa = ceil(vlremunmédianom_clean / 500)

* Calcular a frequência de cada valor de cnae20classe
tabulate cnae20classe, sort
* Iniciar o log para salvar a saída, já que não tem como ver o tabulate completo no Stata
log using "frequencia_cbo.txt", text replace
* Executar o comando
tabulate cboocupação2002, sort
* Fechar o log
log close

* Definir variáveis dependente e independentes como globais
global ylist permanencia
global xlist idade_grupo escolaridadeapós2005 raçacor sexotrabalhador indtrabintermitente tamanhoestabelecimento vlremun_faixa

* Estatísticas descritivas
describe $ylist $xlist
summarize $ylist $xlist
tabulate $ylist

* Regressão linear como comparação inicial
reg $ylist $xlist

* Modelos Logit e Probit
logit $ylist $xlist
probit $ylist $xlist

* Marginal effects (margens ao redor da média e médias marginais)
quietly logit $ylist $xlist
margins, dydx(*) atmeans
margins, dydx(*)

quietly probit $ylist $xlist
margins, dydx(*) atmeans
margins, dydx(*)

* Exibir odds ratios usando modelo logístico
logistic $ylist $xlist

* Predição de probabilidades
quietly logit $ylist $xlist
predict plogit, pr

quietly probit $ylist $xlist
predict pprobit, pr

quietly reg $ylist $xlist
predict pols, xb

summarize $ylist plogit pprobit pols

* Classificação percentual correta
quietly logit $ylist $xlist
estat classification

quietly probit $ylist $xlist
estat classification

* Análise gráfica de efeitos marginais
* Probabilidade por faixa etária
margins, at(idade_grupo=(20(5)60)) predict(pr)
marginsplot, title("Probabilidade Predita de Permanência no Emprego por Idade")

* Probabilidade por faixa de remuneração
margins, at(vlremun_faixa=(1(1)10)) predict(pr)
marginsplot, title("Probabilidade Predita de Permanência no Emprego por Faixa de Remuneração")

* Modelo com interação para análise adicional
logit $ylist c.idade##c.escolaridadeapós2005 $xlist

* Estimar modelos com robustez
logit $ylist $xlist, vce(robust)
probit $ylist $xlist, vce(robust)

* Salvar os resultados em log
log using "analise_permanencia_emprego.log", replace
log close
