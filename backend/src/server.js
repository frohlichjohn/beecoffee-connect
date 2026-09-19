const express = require('express');
const cors = require('cors');
require('dotenv').config();
const db = require('./config/database');

const app = express();

// Configurações padrão do servidor para aceitar JSON
app.use(cors());
app.use(express.json());

// ==========================================
// ROTA 1: Teste de Conexão (Status)
// ==========================================
app.get('/api/status', async (req, res) => {
    try {
        const result = await db.query('SELECT NOW()');
        res.json({ 
            status: '✅ API do BeeCoffee Connect Online', 
            database_time: result.rows[0].now 
        });
    } catch (error) {
        console.error('Erro de conexão:', error);
        res.status(500).json({ error: 'Falha ao conectar com o banco de dados' });
    }
});

// ==========================================
// ROTA 2: Validação de Login
// ==========================================
app.post('/api/login', async (req, res) => {
    const { email, password } = req.body;

    try {
        // Busca o usuário no banco de dados pelo e-mail digitado no app
        const query = 'SELECT * FROM users WHERE email = $1';
        const result = await db.query(query, [email]);

        // Se a lista de resultados for zero, o e-mail não existe
        if (result.rows.length === 0) {
            return res.status(401).json({ error: 'E-mail não cadastrado.' });
        }

        const user = result.rows[0];

        // Valida se a senha confere (comparação direta para o MVP)
        if (user.password_hash !== password) {
            return res.status(401).json({ error: 'Senha incorreta.' });
        }

        // Login bem-sucedido! Retornamos os dados do banco para o Flutter
        // IMPORTANTE: Agora estamos enviando a 'location' também
        res.json({
            message: 'Login realizado com sucesso!',
            user: {
                id: user.id,
                full_name: user.full_name,
                email: user.email,
                role: user.role,
                location: user.location // <-- Nova informação que vai para a Home
            }
        });

    } catch (error) {
        console.error('Erro no login:', error);
        res.status(500).json({ error: 'Erro interno no servidor.' });
    }
});

// ==========================================
// ROTA 3: Cadastro de Novos Usuários
// ==========================================
app.post('/api/register', async (req, res) => {
    // Agora recebemos a 'location' que o usuário vai digitar na tela de cadastro
    const { full_name, email, password, role, location } = req.body;

    try {
        // Primeiro, garantimos que não haja e-mails duplicados
        const checkUser = await db.query('SELECT * FROM users WHERE email = $1', [email]);
        if (checkUser.rows.length > 0) {
            return res.status(400).json({ error: 'Este e-mail já está cadastrado.' });
        }

        // Insere o novo usuário, mapeando as 5 variáveis para os 5 campos do banco ($1 a $5)
        const insertQuery = `
            INSERT INTO users (full_name, email, password_hash, role, location)
            VALUES ($1, $2, $3, $4, $5)
            RETURNING id, full_name, email, role, location;
        `;
        const newUser = await db.query(insertQuery, [full_name, email, password, role.toUpperCase(), location]);

        res.status(201).json({
            message: 'Usuário cadastrado com sucesso!',
            user: newUser.rows[0] // Devolve os dados criados como confirmação
        });

    } catch (error) {
        console.error('Erro no cadastro:', error);
        res.status(500).json({ error: 'Erro interno ao cadastrar usuário.' });
    }
});

// ==========================================
// ROTA 5: Buscar contratos do Cafeicultor
// ==========================================
app.get('/api/contracts/cafeicultor/:id', async (req, res) => {
    const { id } = req.params;
    try {
        const query = `
            SELECT c.id, c.status, c.quantidade_colmeias, c.valor_total, u.full_name AS apicultor_nome
            FROM contracts c
            JOIN users u ON c.apicultor_id = u.id
            WHERE c.cafeicultor_id = $1
            ORDER BY c.created_at DESC;
        `;
        const result = await db.query(query, [id]);
        res.json(result.rows);
    } catch (error) {
        res.status(500).json({ error: 'Erro ao buscar contratos do cafeicultor.' });
    }
});

