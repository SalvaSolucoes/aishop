
-- Tabela de clientes (sem dependências)
CREATE TABLE IF NOT EXISTS clientes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  usuario_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  nome VARCHAR(200) NOT NULL,
  email VARCHAR(200),
  telefone VARCHAR(20),
  documento VARCHAR(20),
  endereco TEXT,
  cidade VARCHAR(100),
  estado VARCHAR(2),
  cep VARCHAR(10),
  observacoes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela de produtos (sem dependências)
CREATE TABLE IF NOT EXISTS produtos (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  usuario_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  codigo VARCHAR(50),
  codigo_barras VARCHAR(13),
  nome VARCHAR(200) NOT NULL,
  descricao TEXT,
  categoria VARCHAR(100),
  unidade VARCHAR(10) DEFAULT 'un',
  quantidade DECIMAL(10,3) DEFAULT 0,
  estoque_minimo DECIMAL(10,3) DEFAULT 0,
  preco_custo DECIMAL(10,2) DEFAULT 0,
  preco_unitario DECIMAL(10,2) NOT NULL,
  margem_lucro DECIMAL(5,2) DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela de categorias (sem dependências)
CREATE TABLE IF NOT EXISTS categorias_produtos (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  usuario_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  nome VARCHAR(100) NOT NULL,
  usado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  vezes_usado INTEGER DEFAULT 1,
  UNIQUE(usuario_id, nome)
);

-- Tabela de contas financeiras (sem dependências)
CREATE TABLE IF NOT EXISTS contas_financeiras (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  usuario_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  descricao TEXT NOT NULL,
  tipo VARCHAR(10) NOT NULL,
  valor DECIMAL(10,2) NOT NULL,
  categoria VARCHAR(100),
  data_vencimento DATE NOT NULL,
  data_pagamento DATE,
  status VARCHAR(20) DEFAULT 'pendente',
  observacoes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela de caixas (sem dependências de outras tabelas da aplicação)
CREATE TABLE IF NOT EXISTS caixas (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  usuario_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  data DATE NOT NULL,
  valor_inicial DECIMAL(10,2) NOT NULL DEFAULT 0,
  data_abertura TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  data_fechamento TIMESTAMP WITH TIME ZONE,
  valor_final DECIMAL(10,2),
  saldo_real DECIMAL(10,2),
  diferenca_caixa DECIMAL(10,2),
  total_dinheiro DECIMAL(10,2) DEFAULT 0,
  total_debito DECIMAL(10,2) DEFAULT 0,
  total_credito DECIMAL(10,2) DEFAULT 0,
  total_pix DECIMAL(10,2) DEFAULT 0,
  total_vale DECIMAL(10,2) DEFAULT 0,
  total_sangria DECIMAL(10,2) DEFAULT 0,
  total_suprimento DECIMAL(10,2) DEFAULT 0,
  observacoes TEXT,
  motivo_fechamento TEXT,
  ultima_sequencia_venda INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(usuario_id, data)
);

-- Tabela de vendas (depende de caixas e clientes)
CREATE TABLE IF NOT EXISTS vendas (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  caixa_id UUID REFERENCES caixas(id) ON DELETE CASCADE NOT NULL,
  cliente_id UUID REFERENCES clientes(id) ON DELETE SET NULL,
  usuario_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  numero_venda VARCHAR(50),
  subtotal DECIMAL(10,2) NOT NULL,
  desconto DECIMAL(10,2) DEFAULT 0,
  total DECIMAL(10,2) NOT NULL,
  forma_pagamento VARCHAR(20) NOT NULL,
  valor_recebido DECIMAL(10,2),
  troco DECIMAL(10,2) DEFAULT 0,
  observacoes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela de itens de venda (depende de vendas e produtos)
CREATE TABLE IF NOT EXISTS itens_venda (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  venda_id UUID REFERENCES vendas(id) ON DELETE CASCADE NOT NULL,
  produto_id UUID REFERENCES produtos(id) ON DELETE RESTRICT NOT NULL,
  quantidade DECIMAL(10,3) NOT NULL,
  preco_unitario DECIMAL(10,2) NOT NULL,
  desconto DECIMAL(10,2) DEFAULT 0,
  subtotal DECIMAL(10,2) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela de movimentações de estoque (depende de produtos)
CREATE TABLE IF NOT EXISTS movimentacoes_estoque (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  produto_id UUID REFERENCES produtos(id) ON DELETE CASCADE NOT NULL,
  usuario_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  tipo VARCHAR(20) NOT NULL,
  quantidade DECIMAL(10,3) NOT NULL,
  quantidade_anterior DECIMAL(10,3),
  quantidade_nova DECIMAL(10,3),
  motivo TEXT,
  origem VARCHAR(50),
  origem_id UUID,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela de movimentações de caixa (depende de caixas)
CREATE TABLE IF NOT EXISTS movimentacoes_caixa (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  caixa_id UUID REFERENCES caixas(id) ON DELETE CASCADE NOT NULL,
  usuario_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  tipo VARCHAR(10) NOT NULL,
  valor DECIMAL(10,2) NOT NULL,
  descricao TEXT NOT NULL,
  categoria VARCHAR(100),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Adicionar campos à tabela caixas se não existirem
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name='caixas' AND column_name='ultima_sequencia_venda') THEN
    ALTER TABLE caixas ADD COLUMN ultima_sequencia_venda INTEGER DEFAULT 0;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name='caixas' AND column_name='motivo_fechamento') THEN
    ALTER TABLE caixas ADD COLUMN motivo_fechamento TEXT;
  END IF;
END $$;

-- Adicionar campos de rastreamento de origem à movimentacoes_estoque
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name='movimentacoes_estoque' AND column_name='origem') THEN
    ALTER TABLE movimentacoes_estoque ADD COLUMN origem VARCHAR(50);
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name='movimentacoes_estoque' AND column_name='origem_id') THEN
    ALTER TABLE movimentacoes_estoque ADD COLUMN origem_id UUID;
  END IF;
END $$;

DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name='clientes' AND column_name='data_nascimento') THEN
    ALTER TABLE clientes ADD COLUMN data_nascimento DATE;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name='clientes' AND column_name='tipo_cliente') THEN
    ALTER TABLE clientes ADD COLUMN tipo_cliente VARCHAR(20);
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name='clientes' AND column_name='limite_credito') THEN
    ALTER TABLE clientes ADD COLUMN limite_credito DECIMAL(10,2) DEFAULT 0;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name='clientes' AND column_name='pontos_fidelidade') THEN
    ALTER TABLE clientes ADD COLUMN pontos_fidelidade INTEGER DEFAULT 0;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name='clientes' AND column_name='situacao') THEN
    ALTER TABLE clientes ADD COLUMN situacao VARCHAR(20) DEFAULT 'ativo';
  END IF;
