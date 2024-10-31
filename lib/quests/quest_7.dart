import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stellar_quest_example/common/converter.dart';
import 'package:flutter_stellar_quest_example/widgets/base_page.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

class Quest7 extends StatefulWidget {
  const Quest7({super.key});

  @override
  State<Quest7> createState() => _Quest7State();
}

class _Quest7State extends State<Quest7> {
  final TextEditingController _secretKeyController = TextEditingController();
  final StellarSDK sdk = StellarSDK.TESTNET;
  late Asset pathAsset;
  @override
  void initState() {
    super.initState();
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
                  onPressed: _manageData, child: const Text('Manage Data')),
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

  _manageData() async {
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
          .addOperation(
              ManageDataOperation('Hello', convertStringToUint8List('World')))
          .addOperation(ManageDataOperation(
              'Hello', convertStringToUint8List('Stellar Quest!')))
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