// ==========================================
// ROTA 6: Listar Apicultores para o Match
// ==========================================
app.get('/api/beekeepers', async (req, res) => {
    try {
        // Agora o SELECT puxa explicitamente as colunas city e state recém-criadas!
        const query = `
            SELECT id, full_name, latitude, longitude, total_colmeias, preco_por_colmeia, city, state 
            FROM users 
            WHERE role = 'APICULTOR'
        `;
        const result = await db.query(query);
        res.json(result.rows);
    } catch (error) {
        console.error('Erro ao buscar apicultores:', error);
        res.status(500).json({ error: 'Erro ao buscar apicultores.' });
    }
});

// ==========================================
// ROTA 7: Buscar propostas pendentes do Apicultor
// ==========================================
app.get('/api/contracts/apicultor/:id', async (req, res) => {
    const { id } = req.params;

    try {
        // Traz apenas as propostas PENDENTES para a tela inicial do apicultor
        const query = `
            SELECT c.id, c.status, u.full_name AS cafeicultor_nome
            FROM contracts c
            JOIN users u ON c.cafeicultor_id = u.id
            WHERE c.apicultor_id = $1 AND c.status = 'PENDENTE'
            ORDER BY c.created_at DESC;
        `;
        const result = await db.query(query, [id]);
        res.json(result.rows);
    } catch (error) {
        console.error('Erro ao buscar contratos do apicultor:', error);
        res.status(500).json({ error: 'Erro ao buscar contratos.' });
    }
});

// ==========================================
// ROTA 8: Atualizar o status do contrato
// ==========================================
app.put('/api/contracts/:id/status', async (req, res) => {
    const { id } = req.params;
    const { status } = req.body;
    try {
        // Atualiza o status e "carimba" a hora da movimentação (updated_at)
        const query = 'UPDATE contracts SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2 RETURNING *';
        const result = await db.query(query, [status, id]);
        res.json(result.rows[0]);
    } catch (error) {
        console.error('Erro ao atualizar status:', error);
        res.status(500).json({ error: 'Erro ao atualizar status.' });
    }
});

// ==========================================
// ROTA 9: Excluir um contrato (Lixeira)
// ==========================================
app.delete('/api/contracts/:id', async (req, res) => {
    const { id } = req.params;

    try {
        const query = 'DELETE FROM contracts WHERE id = $1 RETURNING *;';
        await db.query(query, [id]);
        res.json({ message: 'Contrato excluído com sucesso.' });
    } catch (error) {
        console.error('Erro ao excluir contrato:', error);
        res.status(500).json({ error: 'Erro ao excluir contrato.' });
    }
});

// ==========================================
// ROTA 10: Buscar TODOS os contratos do Apicultor (ATUALIZADA)
// ==========================================
app.get('/api/contracts/apicultor/todos/:id', async (req, res) => {
    const { id } = req.params;
    try {
        const query = `
            SELECT c.id, c.status, c.quantidade_colmeias, c.valor_total, u.full_name AS cafeicultor_nome
            FROM contracts c
            JOIN users u ON c.cafeicultor_id = u.id
            WHERE c.apicultor_id = $1
            ORDER BY c.created_at DESC;
        `;
        const result = await db.query(query, [id]);
        res.json(result.rows);
    } catch (error) {
        res.status(500).json({ error: 'Erro ao buscar histórico do apicultor.' });
    }
});

// ==========================================
// ROTA 11: Buscar Configurações do Apicultor (Colmeias e Preço)
// ==========================================
app.get('/api/users/:id/config', async (req, res) => {
    const { id } = req.params;
    try {
        const query = 'SELECT total_colmeias, preco_por_colmeia FROM users WHERE id = $1';
        const result = await db.query(query, [id]);
        res.json(result.rows[0] || { total_colmeias: 0, preco_por_colmeia: 50.00 });
    } catch (error) {
        res.status(500).json({ error: 'Erro ao buscar config.' });
    }
});

