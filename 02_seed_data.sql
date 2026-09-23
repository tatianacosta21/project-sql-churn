
-- ETAPA 1

create table if not exists clientes (  -- só cria se ainda não existir; se já existir, não faz nada e não dá erro
	id serial primary key, -- coluna "id": número que aumenta sozinho (1, 2, 3...) e é a chave única de cada linha
	nome varchar(100) not null, -- coluna "nome": texto de até 100 caracteres, obrigatório (não pode ficar vazio)
	email varchar(100), -- coluna "email": texto de até 100 caracteres, pode ficar vazio (sem NOT NULL)
	data_cadastro date not null -- coluna "data_cadastro": guarda só a data (sem hora), obrigatória
);

create table if not exists pedidos ( -- só cria se ainda não existir; se já existir, não faz nada e não dá erro
	id serial primary key, -- coluna "id": número automático, chave única de cada pedido
	cliente_id  integer not null -- coluna "cliente_id": número que identifica de qual cliente é o pedido
		references clientes(id),  -- garante que esse número só pode ser um "id" que já existe na tabela clientes (evita pedido "órfão")
	data_pedido date not null, -- coluna "data_pedido": data em que o pedido foi feito, obrigatória
	valor numeric(10, 2) not null -- coluna "valor": número decimal com até 10 dígitos no total e 2 depois da vírgula (ex.: 12345678.90)
		check (valor > 0) -- regra extra: não deixa cadastrar um pedido com valor zero ou negativo
);

------------------------------------------------------------------------------------------------
-- SERIAL: é um atalho prático que cria uma coluna de números inteiros com incremento automático.
-------------------------------------------------------------------------------------------------


-- ETAPA 2

-- Primeiros os 20 clientes:
insert into clientes (nome, email, data_cadastro) -- vai inserir dados nessas 3 colunas da tabela clientes
select 
	'Cliente' || i, -- monta o nome: "Cliente " + o número da linha (Cliente 1, Cliente 2...).          || junta textos
	'cliente' || i || '@email.com', -- monta um email fake no mesmo estilo: cliente1@email.com, cliente2@email.com... 
	current_date - (300 + (i * 5)) :: int * interval '1 day' -- data de cadastro no passado: quanto maior o "i", mais antigo o cadastro
from generate_series(1, 20) as i; -- gera os números de 1 a 20 automaticamente, um para cada cliente (sem precisar escrever 20 linhas à mão) 

---------------------------------------------------
-- CURRENT_DATE - (300 + (i * 5))::int * INTERVAL '1 day'

-- Passos do Cálculo
	-- 1. i * 5: Multiplica o número da linha atual por 5.
		-- Para i = 1, o resultado é 5.
		-- Para i = 20, o resultado é 100
	-- 2. 300 + (i * 5): Soma um offset fixo de 300 ao resultado. Isso garante que até o primeiro cliente (i = 1) já tenha sido cadastrado há mais de 300 dias.
		-- Para i = 1:300 + 5 = 305.
		-- Para i = 20:300 + 100 = 400.
	-- 3. ::int * INTERVAL '1 day': Converte o número inteiro resultante em um intervalo de dias no PostgreSQL (ex.: 305 * INTERVAL '1 day' vira o intervalo de 305 days).
	-- 4. CURRENT_DATE - ...: Subtrai esse intervalo de dias da data atual do sistema (CURRENT_DATE).

-- RESULTADOS PRÁTICOS:
-- i    |     Dias Subtraídos     |   Cálculo da data        |  Data Resultante
-- 1    |  300 + (1 x 5) = 305    |  17/09/2026 - 305 dias   |     16/11/2025
-- 2    |  300 + (2 x 5) = 310    |  17/09/2026 - 310 dias   |     11/11/2025
-- ...  |  ...                    |  ...                     |     ...
-- 20   |  300 + (20 x 5) = 400   |  17/09/2026 - 400 dias   |     13/08/2025

