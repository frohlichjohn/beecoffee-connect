import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../main.dart'; 

class BeekeeperHomeScreen extends StatefulWidget {
  final String userId; 
  final String userName;
  final String location;

  const BeekeeperHomeScreen({
    super.key, 
    required this.userId, 
    required this.userName, 
    required this.location,
  });

  @override
  State<BeekeeperHomeScreen> createState() => _BeekeeperHomeScreenState();
}

class _BeekeeperHomeScreenState extends State<BeekeeperHomeScreen> {
  List<dynamic> _propostas = [];
  bool _isLoading = true;
  int _selectedIndex = 0;
  
  int _totalColmeias = 0;
  double _precoPorColmeia = 50.0; 

  @override
  void initState() {
    super.initState();
    _buscarPropostas();
    _buscarConfiguracoes(); 
  }

  Future<void> _buscarConfiguracoes() async {
    try {
      final response = await http.get(Uri.parse('https://beecoffee-connect.onrender.com/api/users/${widget.userId}/config'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _totalColmeias = int.tryParse(data['total_colmeias']?.toString() ?? '0') ?? 0;
          _precoPorColmeia = double.tryParse(data['preco_por_colmeia']?.toString() ?? '50.0') ?? 50.0;
        });
      }
    } catch (e) {
      debugPrint('Erro ao buscar config: $e');
    }
  }

  Future<void> _atualizarConfiguracoes(int novoTotal, double novoPreco) async {
    try {
      final response = await http.put(
        Uri.parse('https://beecoffee-connect.onrender.com/api/users/${widget.userId}/config'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'total_colmeias': novoTotal, 'preco_por_colmeia': novoPreco}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          _totalColmeias = novoTotal;
          _precoPorColmeia = novoPreco;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configurações atualizadas com sucesso!'), backgroundColor: Colors.green),
        );
      } else {
        // Alerta se o servidor recusar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar: ${response.body}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      // Alerta se houver falha de conexão
      debugPrint('Erro ao atualizar config: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro de conexão ao salvar configurações.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _mostrarDialogAtualizacao() {
    // Variáveis temporárias para a tela do pop-up
    int tempColmeias = _totalColmeias;
    double tempPreco = _precoPorColmeia;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            
            // O limite do slider se ajusta magicamente
            double maxSlider = tempColmeias > 500 ? tempColmeias.toDouble() : 500.0;

            return AlertDialog(
              title: const Text('Configurar Perfil', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total de Colmeias Disponíveis:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 16),
                    
                    // ==========================================
                    // 1. ÁREA DAS COLMEIAS (Com digitação)
                    // ==========================================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 32),
                          onPressed: tempColmeias > 0 
                            ? () => setStateDialog(() => tempColmeias--) 
                            : null,
                        ),
                        
                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            TextEditingController digitadoController = TextEditingController(text: tempColmeias.toString());
                            showDialog(
                              context: context,
                              builder: (ctxTeclado) => AlertDialog(
                                title: const Text('Digitar Quantidade'),
                                content: TextField(
                                  controller: digitadoController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Ex: 1500'),
                                ),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctxTeclado), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                    onPressed: () {
                                      int? novoValor = int.tryParse(digitadoController.text);
                                      if (novoValor != null && novoValor >= 0) {
                                        setStateDialog(() { tempColmeias = novoValor; });
                                      }
                                      Navigator.pop(ctxTeclado);
                                    },
                                    child: const Text('Confirmar', style: TextStyle(color: Colors.white)),
                                  )
                                ],
                              )
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                            child: Row(
                              children: [
                                Text('$tempColmeias', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.brown)),
                                const SizedBox(width: 4),
                                const Icon(Icons.edit, size: 20, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),

                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: Colors.green, size: 32),
                          onPressed: () => setStateDialog(() => tempColmeias++),
                        ),
                      ],
                    ),
                    
                    Slider(
                      value: tempColmeias.toDouble(),
                      min: 0,
                      max: maxSlider,
                      activeColor: Colors.amber[800],
                      inactiveColor: Colors.amber[100],
                      onChanged: (val) {
                        setStateDialog(() { tempColmeias = val.toInt(); });
                      },
                    ),
                    
                    const Divider(height: 32),
                    
                    const Text('Preço por Colmeia (R\$):', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 16),
                    
                    // ==========================================
                    // 2. ÁREA DO DINHEIRO (Agora com digitação livre!)
                    // ==========================================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 32),
                          onPressed: tempPreco > 0 
                            ? () => setStateDialog(() => tempPreco -= 5.0) 
                            : null,
                        ),
                        
                        // NOVO: Área Clicável para digitar o dinheiro!
                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            TextEditingController precoController = TextEditingController(text: tempPreco.toStringAsFixed(2));
                            showDialog(
                              context: context,
                              builder: (ctxTecladoPreco) => AlertDialog(
                                title: const Text('Digitar Valor (R\$)'),
                                content: TextField(
                                  controller: precoController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Ex: 120.50', prefixText: 'R\$ '),
                                ),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctxTecladoPreco), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                    onPressed: () {
                                      // Proteção anti-bug: troca vírgula por ponto se o usuário usar o padrão brasileiro
                                      String valorTratado = precoController.text.replaceAll(',', '.');
                                      double? novoValor = double.tryParse(valorTratado);
                                      if (novoValor != null && novoValor >= 0) {
                                        setStateDialog(() { tempPreco = novoValor; });
                                      }
                                      Navigator.pop(ctxTecladoPreco);
                                    },
                                    child: const Text('Confirmar', style: TextStyle(color: Colors.white)),
                                  )
                                ],
                              )
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                            child: Row(
                              children: [
                                Text('R\$ ${tempPreco.toStringAsFixed(2)}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green)),
                                const SizedBox(width: 4),
                                const Icon(Icons.edit, size: 20, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),

                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: Colors.green, size: 32),
                          onPressed: () => setStateDialog(() => tempPreco += 5.0),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context), 
                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey))
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[800], foregroundColor: Colors.white),
                  onPressed: () {
                    Navigator.pop(context); // Fecha o pop-up
                    _atualizarConfiguracoes(tempColmeias, tempPreco); // Salva no banco!
                  },
                  child: const Text('Salvar Alterações'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ========================================================
  // NOVO: Pop-up de Dupla Confirmação para o Apicultor
  // ========================================================
  void _confirmarAcao(String titulo, String mensagem, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.brown)),
        content: Text(mensagem),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[800], foregroundColor: Colors.white),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  Future<void> _buscarPropostas() async {
    try {
      final response = await http.get(Uri.parse('https://beecoffee-connect.onrender.com/api/contracts/apicultor/todos/${widget.userId}'));
      if (response.statusCode == 200) {
        setState(() {
          _propostas = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() { _isLoading = false; });
      }
    } catch (e) {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _responderProposta(String contratoId, String novoStatus) async {
    try {
      final response = await http.put(
        Uri.parse('https://beecoffee-connect.onrender.com/api/contracts/$contratoId/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': novoStatus}),
      );
      
      if (response.statusCode == 200) {
        _buscarPropostas(); // Atualiza a tela se der sucesso
      } else {
        // NOVO: Alerta visual para o Apicultor se o banco recusar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro no servidor: ${response.body}'), 
              backgroundColor: Colors.red
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Erro de conexão: $e');
    }
  }

  Future<void> _excluirContrato(String contratoId) async {
    try {
      final response = await http.delete(Uri.parse('https://beecoffee-connect.onrender.com/api/contracts/$contratoId'));
      if (response.statusCode == 200) _buscarPropostas(); 
    } catch (e) {}
  }

// ========================================================
  // JANELA: Alterar Senha
  // ========================================================
  void _mostrarDialogAlterarSenha() {
    TextEditingController senhaController = TextEditingController();
    TextEditingController confirmaSenhaController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Alterar Senha', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: senhaController,
                obscureText: true, // Esconde a senha com asteriscos
                decoration: const InputDecoration(labelText: 'Nova Senha', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmaSenhaController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirmar Nova Senha', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock_outline)),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              onPressed: () async {
                if (senhaController.text != confirmaSenhaController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('As senhas não são iguais!'), backgroundColor: Colors.orange));
                  return;
                }
                if (senhaController.text.length < 4) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('A senha é muito curta.'), backgroundColor: Colors.orange));
                  return;
                }

                Navigator.pop(context); // Fecha o pop-up
                
                try {
                  final response = await http.put(
                    Uri.parse('https://beecoffee-connect.onrender.com/api/users/${widget.userId}/password'),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({'nova_senha': senhaController.text}),
                  );
                  if (response.statusCode == 200) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Senha atualizada com sucesso!'), backgroundColor: Colors.green));
                  }
                } catch (e) {
                  debugPrint('Erro: $e');
                }
              },
              child: const Text('Salvar Senha'),
            ),
          ],
        );
      },
    );
  }

  // ========================================================
  // JANELA: Apagar Conta (Com Dupla Confirmação)
  // ========================================================
  void _excluirConta() {
    // 1ª Confirmação
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Zona de Perigo!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
        content: const Text('Tem certeza que deseja apagar sua conta? Todos os seus contratos também serão cancelados automaticamente.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Não, me tire daqui')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context); // Fecha o primeiro
              
              // 2ª Confirmação Absoluta
              showDialog(
                context: context,
                builder: (context2) => AlertDialog(
                  title: const Text('Aviso Final', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  content: const Text('Esta ação não pode ser desfeita. Confirmar exclusão permanente?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context2), child: const Text('Cancelar')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                      onPressed: () async {
                        Navigator.pop(context2);
                        try {
                          final response = await http.delete(Uri.parse('https://beecoffee-connect.onrender.com/api/users/${widget.userId}'));
                          if (response.statusCode == 200) {
                          // Resolve o aviso azul do Flutter: verifica se a tela ainda está ativa
                            if (!mounted) return;
                            // (Opcional) Se usa SharedPreferences para manter o utilizador logado, descomente as 2 linhas abaixo:
                            // final prefs = await SharedPreferences.getInstance();
                            // await prefs.clear();
                            // 1º PASSO: Mostrar a mensagem de sucesso enquanto ainda estamos nesta tela
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                              content: Text('Conta excluída para sempre.'), 
                              backgroundColor: Colors.black,
                              ),
                          );

                            // 2º PASSO: Agora sim, redireciona para o Login e destrói o histórico
                            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), 
                            (route) => false,
                            );
                          }
                          } catch (e) {
                            debugPrint('Erro: $e');
                          }
                      },
                      child: const Text('APAGAR TUDO'),
                    ),
                  ],
                ),
              );
            },
            child: const Text('Sim, quero apagar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('BeeCoffee Connect'),
        backgroundColor: Colors.amber[800], // Laranja característico do Apicultor
        foregroundColor: Colors.white,
        // O botão de logout foi removido daqui para ficar na gaveta!
      ),
      
      // ==========================================
      // NOVO: MENU LATERAL (DRAWER) DO APICULTOR
      // ==========================================
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.amber[800]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.account_circle, size: 64, color: Colors.white),
                  const SizedBox(height: 12),
                  // Usa o nome real do apicultor que vem do login
                  Text('Olá, ${widget.userName}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            
            ListTile(
              leading: const Icon(Icons.lock_reset, color: Colors.grey),
              title: const Text('Alterar Senha'),
              onTap: () {
                Navigator.pop(context); // Fecha a gaveta
                _mostrarDialogAlterarSenha(); // Abre a janelinha nova
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
              title: const Text('Apagar Conta', style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(context); // Fecha a gaveta
                _excluirConta(); // Abre a dupla confirmação
              },
            ),
            
            const Divider(), 
            
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.grey),
              title: const Text('Sair do Aplicativo'),
              onTap: () {
                // Desloga e volta para a tela de Login
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
              },
            ),
          ],
        ),
      ),
      // ==========================================
      // Fim do Menu Lateral
      // ==========================================

      body: _buildBody(), 
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800], // Cor base do apicultor
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() { _selectedIndex = index; }),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Início'),
          BottomNavigationBarItem(icon: Icon(Icons.handshake), label: 'Propostas'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Ganhos'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Histórico'),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0: return _buildHomeContent();
      case 1: return _buildPropostasContent(); // AGORA CHAMA A NOVA TELA
      case 2: return _buildGanhosContent();    // AGORA CHAMA A NOVA TELA
      case 3: return _buildHistoryContent();
      default: return _buildHomeContent();
    }
  }

  // ========================================================
  // NOVA ABA 1: CENTRAL DE PROPOSTAS (Inbox)
  // ========================================================
  Widget _buildPropostasContent() {
    // Filtra apenas as propostas novinhas em folha (PENDENTE)
    final propostasPendentes = _propostas.where((p) => p['status'] == 'PENDENTE').toList();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.mail_outline, color: Colors.amber[800], size: 28),
              const SizedBox(width: 8),
              const Text('NOVIDADES', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown)),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Avalie as solicitações de locação enviadas pelos cafeicultores.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : propostasPendentes.isEmpty
                  ? Center(
                      child: Column(
                        children: [
                          const SizedBox(height: 40),
                          Icon(Icons.inbox, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          const Text('Sua caixa de propostas está vazia.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                        ],
                      ),
                    )
                  : _buildListaPropostas(propostasPendentes),
        ],
      ),
    );
  }

  // ========================================================
  // NOVA ABA 2: PAINEL DE GANHOS FINANCEIROS
  // ========================================================
  Widget _buildGanhosContent() {
    // Filtra os status para calcular os valores
    final finalizados = _propostas.where((p) => p['status'] == 'FINALIZADO').toList();
    final aReceberList = _propostas.where((p) => p['status'] == 'ACEITO' || p['status'] == 'ENCERRAMENTO_CAFEICULTOR' || p['status'] == 'ENCERRAMENTO_APICULTOR').toList();

    // Calcula a soma (faturamento)
    double ganhosTotais = finalizados.fold(0.0, (soma, item) => soma + (double.tryParse(item['valor_total']?.toString() ?? '0') ?? 0.0));
    double aReceber = aReceberList.fold(0.0, (soma, item) => soma + (double.tryParse(item['valor_total']?.toString() ?? '0') ?? 0.0));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('RESUMO FINANCEIRO', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown)),
          const SizedBox(height: 16),
          
          // Card Principal de Faturamento
          Card(
            elevation: 4,
            color: Colors.green[700],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ganhos Totais (Finalizados)', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text('R\$ ${ganhosTotais.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white30),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Parcerias Concluídas:', style: TextStyle(color: Colors.white)),
                      Text('${finalizados.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Card Secundário de Previsão
          Card(
            elevation: 2,
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: CircleAvatar(backgroundColor: Colors.amber[100], child: Icon(Icons.pending_actions, color: Colors.amber[800])),
              title: const Text('A Receber (Em andamento)', style: TextStyle(color: Colors.grey, fontSize: 14)),
              subtitle: Text('R\$ ${aReceber.toStringAsFixed(2)}', style: const TextStyle(color: Colors.brown, fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ),
          
          const SizedBox(height: 32),
          const Text('HISTÓRICO DE RECEBIMENTOS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.brown)),
          const SizedBox(height: 8),
          
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : finalizados.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Você ainda não possui contratos finalizados.', style: TextStyle(color: Colors.grey)),
                    )
                  // Reutiliza a lista para mostrar apenas os finalizados embaixo do painel
                  : _buildListaPropostas(finalizados),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    // 1. Apicultor também continua vendo os contratos pendentes de encerramento na Home
    final propostasAtivas = _propostas.where((p) {
      final s = p['status'];
      return s == 'PENDENTE' || s == 'ACEITO' || s == 'ENCERRAMENTO_CAFEICULTOR' || s == 'ENCERRAMENTO_APICULTOR';
    }).toList();
    
    int alugadasReais = 0;
    for (var proposta in propostasAtivas) {
      // 2. Colmeias só voltam a ficar "Disponíveis" após o FINALIZADO completo
      if (proposta['status'] == 'ACEITO' || 
          proposta['status'] == 'ENCERRAMENTO_CAFEICULTOR' || 
          proposta['status'] == 'ENCERRAMENTO_APICULTOR') {
        alugadasReais += int.tryParse(proposta['quantidade_colmeias']?.toString() ?? '0') ?? 0;
      }
    }
    
    int colmeiasDisponiveis = _totalColmeias - alugadasReais;
    if (colmeiasDisponiveis < 0) colmeiasDisponiveis = 0; 

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Olá, ${widget.userName}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.brown)),
          const SizedBox(height: 24),

          Card(
            elevation: 2,
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.hive, color: Colors.amber[800]),
                          const SizedBox(width: 8),
                          const Text('GESTÃO DE COLMEIAS', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Text('R\$ ${_precoPorColmeia.toStringAsFixed(2)} / un', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('Disponíveis', colmeiasDisponiveis.toString(), Colors.green),
                      _buildStatItem('Alugadas', alugadasReais.toString(), Colors.orange),
                      _buildStatItem('Total', _totalColmeias.toString(), Colors.blue),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _mostrarDialogAtualizacao,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[800], foregroundColor: Colors.white),
                      child: const Text('CONFIGURAR PERFIL'),
                    ),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('AÇÕES PENDENTES E PARCERIAS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown)),
          const SizedBox(height: 8),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : propostasAtivas.isEmpty
                  ? const Text('Nenhuma ação pendente no momento.', style: TextStyle(color: Colors.grey))
                  : _buildListaPropostas(propostasAtivas),
        ],
      ),
    );
  }

  Widget _buildHistoryContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('HISTÓRICO GERAL', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown)),
          const SizedBox(height: 16),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _propostas.isEmpty
                  ? const Center(child: Text('Seu histórico está vazio.', style: TextStyle(color: Colors.grey)))
                  : _buildListaPropostas(_propostas),
        ],
      ),
    );
  }

  // ========================================================
  // LISTA DE PROPOSTAS DO APICULTOR (COM DUPLA CONFIRMAÇÃO)
  // ========================================================
  Widget _buildListaPropostas(List<dynamic> lista) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: lista.length,
      itemBuilder: (context, index) {
        final proposta = lista[index];
        Color statusColor = Colors.orange;
        IconData statusIcon = Icons.hourglass_empty;
        Widget? trailingWidget;

        final int qtd = int.tryParse(proposta['quantidade_colmeias']?.toString() ?? '0') ?? 0;
        final double valor = double.tryParse(proposta['valor_total']?.toString() ?? '0') ?? 0.0;
        
        String statusTexto = proposta['status'] ?? '';

        // --- INÍCIO DA LÓGICA DE STATUS ---
        if (proposta['status'] == 'PENDENTE') {
          trailingWidget = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.check_circle, color: Colors.green), 
                onPressed: () => _confirmarAcao('Aceitar Proposta', 'Deseja alugar $qtd colmeias por R\$ ${valor.toStringAsFixed(2)}?', () => _responderProposta(proposta['id'].toString(), 'ACEITO'))
              ),
              IconButton(
                icon: const Icon(Icons.cancel, color: Colors.red), 
                onPressed: () => _confirmarAcao('Recusar Proposta', 'Tem certeza que deseja recusar?', () => _responderProposta(proposta['id'].toString(), 'RECUSADO'))
              ),
            ],
          );
        } 
        else if (proposta['status'] == 'ACEITO') {
          statusColor = Colors.green;
          statusIcon = Icons.check_circle;
          trailingWidget = IconButton(
            icon: const Icon(Icons.done_all, color: Colors.green),
            tooltip: 'Recolher Colmeias',
            onPressed: () => _confirmarAcao(
              'Solicitar Encerramento', 
              'Deseja notificar o cafeicultor que você está encerrando o serviço e recolhendo as colmeias?', 
              () => _responderProposta(proposta['id'].toString(), 'ENCERRAMENTO_APICULTOR')
            ),
          );
        }
        else if (proposta['status'] == 'ENCERRAMENTO_APICULTOR') {
          statusTexto = 'Fim solicitado (Aguardando Cafeicultor)';
          statusColor = Colors.orange;
          statusIcon = Icons.hourglass_top;
          trailingWidget = const Tooltip(message: 'Aguardando cafeicultor', child: Icon(Icons.access_time, color: Colors.orange));
        }
        else if (proposta['status'] == 'ENCERRAMENTO_CAFEICULTOR') {
          statusTexto = 'Cafeicultor solicitou encerramento';
          statusColor = Colors.blue;
          statusIcon = Icons.notifications_active;
          trailingWidget = IconButton(
            icon: const Icon(Icons.check_circle, color: Colors.blue),
            tooltip: 'Confirmar Recolhimento',
            onPressed: () => _confirmarAcao(
              'Confirmar Recolhimento', 
              'O cafeicultor encerrou a locação. Confirma o recolhimento e a liberação das suas colmeias?', 
              () => _responderProposta(proposta['id'].toString(), 'FINALIZADO')
            ),
          );
        }
        else if (proposta['status'] == 'FINALIZADO') {
          statusColor = Colors.blue; 
          statusIcon = Icons.handshake;
          trailingWidget = IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _confirmarAcao('Apagar Histórico', 'Excluir permanentemente?', () => _excluirContrato(proposta['id'].toString())),
          );
        }
        else if (proposta['status'] == 'RECUSADO' || proposta['status'] == 'CANCELADO') {
          statusColor = proposta['status'] == 'RECUSADO' ? Colors.red : Colors.grey;
          statusIcon = proposta['status'] == 'RECUSADO' ? Icons.cancel : Icons.block;
          trailingWidget = IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _confirmarAcao('Apagar Histórico', 'Excluir permanentemente?', () => _excluirContrato(proposta['id'].toString())),
          );
        }

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 8),
          color: Colors.white,
          child: ListTile(
            leading: CircleAvatar(backgroundColor: statusColor, child: Icon(statusIcon, color: Colors.white)),
            title: Text(proposta['cafeicultor_nome'] ?? 'Cafeicultor', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Status: $statusTexto\nSolicitação: $qtd caixas (R\$ ${valor.toStringAsFixed(2)})'),
            isThreeLine: true,
            trailing: trailingWidget,
          ),
        );
      },
    );
  }
  
  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
      ],
    );
  }
}