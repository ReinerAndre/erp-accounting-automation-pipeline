# Guia de Usuário: Automação de Parâmetros Contábeis

## Visão Geral
Este script automatiza a vinculação de contas contábeis para novos clientes inseridos no ERP. Ele foi desenhado para rodar silenciosamente em *background*, garantindo que a parametrização fiscal exista antes que o primeiro pedido de vendas seja faturado.

## Como Implementar (Deploy)
1. **Agendamento (Job):** A recomendação de arquitetura é encapsular este bloco anônimo em uma `PROCEDURE` e inseri-la no *Task Scheduler* do próprio ERP (ou via `DBMS_SCHEDULER` do Oracle).
2. **Frequência Sugerida:** Agendar a execução a cada 15 ou 30 minutos em horário comercial para simular um comportamento "quase tempo-real" (near real-time) sem sobrecarregar o banco de dados.

## Manutenção de Regras
* **Novas Filiais:** Se a empresa abrir as filiais 8 ou 9, basta adicionar esses IDs na linha `WHERE company_id IN (5,6,7)` do script. O *Pivot* irá absorver as contas automaticamente.
* **Novos Perfis de Clientes:** Atualmente a lógica atende 'E' (Estrangeiro) e 'J' (Nacional/Jurídico). Caso novos tipos sejam criados pelo comercial, eles devem ser adicionados na estrutura de `IF/ELSIF` contida no *loop* principal.

## Monitoramento (Troubleshooting)
A validação de "conta já vinculada" (`v_exists`) impede erros de inserção duplicada. Se um cliente não estiver recebendo a conta contábil:
1. Verifique se o cadastro comercial possui `registration_date` válido e preenchido.
2. Certifique-se de que a carteira (`portfolio_id`) corresponde ao código mapeado na integração (ex: 10591).
3. Confira se as contas `NATIONAL_CLIENT` e `INTERNATIONAL_CLIENT` estão corretamente configuradas e ativas na tabela `accounting_parameters` para a filial em questão.
