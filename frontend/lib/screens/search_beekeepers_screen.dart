import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:latlong2/latlong.dart'; 

class SearchBeekeepersScreen extends StatefulWidget {
  final String cafeicultorId;
  final double latitude;   
  final double longitude;  

  const SearchBeekeepersScreen({
    super.key, 
    required this.cafeicultorId,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<SearchBeekeepersScreen> createState() => _SearchBeekeepersScreenState();
}

class _SearchBeekeepersScreenState extends State<SearchBeekeepersScreen> {
  List<dynamic> _beekeepers = [];
  bool _isLoading = true;

  final Distance _distance = const Distance();

  @override
  void initState() {
    super.initState();
    _buscarApicultores();
  }

  Future<void> _buscarApicultores() async {
    try {
      final response = await http.get(Uri.parse('https://beecoffee-connect.onrender.com/api/beekeepers'));
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        
        // ==========================================
        // REDE DE SEGURANÇA (MOGI MIRIM)
        // ==========================================
        final LatLng centroCafeicultor = (widget.latitude == 0.0 && widget.longitude == 0.0)
            ? const LatLng(-22.4332, -46.9583) 
            : LatLng(widget.latitude, widget.longitude);

        data.sort((a, b) {
          final latA = double.tryParse(a['latitude']?.toString() ?? '0') ?? 0.0;
          final lngA = double.tryParse(a['longitude']?.toString() ?? '0') ?? 0.0;
          final latB = double.tryParse(b['latitude']?.toString() ?? '0') ?? 0.0;
          final lngB = double.tryParse(b['longitude']?.toString() ?? '0') ?? 0.0;

          final distA = _distance.as(LengthUnit.Kilometer, centroCafeicultor, LatLng(latA, lngA));
          final distB = _distance.as(LengthUnit.Kilometer, centroCafeicultor, LatLng(latB, lngB));

          return distA.compareTo(distB);
        });

        setState(() {
          _beekeepers = data;
          _isLoading = false;
        });
      } else {
        setState(() { _isLoading = false; });
      }
    } catch (e) {
      debugPrint('Erro ao buscar apicultores: $e');
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _solicitarParceria(Map<String, dynamic> apicultor) async {
    final int maxColmeias = int.tryParse(apicultor['total_colmeias']?.toString() ?? '0') ?? 0;
    final double precoUnidade = double.tryParse(apicultor['preco_por_colmeia']?.toString() ?? '0') ?? 0.0;
    
    int quantidadeSelecionada = maxColmeias > 0 ? 1 : 0;

    if (maxColmeias == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Este apicultor não tem colmeias disponíveis no momento.'), backgroundColor: Colors.orange));
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            double valorTotal = quantidadeSelecionada * precoUnidade;
            return AlertDialog(
              title: const Text('Configurar Proposta', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Para: ${apicultor['full_name']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  const Text('Quantas colmeias deseja alugar?', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text('$quantidadeSelecionada', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green[700])),
                  Slider(
                    value: quantidadeSelecionada.toDouble(), min: 1, max: maxColmeias.toDouble(), divisions: maxColmeias > 1 ? maxColmeias - 1 : 1, activeColor: Colors.amber[800], label: quantidadeSelecionada.toString(),
                    onChanged: (val) { setStateDialog(() { quantidadeSelecionada = val.toInt(); }); },
                  ),
                  const Divider(), const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Investimento Total:', style: TextStyle(fontWeight: FontWeight.bold)), Text('R\$ ${valorTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 18))])
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[800], foregroundColor: Colors.white),
                  onPressed: () async {
                    final int qtdFinal = quantidadeSelecionada;
                    final double valorFinal = valorTotal;
                    Navigator.pop(context); 
                    try {
                      final response = await http.post(
                        Uri.parse('https://beecoffee-connect.onrender.com/api/contracts'),
                        headers: {'Content-Type': 'application/json'},
                        body: jsonEncode({'cafeicultor_id': widget.cafeicultorId, 'apicultor_id': apicultor['id'], 'quantidade_colmeias': qtdFinal, 'valor_total': valorFinal.toString(), 'status': 'PENDENTE'}),
                      );
                      if (mounted) {
                        if (response.statusCode == 201) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Proposta enviada com sucesso!'), backgroundColor: Colors.green));
                          Navigator.pop(context); 
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao enviar: ${response.body}'), backgroundColor: Colors.red));
                        }
                      }
                    } catch (e) {
                      debugPrint('Erro de conexão: $e');
                    }
                  },
                  child: const Text('Enviar Proposta'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // ==========================================
    // REDE DE SEGURANÇA (MOGI MIRIM)
    // ==========================================
    final LatLng centroCafeicultor = (widget.latitude == 0.0 && widget.longitude == 0.0)
        ? const LatLng(-22.4332, -46.9583) 
        : LatLng(widget.latitude, widget.longitude);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(title: const Text('Buscar Apicultores'), backgroundColor: Colors.green[700], foregroundColor: Colors.white),
      body: _isLoading ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Apicultores na Região', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown)),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: _beekeepers.length,
                    itemBuilder: (context, index) {
                      final apicultor = _beekeepers[index];
                      final double lat = double.tryParse(apicultor['latitude']?.toString() ?? '0') ?? 0.0;
                      final double lng = double.tryParse(apicultor['longitude']?.toString() ?? '0') ?? 0.0;
                      
                      double distKm = 0.0;
                      if (lat != 0.0 && lng != 0.0) {
                        distKm = _distance.as(LengthUnit.Kilometer, centroCafeicultor, LatLng(lat, lng));
                      }
                      
                      final cidade = apicultor['city'] ?? 'Cidade não informada';
                      final estado = apicultor['state'] ?? 'SP';

                      return Card(
                        elevation: 2, margin: const EdgeInsets.only(bottom: 16), color: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(apicultor['full_name'] ?? 'Apicultor', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const Icon(Icons.verified, color: Colors.blue, size: 20)]),
                              const SizedBox(height: 12),
                              Row(children: [const Icon(Icons.location_on, size: 16, color: Colors.grey), const SizedBox(width: 8), Text('$cidade, $estado', style: TextStyle(color: Colors.grey[700]))]),
                              const SizedBox(height: 4),
                              Row(children: [const Icon(Icons.route, size: 16, color: Colors.grey), const SizedBox(width: 8), Text('Aprox. ${distKm.toInt()} km de distância', style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500))]),
                              const SizedBox(height: 4),
                              Row(children: [const Icon(Icons.hive, size: 16, color: Colors.amber), const SizedBox(width: 8), Text('${apicultor['total_colmeias']} Caixas Disponíveis', style: TextStyle(color: Colors.grey[700]))]),
                              const SizedBox(height: 4),
                              Row(children: [const Icon(Icons.monetization_on, size: 16, color: Colors.green), const SizedBox(width: 8), Text('R\$ ${double.tryParse(apicultor['preco_por_colmeia'].toString())?.toStringAsFixed(2) ?? '0.00'} / colmeia', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))]),
                              const SizedBox(height: 16),
                              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => _solicitarParceria(apicultor), style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[400], foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), padding: const EdgeInsets.symmetric(vertical: 12)), child: const Text('SOLICITAR PARCERIA', style: TextStyle(fontWeight: FontWeight.bold)))),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}