END $$;

-- Índices para categorias_produtos
CREATE INDEX IF NOT EXISTS idx_categorias_usuario ON categorias_produtos(usuario_id);
CREATE INDEX IF NOT EXISTS idx_categorias_nome ON categorias_produtos(nome);

-- Índices para produtos
CREATE INDEX IF NOT EXISTS idx_produtos_usuario ON produtos(usuario_id);
CREATE INDEX IF NOT EXISTS idx_produtos_nome ON produtos(nome);
CREATE INDEX IF NOT EXISTS idx_produtos_codigo ON produtos(codigo);
CREATE INDEX IF NOT EXISTS idx_produtos_categoria ON produtos(categoria);

-- Índices para caixas
CREATE INDEX IF NOT EXISTS idx_caixas_usuario_data ON caixas(usuario_id, data);
CREATE INDEX IF NOT EXISTS idx_caixas_data ON caixas(data DESC);

-- Índices para vendas
CREATE INDEX IF NOT EXISTS idx_vendas_numero_venda ON vendas(numero_venda);
CREATE INDEX IF NOT EXISTS idx_vendas_caixa ON vendas(caixa_id);
CREATE INDEX IF NOT EXISTS idx_vendas_cliente ON vendas(cliente_id);
CREATE INDEX IF NOT EXISTS idx_vendas_usuario ON vendas(usuario_id);
CREATE INDEX IF NOT EXISTS idx_vendas_created ON vendas(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_vendas_usuario_data ON vendas(usuario_id, created_at);

-- Índices para itens_venda
CREATE INDEX IF NOT EXISTS idx_itens_venda_venda ON itens_venda(venda_id);
CREATE INDEX IF NOT EXISTS idx_itens_venda_produto ON itens_venda(produto_id);

-- Índices para movimentacoes_estoque
CREATE INDEX IF NOT EXISTS idx_movimentacoes_estoque_produto ON movimentacoes_estoque(produto_id, created_at);
CREATE INDEX IF NOT EXISTS idx_movimentacoes_estoque_origem ON movimentacoes_estoque(origem, origem_id);

-- Índices para movimentacoes_caixa
CREATE INDEX IF NOT EXISTS idx_movimentacoes_caixa_caixa ON movimentacoes_caixa(caixa_id);
CREATE INDEX IF NOT EXISTS idx_movimentacoes_caixa_usuario ON movimentacoes_caixa(usuario_id);

-- Índices para clientes
CREATE INDEX IF NOT EXISTS idx_clientes_usuario ON clientes(usuario_id);
CREATE INDEX IF NOT EXISTS idx_clientes_nome ON clientes(nome);

-- Índices para contas_financeiras
CREATE INDEX IF NOT EXISTS idx_contas_usuario ON contas_financeiras(usuario_id);
CREATE INDEX IF NOT EXISTS idx_contas_vencimento ON contas_financeiras(data_vencimento);
CREATE INDEX IF NOT EXISTS idx_contas_status ON contas_financeiras(status);


CREATE OR REPLACE FUNCTION get_proximo_numero_venda(p_caixa_id UUID)
RETURNS TEXT AS $$
DECLARE
  v_sequencia INTEGER;
BEGIN
  -- Atualizar e obter próxima sequência
  UPDATE caixas 
  SET ultima_sequencia_venda = COALESCE(ultima_sequencia_venda, 0) + 1
  WHERE id = p_caixa_id
  RETURNING ultima_sequencia_venda INTO v_sequencia;
  
  -- Retornar no formato #venda1, #venda2, etc.
  RETURN '#venda' || v_sequencia;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Habilitar RLS em todas as tabelas
ALTER TABLE produtos ENABLE ROW LEVEL SECURITY;
ALTER TABLE caixas ENABLE ROW LEVEL SECURITY;
ALTER TABLE vendas ENABLE ROW LEVEL SECURITY;
ALTER TABLE itens_venda ENABLE ROW LEVEL SECURITY;
ALTER TABLE movimentacoes_estoque ENABLE ROW LEVEL SECURITY;
ALTER TABLE movimentacoes_caixa ENABLE ROW LEVEL SECURITY;
ALTER TABLE clientes ENABLE ROW LEVEL SECURITY;
ALTER TABLE contas_financeiras ENABLE ROW LEVEL SECURITY;

-- Remover políticas existentes se houverem
DROP POLICY IF EXISTS policy_produtos_all ON produtos;
DROP POLICY IF EXISTS policy_caixas_all ON caixas;
DROP POLICY IF EXISTS policy_vendas_all ON vendas;
DROP POLICY IF EXISTS policy_itens_venda_all ON itens_venda;
DROP POLICY IF EXISTS policy_movimentacoes_estoque_all ON movimentacoes_estoque;
DROP POLICY IF EXISTS policy_movimentacoes_caixa_all ON movimentacoes_caixa;
DROP POLICY IF EXISTS policy_clientes_all ON clientes;
DROP POLICY IF EXISTS policy_contas_financeiras_all ON contas_financeiras;

-- Criar políticas para produtos
CREATE POLICY policy_produtos_all ON produtos
  FOR ALL USING (auth.uid() = usuario_id)
  WITH CHECK (auth.uid() = usuario_id);

-- Criar políticas para caixas
CREATE POLICY policy_caixas_all ON caixas
  FOR ALL USING (auth.uid() = usuario_id)
  WITH CHECK (auth.uid() = usuario_id);

-- Criar políticas para vendas
CREATE POLICY policy_vendas_all ON vendas
  FOR ALL USING (auth.uid() = usuario_id)
  WITH CHECK (auth.uid() = usuario_id);

-- Criar políticas para itens_venda (permite acesso através de venda)
CREATE POLICY policy_itens_venda_all ON itens_venda
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM vendas 
      WHERE vendas.id = itens_venda.venda_id 
      AND vendas.usuario_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM vendas 
      WHERE vendas.id = itens_venda.venda_id 
      AND vendas.usuario_id = auth.uid()
    )
  );

