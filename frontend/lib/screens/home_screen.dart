import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_map/flutter_map.dart'; 
import 'package:latlong2/latlong.dart';        
import 'login_screen.dart'; 
import 'search_beekeepers_screen.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  final String userId; 
  final String userName;
  final String location;
  final double latitude;   
  final double longitude;  

  const HomeScreen({
    super.key, 
    required this.userId,
    required this.userName, 
    required this.location,
    required this.latitude,  
    required this.longitude, 
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  final TextEditingController _producaoController = TextEditingController(text: '500'); 
  final TextEditingController _precoSacaController = TextEditingController(text: '1200.00');

  List<dynamic> _contracts = [];
  bool _isLoadingContracts = true;
  
  List<dynamic> _apicultoresMapa = [];
  bool _isLoadingMapa = true;
  
  int _selectedIndex = 0; 

  double _raioBuscaKm = 30.0; 

  @override
  void initState() {
    super.initState();
    _buscarContratos();
    _buscarApicultoresMapa(); 
  }

  Future<void> _atualizarTelaInteira() async {
    await _buscarContratos();
    await _buscarApicultoresMapa();
    setState(() {});
  }

  Future<void> _buscarContratos() async {
    try {
      final response = await http.get(Uri.parse('https://beecoffee-connect.onrender.com/api/contracts/cafeicultor/${widget.userId}'));
      if (response.statusCode == 200) {
        setState(() { _contracts = jsonDecode(response.body); _isLoadingContracts = false; });
      } else { setState(() { _isLoadingContracts = false; }); }
    } catch (e) { setState(() { _isLoadingContracts = false; }); }
  }

  Future<void> _buscarApicultoresMapa() async {
    try {
      final response = await http.get(Uri.parse('https://beecoffee-connect.onrender.com/api/beekeepers'));
      if (response.statusCode == 200) setState(() { _apicultoresMapa = jsonDecode(response.body); _isLoadingMapa = false; });
    } catch (e) { debugPrint('Erro ao carregar mapa: $e'); }
  }

  Future<void> _atualizarStatusContrato(String contratoId, String novoStatus) async {
    try {
      final response = await http.put(
        Uri.parse('https://beecoffee-connect.onrender.com/api/contracts/$contratoId/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': novoStatus}),
      );
      if (response.statusCode == 200) _buscarContratos(); 
      else if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro no servidor: ${response.body}'), backgroundColor: Colors.red));
    } catch (e) { debugPrint('Erro de conexão: $e'); }
  }

  Future<void> _excluirContrato(String contratoId) async {
    try {
      final response = await http.delete(Uri.parse('https://beecoffee-connect.onrender.com/api/contracts/$contratoId'));
      if (response.statusCode == 200) _buscarContratos(); 
      else if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao apagar: ${response.body}'), backgroundColor: Colors.red));
    } catch (e) { debugPrint('Erro de conexão ao excluir: $e'); }
  }

  void _confirmarAcao(String titulo, String mensagem, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.brown)),
        content: Text(mensagem),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); onConfirm(); },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[800], foregroundColor: Colors.white),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

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
              TextField(controller: senhaController, obscureText: true, decoration: const InputDecoration(labelText: 'Nova Senha', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock))),
              const SizedBox(height: 16),
              TextField(controller: confirmaSenhaController, obscureText: true, decoration: const InputDecoration(labelText: 'Confirmar Nova Senha', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock_outline))),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              onPressed: () async {
                if (senhaController.text != confirmaSenhaController.text) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('As senhas não são iguais!'), backgroundColor: Colors.orange)); return; }
                if (senhaController.text.length < 4) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('A senha é muito curta.'), backgroundColor: Colors.orange)); return; }
                Navigator.pop(context); 
                try {
                  final response = await http.put(Uri.parse('https://beecoffee-connect.onrender.com/api/users/${widget.userId}/password'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'nova_senha': senhaController.text}));
                  if (response.statusCode == 200) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Senha atualizada com sucesso!'), backgroundColor: Colors.green));
                } catch (e) { debugPrint('Erro: $e'); }
              },
              child: const Text('Salvar Senha'),
            ),
          ],
        );
      },
    );
  }

  void _excluirConta() {
    final telaContext = context;
    showDialog(
      context: telaContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Zona de Perigo!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
        content: const Text('Tem certeza que deseja apagar sua conta? Todos os seus contratos também serão cancelados automaticamente.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Não, me tire daqui')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(dialogContext); 
              showDialog(
                context: telaContext,
                builder: (dialogContext2) => AlertDialog(
                  title: const Text('Aviso Final', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  content: const Text('Esta ação não pode ser desfeita. Confirmar exclusão permanente?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(dialogContext2), child: const Text('Cancelar')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                      onPressed: () async {
                        Navigator.pop(dialogContext2); 
                        try {
                          final response = await http.delete(Uri.parse('https://beecoffee-connect.onrender.com/api/users/${widget.userId}'));
                          if (response.statusCode == 200 || response.statusCode == 204) {
                            if (!telaContext.mounted) return;
                            ScaffoldMessenger.of(telaContext).showSnackBar(const SnackBar(content: Text('Conta excluída para sempre.'), backgroundColor: Colors.black));
                            Navigator.of(telaContext).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
                          } else {
                            if (telaContext.mounted) ScaffoldMessenger.of(telaContext).showSnackBar(SnackBar(content: Text('Erro do Servidor: ${response.body}'), backgroundColor: Colors.red, duration: const Duration(seconds: 6)));
                          }
                        } catch (e) {
                          if (telaContext.mounted) ScaffoldMessenger.of(telaContext).showSnackBar(SnackBar(content: Text('Falha de conexão com o servidor: $e'), backgroundColor: Colors.red, duration: const Duration(seconds: 6)));
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
      appBar: AppBar(title: const Text('BeeCoffee Connect'), backgroundColor: Colors.green[700], foregroundColor: Colors.white),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.green[700]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.account_circle, size: 64, color: Colors.white),
                  const SizedBox(height: 12),
                  Text('Olá, ${widget.userName}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            ListTile(leading: const Icon(Icons.lock_reset, color: Colors.grey), title: const Text('Alterar Senha'), onTap: () { Navigator.pop(context); _mostrarDialogAlterarSenha(); }),
            ListTile(leading: const Icon(Icons.delete_forever, color: Colors.redAccent), title: const Text('Apagar Conta', style: TextStyle(color: Colors.redAccent)), onTap: () { Navigator.pop(context); _excluirConta(); }),
            const Divider(), 
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.grey),
              title: const Text('Sair do Aplicativo'),
              onTap: () {
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
              },
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _atualizarTelaInteira, color: Colors.green[700],
        child: Container(decoration: const BoxDecoration(image: DecorationImage(image: AssetImage('assets/images/fundo.jpg'), fit: BoxFit.cover, opacity: 0.15)), child: _buildBody()),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, currentIndex: _selectedIndex, selectedItemColor: Colors.green[700], unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() { _selectedIndex = index; }),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Início'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Mapa'),
          BottomNavigationBarItem(icon: Icon(Icons.trending_up), label: 'ROI'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Histórico'),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0: return _buildHomeContent();
      case 1: return _buildMapContent(); 
      case 2: return _buildRoiContent(); 
      case 3: return _buildHistoryContent();
      default: return _buildHomeContent();
    }
  }

  Widget _buildRoiContent() {
    final contratosValidos = _contracts.where((c) => c['status'] == 'ACEITO' || c['status'] == 'ENCERRAMENTO_CAFEICULTOR' || c['status'] == 'ENCERRAMENTO_APICULTOR' || c['status'] == 'FINALIZADO').toList();
    double investimentoTotal = contratosValidos.fold(0.0, (soma, item) => soma + (double.tryParse(item['valor_total']?.toString() ?? '0') ?? 0.0));
    String prodTexto = _producaoController.text.replaceAll('.', '').replaceAll(',', '.');
    String precoTexto = _precoSacaController.text.replaceAll('.', '').replaceAll(',', '.');
    double producaoAtual = double.tryParse(prodTexto) ?? 0.0;
    double precoSaca = double.tryParse(precoTexto) ?? 0.0;
    double incrementoProducao = producaoAtual * 0.20; 
    double receitaExtraBruta = incrementoProducao * precoSaca;
    double lucroLiquido = receitaExtraBruta - investimentoTotal;
    double roiPercentual = investimentoTotal > 0 ? (lucroLiquido / investimentoTotal) * 100 : 0.0;
    final formatterMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final formatterPct = NumberFormat.decimalPattern('pt_BR');

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Icon(Icons.trending_up, color: Colors.green[700], size: 28), const SizedBox(width: 8), const Text('SIMULADOR DE ROI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown))]),
            const SizedBox(height: 8),
            const Text('Estudos da Embrapa indicam que a polinização por abelhas pode aumentar a produtividade do café arábica em até 20%. Simule o impacto financeiro na sua safra:', style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 24),
            Card(
              color: Colors.white, elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Sua estimativa de produção (Sacas):', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(controller: _producaoController, keyboardType: TextInputType.number, onChanged: (val) => setState(() {}), decoration: const InputDecoration(border: OutlineInputBorder(), prefixIcon: Icon(Icons.shopping_bag))),
                    const SizedBox(height: 16),
                    const Text('Preço atual da Saca de Café:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(controller: _precoSacaController, keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: (val) => setState(() {}), decoration: const InputDecoration(border: OutlineInputBorder(), prefixText: 'R\$ ')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 4, color: Colors.green[700], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Lucro Líquido Estimado Extra', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 8),
                    Text(formatterMoeda.format(lucroLiquido), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16), const Divider(color: Colors.white30), const SizedBox(height: 8),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Seu Investimento (App):', style: TextStyle(color: Colors.white)), Text(formatterMoeda.format(investimentoTotal), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16))]),
                    const SizedBox(height: 8),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('ROI %:', style: TextStyle(color: Colors.white)), Text('${formatterPct.format(roiPercentual)} %', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16))]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapContent() {
    if (_isLoadingMapa) return const Center(child: CircularProgressIndicator());
    const Distance distance = Distance();
    
    // ==========================================
    // REDE DE SEGURANÇA (MOGI MIRIM)
    // Se o banco retornar 0.0 (Null Island), joga para Mogi Mirim
    // ==========================================
    final LatLng centroCafeicultor = (widget.latitude == 0.0 && widget.longitude == 0.0)
        ? const LatLng(-22.4332, -46.9583) 
        : LatLng(widget.latitude, widget.longitude);

    final marcadoresApicultores = _apicultoresMapa.where((apicultor) {
      final double lat = double.tryParse(apicultor['latitude']?.toString() ?? '0') ?? 0.0;
      final double lng = double.tryParse(apicultor['longitude']?.toString() ?? '0') ?? 0.0;
      if (lat == 0.0 && lng == 0.0) return false;
      final double distKm = distance.as(LengthUnit.Kilometer, centroCafeicultor, LatLng(lat, lng));
      return distKm <= _raioBuscaKm; 
    }).map((apicultor) {
      final double lat = double.tryParse(apicultor['latitude']?.toString() ?? '0') ?? 0.0;
      final double lng = double.tryParse(apicultor['longitude']?.toString() ?? '0') ?? 0.0;
      final String nome = apicultor['full_name']?.split(' ')[0] ?? 'Apicultor';

      return Marker(
        point: LatLng(lat, lng),
        width: 100, height: 80,
        child: GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(apicultor['full_name'] ?? 'Apicultor'),
                content: Text('Disponíveis: ${apicultor['total_colmeias']} caixas\nInvestimento: R\$ ${apicultor['preco_por_colmeia']} / un'),
                actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar'))],
              ),
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.amber[800]!, width: 2), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3)]),
                child: Text(nome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.brown), overflow: TextOverflow.ellipsis),
              ),
              const Icon(Icons.location_on, color: Colors.amber, size: 40),
            ],
          ),
        ),
      );
    }).toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16), color: Colors.white,
          child: Column(
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Raio de busca:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown)), Text('${_raioBuscaKm.toInt()} km', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16))]),
              Slider(value: _raioBuscaKm, min: 5, max: 150, divisions: 29, activeColor: Colors.green[700], label: '${_raioBuscaKm.toInt()} km', onChanged: (val) { setState(() { _raioBuscaKm = val; }); }),
            ],
          ),
        ),
        Expanded(
          child: FlutterMap(
            options: MapOptions(initialCenter: centroCafeicultor, initialZoom: 9.5),
            children: [
              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.beecoffee.app'),
              CircleLayer(
                circles: [
                  CircleMarker(point: centroCafeicultor, color: Colors.green.withValues(alpha: 0.15), borderColor: Colors.green[700]!, borderStrokeWidth: 2, useRadiusInMeter: true, radius: _raioBuscaKm * 1000),
                ],
              ),
              MarkerLayer(markers: marcadoresApicultores),
              MarkerLayer(
                markers: [
                  Marker(
                    point: centroCafeicultor, width: 80, height: 80,
                    child: const Column(children: [Icon(Icons.home, color: Colors.blue, size: 40), Text('Sua Fazenda', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, backgroundColor: Colors.white))]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHomeContent() {
    final contratosAtivos = _contracts.where((c) {
      final s = c['status'];
      return s == 'PENDENTE' || s == 'ACEITO' || s == 'ENCERRAMENTO_CAFEICULTOR' || s == 'ENCERRAMENTO_APICULTOR';
    }).toList();
    
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Olá, ${widget.userName}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.brown)),
            const SizedBox(height: 24),
            Card(
              elevation: 3, color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [const Icon(Icons.psychology, color: Colors.green), const SizedBox(width: 8), const Text('PREVISÃO DE FLORADA (IA)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green))]),
                    const Divider(), const SizedBox(height: 8),
                    const Text('🌻 Janela ideal para locação de colmeias prevista entre 15 e 20 de Outubro.', style: TextStyle(fontSize: 14)),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => SearchBeekeepersScreen(cafeicultorId: widget.userId, latitude: widget.latitude, longitude: widget.longitude)))
                            .then((_) { _buscarContratos(); _buscarApicultoresMapa(); });
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white),
                        child: const Text('BUSCAR APICULTORES NA REGIÃO'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('CONTRATOS EM ANDAMENTO', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown)),
            const SizedBox(height: 8),
            _isLoadingContracts ? const Center(child: CircularProgressIndicator()) : contratosAtivos.isEmpty ? const Text('Nenhum contrato ativo no momento.', style: TextStyle(color: Colors.grey)) : _buildListaContratos(contratosAtivos),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryContent() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('HISTÓRICO GERAL', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown)),
            const SizedBox(height: 16),
            _isLoadingContracts ? const Center(child: CircularProgressIndicator()) : _contracts.isEmpty ? const Center(child: Text('Seu histórico está vazio.', style: TextStyle(color: Colors.grey))) : _buildListaContratos(_contracts), 
          ],
        ),
      ),
    );
  }

  Widget _buildListaContratos(List<dynamic> lista) {
    return ListView.builder(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: lista.length,
      itemBuilder: (context, index) {
        final contract = lista[index];
        Color statusColor = Colors.orange; IconData statusIcon = Icons.hourglass_empty; Widget? trailingWidget;
        final int qtd = int.tryParse(contract['quantidade_colmeias']?.toString() ?? '0') ?? 0;
        final double valor = double.tryParse(contract['valor_total']?.toString() ?? '0') ?? 0.0;
        String statusTexto = contract['status'] ?? '';
        
        if (contract['status'] == 'ACEITO') {
          statusColor = Colors.green; statusIcon = Icons.check_circle;
          trailingWidget = IconButton(icon: const Icon(Icons.done_all, color: Colors.green), tooltip: 'Solicitar Encerramento', onPressed: () => _confirmarAcao('Encerrar Parceria', 'Deseja notificar o apicultor para encerrar este contrato e devolver as colmeias?', () => _atualizarStatusContrato(contract['id'].toString(), 'ENCERRAMENTO_CAFEICULTOR')));
        } else if (contract['status'] == 'ENCERRAMENTO_CAFEICULTOR') {
          statusTexto = 'Fim solicitado (Aguardando Apicultor)'; statusColor = Colors.orange; statusIcon = Icons.hourglass_top; trailingWidget = const Tooltip(message: 'Aguardando apicultor', child: Icon(Icons.access_time, color: Colors.orange));
        } else if (contract['status'] == 'ENCERRAMENTO_APICULTOR') {
          statusTexto = 'Apicultor solicitou encerramento'; statusColor = Colors.blue; statusIcon = Icons.notifications_active;
          trailingWidget = IconButton(icon: const Icon(Icons.check_circle, color: Colors.blue), tooltip: 'Confirmar Devolução', onPressed: () => _confirmarAcao('Confirmar Encerramento', 'O Apicultor confirmou a devolução. Deseja finalizar o contrato?', () => _atualizarStatusContrato(contract['id'].toString(), 'FINALIZADO')));
        } else if (contract['status'] == 'FINALIZADO') {
          statusColor = Colors.blue; statusIcon = Icons.handshake; trailingWidget = IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _confirmarAcao('Apagar Histórico', 'Excluir permanentemente?', () => _excluirContrato(contract['id'].toString())));
        } else if (contract['status'] == 'RECUSADO' || contract['status'] == 'CANCELADO') {
          statusColor = contract['status'] == 'RECUSADO' ? Colors.red : Colors.grey; statusIcon = contract['status'] == 'RECUSADO' ? Icons.cancel : Icons.block; trailingWidget = IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _confirmarAcao('Apagar Histórico', 'Excluir permanentemente?', () => _excluirContrato(contract['id'].toString())));
        } else if (contract['status'] == 'PENDENTE') {
          trailingWidget = IconButton(icon: const Icon(Icons.close, color: Colors.orange), onPressed: () => _confirmarAcao('Cancelar Proposta', 'Deseja desistir desta solicitação?', () => _atualizarStatusContrato(contract['id'].toString(), 'CANCELADO')));
        }

        return Card(
          elevation: 2, margin: const EdgeInsets.only(bottom: 8), color: Colors.white,
          child: ListTile(leading: CircleAvatar(backgroundColor: statusColor, child: Icon(statusIcon, color: Colors.white)), title: Text(contract['apicultor_nome'] ?? 'Apicultor', style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('Status: $statusTexto\nSolicitação: $qtd caixas (R\$ ${valor.toStringAsFixed(2)})'), isThreeLine: true, trailing: trailingWidget),
        );
      },
    );
  }
}