import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';

void main() {
  runApp(MaterialApp(
    home: Home(),
    debugShowCheckedModeBanner: false,
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _todoController = TextEditingController();

  List _toDoList = [];
  Map<String, dynamic> _lastRemoved;
  int _lastRemovedPos;

  @override
  void initState() {
    super.initState();

    // lê os dados armazenados no dispositivo e quando termina, o ".then" chama a função anônima passando a data (que é a string)
    // retornada do _readData()
    _readData().then((data) {
      setState(() {
        _toDoList = json.decode(data);
      });
    });
  }

  // função para adicionar item à lista
  void _addToDo() {
    setState(() {
      Map<String, dynamic> newToDo = Map();

      // adiciona o título
      newToDo["title"] = _todoController.text;
      _todoController.text = "";

      // adiciona o "ok"
      newToDo["ok"] = false;
      _toDoList.add(newToDo);

      // chama a função para salvar no dispositivo também
      _saveData();
    });
  }

  // Declara o valor de 1 segundo para a lista atualizar
  Future<Null> _refresh() async {
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      _toDoList.sort((a, b) {
        if(a["ok"] && !b["ok"]) return 1;
        else if (!a["ok"] && b["ok"]) return -1;
        else return 0;
      });

      _saveData();
    });

    return null;
  }

  // O app tem uma coluna que possui dois filhos: uma linha e uma lista
  // A linha possui dois filho também: um input e um botão
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("To do list"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      // Column
      body: Column(
        children: <Widget>[
          // Container (para padding)
          Container(
            padding: EdgeInsets.fromLTRB(17, 1, 7, 1),
            // Row
            child: Row(
              children: <Widget>[
                // Expanded e Input (o expanded serve para expadir ao máximo o que estiver dentro dele, no caso o Input)
                Expanded(
                  child: TextField(
                    controller: _todoController,
                    decoration: InputDecoration(
                      labelText: "Nova tarefa",
                      labelStyle: TextStyle(color: Colors.blueAccent)
                    ),
                  ),
                ),
                // Botão
                RaisedButton(
                  color: Colors.blueAccent,
                  child: Text("Add"),
                  textColor: Colors.white,
                  onPressed: _addToDo,
                )
              ],
            )
          ),
          // Expanded
          Expanded(
            // RefreshIndicator
            child: RefreshIndicator(onRefresh: _refresh,
              // ListView
              child: ListView.builder(
                padding: EdgeInsets.only(top: 10),
                itemCount: _toDoList.length,
                itemBuilder: buildItem
              ),
            )
          )
        ],
      ),
    );
  }

  // Widget do CheckboxListTile com alguns comandos
  Widget buildItem(context, index) {
    // Dismissible (permite o deslizamento)
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        // Align (Alinha de -1 a 1, sendo -1 à total esquerda e 1 à total direita)
        child: Align(
          alignment: Alignment(-0.9, 0),
          child: Icon(Icons.delete, color: Colors.white)
        ),
      ),
      // Define que o deslizamento será do começo ao fim (esquerda > direita)
      direction: DismissDirection.startToEnd,
      // CheckboxListTile
      child: CheckboxListTile(
        title: Text(_toDoList[index]["title"]),
        value: _toDoList[index]["ok"],
        secondary: CircleAvatar(
          child: Icon(_toDoList[index]["ok"] ?
            Icons.check : Icons.error
          )
        ), 
        onChanged: (check) {
          setState(() {
            // troca o valor de true para false e vice-versa
            _toDoList[index]["ok"] = check;

            // chama a função para salvar no dispositivo também
            _saveData();
          });
        },
      ),
      onDismissed: (direction) {
        setState(() {
          // salva o último removido
          _lastRemoved = Map.from(_toDoList[index]);
          // salva a posição do último removido
          _lastRemovedPos = index;
          // remove a tarefa selecionado
          _toDoList.removeAt(index);

          // salva as alterações
          _saveData();

          // SnackBar
          final snack = SnackBar(
            // mensagem a ser mostrada
            content: Text("Tarefa \"${_lastRemoved["title"]}\" removida!"),
            // ação ao pressionar a mensagem (fazer voltar a tarefa excluída)
            action: SnackBarAction(label: "Desfazer",
              onPressed: () {
                // atualiza a tela mostrando a tarefa excluída de volta
                setState(() {
                  _toDoList.insert(_lastRemovedPos, _lastRemoved);
                  _saveData();
                });
              },
            ),
            duration: Duration(seconds: 3),
          );
          // mostra a SnackBar
          Scaffold.of(context).removeCurrentSnackBar(); 
          Scaffold.of(context).showSnackBar(snack);
        });
      },
    );
  }

  /* ------------------------------------- ARMAZENAMENTO ------------------------------------- */
  // função que pega o diretório para salvar os dados
  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    
    return File("${directory.path}/data.json");
  }

  // função que converte a lista para JSON e salva como string
  Future<File> _saveData() async {
    String data = json.encode(_toDoList);
    final file = await _getFile();

    return file.writeAsString(data);
  }

  // função que lê os dados salvos
  Future<String> _readData() async {
    // tenta ler, se não der retorna "false"
    try {
      final file = await _getFile();

      return file.readAsString();
    } catch (e) {
      return null;
    }
  }
  /* ----------------------------------------------------------------------------------------- */
}
