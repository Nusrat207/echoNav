// search_bar_widget.dart

/*
class SearchBarWidget extends StatefulWidget {
  final Function(String) onSearch;
  final MapRepository mapRepository;

  const SearchBarWidget({
    super.key,
    required this.onSearch,
    required this.mapRepository,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _predictions = [];
  bool _isSearching = false;

  Future<void> _getPredictions(String input) async {
    if (input.isEmpty) {
      setState(() => _predictions = []);
      return;
    }

    setState(() => _isSearching = true);
    try {
      final predictions = await widget.mapRepository.getPlacePredictions(input);
      setState(() => _predictions = predictions);
    } catch (e) {
      print('Error getting predictions: $e');
    } finally {
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Where do you want to go?',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _predictions = []);
                },
              )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onChanged: _getPredictions,
          ),
        ),
        if (_predictions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _predictions.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_predictions[index]),
                  onTap: () {
                    _searchController.text = _predictions[index];
                    setState(() => _predictions = []);
                    widget.onSearch(_predictions[index]);
                  },
                );
              },
            ),
          ),
        if (_isSearching)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
*/
