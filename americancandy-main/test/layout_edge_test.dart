import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('short phone can scroll a padded form to the last button',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 480));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: _ShortForm()));

    expect(find.text('Create account'), findsOneWidget);
    expect(find.text('Business name'), findsWidgets);

    final button = find.text('Create account');
    await tester.scrollUntilVisible(
      button,
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(button, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tall phone shows the form button without throwing',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: _ShortForm()));
    expect(find.text('Create account'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('product grid builds only visible cards', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: _LazyProductGrid(count: 300)));
    await tester.pump();

    expect(find.text('Product 0'), findsOneWidget);
    expect(find.text('Product 299'), findsNothing);
    expect(find.text('No Product found'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty product list shows the empty message', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: _LazyProductGrid(count: 0)));
    expect(find.text('No Product found'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('one product and a null-like blank name do not overflow',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(
      home: _LazyProductGrid(count: 1, name: ''),
    ));
    expect(find.text('Product'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _ShortForm extends StatelessWidget {
  const _ShortForm();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Scaffold(
      body: SizedBox(
        width: size.width,
        height: size.height,
        child: Stack(
          children: [
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    for (var i = 0; i < 12; i++)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: TextField(
                          decoration: InputDecoration(labelText: 'Business name'),
                        ),
                      ),
                    const SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: Text('Create account'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LazyProductGrid extends StatelessWidget {
  const _LazyProductGrid({required this.count, this.name});

  final int count;
  final String? name;

  @override
  Widget build(BuildContext context) {
    if (count == 0) {
      return const Scaffold(
        body: Center(child: Text('No Product found')),
      );
    }
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.62,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => Text(
                  index == 0 && name != null
                      ? (name!.isEmpty ? 'Product' : name!)
                      : 'Product $index',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                childCount: count,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
