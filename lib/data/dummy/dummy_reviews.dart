import '../models/review_model.dart';

final List<ReviewModel> dummyReviews = [
  const ReviewModel(id: 'r1', productId: null, author: 'Maya Anggraini', city: 'Surabaya', rating: 5, comment: 'Pin enamel-nya lucu banget, packingnya pake kertas cokelat + tali rami. Kelihatannya beneran dibikin dengan hati-hati.', date: '2 hari lalu'),
  const ReviewModel(id: 'r2', productId: null, author: 'Reza Pradana', city: 'Jakarta', rating: 5, comment: 'Beli postcard buat dikirim ke teman luar kota. Gambarnya dapet banget vibes Kayutangan-nya. Bakal balik lagi!', date: '5 hari lalu'),
  const ReviewModel(id: 'r3', productId: null, author: 'Sinta Lestari', city: 'Malang', rating: 4, comment: 'Tote bag-nya kuat dan motifnya beda dari yang lain. Penjualnya juga ramah, cerita proses pembuatannya pas diambil langsung.', date: '1 minggu lalu'),
  const ReviewModel(id: 'r4', productId: 'pin-enamel-apel-malang', author: 'Dimas Saputra', city: 'Bandung', rating: 5, comment: 'Warnanya persis kayak di foto, nggak ngecewain. Jadi oleh-oleh andalan.', date: '3 hari lalu'),
  const ReviewModel(id: 'r5', productId: 'postcard-jendela-kayutangan', author: 'Kartika Dewi', city: 'Yogyakarta', rating: 5, comment: 'Kertasnya tebal dan ilustrasinya cantik. Cerita di baliknya bikin makin sayang.', date: '6 hari lalu'),
  const ReviewModel(id: 'r6', productId: 'kaos-heritage-kayutangan', author: 'Bimo Anugerah', city: 'Malang', rating: 5, comment: 'Bahan adem, sablon rapi meski manual. Motif ubinnya keren parah.', date: '4 hari lalu'),
];

double get storeRating => 4.9;
int get storeReviewTotal => 327;
