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
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Catálogo da turma')));
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
