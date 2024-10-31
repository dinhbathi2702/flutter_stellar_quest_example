import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stellar_quest_example/widgets/base_page.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

class Quest6 extends StatefulWidget {
  const Quest6({super.key});

  @override
  State<Quest6> createState() => _Quest6State();
}

class _Quest6State extends State<Quest6> {
  final TextEditingController _secretKeyController = TextEditingController();
  final StellarSDK sdk = StellarSDK.TESTNET;
  late KeyPair destinationKeypair;
  late Asset pathAsset;
  @override
  void initState() {
    super.initState();
    destinationKeypair = KeyPair.random();
  }

  @override
  void dispose() {
    _secretKeyController.dispose();
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
            hintText: 'Secret key',
          ),
          controller: _secretKeyController,
        ),
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                  onPressed: _accountMerge, child: const Text('Account Merge')),
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

  _accountMerge() async {
    final questKeypair = _getQuestKey();
    if (kDebugMode) {
      print("questKeyId: ${questKeypair.accountId}");
      print("destinationKeyId: ${destinationKeypair.accountId}");
    }

    bool questKeypairFunded =
        await FriendBot.fundTestAccount(questKeypair.accountId);
    bool destinationKeypairFunded =
        await FriendBot.fundTestAccount(destinationKeypair.accountId);
    if (kDebugMode) {
      print("questKeypair: $questKeypairFunded");
      print("destinationKeypair: $destinationKeypairFunded");
    }

    ///set up the server and account that will be used to build and submit the transaction.
    final AccountResponse questAccount =
        await sdk.accounts.account(questKeypair.accountId);

    final transaction = TransactionBuilder(
      questAccount,
    )
        .addOperation(AccountMergeOperation(
            MuxedAccount(destinationKeypair.accountId, null)))
        .build();
    transaction.sign(questKeypair, Network.TESTNET);

    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);

    if (response.success) {
      if (kDebugMode) {
        print("account ${questKeypair.accountId} created");
      }
    }
  }
}