-- Cada novo cliente fica 5 dias mais antigo que o anterior.


	-- GRUPO 1: clientes de id 1 a 5): clientes ativos, com compras recentes e frequentes
insert into pedidos (clientes_id, data_pedido, valor) -- insere nessas 3 colunas da tabela pedidos
select
	c.id, -- usa o id do cliente (vindo da tabela clientes)
	current_date - (s * 15 + (c.id * 2)) :: int * interval '1 day',  -- gera datas espaçadas a cada ~15 dias no passado
	round((50 + random() * 450 ) :: numeric, 2) -- gera um valor aleatório entre 50 e 500, arredondado a 2 casas decimais
from clientes c
cross join generate_series(0, 10) as s  -- gera 12 pedidos (s de 0 a 11) para cada cliente desse grupo
where c.id between 1 and 5; -- filtra só os clientes de id 1 a 5


	-- GRUPO 2: clientes de id 6 a 10): compravam regularmente, mas pararam há uns 70 dias
insert into pedidos(cliente_id, data_pedido, valor)
select
	c.id,
	current_date - (70 + s * 18 + (c.id * 2)) :: int * interval '1 day', -- soma 70 dias de "pausa" antes de começar a contar os pedidos antigos
	round ((50 + random() * 450) :: numeric, 2)
from clientes c
cross join generate_series(0, 8) as s -- 9 pedidos por cliente (s de 0 a 8)
where c.id between 6 and 10;


	-- GRUPO 3 (clientes de 11 a 15): clientes perdidos, última compra há mais de 180 dias
insert into pedidos (cliente_id, data_pedido, valor)
select
	c.id,
	current_date - (200 + s * 20 + (c.id * 2)) :: int * interval '1 day', -- soma 200 dias de "pausa" antes de começar a contar os pedidos antigos
	round ((50 + random() * 450) :: numeric, 2)
from clientes c
cross join generate_series(0, 6) as s -- 7 pedidos por cliente (s de 0 a 6)
where c.id between 11 and 15;

	
	-- GRUPO 4 (clientes de id 16 a 20): clientes novos, cadastro recente e poucas compras
insert into pedidos (cliente_id, data_pedido, valor)
select
    c.id,
    current_date - (s * 10 + c.id) :: int * interval '1 day', -- datas bem recentes, sem período de pausa
    ROUND((50 + random() * 450)::numeric, 2)
from clientes c
cross join generate_series(0, 2) as s -- só 3 pedidos por cliente (s de 0 a 2)
where c.id between 16 and 20;


--------------------------------------------------------------------------------------------------------------------
-- CONFIRMADNDO SE ESTÁ A DAR TUDO CERTO
/*
SELECT
    cliente_id,                          -- id do cliente
    COUNT(*) AS total_pedidos,           -- conta quantos pedidos esse cliente tem
    MIN(data_pedido) AS primeira_compra, -- data do pedido mais antigo dele
    MAX(data_pedido) AS ultima_compra    -- data do pedido mais recente dele
FROM pedidos
GROUP BY cliente_id                      -- agrupa os pedidos por cliente, para as funções acima calcularem por cliente
ORDER BY cliente_id;                     -- ordena o resultado pelo id, só para ficar organizado
*/
--------------------------------------------------------------------------------------------------------------------



-- ETAPA 3 - Explorar os dados antes de partir para o RFM

-- QUERIES DE RECONHECIMENTO
select
	(select count(*) from clientes) as total_clientes, -- conta quantos clientes existem no total
	(select count(*) from pedidos) as total_pedidos, -- ccontas quantos pedidos existem no total
	(select round(sum(valor), 2) from pedidos) as receita_total, -- soma o valo de todos os pedidos
	(select round(avg(valor), 2) from pedidos) as ticket_medio; -- calcula o valor médio de um pedido
	
-- RECEITA E FREQUÊNCIA POR CLIENTE:
