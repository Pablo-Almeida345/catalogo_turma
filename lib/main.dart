import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

const endpoint = String.fromEnvironment(
  'API_URL',
  defaultValue: 'https://6aea6b123d3dd3d37be685e0.mockapi.io/Produtos',
);

void main() => runApp(const CatalogoApp());

class CatalogoApp extends StatelessWidget {
  const CatalogoApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TelaProdutos(),
    );
  }
}

class TelaProdutos extends StatefulWidget {
  const TelaProdutos({super.key});
  @override
  State<TelaProdutos> createState() => _TelaProdutosState();
}

class _TelaProdutosState extends State<TelaProdutos> {
  List<Produto> _produtos = [];
  bool _carregando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    if (_carregando) return;
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final lista = await buscarProdutos();
      if (!mounted) return;
      setState(() {
        _produtos = lista;
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _erro = 'O servidor demorou. Tente novamente.';
      });
    } on FormatException {
      if (!mounted) return;
      setState(() {
        _erro = 'Resposta fora do contrato de produtos.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _erro = 'Falha na consulta. Confira URL e conexão.';
      });
    } finally {
      if (mounted)
        setState(() {
          _carregando = false;
        });
    }
  }

  Widget _conteudo() {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_erro != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_erro!),
              FilledButton(
                onPressed: _carregar,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }
    if (_produtos.isEmpty) {
      return const Center(child: Text('Nenhum produto cadastrado.'));
    }
    return ListView.builder(
      itemCount: _produtos.length,
      itemBuilder: (context, indice) {
        final produto = _produtos[indice];
        return ListTile(
          title: Text(produto.nome),
          subtitle: Text('Estoque: ${produto.estoque}'),
          trailing: Text('BRL ${produto.preco.toStringAsFixed(2)}'),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo da turma'),
        actions: [
          IconButton(
            onPressed: _carregando ? null : _carregar,
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: _conteudo(),
    );
  }
}

class Produto {
  final String id;
  final String nome;
  final double preco;
  final int estoque;

  const Produto({
    required this.id,
    required this.nome,
    required this.preco,
    required this.estoque,
  });

  factory Produto.fromMap(Map<String, dynamic> mapa) {
    final id = mapa['id'];
    final nome = mapa['nome'];
    final preco = mapa['preco'];
    final estoque = mapa['estoque'];
    if ((id is! String && id is! num) ||
        nome is! String ||
        nome.trim().isEmpty ||
        preco is! num ||
        !preco.isFinite ||
        preco < 0 ||
        estoque is! num ||
        !estoque.isFinite ||
        estoque < 0 ||
        estoque % 1 != 0) {
      throw const FormatException('Produto fora do contrato.');
    }
    return Produto(
      id: id.toString(),
      nome: nome,
      preco: preco.toDouble(),
      estoque: estoque.toInt(),
    );
  }
}

Future<List<Produto>> buscarProdutos() async {
  final resposta = await http
      .get(Uri.parse(endpoint))
      .timeout(const Duration(seconds: 10));
  if (resposta.statusCode != 200) {
    throw Exception('HTTP ${resposta.statusCode}: consulta recusada.');
  }
  final dados = jsonDecode(utf8.decode(resposta.bodyBytes));
  if (dados is! List) {
    throw const FormatException('Era esperada uma lista JSON.');
  }
  return dados.map((item) {
    if (item is! Map<String, dynamic>) {
      throw const FormatException('Registro JSON inválido.');
    }
    return Produto.fromMap(item);
  }).toList();
}