-- Criar políticas para movimentacoes_estoque
CREATE POLICY policy_movimentacoes_estoque_all ON movimentacoes_estoque
  FOR ALL USING (auth.uid() = usuario_id)
  WITH CHECK (auth.uid() = usuario_id);

-- Criar políticas para movimentacoes_caixa
CREATE POLICY policy_movimentacoes_caixa_all ON movimentacoes_caixa
  FOR ALL USING (auth.uid() = usuario_id)
  WITH CHECK (auth.uid() = usuario_id);

-- Criar políticas para clientes
CREATE POLICY policy_clientes_all ON clientes
  FOR ALL USING (auth.uid() = usuario_id)
  WITH CHECK (auth.uid() = usuario_id);

-- Criar políticas para contas_financeiras
CREATE POLICY policy_contas_financeiras_all ON contas_financeiras
  FOR ALL USING (auth.uid() = usuario_id)
  WITH CHECK (auth.uid() = usuario_id);

-- Função de trigger para atualizar timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar triggers de atualização
DROP TRIGGER IF EXISTS update_produtos_updated_at ON produtos;
CREATE TRIGGER update_produtos_updated_at
    BEFORE UPDATE ON produtos
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_clientes_updated_at ON clientes;
CREATE TRIGGER update_clientes_updated_at
    BEFORE UPDATE ON clientes
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_contas_financeiras_updated_at ON contas_financeiras;
CREATE TRIGGER update_contas_financeiras_updated_at
    BEFORE UPDATE ON contas_financeiras
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();