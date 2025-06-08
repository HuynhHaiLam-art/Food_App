import 'package:flutter/material.dart';

class CategorySelector extends StatelessWidget {
  final List<String> categories;
  final int selectedCategoryIndex; // Sử dụng index để quản lý mục được chọn
  final ValueChanged<int> onCategorySelected;

  const CategorySelector({
    super.key,
    required this.categories,
    required this.selectedCategoryIndex,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50, // Chiều cao cố định cho category selector
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final isSelected = selectedCategoryIndex == index;
          return GestureDetector(
            onTap: () => onCategorySelected(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              decoration: BoxDecoration(
                color: isSelected ? Colors.orange.withOpacity(0.8) : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected ? Colors.orange : Colors.white24,
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : [],
              ),
              alignment: Alignment.center,
              child: Text(
                categories[index],
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 15,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}