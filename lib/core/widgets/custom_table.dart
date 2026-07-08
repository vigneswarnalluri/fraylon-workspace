import 'package:flutter/material.dart';

class CustomTableRow {
  final List<Widget> cells;
  final VoidCallback? onTap;

  const CustomTableRow({
    required this.cells,
    this.onTap,
  });
}

class CustomTable extends StatelessWidget {
  final List<String> headers;
  final List<CustomTableRow> rows;
  final List<double>? columnWidths;

  const CustomTable({
    super.key,
    required this.headers,
    required this.rows,
    this.columnWidths,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        constraints: BoxConstraints(
          minWidth: MediaQuery.sizeOf(context).width - 48,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Table Header row
            Container(
              decoration: BoxDecoration(
                color: isDark
                    ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25)
                    : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(11),
                  topRight: Radius.circular(11),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: List.generate(headers.length, (index) {
                  final header = headers[index];
                  final width = columnWidths != null && columnWidths!.length > index
                      ? columnWidths![index]
                      : 120.0;

                  return SizedBox(
                    width: width,
                    child: Text(
                      header,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Rows list
            if (rows.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Text(
                    'No entries found.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              Column(
                children: List.generate(rows.length, (rowIndex) {
                  final row = rows[rowIndex];
                  final isLast = rowIndex == rows.length - 1;

                  return InkWell(
                    onTap: row.onTap,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? (rowIndex % 2 == 0 ? Colors.transparent : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.08))
                            : (rowIndex % 2 == 0 ? Colors.transparent : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2)),
                        border: isLast
                            ? null
                            : Border(
                                bottom: BorderSide(
                                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                                  width: 0.8,
                                ),
                              ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        children: List.generate(row.cells.length, (cellIndex) {
                          final cell = row.cells[cellIndex];
                          final width = columnWidths != null && columnWidths!.length > cellIndex
                              ? columnWidths![cellIndex]
                              : 120.0;

                          return SizedBox(
                            width: width,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: cell,
                            ),
                          );
                        }),
                      ),
                    ),
                  );
                }),
              ),
          ],
        ),
      ),
    );
  }
}