// ==========================================
// ROTA 12: Atualizar Configurações do Apicultor
// ==========================================
app.put('/api/users/:id/config', async (req, res) => {
    const { id } = req.params;
    const { total_colmeias, preco_por_colmeia } = req.body;
    try {
        const query = 'UPDATE users SET total_colmeias = $1, preco_por_colmeia = $2 WHERE id = $3 RETURNING *';
        await db.query(query, [total_colmeias, preco_por_colmeia, id]);
        res.json({ message: 'Atualizado com sucesso' });
    } catch (error) {
        res.status(500).json({ error: 'Erro ao atualizar config.' });
    }
});

// ==========================================
// NOVA ROTA 04: Criar um novo contrato
// ==========================================
app.post('/api/contracts', async (req, res) => {
    console.log("CHEGOU NO BACKEND:", req.body); // <--- Isso vai aparecer no terminal!
    const { cafeicultor_id, apicultor_id, quantidade_colmeias, valor_total } = req.body;

    try {
        const query = `
            INSERT INTO contracts (cafeicultor_id, apicultor_id, quantidade_colmeias, valor_total)
            VALUES ($1, $2, $3, $4) RETURNING *;
        `;
        const result = await db.query(query, [
            cafeicultor_id, 
            apicultor_id, 
            quantidade_colmeias || 0, 
            valor_total || 0
        ]);
        res.status(201).json(result.rows[0]);
    } catch (error) {
        console.error('Erro ao criar contrato:', error);
        res.status(500).json({ error: 'Erro ao criar contrato.' });
    }
});

// ==========================================
// ROTA 13: Criar Contrato com Valores
// ==========================================
app.post('/api/contratos/novo', async (req, res) => {
    console.log("DADOS REAIS RECEBIDOS:", req.body);
    
    const { cafeicultor_id, apicultor_id, quantidade_colmeias, valor_total } = req.body;

    try {
        const query = `
            INSERT INTO contracts (cafeicultor_id, apicultor_id, quantidade_colmeias, valor_total)
            VALUES ($1, $2, $3, $4) RETURNING *;
        `;
        const result = await db.query(query, [
            cafeicultor_id, 
            apicultor_id, 
            quantidade_colmeias || 0, 
            valor_total || 0
        ]);
        res.status(201).json(result.rows[0]);
    } catch (error) {
        console.error('Erro ao criar contrato:', error);
        res.status(500).json({ error: 'Erro ao criar contrato.' });
    }
});

// ==========================================
// ROTA 14: Alterar Senha
// ==========================================
app.put('/api/users/:id/password', async (req, res) => {
    const { id } = req.params;
    const { nova_senha } = req.body;
    try {
        await db.query('UPDATE users SET password_hash = $1 WHERE id = $2', [nova_senha, id]);
        res.json({ message: 'Senha atualizada com sucesso!' });
    } catch (error) {
        console.error('Erro ao alterar senha:', error);
        res.status(500).json({ error: 'Erro ao alterar senha.' });
    }
});

// ==========================================
// ROTA 15: Apagar Conta DEFINITIVAMENTE
// ==========================================
app.delete('/api/users/:id', async (req, res) => {
    const { id } = req.params;
    try {
        // 1º: Apaga todos os contratos que pertencem a esta pessoa (seja cafeicultor ou apicultor)
        await db.query('DELETE FROM contracts WHERE cafeicultor_id = $1 OR apicultor_id = $1', [id]);
        
        // 2º: Apaga o usuário do sistema
        await db.query('DELETE FROM users WHERE id = $1', [id]);

        res.json({ message: 'Usuário e dados apagados com sucesso!' });
    } catch (error) {
        console.error('Erro ao apagar conta:', error);
        res.status(500).json({ error: 'Erro interno ao apagar conta.' });
    }
});

// ==========================================
// INICIALIZAÇÃO DO SERVIDOR
// ==========================================
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`🚀 Servidor rodando na porta ${PORT}`);
});