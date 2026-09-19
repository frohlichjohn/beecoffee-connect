const { Pool } = require('pg');

const pool = new Pool({
  // Tenta usar o banco da nuvem primeiro, se não achar, usa o local
  connectionString: process.env.DATABASE_URL || 'postgresql://SEU_USER_LOCAL:SUA_SENHA_LOCAL@localhost:5432/SEU_BANCO_LOCAL',
  
  // A configuração SSL é obrigatória para conectar no banco da nuvem (Neon)
  ssl: process.env.DATABASE_URL ? { rejectUnauthorized: false } : false
});

module.exports = pool;