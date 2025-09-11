import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m_club/features/mclub/offer_detail_screen.dart';
import 'package:m_club/features/mclub/offer_model.dart';

Offer _buildOffer({required int vote, required int rating}) {
  return Offer(
    id: '1',
    categoryIds: const [],
    categoryNames: const [],
    title: 'Title',
    titleShort: 'Title',
    descriptionShort: 'Short',
    descriptionHtml: '<p>Full</p>',
    benefitText: '',
    benefitPercent: null,
    dateStart: null,
    dateEnd: null,
    photoUrl: null,
    photosUrl: const [],
    shareUrl: null,
    branches: const [],
    links: OfferLinks(),
    rating: rating,
    vote: vote,
    isFavorite: false,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('highlights upvote and shows rating', (tester) async {
    final offer = _buildOffer(vote: 1, rating: 42);
    await tester.pumpWidget(MaterialApp(home: OfferDetailScreen(offer: offer)));
    await tester.pumpAndSettle();

    final upIcon = tester.widget<Icon>(find.byIcon(Icons.thumb_up));
    final downIcon = tester.widget<Icon>(find.byIcon(Icons.thumb_down_outlined));
    expect(upIcon.color, Colors.green);
    expect(downIcon.color, Colors.grey);
    expect(find.text('42'), findsOneWidget);
  });

  testWidgets('highlights downvote and shows rating', (tester) async {
    final offer = _buildOffer(vote: -1, rating: 7);
    await tester.pumpWidget(MaterialApp(home: OfferDetailScreen(offer: offer)));
    await tester.pumpAndSettle();

    final upIcon = tester.widget<Icon>(find.byIcon(Icons.thumb_up_outlined));
    final downIcon = tester.widget<Icon>(find.byIcon(Icons.thumb_down));
    expect(upIcon.color, Colors.grey);
    expect(downIcon.color, Colors.red);
    expect(find.text('7'), findsOneWidget);
  });
}
