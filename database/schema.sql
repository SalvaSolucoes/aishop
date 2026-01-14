-- ============================================================================
-- AIShop - Schema do Banco de Dados
-- Sistema de Gestão Empresarial (PostgreSQL/Supabase)
-- ============================================================================
-- Execute este script completo no SQL Editor do Supabase
-- ============================================================================

-- ============================================================================
-- TABELAS
-- ============================================================================

-- Tabela: produtos
CREATE TABLE IF NOT EXISTS produtos (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  usuario_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  codigo VARCHAR(100),
  codigo_barras VARCHAR(50),
  nome VARCHAR(255) NOT NULL,
  quantidade INTEGER NOT NULL DEFAULT 0 CHECK (quantidade >= 0),
  estoque_minimo INTEGER DEFAULT 0 CHECK (estoque_minimo >= 0),
  preco_custo DECIMAL(10, 2) DEFAULT 0 CHECK (preco_custo >= 0),
  preco_unitario DECIMAL(10, 2) NOT NULL DEFAULT 0 CHECK (preco_unitario >= 0),
  margem_lucro DECIMAL(5, 2) DEFAULT 0 CHECK (margem_lucro >= 0),
  unidade VARCHAR(20) DEFAULT 'un',
  categoria VARCHAR(100),
  descricao TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela: movimentacoes_estoque
CREATE TABLE IF NOT EXISTS movimentacoes_estoque (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  produto_id UUID REFERENCES produtos(id) ON DELETE CASCADE NOT NULL,
  usuario_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  tipo VARCHAR(20) NOT NULL CHECK (tipo IN ('compra', 'ajuste', 'devolucao', 'perda', 'troca', 'venda', 'entrada', 'saida')),
  quantidade INTEGER NOT NULL CHECK (quantidade > 0),
  quantidade_anterior INTEGER NOT NULL CHECK (quantidade_anterior >= 0),
  quantidade_nova INTEGER NOT NULL CHECK (quantidade_nova >= 0),
  motivo TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela: clientes
CREATE TABLE IF NOT EXISTS clientes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  usuario_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  nome VARCHAR(255) NOT NULL,
  email VARCHAR(255),
  telefone VARCHAR(20),
  documento VARCHAR(20),
  tipo_cliente VARCHAR(10) DEFAULT 'fisica' CHECK (tipo_cliente IN ('fisica', 'juridica')),
  data_nascimento DATE,
  endereco TEXT,
  cidade VARCHAR(100),
  estado VARCHAR(2),
  cep VARCHAR(10),
  limite_credito DECIMAL(10, 2) DEFAULT 0 CHECK (limite_credito >= 0),
  pontos_fidelidade INTEGER DEFAULT 0 CHECK (pontos_fidelidade >= 0),
  situacao VARCHAR(10) DEFAULT 'ativo' CHECK (situacao IN ('ativo', 'inativo')),
  observacoes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela: caixas
CREATE TABLE IF NOT EXISTS caixas (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  usuario_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  operador_id UUID REFERENCES auth.users(id),
  data DATE NOT NULL,
  valor_inicial DECIMAL(10, 2) NOT NULL DEFAULT 0 CHECK (valor_inicial >= 0),
  valor_final DECIMAL(10, 2) CHECK (valor_final >= 0),
  total_dinheiro DECIMAL(10, 2) DEFAULT 0,
  total_debito DECIMAL(10, 2) DEFAULT 0,
  total_credito DECIMAL(10, 2) DEFAULT 0,
  total_pix DECIMAL(10, 2) DEFAULT 0,
  total_vale DECIMAL(10, 2) DEFAULT 0,
  total_sangria DECIMAL(10, 2) DEFAULT 0,
  total_suprimento DECIMAL(10, 2) DEFAULT 0,
  diferenca_caixa DECIMAL(10, 2) DEFAULT 0,
  data_fechamento TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(usuario_id, data)
);

-- Tabela: movimentacoes_caixa
CREATE TABLE IF NOT EXISTS movimentacoes_caixa (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  caixa_id UUID REFERENCES caixas(id) ON DELETE CASCADE NOT NULL,
  usuario_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  tipo VARCHAR(20) NOT NULL CHECK (tipo IN ('entrada', 'saida', 'sangria', 'suprimento')),
  valor DECIMAL(10, 2) NOT NULL CHECK (valor > 0),
  descricao VARCHAR(255) NOT NULL,
  categoria VARCHAR(100),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela: vendas
CREATE TABLE IF NOT EXISTS vendas (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  caixa_id UUID REFERENCES caixas(id) ON DELETE CASCADE NOT NULL,
  cliente_id UUID REFERENCES clientes(id) ON DELETE SET NULL,
  usuario_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  numero_venda VARCHAR(50),
  subtotal DECIMAL(10, 2) NOT NULL DEFAULT 0 CHECK (subtotal >= 0),
  desconto DECIMAL(10, 2) DEFAULT 0 CHECK (desconto >= 0),
  total DECIMAL(10, 2) NOT NULL DEFAULT 0 CHECK (total >= 0),
  forma_pagamento VARCHAR(20) NOT NULL CHECK (forma_pagamento IN ('dinheiro', 'debito', 'credito', 'pix', 'vale', 'mistura')),
  valor_recebido DECIMAL(10, 2) DEFAULT 0,
  troco DECIMAL(10, 2) DEFAULT 0 CHECK (troco >= 0),
  observacoes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela: itens_venda
CREATE TABLE IF NOT EXISTS itens_venda (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  venda_id UUID REFERENCES vendas(id) ON DELETE CASCADE NOT NULL,
  produto_id UUID REFERENCES produtos(id) ON DELETE CASCADE NOT NULL,
  quantidade INTEGER NOT NULL CHECK (quantidade > 0),
  preco_unitario DECIMAL(10, 2) NOT NULL CHECK (preco_unitario >= 0),
  desconto DECIMAL(10, 2) DEFAULT 0 CHECK (desconto >= 0),
  subtotal DECIMAL(10, 2) NOT NULL CHECK (subtotal >= 0),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela: contas_financeiras
CREATE TABLE IF NOT EXISTS contas_financeiras (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  usuario_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  tipo VARCHAR(20) NOT NULL CHECK (tipo IN ('receber', 'pagar')),
  descricao VARCHAR(255) NOT NULL,
  valor DECIMAL(10, 2) NOT NULL CHECK (valor > 0),
  data_vencimento DATE NOT NULL,
  data_pagamento DATE,
  categoria VARCHAR(100),
  observacoes TEXT,
  status VARCHAR(20) NOT NULL DEFAULT 'pendente' CHECK (status IN ('pendente', 'pago', 'vencido')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- ÍNDICES
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_produtos_usuario ON produtos(usuario_id);
CREATE INDEX IF NOT EXISTS idx_produtos_nome ON produtos(nome);
CREATE INDEX IF NOT EXISTS idx_produtos_codigo_barras ON produtos(codigo_barras);

CREATE INDEX IF NOT EXISTS idx_movimentacoes_estoque_produto ON movimentacoes_estoque(produto_id);
CREATE INDEX IF NOT EXISTS idx_movimentacoes_estoque_usuario ON movimentacoes_estoque(usuario_id);

CREATE INDEX IF NOT EXISTS idx_clientes_usuario ON clientes(usuario_id);
CREATE INDEX IF NOT EXISTS idx_clientes_nome ON clientes(nome);

CREATE INDEX IF NOT EXISTS idx_caixas_usuario ON caixas(usuario_id);
CREATE INDEX IF NOT EXISTS idx_caixas_data ON caixas(data);

CREATE INDEX IF NOT EXISTS idx_movimentacoes_caixa_caixa ON movimentacoes_caixa(caixa_id);
CREATE INDEX IF NOT EXISTS idx_movimentacoes_caixa_usuario ON movimentacoes_caixa(usuario_id);

CREATE INDEX IF NOT EXISTS idx_contas_financeiras_usuario ON contas_financeiras(usuario_id);
CREATE INDEX IF NOT EXISTS idx_contas_financeiras_status ON contas_financeiras(status);
CREATE INDEX IF NOT EXISTS idx_contas_financeiras_vencimento ON contas_financeiras(data_vencimento);

CREATE INDEX IF NOT EXISTS idx_vendas_caixa ON vendas(caixa_id);
CREATE INDEX IF NOT EXISTS idx_vendas_cliente ON vendas(cliente_id);
CREATE INDEX IF NOT EXISTS idx_vendas_usuario ON vendas(usuario_id);
CREATE INDEX IF NOT EXISTS idx_vendas_data ON vendas(created_at);

CREATE INDEX IF NOT EXISTS idx_itens_venda_venda ON itens_venda(venda_id);
CREATE INDEX IF NOT EXISTS idx_itens_venda_produto ON itens_venda(produto_id);

-- ============================================================================
-- FUNÇÕES E TRIGGERS
-- ============================================================================

-- Função para atualizar updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para produtos
DROP TRIGGER IF EXISTS trigger_produtos_updated_at ON produtos;
CREATE TRIGGER trigger_produtos_updated_at
  BEFORE UPDATE ON produtos
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Trigger para clientes
DROP TRIGGER IF EXISTS trigger_clientes_updated_at ON clientes;
CREATE TRIGGER trigger_clientes_updated_at
  BEFORE UPDATE ON clientes
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Trigger para contas_financeiras
DROP TRIGGER IF EXISTS trigger_contas_updated_at ON contas_financeiras;
CREATE TRIGGER trigger_contas_updated_at
  BEFORE UPDATE ON contas_financeiras
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================================

ALTER TABLE produtos ENABLE ROW LEVEL SECURITY;
ALTER TABLE movimentacoes_estoque ENABLE ROW LEVEL SECURITY;
ALTER TABLE clientes ENABLE ROW LEVEL SECURITY;
ALTER TABLE caixas ENABLE ROW LEVEL SECURITY;
ALTER TABLE movimentacoes_caixa ENABLE ROW LEVEL SECURITY;
ALTER TABLE contas_financeiras ENABLE ROW LEVEL SECURITY;
ALTER TABLE vendas ENABLE ROW LEVEL SECURITY;
ALTER TABLE itens_venda ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- POLÍTICAS RLS - PRODUTOS
-- ============================================================================

DROP POLICY IF EXISTS policy_produtos_select ON produtos;
CREATE POLICY policy_produtos_select
  ON produtos FOR SELECT
  USING (auth.uid() = usuario_id);

DROP POLICY IF EXISTS policy_produtos_insert ON produtos;
CREATE POLICY policy_produtos_insert
  ON produtos FOR INSERT
  WITH CHECK (auth.uid() = usuario_id);

DROP POLICY IF EXISTS policy_produtos_update ON produtos;
CREATE POLICY policy_produtos_update
  ON produtos FOR UPDATE
  USING (auth.uid() = usuario_id)
  WITH CHECK (auth.uid() = usuario_id);

DROP POLICY IF EXISTS policy_produtos_delete ON produtos;
CREATE POLICY policy_produtos_delete
  ON produtos FOR DELETE
  USING (auth.uid() = usuario_id);

-- ============================================================================
-- POLÍTICAS RLS - MOVIMENTAÇÕES DE ESTOQUE
-- ============================================================================

DROP POLICY IF EXISTS policy_movimentacoes_estoque_select ON movimentacoes_estoque;
CREATE POLICY policy_movimentacoes_estoque_select
  ON movimentacoes_estoque FOR SELECT
  USING (auth.uid() = usuario_id);

DROP POLICY IF EXISTS policy_movimentacoes_estoque_insert ON movimentacoes_estoque;
CREATE POLICY policy_movimentacoes_estoque_insert
  ON movimentacoes_estoque FOR INSERT
  WITH CHECK (auth.uid() = usuario_id);

-- ============================================================================
-- POLÍTICAS RLS - CLIENTES
-- ============================================================================

DROP POLICY IF EXISTS policy_clientes_select ON clientes;
CREATE POLICY policy_clientes_select
  ON clientes FOR SELECT
  USING (auth.uid() = usuario_id);

DROP POLICY IF EXISTS policy_clientes_insert ON clientes;
CREATE POLICY policy_clientes_insert
  ON clientes FOR INSERT
  WITH CHECK (auth.uid() = usuario_id);

DROP POLICY IF EXISTS policy_clientes_update ON clientes;
CREATE POLICY policy_clientes_update
  ON clientes FOR UPDATE
  USING (auth.uid() = usuario_id)
  WITH CHECK (auth.uid() = usuario_id);

DROP POLICY IF EXISTS policy_clientes_delete ON clientes;
CREATE POLICY policy_clientes_delete
  ON clientes FOR DELETE
  USING (auth.uid() = usuario_id);

-- ============================================================================
-- POLÍTICAS RLS - CAIXAS
-- ============================================================================

DROP POLICY IF EXISTS policy_caixas_select ON caixas;
CREATE POLICY policy_caixas_select
  ON caixas FOR SELECT
  USING (auth.uid() = usuario_id);

DROP POLICY IF EXISTS policy_caixas_insert ON caixas;
CREATE POLICY policy_caixas_insert
  ON caixas FOR INSERT
  WITH CHECK (auth.uid() = usuario_id);

DROP POLICY IF EXISTS policy_caixas_update ON caixas;
CREATE POLICY policy_caixas_update
  ON caixas FOR UPDATE
  USING (auth.uid() = usuario_id)
  WITH CHECK (auth.uid() = usuario_id);

-- ============================================================================
-- POLÍTICAS RLS - MOVIMENTAÇÕES DE CAIXA
-- ============================================================================

DROP POLICY IF EXISTS policy_movimentacoes_caixa_select ON movimentacoes_caixa;
CREATE POLICY policy_movimentacoes_caixa_select
  ON movimentacoes_caixa FOR SELECT
  USING (auth.uid() = usuario_id);

DROP POLICY IF EXISTS policy_movimentacoes_caixa_insert ON movimentacoes_caixa;
CREATE POLICY policy_movimentacoes_caixa_insert
  ON movimentacoes_caixa FOR INSERT
  WITH CHECK (auth.uid() = usuario_id);

-- ============================================================================
-- POLÍTICAS RLS - CONTAS FINANCEIRAS
-- ============================================================================

DROP POLICY IF EXISTS policy_contas_select ON contas_financeiras;
CREATE POLICY policy_contas_select
  ON contas_financeiras FOR SELECT
  USING (auth.uid() = usuario_id);

DROP POLICY IF EXISTS policy_contas_insert ON contas_financeiras;
CREATE POLICY policy_contas_insert
  ON contas_financeiras FOR INSERT
  WITH CHECK (auth.uid() = usuario_id);

DROP POLICY IF EXISTS policy_contas_update ON contas_financeiras;
CREATE POLICY policy_contas_update
  ON contas_financeiras FOR UPDATE
  USING (auth.uid() = usuario_id)
  WITH CHECK (auth.uid() = usuario_id);

DROP POLICY IF EXISTS policy_contas_delete ON contas_financeiras;
CREATE POLICY policy_contas_delete
  ON contas_financeiras FOR DELETE
  USING (auth.uid() = usuario_id);

-- ============================================================================
-- POLÍTICAS RLS - VENDAS
-- ============================================================================

DROP POLICY IF EXISTS policy_vendas_select ON vendas;
CREATE POLICY policy_vendas_select
  ON vendas FOR SELECT
  USING (auth.uid() = usuario_id);

DROP POLICY IF EXISTS policy_vendas_insert ON vendas;
CREATE POLICY policy_vendas_insert
  ON vendas FOR INSERT
  WITH CHECK (auth.uid() = usuario_id);

DROP POLICY IF EXISTS policy_vendas_update ON vendas;
CREATE POLICY policy_vendas_update
  ON vendas FOR UPDATE
  USING (auth.uid() = usuario_id)
  WITH CHECK (auth.uid() = usuario_id);

-- ============================================================================
-- POLÍTICAS RLS - ITENS VENDA
-- ============================================================================

DROP POLICY IF EXISTS policy_itens_venda_select ON itens_venda;
CREATE POLICY policy_itens_venda_select
  ON itens_venda FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM vendas
      WHERE vendas.id = itens_venda.venda_id
      AND vendas.usuario_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS policy_itens_venda_insert ON itens_venda;
CREATE POLICY policy_itens_venda_insert
  ON itens_venda FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM vendas
      WHERE vendas.id = itens_venda.venda_id
      AND vendas.usuario_id = auth.uid()
    )
  );

-- ============================================================================
-- FIM DO SCRIPT
-- ============================================================================
