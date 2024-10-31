import 'package:flutter/material.dart';
import 'package:flutter_stellar_quest_example/widgets/base_page.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

class Quest12 extends StatefulWidget {
  const Quest12({super.key});

  @override
  State<Quest12> createState() => _Quest12State();
}

class _Quest12State extends State<Quest12> {
  final TextEditingController _secretKeyController = TextEditingController();
  final TextEditingController _publicKeyController = TextEditingController();
  final StellarSDK sdk = StellarSDK.TESTNET;
  final sponsorKeypair = KeyPair.random();
  @override
  void dispose() {
    _secretKeyController.dispose();
    _publicKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
        child: Column(
      children: [
        TextField(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Public Key',
          ),
          controller: _publicKeyController,
        ),
        const SizedBox(height: 8),
        TextField(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Secret key',
          ),
          controller: _secretKeyController,
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child:
              ElevatedButton(onPressed: _sponsorships, child: const Text('Sponsorships')),
        )
      ],
    ));
  }

  _sponsorships() async {
    try {
      final secretKey = _secretKeyController.text;
      final KeyPair questKeypair = KeyPair.fromSecretSeed(secretKey);
      debugPrint("questKeyId: ${sponsorKeypair.accountId}");

      bool sponsorKeypairFunded =
          await FriendBot.fundTestAccount(sponsorKeypair.accountId);

      debugPrint("issuerKeypair: $sponsorKeypairFunded");
      final AccountResponse sponsorAccount =
          await sdk.accounts.account(sponsorKeypair.accountId);

      Transaction transaction = TransactionBuilder(sponsorAccount)
          .addOperation(BeginSponsoringFutureReservesOperationBuilder(
                  questKeypair.accountId)
              .build())
          .addOperation(CreateAccountOperation(questKeypair.accountId, '0'))
          .addOperation(EndSponsoringFutureReservesOperationBuilder()
              .setSourceAccount(questKeypair.accountId)
              .build())
          .build();

      transaction.sign(questKeypair, Network.TESTNET);
      transaction.sign(sponsorKeypair, Network.TESTNET);
      SubmitTransactionResponse response =
          await sdk.submitTransaction(transaction);

      if (response.success) {
        debugPrint('Transaction Successful! Hash: ${response.hash}');
      }
    } catch (ex) {
      debugPrint('ex: $ex');
    }
  }
}
