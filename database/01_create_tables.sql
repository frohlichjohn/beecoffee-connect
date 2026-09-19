-- Habilita a extensão para gerar UUIDs automaticamente no PostgreSQL
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 1. Tabela de Usuários
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    full_name VARCHAR(150) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) CHECK (role IN ('CAFEICULTOR', 'APICULTOR')) NOT NULL,
    phone VARCHAR(20),
    document VARCHAR(20) UNIQUE, -- CPF ou CNPJ
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. Tabela de Propriedades (Fazendas e Apiários)
CREATE TABLE properties (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(150) NOT NULL,
    type VARCHAR(20) CHECK (type IN ('FAZENDA', 'APIARIO')) NOT NULL,
    latitude DECIMAL(10, 8) NOT NULL,  -- Para API de Mapas
    longitude DECIMAL(11, 8) NOT NULL, -- Para API de Mapas
    area_size DECIMAL(10, 2), -- Em hectares
    address_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 3. Tabela de Contratos (Match entre Cafeicultor e Apicultor)
CREATE TABLE contracts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cafeicultor_id UUID NOT NULL REFERENCES users(id),
    apicultor_id UUID NOT NULL REFERENCES users(id),
    property_farm_id UUID NOT NULL REFERENCES properties(id),
    property_apiary_id UUID NOT NULL REFERENCES properties(id),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    total_value DECIMAL(10, 2) NOT NULL,
    status VARCHAR(20) CHECK (status IN ('PENDENTE', 'ATIVO', 'CONCLUIDO', 'CANCELADO')) DEFAULT 'PENDENTE',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 4. Tabela de Produtividade (Para o Dashboard e ROI)
CREATE TABLE productivity_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    contract_id UUID NOT NULL REFERENCES contracts(id) ON DELETE CASCADE,
    log_date DATE NOT NULL,
    estimated_yield DECIMAL(10, 2), -- Ex: Sacas de café esperadas
    actual_yield DECIMAL(10, 2),    -- Ex: Sacas de café reais após colheita
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Criação de Índices para melhorar a performance de consultas comuns
CREATE INDEX idx_properties_coords ON properties(latitude, longitude);
CREATE INDEX idx_contracts_status ON contracts(status);