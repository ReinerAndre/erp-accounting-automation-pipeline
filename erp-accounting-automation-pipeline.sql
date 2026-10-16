DECLARE
    v_exists NUMBER;
BEGIN
    -- 1. Identifica novos clientes cadastrados pelo time Comercial
    -- Filtra registros recentes e de carteiras específicas que demandam integração
    FOR r_customer IN (
        SELECT c.customer_id, 
               c.person_type -- 'E' para Estrangeiro, 'J' para Nacional/Jurídica
          FROM erp_schema.dim_customers c
         INNER JOIN erp_schema.dim_customer_types t
            ON t.customer_id = c.customer_id
           AND t.type_code = 'CLIENT' 
         WHERE c.registration_date > sysdate - 7
           AND t.portfolio_id = 10591
    )
    LOOP   
        -- 2. Recupera a parametrização dinâmica de contas contábeis
        -- Utiliza agregação condicional (PIVOT) para buscar as contas ativas das filiais 5, 6 e 7
        FOR r_account IN (
            SELECT company_id,
                   MAX(CASE WHEN purpose = 'NATIONAL_CLIENT' THEN accounting_account_id ELSE NULL END) AS account_nac,
                   MAX(CASE WHEN purpose = 'INTERNATIONAL_CLIENT' THEN accounting_account_id ELSE NULL END) AS account_ext
              FROM erp_schema.accounting_parameters 
             WHERE company_id IN (5,6,7) 
               AND purpose IN ('NATIONAL_CLIENT', 'INTERNATIONAL_CLIENT')
             GROUP BY company_id
        )
        LOOP
            -- 3. Validação de Idempotência: Garante que a conta não seja duplicada 
            -- para o Cliente na Filial específica
            SELECT COUNT(*)
              INTO v_exists
              FROM erp_schema.customer_accounting_accounts 
             WHERE customer_id = r_customer.customer_id
               AND company_id = r_account.company_id;
            
            -- 4. Inserção automatizada eliminando a intervenção manual do time Fiscal
            IF v_exists = 0 THEN
                IF r_customer.person_type = 'E' THEN 
                    INSERT INTO erp_schema.customer_accounting_accounts 
                        (company_id, customer_id, accounting_account_id, check_account) 
                    VALUES 
                        (r_account.company_id, r_customer.customer_id, r_account.account_ext, NULL); 
                    
                ELSIF r_customer.person_type = 'J' THEN 
                    INSERT INTO erp_schema.customer_accounting_accounts 
                        (company_id, customer_id, accounting_account_id, check_account) 
                    VALUES 
                        (r_account.company_id, r_customer.customer_id, r_account.account_nac, NULL); 
                END IF;
            END IF;
        END LOOP;
    END LOOP;
END;
