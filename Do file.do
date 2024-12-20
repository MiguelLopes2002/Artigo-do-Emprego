* Script para Analisar Fatores que Influenciam a Permanência no Emprego usando Modelos Logit/Probit

* Limpar a memória de trabalho para evitar conflitos com dados ou configurações antigas
clear all
set more off

* Definir o diretório de trabalho onde estão os arquivos necessários
cd "C:/Users/Miguel/Desktop/Trabalho do Tillmãe/"

* Importar a base de dados da RAIS, mantendo apenas as variáveis necessárias
import delimited "RAIS_VINC_PUB_SUL.txt", delimiter(";") varnames(1) clear
keep idade escolaridadeapós2005 raçacor sexotrabalhador vlremunmédianom tipovínculo faixahoracontrat indtrabintermitente tamanhoestabelecimento cnae20classe indsimples tempoemprego

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

* Verificar se as conversões de 'vlremunmédianom_clean' e 'tempoemprego_clean' foram bem-sucedidas
sum vlremunmédianom_clean tempoemprego_clean

* Criar a variável dependente binária 'permanencia' para indicar se o trabalhador permaneceu no emprego por mais de 2 anos
gen permanencia = 0
replace permanencia = 1 if tempoemprego_clean > 24

* Criar faixas etárias (arredondadas a cada 5 anos) para análise de efeitos marginais
gen idade_grupo = round(idade/5)*5

* Criar faixas de remuneração para facilitar a análise
gen vlremun_faixa = ceil(vlremunmédianom_clean / 500)

* Analisar estatísticas descritivas das variáveis principais
sum idade escolaridadeapós2005 raçacor sexotrabalhador vlremunmédianom_clean tipovínculo faixahoracontrat indtrabintermitente tamanhoestabelecimento cnae20classe indsimples

* Tabular a variável dependente 'permanencia' para verificar sua distribuição
tab permanencia

* Estimar o modelo Logit para analisar os fatores que influenciam a permanência no emprego
logit permanencia idade_grupo escolaridadeapós2005 raçacor sexotrabalhador vlremunmédianom_clean tipovínculo faixahoracontrat indtrabintermitente tamanhoestabelecimento cnae20classe indsimples vlremun_faixa

* Exibir os Odds Ratios do modelo Logit para melhor interpretação dos coeficientes
logit, or

* Estimar o modelo Probit para comparação com o Logit
probit permanencia idade_grupo escolaridadeapós2005 raçacor sexotrabalhador vlremunmédianom_clean tipovínculo faixahoracontrat indtrabintermitente tamanhoestabelecimento cnae20classe indsimples vlremun_faixa

* Gerar gráficos de probabilidade predita para variáveis de interesse
* Probabilidade de permanência por faixa etária
margins, at(idade_grupo=(20(5)60)) predict(pr)
marginsplot, title("Probabilidade Predita de Permanência no Emprego por Idade")

* Probabilidade de permanência por nível de escolaridade
margins, at(escolaridadeapós2005=(1(1)11)) predict(pr)
marginsplot, title("Probabilidade Predita de Permanência no Emprego por Escolaridade")

* Probabilidade de permanência por sexo
margins, at(sexotrabalhador=(1 2)) predict(pr)
marginsplot, title("Probabilidade Predita de Permanência no Emprego por Sexo")

* Probabilidade de permanência por faixa de remuneração
margins, at(vlremun_faixa=(1(1)10)) predict(pr)
marginsplot, title("Probabilidade Predita de Permanência no Emprego por Faixa de Remuneração")

* Analisar interações entre idade e escolaridade para efeitos marginais
logit permanencia c.idade##c.escolaridadeapós2005 vlremunmédianom_clean tipovínculo faixahoracontrat indtrabintermitente tamanhoestabelecimento cnae20classe indsimples vlremun_faixa

* Estimar os modelos com robustez (variância robusta) para maior confiabilidade dos resultados
logit permanencia idade_grupo escolaridadeapós2005 raçacor sexotrabalhador vlremunmédianom_clean tipovínculo faixahoracontrat indtrabintermitente tamanhoestabelecimento cnae20classe indsimples vlremun_faixa, vce(robust)
probit permanencia idade_grupo escolaridadeapós2005 raçacor sexotrabalhador vlremunmédianom_clean tipovínculo faixahoracontrat indtrabintermitente tamanhoestabelecimento cnae20classe indsimples vlremun_faixa, vce(robust)

* Salvar os resultados em um arquivo de log para referência futura
log using "analise_permanencia_emprego.log", replace

* Fechar o arquivo de log
log close
