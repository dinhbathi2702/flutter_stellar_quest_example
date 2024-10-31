import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stellar_quest_example/widgets/base_page.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

class Quest8 extends StatefulWidget {
  const Quest8({super.key});

  @override
  State<Quest8> createState() => _Quest8State();
}

class _Quest8State extends State<Quest8> {
  final TextEditingController _secretKeyController = TextEditingController();
  final TextEditingController _domainController = TextEditingController();
  final StellarSDK sdk = StellarSDK.TESTNET;
  late Asset pathAsset;

  @override
  void dispose() {
    _secretKeyController.dispose();
    _domainController.dispose();
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
            hintText: 'Domain',
          ),
          controller: _domainController,
        ),
        const SizedBox(height: 8),
        TextField(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Secret key',
          ),
          controller: _secretKeyController,
        ),
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                  onPressed: _setOptions, child: const Text('Set Options')),
            ),
          ],
        ),
      ],
    ));
  }

  KeyPair _getQuestKey() {
    final secretKey = _secretKeyController.text;
    final KeyPair questKeypair = KeyPair.fromSecretSeed(secretKey);
    return questKeypair;
  }

  _setOptions() async {
    try {
      final questKeypair = _getQuestKey();
      if (kDebugMode) {
        print("questKeyId: ${questKeypair.accountId}");
      }

      bool questKeypairFunded =
          await FriendBot.fundTestAccount(questKeypair.accountId);

      if (kDebugMode) {
        print("questKeypair: $questKeypairFunded");
      }

      ///set up the server and account that will be used to build and submit the transaction.
      final AccountResponse questAccount =
          await sdk.accounts.account(questKeypair.accountId);

      final transaction = TransactionBuilder(
        questAccount,
      )
          .addOperation(SetOptionsOperationBuilder()
              .setHomeDomain(_domainController.text)
              .build())
          .build();
      transaction.sign(questKeypair, Network.TESTNET);

      SubmitTransactionResponse response =
          await sdk.submitTransaction(transaction);

      if (response.success) {
        if (kDebugMode) {
          print("account ${questKeypair.accountId} created");
        }
      }
    } catch (ex) {
      debugPrint('$ex');
    }
  }
}
