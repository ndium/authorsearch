import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  runApp(MyApp());
}

class AuthorSearchCubit extends Cubit<List<Author>> {
  AuthorSearchCubit() : super([]);

  void searchAuthors(String query) async {
    try {
      final response = await Dio().get(
        'https://openlibrary.org/search/authors.json?q=$query',
      );

      final List<Author> authors = (response.data['docs'] as List)
          .map((authorData) => Author.fromJson(authorData))
          .toList();

      emit(authors);
    } catch (e) {
      emit([]);
    }
  }
}

class MyApp extends StatelessWidget {
  final AuthorSearchCubit authorSearchCubit = AuthorSearchCubit();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: BlocProvider(
        create: (context) => authorSearchCubit,
        child: AuthorSearchScreen(),
      ),
    );
  }
}

class AuthorSearchScreen extends StatelessWidget {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Author Search'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search for Author',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    final query = _searchController.text;
                    if (query.isNotEmpty) {
                      context.read<AuthorSearchCubit>().searchAuthors(query);
                    }
                  },
                ),
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<AuthorSearchCubit, List<Author>>(
              builder: (context, authors) {
                if (authors.isEmpty) {
                  return Center(child: Text('No authors found.'));
                }

                return ListView.builder(
                  itemCount: authors.length,
                  itemBuilder: (context, index) {
                    return AuthorCard(author: authors[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AuthorCard extends StatelessWidget {
  final Author author;

  AuthorCard({required this.author});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16),
      child: ListTile(
        title: Text(author.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Birth Date: ${author.birthDate}'),
            Text('Top Work: ${author.topWork}'),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WorksListScreen(author: author),
            ),
          );
        },
      ),
    );
  }
}

class WorksListScreen extends StatelessWidget {
  final Author author;

  WorksListScreen({required this.author});

  Future<List<String>> getWorksForAuthor(String authorKey) async {
    try {
      final response = await Dio().get(
        'https://openlibrary.org/authors/$authorKey/works.json?limit=100',
      );
      List<String> works = [];

      for (int i = 0; i < response.data['entries'].length; i++) {
        print('Tour $i');
        if (response.data['entries'][i] != null) {
            works.add(response.data['entries'][i]['title'].toString());
            print(response.data['entries'][i]['title'].toString());
        } else {
            print("Élément null trouvé à l'indice $i.");
        }
      }
      return works;
     } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: getWorksForAuthor(author.key),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        print(author.key);
        if (snapshot.hasError) {
          return Center(child: Text('Error loading works.'));
        }

        final List<String> works = snapshot.data ?? [];

        return Scaffold(
          appBar: AppBar(
            title: Text('Works List'),
          ),
          body: ListView.builder(
            itemCount: works.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(works[index]),
              );
            },
          ),
        );
      },
    );
  }
}

class Author {
  final String key;
  final String name;
  final String birthDate;
  final String topWork;

  Author({
    required this.key,
    required this.name,
    required this.birthDate,
    required this.topWork,
  });

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      key: json['key'],
      name: json['name'],
      birthDate: json['birth_date'] ?? 'N/A',
      topWork: json['top_work'] ?? 'N/A',
    );
  }
}
